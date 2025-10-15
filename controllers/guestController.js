const { sequelize } = require('../models');
const { asyncHandler } = require('../middleware/errorHandler');
const { Op } = require('sequelize');

/**
 * Get all guests with search and filtering
 */
const getAllGuests = asyncHandler(async (req, res) => {
  const {
    search,
    country,
    email,
    phone,
    page = 1,
    limit = 10,
    sort_by = 'last_name',
    order = 'asc'
  } = req.query;

  let whereConditions = ['1=1'];
  let params = [];
  let paramCount = 0;

  // Search filter (name, email, phone)
  if (search) {
    paramCount++;
    whereConditions.push(`
      (first_name ILIKE $${paramCount} 
      OR last_name ILIKE $${paramCount} 
      OR email ILIKE $${paramCount} 
      OR phone ILIKE $${paramCount})
    `);
    params.push(`%${search}%`);
  }

  // Country filter
  if (country) {
    paramCount++;
    whereConditions.push(`country ILIKE $${paramCount}`);
    params.push(`%${country}%`);
  }

  // Email filter
  if (email) {
    paramCount++;
    whereConditions.push(`email ILIKE $${paramCount}`);
    params.push(`%${email}%`);
  }

  // Phone filter
  if (phone) {
    paramCount++;
    whereConditions.push(`phone ILIKE $${paramCount}`);
    params.push(`%${phone}%`);
  }

  const offset = (parseInt(page) - 1) * parseInt(limit);

  // Validate sort field
  const allowedSortFields = ['first_name', 'last_name', 'email', 'created_at', 'country'];
  const sortField = allowedSortFields.includes(sort_by) ? sort_by : 'last_name';
  const sortOrder = order.toLowerCase() === 'desc' ? 'DESC' : 'ASC';

  // Count query
  const countQuery = `
    SELECT COUNT(*) 
    FROM guests 
    WHERE ${whereConditions.join(' AND ')}
  `;

  // Main query
  const mainQuery = `
    SELECT * 
    FROM guests 
    WHERE ${whereConditions.join(' AND ')}
    ORDER BY ${sortField} ${sortOrder}
    LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
  `;

  params.push(parseInt(limit), offset);

  const [countResult, guests] = await Promise.all([
    sequelize.query(countQuery, { bind: params, type: sequelize.QueryTypes.SELECT }),
    sequelize.query(mainQuery, { bind: params, type: sequelize.QueryTypes.SELECT })
  ]);

  const totalCount = parseInt(countResult[0].count);

  res.json({
    success: true,
    data: guests,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: totalCount,
      pages: Math.ceil(totalCount / limit)
    }
  });
});

/**
 * Get guest by ID
 */
const getGuestById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const query = `
    SELECT * FROM guests WHERE id = $1
  `;

  const [guest] = await sequelize.query(query, {
    bind: [id],
    type: sequelize.QueryTypes.SELECT
  });

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
});

/**
 * Create new guest
 */
const createGuest = asyncHandler(async (req, res) => {
  const {
    first_name,
    last_name,
    email,
    phone,
    address,
    city,
    country,
    date_of_birth,
    id_type,
    id_number,
    preferences
  } = req.body;

  // Start transaction
  const transaction = await sequelize.transaction();

  try {
    // Check if guest with same email or phone exists
    if (email || phone) {
      const checkQuery = `
        SELECT id FROM guests 
        WHERE (email = $1 AND $1 IS NOT NULL) 
           OR (phone = $2 AND $2 IS NOT NULL)
      `;

      const [existingGuest] = await sequelize.query(checkQuery, {
        bind: [email, phone],
        type: sequelize.QueryTypes.SELECT,
        transaction
      });

      if (existingGuest) {
        await transaction.rollback();
        return res.status(409).json({
          success: false,
          error: 'Guest with this email or phone already exists'
        });
      }
    }

    // Create guest
    const insertQuery = `
      INSERT INTO guests (
        first_name, last_name, email, phone, address, city, country,
        date_of_birth, id_type, id_number, preferences
      ) 
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *
    `;

    const [guest] = await sequelize.query(insertQuery, {
      bind: [
        first_name,
        last_name,
        email,
        phone,
        address,
        city,
        country,
        date_of_birth,
        id_type,
        id_number,
        preferences || {}
      ],
      type: sequelize.QueryTypes.SELECT,
      transaction
    });

    await transaction.commit();

    res.status(201).json({
      success: true,
      message: 'Guest created successfully',
      data: guest
    });

  } catch (error) {
    await transaction.rollback();
    throw error;
  }
});

/**
 * Update guest
 */
const updateGuest = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const updateData = req.body;

  // Start transaction
  const transaction = await sequelize.transaction();

  try {
    // Check if guest exists
    const checkQuery = 'SELECT id FROM guests WHERE id = $1';
    const [existingGuest] = await sequelize.query(checkQuery, {
      bind: [id],
      type: sequelize.QueryTypes.SELECT,
      transaction
    });

    if (!existingGuest) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        error: 'Guest not found'
      });
    }

    // Check for duplicate email/phone if updating those fields
    if (updateData.email || updateData.phone) {
      const duplicateQuery = `
        SELECT id FROM guests 
        WHERE ((email = $1 AND $1 IS NOT NULL) 
            OR (phone = $2 AND $2 IS NOT NULL))
          AND id != $3
      `;

      const [duplicateGuest] = await sequelize.query(duplicateQuery, {
        bind: [updateData.email, updateData.phone, id],
        type: sequelize.QueryTypes.SELECT,
        transaction
      });

      if (duplicateGuest) {
        await transaction.rollback();
        return res.status(409).json({
          success: false,
          error: 'Another guest with this email or phone already exists'
        });
      }
    }

    // Build dynamic update query
    const updateFields = [];
    const params = [];
    let paramCount = 0;

    const fieldMappings = {
      first_name: 'first_name',
      last_name: 'last_name',
      email: 'email',
      phone: 'phone',
      address: 'address',
      city: 'city',
      country: 'country',
      date_of_birth: 'date_of_birth',
      id_type: 'id_type',
      id_number: 'id_number',
      preferences: 'preferences'
    };

    Object.keys(updateData).forEach(field => {
      if (fieldMappings[field] !== undefined && updateData[field] !== undefined) {
        paramCount++;
        updateFields.push(`${fieldMappings[field]} = $${paramCount}`);
        params.push(updateData[field]);
      }
    });

    if (updateFields.length === 0) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        error: 'No valid fields to update'
      });
    }

    paramCount++;
    params.push(id);

    const updateQuery = `
      UPDATE guests 
      SET ${updateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const [guest] = await sequelize.query(updateQuery, {
      bind: params,
      type: sequelize.QueryTypes.SELECT,
      transaction
    });

    await transaction.commit();

    res.json({
      success: true,
      message: 'Guest updated successfully',
      data: guest
    });

  } catch (error) {
    await transaction.rollback();
    throw error;
  }
});

/**
 * Delete guest
 */
const deleteGuest = asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Start transaction
  const transaction = await sequelize.transaction();

  try {
    // Check if guest has active bookings
    const bookingCheckQuery = `
      SELECT COUNT(*) as active_bookings
      FROM bookings 
      WHERE guest_id = $1 AND status IN ('confirmed', 'checked_in')
    `;

    const [result] = await sequelize.query(bookingCheckQuery, {
      bind: [id],
      type: sequelize.QueryTypes.SELECT,
      transaction
    });

    if (parseInt(result.active_bookings) > 0) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        error: 'Cannot delete guest with active bookings'
      });
    }

    // Delete guest
    const deleteQuery = 'DELETE FROM guests WHERE id = $1 RETURNING id';
    const [deletedGuest] = await sequelize.query(deleteQuery, {
      bind: [id],
      type: sequelize.QueryTypes.SELECT,
      transaction
    });

    if (!deletedGuest) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        error: 'Guest not found'
      });
    }

    await transaction.commit();

    res.json({
      success: true,
      message: 'Guest deleted successfully'
    });

  } catch (error) {
    await transaction.rollback();
    throw error;
  }
});

/**
 * Get guest booking history
 */
const getGuestBookings = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status, page = 1, limit = 10 } = req.query;

  let whereConditions = ['b.guest_id = $1'];
  let params = [id];
  let paramCount = 1;

  // Status filter
  if (status) {
    paramCount++;
    whereConditions.push(`b.status = $${paramCount}`);
    params.push(status);
  }

  const offset = (parseInt(page) - 1) * parseInt(limit);

  // Count query
  const countQuery = `
    SELECT COUNT(*) 
    FROM bookings b
    WHERE ${whereConditions.join(' AND ')}
  `;

  // Main query
  const mainQuery = `
    SELECT 
      b.*,
      r.room_number,
      r.room_type,
      r.price_per_night,
      json_agg(
        json_build_object(
          'id', p.id,
          'amount', p.amount,
          'payment_method', p.payment_method,
          'payment_status', p.payment_status,
          'payment_date', p.payment_date
        )
      ) as payments
    FROM bookings b
    JOIN rooms r ON b.room_id = r.id
    LEFT JOIN payments p ON b.id = p.booking_id
    WHERE ${whereConditions.join(' AND ')}
    GROUP BY b.id, r.id
    ORDER BY b.created_at DESC
    LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
  `;

  params.push(parseInt(limit), offset);

  const [countResult, bookings] = await Promise.all([
    sequelize.query(countQuery, { bind: params, type: sequelize.QueryTypes.SELECT }),
    sequelize.query(mainQuery, { bind: params, type: sequelize.QueryTypes.SELECT })
  ]);

  const totalCount = parseInt(countResult[0].count);

  res.json({
    success: true,
    data: bookings,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: totalCount,
      pages: Math.ceil(totalCount / limit)
    }
  });
});

/**
 * Get guest statistics
 */
const getGuestStatistics = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const statisticsQuery = `
    SELECT 
      COUNT(*) as total_bookings,
      COUNT(CASE WHEN status = 'checked_out' THEN 1 END) as completed_stays,
      COUNT(CASE WHEN status IN ('confirmed', 'checked_in') THEN 1 END) as upcoming_stays,
      COALESCE(SUM(total_amount), 0) as total_spent,
      COALESCE(AVG(total_amount), 0) as avg_booking_value,
      MIN(check_in) as first_booking,
      MAX(check_in) as last_booking
    FROM bookings 
    WHERE guest_id = $1
  `;

  const [statistics] = await sequelize.query(statisticsQuery, {
    bind: [id],
    type: sequelize.QueryTypes.SELECT
  });

  // Get favorite room type
  const favoriteRoomQuery = `
    SELECT 
      r.room_type,
      COUNT(*) as booking_count
    FROM bookings b
    JOIN rooms r ON b.room_id = r.id
    WHERE b.guest_id = $1
    GROUP BY r.room_type
    ORDER BY booking_count DESC
    LIMIT 1
  `;

  const [favoriteRoom] = await sequelize.query(favoriteRoomQuery, {
    bind: [id],
    type: sequelize.QueryTypes.SELECT
  });

  res.json({
    success: true,
    data: {
      ...statistics,
      favorite_room_type: favoriteRoom?.room_type || null,
      favorite_room_bookings: favoriteRoom?.booking_count || 0
    }
  });
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
  let searchParam = `%${query}%`;

  switch (field) {
    case 'name':
      whereCondition = '(first_name ILIKE $1 OR last_name ILIKE $1)';
      break;
    case 'email':
      whereCondition = 'email ILIKE $1';
      break;
    case 'phone':
      whereCondition = 'phone ILIKE $1';
      break;
    case 'all':
    default:
      whereCondition = '(first_name ILIKE $1 OR last_name ILIKE $1 OR email ILIKE $1 OR phone ILIKE $1)';
      break;
  }

  const searchQuery = `
    SELECT 
      id,
      first_name,
      last_name,
      email,
      phone,
      country,
      created_at
    FROM guests 
    WHERE ${whereCondition}
    ORDER BY 
      CASE 
        WHEN first_name ILIKE $1 OR last_name ILIKE $1 THEN 1
        WHEN email ILIKE $1 THEN 2
        WHEN phone ILIKE $1 THEN 3
        ELSE 4
      END,
      last_name, first_name
    LIMIT 20
  `;

  const guests = await sequelize.query(searchQuery, {
    bind: [searchParam],
    type: sequelize.QueryTypes.SELECT
  });

  res.json({
    success: true,
    data: guests
  });
});

/**
 * Get guests by country statistics
 */
const getGuestsByCountry = asyncHandler(async (req, res) => {
  const query = `
    SELECT 
      COALESCE(country, 'Unknown') as country,
      COUNT(*) as guest_count,
      ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM guests), 2) as percentage
    FROM guests 
    GROUP BY country
    ORDER BY guest_count DESC
  `;

  const countryStats = await sequelize.query(query, {
    type: sequelize.QueryTypes.SELECT
  });

  res.json({
    success: true,
    data: countryStats
  });
});

module.exports = {
  getAllGuests,
  getGuestById,
  createGuest,
  updateGuest,
  deleteGuest,
  getGuestBookings,
  getGuestStatistics,
  searchGuests,
  getGuestsByCountry
};