// Script to delete users with dummy/placeholder password hashes
require('dotenv').config();
const { pool } = require('../config/database');

const run = async () => {
  const client = await pool.connect();
  try {
    console.log('🔍 Finding users with dummy password hashes...\n');
    
    // Find users with the dummy hash pattern
    const findResult = await client.query(
      `SELECT user_id, username, role, password_hash 
       FROM public.user_account 
       WHERE password_hash LIKE '$2a$10$dummypass%'
       ORDER BY user_id`
    );

    if (findResult.rowCount === 0) {
      console.log('✅ No users found with dummy password hashes!');
      process.exit(0);
    }

    console.log(`Found ${findResult.rowCount} user(s) with dummy passwords:\n`);
    findResult.rows.forEach(u => {
      console.log(`  - ID: ${u.user_id}, Username: ${u.username}, Role: ${u.role}`);
    });

    console.log('\n🗑️  Deleting related records and users...\n');

    // Start transaction
    await client.query('BEGIN');

    // First, delete related customer records
    const customerDelete = await client.query(
      `DELETE FROM public.customer 
       WHERE user_id IN (
         SELECT user_id FROM public.user_account 
         WHERE password_hash LIKE '$2a$10$dummypass%'
       )`
    );
    console.log(`  ✓ Deleted ${customerDelete.rowCount} customer record(s)`);

    // Then delete the user accounts
    const deleteResult = await client.query(
      `DELETE FROM public.user_account 
       WHERE password_hash LIKE '$2a$10$dummypass%'
       RETURNING user_id, username`
    );

    await client.query('COMMIT');

    console.log(`\n✅ Deleted ${deleteResult.rowCount} user account(s):\n`);
    deleteResult.rows.forEach(u => {
      console.log(`  ✓ Deleted: ${u.username} (ID: ${u.user_id})`);
    });

    console.log('\n✅ Cleanup completed!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  } finally {
    client.release();
  }
};

run();
