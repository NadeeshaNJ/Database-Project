const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { guestValidations, commonValidations } = require('../middleware/validation');
const { asyncHandler } = require('../middleware/errorHandler');
const guestController = require('../controllers/guestController');

const router = express.Router();

// Get all guests
router.get('/', [
  query('search').optional().trim(),
  query('country').optional().trim(),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('sort_by').optional().isIn(['first_name', 'last_name', 'email', 'created_at']),
  query('order').optional().isIn(['asc', 'desc'])
], authenticateToken, asyncHandler(guestController.getAllGuests));

// Get guest by ID
router.get('/:id', [
  commonValidations.id
], authenticateToken, asyncHandler(guestController.getGuestById));

// Create new guest
router.post('/', [
  ...guestValidations.create
], authenticateToken, authorizeRoles('admin', 'receptionist', 'manager'), asyncHandler(guestController.createGuest));

// Update guest
router.put('/:id', [
  commonValidations.id,
  body('first_name').optional().trim().isLength({ min: 2 }),
  body('last_name').optional().trim().isLength({ min: 2 }),
  body('email').optional().isEmail(),
  body('phone').optional().matches(/^[\+]?[1-9][\d]{0,15}$/),
  body('date_of_birth').optional().isDate()
], authenticateToken, authorizeRoles('admin', 'receptionist', 'manager'), asyncHandler(guestController.updateGuest));

// Delete guest
router.delete('/:id', [
  commonValidations.id
], authenticateToken, authorizeRoles('admin'), asyncHandler(guestController.deleteGuest));

// Get guest booking history
router.get('/:id/bookings', [
  commonValidations.id
], authenticateToken, asyncHandler(guestController.getGuestBookings));

module.exports = router;