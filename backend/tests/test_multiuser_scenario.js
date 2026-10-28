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
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
};

const runMultiUserTest = async () => {
  console.log('🚀 Running Multi-User Visibility & Immediate Publishing Test...\n');

  // Step 1: Register / Authenticate User A
  const ts = Date.now();
  console.log('1️⃣ Registering User A...');
  const userARes = await request('POST', '/auth/register', {
    name: 'Alice Owner',
    email: `alice_${ts}@example.com`,
    phone: `+91 91000${ts.toString().slice(-5)}`,
    password: 'Password@123',
    role: 'owner'
  });
  console.log(`   User A registered: id=${userARes.body.user.id}, email=${userARes.body.user.email}`);
  const userA = userARes.body.user;
  const tokenA = userARes.body.token;

  // Step 2: User A uploads "Sony ZV-E10 Camera" at ₹800/day
  console.log('\n2️⃣ User A uploads "Sony ZV-E10 Camera" (₹800/day)...');
  const uploadARes = await request('POST', '/listings', {
    id: `ITEM-SONY-ZVE10-${ts}`,
    title: 'Sony ZV-E10 Camera',
    category: 'Cameras',
    pricePerDay: 800,
    securityDeposit: 3200,
    ownerId: userA.id,
    ownerName: userA.name,
    location: 'Bandra, Mumbai',
    description: 'Vlogging mirrorless camera with 16-50mm kit lens and 4K recording.',
    imageUrls: ['https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800'],
    includedItems: ['Camera Body', '16-50mm Lens', '2x Batteries', 'Carry Case']
  }, tokenA);

  console.log(`   Upload response status: ${uploadARes.status}`);
  console.log(`   Listing Status: "${uploadARes.body.status}" (Must be "active" without admin review)`);
  if (uploadARes.status !== 201 || uploadARes.body.status !== 'active') {
    throw new Error(`User A upload failed or status is not active: ${JSON.stringify(uploadARes.body)}`);
  }

  // Step 3: Register User B
  console.log('\n3️⃣ Registering User B...');
  const userBRes = await request('POST', '/auth/register', {
    name: 'Bob Renter',
    email: `bob_${ts}@example.com`,
    phone: `+91 92000${ts.toString().slice(-5)}`,
    password: 'Password@123',
    role: 'customer'
  });
  console.log(`   User B registered: id=${userBRes.body.user.id}, email=${userBRes.body.user.email}`);
  const userB = userBRes.body.user;
  const tokenB = userBRes.body.token;

  // Step 4: User B opens Explore feed
  console.log('\n4️⃣ User B opens Explore feed to find User A\'s gadget...');
  const exploreB = await request('GET', '/listings', null, tokenB);
  const foundByB = exploreB.body.find(l => l.id === uploadARes.body.id);
  console.log(`   Can User B see User A's "Sony ZV-E10 Camera"? ${foundByB ? '✅ YES' : '❌ NO'}`);
  if (!foundByB) {
    throw new Error('User B cannot see User A\'s listing on Explore!');
  }

  // Step 5: User B opens listing details and books it
  console.log('\n5️⃣ User B creates a rental booking for User A\'s camera...');
  const bookingRes = await request('POST', '/bookings', {
    listingId: foundByB.id,
    startDate: '2026-11-15',
    endDate: '2026-11-17',
    durationDays: 2,
    renterId: userB.id,
    renterName: userB.name,
    paymentMethod: 'UPI'
  }, tokenB);

  console.log(`   Booking Status: ${bookingRes.status}, Booking ID: ${bookingRes.body.booking?.id}`);
  console.log(`   Pickup Code: ${bookingRes.body.booking?.pickupCode}`);
  if (bookingRes.status !== 201) {
    throw new Error(`User B booking failed: ${JSON.stringify(bookingRes.body)}`);
  }

  // Step 6: Critical Cross-Upload Test: User B uploads Item 2
  console.log('\n6️⃣ User B uploads Item 2: "Xbox Series X Console" (₹950/day)...');
  const uploadBRes = await request('POST', '/listings', {
    id: `ITEM-XBOX-${ts}`,
    title: 'Xbox Series X Console',
    category: 'Gaming',
    pricePerDay: 950,
    securityDeposit: 4000,
    ownerId: userB.id,
    ownerName: userB.name,
    location: 'Andheri, Mumbai',
    description: 'Next-gen gaming console with 2 wireless controllers.',
    imageUrls: ['https://images.unsplash.com/photo-1621259182978-fbf93132d53d?w=800']
  }, tokenB);
  console.log(`   Item 2 status: ${uploadBRes.body.status}`);

  // Step 7: Verify User A sees BOTH Item 1 and Item 2 on Explore
  console.log('\n7️⃣ User A opens Explore...');
  const exploreA = await request('GET', '/listings', null, tokenA);
  const userASeesItem1 = exploreA.body.some(l => l.id === uploadARes.body.id);
  const userASeesItem2 = exploreA.body.some(l => l.id === uploadBRes.body.id);
  console.log(`   User A sees Item 1 (Sony ZV-E10): ${userASeesItem1 ? '✅ YES' : '❌ NO'}`);
  console.log(`   User A sees Item 2 (Xbox Series X): ${userASeesItem2 ? '✅ YES' : '❌ NO'}`);

  // Step 8: Verify User B sees BOTH Item 1 and Item 2 on Explore
  console.log('\n8️⃣ User B opens Explore...');
  const exploreB2 = await request('GET', '/listings', null, tokenB);
  const userBSeesItem1 = exploreB2.body.some(l => l.id === uploadARes.body.id);
  const userBSeesItem2 = exploreB2.body.some(l => l.id === uploadBRes.body.id);
  console.log(`   User B sees Item 1 (Sony ZV-E10): ${userBSeesItem1 ? '✅ YES' : '❌ NO'}`);
  console.log(`   User B sees Item 2 (Xbox Series X): ${userBSeesItem2 ? '✅ YES' : '❌ NO'}`);

  // Step 9: User C (Guest / third user) opens Explore
  console.log('\n9️⃣ User C (Public / Unauthenticated Guest) opens Explore...');
  const exploreC = await request('GET', '/listings');
  const userCSeesItem1 = exploreC.body.some(l => l.id === uploadARes.body.id);
  const userCSeesItem2 = exploreC.body.some(l => l.id === uploadBRes.body.id);
  console.log(`   User C sees Item 1: ${userCSeesItem1 ? '✅ YES' : '❌ NO'}`);
  console.log(`   User C sees Item 2: ${userCSeesItem2 ? '✅ YES' : '❌ NO'}`);

  if (userASeesItem1 && userASeesItem2 && userBSeesItem1 && userBSeesItem2 && userCSeesItem1 && userCSeesItem2) {
    console.log('\n🎉 ALL SCENARIOS PASSED! Listings are truly global, immediately published, and visible to all users.');
  } else {
    throw new Error('Listing visibility test failed across multiple users.');
  }
};

runMultiUserTest()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('❌ Test Error:', err);
    process.exit(1);
  });
