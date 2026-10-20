-- RentBox MySQL Database Schema Migration
-- Complete relational architecture for mobile rental marketplace and admin management

CREATE TABLE IF NOT EXISTS roles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(32) NOT NULL UNIQUE,
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS permissions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  permission_code VARCHAR(64) NOT NULL UNIQUE,
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id INT NOT NULL,
  permission_id INT NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  email VARCHAR(191) NOT NULL UNIQUE,
  phone VARCHAR(32),
  role VARCHAR(32) NOT NULL DEFAULT 'customer',
  avatar_url TEXT,
  location VARCHAR(255) DEFAULT 'Mumbai, Maharashtra',
  is_verified TINYINT(1) DEFAULT 1,
  kyc_status ENUM('pending', 'verified', 'rejected', 'resubmit_needed') DEFAULT 'verified',
  id_document_type VARCHAR(64) DEFAULT 'Aadhaar Card',
  rating DECIMAL(3,2) DEFAULT 4.90,
  reviews_count INT DEFAULT 0,
  status ENUM('active', 'suspended', 'deactivated') DEFAULT 'active',
  suspension_reason TEXT,
  password_hash VARCHAR(255) NOT NULL,
  joined_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_email (email),
  INDEX idx_users_role (role),
  INDEX idx_users_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS owner_verifications (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  document_type VARCHAR(64) NOT NULL,
  document_number VARCHAR(128),
  document_url TEXT NOT NULL,
  selfie_url TEXT,
  status ENUM('pending', 'approved', 'rejected', 'resubmit_requested') DEFAULT 'pending',
  admin_feedback TEXT,
  reviewed_by VARCHAR(64),
  reviewed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_verifications_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS categories (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  slug VARCHAR(64) NOT NULL UNIQUE,
  icon VARCHAR(64) DEFAULT 'category',
  description VARCHAR(255),
  min_deposit_rate DECIMAL(5,2) DEFAULT 20.00,
  platform_fee_percent DECIMAL(5,2) DEFAULT 10.00,
  is_active TINYINT(1) DEFAULT 1,
  display_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS listings (
  id VARCHAR(64) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  category VARCHAR(64) NOT NULL,
  category_id VARCHAR(64),
  price_per_day DECIMAL(10,2) NOT NULL,
  original_price DECIMAL(10,2) DEFAULT 0.00,
  security_deposit DECIMAL(10,2) NOT NULL,
  brand VARCHAR(128) DEFAULT 'Standard',
  model_name VARCHAR(128),
  `condition` VARCHAR(64) DEFAULT 'Good',
  description TEXT NOT NULL,
  location VARCHAR(255) NOT NULL,
  latitude DECIMAL(10,7) DEFAULT 19.0760000,
  longitude DECIMAL(10,7) DEFAULT 72.8777000,
  distance_km DECIMAL(6,2) DEFAULT 2.00,
  owner_id VARCHAR(64) NOT NULL,
  owner_name VARCHAR(128) NOT NULL,
  owner_avatar TEXT,
  owner_rating DECIMAL(3,2) DEFAULT 4.90,
  owner_reviews_count INT DEFAULT 12,
  owner_response_time VARCHAR(64) DEFAULT 'Replies in 15 mins',
  is_instant_booking TINYINT(1) DEFAULT 1,
  is_delivery_available TINYINT(1) DEFAULT 1,
  delivery_charge DECIMAL(10,2) DEFAULT 0.00,
  min_rent_days INT DEFAULT 1,
  max_rent_days INT DEFAULT 30,
  has_bill TINYINT(1) DEFAULT 1,
  has_serial_verified TINYINT(1) DEFAULT 1,
  has_id_verified TINYINT(1) DEFAULT 1,
  status ENUM('pendingApproval', 'active', 'rejected', 'paused', 'flagged', 'needsVerification') NOT NULL DEFAULT 'active',
  rejection_reason TEXT,
  rating DECIMAL(3,2) DEFAULT 4.80,
  reviews_count INT DEFAULT 0,
  total_rentals INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_listings_status (status),
  INDEX idx_listings_category (category),
  INDEX idx_listings_owner (owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS listing_images (
  id INT AUTO_INCREMENT PRIMARY KEY,
  listing_id VARCHAR(64) NOT NULL,
  image_url TEXT NOT NULL,
  is_primary TINYINT(1) DEFAULT 0,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE,
  INDEX idx_listing_images (listing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS product_specifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  listing_id VARCHAR(64) NOT NULL,
  spec_key VARCHAR(128) NOT NULL,
  spec_value VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE,
  INDEX idx_listing_specs (listing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS listing_included_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  listing_id VARCHAR(64) NOT NULL,
  item_name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE,
  INDEX idx_listing_items (listing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS listing_availability (
  id INT AUTO_INCREMENT PRIMARY KEY,
  listing_id VARCHAR(64) NOT NULL,
  date DATE NOT NULL,
  is_available TINYINT(1) DEFAULT 1,
  booking_id VARCHAR(64) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_listing_date (listing_id, date),
  FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS listing_approval_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  listing_id VARCHAR(64) NOT NULL,
  admin_id VARCHAR(64) NOT NULL,
  admin_name VARCHAR(128) NOT NULL,
  action ENUM('approved', 'rejected', 'reshoot_requested', 'info_requested', 'flagged') NOT NULL,
  reason TEXT,
  previous_status VARCHAR(64),
  new_status VARCHAR(64),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE,
  INDEX idx_approval_history (listing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bookings (
  id VARCHAR(64) PRIMARY KEY,
  listing_id VARCHAR(64) NOT NULL,
  listing_title VARCHAR(255) NOT NULL,
  listing_image TEXT,
  renter_id VARCHAR(64) NOT NULL,
  renter_name VARCHAR(128) NOT NULL,
  owner_id VARCHAR(64) NOT NULL,
  owner_name VARCHAR(128) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  duration_days INT NOT NULL,
  fulfillment_method ENUM('selfPickup', 'ownerDelivery') DEFAULT 'selfPickup',
  protection_plan ENUM('standard', 'basic', 'none') DEFAULT 'standard',
  daily_rate DECIMAL(10,2) NOT NULL,
  rental_fee DECIMAL(10,2) NOT NULL,
  security_deposit DECIMAL(10,2) NOT NULL,
  delivery_fee DECIMAL(10,2) DEFAULT 0.00,
  protection_fee DECIMAL(10,2) DEFAULT 99.00,
  platform_fee DECIMAL(10,2) DEFAULT 0.00,
  taxes DECIMAL(10,2) DEFAULT 0.00,
  total_payable DECIMAL(10,2) NOT NULL,
  status ENUM('upcoming', 'active', 'completed', 'cancelled') DEFAULT 'upcoming',
  pickup_code VARCHAR(32) NOT NULL,
  return_code VARCHAR(32) DEFAULT 'RB-RET',
  payment_method VARCHAR(64) DEFAULT 'UPI',
  payment_status ENUM('Pending', 'Paid', 'Refunded', 'Failed') DEFAULT 'Paid',
  location VARCHAR(255),
  is_reviewed TINYINT(1) DEFAULT 0,
  cancellation_reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(id),
  FOREIGN KEY (renter_id) REFERENCES users(id),
  FOREIGN KEY (owner_id) REFERENCES users(id),
  INDEX idx_bookings_status (status),
  INDEX idx_bookings_renter (renter_id),
  INDEX idx_bookings_owner (owner_id),
  INDEX idx_bookings_dates (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pickup_return_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  booking_id VARCHAR(64) NOT NULL,
  event_type ENUM('pickup', 'return') NOT NULL,
  verified_code VARCHAR(32) NOT NULL,
  condition_status ENUM('good', 'damaged', 'missing_accessories') DEFAULT 'good',
  condition_notes TEXT,
  photo_evidence_urls JSON,
  recorded_by VARCHAR(64) NOT NULL,
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  INDEX idx_pickup_return_booking (booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payments (
  id VARCHAR(64) PRIMARY KEY,
  booking_id VARCHAR(64) NOT NULL,
  transaction_ref VARCHAR(128) NOT NULL UNIQUE,
  payment_gateway VARCHAR(64) DEFAULT 'Razorpay/UPI',
  amount DECIMAL(10,2) NOT NULL,
  rental_portion DECIMAL(10,2) NOT NULL,
  deposit_portion DECIMAL(10,2) NOT NULL,
  platform_fee_portion DECIMAL(10,2) DEFAULT 0.00,
  status ENUM('initiated', 'captured', 'refunded', 'failed') DEFAULT 'captured',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  INDEX idx_payments_booking (booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS security_deposits (
  id VARCHAR(64) PRIMARY KEY,
  booking_id VARCHAR(64) NOT NULL,
  renter_id VARCHAR(64) NOT NULL,
  deposit_amount DECIMAL(10,2) NOT NULL,
  status ENUM('held_in_escrow', 'refunded_full', 'partially_deducted', 'forfeited') DEFAULT 'held_in_escrow',
  deduction_amount DECIMAL(10,2) DEFAULT 0.00,
  deduction_reason TEXT,
  refunded_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  FOREIGN KEY (renter_id) REFERENCES users(id),
  INDEX idx_deposits_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS refunds (
  id VARCHAR(64) PRIMARY KEY,
  payment_id VARCHAR(64),
  booking_id VARCHAR(64) NOT NULL,
  refund_type ENUM('deposit_refund', 'cancellation_refund', 'dispute_refund') NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  reason TEXT NOT NULL,
  status ENUM('pending', 'processed', 'failed') DEFAULT 'processed',
  processed_by VARCHAR(64),
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  INDEX idx_refunds_booking (booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS owner_payouts (
  id VARCHAR(64) PRIMARY KEY,
  owner_id VARCHAR(64) NOT NULL,
  booking_id VARCHAR(64) NOT NULL,
  gross_amount DECIMAL(10,2) NOT NULL,
  platform_fee DECIMAL(10,2) NOT NULL,
  net_payout DECIMAL(10,2) NOT NULL,
  payout_status ENUM('pending', 'processing', 'completed', 'on_hold') DEFAULT 'pending',
  bank_account_tail VARCHAR(16) DEFAULT '**** 4321',
  payout_batch_id VARCHAR(64),
  processed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id),
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  INDEX idx_payouts_owner (owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS favourites (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  listing_id VARCHAR(64) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_listing (user_id, listing_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS reviews (
  id VARCHAR(64) PRIMARY KEY,
  listing_id VARCHAR(64) NOT NULL,
  booking_id VARCHAR(64),
  user_id VARCHAR(64),
  user_name VARCHAR(128) NOT NULL,
  user_avatar TEXT,
  rating DECIMAL(2,1) NOT NULL,
  comment TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE,
  INDEX idx_reviews_listing (listing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chat_conversations (
  id VARCHAR(64) PRIMARY KEY,
  listing_id VARCHAR(64) NOT NULL,
  listing_title VARCHAR(255) NOT NULL,
  other_user_id VARCHAR(64) NOT NULL,
  other_user_name VARCHAR(128) NOT NULL,
  other_user_avatar TEXT,
  last_message TEXT,
  last_message_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chat_messages (
  id VARCHAR(64) PRIMARY KEY,
  conversation_id VARCHAR(64) NOT NULL,
  sender_id VARCHAR(64) NOT NULL,
  text TEXT NOT NULL,
  is_read TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id) ON DELETE CASCADE,
  INDEX idx_chat_conv (conversation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type ENUM('booking', 'payment', 'listingApproval', 'message', 'reminder', 'security') NOT NULL,
  is_read TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_notif_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS disputes (
  id VARCHAR(64) PRIMARY KEY,
  case_id VARCHAR(64) NOT NULL UNIQUE,
  booking_id VARCHAR(64) NOT NULL,
  item_title VARCHAR(255) NOT NULL,
  renter_name VARCHAR(128) NOT NULL,
  owner_name VARCHAR(128) NOT NULL,
  reason VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  amount_involved DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  status ENUM('open', 'underReview', 'resolved', 'dismissed') DEFAULT 'open',
  resolution TEXT,
  admin_notes TEXT,
  resolved_by VARCHAR(64),
  resolved_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  INDEX idx_disputes_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dispute_evidence (
  id INT AUTO_INCREMENT PRIMARY KEY,
  dispute_id VARCHAR(64) NOT NULL,
  file_url TEXT NOT NULL,
  description VARCHAR(255),
  uploaded_by VARCHAR(64) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dispute_id) REFERENCES disputes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS support_requests (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  user_name VARCHAR(128) NOT NULL,
  email VARCHAR(191) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  status ENUM('open', 'in_progress', 'resolved') DEFAULT 'open',
  response_text TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS platform_settings (
  setting_key VARCHAR(64) PRIMARY KEY,
  setting_value TEXT NOT NULL,
  description VARCHAR(255),
  updated_by VARCHAR(64) DEFAULT 'SYSTEM',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  admin_id VARCHAR(64) NOT NULL,
  admin_name VARCHAR(128) NOT NULL,
  action VARCHAR(64) NOT NULL,
  target_entity VARCHAR(64) NOT NULL,
  target_id VARCHAR(64) NOT NULL,
  details TEXT,
  ip_address VARCHAR(45) DEFAULT '127.0.0.1',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_admin (admin_id),
  INDEX idx_audit_action (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
