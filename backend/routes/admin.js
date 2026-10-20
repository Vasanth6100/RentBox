const express = require('express');
const { query } = require('../config/db');
const { authenticateToken, requireAdmin, recordAuditLog } = require('../middleware/auth');

const router = express.Router();

// -----------------------------------------------------------------
// A. ADMIN DASHBOARD METRICS & RECENT ACTIVITY
// -----------------------------------------------------------------
router.get('/metrics', async (req, res) => {
  try {
    const totalUsersRow = await query('SELECT COUNT(*) as cnt FROM users WHERE role = "customer"');
    const totalOwnersRow = await query('SELECT COUNT(*) as cnt FROM users WHERE role = "owner"');
    const activeListingsRow = await query('SELECT COUNT(*) as cnt FROM listings WHERE status = "active"');
    const pendingListingsRow = await query('SELECT COUNT(*) as cnt FROM listings WHERE status = "pendingApproval"');
    const flaggedListingsRow = await query('SELECT COUNT(*) as cnt FROM listings WHERE status IN ("flagged", "needsVerification")');
    const activeRentalsRow = await query('SELECT COUNT(*) as cnt FROM bookings WHERE status = "active"');
    const completedRentalsRow = await query('SELECT COUNT(*) as cnt FROM bookings WHERE status = "completed"');
    const grossVolumeRow = await query('SELECT COALESCE(SUM(rental_fee), 0) as total FROM bookings WHERE payment_status = "Paid"');
    const escrowDepositsRow = await query('SELECT COALESCE(SUM(deposit_amount), 0) as total FROM security_deposits WHERE status = "held_in_escrow"');
    const pendingKycRow = await query('SELECT COUNT(*) as cnt FROM owner_verifications WHERE status = "pending"');
    const openDisputesRow = await query('SELECT COUNT(*) as cnt FROM disputes WHERE status IN ("open", "underReview")');

    // Recent activity feeds
    const recentBookings = await query(`
      SELECT b.id, b.listing_title, b.renter_name, b.owner_name, b.total_payable, b.rental_fee, b.status, b.created_at
      FROM bookings b ORDER BY b.created_at DESC LIMIT 6
    `);

    const recentSubmissions = await query(`
      SELECT l.id, l.title, l.category, l.owner_name, l.price_per_day, l.security_deposit, l.status, l.created_at
      FROM listings l ORDER BY l.created_at DESC LIMIT 6
    `);

    const recentAuditLogs = await query(`
      SELECT * FROM admin_audit_logs ORDER BY created_at DESC LIMIT 8
    `);

    res.json({
      success: true,
      metrics: {
        totalUsers: parseInt(totalUsersRow[0].cnt || 0, 10),
        registeredOwners: parseInt(totalOwnersRow[0].cnt || 0, 10),
        activeListings: parseInt(activeListingsRow[0].cnt || 0, 10),
        pendingApprovals: parseInt(pendingListingsRow[0].cnt || 0, 10),
        flaggedListings: parseInt(flaggedListingsRow[0].cnt || 0, 10),
        activeRentals: parseInt(activeRentalsRow[0].cnt || 0, 10),
        completedRentals: parseInt(completedRentalsRow[0].cnt || 0, 10),
        grossTransactions: parseFloat(grossVolumeRow[0].total || 0),
        escrowDepositsHeld: parseFloat(escrowDepositsRow[0].total || 0),
        pendingKycCount: parseInt(pendingKycRow[0].cnt || 0, 10),
        openDisputesCount: parseInt(openDisputesRow[0].cnt || 0, 10)
      },
      recentBookings,
      recentSubmissions,
      recentAuditLogs
    });
  } catch (err) {
    console.error('[RentBox Admin] Metrics error:', err);
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// B & C. LISTING APPROVALS QUEUE & MODERATION
// -----------------------------------------------------------------
router.get('/listings/queue', async (req, res) => {
  try {
    const { status = 'pendingApproval' } = req.query;

    let filterSql = 'l.status = ?';
    let params = [status];

    if (status === 'flagged_all') {
      filterSql = 'l.status IN ("flagged", "needsVerification")';
      params = [];
    } else if (status === 'all') {
      filterSql = '1=1';
      params = [];
    }

    const rows = await query(`
      SELECT l.*,
        (SELECT image_url FROM listing_images WHERE listing_id = l.id ORDER BY is_primary DESC, sort_order ASC LIMIT 1) as primary_image,
        u.kyc_status as owner_kyc_status,
        u.is_verified as owner_is_verified
      FROM listings l
      LEFT JOIN users u ON l.owner_id = u.id
      WHERE ${filterSql}
      ORDER BY l.created_at DESC
    `, params);

    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Approve / Reject / Flag a listing
router.post('/listings/:id/review', async (req, res) => {
  try {
    const listingId = req.params.id;
    const { decision, feedback } = req.body; // decision: 'approved', 'rejected', 'flagged', 'needsVerification'
    const adminId = 'USER-ADMIN';
    const adminName = 'RentBox Administrator';

    const rows = await query('SELECT * FROM listings WHERE id = ?', [listingId]);
    if (rows.length === 0) return res.status(404).json({ error: 'Listing not found.' });

    // Map decision to status
    const statusMap = {
      approved: 'active',
      rejected: 'rejected',
      flagged: 'flagged',
      needsVerification: 'needsVerification'
    };
    const newStatus = statusMap[decision] || decision;

    await query(
      'UPDATE listings SET status = ?, updated_at = NOW() WHERE id = ?',
      [newStatus, listingId]
    );

    // Log approval history
    const historyAction = decision === 'approved' ? 'approved' : (decision === 'rejected' ? 'rejected' : 'flagged');
    await query(`
      INSERT INTO listing_approval_history (listing_id, admin_id, admin_name, action, previous_status, new_status, reason)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [listingId, adminId, adminName, historyAction, rows[0].status, newStatus, feedback || 'Admin moderation review']);

    // Notify listing owner
    const listing = rows[0];
    await query(`
      INSERT INTO notifications (id, user_id, title, message, type)
      VALUES (?, ?, ?, ?, 'listingApproval')
    `, [
      'NOTIF-' + Date.now(),
      listing.owner_id,
      decision === 'approved' ? 'Listing Approved! ✅' : `Listing ${decision}`,
      decision === 'approved'
        ? `Your listing "${listing.title}" has been approved and is now live on RentBox!`
        : `Your listing "${listing.title}" review decision: ${decision}. ${feedback || 'Please review guidelines.'}`
    ]);

    await recordAuditLog(adminId, adminName, `LISTING_${decision.toUpperCase()}`, 'LISTING', listingId, `Decision: ${decision}. Feedback: ${feedback || 'N/A'}`, req);

    res.json({ success: true, message: `Listing has been ${newStatus}.` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get single listing details for admin review
router.get('/listings/:id', async (req, res) => {
  try {
    const listingId = req.params.id;
    const rows = await query('SELECT l.*, u.kyc_status as owner_kyc_status FROM listings l LEFT JOIN users u ON l.owner_id = u.id WHERE l.id = ?', [listingId]);
    if (rows.length === 0) return res.status(404).json({ error: 'Listing not found.' });

    const listing = rows[0];
    const images = await query('SELECT * FROM listing_images WHERE listing_id = ? ORDER BY is_primary DESC, sort_order ASC', [listingId]);
    const specs = await query('SELECT * FROM product_specifications WHERE listing_id = ?', [listingId]);
    const included = await query('SELECT * FROM listing_included_items WHERE listing_id = ?', [listingId]);
    const history = await query('SELECT * FROM listing_approval_history WHERE listing_id = ? ORDER BY created_at DESC', [listingId]);

    res.json({ ...listing, images, specs, included, history });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// D. USER MANAGEMENT
// -----------------------------------------------------------------
router.get('/users', async (req, res) => {
  try {
    const { role, status, search } = req.query;

    let sql = `
      SELECT u.id, u.name, u.email, u.phone, u.role, u.location, u.is_verified,
             u.kyc_status, u.status, u.suspension_reason, u.rating, u.reviews_count,
             u.joined_date, u.created_at,
             (SELECT COUNT(*) FROM listings WHERE owner_id = u.id) as listings_count,
             (SELECT COUNT(*) FROM bookings WHERE renter_id = u.id) as rentals_as_customer,
             (SELECT COUNT(*) FROM bookings WHERE owner_id = u.id) as rentals_as_owner
      FROM users u
      WHERE 1=1
    `;
    const params = [];

    if (role && role !== 'all') {
      sql += ' AND u.role = ?';
      params.push(role);
    }

    if (status && status !== 'all') {
      sql += ' AND u.status = ?';
      params.push(status);
    }

    if (search && search.trim().length > 0) {
      sql += ' AND (u.name LIKE ? OR u.email LIKE ? OR u.phone LIKE ? OR u.id LIKE ?)';
      const term = `%${search.trim()}%`;
      params.push(term, term, term, term);
    }

    sql += ' ORDER BY u.created_at DESC';

    const rows = await query(sql, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Suspend or Reactivate User
router.post('/users/:id/status', async (req, res) => {
  try {
    const userId = req.params.id;
    const { status, reason = 'Administrative action' } = req.body;
    const adminId = 'USER-ADMIN';
    const adminName = 'RentBox Administrator';

    if (status !== 'active' && status !== 'suspended') {
      return res.status(400).json({ error: 'Status must be active or suspended.' });
    }

    await query(
      'UPDATE users SET status = ?, suspension_reason = ?, updated_at = NOW() WHERE id = ?',
      [status, status === 'suspended' ? reason : null, userId]
    );

    await recordAuditLog(
      adminId,
      adminName,
      status === 'suspended' ? 'SUSPEND_USER' : 'REACTIVATE_USER',
      'USER',
      userId,
      `User account ${status}. Reason: ${reason}`,
      req
    );

    res.json({ success: true, message: `User account is now ${status}.` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// E. KYC VERIFICATION QUEUE
// -----------------------------------------------------------------
router.get('/kyc/queue', async (req, res) => {
  try {
    const { status } = req.query;
    let sql = `
      SELECT v.*, u.name as user_name, u.email as user_email, u.phone as user_phone, u.location as user_location
      FROM owner_verifications v
      JOIN users u ON v.user_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (status && status !== 'all') {
      sql += ' AND v.status = ?';
      params.push(status);
    }

    sql += ' ORDER BY v.created_at DESC';

    const rows = await query(sql, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/kyc/:id/review', async (req, res) => {
  try {
    const kycId = req.params.id;
    const { decision, feedback } = req.body; // decision: 'approved', 'rejected', 'resubmit_requested'
    const adminId = 'USER-ADMIN';
    const adminName = 'RentBox Administrator';

    const rows = await query('SELECT * FROM owner_verifications WHERE id = ?', [kycId]);
    if (rows.length === 0) return res.status(404).json({ error: 'KYC record not found.' });
    const kyc = rows[0];

    await query(`
      UPDATE owner_verifications
      SET status = ?, admin_feedback = ?, reviewed_by = ?, reviewed_at = NOW(), updated_at = NOW()
      WHERE id = ?
    `, [decision, feedback || null, adminId, kycId]);

    // Update user table KYC status
    const userKycStatus = decision === 'approved' ? 'verified' : (decision === 'rejected' ? 'rejected' : 'resubmit_needed');
    await query('UPDATE users SET kyc_status = ? WHERE id = ?', [userKycStatus, kyc.user_id]);

    // Notify user
    await query(`
      INSERT INTO notifications (id, user_id, title, message, type)
      VALUES (?, ?, ?, ?, 'security')
    `, [
      'NOTIF-' + Date.now(),
      kyc.user_id,
      decision === 'approved' ? 'KYC Verification Approved! 🛡️' : 'KYC Verification Update',
      decision === 'approved'
        ? 'Your identity documents have been verified. You can now post gear and accept rentals!'
        : `Your verification decision: ${decision}. Details: ${feedback || 'Check requirements'}.`
    ]);

    await recordAuditLog(adminId, adminName, 'REVIEW_KYC', 'KYC', kycId, `Decision: ${decision}. Feedback: ${feedback}`, req);

    res.json({ success: true, message: `KYC record updated to ${decision}.` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// G. TRANSACTIONS & REFUNDS
// -----------------------------------------------------------------
router.get('/transactions', async (req, res) => {
  try {
    const payments = await query(`
      SELECT p.*, b.listing_title, b.renter_name, b.owner_name
      FROM payments p
      JOIN bookings b ON p.booking_id = b.id
      ORDER BY p.created_at DESC LIMIT 50
    `);

    const refunds = await query(`
      SELECT r.*, b.listing_title, b.renter_name
      FROM refunds r
      JOIN bookings b ON r.booking_id = b.id
      ORDER BY r.created_at DESC LIMIT 50
    `);

    const deposits = await query(`
      SELECT d.*, b.listing_title, b.renter_name, b.owner_name
      FROM security_deposits d
      JOIN bookings b ON d.booking_id = b.id
      ORDER BY d.created_at DESC LIMIT 50
    `);

    const payouts = await query(`
      SELECT o.*, b.listing_title, u.name as owner_name, u.phone as owner_phone
      FROM owner_payouts o
      JOIN bookings b ON o.booking_id = b.id
      JOIN users u ON o.owner_id = u.id
      ORDER BY o.created_at DESC LIMIT 50
    `);

    res.json({
      payments,
      refunds,
      deposits,
      payouts
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// H. DISPUTES MANAGEMENT
// -----------------------------------------------------------------
router.get('/disputes', async (req, res) => {
  try {
    const rows = await query(`
      SELECT d.*, b.listing_title, b.start_date, b.end_date, b.security_deposit
      FROM disputes d
      LEFT JOIN bookings b ON d.booking_id = b.id
      ORDER BY d.created_at DESC
    `);

    const disputesWithEvidence = await Promise.all(rows.map(async (d) => {
      const evidence = await query('SELECT * FROM dispute_evidence WHERE dispute_id = ?', [d.id]);
      return { ...d, evidence };
    }));

    res.json(disputesWithEvidence);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/disputes/:id/resolve', async (req, res) => {
  try {
    const disputeId = req.params.id;
    const { resolution, adminNotes, status = 'resolved' } = req.body;
    const adminId = 'USER-ADMIN';
    const adminName = 'RentBox Administrator';

    await query(`
      UPDATE disputes
      SET status = ?, resolution = ?, admin_notes = ?, resolved_by = ?, resolved_at = NOW(), updated_at = NOW()
      WHERE id = ?
    `, [status, resolution || 'Resolved by admin.', adminNotes || '', adminId, disputeId]);

    await recordAuditLog(adminId, adminName, 'RESOLVE_DISPUTE', 'DISPUTE', disputeId, `Dispute ${status}. Resolution: ${resolution}`, req);

    res.json({ success: true, message: `Dispute marked as ${status}.` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// I. REPORTS & ANALYTICS
// -----------------------------------------------------------------
router.get('/reports', async (req, res) => {
  try {
    // 1. Category performance breakdown
    const categoryStats = await query(`
      SELECT c.name, COUNT(l.id) as listings_count, COALESCE(SUM(l.total_rentals), 0) as rentals_count
      FROM categories c
      LEFT JOIN listings l ON c.name = l.category
      GROUP BY c.id, c.name
      ORDER BY rentals_count DESC
    `);

    // 2. Booking status breakdown
    const bookingStatusStats = await query(`
      SELECT status, COUNT(*) as count, COALESCE(SUM(rental_fee), 0) as rental_volume
      FROM bookings
      GROUP BY status
    `);

    // 3. Dispute resolution rate
    const disputeStats = await query(`
      SELECT status, COUNT(*) as count FROM disputes GROUP BY status
    `);

    // 4. Monthly volume aggregate
    const revenueStats = await query(`
      SELECT DATE_FORMAT(created_at, '%b %Y') as month,
             COUNT(*) as bookings_count,
             COALESCE(SUM(rental_fee), 0) as gross_rental,
             COALESCE(SUM(platform_fee), 0) as platform_commission
      FROM bookings
      WHERE payment_status = 'Paid'
      GROUP BY DATE_FORMAT(created_at, '%b %Y')
      ORDER BY MIN(created_at) ASC
    `);

    res.json({
      categoryStats,
      bookingStatusStats,
      disputeStats,
      revenueStats
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// J. PLATFORM SETTINGS & AUDIT LOGS
// -----------------------------------------------------------------
router.get('/settings', async (req, res) => {
  try {
    const settings = await query('SELECT * FROM platform_settings');
    const categories = await query('SELECT * FROM categories ORDER BY display_order ASC');
    const roles = await query('SELECT * FROM roles');
    const auditLogs = await query('SELECT * FROM admin_audit_logs ORDER BY created_at DESC LIMIT 50');

    res.json({
      settings,
      categories,
      roles,
      auditLogs
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/settings', async (req, res) => {
  try {
    const { settings } = req.body; // Key-value object of settings
    const adminId = 'USER-ADMIN';
    const adminName = 'RentBox Administrator';

    if (!settings || typeof settings !== 'object') {
      return res.status(400).json({ error: 'Settings payload must be an object.' });
    }

    for (const [key, value] of Object.entries(settings)) {
      await query(`
        INSERT INTO platform_settings (setting_key, setting_value, updated_by, updated_at)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), updated_by = VALUES(updated_by), updated_at = NOW()
      `, [key, String(value), adminId]);
    }

    await recordAuditLog(adminId, adminName, 'UPDATE_SETTINGS', 'SETTINGS', 'PLATFORM', `Updated settings keys: ${Object.keys(settings).join(', ')}`, req);

    res.json({ success: true, message: 'Platform settings updated successfully.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
