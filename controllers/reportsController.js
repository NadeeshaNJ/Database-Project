const { executeQuery } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * Get revenue report
 */
const getRevenueReport = asyncHandler(async (req, res) => {
    const {
        start_date,
        end_date,
        branch_id,
        group_by = 'day' // day, week, month
    } = req.query;

    const params = [];
    let paramIndex = 0;

    let dateGrouping;
    switch (group_by) {
        case 'week':
            dateGrouping = `DATE_TRUNC('week', p.paid_at)`;
            break;
        case 'month':
            dateGrouping = `DATE_TRUNC('month', p.paid_at)`;
            break;
        default:
            dateGrouping = `DATE(p.paid_at)`;
    }

    let query = `
        SELECT 
            ${dateGrouping} AS period,
            COUNT(DISTINCT p.booking_id) AS total_bookings,
            COUNT(p.payment_id) AS total_transactions,
            SUM(p.amount) AS total_revenue,
            AVG(p.amount) AS avg_transaction,
            SUM(CASE WHEN p.method = 'Card' THEN p.amount ELSE 0 END) AS card_revenue,
            SUM(CASE WHEN p.method = 'Cash' THEN p.amount ELSE 0 END) AS cash_revenue,
            SUM(CASE WHEN p.method = 'Online' THEN p.amount ELSE 0 END) AS online_revenue,
            SUM(CASE WHEN p.method = 'BankTransfer' THEN p.amount ELSE 0 END) AS bank_transfer_revenue
        FROM payment p
        JOIN booking b ON p.booking_id = b.booking_id
        JOIN room r ON b.room_id = r.room_id
        WHERE 1=1
    `;

    if (start_date && end_date) {
        query += ` AND p.paid_at BETWEEN $${++paramIndex} AND $${++paramIndex}`;
        params.push(start_date, end_date);
    }

    if (branch_id) {
        query += ` AND r.branch_id = $${++paramIndex}`;
        params.push(branch_id);
    }

    query += ` GROUP BY period ORDER BY period DESC`;

    const result = await executeQuery(query, params);

    res.json({
        success: true,
        data: {
            report: result.rows,
            summary: {
                totalRevenue: result.rows.reduce((sum, r) => sum + parseFloat(r.total_revenue || 0), 0).toFixed(2),
                totalBookings: result.rows.reduce((sum, r) => sum + parseInt(r.total_bookings || 0), 0),
                totalTransactions: result.rows.reduce((sum, r) => sum + parseInt(r.total_transactions || 0), 0)
            }
        }
    });
});

/**
 * Get occupancy report
 */
const getOccupancyReport = asyncHandler(async (req, res) => {
    const {
        start_date,
        end_date,
        branch_id
    } = req.query;

    const params = [];
    let paramIndex = 0;

    let query = `
        SELECT 
            br.branch_id,
            br.branch_name,
            COUNT(DISTINCT r.room_id) AS total_rooms,
            COUNT(DISTINCT CASE WHEN b.status IN ('Booked', 'Checked-In') THEN b.room_id END) AS occupied_rooms,
            COUNT(DISTINCT b.booking_id) AS total_bookings,
            ROUND(
                COUNT(DISTINCT CASE WHEN b.status IN ('Booked', 'Checked-In') THEN b.room_id END) * 100.0 / 
                NULLIF(COUNT(DISTINCT r.room_id), 0), 
                2
            ) AS occupancy_rate
        FROM branch br
        LEFT JOIN room r ON br.branch_id = r.branch_id
        LEFT JOIN booking b ON r.room_id = b.room_id
    `;

    let whereClause = ' WHERE 1=1';

    if (start_date && end_date) {
        whereClause += ` AND b.check_in_date <= $${++paramIndex} AND b.check_out_date >= $${++paramIndex}`;
        params.push(end_date, start_date);
    }

    if (branch_id) {
        whereClause += ` AND br.branch_id = $${++paramIndex}`;
        params.push(branch_id);
    }

    query += whereClause;
    query += ` GROUP BY br.branch_id, br.branch_name ORDER BY br.branch_name`;

    const result = await executeQuery(query, params);

    res.json({
        success: true,
        data: {
            occupancyReport: result.rows,
            summary: {
                totalRooms: result.rows.reduce((sum, r) => sum + parseInt(r.total_rooms || 0), 0),
                totalOccupied: result.rows.reduce((sum, r) => sum + parseInt(r.occupied_rooms || 0), 0),
                averageOccupancy: result.rows.length > 0
                    ? (result.rows.reduce((sum, r) => sum + parseFloat(r.occupancy_rate || 0), 0) / result.rows.length).toFixed(2)
                    : 0
            }
        }
    });
});

/**
 * Get service usage report
 */
const getServiceUsageReport = asyncHandler(async (req, res) => {
    const {
        start_date,
        end_date,
        branch_id
    } = req.query;

    const params = [];
    let paramIndex = 0;

    let query = `
        SELECT 
            sc.service_id,
            sc.code,
            sc.name AS service_name,
            sc.category,
            COUNT(su.service_usage_id) AS usage_count,
            SUM(su.qty) AS total_quantity,
            SUM(su.qty * su.unit_price_at_use) AS total_revenue,
            ROUND(AVG(su.unit_price_at_use), 2) AS avg_unit_price
        FROM service_catalog sc
        LEFT JOIN service_usage su ON sc.service_id = su.service_id
        LEFT JOIN booking b ON su.booking_id = b.booking_id
        LEFT JOIN room r ON b.room_id = r.room_id
        WHERE 1=1
    `;

    if (start_date && end_date) {
        query += ` AND su.used_on BETWEEN $${++paramIndex} AND $${++paramIndex}`;
        params.push(start_date, end_date);
    }

    if (branch_id) {
        query += ` AND r.branch_id = $${++paramIndex}`;
        params.push(branch_id);
    }

    query += ` GROUP BY sc.service_id, sc.code, sc.name, sc.category`;
    query += ` ORDER BY total_revenue DESC`;

    const result = await executeQuery(query, params);

    res.json({
        success: true,
        data: {
            serviceReport: result.rows,
            summary: {
                totalRevenue: result.rows.reduce((sum, r) => sum + parseFloat(r.total_revenue || 0), 0).toFixed(2),
                totalUsages: result.rows.reduce((sum, r) => sum + parseInt(r.usage_count || 0), 0),
                totalQuantity: result.rows.reduce((sum, r) => sum + parseInt(r.total_quantity || 0), 0)
            }
        }
    });
});

/**
 * Get payment method breakdown
 */
const getPaymentMethodReport = asyncHandler(async (req, res) => {
    const {
        start_date,
        end_date,
        branch_id
    } = req.query;

    const params = [];
    let paramIndex = 0;

    let query = `
        SELECT 
            p.method,
            COUNT(p.payment_id) AS transaction_count,
            SUM(p.amount) AS total_amount,
            ROUND(AVG(p.amount), 2) AS avg_amount,
            MIN(p.amount) AS min_amount,
            MAX(p.amount) AS max_amount
        FROM payment p
        JOIN booking b ON p.booking_id = b.booking_id
        JOIN room r ON b.room_id = r.room_id
        WHERE 1=1
    `;

    if (start_date && end_date) {
        query += ` AND p.paid_at BETWEEN $${++paramIndex} AND $${++paramIndex}`;
        params.push(start_date, end_date);
    }

    if (branch_id) {
        query += ` AND r.branch_id = $${++paramIndex}`;
        params.push(branch_id);
    }

    query += ` GROUP BY p.method ORDER BY total_amount DESC`;

    const result = await executeQuery(query, params);

    const totalAmount = result.rows.reduce((sum, r) => sum + parseFloat(r.total_amount || 0), 0);

    const reportWithPercentage = result.rows.map(row => ({
        ...row,
        percentage: totalAmount > 0 ? ((parseFloat(row.total_amount) / totalAmount) * 100).toFixed(2) : 0
    }));

    res.json({
        success: true,
        data: {
            paymentMethodReport: reportWithPercentage,
            summary: {
                totalAmount: totalAmount.toFixed(2),
                totalTransactions: result.rows.reduce((sum, r) => sum + parseInt(r.transaction_count || 0), 0)
            }
        }
    });
});

/**
 * Get guest statistics
 */
const getGuestStatistics = asyncHandler(async (req, res) => {
    const {
        start_date,
        end_date
    } = req.query;

    const params = [];
    let paramIndex = 0;

    let query = `
        SELECT 
            COUNT(DISTINCT g.guest_id) AS total_guests,
            COUNT(DISTINCT b.booking_id) AS total_bookings,
            ROUND(AVG(b.room_estimate), 2) AS avg_booking_value,
            COUNT(DISTINCT CASE WHEN b.status = 'Checked-Out' THEN b.booking_id END) AS completed_bookings,
            COUNT(DISTINCT CASE WHEN b.status = 'Cancelled' THEN b.booking_id END) AS cancelled_bookings,
            g.nationality,
            COUNT(DISTINCT g.guest_id) AS guests_by_nationality
        FROM guest g
        LEFT JOIN booking b ON g.guest_id = b.guest_id
        WHERE 1=1
    `;

    if (start_date && end_date) {
        query += ` AND b.check_in_date BETWEEN $${++paramIndex} AND $${++paramIndex}`;
        params.push(start_date, end_date);
    }

    query += ` GROUP BY g.nationality ORDER BY guests_by_nationality DESC`;

    const result = await executeQuery(query, params);

    res.json({
        success: true,
        data: {
            guestStatistics: result.rows
        }
    });
});

/**
 * Get dashboard summary
 */
const getDashboardSummary = asyncHandler(async (req, res) => {
    const { branch_id } = req.query;

    // Today's stats
    const todayStatsQuery = `
        SELECT 
            COUNT(DISTINCT CASE WHEN b.check_in_date = CURRENT_DATE THEN b.booking_id END) AS today_checkins,
            COUNT(DISTINCT CASE WHEN b.check_out_date = CURRENT_DATE THEN b.booking_id END) AS today_checkouts,
            COUNT(DISTINCT CASE WHEN b.status = 'Checked-In' THEN b.booking_id END) AS current_guests,
            COALESCE(SUM(CASE WHEN p.paid_at::date = CURRENT_DATE THEN p.amount ELSE 0 END), 0) AS today_revenue
        FROM booking b
        LEFT JOIN payment p ON b.booking_id = p.booking_id
        LEFT JOIN room r ON b.room_id = r.room_id
        WHERE 1=1 ${branch_id ? 'AND r.branch_id = $1' : ''}
    `;

    // Room availability
    const roomAvailQuery = `
        SELECT 
            COUNT(r.room_id) AS total_rooms,
            COUNT(CASE WHEN r.status = 'Available' THEN 1 END) AS available_rooms,
            COUNT(CASE WHEN r.status = 'Occupied' THEN 1 END) AS occupied_rooms,
            COUNT(CASE WHEN r.status = 'Maintenance' THEN 1 END) AS maintenance_rooms
        FROM room r
        WHERE 1=1 ${branch_id ? 'AND r.branch_id = $1' : ''}
    `;

    // Monthly revenue
    const monthlyRevenueQuery = `
        SELECT 
            COALESCE(SUM(p.amount), 0) AS monthly_revenue,
            COUNT(DISTINCT p.booking_id) AS monthly_bookings
        FROM payment p
        JOIN booking b ON p.booking_id = b.booking_id
        JOIN room r ON b.room_id = r.room_id
        WHERE DATE_TRUNC('month', p.paid_at) = DATE_TRUNC('month', CURRENT_DATE)
        ${branch_id ? 'AND r.branch_id = $1' : ''}
    `;

    const params = branch_id ? [branch_id] : [];

    const [todayStats, roomAvail, monthlyRevenue] = await Promise.all([
        executeQuery(todayStatsQuery, params),
        executeQuery(roomAvailQuery, params),
        executeQuery(monthlyRevenueQuery, params)
    ]);

    res.json({
        success: true,
        data: {
            today: todayStats.rows[0],
            rooms: roomAvail.rows[0],
            monthly: monthlyRevenue.rows[0]
        }
    });
});

module.exports = {
    getRevenueReport,
    getOccupancyReport,
    getServiceUsageReport,
    getPaymentMethodReport,
    getGuestStatistics,
    getDashboardSummary
};
