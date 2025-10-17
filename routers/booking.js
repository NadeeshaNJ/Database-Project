const express = require('express');
const { query } = require('express-validator');
const { asyncHandler } = require('../middleware/errorHandler');
const bookingController = require('../controllers/bookingcontroller');
const { optionalAuth } = require('../middleware/auth');

const router = express.Router();

// Get all bookings - simple route for frontend
router.get('/', [
    query('status').optional().isIn(['Booked', 'Checked-In', 'Checked-Out', 'Cancelled']),
    query('check_in_start').optional().isDate(),
    query('check_in_end').optional().isDate(),
    query('guest_name').optional().trim(),
    query('room_number').optional().trim(),
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 1000 })
], optionalAuth, asyncHandler(bookingController.getAllBookings));

module.exports = router;