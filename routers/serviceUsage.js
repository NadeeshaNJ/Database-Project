const express = require('express');
const { query } = require('express-validator');
const { asyncHandler } = require('../middleware/errorHandler');
const serviceUsageController = require('../controllers/serviceUsageControllerNew');
const { optionalAuth } = require('../middleware/auth');

const router = express.Router();

// Get all service usages with filters
router.get('/', [
    query('booking_id').optional().isInt({ min: 1 }),
    query('service_id').optional().isInt({ min: 1 }),
    query('guest_name').optional().trim(),
    query('start_date').optional().isDate(),
    query('end_date').optional().isDate(),
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 1000 })
], optionalAuth, asyncHandler(serviceUsageController.getAllServiceUsages));

// Get service usages by booking ID
router.get('/booking/:bookingId', optionalAuth, asyncHandler(serviceUsageController.getServiceUsagesByBooking));

module.exports = router;