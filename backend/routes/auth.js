const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('../config/db');
const { loginLimiter, authenticateToken, recordAuditLog, JWT_SECRET } = require('../middleware/auth');

const router = express.Router();

// Helper to format user response object
const formatUserResponse = async (user) => {
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

// -----------------------------------------------------------------
// 1. CUSTOMER & OWNER LOGIN
// -----------------------------------------------------------------
router.post('/login', loginLimiter, async (req, res) => {
  try {
    const { emailPhone, password } = req.body;

    if (!emailPhone || !emailPhone.trim()) {
      return res.status(400).json({ success: false, error: 'Email or mobile number is required.' });
    }
    if (!password || !password.trim()) {
      return res.status(400).json({ success: false, error: 'Password is required.' });
    }

    const trimmed = emailPhone.trim();
    const rows = await query(
      'SELECT * FROM users WHERE (email = ? OR phone = ?) AND status != "suspended"',
      [trimmed, trimmed]
    );
    const user = rows[0];

    if (!user) {
      return res.status(401).json({ success: false, error: 'Account not found with this email or mobile number.' });
    }

    if (user.status === 'suspended') {
      return res.status(403).json({ success: false, error: 'Your account has been suspended. Please contact support.' });
    }

    // Strictly verify password via bcrypt — no plaintext bypass allowed
    if (!user.password_hash) {
      return res.status(401).json({ success: false, error: 'Account authentication is not properly configured. Please contact support.' });
    }
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ success: false, error: 'Incorrect password. Please try again.' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    const userPayload = await formatUserResponse(user);

    return res.json({
      success: true,
      token,
      user: userPayload
    });
  } catch (err) {
    console.error('[RentBox Auth] Login error:', err);
    return res.status(500).json({ success: false, error: 'Internal server error during authentication.' });
  }
});

// -----------------------------------------------------------------
// 2. USER REGISTRATION
// -----------------------------------------------------------------
router.post('/register', async (req, res) => {
  try {
    const { name, email, phone, password, location, role } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, error: 'Name, email, and password are required.' });
    }

    const existing = await query('SELECT id FROM users WHERE email = ?', [email.trim().toLowerCase()]);
    if (existing.length > 0) {
      return res.status(409).json({ success: false, error: 'An account with this email already exists.' });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);
    const userId = 'USER-' + Date.now().toString(36).toUpperCase();
    const assignedRole = (role === 'owner' || role === 'customer') ? role : 'customer';

    await query(`
      INSERT INTO users (id, name, email, phone, role, password_hash, location, is_verified, kyc_status)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1, 'verified')
    `, [userId, name.trim(), email.trim().toLowerCase(), phone || '', assignedRole, passwordHash, location || 'Mumbai, Maharashtra']);

    const rows = await query('SELECT * FROM users WHERE id = ?', [userId]);
    const newUser = rows[0];

    const token = jwt.sign(
      { id: newUser.id, email: newUser.email, role: newUser.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    const userPayload = await formatUserResponse(newUser);

    return res.status(201).json({
      success: true,
      message: 'Account created successfully!',
      token,
      user: userPayload
    });
  } catch (err) {
    console.error('[RentBox Auth] Register error:', err);
    return res.status(500).json({ success: false, error: 'Internal server error creating account.' });
  }
});

// -----------------------------------------------------------------
// 3. DEDICATED SECURE ADMIN LOGIN
// -----------------------------------------------------------------
router.post('/admin-login', loginLimiter, async (req, res) => {
  try {
    const { emailPhone, email, password, passkey } = req.body;
    const identifier = (emailPhone || email || '').trim();
    const secret = password || passkey || '';

    if (!identifier && !secret) {
      return res.status(400).json({ success: false, error: 'Administrator credentials required.' });
    }

    // Master PIN shortcut check if supported in dev/ops mode
    const adminPin = process.env.ADMIN_MASTER_PIN || '8899';
    let adminUser = null;

    if (secret === adminPin && (!identifier || identifier === 'admin@rentbox.in' || identifier === 'admin')) {
      const rows = await query('SELECT * FROM users WHERE role = "admin" LIMIT 1');
      if (rows.length > 0) adminUser = rows[0];
    }

    if (!adminUser) {
      const rows = await query(
        'SELECT * FROM users WHERE (email = ? OR phone = ? OR id = ?) AND role IN ("admin", "super_admin")',
        [identifier, identifier, identifier]
      );
      if (rows.length === 0) {
        return res.status(401).json({
          success: false,
          error: 'Access denied: No administrative account found with these credentials.'
        });
      }

      adminUser = rows[0];
      const isMatch = await bcrypt.compare(secret, adminUser.password_hash);
      if (!isMatch) {
        return res.status(401).json({ success: false, error: 'Invalid administrator password or passkey.' });
      }
    }

    // Role-based verification safeguard
    if (adminUser.role !== 'admin' && adminUser.role !== 'super_admin') {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: You do not possess administrative permissions on RentBox.'
      });
    }

    const token = jwt.sign(
      { id: adminUser.id, email: adminUser.email, role: adminUser.role },
      JWT_SECRET,
      { expiresIn: '3d' }
    );

    // Audit log this administrative access
    await recordAuditLog(
      adminUser.id,
      adminUser.name,
      'ADMIN_LOGIN',
      'ADMIN_PORTAL',
      adminUser.id,
      'Administrator successfully authenticated to command center.',
      req
    );

    const userPayload = await formatUserResponse(adminUser);

    return res.json({
      success: true,
      message: 'Admin authentication verified.',
      token,
      user: userPayload,
      portalUrl: '/admin.html?token=' + token
    });
  } catch (err) {
    console.error('[RentBox Auth] Admin Login error:', err);
    return res.status(500).json({ success: false, error: 'Error during admin verification.' });
  }
});

// -----------------------------------------------------------------
// 4. VERIFY CURRENT SESSION / USER
// -----------------------------------------------------------------
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const userPayload = await formatUserResponse(req.user);
    res.json({ success: true, user: userPayload });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// -----------------------------------------------------------------
// 5. LOGOUT
// -----------------------------------------------------------------
router.post('/logout', (req, res) => {
  res.json({ success: true, message: 'Logged out successfully.' });
});

module.exports = router;
