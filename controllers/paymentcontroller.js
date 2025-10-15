const { sequelize } = require('../models');
const { asyncHandler } = require('../middleware/errorHandler');
const moment = require('moment');

/**
 * Get all payments with filtering
 */
const getAllPayments = asyncHandler(async (req, res) => {
  const {
    payment_status,
    payment_method,
    start_date,
    end_date,
    booking_id,
    page = 1,
    limit = 10
  } = req.query;

  let whereConditions = ['1=1'];
  let params = [];
  let paramCount = 0;

  // Status filter
  if (payment_status) {
    paramCount++;
    whereConditions.push(`p.payment_status = $${paramCount}`);
    params.push(payment_status);
  }

  // Payment method filter
  if (payment_method) {
    paramCount++;
    whereConditions.push(`p.payment_method = $${paramCount}`);
    params.push(payment_method);
  }

  // Booking ID filter
  if (booking_id) {
    paramCount++;
    whereConditions.push(`p.booking_id = $${paramCount}`);
    params.push(booking_id);
  }

  // Date range filter
  if (start_date && end_date) {
    paramCount++;
    whereConditions.push(`p.payment_date BETWEEN $${paramCount}`);
    paramCount++;
    whereConditions.push(`$${paramCount}`);
    params.push(start_date, end_date);
  }

  const offset = (parseInt(page) - 1) * parseInt(limit);

  // Count query
  const countQuery = `
    SELECT COUNT(*) 
    FROM payments p
    JOIN bookings b ON p.booking_id = b.id
    JOIN guests g ON b.guest_id = g.id
    JOIN rooms r ON b.room_id = r.id
    WHERE ${whereConditions.join(' AND ')}
  `;

  // Main query
  const mainQuery = `
    SELECT 
      p.*,
      b.check_in,
      b.check_out,
      b.total_amount as booking_total,
      g.first_name,
      g.last_name,
      g.email,
      r.room_number,
      r.room_type
    FROM payments p
    JOIN bookings b ON p.booking_id = b.id
    JOIN guests g ON b.guest_id = g.id
    JOIN rooms r ON b.room_id = r.id
    WHERE ${whereConditions.join(' AND ')}
    ORDER BY p.payment_date DESC
    LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
  `;

  params.push(parseInt(limit), offset);

  const [countResult, payments] = await Promise.all([
    sequelize.query(countQuery, { bind: params, type: sequelize.QueryTypes.SELECT }),
    sequelize.query(mainQuery, { bind: params, type: sequelize.QueryTypes.SELECT })
  ]);

  const totalCount = parseInt(countResult[0].count);

  res.json({
    success: true,
    data: payments,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: totalCount,
      pages: Math.ceil(totalCount / limit)
    }
  });
});

/**
 * Get payment by ID
 */
const getPaymentById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const query = `
    SELECT 
      p.*,
      b.check_in,
      b.check_out,
      b.total_amount as booking_total,
      b.status as booking_status,
      g.first_name,
      g.last_name,
      g.email,
      g.phone,
      r.room_number,
      r.room_type,
      r.price_per_night
    FROM payments p
    JOIN bookings b ON p.booking_id = b.id
    JOIN guests g ON b.guest_id = g.id
    JOIN rooms r ON b.room_id = r.id
    WHERE p.id = $1
  `;

  const [payment] = await sequelize.query(query, {
    bind: [id],
    type: sequelize.QueryTypes.SELECT
  });

  if (!payment) {
    return res.status(404).json({
      success: false,
      error: 'Payment not found'
    });
  }

  res.json({
    success: true,
    data: payment
  });
});

/**
 * Create new payment
 */
const createPayment = asyncHandler(async (req, res) => {
  const { booking_id, amount, payment_method, transaction_id, card_last_four, card_brand } = req.body;

  // Start transaction
  const transaction = await sequelize.transaction();

  try {
    // Check if booking exists and get details
    const bookingQuery = `
      SELECT 
        b.total_amount,
        b.status as booking_status,
        COALESCE(SUM(p.amount) FILTER (WHERE p.payment_status = 'completed'), 0) as total_paid
      FROM bookings b
      LEFT JOIN payments p ON b.id = p.booking_id
      WHERE b.id = $1
      GROUP BY b.id
    `;

    const [booking] = await sequelize.query(bookingQuery, {
      bind: [booking_id],
      type: sequelize.QueryTypes.SELECT,
      transaction
    });

    if (!booking) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        error: 'Booking not found'
      });
    }

    // Validate amount
    const paymentAmount = parseFloat(amount);
    if (paymentAmount <= 0) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        error: 'Payment amount must be greater than 0'
      });
    }

    // Check if payment exceeds remaining balance
    const remainingBalance = booking.total_amount - booking.total_paid;
    if (paymentAmount > remainingBalance) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        error: `Payment amount exceeds remaining balance. Maximum: $${remainingBalance.toFixed(2)}`
      });
    }

    // Create payment
    const insertQuery = `
      INSERT INTO payments (
        booking_id, amount, payment_method, payment_status,
        transaction_id, card_last_four, card_brand, payment_date
      ) 
      VALUES ($1, $2, $3, 'completed', $4, $5, $6, $7)
      RETURNING *
    `;

    const [payment] = await sequelize.query(insertQuery, {
      bind: [
        booking_id, 
        paymentAmount, 
        payment_method, 
        transaction_id, 
        card_last_four, 
        card_brand,
        new Date()
      ],
      type: sequelize.QueryTypes.SELECT,
      transaction
    });

    await transaction.commit();

    // Get complete payment details
    const fullQuery = `
      SELECT 
        p.*,
        b.check_in,
        b.check_out,
        b.total_amount as booking_total,
        g.first_name,
        g.last_name,
        r.room_number
      FROM payments p
      JOIN bookings b ON p.booking_id = b.id
      JOIN guests g ON b.guest_id = g.id
      JOIN rooms r ON b.room_id = r.id
      WHERE p.id = $1
    `;

    const [fullPayment] = await sequelize.query(fullQuery, {
      bind: [payment.id],
      type: sequelize.QueryTypes.SELECT
    });

    res.status(201).json({
      success: true,
      message: 'Payment created successfully',
      data: fullPayment
    });

  } catch (error) {
    await transaction.rollback();
    throw error;
  }
});

/**
 * Update payment status
 */
const updatePaymentStatus = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { payment_status, transaction_id } = req.body;

  // Get current payment status
  const currentQuery = 'SELECT payment_status FROM payments WHERE id = $1';
  const [currentPayment] = await sequelize.query(currentQuery, {
    bind: [id],
    type: sequelize.QueryTypes.SELECT
  });

  if (!currentPayment) {
    return res.status(404).json({
      success: false,
      error: 'Payment not found'
    });
  }

  // Validate status transition
  const allowedTransitions = {
    'pending': ['completed', 'failed'],
    'completed': ['refunded'],
    'failed': ['pending'],
    'refunded': []
  };

  const currentStatus = currentPayment.payment_status;
  if (!allowedTransitions[currentStatus]?.includes(payment_status)) {
    return res.status(400).json({
      success: false,
      error: `Cannot change payment status from ${currentStatus} to ${payment_status}`
    });
  }

  const updateQuery = `
    UPDATE payments 
    SET payment_status = $1, transaction_id = COALESCE($2, transaction_id)
    WHERE id = $3
    RETURNING *
  `;

  const [payment] = await sequelize.query(updateQuery, {
    bind: [payment_status, transaction_id, id],
    type: sequelize.QueryTypes.SELECT
  });

  res.json({
    success: true,
    message: 'Payment status updated successfully',
    data: payment
  });
});

/**
 * Process refund
 */
const processRefund = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { refund_amount, refund_reason } = req.body;

  // Start transaction
  const transaction = await sequelize.transaction();

  try {
    // Get payment details
    const paymentQuery = `
      SELECT * FROM payments 
      WHERE id = $1 AND payment_status = 'completed'
      FOR UPDATE
    `;

    const [payment] = await sequelize.query(paymentQuery, {
      bind: [id],
      type: sequelize.QueryTypes.SELECT,
      transaction
    });

    if (!payment) {
      await transaction.rollback();
      return res.status(404).json({
        success: false,
        error: 'Payment not found or not eligible for refund'
      });
    }

    const refundAmount = parseFloat(refund_amount);
    if (refundAmount <= 0) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        error: 'Refund amount must be greater than 0'
      });
    }

    if (refundAmount > payment.amount) {
      await transaction.rollback();
      return res.status(400).json({
        success: false,
        error: `Refund amount cannot exceed original payment amount of $${payment.amount}`
      });
    }

    if (refundAmount === payment.amount) {
      // Full refund - update existing payment
      const updateQuery = `
        UPDATE payments 
        SET payment_status = 'refunded', refund_amount = $1, refund_reason = $2
        WHERE id = $3
        RETURNING *
      `;

      const [refundedPayment] = await sequelize.query(updateQuery, {
        bind: [refundAmount, refund_reason, id],
        type: sequelize.QueryTypes.SELECT,
        transaction
      });

      await transaction.commit();

      res.json({
        success: true,
        message: `Full refund processed for $${refundAmount.toFixed(2)}`,
        data: refundedPayment
      });

    } else {
      // Partial refund - create new refund record
      const insertQuery = `
        INSERT INTO payments (
          booking_id, amount, payment_method, payment_status,
          refund_amount, refund_reason, payment_date
        ) 
        VALUES ($1, $2, $3, 'refunded', $4, $5, $6)
        RETURNING *
      `;

      const [refundPayment] = await sequelize.query(insertQuery, {
        bind: [
          payment.booking_id,
          -refundAmount, // Negative amount for refund
          payment.payment_method,
          refundAmount,
          refund_reason,
          new Date()
        ],
        type: sequelize.QueryTypes.SELECT,
        transaction
      });

      await transaction.commit();

      res.json({
        success: true,
        message: `Partial refund processed for $${refundAmount.toFixed(2)}`,
        data: refundPayment
      });
    }

  } catch (error) {
    await transaction.rollback();
    throw error;
  }
});

/**
 * Get payments by booking ID
 */
const getPaymentsByBookingId = asyncHandler(async (req, res) => {
  const { booking_id } = req.params;

  const paymentsQuery = `
    SELECT * FROM payments 
    WHERE booking_id = $1 
    ORDER BY payment_date DESC
  `;

  const summaryQuery = `
    SELECT 
      b.total_amount,
      COALESCE(SUM(p.amount) FILTER (WHERE p.payment_status = 'completed'), 0) as total_paid,
      COALESCE(SUM(p.refund_amount), 0) as total_refunded
    FROM bookings b
    LEFT JOIN payments p ON b.id = p.booking_id
    WHERE b.id = $1
    GROUP BY b.id
  `;

  const [payments, [summary]] = await Promise.all([
    sequelize.query(paymentsQuery, {
      bind: [booking_id],
      type: sequelize.QueryTypes.SELECT
    }),
    sequelize.query(summaryQuery, {
      bind: [booking_id],
      type: sequelize.QueryTypes.SELECT
    })
  ]);

  const balance = summary ? summary.total_amount - summary.total_paid + summary.total_refunded : 0;

  res.json({
    success: true,
    data: {
      payments,
      summary: {
        total_paid: summary?.total_paid || 0,
        total_refunded: summary?.total_refunded || 0,
        current_balance: balance,
        booking_total: summary?.total_amount || 0
      }
    }
  });
});

module.exports = {
  getAllPayments,
  getPaymentById,
  createPayment,
  updatePaymentStatus,
  processRefund,
  getPaymentsByBookingId
};