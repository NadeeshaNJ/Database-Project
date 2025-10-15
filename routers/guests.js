const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { guestValidations, commonValidations } = require('../middleware/validation');
const { asyncHandler } = require('../middleware/errorHandler');
const guestController = require('../controllers/guestController');

const router = express.Router();

// Get all guests
router.get('/all', [
  query('search').optional().trim(),
  query('country').optional().trim(),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('sort_by').optional().isIn('first_name', 'last_name', 'email', 'created_at'),
  query('order').optional().isIn(['asc', 'desc'])
], authenticateToken, asyncHandler(guestController.getAllGuests));

router.get('/search', [
  query('query').notEmpty().trim().withMessage('Search query string is required.'),
  query('field').optional().isIn('all', 'name', 'nic', 'email', 'phone').withMessage('Invalid search field.')
], authenticateToken, authorizeRoles('Admin', 'Manager', 'Receptionist', 'Accountant'), asyncHandler(guestController.searchGuests));


// Get guest by ID
router.get('/:id', [
  commonValidations.id
], authenticateToken, asyncHandler(guestController.getGuestById));

// Create new guest
router.post('/createnew', [
  // Validation checks matching the PostgreSQL 'guest' table schema:
  body('full_name').notEmpty().withMessage('Full Name is required.').trim().isLength({ max: 120 }).withMessage('Full Name exceeds max length (120).'), 
  body('nic').optional().isString().trim().isLength({ max: 30 }).withMessage('NIC/ID must be a string up to 30 characters.'),
  body('email').optional().isEmail().withMessage('Invalid email format.').isLength({ max: 150 }).withMessage('Email exceeds max length (150).'),
  body('phone').optional().isString().trim().isLength({ max: 30 }).withMessage('Phone number exceeds max length (30).'),
  body('gender').optional().isString().trim().isLength({ max: 20 }).withMessage('Gender exceeds max length (20).'),
  body('date_of_birth').optional().isDate().withMessage('Date of Birth must be a valid date (YYYY-MM-DD).'), 
  body('address').optional().trim(),
  body('nationality').optional().isString().trim().isLength({ max: 80 }).withMessage('Nationality exceeds max length (80).'),
], authenticateToken, authorizeRoles('Admin', 'Receptionist', 'Manager'), asyncHandler(guestController.createGuest));


// Delete guest
router.delete('/delete/:id', [
  commonValidations.id
], authenticateToken, authorizeRoles('Admin'), asyncHandler(guestController.deleteGuest));

// Get guest booking history
router.get('/:id/bookings', [
  commonValidations.id
], authenticateToken, asyncHandler(guestController.getGuestBookings));

router.get('/:id/statistics', [
  commonValidations.id
], authenticateToken, authorizeRoles('Admin', 'Manager', 'Receptionist', 'Accountant'), asyncHandler(guestController.getGuestStatistics));

router.get('/statistics/nationality', authenticateToken, authorizeRoles('Admin', 'Manager', 'Accountant'), asyncHandler(guestController.getGuestsByNationality));

module.exports = router;