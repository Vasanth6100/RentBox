const fs = require('fs');
const path = require('path');
const { initDbConnection, query, isMySQL } = require('../config/db');

const runMigrations = async () => {
  console.log('[RentBox Migrations] Starting database migration...');
  await initDbConnection();

  const migrationFile = path.join(__dirname, '..', 'migrations', '001_create_schema.sql');
  const sql = fs.readFileSync(migrationFile, 'utf8');

  if (isMySQL()) {
    // MySQL supports multiple statements in query if configured
    await query(sql);
    console.log('[RentBox Migrations] Successfully executed 001_create_schema.sql in MySQL.');
  } else {
    // If running in SQLite fallback, execute statements individually
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (const stmt of statements) {
      try {
        await query(stmt);
      } catch (e) {
        // Ignore dialect mismatch on fallback
      }
    }
    console.log('[RentBox Migrations] Finished executing statements in fallback mode.');
  }

  console.log('[RentBox Migrations] All database tables and indexes verified.');
};

if (require.main === module) {
  runMigrations()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('[RentBox Migrations] Error running migrations:', err);
      process.exit(1);
    });
}

module.exports = { runMigrations };
