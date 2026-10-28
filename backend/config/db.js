const mysql = require('mysql2/promise');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

let pool = null;
let isUsingMySQL = false;
let sqliteDb = null;

/**
 * Parses connection configuration from either a connection string or individual env vars.
 */
const resolveDbConfig = () => {
  const dbUrl = process.env.DATABASE_URL || process.env.MYSQL_URL || process.env.JAWSDB_URL || process.env.CLEARDB_DATABASE_URL;

  let host = process.env.DB_HOST || process.env.MYSQLHOST || 'localhost';
  let port = parseInt(process.env.DB_PORT || process.env.MYSQLPORT || '3306', 10);
  let user = process.env.DB_USER || process.env.MYSQLUSER || 'root';
  let password = process.env.DB_PASS || process.env.DB_PASSWORD || process.env.MYSQLPASSWORD || 'Vasanth@123';
  let database = process.env.DB_NAME || process.env.MYSQLDATABASE || 'rentbox_db';
  let ssl = undefined;

  if (dbUrl) {
    try {
      const parsed = new URL(dbUrl);
      host = parsed.hostname;
      port = parseInt(parsed.port || '3306', 10);
      user = decodeURIComponent(parsed.username || '');
      password = decodeURIComponent(parsed.password || '');
      database = (parsed.pathname || '').replace(/^\//, '') || database;

      const isInternal = host.includes('railway.internal') || host === 'localhost' || host === '127.0.0.1';
      if (!isInternal && (parsed.searchParams.has('ssl') || process.env.DB_SSL === 'true')) {
        const rejectUnauthorized = process.env.DB_SSL_REJECT_UNAUTHORIZED === 'true';
        ssl = { rejectUnauthorized };
      }
    } catch (e) {
      console.warn('[RentBox DB] Could not parse DATABASE_URL string, falling back to individual env variables:', e.message);
    }
  } else if (process.env.DB_SSL === 'true' && !host.includes('railway.internal')) {
    const rejectUnauthorized = process.env.DB_SSL_REJECT_UNAUTHORIZED === 'true';
    ssl = { rejectUnauthorized };
  }

  return { host, port, user, password, database, ssl };
};

let isInitializing = false;
let isInitialized = false;

const initDbConnection = async () => {
  if (isInitialized && (pool || sqliteDb)) {
    return;
  }
  if (isInitializing) {
    while (isInitializing) {
      await new Promise(r => setTimeout(r, 100));
    }
    return;
  }
  isInitializing = true;

  const config = resolveDbConfig();

  try {
    // 1. In local development only, attempt CREATE DATABASE IF NOT EXISTS
    // (Cloud MySQL users often lack root/create db privileges, so we guard this)
    if (process.env.NODE_ENV !== 'production' && !process.env.DATABASE_URL && config.host === 'localhost') {
      try {
        const rootConn = await mysql.createConnection({
          host: config.host,
          port: config.port,
          user: config.user,
          password: config.password,
          multipleStatements: true
        });
        await rootConn.query(`CREATE DATABASE IF NOT EXISTS \`${config.database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`);
        await rootConn.end();
      } catch (createErr) {
        // Ignored if permissions are restricted
      }
    }

    // 2. Create MySQL connection pool
    pool = mysql.createPool({
      host: config.host,
      port: config.port,
      user: config.user,
      password: config.password,
      database: config.database,
      ssl: config.ssl,
      waitForConnections: true,
      connectionLimit: 10,
      enableKeepAlive: true,
      queueLimit: 0,
      multipleStatements: true,
      dateStrings: true
    });

    // Test connection
    const [test] = await pool.query('SELECT 1 as connected');
    if (test && test[0].connected === 1) {
      isUsingMySQL = true;
      isInitialized = true;
      isInitializing = false;
      console.log(`[RentBox DB] Connected to MySQL server at ${config.host}:${config.port}, database: ${config.database}${config.ssl ? ' (SSL enabled)' : ''}`);

      // Auto-run schema migrations if tables do not exist
      try {
        const [tables] = await pool.query('SHOW TABLES LIKE "users"');
        if (tables.length === 0) {
          console.log('[RentBox DB] Schema tables not detected. Automatically applying migrations...');
          const { runMigrations } = require('../scripts/migrate');
          await runMigrations(true);

          console.log('[RentBox DB] Automatically seeding initial catalog and admin accounts...');
          const { seedDatabase } = require('../scripts/seed');
          await seedDatabase(false, true);
        }

        // Ensure all listings are active and admin approval is disabled
        await pool.query("UPDATE listings SET status = 'active' WHERE status = 'pendingApproval'");
        await pool.query(`
          INSERT INTO platform_settings (setting_key, setting_value, description)
          VALUES ('admin_approval_required', 'false', 'Listings go live instantly without approval')
          ON DUPLICATE KEY UPDATE setting_value = 'false'
        `);

        // Ensure users table has password reset columns
        try {
          await pool.query("ALTER TABLE users ADD COLUMN password_reset_token VARCHAR(64) NULL, ADD COLUMN reset_token_expires DATETIME NULL");
        } catch (_) {
          // Columns may already exist
        }
      } catch (migErr) {
        console.warn('[RentBox DB] Auto-migration check warning:', migErr.message);
      }

      return;
    }
  } catch (err) {
    console.warn(`[RentBox DB] Could not connect to MySQL: ${err.message}. Initializing SQLite fallback.`);
  }

  // SQLite Fallback if MySQL fails
  try {
    const sqlite3 = require('sqlite3').verbose();
    const dbDir = path.join(__dirname, '..', 'data');
    if (!fs.existsSync(dbDir)) fs.mkdirSync(dbDir, { recursive: true });
    const dbPath = path.join(dbDir, 'rentbox.db');
    sqliteDb = new sqlite3.Database(dbPath);
    isUsingMySQL = false;
    isInitialized = true;
    console.log(`[RentBox DB] Fallback SQLite database connected at: ${dbPath}`);
  } catch (sqliteErr) {
    console.error('[RentBox DB] Fatal: Failed to initialize any database driver:', sqliteErr);
  } finally {
    isInitializing = false;
  }
};

// Generic query helper
const query = async (sql, params = []) => {
  if (isUsingMySQL && pool) {
    const [rows] = await pool.query(sql, params);
    return rows;
  }

  // SQLite fallback emulation
  if (sqliteDb) {
    return new Promise((resolve, reject) => {
      const trimmed = sql.trim().toUpperCase();
      if (trimmed.startsWith('SELECT') || trimmed.startsWith('SHOW') || trimmed.startsWith('PRAGMA')) {
        sqliteDb.all(sql, params, (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        });
      } else {
        sqliteDb.run(sql, params, function (err) {
          if (err) reject(err);
          else resolve({ insertId: this.lastID, affectedRows: this.changes });
        });
      }
    });
  }

  throw new Error('No active database connection available.');
};

// Transaction helper
const transaction = async (callback) => {
  if (isUsingMySQL && pool) {
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      const result = await callback(conn);
      await conn.commit();
      return result;
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  }

  // SQLite fallback
  await query('BEGIN TRANSACTION');
  try {
    const result = await callback({ query });
    await query('COMMIT');
    return result;
  } catch (err) {
    await query('ROLLBACK');
    throw err;
  }
};

module.exports = {
  initDbConnection,
  query,
  transaction,
  isMySQL: () => isUsingMySQL,
  getPool: () => pool
};
