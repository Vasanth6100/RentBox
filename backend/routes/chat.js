const express = require('express');
const { query } = require('../config/db');

const router = express.Router();

router.get('/conversations', async (req, res) => {
  try {
    const rows = await query('SELECT * FROM chat_conversations ORDER BY last_message_time DESC');
    res.json(rows.map(c => ({
      id: c.id,
      listingId: c.listing_id,
      listingTitle: c.listing_title,
      otherUserId: c.other_user_id,
      otherUserName: c.other_user_name,
      otherUserAvatar: c.other_user_avatar,
      lastMessage: c.last_message,
      lastMessageTime: c.last_message_time,
      unreadCount: 0
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/messages/:convId', async (req, res) => {
  try {
    const rows = await query('SELECT * FROM chat_messages WHERE conversation_id = ? ORDER BY created_at ASC', [req.params.convId]);
    res.json(rows.map(m => ({
      id: m.id,
      conversationId: m.conversation_id,
      senderId: m.sender_id,
      text: m.text,
      timestamp: m.created_at,
      isRead: Boolean(m.is_read)
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/messages', async (req, res) => {
  try {
    const { conversationId, senderId, text } = req.body;
    const id = 'MSG-' + Date.now();

    await query('INSERT INTO chat_messages (id, conversation_id, sender_id, text) VALUES (?, ?, ?, ?)', [
      id, conversationId, senderId || 'USER-1', text
    ]);

    await query('UPDATE chat_conversations SET last_message = ?, last_message_time = NOW() WHERE id = ?', [
      text, conversationId
    ]);

    res.status(201).json({ id, conversationId, senderId, text, timestamp: new Date() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
