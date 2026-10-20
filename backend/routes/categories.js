const express = require('express');
const { query } = require('../config/db');

const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const rows = await query('SELECT * FROM categories WHERE is_active = 1 ORDER BY display_order ASC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
