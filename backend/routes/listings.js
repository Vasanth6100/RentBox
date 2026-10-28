const express = require('express');
const { query, transaction } = require('../config/db');
const { authenticateToken, requireAdmin, recordAuditLog } = require('../middleware/auth');

const router = express.Router();

// Helper to format listing with images, specs, accessories
const formatListingFull = async (row) => {
  if (!row) return null;

  const images = await query(
    'SELECT image_url, is_primary FROM listing_images WHERE listing_id = ? ORDER BY sort_order ASC',
    [row.id]
  );
  const specs = await query(
    'SELECT spec_key, spec_value FROM product_specifications WHERE listing_id = ?',
    [row.id]
  );
  const items = await query(
    'SELECT item_name FROM listing_included_items WHERE listing_id = ?',
    [row.id]
  );

  const specMap = {};
  for (const s of specs) {
    specMap[s.spec_key] = s.spec_value;
  }

  return {
    id: row.id,
    title: row.title,
    category: row.category,
    categoryId: row.category_id,
    pricePerDay: parseFloat(row.price_per_day),
    originalPrice: parseFloat(row.original_price || 0),
    securityDeposit: parseFloat(row.security_deposit),
    brand: row.brand || 'Standard',
    modelName: row.model_name || '',
    condition: row.condition || 'Good',
    description: row.description,
    location: row.location,
    latitude: parseFloat(row.latitude || 19.0760),
    longitude: parseFloat(row.longitude || 72.8777),
    distanceKm: parseFloat(row.distance_km || 2.0),
    ownerId: row.owner_id,
    ownerName: row.owner_name,
    ownerAvatar: row.owner_avatar,
    ownerRating: parseFloat(row.owner_rating || 4.9),
    ownerReviewsCount: parseInt(row.owner_reviews_count || 12, 10),
    ownerResponseTime: row.owner_response_time || 'Replies in 15 mins',
    isInstantBooking: Boolean(row.is_instant_booking),
    isDeliveryAvailable: Boolean(row.is_delivery_available),
    deliveryCharge: parseFloat(row.delivery_charge || 0),
    minRentDays: parseInt(row.min_rent_days || 1, 10),
    maxRentDays: parseInt(row.max_rent_days || 30, 10),
    hasBill: Boolean(row.has_bill),
    hasSerialVerified: Boolean(row.has_serial_verified),
    hasIdVerified: Boolean(row.has_id_verified),
    status: row.status,
    rejectionReason: row.rejection_reason,
    rating: parseFloat(row.rating || 4.8),
    reviewsCount: parseInt(row.reviews_count || 0, 10),
    totalRentals: parseInt(row.total_rentals || 0, 10),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    imageUrls: images.map(img => img.image_url),
    specifications: specMap,
    includedAccessories: items.map(i => i.item_name)
  };
};

// -----------------------------------------------------------------
// 1. GET ALL LISTINGS (Public or Filtered)
// -----------------------------------------------------------------
router.get('/', async (req, res) => {
  try {
    const { category, status, search, ownerId, isAdmin, userId } = req.query;

    let sql = 'SELECT * FROM listings WHERE 1=1';
    const params = [];

    // Filter logic
    if (isAdmin === 'true') {
      if (status) {
        sql += ' AND status = ?';
        params.push(status);
      }
      if (ownerId) {
        sql += ' AND owner_id = ?';
        params.push(ownerId);
      }
    } else {
      // Mobile app client query & public marketplace
      if (ownerId) {
        sql += ' AND owner_id = ?';
        params.push(ownerId);
        if (status) {
          sql += ' AND status = ?';
          params.push(status);
        }
      } else {
        // Everyone on the internet sees all active published listings
        if (status) {
          sql += ' AND status = ?';
          params.push(status);
        } else {
          // Only show active listings — no admin approval step exists
          sql += ' AND status = "active"';
        }
      }
    }

    if (category && category !== 'All') {
      sql += ' AND (category = ? OR category_id = ?)';
      params.push(category, category);
    }

    if (search && search.trim().length > 0) {
      sql += ' AND (title LIKE ? OR brand LIKE ? OR location LIKE ? OR description LIKE ?)';
      const term = `%${search.trim()}%`;
      params.push(term, term, term, term);
    }

    sql += ' ORDER BY created_at DESC';

    const rows = await query(sql, params);
    const results = await Promise.all(rows.map(r => formatListingFull(r)));

    res.json(results);
  } catch (err) {
    console.error('[RentBox Listings] GET / error:', err);
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// 2. GET LISTING DETAILS BY ID
// -----------------------------------------------------------------
router.get('/:id', async (req, res) => {
  try {
    const rows = await query('SELECT * FROM listings WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Listing not found.' });
    }

    const listing = await formatListingFull(rows[0]);

    // Also fetch review history and approval moderation history
    const reviews = await query('SELECT * FROM reviews WHERE listing_id = ? ORDER BY created_at DESC', [listing.id]);
    const history = await query('SELECT * FROM listing_approval_history WHERE listing_id = ? ORDER BY created_at DESC', [listing.id]);

    res.json({
      ...listing,
      reviews,
      approvalHistory: history
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// 3. CREATE LISTING (Owner flow)
// -----------------------------------------------------------------
router.post('/', async (req, res) => {
  try {
    const b = req.body;
    const id = b.id || 'ITEM-' + Date.now().toString(36).toUpperCase();

    // All listings are published directly without admin approval
    const initialStatus = 'active';

    const pricePerDay = parseFloat(b.pricePerDay || 0);
    const securityDeposit = parseFloat(b.securityDeposit || (pricePerDay * 4));

    // Ensure owner_id exists in users table so foreign key constraint NEVER fails
    const ownerId = b.ownerId || 'USER-1';
    const ownerCheck = await query('SELECT id FROM users WHERE id = ?', [ownerId]);
    if (ownerCheck.length === 0) {
      await query(`
        INSERT INTO users (id, name, email, phone, role, password_hash, location, is_verified, kyc_status)
        VALUES (?, ?, ?, ?, 'owner', 'N/A', ?, 1, 'verified')
        ON DUPLICATE KEY UPDATE name = VALUES(name)
      `, [
        ownerId,
        b.ownerName || 'Verified Owner',
        `${ownerId.toLowerCase()}@rentbox.in`,
        b.ownerPhone || '',
        b.location || 'Mumbai, Maharashtra'
      ]);
    }

    await query(`
      INSERT INTO listings (
        id, title, category, category_id, price_per_day, original_price, security_deposit,
        brand, model_name, \`condition\`, description, location, latitude, longitude,
        distance_km, owner_id, owner_name, owner_avatar, owner_rating, owner_reviews_count,
        delivery_charge, is_instant_booking, is_delivery_available, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        title = VALUES(title),
        category = VALUES(category),
        category_id = VALUES(category_id),
        price_per_day = VALUES(price_per_day),
        original_price = VALUES(original_price),
        security_deposit = VALUES(security_deposit),
        brand = VALUES(brand),
        model_name = VALUES(model_name),
        \`condition\` = VALUES(\`condition\`),
        description = VALUES(description),
        location = VALUES(location),
        status = VALUES(status),
        updated_at = NOW()
    `, [
      id,
      b.title || 'Untitled Equipment',
      b.category || 'General',
      b.categoryId || 'cat-' + (b.category || 'general').toLowerCase(),
      pricePerDay,
      parseFloat(b.originalPrice || pricePerDay * 1.5),
      securityDeposit,
      b.brand || 'Standard',
      b.modelName || '',
      b.condition || 'Like New',
      b.description || '',
      b.location || 'Mumbai, Maharashtra',
      parseFloat(b.latitude || 19.0760),
      parseFloat(b.longitude || 72.8777),
      parseFloat(b.distanceKm || 2.0),
      ownerId,
      b.ownerName || 'Verified Owner',
      b.ownerAvatar || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      parseFloat(b.ownerRating || 4.9),
      parseInt(b.ownerReviewsCount || 10, 10),
      parseFloat(b.deliveryCharge || 0),
      b.isInstantBooking ? 1 : 0,
      b.isDeliveryAvailable ? 1 : 0,
      initialStatus
    ]);

    // Clean existing related rows to avoid duplicate keys on re-insert
    await query('DELETE FROM listing_images WHERE listing_id = ?', [id]);
    await query('DELETE FROM product_specifications WHERE listing_id = ?', [id]);
    await query('DELETE FROM listing_included_items WHERE listing_id = ?', [id]);

    // Insert Images
    const imageUrls = Array.isArray(b.imageUrls) ? b.imageUrls : [];
    if (imageUrls.length === 0) {
      imageUrls.push('https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800');
    }
    for (let i = 0; i < imageUrls.length; i++) {
      await query('INSERT INTO listing_images (listing_id, image_url, is_primary, sort_order) VALUES (?, ?, ?, ?)', [
        id, imageUrls[i], i === 0 ? 1 : 0, i
      ]);
    }

    // Insert Specifications
    if (b.specifications && typeof b.specifications === 'object') {
      for (const [key, val] of Object.entries(b.specifications)) {
        await query('INSERT INTO product_specifications (listing_id, spec_key, spec_value) VALUES (?, ?, ?)', [id, key, String(val)]);
      }
    }

    // Insert Included Accessories
    const accessories = Array.isArray(b.includedAccessories || b.includedItems) ? (b.includedAccessories || b.includedItems) : [];
    for (const item of accessories) {
      await query('INSERT INTO listing_included_items (listing_id, item_name) VALUES (?, ?)', [id, item]);
    }

    // Send owner in-app notification
    await query(`
      INSERT INTO notifications (id, user_id, title, message, type)
      VALUES (?, ?, ?, ?, 'listingApproval')
    `, [
      'NOTIF-' + Date.now(),
      b.ownerId || 'USER-1',
      'Listing Published! 🎉',
      `"${b.title}" is now published and live for everyone on RentBox.`
    ]);

    const createdRows = await query('SELECT * FROM listings WHERE id = ?', [id]);
    const responseData = await formatListingFull(createdRows[0]);

    res.status(201).json(responseData);
  } catch (err) {
    console.error('[RentBox Listings] POST / error:', err);
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// 4. ADMIN APPROVE LISTING
// -----------------------------------------------------------------
router.post('/:id/approve', async (req, res) => {
  try {
    const listingId = req.params.id;
    const { adminId = 'USER-ADMIN', adminName = 'RentBox Administrator' } = req.body;

    const rows = await query('SELECT * FROM listings WHERE id = ?', [listingId]);
    if (rows.length === 0) return res.status(404).json({ error: 'Listing not found.' });
    const listing = rows[0];

    // Business Rule: Owners cannot approve their own listings
    if (listing.owner_id === adminId) {
      return res.status(403).json({ error: 'Business Rule Violation: Owners cannot approve their own listings.' });
    }

    await query(`
      UPDATE listings
      SET status = 'active', rejection_reason = NULL, updated_at = NOW()
      WHERE id = ?
    `, [listingId]);

    // Record Moderation Audit History
    await query(`
      INSERT INTO listing_approval_history (listing_id, admin_id, admin_name, action, previous_status, new_status, reason)
      VALUES (?, ?, ?, 'approved', ?, 'active', 'Listing approved by administrator. Meets all safety, photo, and pricing guidelines.')
    `, [listingId, adminId, adminName, listing.status]);

    // Notify owner
    await query(`
      INSERT INTO notifications (id, user_id, title, message, type)
      VALUES (?, ?, ?, ?, 'listingApproval')
    `, [
      'NOTIF-' + Date.now(),
      listing.owner_id,
      'Listing Approved! 🎉',
      `"${listing.title}" is now active and bookable by customers in Mumbai.`
    ]);

    await recordAuditLog(adminId, adminName, 'APPROVE_LISTING', 'LISTING', listingId, `Approved listing "${listing.title}".`, req);

    res.json({ success: true, message: 'Listing approved and is now live.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// 5. ADMIN REJECT LISTING
// -----------------------------------------------------------------
router.post('/:id/reject', async (req, res) => {
  try {
    const listingId = req.params.id;
    const { reason = 'Listing did not meet platform safety and photo guidelines.', adminId = 'USER-ADMIN', adminName = 'RentBox Administrator' } = req.body;

    const rows = await query('SELECT * FROM listings WHERE id = ?', [listingId]);
    if (rows.length === 0) return res.status(404).json({ error: 'Listing not found.' });
    const listing = rows[0];

    await query(`
      UPDATE listings
      SET status = 'rejected', rejection_reason = ?, updated_at = NOW()
      WHERE id = ?
    `, [reason, listingId]);

    await query(`
      INSERT INTO listing_approval_history (listing_id, admin_id, admin_name, action, previous_status, new_status, reason)
      VALUES (?, ?, ?, 'rejected', ?, 'rejected', ?)
    `, [listingId, adminId, adminName, listing.status, reason]);

    await query(`
      INSERT INTO notifications (id, user_id, title, message, type)
      VALUES (?, ?, ?, ?, 'listingApproval')
    `, [
      'NOTIF-' + Date.now(),
      listing.owner_id,
      'Listing Needs Attention',
      `"${listing.title}" was not approved: ${reason}`
    ]);

    await recordAuditLog(adminId, adminName, 'REJECT_LISTING', 'LISTING', listingId, `Rejected listing: ${reason}`, req);

    res.json({ success: true, message: 'Listing rejected.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// 6. ADMIN REQUEST PHOTO RESHOOT OR ADDITIONAL INFO
// -----------------------------------------------------------------
router.post('/:id/request-action', async (req, res) => {
  try {
    const listingId = req.params.id;
    const { actionType = 'reshoot_requested', reason = 'Please provide clearer, well-lit photos.', adminId = 'USER-ADMIN', adminName = 'RentBox Administrator' } = req.body;

    const rows = await query('SELECT * FROM listings WHERE id = ?', [listingId]);
    if (rows.length === 0) return res.status(404).json({ error: 'Listing not found.' });
    const listing = rows[0];

    const newStatus = actionType === 'flagged' ? 'flagged' : 'needsVerification';

    await query(`
      UPDATE listings
      SET status = ?, rejection_reason = ?, updated_at = NOW()
      WHERE id = ?
    `, [newStatus, reason, listingId]);

    await query(`
      INSERT INTO listing_approval_history (listing_id, admin_id, admin_name, action, previous_status, new_status, reason)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [listingId, adminId, adminName, actionType, listing.status, newStatus, reason]);

    await query(`
      INSERT INTO notifications (id, user_id, title, message, type)
      VALUES (?, ?, ?, ?, 'listingApproval')
    `, [
      'NOTIF-' + Date.now(),
      listing.owner_id,
      'Action Required on Listing',
      `"${listing.title}": ${reason}`
    ]);

    await recordAuditLog(adminId, adminName, `MODERATE_${actionType.toUpperCase()}`, 'LISTING', listingId, reason, req);

    res.json({ success: true, message: `Listing marked as ${newStatus}.` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// 7. OWNER TOGGLE PAUSE LISTING
// -----------------------------------------------------------------
router.post('/:id/toggle-pause', async (req, res) => {
  try {
    const listingId = req.params.id;
    const rows = await query('SELECT status FROM listings WHERE id = ?', [listingId]);
    if (rows.length === 0) return res.status(404).json({ error: 'Listing not found.' });

    const current = rows[0].status;
    const nextStatus = current === 'active' ? 'paused' : 'active';

    await query('UPDATE listings SET status = ?, updated_at = NOW() WHERE id = ?', [nextStatus, listingId]);
    res.json({ success: true, status: nextStatus });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
