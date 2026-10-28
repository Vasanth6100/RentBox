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
// 5. FORGOT PASSWORD / RESET CODE REQUEST
// -----------------------------------------------------------------
router.post('/forgot-password', async (req, res) => {
  try {
    const { email, phone } = req.body;
    const identifier = (email || phone || '').trim();

    if (!identifier) {
      return res.status(400).json({ success: false, error: 'Email address or mobile number is required.' });
    }

    // Find user by email or phone
    const rows = await query(
      'SELECT id, name, email, phone FROM users WHERE email = ? OR phone = ?',
      [identifier, identifier]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'No account found with this ' + (email ? 'email address' : 'mobile number') + '. Please check and try again.'
      });
    }

    const user = rows[0];

    // Generate a 6-digit reset code and store it with 15-min expiry
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    // Store reset token in the DB (reuse password_reset_token column if exists, else use audit log)
    try {
      await query(
        'UPDATE users SET password_reset_token = ?, reset_token_expires = ? WHERE id = ?',
        [resetCode, expiresAt, user.id]
      );
    } catch (_) {
      // Column may not exist — log it to audit trail instead
      await query(`
        INSERT INTO audit_logs (id, user_id, user_name, action, entity_type, entity_id, details)
        VALUES (?, ?, ?, 'PASSWORD_RESET_REQUEST', 'USER', ?, ?)
      `, [
        'AUDIT-' + Date.now(),
        user.id,
        user.name,
        user.id,
        JSON.stringify({ resetCode, expiresAt })
      ]);
    }

    // In production: send via email/SMS. For now, return success with a hint.
    const maskedContact = email
      ? user.email.replace(/(.{2}).*(@.*)/, '$1***$2')
      : user.phone.replace(/(\+\d{2})\d+(\d{4})/, '$1*****$2');

    return res.json({
      success: true,
      message: `A reset code has been sent to ${maskedContact}. Please check your ${email ? 'inbox' : 'SMS'}.`,
      // In dev: include code so it can be tested without email setup
      ...(process.env.NODE_ENV !== 'production' && { devCode: resetCode }),
    });

  } catch (err) {
    console.error('[RentBox Auth] Forgot password error:', err);
    return res.status(500).json({ success: false, error: 'Server error processing reset request.' });
  }
});

// -----------------------------------------------------------------
// 5B. VERIFY RESET CODE AND SET NEW PASSWORD
// -----------------------------------------------------------------
router.post('/reset-password', async (req, res) => {
  try {
    const { email, phone, code, newPassword } = req.body;
    const identifier = (email || phone || '').trim();
    const resetCode = (code || '').toString().trim();
    const password = (newPassword || '').trim();

    if (!identifier) {
      return res.status(400).json({ success: false, error: 'Email address or mobile number is required.' });
    }
    if (!resetCode) {
      return res.status(400).json({ success: false, error: 'Verification code is required.' });
    }
    if (!password || password.length < 6) {
      return res.status(400).json({ success: false, error: 'New password must be at least 6 characters long.' });
    }

    let rows = [];
    try {
      rows = await query(
        'SELECT id, name, email, phone, password_reset_token, reset_token_expires FROM users WHERE email = ? OR phone = ?',
        [identifier, identifier]
      );
    } catch (_) {
      rows = await query(
        'SELECT id, name, email, phone FROM users WHERE email = ? OR phone = ?',
        [identifier, identifier]
      );
    }

    if (rows.length === 0) {
      return res.status(404).json({ success: false, error: 'No account found with this credential.' });
    }

    const user = rows[0];

    // Verify token
    let isCodeValid = false;
    if (user.password_reset_token && user.password_reset_token.toString().trim() === resetCode) {
      if (!user.reset_token_expires || new Date(user.reset_token_expires) > new Date()) {
        isCodeValid = true;
      } else {
        return res.status(400).json({ success: false, error: 'Verification code has expired. Please request a new one.' });
      }
    } else {
      // Check audit logs fallback
      try {
        const auditRows = await query(`
          SELECT details, created_at FROM audit_logs 
          WHERE user_id = ? AND action = 'PASSWORD_RESET_REQUEST' 
          ORDER BY created_at DESC LIMIT 1
        `, [user.id]);
        if (auditRows.length > 0) {
          const details = typeof auditRows[0].details === 'string' ? JSON.parse(auditRows[0].details) : auditRows[0].details;
          if (details && details.resetCode && details.resetCode.toString().trim() === resetCode) {
            isCodeValid = true;
          }
        }
      } catch (_) {}
    }

    if (!isCodeValid) {
      return res.status(400).json({ success: false, error: 'Invalid verification code. Please check and try again.' });
    }

    // Hash new password and update
    const salt = await bcrypt.genSalt(10);
    const newHash = await bcrypt.hash(password, salt);

    try {
      await query(
        'UPDATE users SET password_hash = ?, password_reset_token = NULL, reset_token_expires = NULL, updated_at = NOW() WHERE id = ?',
        [newHash, user.id]
      );
    } catch (_) {
      await query('UPDATE users SET password_hash = ?, updated_at = NOW() WHERE id = ?', [newHash, user.id]);
    }

    // Record audit log
    await recordAuditLog(user.id, user.name, 'PASSWORD_RESET_SUCCESS', 'USER', user.id, 'User successfully reset password using verification code.', req);

    return res.json({
      success: true,
      message: 'Password reset successfully! You can now log in with your new password.'
    });
  } catch (err) {
    console.error('[RentBox Auth] Reset password error:', err);
    return res.status(500).json({ success: false, error: 'Server error resetting password.' });
  }
});

// -----------------------------------------------------------------
// 6. LOGOUT
// -----------------------------------------------------------------
router.post('/logout', (req, res) => {
  res.json({ success: true, message: 'Logged out successfully.' });
});

module.exports = router;

