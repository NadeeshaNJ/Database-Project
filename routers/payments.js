const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { paymentValidations, commonValidations } = require('../middleware/validation');
const { asyncHandler } = require('../middleware/errorHandler');
const paymentController = require('../controllers/paymentcontroller');

const router = express.Router();

// Get all payments
router.get('/', [
  query('payment_status').optional().isIn(['pending', 'completed', 'failed', 'refunded']),
  query('payment_method').optional().isIn(['credit_card', 'debit_card', 'cash', 'online', 'bank_transfer']),
  query('start_date').optional().isDate(),
  query('end_date').optional().isDate(),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 })
], authenticateToken, authorizeRoles('admin', 'manager'), asyncHandler(paymentController.getAllPayments));

// Get payment by ID
router.get('/:id', [
  commonValidations.id
], authenticateToken, asyncHandler(paymentController.getPaymentById));

// Create new payment
router.post('/', [
  ...paymentValidations.create
], authenticateToken, authorizeRoles('admin', 'receptionist'), asyncHandler(paymentController.createPayment));

// Update payment status
router.patch('/:id/status', [
  commonValidations.id,
  body('payment_status').isIn(['pending', 'completed', 'failed', 'refunded']).withMessage('Invalid payment status'),
  body('transaction_id').optional().trim()
], authenticateToken, authorizeRoles('admin', 'receptionist'), asyncHandler(paymentController.updatePaymentStatus));

// Process refund
router.post('/:id/refund', [
  commonValidations.id,
  body('refund_amount').isFloat({ min: 0 }).withMessage('Valid refund amount is required'),
  body('refund_reason').optional().trim()
], authenticateToken, authorizeRoles('admin', 'manager'), asyncHandler(paymentController.processRefund));

module.exports = router;