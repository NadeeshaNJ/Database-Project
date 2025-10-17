const { executeQuery } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

/**
 * Get all payments with filters
 */
const getAllPayments = asyncHandler(async (req, res) => {
    const {
        booking_id,
        method,
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
            p.payment_id,
            p.booking_id,
            p.amount,
            p.method,
            p.paid_at,
            p.payment_reference,
            b.check_in_date,
            b.check_out_date,
            b.status AS booking_status,
            g.guest_id,
            g.full_name AS guest_name,
            g.email AS guest_email,
            g.phone AS guest_phone,
            r.room_number,
            br.branch_name,
            rt.name AS room_type
        FROM payment p
        JOIN booking b ON p.booking_id = b.booking_id
        JOIN guest g ON b.guest_id = g.guest_id
        JOIN room r ON b.room_id = r.room_id
        JOIN branch br ON r.branch_id = br.branch_id
        JOIN room_type rt ON r.room_type_id = rt.room_type_id
        WHERE 1=1
    `;

    // Filters
    if (booking_id) {
        query += ` AND p.booking_id = $${++paramIndex}`;
        params.push(booking_id);
    }

    if (method) {
        query += ` AND p.method = $${++paramIndex}`;
        params.push(method);
    }

    if (start_date && end_date) {
        query += ` AND p.paid_at BETWEEN $${++paramIndex} AND $${++paramIndex}`;
        params.push(start_date, end_date);
    }

    query += ` ORDER BY p.paid_at DESC`;
    query += ` LIMIT $${++paramIndex} OFFSET $${++paramIndex}`;
    params.push(parseInt(limit), parseInt(offset));

    // Count query
    let countQuery = `
        SELECT COUNT(*) as count
        FROM payment p
        JOIN booking b ON p.booking_id = b.booking_id
        WHERE 1=1
    `;

    const countParams = [];
    let countParamIndex = 0;

    if (booking_id) {
        countQuery += ` AND p.booking_id = $${++countParamIndex}`;
        countParams.push(booking_id);
    }

    if (method) {
        countQuery += ` AND p.method = $${++countParamIndex}`;
        countParams.push(method);
    }

    if (start_date && end_date) {
        countQuery += ` AND p.paid_at BETWEEN $${++countParamIndex} AND $${++countParamIndex}`;
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
            payments: results.rows,
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
 * Get payments by booking ID
 */
const getPaymentsByBooking = asyncHandler(async (req, res) => {
    const { bookingId } = req.params;

    const query = `
        SELECT 
            p.payment_id,
            p.booking_id,
            p.amount,
            p.method,
            p.paid_at,
            p.payment_reference
        FROM payment p
        WHERE p.booking_id = $1
        ORDER BY p.paid_at DESC
    `;

    const result = await executeQuery(query, [bookingId]);

    const totalPaid = result.rows.reduce((sum, payment) => {
        return sum + parseFloat(payment.amount || 0);
    }, 0);

    res.json({
        success: true,
        data: {
            payments: result.rows,
            summary: {
                totalPayments: result.rows.length,
                totalPaid: totalPaid.toFixed(2)
            }
        }
    });
});

/**
 * Get payment adjustments
 */
const getPaymentAdjustments = asyncHandler(async (req, res) => {
    const {
        booking_id,
        type,
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
            pa.adjustment_id,
            pa.booking_id,
            pa.amount,
            pa.type,
            pa.reference_note,
            pa.created_at,
            b.check_in_date,
            b.check_out_date,
            b.status AS booking_status,
            g.guest_id,
            g.full_name AS guest_name,
            g.email AS guest_email,
            r.room_number,
            br.branch_name
        FROM payment_adjustment pa
        JOIN booking b ON pa.booking_id = b.booking_id
        JOIN guest g ON b.guest_id = g.guest_id
        JOIN room r ON b.room_id = r.room_id
        JOIN branch br ON r.branch_id = br.branch_id
        WHERE 1=1
    `;

    // Filters
    if (booking_id) {
        query += ` AND pa.booking_id = $${++paramIndex}`;
        params.push(booking_id);
    }

    if (type) {
        query += ` AND pa.type = $${++paramIndex}`;
        params.push(type);
    }

    if (start_date && end_date) {
        query += ` AND pa.created_at BETWEEN $${++paramIndex} AND $${++paramIndex}`;
        params.push(start_date, end_date);
    }

    query += ` ORDER BY pa.created_at DESC`;
    query += ` LIMIT $${++paramIndex} OFFSET $${++paramIndex}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await executeQuery(query, params);

    res.json({
        success: true,
        data: {
            adjustments: result.rows,
            pagination: {
                total: result.rows.length,
                page: parseInt(page),
                limit: parseInt(limit)
            }
        }
    });
});

/**
 * Get billing summary for a booking
 */
const getBookingBillingSummary = asyncHandler(async (req, res) => {
    const { bookingId } = req.params;

    // Get booking details with room charges
    const bookingQuery = `
        SELECT 
            b.booking_id,
            b.check_in_date,
            b.check_out_date,
            b.status,
            b.booked_rate,
            b.tax_rate_percent,
            b.discount_amount,
            b.late_fee_amount,
            b.advance_payment,
            b.room_estimate,
            b.preferred_payment_method,
            (b.check_out_date - b.check_in_date) as nights,
            g.guest_id,
            g.full_name AS guest_name,
            g.email AS guest_email,
            g.phone AS guest_phone,
            r.room_number,
            rt.name AS room_type,
            rt.daily_rate,
            br.branch_name
        FROM booking b
        JOIN guest g ON b.guest_id = g.guest_id
        JOIN room r ON b.room_id = r.room_id
        JOIN room_type rt ON r.room_type_id = rt.room_type_id
        JOIN branch br ON r.branch_id = br.branch_id
        WHERE b.booking_id = $1
    `;

    // Get payments
    const paymentsQuery = `
        SELECT 
            payment_id,
            amount,
            method,
            paid_at,
            payment_reference
        FROM payment
        WHERE booking_id = $1
        ORDER BY paid_at DESC
    `;

    // Get service charges
    const servicesQuery = `
        SELECT 
            su.service_usage_id,
            su.used_on,
            su.qty,
            su.unit_price_at_use,
            (su.qty * su.unit_price_at_use) AS total_price,
            sc.name AS service_name,
            sc.category AS service_category
        FROM service_usage su
        JOIN service_catalog sc ON su.service_id = sc.service_id
        WHERE su.booking_id = $1
        ORDER BY su.used_on DESC
    `;

    // Get adjustments
    const adjustmentsQuery = `
        SELECT 
            adjustment_id,
            amount,
            type,
            reference_note,
            created_at
        FROM payment_adjustment
        WHERE booking_id = $1
        ORDER BY created_at DESC
    `;

    const [bookingResult, paymentsResult, servicesResult, adjustmentsResult] = await Promise.all([
        executeQuery(bookingQuery, [bookingId]),
        executeQuery(paymentsQuery, [bookingId]),
        executeQuery(servicesQuery, [bookingId]),
        executeQuery(adjustmentsQuery, [bookingId])
    ]);

    if (bookingResult.rows.length === 0) {
        return res.status(404).json({
            success: false,
            error: 'Booking not found'
        });
    }

    const booking = bookingResult.rows[0];
    const payments = paymentsResult.rows;
    const services = servicesResult.rows;
    const adjustments = adjustmentsResult.rows;

    // Calculate totals
    const roomCharges = parseFloat(booking.room_estimate) || 0;
    const serviceCharges = services.reduce((sum, s) => sum + parseFloat(s.total_price || 0), 0);
    const subtotal = roomCharges + serviceCharges;
    const tax = (subtotal * parseFloat(booking.tax_rate_percent || 0)) / 100;
    const discount = parseFloat(booking.discount_amount) || 0;
    const lateFee = parseFloat(booking.late_fee_amount) || 0;
    const grandTotal = subtotal + tax - discount + lateFee;

    const totalPaid = payments.reduce((sum, p) => sum + parseFloat(p.amount || 0), 0);
    const refunds = adjustments
        .filter(a => a.type === 'refund')
        .reduce((sum, a) => sum + parseFloat(a.amount || 0), 0);
    const manualAdjustments = adjustments
        .filter(a => a.type === 'manual_adjustment')
        .reduce((sum, a) => sum + parseFloat(a.amount || 0), 0);

    const balance = grandTotal - totalPaid + refunds - manualAdjustments;

    res.json({
        success: true,
        data: {
            booking,
            payments,
            services,
            adjustments,
            summary: {
                roomCharges: roomCharges.toFixed(2),
                serviceCharges: serviceCharges.toFixed(2),
                subtotal: subtotal.toFixed(2),
                tax: tax.toFixed(2),
                discount: discount.toFixed(2),
                lateFee: lateFee.toFixed(2),
                grandTotal: grandTotal.toFixed(2),
                totalPaid: totalPaid.toFixed(2),
                refunds: refunds.toFixed(2),
                manualAdjustments: manualAdjustments.toFixed(2),
                balance: balance.toFixed(2)
            }
        }
    });
});

module.exports = {
    getAllPayments,
    getPaymentsByBooking,
    getPaymentAdjustments,
    getBookingBillingSummary
};
