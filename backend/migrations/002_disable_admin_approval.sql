-- ============================================================
-- Migration: 002_disable_admin_approval
-- Purpose  : Disable the admin approval gate so all listings
--            go live instantly and are visible to all users.
-- Run this on your production MySQL database (Railway).
-- ============================================================

-- 1. Set admin_approval_required to false
INSERT INTO platform_settings (setting_key, setting_value, description)
VALUES ('admin_approval_required', 'false', 'All newly created owner listings go live instantly without administrator review')
ON DUPLICATE KEY UPDATE
  setting_value = 'false',
  description   = 'All newly created owner listings go live instantly without administrator review';

-- 2. Promote all stuck pendingApproval listings to active
--    (these are items that real users uploaded but could never be seen by others)
UPDATE listings
SET status = 'active'
WHERE status = 'pendingApproval';

-- 3. Verify the result
SELECT setting_key, setting_value FROM platform_settings WHERE setting_key = 'admin_approval_required';
SELECT COUNT(*) AS still_pending FROM listings WHERE status = 'pendingApproval';
SELECT COUNT(*) AS now_active    FROM listings WHERE status = 'active';
