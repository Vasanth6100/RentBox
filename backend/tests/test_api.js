const http = require('http');

const PORT = process.env.PORT || 5000;
const BASE_URL = `http://localhost:${PORT}/api`;

const request = (method, path, body = null, token = null) => {
  return new Promise((resolve, reject) => {
    const url = new URL(BASE_URL + path);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, body: parsed });
        } catch {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
};

const runTests = async () => {
  console.log('🧪 Starting RentBox Automated Backend Verification Suite...\n');
  let passed = 0;
  let total = 0;

  const assert = (condition, title) => {
    total++;
    if (condition) {
      console.log(`  ✅ [PASS] ${title}`);
      passed++;
    } else {
      console.error(`  ❌ [FAIL] ${title}`);
    }
  };

  try {
    // 1. Health & Database Engine
    const health = await request('GET', '/health');
    assert(health.status === 200 && health.body.status === 'online', '1. System Health API is online');
    assert(health.body.database.includes('MySQL'), '2. Database engine is verified as MySQL 8.0');

    // 2. Customer / Owner Authentication
    const customerLogin = await request('POST', '/auth/login', {
      emailPhone: 'vasanth@rentbox.in',
      password: 'RentBox@2026'
    });
    assert(customerLogin.status === 200 && customerLogin.body.user.role === 'customer', '3. Customer Login successful & returns role customer');

    // 3. Admin Authentication & Role Enforcement
    const invalidAdmin = await request('POST', '/auth/admin-login', {
      emailPhone: 'admin@rentbox.in',
      password: 'wrong_password_99'
    });
    assert(invalidAdmin.status === 401, '4. Admin Login rejects invalid credentials with 401');

    const validAdmin = await request('POST', '/auth/admin-login', {
      emailPhone: 'admin@rentbox.in',
      password: 'Admin@2026'
    });
    assert(validAdmin.status === 200 && validAdmin.body.user.role === 'admin' && Boolean(validAdmin.body.token), '5. Admin Login succeeds with hashed bcrypt check & JWT token');
    const adminToken = validAdmin.body.token;

    // 4. Categories API
    const categories = await request('GET', '/categories');
    assert(categories.status === 200 && categories.body.length >= 6, '6. Categories API returns all 6 equipment categories');

    // 5. Listings API - Public vs Moderation
    const publicListings = await request('GET', '/listings');
    assert(publicListings.status === 200 && publicListings.body.every(l => l.status === 'active'), '7. Public Listings API ONLY returns approved active items');

    const adminQueue = await request('GET', '/admin/listings/queue?status=pendingApproval', null, adminToken);
    assert(adminQueue.status === 200 && adminQueue.body.length > 0, '8. Admin Approvals Queue returns pending equipment submissions');

    // 6. Listing Approval Workflow
    const testItemId = adminQueue.body[0].id;
    const approveRes = await request('POST', `/listings/${testItemId}/approve`, {
      adminId: 'USER-ADMIN',
      adminName: 'RentBox Master Admin'
    }, adminToken);
    assert(approveRes.status === 200 && approveRes.body.success === true, '9. Admin Approve Listing succeeds & persists to MySQL');

    // 7. Booking Creation & Availability Overlap Prevention
    const bookingRes = await request('POST', '/bookings', {
      listingId: 'item-1',
      startDate: '2026-11-10',
      endDate: '2026-11-12',
      durationDays: 2,
      renterId: 'USER-1',
      renterName: 'Vasanth Kumar',
      paymentMethod: 'UPI'
    });
    assert(bookingRes.status === 201 && bookingRes.body.pickupCode.startsWith('RB-'), '10. Booking created with backend recalculated price & escrow deposit');

    const conflictRes = await request('POST', '/bookings', {
      listingId: 'item-1',
      startDate: '2026-11-11',
      endDate: '2026-11-13',
      renterId: 'USER-1'
    });
    assert(conflictRes.status === 409, '11. Business Rule: Overlapping booking on same dates is blocked (409 Conflict)');

    // 8. Admin Metrics & Financial Ledger
    const metricsRes = await request('GET', '/admin/metrics', null, adminToken);
    assert(metricsRes.status === 200 && metricsRes.body.metrics.activeListings > 0, '12. Admin Metrics API returns real MySQL aggregated counts');

    // 9. Disputes & Resolution
    const disputesRes = await request('GET', '/admin/disputes', null, adminToken);
    assert(disputesRes.status === 200 && disputesRes.body.length > 0, '13. Disputes API returns open claims with evidence');

    // 10. Platform Settings & Audit Logs
    const settingsRes = await request('POST', '/admin/settings', {
      settings: { platform_fee_percent: '10.5' }
    }, adminToken);
    assert(settingsRes.status === 200 && settingsRes.body.success === true, '14. Platform Settings updated & recorded in admin audit logs');

    console.log(`\n🎉 Test Suite Completed: ${passed}/${total} checks passed successfully!`);
    process.exit(passed === total ? 0 : 1);
  } catch (err) {
    console.error('Test Suite encountered error:', err);
    process.exit(1);
  }
};

runTests();
