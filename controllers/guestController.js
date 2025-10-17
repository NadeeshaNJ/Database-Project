const { sequelize } = require('../models');
const { asyncHandler } = require('../middleware/errorHandler');
const { Op } = require('sequelize');
const { executeQuery,executeTransaction } = require('../config/database'); 

/**
 * Get all guests with search and filtering
 */

const getAllGuests = asyncHandler(async (req, res) => {
    const {
        search,
        nationality, // Using 'nationality' to match schema, derived from 'country' query param
        email,
        phone,
        branch_id,
        page = 1,
        limit = 10,
        sort_by = 'full_name', // Defaulting to full_name
        order = 'asc'
    } = req.query;

    const whereConditions = ['1=1'];
    const params = [];
    let paramCount = 0;

    // 1. FILTERS (Using full_name and nationality)

    // Search filter (full_name, email, phone)
    if (search) {
        paramCount++;
        whereConditions.push(`
          (g.full_name ILIKE $${paramCount} 
          OR g.email ILIKE $${paramCount} 
          OR g.phone ILIKE $${paramCount})
        `);
        params.push(`%${search}%`);
    }

    // Nationality filter (Derived from 'country' param, using schema's 'nationality' column)
    if (nationality) {
        paramCount++;
        whereConditions.push(`g.nationality ILIKE $${paramCount}`);
        params.push(`%${nationality}%`);
    }

    // Email filter
    if (email) {
        paramCount++;
        whereConditions.push(`g.email ILIKE $${paramCount}`);
        params.push(`%${email}%`);
    }

    // Phone filter
    if (phone) {
        paramCount++;
        whereConditions.push(`g.phone ILIKE $${paramCount}`);
        params.push(`%${phone}%`);
    }

    // Branch filter - Filter guests who have bookings in specific branch
    if (branch_id) {
        paramCount++;
        whereConditions.push(`EXISTS (
            SELECT 1 FROM booking b 
            JOIN room r ON b.room_id = r.room_id 
            WHERE b.guest_id = g.guest_id AND r.branch_id = $${paramCount}
        )`);
        params.push(branch_id);
    }
    
    // Store params for count query (before adding limit/offset)
    const filterParams = [...params];
    const offset = (parseInt(page) - 1) * parseInt(limit);

    // 2. Sorting and Pagination Preparation
    
    // Validate sort field against schema columns
    const allowedSortFields = ['full_name', 'email', 'created_at', 'nationality', 'guest_id'];
    const sortField = allowedSortFields.includes(sort_by) ? sort_by : 'full_name';
    const sortOrder = order.toLowerCase() === 'desc' ? 'DESC' : 'ASC';

    // 3. SQL Queries (Using executeQuery)

    // Count query
    const countQuery = `
        SELECT COUNT(g.guest_id) 
        FROM public.guest g
        WHERE ${whereConditions.join(' AND ')}
    `;

    // Main query
    const mainQuery = `
        SELECT * FROM public.guest g 
        WHERE ${whereConditions.join(' AND ')}
        ORDER BY ${sortField} ${sortOrder}
        LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
    `;

    // Add pagination parameters
    params.push(parseInt(limit), offset);

    const [countResult, guestsResult] = await Promise.all([
        executeQuery(countQuery, filterParams), // Use only filter params for count
        executeQuery(mainQuery, params)         // Use all params for main query
    ]);

    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
        success: true,
        data: {
            guests: guestsResult.rows,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: totalCount,
                pages: Math.ceil(totalCount / limit)
            }
        }
    });
});

/**
 * Get guest by ID
 */
// const getGuestById = asyncHandler(async (req, res) => {
//   const { id } = req.params;

//   const query = `
//     SELECT * FROM guests WHERE id = $1
//   `;

//   const [guest] = await sequelize.query(query, {
//     bind: [id],
//     type: sequelize.QueryTypes.SELECT
//   });

//   if (!guest) {
//     return res.status(404).json({
//       success: false,
//       error: 'Guest not found'
//     });
//   }

//   res.json({
//     success: true,
//     data: guest
//   });
// });

const getGuestById = asyncHandler(async (req, res) => {
  // The ID captured from the route /api/guests/:id is accessed via req.params
  const { id } = req.params; 

  if (!id) {
    return res.status(400).json({ success: false, error: 'Guest ID is required.' });
  }

  // Use correct table name (public.guest) and primary key column name (guest_id)
  const query = `
    SELECT 
      g.guest_id, 
      g.nic, 
      g.full_name, 
      g.email, 
      g.phone, 
      g.gender, 
      g.date_of_birth, 
      g.address, 
      g.nationality 
    FROM public.guest g
    WHERE g.guest_id = $1
  `;

  try {
    // Execute the query using your standard helper
    const result = await executeQuery(query, [id]);
    
    // The result from executeQuery is an object with a 'rows' array
    const guest = result.rows[0]; 

    if (!guest) {
      return res.status(404).json({
        success: false,
        error: 'Guest not found'
      });
    }

    res.json({
      success: true,
      data: guest
    });
  } catch (error) {
    console.error('Get Guest By ID Error:', error);
    res.status(500).json({
      success: false,
      error: `Internal server error while fetching guest details: ${error.message}`
    });
  }
});

/**
 * Create new guest
 */


const createGuest = asyncHandler(async (req, res) => {
  const {
    full_name,
    email,
    phone,
    address,
    gender,
    date_of_birth,
    nic, // Used for National ID
    nationality
  } = req.body;

  // 1. Validate required field (full_name is NOT NULL)
  if (!full_name) {
    return res.status(400).json({ success: false, error: 'Full Name is required.' });
  }

  // 2. Check for Unique Constraint Violations (email, phone, nic)
  const checkQuery = `
    SELECT guest_id FROM public.guest
    WHERE (email = $1 AND $1 IS NOT NULL) 
       OR (phone = $2 AND $2 IS NOT NULL)
       OR (nic = $3 AND $3 IS NOT NULL)
  `;
  
  // NOTE: If any of these fields are NULL in the request, the 'AND $X IS NOT NULL' clause
  // ensures we only check existing non-NULL database entries against non-NULL request values.
  const checkResult = await executeQuery(checkQuery, [email, phone, nic]);

  if (checkResult.rows.length > 0) {
    return res.status(409).json({
      success: false,
      error: 'Guest with this email, phone, or NIC already exists.'
    });
  }

  // 3. Prepare Guest Insertion Query
  const insertQuery = {
    text: `
      INSERT INTO public.guest (
        nic, full_name, email, phone, gender, date_of_birth, address, nationality
      ) 
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING guest_id, full_name, email
    `,
    params: [
      nic || null,
      full_name,
      email || null,
      phone || null,
      gender || null,
      date_of_birth || null,
      address || null,
      nationality || null
    ]
  };

  try {
    const results = await executeTransaction([insertQuery]);
    const guest = results[0].rows[0];

    res.status(201).json({
      success: true,
      message: 'Guest successfully registered.',
      data: guest
    });

  } catch (error) {
    console.error('Guest creation error:', error);
    if (error.code === '23505') { 
      return res.status(409).json({
        success: false,
        error: 'A unique constraint violation occurred (e.g., email already registered).'
      });
    }
    res.status(500).json({
      success: false,
      error: `Internal server error during guest creation: ${error.message}`
    });
  }
});


/**
 * Delete guest
 */

const deleteGuest = asyncHandler(async (req, res) => {
  // The ID captured from the route /api/guests/:id is accessed via req.params
  const { id: guestId } = req.params;

  if (!guestId) {
    return res.status(400).json({ success: false, error: 'Guest ID is required.' });
  }

  // 1. Check for Active Bookings (Executed outside main transaction for quick failure)
  // Uses correct table (booking) and status ENUM values.
  const bookingCheckQuery = `
    SELECT COUNT(booking_id) AS active_bookings
    FROM public.booking 
    WHERE guest_id = $1 
      AND status IN ('Booked', 'Checked-In') -- Confirmed status ENUM values
  `;

  const checkResult = await executeQuery(bookingCheckQuery, [guestId]);
  const activeBookings = parseInt(checkResult.rows[0].active_bookings);

  if (activeBookings > 0) {
    return res.status(400).json({
      success: false,
      error: `Cannot delete guest. ${activeBookings} active booking(s) found (Booked or Checked-In).`
    });
  }

  // 2. Prepare Transaction Queries
  // Note: Due to Foreign Key constraints (user_account, customer, booking, pre_booking),
  // deleting the guest may fail unless CASCADE is used on those FKs or related records are deleted first.
  // We assume the database has CASCADE ON DELETE for related tables or that related records are removed by the client.
  
  const deleteQuery = {
    text: 'DELETE FROM public.guest WHERE guest_id = $1 RETURNING guest_id',
    params: [guestId]
  };

  try {
    // 3. Execute Transaction
    const results = await executeTransaction([deleteQuery]);
    const deletedGuest = results[0].rows[0];

    if (!deletedGuest) {
      return res.status(404).json({
        success: false,
        error: 'Guest not found.'
      });
    }

    res.json({
      success: true,
      message: `✅ Guest ID ${guestId} deleted successfully.`
    });

  } catch (error) {
    console.error('Guest Deletion Transaction Error:', error);
    // 23503 is PostgreSQL Foreign Key violation error code
    if (error.code === '23503') {
        return res.status(400).json({
            success: false,
            error: 'Cannot delete guest. Foreign key constraints exist (e.g., linked to user account or past records).'
        });
    }
    res.status(500).json({
      success: false,
      error: `Internal server error during guest deletion: ${error.message}`
    });
  }
});

/**
 * Get guest booking history
 */
// const getGuestBookings = asyncHandler(async (req, res) => {
//   const { id } = req.params;
//   const { status, page = 1, limit = 10 } = req.query;

//   let whereConditions = ['b.guest_id = $1'];
//   let params = [id];
//   let paramCount = 1;

//   // Status filter
//   if (status) {
//     paramCount++;
//     whereConditions.push(`b.status = $${paramCount}`);
//     params.push(status);
//   }

//   const offset = (parseInt(page) - 1) * parseInt(limit);

//   // Count query
//   const countQuery = `
//     SELECT COUNT(*) 
//     FROM bookings b
//     WHERE ${whereConditions.join(' AND ')}
//   `;

//   // Main query
//   const mainQuery = `
//     SELECT 
//       b.*,
//       r.room_number,
//       r.room_type,
//       r.price_per_night,
//       json_agg(
//         json_build_object(
//           'id', p.id,
//           'amount', p.amount,
//           'payment_method', p.payment_method,
//           'payment_status', p.payment_status,
//           'payment_date', p.payment_date
//         )
//       ) as payments
//     FROM bookings b
//     JOIN rooms r ON b.room_id = r.id
//     LEFT JOIN payments p ON b.id = p.booking_id
//     WHERE ${whereConditions.join(' AND ')}
//     GROUP BY b.id, r.id
//     ORDER BY b.created_at DESC
//     LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
//   `;

//   params.push(parseInt(limit), offset);

//   const [countResult, bookings] = await Promise.all([
//     sequelize.query(countQuery, { bind: params, type: sequelize.QueryTypes.SELECT }),
//     sequelize.query(mainQuery, { bind: params, type: sequelize.QueryTypes.SELECT })
//   ]);

//   const totalCount = parseInt(countResult[0].count);

//   res.json({
//     success: true,
//     data: bookings,
//     pagination: {
//       page: parseInt(page),
//       limit: parseInt(limit),
//       total: totalCount,
//       pages: Math.ceil(totalCount / limit)
//     }
//   });
// });

const getGuestBookings = asyncHandler(async (req, res) => {
  // ID is the guest_id from /api/guests/:id/bookings
  const { id: guest_id } = req.params;
  const { status, page = 1, limit = 10 } = req.query;

  // 1. Setup Parameters and WHERE Clauses
  // Start with the mandatory guest_id filter ($1)
  let whereConditions = [`b.guest_id = $1`];
  let params = [guest_id];
  let paramCount = 1;

  // Status filter (uses b.status and $2)
  if (status) {
    paramCount++;
    whereConditions.push(`b.status = $${paramCount}`);
    params.push(status);
  }

  const offset = (parseInt(page) - 1) * parseInt(limit);
  const filterParams = [...params]; // Parameters used only for filtering (Count Query)

  // 2. Define SQL Queries
  
  // Base Query Segment (used by both Count and Main Query before aggregation/pagination)
  // NOTE: Use correct table and column names (public.booking, public.room, etc.)
  const baseQuerySelect = `
    SELECT 
      b.booking_id,
      b.check_in_date,
      b.check_out_date,
      b.status,
      b.created_at,
      b.advance_payment,
      b.booked_rate,
      b.tax_rate_percent,
      b.discount_amount,
      r.room_number,
      rt.name AS room_type_name,
      rt.daily_rate
    FROM public.booking b
    JOIN public.room r ON b.room_id = r.room_id
    JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
    WHERE ${whereConditions.join(' AND ')}
  `;

  // Count query
  const countQuery = `
    SELECT COUNT(b.booking_id) 
    FROM public.booking b
    WHERE ${whereConditions.join(' AND ')}
  `;

  // Main query (includes payment aggregation)
  const mainQuery = `
    WITH BaseBookings AS (${baseQuerySelect})
    SELECT 
      bb.*, -- Select all columns from the base booking result
      COALESCE(
        json_agg(
          json_build_object(
            'payment_id', p.payment_id,
            'amount', p.amount,
            'method', p.method,
            'paid_at', p.paid_at
          )
        ) FILTER (WHERE p.payment_id IS NOT NULL), 
        '[]'
      ) AS payments
    FROM BaseBookings bb
    LEFT JOIN public.payment p ON bb.booking_id = p.booking_id
    
    -- Group by all non-aggregated columns from BaseBookings (which is all selected columns)
    GROUP BY 
      bb.booking_id, bb.check_in_date, bb.check_out_date, bb.status, 
      bb.created_at, bb.advance_payment, bb.booked_rate, bb.tax_rate_percent,
      bb.discount_amount, bb.room_number, bb.room_type_name, bb.daily_rate
      
    ORDER BY bb.created_at DESC
    LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
  `;

  // 3. Execution
  
  // Add pagination parameters to the params array
  params.push(parseInt(limit), offset);

  const [countResult, bookingsResult] = await Promise.all([
    executeQuery(countQuery, filterParams), // Executes the simple count query
    executeQuery(mainQuery, params)         // Executes the complex query
  ]);

  const totalCount = parseInt(countResult.rows[0].count);

  res.json({
    success: true,
    data: {
      bookings: bookingsResult.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalCount,
        pages: Math.ceil(totalCount / limit)
      }
    }
  });
});

/**
 * Get guest statistics
 */

const getGuestStatistics = asyncHandler(async (req, res) => {
  const { id: guestId } = req.params;

  if (!guestId) {
    return res.status(400).json({ success: false, error: 'Guest ID is required.' });
  }

  // 1. Main Statistics Query
  const statisticsQuery = `
    SELECT 
      COUNT(b.booking_id) AS total_bookings,
      COUNT(CASE WHEN b.status = 'Checked-Out' THEN 1 END) AS completed_stays,
      COUNT(CASE WHEN b.status IN ('Booked', 'Checked-In') THEN 1 END) AS upcoming_stays,
      
      -- Total spent calculation: Sum of all payments minus all refunds
      COALESCE(SUM(fn_total_paid(b.booking_id)), 0) - COALESCE(SUM(fn_total_refunds(b.booking_id)), 0) AS total_net_spent,
      
      -- Average booking value: Use fn_bill_total for a single booking before payments/services
      COALESCE(AVG(fn_bill_total(b.booking_id)), 0) AS avg_booking_value,
      
      MIN(b.check_in_date) AS first_booking_check_in,
      MAX(b.check_in_date) AS last_booking_check_in
      
    FROM public.booking b 
    WHERE b.guest_id = $1
  `;

  // 2. Favorite Room Type Query
  const favoriteRoomQuery = `
    SELECT 
      rt.name AS room_type,
      COUNT(b.booking_id) AS booking_count
    FROM public.booking b
    JOIN public.room r ON b.room_id = r.room_id
    JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
    WHERE b.guest_id = $1
    AND b.status IN ('Booked', 'Checked-In', 'Checked-Out') -- Consider only non-cancelled bookings
    GROUP BY rt.name
    ORDER BY booking_count DESC
    LIMIT 1
  `;

  try {
    const [statisticsResult, favoriteRoomResult] = await Promise.all([
      executeQuery(statisticsQuery, [guestId]),
      executeQuery(favoriteRoomQuery, [guestId])
    ]);

    const stats = statisticsResult.rows[0] || {};
    const favoriteRoom = favoriteRoomResult.rows[0];

    res.json({
      success: true,
      data: {
        total_bookings: parseInt(stats.total_bookings || 0),
        completed_stays: parseInt(stats.completed_stays || 0),
        upcoming_stays: parseInt(stats.upcoming_stays || 0),
        
        // Use direct float values from the database
        total_net_spent: parseFloat(stats.total_net_spent || 0).toFixed(2),
        avg_booking_value: parseFloat(stats.avg_booking_value || 0).toFixed(2),
        
        first_booking: stats.first_booking_check_in,
        last_booking: stats.last_booking_check_in,
        
        favorite_room_type: favoriteRoom ? favoriteRoom.room_type : null,
        favorite_room_bookings: favoriteRoom ? parseInt(favoriteRoom.booking_count) : 0
      }
    });

  } catch (error) {
    console.error('Get Guest Statistics Error:', error);
    res.status(500).json({
      success: false,
      error: `Internal server error while fetching guest statistics: ${error.message}`
    });
  }
});

/**
 * Search guests by multiple criteria
 */

const searchGuests = asyncHandler(async (req, res) => {
  const { query, field = 'all' } = req.query;

  if (!query) {
    return res.status(400).json({
      success: false,
      error: 'Search query is required'
    });
  }

  let whereCondition = '';
  let paramIndex = 1; 
  let searchParam = `%${query}%`;
  let params = [searchParam];

  // Map requested field to schema columns (full_name, nic, email, phone)
  switch (field) {
    case 'name':
      whereCondition = `g.full_name ILIKE $${paramIndex}`;
      break;
    case 'nic':
      whereCondition = `g.nic ILIKE $${paramIndex}`;
      break;
    case 'email':
      whereCondition = `g.email ILIKE $${paramIndex}`;
      break;
    case 'phone':
      whereCondition = `g.phone ILIKE $${paramIndex}`;
      break;
    case 'all':
    default:
      // FIX 1: Ensure this is a single, clean string without unnecessary line breaks
      whereCondition = `(g.full_name ILIKE $${paramIndex} OR g.nic ILIKE $${paramIndex} OR g.email ILIKE $${paramIndex} OR g.phone ILIKE $${paramIndex})`;
      break;
  }

  const searchQuery = `
    SELECT 
      g.guest_id,
      g.full_name,
      g.nic,
      g.email,
      g.phone,
      g.nationality  -- FIX 2: Removed trailing comma here
    FROM public.guest g
    WHERE ${whereCondition}
    ORDER BY 
      CASE 
        WHEN g.full_name ILIKE $1 THEN 1 
        WHEN g.nic ILIKE $1 THEN 2
        WHEN g.email ILIKE $1 THEN 3
        WHEN g.phone ILIKE $1 THEN 4
        ELSE 5
      END,
      g.full_name
    LIMIT 20
  `;

  try {
    const guests = await executeQuery(searchQuery, params);

    res.json({
      success: true,
      data: guests.rows
    });
  } catch (error) {
    console.error('Guest Search Error:', error);
    res.status(500).json({
      success: false,
      error: `Internal server error during guest search: ${error.message}`
    });
  }
});


/**
 * Get guests by country statistics
 */
// const getGuestsByCountry = asyncHandler(async (req, res) => {
//   const query = `
//     SELECT 
//       COALESCE(country, 'Unknown') as country,
//       COUNT(*) as guest_count,
//       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM guests), 2) as percentage
//     FROM guests 
//     GROUP BY country
//     ORDER BY guest_count DESC
//   `;

//   const countryStats = await sequelize.query(query, {
//     type: sequelize.QueryTypes.SELECT
//   });

//   res.json({
//     success: true,
//     data: countryStats
//   });
// });

const getGuestsByNationality = asyncHandler(async (req, res) => {
  // Use 'nationality' as the grouping field
  const query = `
    SELECT 
      COALESCE(g.nationality, 'Unknown') AS nationality,
      COUNT(g.guest_id) AS guest_count,
      -- Calculate percentage based on total guests
      ROUND(COUNT(g.guest_id) * 100.0 / (SELECT COUNT(*) FROM public.guest), 2) AS percentage
    FROM public.guest g
    GROUP BY g.nationality
    ORDER BY guest_count DESC
  `;

  try {
    const nationalityStats = await executeQuery(query);

    res.json({
      success: true,
      data: nationalityStats.rows
    });
  } catch (error) {
    console.error('Get Guests by Nationality Error:', error);
    res.status(500).json({
      success: false,
      error: `Internal server error while fetching guest statistics: ${error.message}`
    });
  }
});

module.exports = {
  getAllGuests,
  getGuestById,
  createGuest,
  deleteGuest,
  getGuestBookings,
  getGuestStatistics,
  searchGuests,
  getGuestsByNationality
};