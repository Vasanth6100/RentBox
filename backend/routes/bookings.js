const express = require('express');
const { query, transaction } = require('../config/db');
const { recordAuditLog } = require('../middleware/auth');

const router = express.Router();

const formatBookingResponse = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    listingId: row.listing_id,
    listingTitle: row.listing_title,
    listingImage: row.listing_image,
    renterId: row.renter_id,
    renterName: row.renter_name,
    ownerId: row.owner_id,
    ownerName: row.owner_name,
    startDate: row.start_date,
    endDate: row.end_date,
    durationDays: parseInt(row.duration_days, 10),
    fulfillmentMethod: row.fulfillment_method,
    protectionPlan: row.protection_plan,
    dailyRate: parseFloat(row.daily_rate),
    rentalFee: parseFloat(row.rental_fee),
    securityDeposit: parseFloat(row.security_deposit),
    deliveryFee: parseFloat(row.delivery_fee || 0),
    protectionFee: parseFloat(row.protection_fee || 0),
    platformFee: parseFloat(row.platform_fee || 0),
    taxes: parseFloat(row.taxes || 0),
    totalPayable: parseFloat(row.total_payable),
    status: row.status,
    pickupCode: row.pickup_code,
    returnCode: row.return_code,
    paymentMethod: row.payment_method,
    paymentStatus: row.payment_status,
    location: row.location,
    isReviewed: Boolean(row.is_reviewed),
    cancellationReason: row.cancellation_reason,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
};

// -----------------------------------------------------------------
// 1. GET ALL BOOKINGS (Filtered)
// -----------------------------------------------------------------
router.get('/', async (req, res) => {
  try {
    const { renterId, ownerId, status, search, limit = 50, offset = 0 } = req.query;

    let sql = 'SELECT * FROM bookings WHERE 1=1';
    const params = [];

    if (renterId) {
      sql += ' AND renter_id = ?';
      params.push(renterId);
    }

    if (ownerId) {
      sql += ' AND owner_id = ?';
      params.push(ownerId);
    }

    if (status) {
      sql += ' AND status = ?';
      params.push(status);
    }

    if (search && search.trim().length > 0) {
      sql += ' AND (id LIKE ? OR listing_title LIKE ? OR renter_name LIKE ? OR owner_name LIKE ?)';
      const term = `%${search.trim()}%`;
      params.push(term, term, term, term);
    }

    sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const rows = await query(sql, params);
    res.json(rows.map(r => formatBookingResponse(r)));
  } catch (err) {
    console.error('[RentBox Bookings] GET / error:', err);
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// 2. GET SINGLE BOOKING DETAILS
// -----------------------------------------------------------------
router.get('/:id', async (req, res) => {
  try {
    const rows = await query('SELECT * FROM bookings WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Booking not found.' });

    const booking = formatBookingResponse(rows[0]);

    // Fetch related payment, deposit, and inspection records
    const payments = await query('SELECT * FROM payments WHERE booking_id = ?', [booking.id]);
    const deposits = await query('SELECT * FROM security_deposits WHERE booking_id = ?', [booking.id]);
    const refunds = await query('SELECT * FROM refunds WHERE booking_id = ?', [booking.id]);
    const handovers = await query('SELECT * FROM pickup_return_records WHERE booking_id = ?', [booking.id]);

    res.json({
      ...booking,
      paymentRecords: payments,
      depositRecord: deposits[0] || null,
      refundRecords: refunds,
      handoverRecords: handovers
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// 3. CREATE BOOKING WITH BACKEND PRICE RECALCULATION & OVERLAP CHECK
// -----------------------------------------------------------------
router.post('/', async (req, res) => {
  try {
    const b = req.body;
    const listingId = b.listingId;

    if (!listingId) {
      return res.status(400).json({ error: 'listingId is required.' });
    }

    // 1. Fetch listing details from database
    const listings = await query('SELECT * FROM listings WHERE id = ?', [listingId]);
    if (listings.length === 0) {
      return res.status(404).json({ error: 'The requested listing does not exist.' });
    }
    const listing = listings[0];

    // Business rule: Unapproved listings cannot be booked
    if (listing.status !== 'active') {
      return res.status(400).json({
        error: `Item cannot be booked. Current listing status is: ${listing.status}.`
      });
    }

    const startDate = (b.startDate || '').split('T')[0];
    const endDate = (b.endDate || '').split('T')[0];

    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required.' });
    }

    // 2. Business rule: Prevent overlapping confirmed bookings
    const overlapRows = await query(`
      SELECT id FROM bookings
      WHERE listing_id = ?
        AND status IN ('upcoming', 'active')
        AND (
          (start_date <= ? AND end_date >= ?) OR
          (start_date <= ? AND end_date >= ?) OR
          (start_date >= ? AND end_date <= ?)
        )
    `, [listingId, startDate, startDate, endDate, endDate, startDate, endDate]);

    if (overlapRows.length > 0) {
      return res.status(409).json({
        error: 'Date Conflict: This equipment is already booked for all or part of the selected dates.'
      });
    }

    // 3. Recalculate duration & pricing on backend
    const sDate = new Date(startDate);
    const eDate = new Date(endDate);
    const timeDiff = Math.max(1, Math.ceil((eDate.getTime() - sDate.getTime()) / (1000 * 60 * 60 * 24)));
    const durationDays = b.durationDays ? Math.max(1, parseInt(b.durationDays, 10)) : timeDiff;

    const dailyRate = parseFloat(listing.price_per_day);
    const rentalFee = dailyRate * durationDays;
    const securityDeposit = parseFloat(listing.security_deposit);

    const protectionPlan = b.protectionPlan || 'standard';
    let protectionFee = 99.00;
    if (protectionPlan === 'basic') protectionFee = 49.00;
    if (protectionPlan === 'none') protectionFee = 0.00;

    const fulfillmentMethod = b.fulfillmentMethod || 'selfPickup';
    const deliveryFee = fulfillmentMethod === 'ownerDelivery' ? parseFloat(listing.delivery_charge || 150) : 0.00;

    // Platform fee calculation (10% default)
    const platformFee = Math.round(rentalFee * 0.10 * 100) / 100;
    const totalPayable = rentalFee + securityDeposit + deliveryFee + protectionFee;

    const bookingId = b.id || 'RB-BKG-' + Date.now().toString(36).toUpperCase();
    const pickupCode = 'RB-' + Math.floor(1000 + Math.random() * 9000);
    const returnCode = 'RB-RET-' + Math.floor(1000 + Math.random() * 9000);

    // 4. Atomic Transaction for booking, payment & deposit escrow
    await transaction(async () => {
      // Create Booking
      await query(`
        INSERT INTO bookings (
          id, listing_id, listing_title, listing_image, renter_id, renter_name,
          owner_id, owner_name, start_date, end_date, duration_days, fulfillment_method,
          protection_plan, daily_rate, rental_fee, security_deposit, delivery_fee,
          protection_fee, platform_fee, taxes, total_payable, status, pickup_code,
          return_code, payment_method, payment_status, location
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0.00, ?, 'upcoming', ?, ?, ?, 'Paid', ?)
      `, [
        bookingId,
        listing.id,
        listing.title,
        b.listingImage || 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
        b.renterId || 'USER-1',
        b.renterName || 'Vasanth Kumar',
        listing.owner_id,
        listing.owner_name,
        startDate,
        endDate,
        durationDays,
        fulfillmentMethod,
        protectionPlan,
        dailyRate,
        rentalFee,
        securityDeposit,
        deliveryFee,
        protectionFee,
        platformFee,
        totalPayable,
        pickupCode,
        returnCode,
        b.paymentMethod || 'UPI',
        b.location || listing.location
      ]);

      // Record captured payment
      await query(`
        INSERT INTO payments (id, booking_id, transaction_ref, payment_gateway, amount, rental_portion, deposit_portion, platform_fee_portion, status)
        VALUES (?, ?, ?, 'UPI / Gateway', ?, ?, ?, ?, 'captured')
      `, [
        'PAY-' + bookingId,
        bookingId,
        'TXN_' + Date.now(),
        totalPayable,
        rentalFee,
        securityDeposit,
        platformFee
      ]);

      // Record escrow refundable security deposit (Never mixed with revenue)
      await query(`
        INSERT INTO security_deposits (id, booking_id, renter_id, deposit_amount, status)
        VALUES (?, ?, ?, ?, 'held_in_escrow')
      `, ['DEP-' + bookingId, bookingId, b.renterId || 'USER-1', securityDeposit]);

      // Update listing stats
      await query('UPDATE listings SET total_rentals = total_rentals + 1 WHERE id = ?', [listing.id]);

      // Notification to renter
      await query(`
        INSERT INTO notifications (id, user_id, title, message, type)
        VALUES (?, ?, ?, ?, 'booking')
      `, [
        'NOTIF-' + Date.now(),
        b.renterId || 'USER-1',
        'Booking Confirmed 🎉',
        `Your reservation for "${listing.title}" is confirmed! Show pickup code ${pickupCode} upon receiving gear.`
      ]);

      // Notification to owner
      await query(`
        INSERT INTO notifications (id, user_id, title, message, type)
        VALUES (?, ?, ?, ?, 'booking')
      `, [
        'NOTIF-' + (Date.now() + 1),
        listing.owner_id,
        'New Rental Reservation Received! 💰',
        `"${listing.title}" booked from ${startDate} to ${endDate} by ${b.renterName || 'Customer'}.`
      ]);
    });

    const createdRows = await query('SELECT * FROM bookings WHERE id = ?', [bookingId]);
    res.status(201).json(formatBookingResponse(createdRows[0]));
  } catch (err) {
    console.error('[RentBox Bookings] POST / error:', err);
    res.status(500).json({ error: err.message });
  }
});

// -----------------------------------------------------------------
// 4. UPDATE BOOKING STATUS & HANDOVERS
// -----------------------------------------------------------------
router.put('/:id/status', async (req, res) => {
  try {
    const bookingId = req.params.id;
    const { status, paymentStatus, verifiedCode, conditionStatus, notes } = req.body;

    const rows = await query('SELECT * FROM bookings WHERE id = ?', [bookingId]);
    if (rows.length === 0) return res.status(404).json({ error: 'Booking not found.' });
    const booking = rows[0];

    const updates = [];
    const params = [];

    if (status) {
      updates.push('status = ?');
      params.push(status);
    }
    if (paymentStatus) {
      updates.push('payment_status = ?');
      params.push(paymentStatus);
    }

    if (updates.length > 0) {
      updates.push('updated_at = NOW()');
      params.push(bookingId);
      await query(`UPDATE bookings SET ${updates.join(', ')} WHERE id = ?`, params);
    }

    // If transitioned to 'active' (gear picked up)
    if (status === 'active') {
      await query(`
        INSERT INTO pickup_return_records (booking_id, event_type, verified_code, condition_status, condition_notes, recorded_by)
        VALUES (?, 'pickup', ?, ?, ?, ?)
      `, [bookingId, verifiedCode || booking.pickup_code, conditionStatus || 'good', notes || 'Gear handed over in excellent condition.', booking.owner_id]);
    }

    // If transitioned to 'completed' (gear returned safely)
    if (status === 'completed') {
      await query(`
        INSERT INTO pickup_return_records (booking_id, event_type, verified_code, condition_status, condition_notes, recorded_by)
        VALUES (?, 'return', ?, ?, ?, ?)
      `, [bookingId, verifiedCode || booking.return_code || 'RB-RET', conditionStatus || 'good', notes || 'Gear returned and verified by owner.', booking.owner_id]);

      // Automatically release security deposit back to renter
      await query(`
        UPDATE security_deposits
        SET status = 'refunded_full', refunded_at = NOW()
        WHERE booking_id = ? AND status = 'held_in_escrow'
      `, [bookingId]);

      await query(`
        INSERT INTO refunds (id, payment_id, booking_id, refund_type, amount, reason, status)
        VALUES (?, ?, ?, 'deposit_refund', ?, 'Automatic deposit release after zero-damage return.', 'processed')
      `, ['REF-' + Date.now(), 'PAY-' + bookingId, bookingId, booking.security_deposit]);

      // Create owner payout
      const netPayout = parseFloat(booking.rental_fee) - parseFloat(booking.platform_fee || 0);
      await query(`
        INSERT INTO owner_payouts (id, owner_id, booking_id, gross_amount, platform_fee, net_payout, payout_status)
        VALUES (?, ?, ?, ?, ?, ?, 'completed')
      `, ['PAYOUT-' + Date.now(), booking.owner_id, bookingId, booking.rental_fee, booking.platform_fee, netPayout]);
    }

    res.json({ success: true, message: `Booking status updated to ${status}.` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
