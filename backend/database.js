const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const dbDir = path.join(__dirname, 'data');
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

const dbPath = path.join(dbDir, 'rentbox.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Failed to connect to SQLite database:', err);
  } else {
    console.log(`[RentBox DB] SQLite database connected at: ${dbPath}`);
  }
});

// Helper for promises
const runQuery = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
};

const getRow = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
};

const getAll = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

// Initialize schema
const initDatabase = async () => {
  await runQuery(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      phone TEXT,
      role TEXT NOT NULL DEFAULT 'customer',
      avatarUrl TEXT,
      location TEXT,
      isVerified INTEGER DEFAULT 1,
      kycStatus TEXT DEFAULT 'verified',
      idDocumentType TEXT,
      rating REAL DEFAULT 4.9,
      reviewsCount INTEGER DEFAULT 0,
      joinedDate TEXT,
      favoriteListingIds TEXT DEFAULT '[]',
      password TEXT DEFAULT 'password123'
    )
  `);

  await runQuery(`
    CREATE TABLE IF NOT EXISTS listings (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      pricePerDay REAL NOT NULL,
      originalPrice REAL,
      securityDeposit REAL NOT NULL,
      location TEXT NOT NULL,
      description TEXT NOT NULL,
      features TEXT DEFAULT '[]',
      includedAccessories TEXT DEFAULT '[]',
      imageUrls TEXT DEFAULT '[]',
      ownerId TEXT NOT NULL,
      ownerName TEXT NOT NULL,
      ownerAvatar TEXT,
      ownerRating REAL DEFAULT 4.9,
      ownerReviewsCount INTEGER DEFAULT 12,
      isInstantBooking INTEGER DEFAULT 1,
      deliveryCharge REAL DEFAULT 0,
      minRentDays INTEGER DEFAULT 1,
      maxRentDays INTEGER DEFAULT 30,
      status TEXT NOT NULL DEFAULT 'active',
      rejectionReason TEXT,
      rating REAL DEFAULT 4.9,
      totalRentals INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  `);

  await runQuery(`
    CREATE TABLE IF NOT EXISTS bookings (
      id TEXT PRIMARY KEY,
      listingId TEXT NOT NULL,
      listingTitle TEXT NOT NULL,
      listingImage TEXT,
      renterId TEXT NOT NULL,
      renterName TEXT NOT NULL,
      ownerId TEXT NOT NULL,
      ownerName TEXT NOT NULL,
      startDate TEXT NOT NULL,
      endDate TEXT NOT NULL,
      durationDays INTEGER NOT NULL,
      fulfillmentMethod TEXT NOT NULL,
      protectionPlan TEXT NOT NULL,
      dailyRate REAL NOT NULL,
      rentalFee REAL NOT NULL,
      securityDeposit REAL NOT NULL,
      deliveryFee REAL NOT NULL,
      protectionFee REAL NOT NULL,
      taxes REAL NOT NULL,
      totalPayable REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'upcoming',
      pickupCode TEXT NOT NULL,
      paymentMethod TEXT NOT NULL DEFAULT 'UPI',
      paymentStatus TEXT NOT NULL DEFAULT 'Paid',
      location TEXT,
      createdAt TEXT NOT NULL
    )
  `);

  await runQuery(`
    CREATE TABLE IF NOT EXISTS disputes (
      id TEXT PRIMARY KEY,
      caseId TEXT NOT NULL,
      bookingId TEXT NOT NULL,
      itemTitle TEXT NOT NULL,
      renterName TEXT NOT NULL,
      ownerName TEXT NOT NULL,
      reason TEXT NOT NULL,
      description TEXT NOT NULL,
      amountInvolved REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'open',
      resolution TEXT,
      adminNotes TEXT,
      createdAt TEXT NOT NULL
    )
  `);

  await runQuery(`
    CREATE TABLE IF NOT EXISTS reviews (
      id TEXT PRIMARY KEY,
      listingId TEXT NOT NULL,
      userName TEXT NOT NULL,
      userAvatar TEXT,
      rating REAL NOT NULL,
      comment TEXT NOT NULL,
      date TEXT NOT NULL
    )
  `);

  await runQuery(`
    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      userId TEXT DEFAULT 'USER-1',
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      type TEXT NOT NULL,
      isRead INTEGER DEFAULT 0,
      timestamp TEXT NOT NULL
    )
  `);

  await runQuery(`
    CREATE TABLE IF NOT EXISTS chat_conversations (
      id TEXT PRIMARY KEY,
      listingId TEXT NOT NULL,
      listingTitle TEXT NOT NULL,
      otherUserId TEXT NOT NULL,
      otherUserName TEXT NOT NULL,
      otherUserAvatar TEXT,
      lastMessage TEXT,
      lastMessageTime TEXT NOT NULL
    )
  `);

  await runQuery(`
    CREATE TABLE IF NOT EXISTS chat_messages (
      id TEXT PRIMARY KEY,
      conversationId TEXT NOT NULL,
      senderId TEXT NOT NULL,
      text TEXT NOT NULL,
      timestamp TEXT NOT NULL
    )
  `);

  console.log('[RentBox DB] Tables verified/created.');
};

// Seed default data if empty
const seedDatabase = async (force = false) => {
  const userCount = await getRow('SELECT COUNT(*) as cnt FROM users');
  if (userCount && userCount.cnt > 0 && !force) {
    console.log('[RentBox DB] Database already contains data. Skipping initial seeding.');
    return;
  }

  if (force) {
    await runQuery('DELETE FROM chat_messages');
    await runQuery('DELETE FROM chat_conversations');
    await runQuery('DELETE FROM notifications');
    await runQuery('DELETE FROM reviews');
    await runQuery('DELETE FROM disputes');
    await runQuery('DELETE FROM bookings');
    await runQuery('DELETE FROM listings');
    await runQuery('DELETE FROM users');
  }

  console.log('[RentBox DB] Seeding initial marketplace data...');

  // 1. Seed Users
  const users = [
    {
      id: 'USER-1',
      name: 'Alex Johnson',
      email: 'alex.rentbox@gmail.com',
      phone: '+91 98765 43210',
      role: 'customer',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      location: 'Bandra West, Mumbai',
      isVerified: 1,
      kycStatus: 'verified',
      idDocumentType: 'Aadhaar Card',
      rating: 4.9,
      reviewsCount: 14,
      joinedDate: 'Jan 2024',
      favoriteListingIds: JSON.stringify(['item-1', 'item-4']),
      password: 'password123'
    },
    {
      id: 'USER-ADMIN',
      name: 'RentBox Master Admin',
      email: 'admin@rentbox.io',
      phone: '+91 99000 88776',
      role: 'admin',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      location: 'RentBox HQ, Mumbai',
      isVerified: 1,
      kycStatus: 'verified',
      idDocumentType: 'Official Government ID',
      rating: 5.0,
      reviewsCount: 99,
      joinedDate: 'Dec 2023',
      favoriteListingIds: JSON.stringify([]),
      password: 'admin'
    },
    {
      id: 'OWNER-2',
      name: 'Priya Sharma',
      email: 'priya.s@gearhub.in',
      phone: '+91 98221 12345',
      role: 'owner',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      location: 'Koramangala, Bengaluru',
      isVerified: 1,
      kycStatus: 'verified',
      idDocumentType: 'Passport',
      rating: 4.9,
      reviewsCount: 28,
      joinedDate: 'Feb 2024',
      favoriteListingIds: JSON.stringify([]),
      password: 'password123'
    },
    {
      id: 'OWNER-3',
      name: 'Rahul Verma',
      email: 'rahul.v@soundlabs.com',
      phone: '+91 97110 56789',
      role: 'owner',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      location: 'Indiranagar, Bengaluru',
      isVerified: 1,
      kycStatus: 'pending',
      idDocumentType: 'Driving License',
      rating: 4.8,
      reviewsCount: 19,
      joinedDate: 'Mar 2024',
      favoriteListingIds: JSON.stringify([]),
      password: 'password123'
    }
  ];

  for (const u of users) {
    await runQuery(
      `INSERT INTO users (id, name, email, phone, role, avatarUrl, location, isVerified, kycStatus, idDocumentType, rating, reviewsCount, joinedDate, favoriteListingIds, password)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [u.id, u.name, u.email, u.phone, u.role, u.avatarUrl, u.location, u.isVerified, u.kycStatus, u.idDocumentType, u.rating, u.reviewsCount, u.joinedDate, u.favoriteListingIds, u.password]
    );
  }

  // 2. Seed Listings
  const listings = [
    {
      id: 'item-1',
      title: 'Sony Alpha A7 IV Full-Frame Camera + 24-70mm Lens',
      category: 'Electronics',
      pricePerDay: 1200,
      originalPrice: 1500,
      securityDeposit: 3500,
      location: 'Bandra West, Mumbai (1.2 km away)',
      description: 'Professional 33MP full-frame hybrid camera with 4K 60p 10-bit video, real-time eye autofocus, 2 battery packs, 128GB Pro V90 SD card, and Sony GM 24-70mm f/2.8 lens. Sanitized and ready for shoots.',
      features: JSON.stringify(['33MP Full-Frame Exmor R Sensor', '4K 60p 10-bit 4:2:2 Video', 'Dual SD Card Slots', '2 Extra Batteries + Fast Charger', 'Rugged Waterproof Bag']),
      includedAccessories: JSON.stringify(['Sony FE 24-70mm f/2.8 GM Lens', 'Lens Hood & UV Filter', '2x Sony NP-FZ100 Batteries', 'Sandisk 128GB Extreme Pro Card', 'Padded Shoulder Case']),
      imageUrls: JSON.stringify([
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
        'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=800',
        'https://images.unsplash.com/photo-1512790182412-b19e6d62bc39?w=800'
      ]),
      ownerId: 'OWNER-2',
      ownerName: 'Priya Sharma',
      ownerAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      ownerRating: 4.95,
      ownerReviewsCount: 34,
      isInstantBooking: 1,
      deliveryCharge: 150,
      minRentDays: 1,
      maxRentDays: 14,
      status: 'active',
      rejectionReason: null,
      rating: 4.9,
      totalRentals: 42,
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 30).toISOString()
    },
    {
      id: 'item-2',
      title: 'PlayStation 5 Console + 2 DualSense Controllers + 5 Games',
      category: 'Gaming',
      pricePerDay: 499,
      originalPrice: 650,
      securityDeposit: 2000,
      location: 'Andheri East, Mumbai (3.5 km away)',
      description: 'Next-gen PS5 825GB console with ultra-high speed SSD, ray tracing, 3D audio, 2 wireless controllers, HDMI 2.1 cable, and pre-installed games including Spider-Man 2, FIFA 24, and God of War Ragnarok.',
      features: JSON.stringify(['Ultra-High Speed SSD', 'Ray Tracing & 120fps Support', '2 Wireless DualSense Controllers', 'Top 5 AAA Games Included', 'Original Sony Box']),
      includedAccessories: JSON.stringify(['2x DualSense Controllers', 'HDMI 2.1 Cable', 'Power Cord', 'Dual Controller Charging Dock']),
      imageUrls: JSON.stringify([
        'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800',
        'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=800'
      ]),
      ownerId: 'OWNER-3',
      ownerName: 'Rahul Verma',
      ownerAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      ownerRating: 4.88,
      ownerReviewsCount: 22,
      isInstantBooking: 1,
      deliveryCharge: 100,
      minRentDays: 2,
      maxRentDays: 20,
      status: 'active',
      rejectionReason: null,
      rating: 4.8,
      totalRentals: 19,
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 18).toISOString()
    },
    {
      id: 'item-3',
      title: 'DJI Mini 4 Pro Drone + Fly More Combo (4K HDR)',
      category: 'Drones',
      pricePerDay: 950,
      originalPrice: 1200,
      securityDeposit: 3000,
      location: 'Juhu, Mumbai (2.1 km away)',
      description: 'Ultra-lightweight under 249g drone with omnidirectional obstacle sensing, 4K/60fps HDR True Vertical shooting, 34-min flight time per battery, and DJI RC 2 controller with 5.5-inch FHD screen.',
      features: JSON.stringify(['Omnidirectional Active Obstacle Sensing', '4K/60fps HDR True Vertical Shooting', '3 Intelligent Flight Batteries', 'DJI RC 2 Smart Controller', 'Up to 20km HD Video Transmission']),
      includedAccessories: JSON.stringify(['3x Flight Batteries', 'Two-Way Charging Hub', 'DJI RC 2 Controller', 'Shoulder Bag', 'Spare Propellers']),
      imageUrls: JSON.stringify([
        'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?w=800',
        'https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=800'
      ]),
      ownerId: 'OWNER-2',
      ownerName: 'Priya Sharma',
      ownerAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      ownerRating: 4.95,
      ownerReviewsCount: 34,
      isInstantBooking: 1,
      deliveryCharge: 120,
      minRentDays: 1,
      maxRentDays: 7,
      status: 'active',
      rejectionReason: null,
      rating: 4.95,
      totalRentals: 27,
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 12).toISOString()
    },
    {
      id: 'item-4',
      title: 'Quechua 4-Person Waterproof Camping Tent + Sleeping Bags + Stove',
      category: 'Camping',
      pricePerDay: 350,
      originalPrice: 450,
      securityDeposit: 1000,
      location: 'Powai, Mumbai (5.0 km away)',
      description: 'Complete weekend adventure kit! Weatherproof 4-person setup, 2 thermal sleeping bags (-5°C rating), portable butane camping burner, and solar-powered LED lantern.',
      features: JSON.stringify(['Quick 10-Minute Pitching', 'Wind Resistance up to 50 km/h', '2 Ergonomic Sleeping Bags', 'Portable Cooking Stove', 'Compact Carry Bags']),
      includedAccessories: JSON.stringify(['Tent Pegs & Guy Lines', 'Butane Gas Canister', 'Rechargeable LED Lantern', 'Ground Mat']),
      imageUrls: JSON.stringify([
        'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=800',
        'https://images.unsplash.com/photo-1523987355523-c7b5b0dd90a7?w=800'
      ]),
      ownerId: 'USER-1',
      ownerName: 'Alex Johnson',
      ownerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      ownerRating: 4.9,
      ownerReviewsCount: 14,
      isInstantBooking: 1,
      deliveryCharge: 90,
      minRentDays: 2,
      maxRentDays: 10,
      status: 'active',
      rejectionReason: null,
      rating: 4.75,
      totalRentals: 15,
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 25).toISOString()
    },
    {
      id: 'item-5',
      title: 'DeWalt 20V Max Cordless Drill Driver Kit + 100-pc Bit Set',
      category: 'Tools',
      pricePerDay: 250,
      originalPrice: 350,
      securityDeposit: 800,
      location: 'Dadar, Mumbai (4.2 km away)',
      description: 'Heavy duty brushless drill driver with 2x 20V Lithium batteries, rapid charger, magnetic bit holder, and full multi-material drilling/screwdriving set.',
      features: JSON.stringify(['Brushless High-Torque Motor', '2-Speed Transmission (0-450 / 0-1500 RPM)', '2x 2.0Ah XR Batteries', 'Heavy Duty Hard Shell Case']),
      includedAccessories: JSON.stringify(['100-pc Driver Bit Set', 'Fast Charger', 'Belt Hook', 'Safety Goggles']),
      imageUrls: JSON.stringify([
        'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=800'
      ]),
      ownerId: 'OWNER-3',
      ownerName: 'Rahul Verma',
      ownerAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      ownerRating: 4.88,
      ownerReviewsCount: 22,
      isInstantBooking: 1,
      deliveryCharge: 60,
      minRentDays: 1,
      maxRentDays: 15,
      status: 'active',
      rejectionReason: null,
      rating: 4.6,
      totalRentals: 6,
      createdAt: new Date().toISOString()
    },
    {
      id: 'item-6',
      title: 'Apple MacBook Pro 16" M3 Max (36GB RAM / 1TB SSD)',
      category: 'Electronics',
      pricePerDay: 1800,
      originalPrice: 2200,
      securityDeposit: 6000,
      location: 'BKC, Mumbai (2.8 km away)',
      description: 'Ultimate powerhouse for video rendering, 3D animation, and heavy software development. Liquid Retina XDR display, 140W MagSafe charger, and protective sleeve.',
      features: JSON.stringify(['Apple M3 Max 14-Core CPU / 30-Core GPU', '36GB Unified Memory', '1TB Ultra-Fast SSD', 'Liquid Retina XDR 120Hz ProMotion', '22-Hour Battery Life']),
      includedAccessories: JSON.stringify(['140W USB-C Power Adapter', 'MagSafe 3 Braided Cable', 'Incase Protective Sleeve']),
      imageUrls: JSON.stringify([
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800'
      ]),
      ownerId: 'OWNER-2',
      ownerName: 'Priya Sharma',
      ownerAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      ownerRating: 4.95,
      ownerReviewsCount: 34,
      isInstantBooking: 1,
      deliveryCharge: 180,
      minRentDays: 3,
      maxRentDays: 30,
      status: 'active',
      rejectionReason: null,
      rating: 5.0,
      totalRentals: 8,
      createdAt: new Date().toISOString()
    }
  ];

  for (const l of listings) {
    await runQuery(
      `INSERT INTO listings (id, title, category, pricePerDay, originalPrice, securityDeposit, location, description, features, includedAccessories, imageUrls, ownerId, ownerName, ownerAvatar, ownerRating, ownerReviewsCount, isInstantBooking, deliveryCharge, minRentDays, maxRentDays, status, rejectionReason, rating, totalRentals, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        l.id, l.title, l.category, l.pricePerDay, l.originalPrice, l.securityDeposit,
        l.location, l.description, l.features, l.includedAccessories, l.imageUrls,
        l.ownerId, l.ownerName, l.ownerAvatar, l.ownerRating, l.ownerReviewsCount,
        l.isInstantBooking, l.deliveryCharge, l.minRentDays, l.maxRentDays,
        l.status, l.rejectionReason, l.rating, l.totalRentals, l.createdAt
      ]
    );
  }

  // 3. Seed Bookings
  const bookings = [
    {
      id: 'RB-984210',
      listingId: 'item-1',
      listingTitle: 'Sony Alpha A7 IV Full-Frame Camera + 24-70mm Lens',
      listingImage: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
      renterId: 'USER-1',
      renterName: 'Alex Johnson',
      ownerId: 'OWNER-2',
      ownerName: 'Priya Sharma',
      startDate: new Date(Date.now() + 1000 * 60 * 60 * 24 * 2).toISOString(),
      endDate: new Date(Date.now() + 1000 * 60 * 60 * 24 * 5).toISOString(),
      durationDays: 3,
      fulfillmentMethod: 'selfPickup',
      protectionPlan: 'standard',
      dailyRate: 1200,
      rentalFee: 3600,
      securityDeposit: 3500,
      deliveryFee: 0,
      protectionFee: 99,
      taxes: 180,
      totalPayable: 7379,
      status: 'upcoming',
      pickupCode: 'RB-4829',
      paymentMethod: 'UPI (Google Pay)',
      paymentStatus: 'Paid',
      location: 'Bandra West, Mumbai',
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 8).toISOString()
    },
    {
      id: 'RB-821940',
      listingId: 'item-2',
      listingTitle: 'PlayStation 5 Console + 2 DualSense Controllers + 5 Games',
      listingImage: 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800',
      renterId: 'USER-1',
      renterName: 'Alex Johnson',
      ownerId: 'OWNER-3',
      ownerName: 'Rahul Verma',
      startDate: new Date(Date.now() - 1000 * 60 * 60 * 24 * 2).toISOString(),
      endDate: new Date(Date.now() + 1000 * 60 * 60 * 24 * 1).toISOString(),
      durationDays: 3,
      fulfillmentMethod: 'ownerDelivery',
      protectionPlan: 'basic',
      dailyRate: 499,
      rentalFee: 1497,
      securityDeposit: 2000,
      deliveryFee: 100,
      protectionFee: 49,
      taxes: 75,
      totalPayable: 3721,
      status: 'ongoing',
      pickupCode: 'RB-8291',
      paymentMethod: 'Credit Card',
      paymentStatus: 'Paid',
      location: 'Andheri East, Mumbai',
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 3).toISOString()
    },
    {
      id: 'RB-716492',
      listingId: 'item-4',
      listingTitle: 'Quechua 4-Person Waterproof Camping Tent + Sleeping Bags + Stove',
      listingImage: 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=800',
      renterId: 'OWNER-3',
      renterName: 'Rahul Verma',
      ownerId: 'USER-1',
      ownerName: 'Alex Johnson',
      startDate: new Date(Date.now() - 1000 * 60 * 60 * 24 * 10).toISOString(),
      endDate: new Date(Date.now() - 1000 * 60 * 60 * 24 * 7).toISOString(),
      durationDays: 3,
      fulfillmentMethod: 'selfPickup',
      protectionPlan: 'standard',
      dailyRate: 350,
      rentalFee: 1050,
      securityDeposit: 1000,
      deliveryFee: 0,
      protectionFee: 99,
      taxes: 52,
      totalPayable: 2201,
      status: 'completed',
      pickupCode: 'RB-9104',
      paymentMethod: 'UPI',
      paymentStatus: 'Paid & Deposit Returned',
      location: 'Powai, Mumbai',
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 12).toISOString()
    }
  ];

  for (const b of bookings) {
    await runQuery(
      `INSERT INTO bookings (id, listingId, listingTitle, listingImage, renterId, renterName, ownerId, ownerName, startDate, endDate, durationDays, fulfillmentMethod, protectionPlan, dailyRate, rentalFee, securityDeposit, deliveryFee, protectionFee, taxes, totalPayable, status, pickupCode, paymentMethod, paymentStatus, location, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        b.id, b.listingId, b.listingTitle, b.listingImage, b.renterId, b.renterName,
        b.ownerId, b.ownerName, b.startDate, b.endDate, b.durationDays, b.fulfillmentMethod,
        b.protectionPlan, b.dailyRate, b.rentalFee, b.securityDeposit, b.deliveryFee,
        b.protectionFee, b.taxes, b.totalPayable, b.status, b.pickupCode, b.paymentMethod,
        b.paymentStatus, b.location, b.createdAt
      ]
    );
  }

  // 4. Seed Disputes
  const disputes = [
    {
      id: 'DISP-101',
      caseId: 'CASE-001',
      bookingId: 'RB-821940',
      itemTitle: 'PlayStation 5 Console',
      renterName: 'Alex Johnson',
      ownerName: 'Rahul Verma',
      reason: 'HDMI cable connector loose upon arrival',
      description: 'The package arrived on time, but the HDMI port on the back cuts out when bumped. Requesting owner to provide replacement HDMI cord.',
      amountInvolved: 499.0,
      status: 'underReview',
      resolution: null,
      adminNotes: 'Contacted owner Rahul; replacement ultra-speed HDMI cable dispatched via Dunzo.',
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 20).toISOString()
    }
  ];

  for (const d of disputes) {
    await runQuery(
      `INSERT INTO disputes (id, caseId, bookingId, itemTitle, renterName, ownerName, reason, description, amountInvolved, status, resolution, adminNotes, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [d.id, d.caseId, d.bookingId, d.itemTitle, d.renterName, d.ownerName, d.reason, d.description, d.amountInvolved, d.status, d.resolution, d.adminNotes, d.createdAt]
    );
  }

  // 5. Seed Reviews
  const reviews = [
    {
      id: 'REV-1',
      listingId: 'item-1',
      userName: 'Siddharth M.',
      userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
      rating: 5.0,
      comment: 'Top tier gear! Shot a full commercial with this A7 IV. Priya maintained the sensor flawlessly with zero dust spots.',
      date: '3 days ago'
    },
    {
      id: 'REV-2',
      listingId: 'item-1',
      userName: 'Kavita Iyer',
      userAvatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
      rating: 4.8,
      comment: 'Super easy handoff. Included two fast chargers and great lenses. Will rent again next weekend.',
      date: '1 week ago'
    }
  ];

  for (const r of reviews) {
    await runQuery(
      `INSERT INTO reviews (id, listingId, userName, userAvatar, rating, comment, date)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [r.id, r.listingId, r.userName, r.userAvatar, r.rating, r.comment, r.date]
    );
  }

  // 6. Seed Notifications
  const notifications = [
    {
      id: 'NOTIF-1',
      userId: 'USER-1',
      title: 'Booking Confirmed! 📦',
      message: 'Your rental for Sony Alpha A7 IV is confirmed. Pickup Code: RB-4829',
      type: 'booking',
      isRead: 0,
      timestamp: new Date(Date.now() - 1000 * 60 * 30).toISOString()
    },
    {
      id: 'NOTIF-2',
      userId: 'USER-1',
      title: 'Welcome to RentBox Mumbai! 🎉',
      message: 'Your account is verified. Enjoy zero security deposit on select verified community items.',
      type: 'general',
      isRead: 1,
      timestamp: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString()
    }
  ];

  for (const n of notifications) {
    await runQuery(
      `INSERT INTO notifications (id, userId, title, message, type, isRead, timestamp)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [n.id, n.userId, n.title, n.message, n.type, n.isRead, n.timestamp]
    );
  }

  // 7. Seed Chat Conversations
  const convs = [
    {
      id: 'CONV-1',
      listingId: 'item-1',
      listingTitle: 'Sony Alpha A7 IV Full-Frame Camera',
      otherUserId: 'OWNER-2',
      otherUserName: 'Priya Sharma',
      otherUserAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      lastMessage: 'Awesome! Both extra batteries are fully charged and ready.',
      lastMessageTime: new Date(Date.now() - 1000 * 60 * 45).toISOString()
    }
  ];

  for (const c of convs) {
    await runQuery(
      `INSERT INTO chat_conversations (id, listingId, listingTitle, otherUserId, otherUserName, otherUserAvatar, lastMessage, lastMessageTime)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [c.id, c.listingId, c.listingTitle, c.otherUserId, c.otherUserName, c.otherUserAvatar, c.lastMessage, c.lastMessageTime]
    );
  }

  // 8. Seed Chat Messages
  const messages = [
    {
      id: 'MSG-1',
      conversationId: 'CONV-1',
      senderId: 'USER-1',
      text: 'Hi Priya, does the kit come with the dual battery charger?',
      timestamp: new Date(Date.now() - 1000 * 60 * 60).toISOString()
    },
    {
      id: 'MSG-2',
      conversationId: 'CONV-1',
      senderId: 'OWNER-2',
      text: 'Yes Alex, dual charger plus 2 high-capacity batteries are packed in the case.',
      timestamp: new Date(Date.now() - 1000 * 60 * 50).toISOString()
    },
    {
      id: 'MSG-3',
      conversationId: 'CONV-1',
      senderId: 'OWNER-2',
      text: 'Awesome! Both extra batteries are fully charged and ready.',
      timestamp: new Date(Date.now() - 1000 * 60 * 45).toISOString()
    }
  ];

  for (const m of messages) {
    await runQuery(
      `INSERT INTO chat_messages (id, conversationId, senderId, text, timestamp)
       VALUES (?, ?, ?, ?, ?)`,
      [m.id, m.conversationId, m.senderId, m.text, m.timestamp]
    );
  }

  console.log('[RentBox DB] Seeding completed successfully!');
};

module.exports = {
  db,
  runQuery,
  getRow,
  getAll,
  initDatabase,
  seedDatabase
};
