require('dotenv').config({ path: '../.env' });
const { query, initDbConnection } = require('../config/db');

(async () => {
  try {
    // Must initialize the DB connection before any queries
    await initDbConnection();
    await new Promise(r => setTimeout(r, 500));

    // 1. Set admin_approval_required to false
    await query(`
      INSERT INTO platform_settings (setting_key, setting_value, description)
      VALUES ('admin_approval_required', 'false', 'Listings go live instantly')
      ON DUPLICATE KEY UPDATE setting_value = 'false'
    `);
    console.log('[OK] admin_approval_required set to false');

    // 2. Promote all stuck pendingApproval listings to active
    const result = await query("UPDATE listings SET status = 'active' WHERE status = 'pendingApproval'");
    console.log('[OK] Promoted pending listings to active. Result:', result);

    // 3. Verify
    const settings = await query("SELECT setting_key, setting_value FROM platform_settings WHERE setting_key = 'admin_approval_required'");
    console.log('[VERIFY] Setting:', JSON.stringify(settings));

    const counts = await query("SELECT status, COUNT(*) as count FROM listings GROUP BY status");
    console.log('[VERIFY] Listing counts by status:', JSON.stringify(counts));

    process.exit(0);
  } catch (err) {
    console.error('[FAIL]', err.message);
    process.exit(1);
  }
})();
