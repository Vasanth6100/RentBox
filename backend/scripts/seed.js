const bcrypt = require('bcryptjs');
const { initDbConnection, query } = require('../config/db');

const seedDatabase = async (force = false) => {
  console.log('[RentBox Seed] Starting database seeding...');
  await initDbConnection();

  const existingUsers = await query('SELECT COUNT(*) as cnt FROM users');
  if (existingUsers && existingUsers[0] && existingUsers[0].cnt > 0 && !force) {
    console.log('[RentBox Seed] Database already contains records. Skipping seed (use force to re-seed).');
    return;
  }

  // Clear data if force
  if (force) {
    console.log('[RentBox Seed] Clearing existing records for clean seed...');
    await query('DELETE FROM admin_audit_logs');
    await query('DELETE FROM dispute_evidence');
    await query('DELETE FROM disputes');
    await query('DELETE FROM support_requests');
    await query('DELETE FROM chat_messages');
    await query('DELETE FROM chat_conversations');
    await query('DELETE FROM notifications');
    await query('DELETE FROM reviews');
    await query('DELETE FROM favourites');
    await query('DELETE FROM owner_payouts');
    await query('DELETE FROM refunds');
    await query('DELETE FROM security_deposits');
    await query('DELETE FROM payments');
    await query('DELETE FROM pickup_return_records');
    await query('DELETE FROM bookings');
    await query('DELETE FROM listing_approval_history');
    await query('DELETE FROM listing_availability');
    await query('DELETE FROM listing_included_items');
    await query('DELETE FROM product_specifications');
    await query('DELETE FROM listing_images');
    await query('DELETE FROM listings');
    await query('DELETE FROM categories');
    await query('DELETE FROM owner_verifications');
    await query('DELETE FROM role_permissions');
    await query('DELETE FROM permissions');
    await query('DELETE FROM roles');
    await query('DELETE FROM users');
    await query('DELETE FROM platform_settings');
  }

  // 1. Roles & Permissions
  console.log('[RentBox Seed] 1/12 Seeding Roles & Permissions...');
  await query(`
    INSERT INTO roles (id, name, description) VALUES
    (1, 'super_admin', 'Full platform administrative control'),
    (2, 'moderator', 'Listing and verification moderation access'),
    (3, 'owner', 'Equipment owner / lender'),
    (4, 'customer', 'Renter / customer')
    ON DUPLICATE KEY UPDATE name=VALUES(name)
  `);

  await query(`
    INSERT INTO permissions (id, permission_code, description) VALUES
    (1, 'listings:moderate', 'Approve, reject, or flag listings'),
    (2, 'kyc:verify', 'Review and approve owner documents'),
    (3, 'disputes:manage', 'Resolve disputes and handle escrow'),
    (4, 'users:suspend', 'Suspend or reactivate accounts'),
    (5, 'settings:edit', 'Configure platform rates and policies')
    ON DUPLICATE KEY UPDATE permission_code=VALUES(permission_code)
  `);

  await query(`
    INSERT INTO role_permissions (role_id, permission_id) VALUES
    (1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
    (2, 1), (2, 2), (2, 3)
    ON DUPLICATE KEY UPDATE role_id=VALUES(role_id)
  `);

  // 2. Users (Hashed Passwords with bcrypt)
  console.log('[RentBox Seed] 2/12 Seeding Users...');
  const salt = await bcrypt.genSalt(10);
  const adminHash = await bcrypt.hash('Admin@2026', salt);
  const userHash = await bcrypt.hash('RentBox@2026', salt);
  const defaultHash = await bcrypt.hash('password123', salt);

  const users = [
    {
      id: 'USER-ADMIN',
      name: 'RentBox Master Admin',
      email: 'admin@rentbox.in',
      phone: '+91 99000 88776',
      role: 'admin',
      avatar_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      location: 'RentBox Operations Hub, BKC, Mumbai',
      is_verified: 1,
      kyc_status: 'verified',
      id_document_type: 'Official Government ID',
      rating: 5.0,
      reviews_count: 99,
      password_hash: adminHash
    },
    {
      id: 'USER-1',
      name: 'Vasanth Kumar',
      email: 'vasanth@rentbox.in',
      phone: '+91 98765 43210',
      role: 'customer',
      avatar_url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      location: 'Bandra West, Mumbai',
      is_verified: 1,
      kyc_status: 'verified',
      id_document_type: 'Aadhaar Card',
      rating: 4.9,
      reviews_count: 14,
      password_hash: userHash
    },
    {
      id: 'OWNER-1',
      name: 'Vikram Shah',
      email: 'vikram.cams@gmail.com',
      phone: '+91 98111 22334',
      role: 'owner',
      avatar_url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      location: 'Andheri West, Mumbai',
      is_verified: 1,
      kyc_status: 'verified',
      id_document_type: 'Passport',
      rating: 4.95,
      reviews_count: 38,
      password_hash: defaultHash
    },
    {
      id: 'OWNER-2',
      name: 'Rohit Patil',
      email: 'rohit.gaming@gmail.com',
      phone: '+91 98222 33445',
      role: 'owner',
      avatar_url: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400',
      location: 'Powai, Mumbai',
      is_verified: 1,
      kyc_status: 'verified',
      id_document_type: 'Driving License',
      rating: 4.88,
      reviews_count: 22,
      password_hash: defaultHash
    },
    {
      id: 'OWNER-3',
      name: 'Priya Sen',
      email: 'priya.sound@gmail.com',
      phone: '+91 98333 44556',
      role: 'owner',
      avatar_url: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      location: 'Juhu, Mumbai',
      is_verified: 1,
      kyc_status: 'pending',
      id_document_type: 'Voter ID',
      rating: 4.70,
      reviews_count: 5,
      password_hash: defaultHash
    }
  ];

  for (const u of users) {
    await query(`
      INSERT INTO users (id, name, email, phone, role, avatar_url, location, is_verified, kyc_status, id_document_type, rating, reviews_count, password_hash)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE name=VALUES(name), password_hash=VALUES(password_hash), role=VALUES(role)
    `, [u.id, u.name, u.email, u.phone, u.role, u.avatar_url, u.location, u.is_verified, u.kyc_status, u.id_document_type, u.rating, u.reviews_count, u.password_hash]);
  }

  // 3. Owner Verification Records
  console.log('[RentBox Seed] 3/12 Seeding Owner KYC Verifications...');
  await query(`
    INSERT INTO owner_verifications (id, user_id, document_type, document_number, document_url, selfie_url, status, admin_feedback, reviewed_by, reviewed_at)
    VALUES
    ('KYC-1', 'OWNER-1', 'Passport', 'Z1234567', 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=600', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400', 'approved', 'Clear official document verified against Mumbai address.', 'USER-ADMIN', NOW()),
    ('KYC-2', 'OWNER-2', 'Driving License', 'MH-02-2018-0099', 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=600', 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400', 'approved', 'DL verified with valid address and selfie match.', 'USER-ADMIN', NOW()),
    ('KYC-3', 'OWNER-3', 'Voter ID', 'EPIC-MH88992', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400', 'pending', 'Pending document verification by staff.', NULL, NULL)
    ON DUPLICATE KEY UPDATE status=VALUES(status)
  `);

  // 4. Categories
  console.log('[RentBox Seed] 4/12 Seeding Product Categories...');
  const categories = [
    { id: 'cat-cameras', name: 'Cameras', slug: 'cameras', icon: 'camera_alt', min_deposit_rate: 25.0, platform_fee_percent: 10.0, display_order: 1 },
    { id: 'cat-gaming', name: 'Gaming', slug: 'gaming', icon: 'sports_esports', min_deposit_rate: 30.0, platform_fee_percent: 12.0, display_order: 2 },
    { id: 'cat-projectors', name: 'Projectors', slug: 'projectors', icon: 'videocam', min_deposit_rate: 20.0, platform_fee_percent: 10.0, display_order: 3 },
    { id: 'cat-audio', name: 'Audio', slug: 'audio', icon: 'speaker', min_deposit_rate: 15.0, platform_fee_percent: 8.0, display_order: 4 },
    { id: 'cat-tech', name: 'Tech & Drones', slug: 'tech', icon: 'devices_other', min_deposit_rate: 35.0, platform_fee_percent: 12.0, display_order: 5 },
    { id: 'cat-outdoor', name: 'Outdoor', slug: 'outdoor', icon: 'terrain', min_deposit_rate: 20.0, platform_fee_percent: 8.0, display_order: 6 }
  ];

  for (const c of categories) {
    await query(`
      INSERT INTO categories (id, name, slug, icon, min_deposit_rate, platform_fee_percent, display_order)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE name=VALUES(name)
    `, [c.id, c.name, c.slug, c.icon, c.min_deposit_rate, c.platform_fee_percent, c.display_order]);
  }

  // 5. Listings
  console.log('[RentBox Seed] 5/12 Seeding Listings & Relations...');
  const listings = [
    {
      id: 'item-1',
      title: 'Sony Alpha A7 IV (28-70mm Lens + 2 Batteries)',
      category: 'Cameras',
      category_id: 'cat-cameras',
      price_per_day: 1499.00,
      original_price: 2499.00,
      security_deposit: 6000.00,
      brand: 'Sony',
      model_name: 'ILCE-7M4',
      condition: 'Like New',
      description: 'Flagship full-frame mirrorless camera with 33MP sensor, 4K 60p 10-bit recording, dual SD card slots. Comes with 28-70mm f/3.5-5.6 OSS lens, two genuine Sony batteries, 128GB V90 high-speed memory card, and shoulder bag.',
      location: 'Bandra West, Mumbai',
      latitude: 19.0596,
      longitude: 72.8295,
      distance_km: 1.8,
      owner_id: 'OWNER-1',
      owner_name: 'Vikram Shah',
      owner_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      owner_rating: 4.95,
      owner_reviews_count: 38,
      status: 'active',
      images: [
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
        'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=800'
      ],
      specs: [
        ['Sensor', '33MP Full-Frame Exmor R CMOS'],
        ['Video', '4K 60p 10-bit 4:2:2'],
        ['Mount', 'Sony E-Mount'],
        ['Stabilization', '5-Axis In-Body SteadyShot']
      ],
      items: ['Sony A7 IV Body', '28-70mm Lens', '2x Original Batteries', 'Dual Charger', '128GB V90 SD Card', 'Padded Bag']
    },
    {
      id: 'item-2',
      title: 'Sony PlayStation 5 Disc Edition + 2 DualSense Controllers',
      category: 'Gaming',
      category_id: 'cat-gaming',
      price_per_day: 699.00,
      original_price: 1199.00,
      security_deposit: 4500.00,
      brand: 'Sony',
      model_name: 'PS5 Disc Edition 1TB',
      condition: 'Excellent',
      description: 'PS5 console loaded with Spider-Man 2, FIFA 24, and God of War Ragnarok. Includes 2 wireless DualSense haptic feedback controllers and ultra-high-speed HDMI 2.1 cable.',
      location: 'Powai, Mumbai',
      latitude: 19.1176,
      longitude: 72.9060,
      distance_km: 3.4,
      owner_id: 'OWNER-2',
      owner_name: 'Rohit Patil',
      owner_avatar: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400',
      owner_rating: 4.88,
      owner_reviews_count: 22,
      status: 'active',
      images: [
        'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800',
        'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=800'
      ],
      specs: [
        ['Storage', '1TB Ultra-High Speed NVMe SSD'],
        ['Resolution', '4K 120Hz & HDR Output'],
        ['Controllers', '2x DualSense Wireless']
      ],
      items: ['PS5 Disc Console', '2x DualSense Controllers', 'HDMI 2.1 Cable', 'Power Cord', 'Controller Charging Cable']
    },
    {
      id: 'item-3',
      title: 'DJI Mini 3 Pro Drone with Smart RC Controller & Fly More Kit',
      category: 'Tech & Drones',
      category_id: 'cat-tech',
      price_per_day: 1899.00,
      original_price: 2999.00,
      security_deposit: 8000.00,
      brand: 'DJI',
      model_name: 'Mini 3 Pro Smart RC',
      condition: 'Like New',
      description: 'Sub-249g ultra-light drone with obstacle sensing in 3 directions, 4K HDR video, true vertical shooting for social reels, 34-min battery life. Comes with built-in screen controller, 3 batteries, two-way charging hub, and ND filter kit.',
      location: 'Andheri West, Mumbai',
      latitude: 19.1363,
      longitude: 72.8277,
      distance_km: 2.1,
      owner_id: 'OWNER-1',
      owner_name: 'Vikram Shah',
      owner_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      owner_rating: 4.95,
      owner_reviews_count: 38,
      status: 'active',
      images: [
        'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?w=800',
        'https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=800'
      ],
      specs: [
        ['Weight', '249 grams'],
        ['Video Resolution', '4K 60fps HDR'],
        ['Range', 'Up to 12 km O3 Video Transmission']
      ],
      items: ['DJI Mini 3 Pro Drone', 'DJI RC Smart Controller', '3x Flight Batteries', 'Two-Way Charging Hub', 'ND Filters Kit', 'Carry Case']
    },
    {
      id: 'item-4',
      title: 'BenQ 4K HDR Home Theater Projector (3200 Lumens)',
      category: 'Projectors',
      category_id: 'cat-projectors',
      price_per_day: 899.00,
      original_price: 1599.00,
      security_deposit: 5000.00,
      brand: 'BenQ',
      model_name: 'TK850i 4K',
      condition: 'Good',
      description: 'Ultra-bright 3200 lumens projector with native 4K resolution, HDR-PRO, built-in Android TV, and dual 5W chamber speakers. Perfect for movie nights, sports events, and terrace presentations.',
      location: 'Juhu, Mumbai',
      latitude: 19.0988,
      longitude: 72.8264,
      distance_km: 2.7,
      owner_id: 'OWNER-3',
      owner_name: 'Priya Sen',
      owner_avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      owner_rating: 4.70,
      owner_reviews_count: 5,
      status: 'pendingApproval',
      images: [
        'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=800'
      ],
      specs: [
        ['Brightness', '3200 ANSI Lumens'],
        ['Resolution', 'True 4K UHD 3840x2160']
      ],
      items: ['BenQ 4K Projector', 'Remote Control', '10m High-Speed HDMI', 'Tripod Stand', 'Protective Case']
    },
    {
      id: 'item-5',
      title: 'JBL PartyBox 310 Portable Bluetooth Party Speaker with Wheels',
      category: 'Audio',
      category_id: 'cat-audio',
      price_per_day: 799.00,
      original_price: 1299.00,
      security_deposit: 4000.00,
      brand: 'JBL',
      model_name: 'PartyBox 310',
      condition: 'Excellent',
      description: '240W of powerful JBL Pro Sound, dynamic light sync show, 18 hours of battery life, telescopic handle and smooth glide wheels. Includes wireless microphone for karaoke and parties.',
      location: 'Bandra West, Mumbai',
      latitude: 19.0550,
      longitude: 72.8350,
      distance_km: 1.5,
      owner_id: 'OWNER-2',
      owner_name: 'Rohit Patil',
      owner_avatar: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400',
      owner_rating: 4.88,
      owner_reviews_count: 22,
      status: 'active',
      images: [
        'https://images.unsplash.com/photo-1545454675-3531b543be5d?w=800'
      ],
      specs: [
        ['Power Output', '240 Watts RMS'],
        ['Battery', '18 Hours Playtime'],
        ['Water Protection', 'IPX4 Splashproof']
      ],
      items: ['JBL PartyBox 310', 'Power Cord', 'JBL Wireless Microphone Kit']
    },
    {
      id: 'item-6',
      title: 'GoPro HERO 12 Black Creator Edition (Volta Grip + Light Mod)',
      category: 'Cameras',
      category_id: 'cat-cameras',
      price_per_day: 599.00,
      original_price: 999.00,
      security_deposit: 3500.00,
      brand: 'GoPro',
      model_name: 'HERO12 Black Creator',
      condition: 'Like New',
      description: '5.3K 60fps action camera with HyperSmooth 6.0 stabilization, HDR video, Volta battery grip with over 5 hours of 4K recording, directional audio mic, and compact LED light mod.',
      location: 'Andheri West, Mumbai',
      latitude: 19.1200,
      longitude: 72.8300,
      distance_km: 2.9,
      owner_id: 'OWNER-1',
      owner_name: 'Vikram Shah',
      owner_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      owner_rating: 4.95,
      owner_reviews_count: 38,
      status: 'pendingApproval',
      images: [
        'https://images.unsplash.com/photo-1564466809058-bf4114d55352?w=800'
      ],
      specs: [
        ['Video', '5.3K 60fps / 4K 120fps'],
        ['Waterproof', 'Up to 33ft (10m) naked']
      ],
      items: ['GoPro HERO12 Camera', 'Volta Battery Grip', 'Media Mod with Mic', 'Light Mod', '2x Enduro Batteries', '64GB Extreme Pro MicroSD']
    }
  ];

  for (const item of listings) {
    await query(`
      INSERT INTO listings (
        id, title, category, category_id, price_per_day, original_price, security_deposit,
        brand, model_name, \`condition\`, description, location, latitude, longitude,
        distance_km, owner_id, owner_name, owner_avatar, owner_rating, owner_reviews_count,
        status, rating, reviews_count, total_rentals
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 4.9, 12, 8)
      ON DUPLICATE KEY UPDATE title=VALUES(title), status=VALUES(status)
    `, [
      item.id, item.title, item.category, item.category_id, item.price_per_day, item.original_price,
      item.security_deposit, item.brand, item.model_name, item.condition, item.description,
      item.location, item.latitude, item.longitude, item.distance_km, item.owner_id,
      item.owner_name, item.owner_avatar, item.owner_rating, item.owner_reviews_count, item.status
    ]);

    // Images
    for (let i = 0; i < item.images.length; i++) {
      await query(`
        INSERT INTO listing_images (listing_id, image_url, is_primary, sort_order)
        VALUES (?, ?, ?, ?)
      `, [item.id, item.images[i], i === 0 ? 1 : 0, i]);
    }

    // Specifications
    for (const [key, val] of item.specs) {
      await query(`
        INSERT INTO product_specifications (listing_id, spec_key, spec_value)
        VALUES (?, ?, ?)
      `, [item.id, key, val]);
    }

    // Included Items
    for (const inc of item.items) {
      await query(`
        INSERT INTO listing_included_items (listing_id, item_name)
        VALUES (?, ?)
      `, [item.id, inc]);
    }
  }

  // 6. Favourites
  console.log('[RentBox Seed] 6/12 Seeding Favourites...');
  await query(`
    INSERT INTO favourites (user_id, listing_id)
    VALUES ('USER-1', 'item-1'), ('USER-1', 'item-2')
    ON DUPLICATE KEY UPDATE user_id=VALUES(user_id)
  `);

  // 7. Bookings
  console.log('[RentBox Seed] 7/12 Seeding Bookings & Payments...');
  const bookings = [
    {
      id: 'RB-BKG-101',
      listing_id: 'item-1',
      listing_title: 'Sony Alpha A7 IV (28-70mm Lens + 2 Batteries)',
      listing_image: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
      renter_id: 'USER-1',
      renter_name: 'Vasanth Kumar',
      owner_id: 'OWNER-1',
      owner_name: 'Vikram Shah',
      start_date: '2026-10-25',
      end_date: '2026-10-27',
      duration_days: 2,
      daily_rate: 1499.00,
      rental_fee: 2998.00,
      security_deposit: 6000.00,
      delivery_fee: 0.00,
      protection_fee: 99.00,
      platform_fee: 299.80,
      total_payable: 9097.00,
      status: 'upcoming',
      pickup_code: 'RB-8291',
      payment_method: 'UPI / GPay',
      payment_status: 'Paid',
      location: 'Bandra West, Mumbai'
    },
    {
      id: 'RB-BKG-102',
      listing_id: 'item-2',
      listing_title: 'Sony PlayStation 5 Disc Edition + 2 DualSense Controllers',
      listing_image: 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800',
      renter_id: 'USER-1',
      renter_name: 'Vasanth Kumar',
      owner_id: 'OWNER-2',
      owner_name: 'Rohit Patil',
      start_date: '2026-10-18',
      end_date: '2026-10-22',
      duration_days: 4,
      daily_rate: 699.00,
      rental_fee: 2796.00,
      security_deposit: 4500.00,
      delivery_fee: 150.00,
      protection_fee: 99.00,
      platform_fee: 279.60,
      total_payable: 7545.00,
      status: 'active',
      pickup_code: 'RB-3304',
      payment_method: 'Credit Card',
      payment_status: 'Paid',
      location: 'Powai, Mumbai'
    },
    {
      id: 'RB-BKG-103',
      listing_id: 'item-5',
      listing_title: 'JBL PartyBox 310 Portable Bluetooth Party Speaker with Wheels',
      listing_image: 'https://images.unsplash.com/photo-1545454675-3531b543be5d?w=800',
      renter_id: 'USER-1',
      renter_name: 'Vasanth Kumar',
      owner_id: 'OWNER-2',
      owner_name: 'Rohit Patil',
      start_date: '2026-10-10',
      end_date: '2026-10-12',
      duration_days: 2,
      daily_rate: 799.00,
      rental_fee: 1598.00,
      security_deposit: 4000.00,
      delivery_fee: 0.00,
      protection_fee: 99.00,
      platform_fee: 159.80,
      total_payable: 5697.00,
      status: 'completed',
      pickup_code: 'RB-4912',
      payment_method: 'UPI',
      payment_status: 'Paid',
      location: 'Bandra West, Mumbai'
    }
  ];

  for (const b of bookings) {
    await query(`
      INSERT INTO bookings (
        id, listing_id, listing_title, listing_image, renter_id, renter_name,
        owner_id, owner_name, start_date, end_date, duration_days, daily_rate,
        rental_fee, security_deposit, delivery_fee, protection_fee, platform_fee,
        total_payable, status, pickup_code, payment_method, payment_status, location
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE status=VALUES(status)
    `, [
      b.id, b.listing_id, b.listing_title, b.listing_image, b.renter_id, b.renter_name,
      b.owner_id, b.owner_name, b.start_date, b.end_date, b.duration_days, b.daily_rate,
      b.rental_fee, b.security_deposit, b.delivery_fee, b.protection_fee, b.platform_fee,
      b.total_payable, b.status, b.pickup_code, b.payment_method, b.payment_status, b.location
    ]);

    // Payment Record
    await query(`
      INSERT INTO payments (id, booking_id, transaction_ref, payment_gateway, amount, rental_portion, deposit_portion, platform_fee_portion, status)
      VALUES (?, ?, ?, 'Razorpay', ?, ?, ?, ?, 'captured')
      ON DUPLICATE KEY UPDATE status=VALUES(status)
    `, [
      'PAY-' + b.id, b.id, 'TXN_RZP_' + b.id, b.total_payable, b.rental_fee, b.security_deposit, b.platform_fee
    ]);

    // Escrow Security Deposit Record
    const depositStatus = b.status === 'completed' ? 'refunded_full' : 'held_in_escrow';
    await query(`
      INSERT INTO security_deposits (id, booking_id, renter_id, deposit_amount, status, refunded_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE status=VALUES(status)
    `, [
      'DEP-' + b.id, b.id, b.renter_id, b.security_deposit, depositStatus, b.status === 'completed' ? new Date() : null
    ]);

    // If completed, record refund of security deposit
    if (b.status === 'completed') {
      await query(`
        INSERT INTO refunds (id, payment_id, booking_id, refund_type, amount, reason, status)
        VALUES (?, ?, ?, 'deposit_refund', ?, 'Automatic deposit release after zero-damage return inspection.', 'processed')
        ON DUPLICATE KEY UPDATE status=VALUES(status)
      `, ['REF-DEP-' + b.id, 'PAY-' + b.id, b.id, b.security_deposit]);

      // Owner Payout
      await query(`
        INSERT INTO owner_payouts (id, owner_id, booking_id, gross_amount, platform_fee, net_payout, payout_status, processed_at)
        VALUES (?, ?, ?, ?, ?, ?, 'completed', NOW())
        ON DUPLICATE KEY UPDATE payout_status=VALUES(payout_status)
      `, ['PAYOUT-' + b.id, b.owner_id, b.id, b.rental_fee, b.platform_fee, b.rental_fee - b.platform_fee]);
    }
  }

  // 8. Reviews
  console.log('[RentBox Seed] 8/12 Seeding Reviews & Ratings...');
  await query(`
    INSERT INTO reviews (id, listing_id, booking_id, user_id, user_name, user_avatar, rating, comment)
    VALUES
    ('REV-1', 'item-1', 'RB-BKG-101', 'USER-1', 'Alex Johnson', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', 5.0, 'Incredible camera! Condition was pristine, Vikram provided extra batteries and was super helpful explaining the menu settings.'),
    ('REV-2', 'item-2', 'RB-BKG-102', 'USER-1', 'Vasanth Kumar', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', 4.9, 'Awesome gaming console with all top games loaded. Controllers had great battery life.'),
    ('REV-3', 'item-5', 'RB-BKG-103', 'USER-1', 'Vasanth Kumar', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', 4.8, 'The party box rocked our family anniversary event. Clear audio and mic worked without any lag.')
    ON DUPLICATE KEY UPDATE rating=VALUES(rating)
  `);

  // 9. Disputes & Evidence
  console.log('[RentBox Seed] 9/12 Seeding Disputes & Evidence...');
  await query(`
    INSERT INTO disputes (id, case_id, booking_id, item_title, renter_name, owner_name, reason, description, amount_involved, status, resolution, admin_notes)
    VALUES
    ('DISP-1', 'CASE-2026-089', 'RB-BKG-102', 'Sony PlayStation 5 Disc Edition', 'Vasanth Kumar', 'Rohit Patil', 'Minor scuff on controller grip', 'Owner noticed a minor surface scratch on controller left analog grip after weekend rent. Security deposit escrow adjustment requested.', 450.00, 'open', NULL, 'Reviewing photos sent by both parties during handover inspection.')
    ON DUPLICATE KEY UPDATE status=VALUES(status)
  `);

  await query(`
    INSERT INTO dispute_evidence (dispute_id, file_url, description, uploaded_by)
    VALUES
    ('DISP-1', 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=800', 'Return condition photo showing left grip.', 'Rohit Patil')
  `);

  // 10. Chat Conversations & Messages
  console.log('[RentBox Seed] 10/12 Seeding Chat Conversations & Messages...');
  await query(`
    INSERT INTO chat_conversations (id, listing_id, listing_title, other_user_id, other_user_name, other_user_avatar, last_message, last_message_time)
    VALUES
    ('CONV-1', 'item-1', 'Sony Alpha A7 IV', 'OWNER-1', 'Vikram Shah', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400', 'Yes, both Sony NP-FZ100 batteries are fully charged and ready!', NOW()),
    ('CONV-2', 'item-2', 'Sony PlayStation 5', 'OWNER-2', 'Rohit Patil', 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400', 'Enjoy your gaming session! Pickup was smooth.', NOW())
    ON DUPLICATE KEY UPDATE last_message=VALUES(last_message)
  `);

  await query(`
    INSERT INTO chat_messages (id, conversation_id, sender_id, text)
    VALUES
    ('MSG-1', 'CONV-1', 'USER-1', 'Hi Vikram, does the A7 IV come with the dual charger?'),
    ('MSG-2', 'CONV-1', 'OWNER-1', 'Yes, both Sony NP-FZ100 batteries are fully charged and ready!')
    ON DUPLICATE KEY UPDATE text=VALUES(text)
  `);

  // 11. Notifications
  console.log('[RentBox Seed] 11/12 Seeding Notifications...');
  await query(`
    INSERT INTO notifications (id, user_id, title, message, type, is_read)
    VALUES
    ('NOTIF-1', 'USER-1', 'Booking Confirmed 🎉', 'Your rental for Sony Alpha A7 IV is confirmed for Oct 25-27. Pickup code is RB-8291.', 'booking', 0),
    ('NOTIF-2', 'USER-1', 'Safe Deposit Guard Active 🛡️', '₹6,000 security deposit is safely locked in RentBox Escrow.', 'security', 0),
    ('NOTIF-3', 'USER-1', 'Listing Verified', 'Owner Vikram Shah has completed biometric KYC verification.', 'listingApproval', 1)
    ON DUPLICATE KEY UPDATE title=VALUES(title)
  `);

  // 12. Platform Settings & Audit Logs
  console.log('[RentBox Seed] 12/12 Seeding Platform Settings & Audit Logs...');
  const settings = [
    ['platform_fee_percent', '10.0', 'Standard platform service fee percentage on gross rental fee'],
    ['security_deposit_rule', 'ESCROW_100_PERCENT', '100% of refundable deposit held in safe escrow until return inspection'],
    ['cancellation_policy', 'FLEXIBLE_24H', 'Free cancellation up to 24 hours before pickup time'],
    ['protection_plan_basic_fee', '49.0', 'Basic protection plan fee in INR per rental'],
    ['protection_plan_standard_fee', '99.0', 'Standard protection plan fee in INR per rental'],
    ['max_rental_days', '30', 'Maximum duration for a single continuous rental booking in days'],
    ['admin_approval_required', 'true', 'All newly created owner listings require administrator review before going public']
  ];

  for (const [k, v, desc] of settings) {
    await query(`
      INSERT INTO platform_settings (setting_key, setting_value, description)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value)
    `, [k, v, desc]);
  }

  await query(`
    INSERT INTO admin_audit_logs (admin_id, admin_name, action, target_entity, target_id, details)
    VALUES
    ('USER-ADMIN', 'RentBox Master Admin', 'INITIALIZE_SYSTEM', 'PLATFORM', 'SYSTEM', 'Initialized database schema, default roles, escrow rules, and seeded sample listings.')
  `);

  console.log('[RentBox Seed] ✅ Database successfully populated with real marketplace and admin data!');
};

if (require.main === module) {
  seedDatabase(true)
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('[RentBox Seed] Error seeding database:', err);
      process.exit(1);
    });
}

module.exports = { seedDatabase };
