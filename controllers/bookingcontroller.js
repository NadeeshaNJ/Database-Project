const { executeQuery } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const { BOOKING_STATUS } = require('../utils/enums');

/**
 * Get all bookings with filtering
 */
const getAllBookings = asyncHandler(async (req, res) => {
    const {
        status,
        check_in_start,
        check_in_end,
        guest_name,
        room_number,
        branch_id,
        page = 1,
        limit = 100
    } = req.query;

    const offset = (page - 1) * limit;
    const params = [];
    let paramIndex = 0;

    let query = `
        SELECT 
            b.booking_id,
            b.check_in_date,
            b.check_out_date,
            b.status,
            b.booked_rate,
            b.tax_rate_percent,
            b.created_at,
            g.guest_id,
            g.full_name as guest_name,
            g.email as guest_email,
            g.phone as guest_phone,
            r.room_id,
            r.room_number,
            r.branch_id,
            br.branch_name,
            rt.name as room_type,
            rt.daily_rate,
            p.payment_id,
            p.method as payment_method,
            p.amount as payment_amount,
            p.paid_at,
            b.advance_payment,
            b.discount_amount,
            b.late_fee_amount,
            b.room_estimate,
            b.preferred_payment_method,
            (b.check_out_date - b.check_in_date) as nights
        FROM booking b
        JOIN guest g ON b.guest_id = g.guest_id
        JOIN room r ON b.room_id = r.room_id
        JOIN branch br ON r.branch_id = br.branch_id
        JOIN room_type rt ON r.room_type_id = rt.room_type_id
        LEFT JOIN payment p ON b.booking_id = p.booking_id
        WHERE 1=1
    `;

    // Status filter
    if (status && status !== 'All') {
        query += ` AND b.status = $${++paramIndex}`;
        params.push(status);
    }

    // Date range filters
    if (check_in_start && check_in_end) {
        query += ` AND b.check_in_date BETWEEN $${++paramIndex} AND $${++paramIndex}`;
        params.push(check_in_start, check_in_end);
    }

    // Guest name filter
    if (guest_name) {
        query += ` AND g.full_name ILIKE $${++paramIndex}`;
        params.push(`%${guest_name}%`);
    }

    // Room number filter
    if (room_number) {
        query += ` AND r.room_number = $${++paramIndex}`;
        params.push(room_number);
    }

    // Branch filter
    if (branch_id) {
        query += ` AND r.branch_id = $${++paramIndex}`;
        params.push(branch_id);
    }

    query += ` ORDER BY b.created_at DESC LIMIT $${++paramIndex} OFFSET $${++paramIndex}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await executeQuery(query, params);

    // Get total count
    let countQuery = `
        SELECT COUNT(DISTINCT b.booking_id) as total
        FROM booking b
        JOIN guest g ON b.guest_id = g.guest_id
        JOIN room r ON b.room_id = r.room_id
        WHERE 1=1
    `;
    
    const countParams = [];
    let countParamIndex = 0;
    
    if (status && status !== 'All') {
        countQuery += ` AND b.status = $${++countParamIndex}`;
        countParams.push(status);
    }
    if (check_in_start && check_in_end) {
        countQuery += ` AND b.check_in_date BETWEEN $${++countParamIndex} AND $${++countParamIndex}`;
        countParams.push(check_in_start, check_in_end);
    }
    if (guest_name) {
        countQuery += ` AND g.full_name ILIKE $${++countParamIndex}`;
        countParams.push(`%${guest_name}%`);
    }
    if (room_number) {
        countQuery += ` AND r.room_number = $${++countParamIndex}`;
        countParams.push(room_number);
    }

    const countResult = await executeQuery(countQuery, countParams);
    const totalBookings = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(totalBookings / limit);

    res.json({
        success: true,
        data: {
            bookings: result.rows,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: totalBookings,
                totalPages
            }
        }
    });
});

module.exports = {
    getAllBookings
};
