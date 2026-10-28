require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const { initDbConnection, isMySQL, query } = require('./config/db');
const { seedDatabase } = require('./scripts/seed');

// Import Route Handlers
const authRoutes = require('./routes/auth');
const listingRoutes = require('./routes/listings');
const bookingRoutes = require('./routes/bookings');
const adminRoutes = require('./routes/admin');
const categoryRoutes = require('./routes/categories');
const userRoutes = require('./routes/users');
const disputeRoutes = require('./routes/disputes');
const notificationRoutes = require('./routes/notifications');
const chatRoutes = require('./routes/chat');
const uploadRoutes = require('./routes/upload');
const appUpdateRoutes = require('./routes/app_update');

const app = express();
const PORT = process.env.PORT || 5000;

// Enable Cross-Origin Resource Sharing & Request Body Parsing
app.use(cors());
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));

// Serve Static Frontend Admin & App Assets
app.use(express.static(path.join(__dirname, 'public')));

// -------------------------------------------------------------
// HEALTH & DIAGNOSTICS ENDPOINT
// -------------------------------------------------------------
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    service: 'RentBox Mobile Backend & Admin REST API',
    database: isMySQL() ? 'MySQL 8.0 Community Server' : 'SQLite3 Fallback',
    version: '2.0.0',
    timestamp: new Date().toISOString()
  });
});

// Reseed endpoint for development & testing
app.post('/api/seed', async (req, res) => {
  try {
    await seedDatabase(true);
    res.json({ success: true, message: 'Database reseeded successfully with full demo data.' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// -------------------------------------------------------------
// MOUNT API ROUTES
// -------------------------------------------------------------
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

// Admin login convenience alias (accepts either /api/admin/login or /api/auth/admin-login)
app.post('/api/admin/login', (req, res, next) => {
  req.url = '/admin-login';
  authRoutes(req, res, next);
});

app.use('/api/listings', listingRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/users', userRoutes);
app.use('/api/disputes', disputeRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/app', appUpdateRoutes);

// Route fallback for Admin Web Portal
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// -------------------------------------------------------------
// 404 & ERROR HANDLING MIDDLEWARE
// -------------------------------------------------------------
app.use((req, res, next) => {
  if (req.path.startsWith('/api/')) {
    return res.status(404).json({ error: `Route not found: ${req.method} ${req.path}` });
  }
  next();
});

app.use((err, req, res, next) => {
  console.error('[RentBox Server] Unhandled error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal Server Error',
    message: err.message
  });
});

// -------------------------------------------------------------
// SERVER INITIALIZATION
// -------------------------------------------------------------
const startServer = async () => {
  try {
    await initDbConnection();

    app.listen(PORT, '0.0.0.0', () => {
      console.log('====================================================');
      console.log(`🚀 RentBox Backend running on http://localhost:${PORT}`);
      console.log(`📊 Admin Web Console: http://localhost:${PORT}/admin.html`);
      console.log(`🗄️  Database Engine: ${isMySQL() ? 'MySQL 8.0 (rentbox_db)' : 'SQLite3'}`);
      console.log('====================================================');
    });
  } catch (err) {
    console.error('[RentBox Server] Failed to start:', err);
    process.exit(1);
  }
};

startServer();

module.exports = app;
