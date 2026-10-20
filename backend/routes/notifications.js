const express = require('express');
const { query } = require('../config/db');

const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const userId = req.query.userId || 'USER-1';
    const rows = await query('SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC', [userId]);
    res.json(rows.map(r => ({
      id: r.id,
      userId: r.user_id,
      title: r.title,
      message: r.message,
      type: r.type,
      isRead: Boolean(r.is_read),
      timestamp: r.created_at
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/:id/read', async (req, res) => {
  try {
    await query('UPDATE notifications SET is_read = 1 WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
