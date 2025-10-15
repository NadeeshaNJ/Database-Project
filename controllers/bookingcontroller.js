// const { Booking, Guest, Room, RoomType, Payment, PaymentAdjustment, PreBooking } = require('../models');

// const { Op } = require('sequelize');
// const { asyncHandler } = require('../middleware/errorHandler');
// const { BOOKING_STATUS } = require('../utils/enums');
// const path = require('path');

// /**
//  * Get all bookings with filtering
//  */
// const getAllBookings = asyncHandler(async (req, res) => {
//     const {
//         status,
//         check_in_start,
//         check_in_end,
//         check_out_start,
//         check_out_end,
//         guest_name,
//         room_number,
//         page = 1,
//         limit = 10
//     } = req.query;

//     const offset = (page - 1) * limit;
//     const params = [];
//     let paramIndex = 0;

//     let query = `
//         SELECT 
//             b.booking_id,
//             b.check_in_date,
//             b.check_out_date,
//             b.status,
//             b.created_at,
//             g.guest_id,
//             g.full_name as guest_name,
//             g.email as guest_email,
//             g.phone as guest_phone,
//             r.room_id,
//             r.room_number,
//             rt.name as room_type,
//             rt.daily_rate,
//             pb.pre_booking_id,
//             pb.prebooking_method,
//             COALESCE(
//                 json_agg(
//                     json_build_object(
//                         'payment_id', p.payment_id,
//                         'amount', p.amount,
//                         'method', p.method,
//                         'paid_at', p.paid_at,
//                         'advance_payment', p.advance_payment
//                     )
//                 ) FILTER (WHERE p.payment_id IS NOT NULL), 
//                 '[]'
//             ) as payments
//         FROM bookings b
//         JOIN guests g ON b.guest_id = g.guest_id
//         JOIN rooms r ON b.room_id = r.room_id
//         JOIN room_types rt ON r.room_type_id = rt.room_type_id
//         LEFT JOIN pre_bookings pb ON b.pre_booking_id = pb.pre_booking_id
//         LEFT JOIN payments p ON b.booking_id = p.booking_id
//         WHERE 1=1
//     `;

//     // Status filter
//     if (status) {
//         query += ` AND b.status = $${++paramIndex}`;
//         params.push(status);
//     }

//     // Date range filters
//     if (check_in_start && check_in_end) {
//         query += ` AND b.check_in_date BETWEEN $${++paramIndex} AND $${++paramIndex}`;
//         params.push(check_in_start, check_in_end);
//     }

//     if (check_out_start && check_out_end) {
//         query += ` AND b.check_out_date BETWEEN $${++paramIndex} AND $${++paramIndex}`;
//         params.push(check_out_start, check_out_end);
//     }

//     // Guest name filter
//     if (guest_name) {
//         query += ` AND g.full_name ILIKE $${++paramIndex}`;
//         params.push(`%${guest_name}%`);
//     }

//     // Room number filter
//     if (room_number) {
//         query += ` AND r.room_number = $${++paramIndex}`;
//         params.push(room_number);
//     }

//     // Group by clause for json_agg
//     query += `
//         GROUP BY 
//             b.booking_id, 
//             g.guest_id, 
//             r.room_id, 
//             rt.room_type_id, 
//             pb.pre_booking_id
//     `;

//     // Add pagination
//     query += ` ORDER BY b.created_at DESC LIMIT $${++paramIndex} OFFSET $${++paramIndex}`;
//     params.push(parseInt(limit), parseInt(offset));

//     // Get total count for pagination
//     const countQuery = `
//         SELECT COUNT(DISTINCT b.booking_id) 
//         FROM (${query.split('GROUP BY')[0]}) as sub
//     `;

//     const [bookings, countResult] = await Promise.all([
//         executeQuery(query, params),
//         executeQuery(countQuery, params.slice(0, -2))
//     ]);

//     const totalBookings = parseInt(countResult.rows[0].count);
//     const totalPages = Math.ceil(totalBookings / limit);

//     res.json({
//         success: true,
//         data: {
//             bookings: bookings.rows,
//             pagination: {
//                 total: totalBookings,
//                 page: parseInt(page),
//                 totalPages,
//                 hasNext: page < totalPages,
//                 hasPrev: page > 1
//             }
//         }
//     });
// });

// /**
//  * Get booking details with all related information
//  */
// const getBookingDetails = asyncHandler(async (req, res) => {
//     const { bookingId } = req.params;
    
//     const booking = await Booking.findOne({
//         where: { booking_id: bookingId },
//         include: [
//             {
//                 model: Guest,
//                 attributes: ['guest_id', 'full_name', 'email', 'phone']
//             },
//             {
//                 model: Room,
//                 include: [{
//                     model: RoomType,
//                     attributes: ['room_type_id', 'name', 'capacity', 'daily_rate']
//                 }]
//             },
//             {
//                 model: Payment,
//                 attributes: ['payment_id', 'amount', 'method', 'paid_at', 'payment_reference']
//             },
//             {
//                 model: PaymentAdjustment,
//                 attributes: ['adjustment_id', 'amount', 'type', 'reference_note', 'created_at']
//             }
//         ]
//     });

//     if (!booking) {
//         return res.status(404).json({
//             success: false,
//             error: 'Booking not found'
//         });
//     }

//     res.json({
//         success: true,
//         data: booking
//     });
// });

// /**
//  * Check room availability
//  */
// const checkAvailability = asyncHandler(async (req, res) => {
//     const {
//         check_in,
//         check_out,
//         room_type_id,
//         min_capacity,
//         min_price,
//         max_price
//     } = req.query;

//     if (!check_in || !check_out) {
//         return res.status(400).json({
//             success: false,
//             error: 'Check-in and check-out dates are required'
//         });
//     }

//     // Find occupied rooms for the given dates
//     const occupiedRoomIds = (await Booking.findAll({
//         where: {
//             status: {
//                 [Op.in]: [BOOKING_STATUS.BOOKED, BOOKING_STATUS.CHECKED_IN]
//             },
//             [Op.or]: [
//                 {
//                     check_in_date: {
//                         [Op.between]: [check_in, check_out]
//                     }
//                 },
//                 {
//                     check_out_date: {
//                         [Op.between]: [check_in, check_out]
//                     }
//                 },
//                 {
//                     [Op.and]: [
//                         { check_in_date: { [Op.lte]: check_in } },
//                         { check_out_date: { [Op.gte]: check_out } }
//                     ]
//                 }
//             ]
//         },
//         attributes: ['room_id']
//     })).map(booking => booking.room_id);

//     // Build room type conditions
//     const roomTypeConditions = {};
//     if (room_type_id) {
//         roomTypeConditions.room_type_id = room_type_id;
//     }
//     if (min_capacity) {
//         roomTypeConditions.capacity = { [Op.gte]: min_capacity };
//     }
//     if (min_price) {
//         roomTypeConditions.daily_rate = { [Op.gte]: min_price };
//     }
//     if (max_price) {
//         roomTypeConditions.daily_rate = {
//             ...roomTypeConditions.daily_rate,
//             [Op.lte]: max_price
//         };
//     }

//     // Find available rooms
//     const availableRooms = await Room.findAll({
//         where: {
//             status: ROOM_STATUS.AVAILABLE,
//             room_id: {
//                 [Op.notIn]: occupiedRoomIds
//             }
//         },
//         include: [{
//             model: RoomType,
//             where: roomTypeConditions,
//             required: true
//         }]
//     });

//     res.json({
//         success: true,
//         data: availableRooms.map(room => ({
//             ...room.toJSON(),
//             is_available: true
//         }))
//     });
// });

// /**
//  * Create new booking
//  */
// const createBooking = asyncHandler(async (req, res) => {
//     const {
//         guest_id,
//         room_id,
//         check_in_date,
//         check_out_date,
//         booked_rate,
//         tax_rate_percent = 0,
//         discount_amount = 0,
//         advance_payment,
//         preferred_payment_method,
//         payment_details
//     } = req.body;

//     const queries = [];

//     // Check room availability
//     const availabilityCheck = {
//         text: `
//             SELECT EXISTS (
//                 SELECT 1 FROM bookings
//                 WHERE room_id = $1
//                 AND status IN ('Booked', 'Checked-In')
//                 AND (
//                     (check_in_date <= $2 AND check_out_date >= $3)
//                     OR (check_in_date <= $4 AND check_out_date >= $5)
//                     OR (check_in_date >= $6 AND check_out_date <= $7)
//                 )
//             )
//         `,
//         params: [
//             room_id,
//             check_out_date, check_in_date,
//             check_in_date, check_out_date,
//             check_in_date, check_out_date
//         ]
//     };

//     // Create booking
//     const createBookingQuery = {
//         text: `
//             INSERT INTO bookings (
//                 guest_id,
//                 room_id,
//                 check_in_date,
//                 check_out_date,
//                 booked_rate,
//                 tax_rate_percent,
//                 discount_amount,
//                 advance_payment,
//                 preferred_payment_method,
//                 status,
//                 created_at
//             )
//             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
//             RETURNING booking_id
//         `,
//         params: [
//             guest_id,
//             room_id,
//             check_in_date,
//             check_out_date,
//             booked_rate,
//             tax_rate_percent,
//             discount_amount,
//             advance_payment,
//             preferred_payment_method,
//             BOOKING_STATUS.BOOKED
//         ]
//     };

//     // If payment details provided, create payment record
//     if (payment_details) {
//         const createPaymentQuery = {
//             text: `
//                 INSERT INTO payments (
//                     booking_id,
//                     amount,
//                     method,
//                     payment_reference,
//                     paid_at
//                 )
//                 VALUES (
//                     (SELECT booking_id FROM bookings WHERE guest_id = $1 ORDER BY created_at DESC LIMIT 1),
//                     $2, $3, $4, NOW()
//                 )
//             `,
//             params: [
//                 guest_id,
//                 payment_details.amount,
//                 payment_details.method,
//                 payment_details.reference
//             ]
//         };
//         queries.push(createPaymentQuery);
//     }

//     try {
//         // Check availability first
//         const availabilityResult = await executeQuery(
//             availabilityCheck.text,
//             availabilityCheck.params
//         );

//         if (availabilityResult.rows[0].exists) {
//             return res.status(400).json({
//                 success: false,
//                 error: 'Room is not available for the selected dates'
//             });
//         }

//         // Execute booking creation transaction
//         const results = await executeTransaction([createBookingQuery, ...queries]);
//         const bookingId = results[0].rows[0].booking_id;

//         // Get the created booking details
//         const bookingDetails = await executeQuery(
//             sqlLoader.getQuery('getBookingDetails'),
//             [bookingId]
//         );

//         res.status(201).json({
//             success: true,
//             data: bookingDetails.rows[0]
//         });
//     } catch (error) {
//         if (error.code === '23514') { // check_violation
//             return res.status(400).json({
//                 success: false,
//                 error: 'Advance payment must be at least 10% of total room charges'
//             });
//         }
//         throw error;
//     }
// });

// /**
//  * Update booking status
//  */
// const updateBookingStatus = asyncHandler(async (req, res) => {
//     const { bookingId } = req.params;
//     const { status } = req.body;

//     if (!Object.values(BOOKING_STATUS).includes(status)) {
//         return res.status(400).json({
//             success: false,
//             error: 'Invalid booking status'
//         });
//     }

//     const query = `
//         UPDATE bookings
//         SET 
//             status = $1,
//             updated_at = NOW()
//         WHERE booking_id = $2
//         RETURNING *
//     `;

//     const result = await executeQuery(query, [status, bookingId]);

//     if (!result.rows[0]) {
//         return res.status(404).json({
//             success: false,
//             error: 'Booking not found'
//         });
//     }

//     res.json({
//         success: true,
//         data: result.rows[0]
//     });
// });

// /**
//  * Cancel booking with automatic refund processing
//  */
// const cancelBooking = asyncHandler(async (req, res) => {
//     const { bookingId } = req.params;
    
//     // Using the stored procedure for cancellation
//     const query = `
//         SELECT * FROM sp_cancel_booking($1, $2)
//     `;

//     const result = await executeQuery(query, [
//         bookingId,
//         req.body.reason || null
//     ]);

//     if (!result.rows[0]) {
//         return res.status(404).json({
//             success: false,
//             error: 'Booking not found'
//         });
//     }

//     res.json({
//         success: true,
//         data: result.rows[0]
//     });
// });

// module.exports = {
//     getAllBookings,
//     getBookingDetails,
//     checkAvailability,
//     createBooking,
//     updateBookingStatus,
//     cancelBooking
// };

const { executeQuery, executeTransaction } = require('../config/database');
const { Booking, Guest, Room, RoomType, Payment, PaymentAdjustment, PreBooking } = require('../models');
const { Op } = require('sequelize');
const { asyncHandler } = require('../middleware/errorHandler');
const { BOOKING_STATUS, ROOM_STATUS } = require('../utils/enums');
const path = require('path');
const {pool} = require('../config/database');
// --- Pre-Booking Logic (Using SQL) ---

/**
 * Create new Pre-Booking record (Initiated by staff or customer)
 */
// const createPreBooking = asyncHandler(async (req, res) => {
//     // Guest ID is derived from the JWT or body (must be checked by router validation)
//     const guestId = req.user.guestId || req.body.guest_id; 
//     const createdByEmployeeId = req.user.employeeId || null; 

//     const {
//         capacity,
//         prebooking_method,
//         expected_check_in,
//         expected_check_out,
//         room_id, // This room ID must be checked for conflict
//     } = req.body;

//     if (!guestId) {
//         return res.status(400).json({ success: false, error: 'Guest ID is required.' });
//     }
    
//     const queries = [];
    
//     // --- 1. CRITICAL: Check for Overlap on Pre-Bookings ---
//     if (room_id) {
//         const overlapCheckQuery = `
//             SELECT EXISTS (
//                 SELECT 1 
//                 FROM public.pre_booking
//                 WHERE 
//                     room_id = $1
//                     AND (
//                         (expected_check_in, expected_check_out) OVERLAPS (DATE $2, DATE $3)
//                     )
//             ) AS is_occupied
//         `;
        
//         // Execute the check outside the transaction
//         const overlapResult = await executeQuery(overlapCheckQuery, [
//             room_id,
//             expected_check_in,
//             expected_check_out
//         ]);

//         if (overlapResult.rows[0].is_occupied) {
//             return res.status(400).json({
//                 success: false,
//                 error: 'Room is already pre-booked for the selected dates.'
//             });
//         }
//     }


//     // ✅ Using explicit SQL for insertion
//     const query = `
//         INSERT INTO public.pre_booking (
//             guest_id, capacity, prebooking_method, 
//             expected_check_in, expected_check_out, room_id, 
//             created_by_employee_id, created_at
//         )
//         VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
//         RETURNING pre_booking_id
//     `;
    
//     const params = [
//         guestId, capacity, prebooking_method, 
//         expected_check_in, expected_check_out, room_id || null, 
//         createdByEmployeeId
//     ];

//     try {
//         const result = await executeQuery(query, params);
//         res.status(201).json({
//             success: true,
//             message: 'Pre-Booking successfully logged via SQL.',
//             pre_booking_id: result.rows[0].pre_booking_id
//         });
//     } catch (error) {
//         console.error('Pre-Booking SQL Error:', error);
//         throw error;
//     }
// });


// --- Confirmed Booking Logic (Using SQL Transaction) ---

const createPreBooking = asyncHandler(async (req, res) => {
    const guestId = req.user.guestId || req.body.guest_id;
    const createdByEmployeeId = req.user.employeeId || req.body.created_by_employee_id || null;

    const {
        capacity,
        prebooking_method,
        expected_check_in,
        expected_check_out,
        room_id
    } = req.body;

    if (!guestId) {
        return res.status(400).json({ success: false, error: 'Guest ID is required.' });
    }
    if (!expected_check_in || !expected_check_out) {
        return res.status(400).json({ success: false, error: 'Check-in and check-out dates are required.' });
    }

    // --- 1️⃣ Room Overlap Check (full inclusive range) ---
    if (room_id) {
        const overlapCheckQuery = `
            SELECT EXISTS (
                SELECT 1 
                FROM public.pre_booking
                WHERE 
                    room_id = $1
                    AND daterange(expected_check_in, expected_check_out, '[]')
                        && daterange($2::date, $3::date, '[]')
            ) AS is_occupied
        `;

        const overlapResult = await executeQuery(overlapCheckQuery, [
            room_id,
            expected_check_in,
            expected_check_out
        ]);

        if (overlapResult.rows[0].is_occupied) {
            return res.status(400).json({
                success: false,
                error: '❌ Room is already pre-booked for the selected dates.'
            });
        }
    }

    // --- 2️⃣ Create Pre-Booking Record ---
    const insertQuery = `
        INSERT INTO public.pre_booking (
            guest_id, capacity, prebooking_method, 
            expected_check_in, expected_check_out, room_id, 
            created_by_employee_id, created_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
        RETURNING pre_booking_id
    `;
    
    const params = [
        guestId,
        capacity,
        prebooking_method,
        expected_check_in,
        expected_check_out,
        room_id || null,
        createdByEmployeeId
    ];

    try {
        const result = await executeQuery(insertQuery, params);
        res.status(201).json({
            success: true,
            message: '✅ Pre-Booking successfully created.',
            pre_booking_id: result.rows[0].pre_booking_id
        });
    } catch (error) {
        console.error('Pre-Booking SQL Error:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error while creating pre-booking.'
        });
    }
});

//no need of cancelling pre_book since anyway need a booking to confirm
// const cancelPreBooking = asyncHandler(async (req, res) => {
//     // The pre_booking_id to cancel is typically passed as a route parameter (e.g., /api/prebooking/:id)
//     const { pre_booking_id } = req.body; 
//     const role = req.body.role;
//     if(role=='Customer'){
//         return res.status(403).json({ success: false, error: 'Only staff or admin can create a booking.' });
//     }

//     if (!pre_booking_id) {
//         return res.status(400).json({ success: false, error: 'Pre-Booking ID is required for cancellation.' });
//     }

//     // --- 1️⃣ Status Update Query ---
//     const cancelQuery = {
//         text :`
//         UPDATE public.pre_booking
//         SET 
//             created_at = NOW()   -- Add a timestamp for when the cancellation occurred
//         WHERE 
//             pre_booking_id = $1
//         RETURNING pre_booking_id;
//     `, params: [pre_booking_id] };

//     try {
//         const result = await executeQuery(cancelQuery.text, cancelQuery.params);

//         if (result.rowCount === 0) {
//             // Check if the ID exists but the status prevented the update
//             const checkExistsQuery = `SELECT status FROM public.pre_booking WHERE pre_booking_id = $1;`;
//             const checkResult = await executeQuery(checkExistsQuery, [pre_booking_id]);

//             if (checkResult.rowCount === 0) {
//                  // The ID does not exist
//                 return res.status(404).json({
//                     success: false,
//                     error: `❌ Pre-Booking with ID ${pre_booking_id} not found.`
//                 });
//             } else {
//                  // The pre-booking exists but is in a state that cannot be canceled (e.g., already 'Canceled' or 'CheckedIn')
//                 return res.status(400).json({
//                     success: false,
//                     error: `❌ Pre-Booking ID ${pre_booking_id} cannot be canceled (current status: ${checkResult.rows[0].status}).`
//                 });
//             }
//         }

//         // Successfully canceled
//         res.status(200).json({
//             success: true,
//             message: `✅ Pre-Booking ID ${pre_booking_id} successfully canceled.`,
//             pre_booking_id: result.rows[0].pre_booking_id,
//             new_status: result.rows[0].status
//         });
//     } catch (error) {
//         console.error('Cancellation SQL Error:', error);
//         res.status(500).json({
//             success: false,
//             error: `Internal server error while canceling pre-booking. ${error.message}`
//         });
//     }
// });



// const cancelPreBooking = asyncHandler(async (req, res) => {
//     // Accept either body or param ID
//     const { pre_booking_id } = req.body.pre_booking_id ? req.body : req.params;
//     const role = req.body.role;

//     // 1️⃣ Permission check
//     if (role === 'Customer') {
//         return res.status(403).json({
//             success: false,
//             error: 'Only staff or admin can cancel a pre-booking.'
//         });
//     }

//     if (!pre_booking_id) {
//         return res.status(400).json({
//             success: false,
//             error: 'Pre-Booking ID is required for cancellation.'
//         });
//     }

//     try {
//         // 2️⃣ Attempt cancellation (only if not already canceled)
//         const cancelQuery = `
//             UPDATE public.pre_booking
//             SET 
//                 status = 'Canceled',
//                 status_updated_at = NOW()
//             WHERE 
//                 pre_booking_id = $1
//                 AND status <> 'Canceled'
//             RETURNING pre_booking_id, status;
//         `;

//         const result = await executeQuery(cancelQuery, [pre_booking_id]);

//         if (result.rowCount === 0) {
//             // 3️⃣ Check if booking exists but cannot be canceled
//             const checkQuery = `
//                 SELECT status 
//                 FROM public.pre_booking 
//                 WHERE pre_booking_id = $1;
//             `;
//             const checkResult = await executeQuery(checkQuery, [pre_booking_id]);

//             if (checkResult.rowCount === 0) {
//                 return res.status(404).json({
//                     success: false,
//                     error: `❌ Pre-booking with ID ${pre_booking_id} not found.`
//                 });
//             } else {
//                 return res.status(400).json({
//                     success: false,
//                     error: `❌ Cannot cancel pre-booking ${pre_booking_id} (current status: ${checkResult.rows[0].status}).`
//                 });
//             }
//         }

//         // 4️⃣ Success response
//         return res.status(200).json({
//             success: true,
//             message: `✅ Pre-booking ${pre_booking_id} successfully canceled.`,
//             pre_booking_id: result.rows[0].pre_booking_id,
//             new_status: result.rows[0].status
//         });

//     } catch (error) {
//         console.error('❌ Cancel Pre-Booking SQL Error:', error);
//         return res.status(500).json({
//             success: false,
//             error: 'Internal server error while canceling pre-booking.'
//         });
//     }
// });


/**
 * Create new confirmed booking (Handles the final transaction)
 */
// const createBooking = asyncHandler(async (req, res) => {
//     // ✅ FIX 1: Get guest_id from the authenticated user's JWT
//     const guest_id = req.user.guestId; 

//     // Destructure required fields
//     const {
//         room_id,
//         check_in_date,
//         check_out_date,
//         booked_rate,
//         tax_rate_percent = 0,
//         discount_amount = 0,
//         advance_payment,
//         preferred_payment_method,
//         payment_details,
//         pre_booking_id 
//     } = req.body;

//     if (!guest_id) {
//         return res.status(400).json({ success: false, error: 'Guest ID is required for a confirmed booking.' });
//     }

//     const queries = [];

//     // 1. Create booking query
//     const createBookingQuery = {
//         text: `
//             INSERT INTO booking ( 
//                 guest_id, room_id, check_in_date, check_out_date, booked_rate,
//                 tax_rate_percent, discount_amount, advance_payment, preferred_payment_method,
//                 pre_booking_id, status, created_at
//             )
//             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())
//             RETURNING booking_id
//         `,
//         params: [
//             guest_id, room_id, check_in_date, check_out_date, booked_rate,
//             tax_rate_percent, discount_amount, advance_payment, preferred_payment_method,
//             pre_booking_id || null, 
//             BOOKING_STATUS.BOOKED
//         ]
//     };
//     queries.push(createBookingQuery);

//     // 2. Handle Payment Details (if payment details provided) - Added to the transaction
//     if (payment_details) {
//         const createPaymentQuery = {
//             // NOTE: Relying on the subquery to fetch the ID immediately after the booking insert
//             text: `
//                 INSERT INTO public.payment (
//                     booking_id, amount, method, payment_reference, paid_at
//                 )
//                 VALUES (
//                     (SELECT booking_id FROM booking WHERE guest_id = $1 ORDER BY created_at DESC LIMIT 1),
//                     $2, $3, $4, NOW()
//                 )
//             `,
//             params: [
//                 guest_id, // Used for subquery selection
//                 payment_details.amount,
//                 payment_details.method,
//                 payment_details.reference
//             ]
//         };
//         queries.push(createPaymentQuery);
//     }

//     try {
//         // Execute the booking creation transaction. 
//         const results = await executeTransaction(queries);
//         const bookingId = results[0].rows[0].booking_id;

//         res.status(201).json({
//             success: true,
//             message: 'Booking successfully created and confirmed.',
//             booking_id: bookingId 
//         });
//     } catch (error) {
//         if (error.code === '23514') { // PostgreSQL check_violation code (min advance payment)
//             return res.status(400).json({
//                 success: false,
//                 error: 'Advance payment must be at least 10% of total room charges.'
//             });
//         }
//         if (error.code === '23P01') { // PostgreSQL exclusion_violation code (no_overlapping_bookings)
//              return res.status(400).json({
//                 success: false,
//                 error: 'Room is already booked for the selected dates.'
//             });
//         }
//         console.error('Booking creation error:', error);
//         throw error;
//     }
// });


// --- Remaining Controller Functions (Assuming they are complete and rely on the execution helpers) ---

//const getAllBookings = asyncHandler(async (req, res) => { /* ... existing logic ... */ });


// NOTE: Assuming Booking, Payment, and PreBooking models are imported if needed,
// but all operations here use raw SQL helpers.

/**
 * Create new confirmed booking (Handles the final transaction)
 */
const createBooking = asyncHandler(async (req, res) => {
    const guest_id = req.body.guest_id; 
    const role=req.user.role;
    
    if(role=='Customer'){
        return res.status(403).json({ success: false, error: 'Only staff or admin can create a booking.' });
    }

    const {
        room_id, check_in_date, check_out_date, booked_rate, tax_rate_percent = 0,
        discount_amount = 0, advance_payment, preferred_payment_method, payment_details,
        pre_booking_id 
    } = req.body;
    
    const cost=booked_rate * ((new Date(check_out_date) - new Date(check_in_date)) / (1000 * 60 * 60 * 24));
    const need_payment=cost+cost*tax_rate_percent/100-discount_amount;
    if (!guest_id) {
        return res.status(400).json({ success: false, error: 'Guest ID is required for a confirmed booking.' });
    }

    const queries = [];

    // 1. Create booking query status-done
    const createBookingQuery = {
        text: `
            INSERT INTO booking ( 
                guest_id, room_id, check_in_date, check_out_date, booked_rate,
                tax_rate_percent, discount_amount, advance_payment, preferred_payment_method,
                pre_booking_id, status, created_at
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())
            RETURNING booking_id
        `,
        params: [
            guest_id, room_id, check_in_date, check_out_date, booked_rate,
            tax_rate_percent, discount_amount, advance_payment, preferred_payment_method,
            pre_booking_id || null, 
            BOOKING_STATUS.BOOKED
        ]
    };
    queries.push(createBookingQuery);
/*
    // 2. Handle Payment Details (if payment details provided) status-done
     if (true) {
        const createPaymentQuery = {
            text: `
                INSERT INTO payment (
                    booking_id, amount, method, payment_reference, paid_at
                )
                VALUES (
                    (SELECT booking_id FROM booking WHERE guest_id = $1 ORDER BY created_at DESC LIMIT 1),
                    $2, $3, $4, NOW()
                )
            `,
            params: [
                guest_id, // Used for subquery selection
                need_payment,
                preferred_payment_method,
                payment_details
            ]
        };
        queries.push(createPaymentQuery);
    }
   */ 
    // 3️⃣ Update Room Availability
    // const updateRoomQuery = {
    //     text: `
    //         UPDATE room
    //         SET status = 'Booked'
    //         WHERE room_id = $1
    //     `,
    //     params: [room_id]
    // };
    // queries.push(updateRoomQuery);

    try {
        const results = await executeTransaction(queries);
        const bookingId = results[0].rows[0].booking_id;

        res.status(201).json({
            success: true,
            message: 'Booking successfully created and confirmed.',
            booking_id: bookingId 
        });
    } catch (error) {
        if (error.code === '23514') { // check_violation (min advance payment)
            return res.status(400).json({ error: 'Advance payment must be at least 10% of total room charges.' });
        }
        if (error.code === '23P01') { // exclusion_violation (no_overlapping_bookings)
             return res.status(400).json({ error: 'Room is already booked for the selected dates.' });
        }
        console.error('Booking creation error:', error);
        throw error;
    }
});

const cancelcreatedBooking = asyncHandler(async (req, res) => {
    const { booking_id } = req.body;
    const role = req.user.role;

    // Customers can cancel only their own pending/booked bookings
    const allowedStatuses = ['Booked'];

    const bookingResult = await pool.query(
        `SELECT status FROM booking WHERE booking_id = $1`,
        [booking_id]
    );

    if (bookingResult.rowCount === 0) {
        return res.status(404).json({ success: false, error: 'Booking not found.' });
    }

    const currentStatus = bookingResult.rows[0].status;

    if (!allowedStatuses.includes(currentStatus)) {
        return res.status(400).json({
            success: false,
            error: `Cannot cancel a booking that is already ${currentStatus}.`
        });
    }

    await pool.query(
        `UPDATE booking SET status = 'Cancelled' WHERE booking_id = $1`,
        [booking_id]
    );

    res.status(200).json({
        success: true,
        message: 'Booking successfully cancelled.'
    });
});



/* Get all bookings with filtering and pagination
 */
// const getAllBookings = asyncHandler(async (req, res) => {
//     // NOTE: This function's implementation was largely provided in your prompt, 
//     // so we assume the existing SQL query logic is being executed correctly.
    
//     const {
//         status,
//         check_in_start,
//         check_in_end,
//         check_out_start,
//         check_out_end,
//         guest_name,
//         room_number,
//         page = 1,
//         limit = 10
//     } = req.query;

//     const offset = (page - 1) * limit;
//     const params = [];
//     let paramIndex = 0;

//     let query = `
//         SELECT 
//             b.booking_id,
//             b.check_in_date,
//             b.check_out_date,
//             b.status,
//             b.created_at,
//             g.guest_id,
//             g.full_name as guest_name,
//             g.email as guest_email,
//             g.phone as guest_phone,
//             r.room_id,
//             r.room_number,
//             rt.name as room_type,
//             rt.daily_rate,
//             pb.pre_booking_id,
//             pb.prebooking_method,
//             -- Aggregates payment details into a JSON array
//             COALESCE(
//                 json_agg(
//                     json_build_object(
//                         'payment_id', p.payment_id,
//                         'amount', p.amount,
//                         'method', p.method,
//                         'paid_at', p.paid_at,
//                         'advance_payment', b.advance_payment -- Use booking table's advance
//                     )
//                 ) FILTER (WHERE p.payment_id IS NOT NULL), 
//                 '[]'
//             ) as payments
//         FROM public.booking b
//         JOIN public.guest g ON b.guest_id = g.guest_id
//         JOIN public.room r ON b.room_id = r.room_id
//         JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
//         LEFT JOIN public.pre_booking pb ON b.pre_booking_id = pb.pre_booking_id
//         LEFT JOIN public.payment p ON b.booking_id = p.booking_id
//         WHERE 1=1
//     `;

//     // Status filter
//     if (status) {
//         query += ` AND b.status = $${++paramIndex}`;
//         params.push(status);
//     }

//     // Date range filters (check-in)
//     if (check_in_start && check_in_end) {
//         query += ` AND b.check_in_date BETWEEN $${++paramIndex} AND $${++paramIndex}`;
//         params.push(check_in_start, check_in_end);
//     }

//     // Date range filters (check-out)
//     if (check_out_start && check_out_end) {
//         query += ` AND b.check_out_date BETWEEN $${++paramIndex} AND $${++paramIndex}`;
//         params.push(check_out_start, check_out_end);
//     }

//     // Guest name filter
//     if (guest_name) {
//         query += ` AND g.full_name ILIKE $${++paramIndex}`;
//         params.push(`%${guest_name}%`);
//     }

//     // Room number filter
//     if (room_number) {
//         query += ` AND r.room_number = $${++paramIndex}`;
//         params.push(room_number);
//     }

//     // Group by clause for json_agg
//     query += `
//         GROUP BY 
//             b.booking_id, 
//             g.guest_id, 
//             r.room_id, 
//             rt.room_type_id, 
//             pb.pre_booking_id
//     `;

//     // Pagination preparation
//     const countQuery = `
//         SELECT COUNT(DISTINCT b.booking_id) 
//         FROM (${query.split('GROUP BY')[0]}) as sub
//     `;
    
//     // Add pagination
//     query += ` ORDER BY b.created_at DESC LIMIT $${++paramIndex} OFFSET $${++paramIndex}`;
//     params.push(parseInt(limit), parseInt(offset));

//     const [bookings, countResult] = await Promise.all([
//         executeQuery(query, params),
//         executeQuery(countQuery, params.slice(0, -2)) // Count query doesn't need LIMIT/OFFSET params
//     ]);

//     const totalBookings = parseInt(countResult.rows[0].count);
//     const totalPages = Math.ceil(totalBookings / limit);

//     res.json({
//         success: true,
//         data: {
//             bookings: bookings.rows,
//             pagination: {
//                 total: totalBookings,
//                 page: parseInt(page),
//                 totalPages,
//                 hasNext: page < totalPages,
//                 hasPrev: page > 1
//             }
//         }
//     });
// });

// const getAllBookingsAndPrebookings = asyncHandler(async (req, res) => {
//     const {
//         status,
//         check_in_start,
//         check_in_end,
//         check_out_start,
//         check_out_end,
//         guest_name,
//         room_number,
//         page = 1,
//         limit = 10
//     } = req.query;

//     const offset = (page - 1) * limit;
//     const params = [];
//     let paramIndex = 0;

//     // Combined query: bookings + pre-bookings
//     let queryText = `
//         SELECT * FROM (
//             -- BOOKINGS
//             SELECT
//                 'Booking' AS type,
//                 b.booking_id AS id,
//                 b.check_in_date AS start_date,
//                 b.check_out_date AS end_date,
//                 b.status,
//                 g.guest_id,
//                 g.full_name AS guest_name,
//                 g.email AS guest_email,
//                 g.phone AS guest_phone,
//                 r.room_id,
//                 r.room_number,
//                 rt.name AS room_type,
//                 rt.daily_rate,
//                 b.advance_payment,
//                 pb.pre_booking_id,
//                 pb.prebooking_method,
//                 COALESCE(
//                     json_agg(
//                         json_build_object(
//                             'payment_id', p.payment_id,
//                             'amount', p.amount,
//                             'method', p.method,
//                             'paid_at', p.paid_at,
//                             'advance_payment', b.advance_payment
//                         )
//                     ) FILTER (WHERE p.payment_id IS NOT NULL), 
//                     '[]'
//                 ) AS payments
//             FROM public.booking b
//             JOIN public.guest g ON b.guest_id = g.guest_id
//             JOIN public.room r ON b.room_id = r.room_id
//             JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
//             LEFT JOIN public.pre_booking pb ON b.pre_booking_id = pb.pre_booking_id
//             LEFT JOIN public.payment p ON b.booking_id = p.booking_id
//             WHERE 1=1
//             GROUP BY b.booking_id, g.guest_id, r.room_id, rt.room_type_id, pb.pre_booking_id

//             UNION ALL

//             -- PRE-BOOKINGS
//             SELECT
//                 'Pre-Booking' AS type,
//                 pb.pre_booking_id AS id,
//                 pb.expected_check_in AS start_date,
//                 pb.expected_check_out AS end_date,
//                 NULL AS status,
//                 g.guest_id,
//                 g.full_name AS guest_name,
//                 g.email AS guest_email,
//                 g.phone AS guest_phone,
//                 r.room_id,
//                 r.room_number,
//                 rt.name AS room_type,
//                 rt.daily_rate,
//                 NULL AS advance_payment,
//                 pb.pre_booking_id,
//                 pb.prebooking_method,
//                 '[]'::json AS payments
//             FROM public.pre_booking pb
//             JOIN public.guest g ON g.guest_id = pb.guest_id
//             JOIN public.room r ON r.room_id = pb.room_id
//             JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
//             WHERE 1=1
//         ) AS combined
//         WHERE 1=1
//     `;

//     // FILTERS (applies to both bookings and pre-bookings)
//     if (status) {
//         queryText += ` AND type='Booking' AND combined.status = $${++paramIndex}`;
//         params.push(status);
//     }
//     if (check_in_start && check_in_end) {
//         queryText += ` AND combined.start_date BETWEEN $${++paramIndex} AND $${++paramIndex}`;
//         params.push(check_in_start, check_in_end);
//     }
//     if (check_out_start && check_out_end) {
//         queryText += ` AND combined.end_date BETWEEN $${++paramIndex} AND $${++paramIndex}`;
//         params.push(check_out_start, check_out_end);
//     }
//     if (guest_name) {
//         queryText += ` AND combined.guest_name ILIKE $${++paramIndex}`;
//         params.push(`%${guest_name}%`);
//     }
//     if (room_number) {
//         queryText += ` AND combined.room_number = $${++paramIndex}`;
//         params.push(room_number);
//     }

//     // Count query for pagination
//     const countQuery = `SELECT COUNT(*) FROM (${queryText}) AS count_sub`;

//     // Add ordering and pagination
//     queryText += ` ORDER BY combined.start_date DESC LIMIT $${++paramIndex} OFFSET $${++paramIndex}`;
//     params.push(parseInt(limit), parseInt(offset));

//     const [results, countResult] = await Promise.all([
//         executeQuery(queryText, params),
//         executeQuery(countQuery, params.slice(0, -2))
//     ]);

//     const total = parseInt(countResult.rows[0].count);
//     const totalPages = Math.ceil(total / limit);

//     res.json({
//         success: true,
//         data: {
//             bookings: results.rows,
//             pagination: {
//                 total,
//                 page: parseInt(page),
//                 totalPages,
//                 hasNext: page < totalPages,
//                 hasPrev: page > 1
//             }
//         }
//     });
// });
const getAllPrebookings = asyncHandler(async (req, res) => {
    const {
        status, // Status filter is tricky for pre-bookings as original query had NULL. We'll filter on the actual status column.
        check_in_start,
        check_in_end,
        check_out_start,
        check_out_end,
        guest_name,
        room_number,
        page = 1,
        limit = 10
    } = req.query;

    const offset = (page - 1) * limit;
    const params = [];
    let paramIndex = 0;

    // Base query: only pre-bookings
    let queryText = `
        SELECT
            'Pre-Booking' AS type,
            pb.pre_booking_id AS id,
            pb.expected_check_in AS start_date,
            pb.expected_check_out AS end_date,
            g.guest_id,
            g.full_name AS guest_name,
            g.email AS guest_email,
            g.phone AS guest_phone,
            r.room_id,
            r.room_number,
            rt.name AS room_type,
            rt.daily_rate,
            NULL::numeric AS advance_payment, -- Explicitly cast NULL for consistent type
            pb.pre_booking_id,
            pb.prebooking_method
        FROM public.pre_booking pb
        JOIN public.guest g ON g.guest_id = pb.guest_id
        LEFT JOIN public.room r ON r.room_id = pb.room_id
        LEFT JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
        WHERE 1=1
    `;

    // FILTERS (applies only to pre-bookings)
    if (status) {
        queryText += ` AND pb.status = $${++paramIndex}`;
        params.push(status);
    }
    if (check_in_start && check_in_end) {
        queryText += ` AND pb.expected_check_in BETWEEN $${++paramIndex} AND $${++paramIndex}`;
        params.push(check_in_start, check_in_end);
    }
    if (check_out_start && check_out_end) {
        queryText += ` AND pb.expected_check_out BETWEEN $${++paramIndex} AND $${++paramIndex}`;
        params.push(check_out_start, check_out_end);
    }
    if (guest_name) {
        queryText += ` AND g.full_name ILIKE $${++paramIndex}`;
        params.push(`%${guest_name}%`);
    }
    if (room_number) {
        queryText += ` AND r.room_number = $${++paramIndex}`;
        params.push(room_number);
    }

    // Count query for pagination (using the filter parameters)
    // We must use the queryText as it is BEFORE adding LIMIT/OFFSET
    const countQuery = `SELECT COUNT(*) FROM (${queryText}) AS count_sub`;
    const filterParams = [...params]; // Clone parameters used for filtering

    // Add ordering and pagination
    queryText += ` ORDER BY pb.expected_check_in DESC LIMIT $${++paramIndex} OFFSET $${++paramIndex}`;
    params.push(parseInt(limit), parseInt(offset));

    const [results, countResult] = await Promise.all([
        executeQuery(queryText, params),
        executeQuery(countQuery, filterParams) // Use only filter params for count query
    ]);

    const total = parseInt(countResult.rows[0].count);
    const totalPages = Math.ceil(total / limit);

    res.json({
        success: true,
        data: {
            prebookings: results.rows, // Changed key from 'bookings' to 'prebookings'
            pagination: {
                total,
                page: parseInt(page),
                totalPages,
                hasNext: page < totalPages,
                hasPrev: page > 1
            }
        }
    });
});

// const getAllBookings = asyncHandler(async (req, res) => {
//     const {
//         status,
//         check_in_start,
//         check_in_end,
//         check_out_start,
//         check_out_end,
//         guest_name,
//         room_number,
//         page = 1,
//         limit = 10
//     } = req.query;

//     const offset = (page - 1) * limit;
//     const params = [];
//     let paramIndex = 0;

//     let queryText = `
//         SELECT 
//             b.booking_id AS id,
//             'Confirmed' AS type,
//             b.check_in_date,
//             b.check_out_date,
//             b.status,
//             b.created_at,
//             g.guest_id,
//             g.full_name as guest_name,
//             g.email as guest_email,
//             g.phone as guest_phone,
//             r.room_id,
//             r.room_number,
//             rt.name as room_type,
//             rt.daily_rate,
//             pb.pre_booking_id,
//             pb.prebooking_method,
//             COALESCE(
//                 json_agg(
//                     json_build_object(
//                         'payment_id', p.payment_id,
//                         'amount', p.amount,
//                         'method', p.method,
//                         'paid_at', p.paid_at,
//                         'advance_payment', b.advance_payment 
//                     )
//                 ) FILTER (WHERE p.payment_id IS NOT NULL), 
//                 '[]'
//             ) as payments
//         FROM public.booking b
//         JOIN public.guest g ON b.guest_id = g.guest_id
//         JOIN public.room r ON b.room_id = r.room_id
//         JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
//         LEFT JOIN public.pre_booking pb ON b.pre_booking_id = pb.pre_booking_id
//         LEFT JOIN public.payment p ON b.booking_id = p.booking_id
//         WHERE 1=1
//     `;

//     // 1. FILTERS (applies to confirmed bookings)
//     if (status) {
//         queryText += ` AND b.status = $${++paramIndex}`;
//         params.push(status);
//     }

//     if (check_in_start && check_in_end) {
//         queryText += ` AND b.check_in_date BETWEEN $${++paramIndex} AND $${++paramIndex}`;
//         params.push(check_in_start, check_in_end);
//     }

//     if (check_out_start && check_out_end) {
//         queryText += ` AND b.check_out_date BETWEEN $${++paramIndex} AND $${++paramIndex}`;
//         params.push(check_out_start, check_out_end);
//     }

//     if (guest_name) {
//         queryText += ` AND g.full_name ILIKE $${++paramIndex}`;
//         params.push(`%${guest_name}%`);
//     }

//     if (room_number) {
//         queryText += ` AND r.room_number = $${++paramIndex}`;
//         params.push(room_number);
//     }

//     // 2. GROUP BY (Required for json_agg)
//     queryText += `
//         GROUP BY 
//             b.booking_id, 
//             g.guest_id, 
//             r.room_id, 
//             rt.room_type_id, 
//             pb.pre_booking_id
//     `;
    
//     // Store parameters used for filtering only
//     const filterParams = [...params]; 

//     // 3. Count query for pagination
//     // To ensure the count query uses the correct parameters, we must remove the GROUP BY clause from the source query for COUNT.
//     const countQuery = `
//         SELECT COUNT(DISTINCT b.booking_id) 
//         FROM (
//             ${queryText.split('GROUP BY')[0]} 
//         ) as sub
//     `;

//     // 4. Add ordering and pagination
//     queryText += ` ORDER BY b.created_at DESC LIMIT $${++paramIndex} OFFSET $${++paramIndex}`;
//     params.push(parseInt(limit), parseInt(offset));

//     const [results, countResult] = await Promise.all([
//         executeQuery(queryText, params),
//         executeQuery(countQuery, filterParams) // Use only filter params for count query
//     ]);

//     const total = parseInt(countResult.rows[0].count);
//     const totalPages = Math.ceil(total / limit);

//     res.json({
//         success: true,
//         data: {
//             bookings: results.rows,
//             pagination: {
//                 total,
//                 page: parseInt(page),
//                 totalPages,
//                 hasNext: page < totalPages,
//                 hasPrev: page > 1
//             }
//         }
//     });
// });

const getAllBookings = asyncHandler(async (req, res) => {
    const {
        status,
        check_in_start,
        check_in_end,
        check_out_start,
        check_out_end,
        guest_name,
        room_number,
        page = 1,
        limit = 10
    } = req.query;

    const offset = (page - 1) * limit;
    const params = [];
    let paramIndex = 0;

    // Base query for WHERE conditions
    let whereClause = 'WHERE 1=1';
    const filterParams = [];
    let filterParamIndex = 0;

    // Build WHERE clause with filters
    if (status) {
        whereClause += ` AND b.status = $${++filterParamIndex}`;
        filterParams.push(status);
    }

    if (check_in_start && check_in_end) {
        whereClause += ` AND b.check_in_date BETWEEN $${++filterParamIndex} AND $${++filterParamIndex}`;
        filterParams.push(check_in_start, check_in_end);
    }

    if (check_out_start && check_out_end) {
        whereClause += ` AND b.check_out_date BETWEEN $${++filterParamIndex} AND $${++filterParamIndex}`;
        filterParams.push(check_out_start, check_out_end);
    }

    if (guest_name) {
        whereClause += ` AND g.full_name ILIKE $${++filterParamIndex}`;
        filterParams.push(`%${guest_name}%`);
    }

    if (room_number) {
        whereClause += ` AND r.room_number = $${++filterParamIndex}`;
        filterParams.push(room_number);
    }

    // Main query
    let queryText = `
        SELECT 
            b.booking_id AS id,
            'Confirmed' AS type,
            b.check_in_date,
            b.check_out_date,
            b.status,
            b.created_at,
            b.booked_rate,
            b.advance_payment,
            g.guest_id,
            g.full_name AS guest_name,
            g.email AS guest_email,
            g.phone AS guest_phone,
            r.room_id,
            r.room_number,
            rt.name AS room_type,
            rt.daily_rate,
            pb.pre_booking_id,
            pb.prebooking_method,
            COALESCE(
                json_agg(
                    json_build_object(
                        'payment_id', p.payment_id,
                        'amount', p.amount,
                        'method', p.method,
                        'paid_at', p.paid_at,
                        'advance_payment', b.advance_payment
                    )
                ) FILTER (WHERE p.payment_id IS NOT NULL),
                '[]'
            ) AS payments
        FROM public.booking b
        JOIN public.guest g ON b.guest_id = g.guest_id
        JOIN public.room r ON b.room_id = r.room_id
        JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
        LEFT JOIN public.pre_booking pb ON b.pre_booking_id = pb.pre_booking_id
        LEFT JOIN public.payment p ON b.booking_id = p.booking_id
        ${whereClause}
        GROUP BY
            b.booking_id,
            b.check_in_date,
            b.check_out_date,
            b.status,
            b.created_at,
            b.booked_rate,
            b.advance_payment,
            g.guest_id,
            g.full_name,
            g.email,
            g.phone,
            r.room_id,
            r.room_number,
            rt.room_type_id,
            rt.name,
            rt.daily_rate,
            pb.pre_booking_id,
            pb.prebooking_method
        ORDER BY b.created_at DESC 
        LIMIT $${filterParamIndex + 1} 
        OFFSET $${filterParamIndex + 2}
    `;

    // Count query (simpler and more efficient)
    const countQuery = `
        SELECT COUNT(DISTINCT b.booking_id) as count
        FROM public.booking b
        JOIN public.guest g ON b.guest_id = g.guest_id
        JOIN public.room r ON b.room_id = r.room_id
        JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
        LEFT JOIN public.pre_booking pb ON b.pre_booking_id = pb.pre_booking_id
        LEFT JOIN public.payment p ON b.booking_id = p.booking_id
        ${whereClause}
    `;

    try {
        // Execute both queries
        const [results, countResult] = await Promise.all([
            executeQuery(queryText, [...filterParams, parseInt(limit), parseInt(offset)]),
            executeQuery(countQuery, filterParams)
        ]);

        const total = parseInt(countResult.rows[0].count);
        const totalPages = Math.ceil(total / limit);

        res.json({
            success: true,
            data: {
                bookings: results.rows,
                pagination: {
                    total,
                    page: parseInt(page),
                    totalPages,
                    hasNext: page < totalPages,
                    hasPrev: page > 1
                }
            }
        });
    } catch (err) {
        console.error('Error in getAllBookings:', err);
        res.status(500).json({ 
            success: false, 
            error: 'Internal server error',
            details: err.message 
        });
    }
});

const getBookingDetails = asyncHandler(async (req, res) => {
    // Extract ID from the route parameters
    const { id } = req.params; 
    
    if (!id) {
        return res.status(400).json({ success: false, error: 'Booking ID is required.' });
    }

    const query = `
        SELECT 
            b.booking_id AS id,
            'Confirmed' AS type,
            b.check_in_date,
            b.check_out_date,
            b.status,
            b.created_at,
            b.booked_rate,
            b.tax_rate_percent,
            b.discount_amount,
            b.advance_payment,
            b.preferred_payment_method,
            g.guest_id,
            g.full_name as guest_name,
            g.email as guest_email,
            g.phone as guest_phone,
            r.room_id,
            r.room_number,
            rt.name as room_type_name,
            rt.daily_rate,
            pb.pre_booking_id,
            pb.prebooking_method,
            -- Aggregate Payments
            COALESCE(
                json_agg(
                    json_build_object(
                        'payment_id', p.payment_id,
                        'amount', p.amount,
                        'method', p.method,
                        'paid_at', p.paid_at,
                        'reference', p.payment_reference
                    )
                ) FILTER (WHERE p.payment_id IS NOT NULL), 
                '[]'
            ) as payments,
            -- Calculate Net Balance Due (using your database function)
            fn_net_balance(b.booking_id) AS balance_due,
            fn_bill_total(b.booking_id) AS bill_total
            
        FROM public.booking b
        JOIN public.guest g ON b.guest_id = g.guest_id
        JOIN public.room r ON b.room_id = r.room_id
        JOIN public.room_type rt ON r.room_type_id = rt.room_type_id
        LEFT JOIN public.pre_booking pb ON b.pre_booking_id = pb.pre_booking_id
        LEFT JOIN public.payment p ON b.booking_id = p.booking_id
        
        WHERE b.booking_id = $1 -- Filter by specific booking ID
        
        -- GROUP BY every non-aggregated column (essential for PostgreSQL)
        GROUP BY 
            b.booking_id, g.guest_id, r.room_id, rt.room_type_id, pb.pre_booking_id
            -- Add calculated fields/functions that rely on b.booking_id outside the GROUP BY
            -- Note: PostgreSQL is usually smart enough to allow functions depending only on grouped PKs
    `;
    
    try {
        const result = await executeQuery(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Booking not found.'
            });
        }

        // Return the single booking record
        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Get Booking Details SQL Error:', error);
        res.status(500).json({
            success: false,
            error: `Internal server error while fetching booking details. ${error.message}`
        });
    }
});

const checkIn = asyncHandler(async (req, res) => {
    const { id: bookingId } = req.params; 

    // 1. Define Queries for Transaction
    const queries = [];

    // Query to get the current booking status and room_id
    const checkStatusQuery = `
        SELECT status, room_id, check_in_date 
        FROM public.booking 
        WHERE booking_id = $1
    `;
    const checkResult = await executeQuery(checkStatusQuery, [bookingId]);

    if (checkResult.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'Booking not found.' });
    }

    const { status, room_id, check_in_date } = checkResult.rows[0];
    const today = new Date().toISOString().slice(0, 10); // Current date in YYYY-MM-DD format

    // Prevent checking in if the booking is already checked out or cancelled
    if (status === 'Checked-Out' || status === 'Cancelled') {
        return res.status(400).json({ 
            success: false, 
            error: `Booking ${bookingId} is already ${status} and cannot be checked in.` 
        });
    }

    // Optional: Add logic for early check-in warning if today < check_in_date
    if (today < check_in_date.toISOString().slice(0, 10) && status === 'Booked') {
        console.warn(`Attempting early check-in for Booking ID ${bookingId}`);
        // You might decide to return an error, apply a fee, or proceed with a warning.
    }
    
    // 2. Booking Status Update
    const updateBookingQuery = {
        text: `
            UPDATE public.booking
            SET status = 'Checked-In', 
                actual_check_in = NOW(), -- Assumes you have an actual_check_in column
                updated_at = NOW() 
            WHERE booking_id = $1
            RETURNING booking_id, room_id
        `,
        params: [bookingId]
    };
    queries.push(updateBookingQuery);
    
    // 3. Room Status Update (Change room status to 'Occupied')
    const updateRoomQuery = {
        text: `
            UPDATE public.room
            SET status = 'Occupied'
            WHERE room_id = $1
        `,
        params: [room_id]
    };
    queries.push(updateRoomQuery);

    try {
        await executeTransaction(queries);

        res.status(200).json({
            success: true,
            message: `✅ Booking ID ${bookingId} successfully checked in. Room ${room_id} is now Occupied.`,
            booking_id: bookingId,
            new_status: 'Checked-In'
        });
    } catch (error) {
        console.error('Check-In Transaction Error:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error during check-in transaction.'
        });
    }
});

const updateBookingStatus = asyncHandler(async (req, res) => { /* ... existing logic ... */ });

module.exports = {
    getAllPrebookings,
    getAllBookings,
    getBookingDetails,
    checkIn,
    createPreBooking, 
    createBooking,
    updateBookingStatus,
    cancelcreatedBooking
};