// const express = require('express');
// const { body, param, query, validationResult } = require('express-validator');
// const { authenticateToken, authorizeRoles } = require('../middleware/auth');
// const { bookingValidations, commonValidations } = require('../middleware/validation');
// const { asyncHandler } = require('../middleware/errorHandler');
// const bookingController = require('../controllers/bookingcontroller');

// const router = express.Router();

// // Get all bookings
// router.get('/', [
//   query('status').optional().isIn(['pending', 'confirmed', 'checked_in', 'checked_out', 'cancelled']),
//   query('check_in_start').optional().isDate(),
//   query('check_in_end').optional().isDate(),
//   query('check_out_start').optional().isDate(),
//   query('check_out_end').optional().isDate(),
//   query('guest_name').optional().trim(),
//   query('room_number').optional().trim(),
//   query('page').optional().isInt({ min: 1 }),
//   query('limit').optional().isInt({ min: 1, max: 100 })
// ], authenticateToken, asyncHandler(bookingController.getAllBookings));

// // Get booking by ID
// router.get('/:id', [
//   commonValidations.id
// ], authenticateToken, asyncHandler(bookingController.getBookingById));

// // Create new booking
// router.post('/', [
//   ...bookingValidations.create
// ], authenticateToken, authorizeRoles('admin', 'receptionist', 'manager'), asyncHandler(bookingController.createBooking));

// // Update booking
// router.put('/:id', [
//   commonValidations.id,
//   body('check_in').optional().isDate(),
//   body('check_out').optional().isDate(),
//   body('adults').optional().isInt({ min: 1 }),
//   body('children').optional().isInt({ min: 0 }),
//   body('special_requests').optional().trim()
// ], authenticateToken, authorizeRoles('admin', 'receptionist', 'manager'), asyncHandler(bookingController.updateBooking));

// // Check-in guest
// router.post('/:id/checkin', [
//   commonValidations.id
// ], authenticateToken, authorizeRoles('admin', 'receptionist'), asyncHandler(bookingController.checkIn));

// // Check-out guest
// router.post('/:id/checkout', [
//   commonValidations.id
// ], authenticateToken, authorizeRoles('admin', 'receptionist'), asyncHandler(bookingController.checkOut));

// // Cancel booking
// router.post('/:id/cancel', [
//   commonValidations.id,
//   body('reason').optional().trim()
// ], authenticateToken, authorizeRoles('admin', 'receptionist', 'manager'), asyncHandler(bookingController.cancelBooking));

// // Get today's check-ins
// router.get('/today/checkins', authenticateToken, asyncHandler(bookingController.getTodayCheckIns));

// // Get today's check-outs
// router.get('/today/checkouts', authenticateToken, asyncHandler(bookingController.getTodayCheckOuts));

// module.exports = router;

const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { bookingValidations, commonValidations } = require('../middleware/validation');
const { asyncHandler } = require('../middleware/errorHandler');
const bookingController = require('../controllers/bookingcontroller');

const router = express.Router();

// --- NEW/UPDATED ROUTES ---

// 1. Create New Pre-Booking (Staff or Customer can initiate)
router.post('/prebooking', [
  body('capacity').isInt({ min: 1 }).withMessage('Capacity must be at least 1.'),
  body('prebooking_method').isIn(['Online', 'Phone', 'Walk-in']).withMessage('Invalid pre-booking method.'),
  body('expected_check_in').isDate().withMessage('Valid check-in date is required.'),
  body('expected_check_out').isDate().withMessage('Valid check-out date is required.'),
  body('room_id').optional().isInt({ min: 1 }).withMessage('Room ID must be an integer.'),
  body('guest_id').optional().isInt().withMessage('Valid Guest ID must be an integer.'),
  body('employee_id').optional().isInt().withMessage('Valid Employee ID must be an integer.'),
  body('created_by_employee_id').optional().isInt({ min: 1 }).withMessage('Created By Employee ID must be an integer.')
], 
authenticateToken, // Authenticate token (all logged-in users)
asyncHandler(bookingController.createPreBooking)); 

router.post('/booking/cancel', [
  body('booking_id').isInt({ min: 1 }).withMessage('Pre-Booking ID must be an integer.')
], 
authenticateToken, // Authenticate token (all logged-in users)
asyncHandler(bookingController.cancelcreatedBooking)); 

// 2. Create New Confirmed Booking
// router.post('/booking/confirmed', [
//   // Assumes bookingValidations.create includes required fields like room_id, dates, advance_payment, etc.
//   ...bookingValidations.create
// ], 
// authenticateToken, authorizeRoles(['Admin', 'Receptionist', 'Manager']), // Staff authorization
// asyncHandler(bookingController.createBooking));
router.post('/confirmed', [
  // Validation for critical booking fields:
  body('room_id').isInt({ min: 1 }).withMessage('Room ID is required.'),
  body('check_in_date').isDate().withMessage('Valid check-in date is required.'),
  body('check_out_date').isDate().withMessage('Valid check-out date is required.'),
  //body('role').isIn(['Admin', 'Receptionist', 'Manager'/*, 'Customer'*/]).withMessage('Invalid role'),
  body('booked_rate').isFloat({ min: 1.0 }).withMessage('Daily rate is required.'),
  body('guest_id').optional().isInt().withMessage('Valid Guest ID must be an integer.'),
  body('advance_payment').isFloat({ min: 0.0 }).withMessage('Advance payment is required.'),
  body('preferred_payment_method').isIn(['Cash', 'Card', 'Online', 'BankTransfer']).withMessage('Invalid payment method.'),
  body('pre_booking_id').optional().isInt().withMessage('Pre-Booking ID must be an integer.')
], 
authenticateToken, /*authorizeRoles('Admin', 'Receptionist', 'Manager'), */// Staff authorization
asyncHandler(bookingController.createBooking));


// --- EXISTING ROUTES (Finalized) ---

// Get all bookings
// router.get('/all', [
//   query('status').optional().isIn(['Booked', 'Checked-In', 'Checked-Out', 'Cancelled']), 
//   query('check_in_start').optional().isDate(),
//   query('check_in_end').optional().isDate(),
//   query('check_out_start').optional().isDate(),
//   query('check_out_end').optional().isDate(),
//   query('guest_name').optional().trim(),
//   query('room_number').optional().trim(),
//   query('page').optional().isInt({ min: 1 }),
//   query('limit').optional().isInt({ min: 1, max: 100 })
// ], authenticateToken, asyncHandler(bookingController.getAllBookings));


router.get('/prebkooking/all', [
    query('status').optional().isIn(['Booked', 'Checked-In', 'Checked-Out', 'Cancelled']), 
    query('check_in_start').optional().isDate(),
    query('check_in_end').optional().isDate(),
    query('check_out_start').optional().isDate(),
    query('check_out_end').optional().isDate(),
    query('guest_name').optional().trim(),
    query('room_number').optional().trim(),
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 })
], authenticateToken, bookingController.getAllPrebookings);

router.get('/booking/all', [
    // Statuses must match the 'booking_status' ENUM: 'Booked', 'Checked-In', 'Checked-Out', 'Cancelled'
    query('status').optional().isIn(['Booked', 'Checked-In', 'Checked-Out', 'Cancelled']).withMessage('Invalid confirmed booking status.'), 
    query('check_in_start').optional().isDate().withMessage('Check-in start must be a valid date.'),
    query('check_in_end').optional().isDate().withMessage('Check-in end must be a valid date.'),
    query('check_out_start').optional().isDate().withMessage('Check-out start must be a valid date.'),
    query('check_out_end').optional().isDate().withMessage('Check-out end must be a valid date.'),
    query('guest_name').optional().trim(),
    query('room_number').optional().trim(),
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer.'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100.')
], authenticateToken, bookingController.getAllBookings);

// Get booking by ID
router.get('/:id', [
  commonValidations.id
], authenticateToken, asyncHandler(bookingController.getBookingDetails)); 

// Check-in guest
router.post('/:id/checkin', [
  commonValidations.id
], authenticateToken, authorizeRoles(['Admin', 'Receptionist','Manager','Accountant']), asyncHandler(bookingController.checkIn));

// Check-out guest
router.post('/:id/checkout', [
  commonValidations.id
], authenticateToken, authorizeRoles(['Admin', 'Receptionist','Manager','Accountant']), asyncHandler(bookingController.checkOut));

// Cancel booking
router.post('/:id/cancel', [
  commonValidations.id,
  body('reason').optional().trim()
], authenticateToken, authorizeRoles(['Admin', 'Receptionist', 'Manager']), asyncHandler(bookingController.cancelBooking));

// Get today's check-ins
router.get('/today/checkins', authenticateToken, authorizeRoles(['Admin', 'Receptionist']), asyncHandler(bookingController.getTodayCheckIns));

// Get today's check-outs
router.get('/today/checkouts', authenticateToken, authorizeRoles(['Admin', 'Receptionist']), asyncHandler(bookingController.getTodayCheckOuts));

module.exports = router;