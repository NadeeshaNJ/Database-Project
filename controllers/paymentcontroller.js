const { sequelize } = require('../models');
const { asyncHandler } = require('../middleware/errorHandler');
const moment = require('moment');
const { executeQuery, executeTransaction } = require('../config/database'); 
/**
 * Get all payments with filtering
 */


const getAllPayments = asyncHandler(async (req, res) => {
    const {
        payment_method,
        start_date,
        end_date,
        booking_id,
        page = 1,
        limit = 10
    } = req.query;

    const whereConditions = ['1=1'];
    const params = [];
    let paramCount = 0;

    // 1. FILTERS (Building WHERE clause and parameters)

    // Payment method filter (p.method is the correct column name)
    if (payment_method) {
        paramCount++;
        whereConditions.push(`p.method = $${paramCount}`);
        params.push(payment_method);
    }

    // Booking ID filter
    if (booking_id) {
        paramCount++;
        whereConditions.push(`p.booking_id = $${paramCount}`);
        params.push(booking_id);
    }

    // Date range filter (p.paid_at is the correct column name)
    if (start_date && end_date) {
        // FIX: The date filter uses two parameters
        paramCount++;
        whereConditions.push(`p.paid_at >= $${paramCount}`); // paid_at >= start_date
        params.push(start_date);
        
        paramCount++;
        whereConditions.push(`p.paid_at <= $${paramCount}`); // paid_at <= end_date
        params.push(end_date);
    }
    
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const filterParams = [...params]; // Params array used for the COUNT query

    // 2. SQL Queries (Using correct PostgreSQL table/column names)
    
    // Count query
    const countQuery = `
        SELECT COUNT(p.payment_id) 
        FROM public.payment p
        JOIN public.booking b ON p.booking_id = b.booking_id
        JOIN public.guest g ON b.guest_id = g.guest_id
        JOIN public.room r ON b.room_id = r.room_id
        WHERE ${whereConditions.join(' AND ')}
    `;

    // Main query
    const mainQuery = `
        SELECT 
            p.payment_id,
            p.booking_id,
            p.amount,
            p.method,
            p.paid_at,
            p.payment_reference,
            b.check_in_date,
            b.check_out_date,
            g.full_name AS guest_name, -- FIX: Use g.full_name, not g.first/last_name
            g.email AS guest_email,
            r.room_number,
            rt.name AS room_type -- FIX: rt.name for room_type
        FROM public.payment p
        JOIN public.booking b ON p.booking_id = b.booking_id
        JOIN public.guest g ON b.guest_id = g.guest_id
        JOIN public.room r ON b.room_id = r.room_id
        JOIN public.room_type rt ON r.room_type_id = rt.room_type_id -- Required for room_type
        WHERE ${whereConditions.join(' AND ')}
        ORDER BY p.paid_at DESC
        LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
    `;

    // 3. EXECUTION
    
    // Add pagination parameters to the params array
    params.push(parseInt(limit), offset);

    const [countResult, payments] = await Promise.all([
        executeQuery(countQuery, filterParams), // Use only filter params
        executeQuery(mainQuery, params)         // Use all params (filters + limit/offset)
    ]);

    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
        success: true,
        data: payments.rows,
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
// const getPaymentById = asyncHandler(async (req, res) => {
//   const { id } = req.params;

//   const query = `
//     SELECT 
//       p.*,
//       b.check_in,
//       b.check_out,
//       b.total_amount as booking_total,
//       b.status as booking_status,
//       g.first_name,
//       g.last_name,
//       g.email,
//       g.phone,
//       r.room_number,
//       r.room_type,
//       r.price_per_night
//     FROM payments p
//     JOIN bookings b ON p.booking_id = b.id
//     JOIN guests g ON b.guest_id = g.id
//     JOIN rooms r ON b.room_id = r.id
//     WHERE p.id = $1
//   `;

//   const [payment] = await sequelize.query(query, {
//     bind: [id],
//     type: sequelize.QueryTypes.SELECT
//   });

//   if (!payment) {
//     return res.status(404).json({
//       success: false,
//       error: 'Payment not found'
//     });
//   }

//   res.json({
//     success: true,
//     data: payment
//   });
// });


const getPaymentById = asyncHandler(async (req, res) => {
  // 1. Extract ID from route parameters
  const { id } = req.params;

  if (!id) {
    return res.status(400).json({ success: false, error: 'Payment ID is required.' });
  }

  // 2. Define the PostgreSQL Query
  const query = `
    SELECT 
      -- Payment details (p.* is avoided to be explicit)
      p.payment_id,
      p.booking_id,
      p.amount,
      p.method,
      p.paid_at,
      p.payment_reference,

      -- Booking details
      b.check_in_date,      -- Correct column name
      b.check_out_date,     -- Correct column name
      b.status AS booking_status, -- Correct column name
      
      -- Guest details (using g.full_name from your schema)
      g.guest_id,
      g.full_name AS guest_name,
      g.email AS guest_email,
      g.phone AS guest_phone,
      
      -- Room and Room Type details (using correct table/column names)
      r.room_number,
      rt.name AS room_type,      -- rt.name for room type name
      rt.daily_rate              -- rt.daily_rate for price

    FROM public.payment p
    JOIN public.booking b ON p.booking_id = b.booking_id
    JOIN public.guest g ON b.guest_id = g.guest_id
    JOIN public.room r ON b.room_id = r.room_id
    JOIN public.room_type rt ON r.room_type_id = rt.room_type_id -- Join room_type for details
    WHERE p.payment_id = $1
  `;

  try {
    // 3. Execute the query using the standard helper function
    const result = await executeQuery(query, [id]);
    const payment = result.rows[0]; // Gets the first row

    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found'
      });
    }

    // 4. Return the detailed payment data
    res.json({
      success: true,
      data: payment
    });

  } catch (error) {
    console.error('Get Payment By ID Error:', error);
    res.status(500).json({
      success: false,
      error: `Internal server error while fetching payment details: ${error.message}`
    });
  }
});

/**
 * Create new payment
 */
// const createPayment = asyncHandler(async (req, res) => {
//   const { booking_id, amount, payment_method, transaction_id, card_last_four, card_brand } = req.body;

//   // Start transaction
//   const transaction = await sequelize.transaction();

//   try {
//     // Check if booking exists and get details
//     const bookingQuery = `
//       SELECT 
//         b.total_amount,
//         b.status as booking_status,
//         COALESCE(SUM(p.amount) FILTER (WHERE p.payment_status = 'completed'), 0) as total_paid
//       FROM bookings b
//       LEFT JOIN payments p ON b.id = p.booking_id
//       WHERE b.id = $1
//       GROUP BY b.id
//     `;

//     const [booking] = await sequelize.query(bookingQuery, {
//       bind: [booking_id],
//       type: sequelize.QueryTypes.SELECT,
//       transaction
//     });

//     if (!booking) {
//       await transaction.rollback();
//       return res.status(404).json({
//         success: false,
//         error: 'Booking not found'
//       });
//     }

//     // Validate amount
//     const paymentAmount = parseFloat(amount);
//     if (paymentAmount <= 0) {
//       await transaction.rollback();
//       return res.status(400).json({
//         success: false,
//         error: 'Payment amount must be greater than 0'
//       });
//     }

//     // Check if payment exceeds remaining balance
//     const remainingBalance = booking.total_amount - booking.total_paid;
//     if (paymentAmount > remainingBalance) {
//       await transaction.rollback();
//       return res.status(400).json({
//         success: false,
//         error: `Payment amount exceeds remaining balance. Maximum: $${remainingBalance.toFixed(2)}`
//       });
//     }

//     // Create payment
//     const insertQuery = `
//       INSERT INTO payments (
//         booking_id, amount, payment_method, payment_status,
//         transaction_id, card_last_four, card_brand, payment_date
//       ) 
//       VALUES ($1, $2, $3, 'completed', $4, $5, $6, $7)
//       RETURNING *
//     `;

//     const [payment] = await sequelize.query(insertQuery, {
//       bind: [
//         booking_id, 
//         paymentAmount, 
//         payment_method, 
//         transaction_id, 
//         card_last_four, 
//         card_brand,
//         new Date()
//       ],
//       type: sequelize.QueryTypes.SELECT,
//       transaction
//     });

//     await transaction.commit();

//     // Get complete payment details
//     const fullQuery = `
//       SELECT 
//         p.*,
//         b.check_in,
//         b.check_out,
//         b.total_amount as booking_total,
//         g.first_name,
//         g.last_name,
//         r.room_number
//       FROM payments p
//       JOIN bookings b ON p.booking_id = b.id
//       JOIN guests g ON b.guest_id = g.id
//       JOIN rooms r ON b.room_id = r.id
//       WHERE p.id = $1
//     `;

//     const [fullPayment] = await sequelize.query(fullQuery, {
//       bind: [payment.id],
//       type: sequelize.QueryTypes.SELECT
//     });

//     res.status(201).json({
//       success: true,
//       message: 'Payment created successfully',
//       data: fullPayment
//     });

//   } catch (error) {
//     await transaction.rollback();
//     throw error;
//   }
// });

const createPayment = asyncHandler(async (req, res) => {
    // NOTE: The request body must provide amount, method, and a reference.
    const { booking_id, amount, method, payment_reference } = req.body;

    if (!booking_id || !amount || !method) {
        return res.status(400).json({ 
            success: false, 
            error: 'Booking ID, amount, and payment method are required.' 
        });
    }
    
    const paymentAmount = parseFloat(amount);
    if (paymentAmount <= 0) {
        return res.status(400).json({
            success: false,
            error: 'Payment amount must be greater than 0.'
        });
    }

    // 1. Check Remaining Balance using PostgreSQL functions
    const balanceQuery = `
        SELECT 
            b.status AS booking_status,
            fn_net_balance($1) AS net_balance,
            fn_bill_total($1) AS bill_total
        FROM public.booking b
        WHERE b.booking_id = $1
    `;

    const balanceResult = await executeQuery(balanceQuery, [booking_id]);

    if (balanceResult.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Booking not found.' });
    }

    const { net_balance, booking_status } = balanceResult.rows[0];
    const remainingBalance = parseFloat(net_balance);

    // Prevent payment if the booking is fully paid or cancelled
    if (remainingBalance <= 0) {
        return res.status(400).json({
            success: false,
            error: 'Booking is already fully paid or the payment amount exceeds the bill.'
        });
    }
    if (booking_status === 'Cancelled' || booking_status === 'Checked-Out') {
        return res.status(400).json({
            success: false,
            error: `Cannot accept payment for a ${booking_status} booking.`
        });
    }

    // Check if payment exceeds remaining balance
    if (paymentAmount > remainingBalance) {
        return res.status(400).json({
            success: false,
            error: `Payment amount exceeds remaining balance. Maximum allowed: $${remainingBalance.toFixed(2)}`
        });
    }

    // 2. Prepare Payment Insertion Query
    const insertPaymentQuery = {
        text: `
            INSERT INTO public.payment (
                booking_id, 
                amount, 
                method, 
                payment_reference, 
                paid_at
            ) 
            VALUES ($1, $2, $3, $4, NOW())
            RETURNING payment_id
        `,
        params: [
            booking_id, 
            paymentAmount, 
            method, 
            payment_reference || null // Reference is VARCHAR(100) (optional)
        ]
    };

    try {
        // Execute the insertion within a transaction (though only one query here, it's good practice)
        const results = await executeTransaction([insertPaymentQuery]);
        const paymentId = results[0].rows[0].payment_id;

        // 3. Optional: Fetch complete payment details (similar to original code)
        // This query needs to join booking, guest, room, etc.
        const detailQuery = `
            SELECT 
                p.payment_id, p.amount, p.method, p.paid_at, p.payment_reference,
                b.booking_id, b.check_in_date, b.check_out_date,
                g.full_name AS guest_name, r.room_number
            FROM public.payment p
            JOIN public.booking b ON p.booking_id = b.booking_id
            JOIN public.guest g ON b.guest_id = g.guest_id
            JOIN public.room r ON b.room_id = r.room_id
            WHERE p.payment_id = $1
        `;

        const finalPaymentResult = await executeQuery(detailQuery, [paymentId]);

        res.status(201).json({
            success: true,
            message: '✅ Payment successfully recorded.',
            data: finalPaymentResult.rows[0]
        });

    } catch (error) {
        // Since we used executeTransaction, any error will roll back automatically.
        console.error('Payment Transaction Error:', error);
        res.status(500).json({
            success: false,
            error: `Internal server error while recording payment: ${error.message}`
        });
    }
});

/**
 * Update payment status
 */
// const updatePaymentStatus = asyncHandler(async (req, res) => {
//   const { id } = req.params;
//   const { payment_status, transaction_id } = req.body;

//   // Get current payment status
//   const currentQuery = 'SELECT payment_status FROM payments WHERE id = $1';
//   const [currentPayment] = await sequelize.query(currentQuery, {
//     bind: [id],
//     type: sequelize.QueryTypes.SELECT
//   });

//   if (!currentPayment) {
//     return res.status(404).json({
//       success: false,
//       error: 'Payment not found'
//     });
//   }

//   // Validate status transition
//   const allowedTransitions = {
//     'pending': ['completed', 'failed'],
//     'completed': ['refunded'],
//     'failed': ['pending'],
//     'refunded': []
//   };

//   const currentStatus = currentPayment.payment_status;
//   if (!allowedTransitions[currentStatus]?.includes(payment_status)) {
//     return res.status(400).json({
//       success: false,
//       error: `Cannot change payment status from ${currentStatus} to ${payment_status}`
//     });
//   }

//   const updateQuery = `
//     UPDATE payments 
//     SET payment_status = $1, transaction_id = COALESCE($2, transaction_id)
//     WHERE id = $3
//     RETURNING *
//   `;

//   const [payment] = await sequelize.query(updateQuery, {
//     bind: [payment_status, transaction_id, id],
//     type: sequelize.QueryTypes.SELECT
//   });

//   res.json({
//     success: true,
//     message: 'Payment status updated successfully',
//     data: payment
//   });
// });

/**
 * Process refund
 */


const processRefund = asyncHandler(async (req, res) => {
    const { id: paymentId } = req.params;
    const { refund_amount, refund_reason } = req.body;

    if (!paymentId) {
        return res.status(400).json({ success: false, error: 'Payment ID is required.' });
    }

    const refundAmount = parseFloat(refund_amount);
    if (isNaN(refundAmount) || refundAmount <= 0) {
        return res.status(400).json({ success: false, error: 'Refund amount must be greater than 0.' });
    }

    // 1️⃣ Lookup payment + booking
    const lookupQuery = `
        SELECT 
            p.booking_id,
            p.amount AS payment_amount_original,
            b.status AS booking_status,
            fn_total_paid(p.booking_id) AS total_paid,
            fn_total_refunds(p.booking_id) AS total_refunded_to_date
        FROM public.payment p
        JOIN public.booking b ON p.booking_id = b.booking_id
        WHERE p.payment_id = $1
    `;
    const lookupResult = await executeQuery(lookupQuery, [paymentId]);

    if (lookupResult.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Payment record not found.' });
    }

    const {
        booking_id,
        total_paid,
        total_refunded_to_date,
        booking_status
    } = lookupResult.rows[0];

    // 2️⃣ Validate booking status
    if (['Checked-Out', 'Cancelled'].includes(booking_status)) {
        return res.status(400).json({
            success: false,
            error: `❌ Cannot process refund. Booking ${booking_id} is already ${booking_status}.`
        });
    }

    // 3️⃣ Validate refund limit
    const netPaid = parseFloat(total_paid) - parseFloat(total_refunded_to_date);
    if (refundAmount > netPaid) {
        return res.status(400).json({
            success: false,
            error: `Refund amount ($${refundAmount.toFixed(2)}) exceeds available refundable amount ($${netPaid.toFixed(2)}).`
        });
    }

    // 4️⃣ Prepare transaction queries
    const queries = [];

    // A. Insert into payment_adjustment
    queries.push({
        text: `
            INSERT INTO public.payment_adjustment (
                booking_id, amount, type, reference_note
            )
            VALUES ($1, $2, 'refund', $3)
            RETURNING adjustment_id
        `,
        params: [
            booking_id,
            refundAmount,
            `Refund: ${refund_reason || 'No reason provided'} (Linked to Payment ID: ${paymentId})`
        ]
    });

    // B. Update original payment record (CAST FIX APPLIED)
    queries.push({
        text: `
            UPDATE public.payment 
            SET 
                payment_reference = CONCAT(
                    COALESCE(payment_reference, ''), 
                    ' [REFUNDED DUE TO: ', CAST($1 AS TEXT), ']'
                )
            WHERE payment_id = $2
            RETURNING payment_id, payment_reference
        `,
        params: [
            refund_reason || 'Reason not specified',
            paymentId
        ]
    });

    // 5️⃣ Execute transaction
    try {
        const results = await executeTransaction(queries);

        const adjustmentId = results[0].rows[0].adjustment_id;
        const updatedPayment = results[1].rows[0];
        const newNetBalance = (netPaid - refundAmount).toFixed(2);

        res.status(200).json({
            success: true,
            message: `✅ Refund of $${refundAmount.toFixed(2)} processed successfully.`,
            adjustment_id: adjustmentId,
            updated_payment_reference: updatedPayment.payment_reference,
            new_net_balance_on_booking: newNetBalance
        });

    } catch (error) {
        console.error('Refund Transaction Error:', error);
        res.status(500).json({
            success: false,
            error: `Internal server error during refund process: ${error.message}`
        });
    }
});

/**
 * Get payments by booking ID
 */
// const getPaymentsByBookingId = asyncHandler(async (req, res) => {
//   const { booking_id } = req.params;

//   const paymentsQuery = `
//     SELECT * FROM payments 
//     WHERE booking_id = $1 
//     ORDER BY payment_date DESC
//   `;

//   const summaryQuery = `
//     SELECT 
//       b.total_amount,
//       COALESCE(SUM(p.amount) FILTER (WHERE p.payment_status = 'completed'), 0) as total_paid,
//       COALESCE(SUM(p.refund_amount), 0) as total_refunded
//     FROM bookings b
//     LEFT JOIN payments p ON b.id = p.booking_id
//     WHERE b.id = $1
//     GROUP BY b.id
//   `;

//   const [payments, [summary]] = await Promise.all([
//     sequelize.query(paymentsQuery, {
//       bind: [booking_id],
//       type: sequelize.QueryTypes.SELECT
//     }),
//     sequelize.query(summaryQuery, {
//       bind: [booking_id],
//       type: sequelize.QueryTypes.SELECT
//     })
//   ]);

//   const balance = summary ? summary.total_amount - summary.total_paid + summary.total_refunded : 0;

//   res.json({
//     success: true,
//     data: {
//       payments,
//       summary: {
//         total_paid: summary?.total_paid || 0,
//         total_refunded: summary?.total_refunded || 0,
//         current_balance: balance,
//         booking_total: summary?.total_amount || 0
//       }
//     }
//   });
// });


// const getPaymentsByBookingId = asyncHandler(async (req, res) => {
//     // We assume the route parameter is the booking ID: /api/payments/booking/:id
//     const { id: booking_id } = req.params; 

//     if (!booking_id) {
//         return res.status(400).json({ success: false, error: 'Booking ID is required.' });
//     }

//     // 1. Query to get ALL Financial Transactions (Payments and Adjustments)
//     // We UNION the payment and adjustment tables for a unified timeline view.
//     const transactionsQuery = `
//         SELECT
//             p.payment_id AS id,
//             'Payment' AS type,
//             p.amount,
//             p.method,
//             p.paid_at AS transaction_date,
//             p.payment_reference AS reference_note
//         FROM public.payment p
//         WHERE p.booking_id = $1

//         UNION ALL

//         SELECT
//             pa.adjustment_id AS id,
//             pa.type AS type, -- Will be 'refund', 'chargeback', 'manual_adjustment'
//             pa.amount * -1 AS amount, -- Refunds are negative for net calculation display
//             'Adjustment' AS method,
//             pa.created_at AS transaction_date,
//             pa.reference_note
//         FROM public.payment_adjustment pa
//         WHERE pa.booking_id = $1
        
//         ORDER BY transaction_date DESC;
//     `;

//     // 2. Query for Financial Summary (Using PostgreSQL functions)
//     const summaryQuery = `
//         SELECT
//             fn_bill_total($1) AS total_bill,
//             fn_total_paid($1) AS total_paid,
//             fn_total_refunds($1) AS total_refunded,
//             fn_net_balance($1) AS net_balance -- This is the current balance due (or credit)
//         FROM public.booking b
//         WHERE b.booking_id = $1
//     `;

//     const [transactionsResult, summaryResult] = await Promise.all([
//         executeQuery(transactionsQuery, [booking_id]),
//         executeQuery(summaryQuery, [booking_id])
//     ]);

//     if (summaryResult.rows.length === 0) {
//         return res.status(404).json({ success: false, error: 'Booking not found.' });
//     }

//     const summary = summaryResult.rows[0];

//     // Calculate Balance Due (If fn_net_balance returns a positive value, it's due; negative is credit)
//     const current_balance = parseFloat(summary.net_balance);

//     res.json({
//         success: true,
//         data: {
//             booking_id: booking_id,
//             transactions: transactionsResult.rows,
//             summary: {
//                 total_bill: parseFloat(summary.total_bill).toFixed(2),
//                 total_paid: (parseFloat(summary.total_paid) - parseFloat(summary.total_refunded)).toFixed(2), // Net Paid
//                 total_refunded: parseFloat(summary.total_refunded).toFixed(2),
//                 current_balance: current_balance.toFixed(2)
//             }
//         }
//     });
// });

const getPaymentsByBookingId = asyncHandler(async (req, res) => {
    const { id: booking_id } = req.params;

    if (!booking_id) {
        return res.status(400).json({ success: false, error: 'Booking ID is required.' });
    }

    // 1️⃣ Unified Transactions Query (Force type column to TEXT to avoid enum conflict)
    const transactionsQuery = `
    SELECT
        p.payment_id AS id,
        CAST('Payment' AS TEXT) AS type,
        p.amount,
        CAST(p.method AS TEXT) AS method,  -- ✅ convert enum to text
        p.paid_at AS transaction_date,
        p.payment_reference AS reference_note
    FROM public.payment p
    WHERE p.booking_id = $1

    UNION ALL

    SELECT
        pa.adjustment_id AS id,
        CAST(pa.type AS TEXT) AS type,
        pa.amount * -1 AS amount,
        CAST('Adjustment' AS TEXT) AS method,  -- ✅ cast to text explicitly
        pa.created_at AS transaction_date,
        pa.reference_note
    FROM public.payment_adjustment pa
    WHERE pa.booking_id = $1
        
    ORDER BY transaction_date DESC;
`;


    // 2️⃣ Financial Summary
    const summaryQuery = `
        SELECT
            fn_bill_total($1) AS total_bill,
            fn_total_paid($1) AS total_paid,
            fn_total_refunds($1) AS total_refunded,
            fn_net_balance($1) AS net_balance
        FROM public.booking b
        WHERE b.booking_id = $1
    `;

    try {
        const [transactionsResult, summaryResult] = await Promise.all([
            executeQuery(transactionsQuery, [booking_id]),
            executeQuery(summaryQuery, [booking_id])
        ]);

        if (summaryResult.rows.length === 0) {
            return res.status(404).json({ success: false, error: 'Booking not found.' });
        }

        const summary = summaryResult.rows[0];
        const current_balance = parseFloat(summary.net_balance);

        res.json({
            success: true,
            data: {
                booking_id: booking_id,
                transactions: transactionsResult.rows,
                summary: {
                    total_bill: parseFloat(summary.total_bill).toFixed(2),
                    total_paid: (parseFloat(summary.total_paid) - parseFloat(summary.total_refunded)).toFixed(2),
                    total_refunded: parseFloat(summary.total_refunded).toFixed(2),
                    current_balance: current_balance.toFixed(2)
                }
            }
        });

    } catch (error) {
        console.error('getPaymentsByBookingId Error:', error);
        res.status(500).json({
            success: false,
            error: `Internal server error: ${error.message}`
        });
    }
});


module.exports = {
  getAllPayments,
  getPaymentById,
  createPayment,
  //updatePaymentStatus,
  processRefund,
  getPaymentsByBookingId
};