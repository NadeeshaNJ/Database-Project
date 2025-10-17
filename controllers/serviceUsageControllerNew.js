const { executeQuery } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * Get all service usages with filters
 */
const getAllServiceUsages = asyncHandler(async (req, res) => {
    const {
        booking_id,
        service_id,
        guest_name,
        start_date,
        end_date,
        page = 1,
        limit = 100
    } = req.query;

    const offset = (page - 1) * limit;
    const params = [];
    let paramIndex = 0;

    let query = `
        SELECT 
            su.service_usage_id,
            su.booking_id,
            su.service_id,
            su.used_on,
            su.qty,
            su.unit_price_at_use,
            (su.qty * su.unit_price_at_use) AS total_price,
            sc.name AS service_name,
            sc.code AS service_code,
            sc.category AS service_category,
            b.check_in_date,
            b.check_out_date,
            b.status AS booking_status,
            g.guest_id,
            g.full_name AS guest_name,
            g.email AS guest_email,
            r.room_number,
            rt.name AS room_type
        FROM service_usage su
        JOIN service_catalog sc ON su.service_id = sc.service_id
        JOIN booking b ON su.booking_id = b.booking_id
        JOIN guest g ON b.guest_id = g.guest_id
        JOIN room r ON b.room_id = r.room_id
        JOIN room_type rt ON r.room_type_id = rt.room_type_id
        WHERE 1=1
    `;

    // Filters
    if (booking_id) {
        query += ` AND su.booking_id = $${++paramIndex}`;
        params.push(booking_id);
    }

    if (service_id) {
        query += ` AND su.service_id = $${++paramIndex}`;
        params.push(service_id);
    }

    if (guest_name) {
        query += ` AND g.full_name ILIKE $${++paramIndex}`;
        params.push(`%${guest_name}%`);
    }

    if (start_date && end_date) {
        query += ` AND su.used_on BETWEEN $${++paramIndex} AND $${++paramIndex}`;
        params.push(start_date, end_date);
    }

    query += ` ORDER BY su.used_on DESC`;
    query += ` LIMIT $${++paramIndex} OFFSET $${++paramIndex}`;
    params.push(parseInt(limit), parseInt(offset));

    // Count query
    let countQuery = `
        SELECT COUNT(*) as count
        FROM service_usage su
        JOIN service_catalog sc ON su.service_id = sc.service_id
        JOIN booking b ON su.booking_id = b.booking_id
        JOIN guest g ON b.guest_id = g.guest_id
        WHERE 1=1
    `;

    const countParams = [];
    let countParamIndex = 0;

    if (booking_id) {
        countQuery += ` AND su.booking_id = $${++countParamIndex}`;
        countParams.push(booking_id);
    }

    if (service_id) {
        countQuery += ` AND su.service_id = $${++countParamIndex}`;
        countParams.push(service_id);
    }

    if (guest_name) {
        countQuery += ` AND g.full_name ILIKE $${++countParamIndex}`;
        countParams.push(`%${guest_name}%`);
    }

    if (start_date && end_date) {
        countQuery += ` AND su.used_on BETWEEN $${++countParamIndex} AND $${++countParamIndex}`;
        countParams.push(start_date, end_date);
    }

    const [results, countResult] = await Promise.all([
        executeQuery(query, params),
        executeQuery(countQuery, countParams)
    ]);

    const total = parseInt(countResult.rows[0].count);
    const totalPages = Math.ceil(total / limit);

    res.json({
        success: true,
        data: {
            serviceUsages: results.rows,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages,
                hasNext: page < totalPages,
                hasPrev: page > 1
            }
        }
    });
});

/**
 * Get service usages by booking ID
 */
const getServiceUsagesByBooking = asyncHandler(async (req, res) => {
    const { bookingId } = req.params;

    const query = `
        SELECT 
            su.service_usage_id,
            su.booking_id,
            su.service_id,
            su.used_on,
            su.qty,
            su.unit_price_at_use,
            (su.qty * su.unit_price_at_use) AS total_price,
            sc.name AS service_name,
            sc.code AS service_code,
            sc.category AS service_category
        FROM service_usage su
        JOIN service_catalog sc ON su.service_id = sc.service_id
        WHERE su.booking_id = $1
        ORDER BY su.used_on DESC
    `;

    const result = await executeQuery(query, [bookingId]);

    // Calculate total
    const totalCharges = result.rows.reduce((sum, usage) => {
        return sum + parseFloat(usage.total_price || 0);
    }, 0);

    res.json({
        success: true,
        data: {
            serviceUsages: result.rows,
            summary: {
                totalServices: result.rows.length,
                totalCharges: totalCharges.toFixed(2)
            }
        }
    });
});

module.exports = {
    getAllServiceUsages,
    getServiceUsagesByBooking
};
