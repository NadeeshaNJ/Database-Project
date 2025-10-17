const express = require('express');
const { query } = require('express-validator');
const { asyncHandler } = require('../middleware/errorHandler');
const reportsController = require('../controllers/reportsController');
const { optionalAuth } = require('../middleware/auth');

const router = express.Router();

// Get revenue report
router.get('/revenue', [
    query('start_date').optional().isDate(),
    query('end_date').optional().isDate(),
    query('branch_id').optional().isInt({ min: 1 }),
    query('group_by').optional().isIn(['day', 'week', 'month'])
], optionalAuth, asyncHandler(reportsController.getRevenueReport));

// Get occupancy report
router.get('/occupancy', [
    query('start_date').optional().isDate(),
    query('end_date').optional().isDate(),
    query('branch_id').optional().isInt({ min: 1 })
], optionalAuth, asyncHandler(reportsController.getOccupancyReport));

// Get service usage report
router.get('/service-usage', [
    query('start_date').optional().isDate(),
    query('end_date').optional().isDate(),
    query('branch_id').optional().isInt({ min: 1 })
], optionalAuth, asyncHandler(reportsController.getServiceUsageReport));

// Get payment method report
router.get('/payment-methods', [
    query('start_date').optional().isDate(),
    query('end_date').optional().isDate(),
    query('branch_id').optional().isInt({ min: 1 })
], optionalAuth, asyncHandler(reportsController.getPaymentMethodReport));

// Get guest statistics
router.get('/guest-statistics', [
    query('start_date').optional().isDate(),
    query('end_date').optional().isDate()
], optionalAuth, asyncHandler(reportsController.getGuestStatistics));

// Get dashboard summary
router.get('/dashboard-summary', [
    query('branch_id').optional().isInt({ min: 1 })
], optionalAuth, asyncHandler(reportsController.getDashboardSummary));

module.exports = router;
