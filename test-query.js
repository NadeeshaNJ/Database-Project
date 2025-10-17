require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'skynest',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'Group40'
});

async function testQuery() {
  try {
    console.log('Testing database connection...');
    
    // Test 1: Check if room table exists and has data
    const roomsResult = await pool.query('SELECT COUNT(*) FROM room');
    console.log(`✅ Found ${roomsResult.rows[0].count} rooms in database`);
    
    // Test 2: Check room_type table
    const roomTypesResult = await pool.query('SELECT * FROM room_type');
    console.log(`✅ Found ${roomTypesResult.rows.length} room types:`);
    roomTypesResult.rows.forEach(rt => {
      console.log(`   - ${rt.name}: $${rt.daily_rate}, Capacity: ${rt.capacity}, Amenities: ${rt.amenities}`);
    });
    
    // Test 3: Try the actual query from controller with branch info
    const testQuery = `
      SELECT 
        r.room_id,
        r.room_number,
        r.status,
        r.branch_id,
        b.branch_name,
        b.branch_code,
        rt.room_type_id,
        rt.name as room_type_name,
        rt.capacity,
        rt.daily_rate,
        rt.amenities,
        CASE 
          WHEN bk.room_id IS NULL THEN true 
          ELSE false 
        END as is_available
      FROM room r
      JOIN room_type rt ON r.room_type_id = rt.room_type_id
      JOIN branch b ON r.branch_id = b.branch_id
      LEFT JOIN (
        SELECT DISTINCT room_id
        FROM booking
        WHERE status NOT IN ('Cancelled', 'Checked-Out')
      ) bk ON r.room_id = bk.room_id
      LIMIT 5
    `;
    
    const result = await pool.query(testQuery);
    console.log(`\n✅ Query successful! Found ${result.rows.length} rooms:`);
    console.log(JSON.stringify(result.rows, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Full error:', error);
  } finally {
    await pool.end();
  }
}

testQuery();
