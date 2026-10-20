const express = require('express');
const { query } = require('../config/db');

const router = express.Router();

const formatUserPayload = async (user) => {
  const favs = await query('SELECT listing_id FROM favourites WHERE user_id = ?', [user.id]);
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    avatarUrl: user.avatar_url,
    location: user.location,
    isVerified: Boolean(user.is_verified),
    kycStatus: user.kyc_status,
    idDocumentType: user.id_document_type,
    rating: parseFloat(user.rating || 4.9),
    reviewsCount: parseInt(user.reviews_count || 0, 10),
    favoriteListingIds: favs.map(f => f.listing_id),
    joinedDate: user.joined_date || user.created_at
  };
};

// Current User fetch
router.get('/current', async (req, res) => {
  try {
    const userId = req.query.userId || 'USER-1';
    const rows = await query('SELECT * FROM users WHERE id = ?', [userId]);
    if (rows.length === 0) {
      // Fallback
      const fallback = await query('SELECT * FROM users WHERE id = "USER-1"');
      if (fallback.length > 0) {
        return res.json(await formatUserPayload(fallback[0]));
      }
      return res.status(404).json({ error: 'User not found.' });
    }
    res.json(await formatUserPayload(rows[0]));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Toggle Favorite
router.post('/favorites/toggle', async (req, res) => {
  try {
    const { userId, listingId } = req.body;
    if (!userId || !listingId) return res.status(400).json({ error: 'userId and listingId required.' });

    const existing = await query('SELECT id FROM favourites WHERE user_id = ? AND listing_id = ?', [userId, listingId]);
    if (existing.length > 0) {
      await query('DELETE FROM favourites WHERE user_id = ? AND listing_id = ?', [userId, listingId]);
      return res.json({ success: true, isFavorite: false });
    } else {
      await query('INSERT INTO favourites (user_id, listing_id) VALUES (?, ?)', [userId, listingId]);
      return res.json({ success: true, isFavorite: true });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update Profile
router.put('/profile', async (req, res) => {
  try {
    const { userId, name, phone, location, avatarUrl } = req.body;
    const uid = userId || 'USER-1';

    await query(`
      UPDATE users
      SET name = COALESCE(?, name),
          phone = COALESCE(?, phone),
          location = COALESCE(?, location),
          avatar_url = COALESCE(?, avatar_url),
          updated_at = NOW()
      WHERE id = ?
    `, [name, phone, location, avatarUrl, uid]);

    // Also sync to listings owned by this user
    if (name || avatarUrl) {
      await query(`
        UPDATE listings
        SET owner_name = COALESCE(?, owner_name),
            owner_avatar = COALESCE(?, owner_avatar)
        WHERE owner_id = ?
      `, [name, avatarUrl, uid]);
    }

    const rows = await query('SELECT * FROM users WHERE id = ?', [uid]);
    res.json({ success: true, user: await formatUserPayload(rows[0]) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
