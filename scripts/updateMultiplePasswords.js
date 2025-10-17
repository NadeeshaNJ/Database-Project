// Script to update passwords for multiple users
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { pool } = require('../config/database');

// Add your users here: username -> password
const usersToUpdate = {
  'nuwan.peiris7': 'customer123',
  'admin': 'admin123',
  'manager': 'manager123',
  'receptionist': 'reception123',
  'accountant': 'accountant123'
  // Add more users as needed
};

const run = async () => {
  const client = await pool.connect();
  try {
    console.log('🔄 Updating passwords for multiple users...\n');
    
    for (const [username, password] of Object.entries(usersToUpdate)) {
      try {
        const hashedPassword = await bcrypt.hash(password, 12);
        
        const result = await client.query(
          'UPDATE public.user_account SET password_hash = $1 WHERE username = $2 RETURNING user_id, username',
          [hashedPassword, username]
        );

        if (result.rowCount === 0) {
          console.log(`  ⚠️  User "${username}" not found - skipping`);
        } else {
          console.log(`  ✅ Updated: ${username} (ID: ${result.rows[0].user_id})`);
        }
      } catch (err) {
        console.log(`  ❌ Error updating ${username}: ${err.message}`);
      }
    }
    
    console.log('\n✅ Password update completed!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  } finally {
    client.release();
  }
};

run();
