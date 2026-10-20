const express = require('express');
const { query } = require('../config/db');

const router = express.Router();

const formatDispute = (d) => ({
  id: d.id,
  caseId: d.case_id,
  bookingId: d.booking_id,
  itemTitle: d.item_title,
  renterName: d.renter_name,
  ownerName: d.owner_name,
  reason: d.reason,
  description: d.description,
  amountInvolved: parseFloat(d.amount_involved || 0),
  status: d.status,
  resolution: d.resolution,
  adminNotes: d.admin_notes,
  createdAt: d.created_at,
  updatedAt: d.updated_at
});

router.get('/', async (req, res) => {
  try {
    const rows = await query('SELECT * FROM disputes ORDER BY created_at DESC');
    res.json(rows.map(r => formatDispute(r)));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { bookingId, itemTitle, ownerName, renterName, reason, description, amountInvolved } = req.body;
    const id = 'DISP-' + Date.now();
    const caseId = 'CASE-' + new Date().getFullYear() + '-' + Math.floor(100 + Math.random() * 900);

    await query(`
      INSERT INTO disputes (id, case_id, booking_id, item_title, owner_name, renter_name, reason, description, amount_involved, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'open')
    `, [id, caseId, bookingId || 'GENERAL', itemTitle || 'Rented Item', ownerName || 'Owner', renterName || 'Renter', reason || 'Rental issue', description || '', parseFloat(amountInvolved || 0)]);

    const rows = await query('SELECT * FROM disputes WHERE id = ?', [id]);
    res.status(201).json(formatDispute(rows[0]));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id/resolve', async (req, res) => {
  try {
    const { resolution } = req.body;
    await query('UPDATE disputes SET status = "resolved", resolution = ?, resolved_at = NOW(), updated_at = NOW() WHERE id = ?', [resolution || 'Resolved', req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
