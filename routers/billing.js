const express = require('express');
const { query, param } = require('express-validator');
const { asyncHandler } = require('../middleware/errorHandler');
const billingController = require('../controllers/billingController');
const { optionalAuth } = require('../middleware/auth');

const router = express.Router();

// Get all payments
router.get('/payments', [
    query('booking_id').optional().isInt({ min: 1 }),
    query('method').optional().isIn(['Card', 'Cash', 'Online', 'BankTransfer']),
    query('start_date').optional().isDate(),
    query('end_date').optional().isDate(),
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 1000 })
], optionalAuth, asyncHandler(billingController.getAllPayments));

// Get payments by booking ID
router.get('/payments/booking/:bookingId', [
    param('bookingId').isInt({ min: 1 })
], optionalAuth, asyncHandler(billingController.getPaymentsByBooking));

// Get payment adjustments
router.get('/adjustments', [
    query('booking_id').optional().isInt({ min: 1 }),
    query('type').optional().isIn(['refund', 'manual_adjustment']),
    query('start_date').optional().isDate(),
    query('end_date').optional().isDate(),
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 1000 })
], optionalAuth, asyncHandler(billingController.getPaymentAdjustments));

// Get billing summary for a booking
router.get('/summary/:bookingId', [
    param('bookingId').isInt({ min: 1 })
], optionalAuth, asyncHandler(billingController.getBookingBillingSummary));

module.exports = router;
