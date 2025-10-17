// Script to update a user's password with a proper bcrypt hash
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { pool } = require('../config/database');

const username = process.argv[2] || 'nuwan.peiris7';
const newPassword = process.argv[3] || 'customer123';

const run = async () => {
  const client = await pool.connect();
  try {
    // Hash the password with bcrypt (12 rounds to match model hooks)
    const hashedPassword = await bcrypt.hash(newPassword, 12);
    
    // Update the user's password_hash
    const result = await client.query(
      'UPDATE public.user_account SET password_hash = $1 WHERE username = $2 RETURNING user_id, username',
      [hashedPassword, username]
    );

    if (result.rowCount === 0) {
      console.log(`❌ User "${username}" not found`);
      process.exit(1);
    }

    console.log(`✅ Password updated for user: ${username}`);
    console.log(`   User ID: ${result.rows[0].user_id}`);
    console.log(`   New hash: ${hashedPassword.substring(0, 20)}...`);
    console.log(`\n   You can now login with:`);
    console.log(`   Username: ${username}`);
    console.log(`   Password: ${newPassword}`);
    
    process.exit(0);
  } catch (err) {
    console.error('❌ Error updating password:', err.message);
    process.exit(1);
  } finally {
    client.release();
  }
};

run();
