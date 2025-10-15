const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { paymentValidations, commonValidations } = require('../middleware/validation');
const { asyncHandler } = require('../middleware/errorHandler');
const paymentController = require('../controllers/paymentcontroller');

const router = express.Router();

// Get all payments
// router.get('/', [
//   query('payment_status').optional().isIn('pending', 'completed', 'failed', 'refunded'),
//   query('payment_method').optional().isIn('credit_card', 'debit_card', 'cash', 'online', 'bank_transfer'),
//   query('start_date').optional().isDate(),
//   query('end_date').optional().isDate(),
//   query('page').optional().isInt({ min: 1 }),
//   query('limit').optional().isInt({ min: 1, max: 100 })
// ], authenticateToken, authorizeRoles('Admin', 'Manager','Receptionist','Accountant'), asyncHandler(paymentController.getAllPayments));

// In paymentrouter.js

router.get('/all', [
  // FIX 1: Remove 'payment_status' (payment table doesn't show one; use 'payment_reference' or remove status filter)
  // FIX 2: Ensure payment_method matches your ENUM (Cash, Card, Online, BankTransfer)
  query('payment_method').optional().isIn(['Cash', 'Card', 'Online', 'BankTransfer']),
  query('start_date').optional().isDate(),
  query('end_date').optional().isDate(),
  // FIX 3: Add booking_id to the query validation list
  query('booking_id').optional().isInt({ min: 1 }),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 })
], authenticateToken, authorizeRoles('Admin', 'Manager', 'Receptionist', 'Accountant'), asyncHandler(paymentController.getAllPayments));

// Get payment by ID
router.get('/:id', [
  commonValidations.id
], authenticateToken, asyncHandler(paymentController.getPaymentById));

// Create new payment
// router.post('/pay', [
//   ...paymentValidations.create
// ], authenticateToken, authorizeRoles('Admin', 'Manager','Receptionist','Accountant'), asyncHandler(paymentController.createPayment));

router.post('/pay', [
    // --- Basic Request Body Validation ---
    body('booking_id').isInt({ min: 1 }).withMessage('A valid Booking ID is required.'),
    body('amount').isFloat({ gt: 0 }).withMessage('Payment amount must be a positive number.'),
    body('method').isIn('Cash', 'Card', 'Online', 'BankTransfer').withMessage('Invalid payment method.'),
    body('payment_reference').optional().isString().trim().isLength({ max: 100 }).withMessage('Reference cannot exceed 100 characters.'),

    // You would include your paymentValidations.create here if they are separate/more complex:
    // ...paymentValidations.create, 
], 
authenticateToken, 
authorizeRoles('Admin', 'Manager', 'Receptionist', 'Accountant'), 
asyncHandler(paymentController.createPayment));


// // Update payment status
// router.patch('/:id/status', [
//   commonValidations.id,
//   body('payment_status').isIn(['pending', 'completed', 'failed', 'refunded']).withMessage('Invalid payment status'),
//   body('transaction_id').optional().trim()
// ], authenticateToken, authorizeRoles('admin', 'receptionist'), asyncHandler(paymentController.updatePaymentStatus));

// Process refund
router.post('/:id/refund', [
  commonValidations.id,
  body('refund_amount').isFloat({ min: 0 }).withMessage('Valid refund amount is required'),
  body('refund_reason').optional().trim()
], authenticateToken, authorizeRoles('Admin', 'Manager'), asyncHandler(paymentController.processRefund));

// In your paymentrouter.js:
router.get('/booking/:id', [
  commonValidations.id
], authenticateToken, asyncHandler(paymentController.getPaymentsByBookingId));

module.exports = router;