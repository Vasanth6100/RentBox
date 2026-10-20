const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const { query } = require('../config/db');

const JWT_SECRET = process.env.JWT_SECRET || 'rentbox_super_secure_jwt_secret_key_2026_mumbai';

// Rate Limiter for Login endpoints (Prevents brute force attacks)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 15, // limit each IP to 15 login requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'Too many login attempts from this IP. Please try again after 15 minutes.'
  }
});

// Middleware to authenticate JWT token
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  let token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;

  // Also check query param token for web browser admin portals
  if (!token && req.query.token) {
    token = req.query.token;
  }

  if (!token) {
    return res.status(401).json({ success: false, error: 'Authentication token required.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    // Fetch fresh user record from MySQL to ensure account is not suspended
    const users = await query('SELECT id, name, email, role, status FROM users WHERE id = ?', [decoded.id]);
    if (!users || users.length === 0) {
      return res.status(401).json({ success: false, error: 'User account no longer exists.' });
    }

    const user = users[0];
    if (user.status === 'suspended') {
      return res.status(403).json({ success: false, error: 'Account has been suspended by administration.' });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(403).json({ success: false, error: 'Invalid or expired session token.' });
  }
};

// Middleware to require Admin privileges
const requireAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ success: false, error: 'Authentication required.' });
  }

  const role = req.user.role;
  if (role !== 'admin' && role !== 'super_admin') {
    return res.status(403).json({
      success: false,
      error: 'Forbidden: Restricted access. Platform Administrator privileges required.'
    });
  }

  next();
};

// Admin Audit Logging Helper
const recordAuditLog = async (adminId, adminName, action, targetEntity, targetId, details, req) => {
  try {
    const ip = req ? (req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1') : '127.0.0.1';
    await query(`
      INSERT INTO admin_audit_logs (admin_id, admin_name, action, target_entity, target_id, details, ip_address)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [adminId, adminName, action, targetEntity, targetId, details, ip]);
  } catch (err) {
    console.error('[RentBox Audit] Failed to write audit log:', err.message);
  }
};

module.exports = {
  loginLimiter,
  authenticateToken,
  requireAdmin,
  recordAuditLog,
  JWT_SECRET
};
