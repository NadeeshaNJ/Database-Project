const express = require('express');
const { query } = require('express-validator');
const { asyncHandler } = require('../middleware/errorHandler');
const serviceCatalogController = require('../controllers/serviceCatalogController');
const { optionalAuth } = require('../middleware/auth');

const router = express.Router();

// Get all services
router.get('/', [
    query('category').optional().trim(),
    query('active').optional().isBoolean(),
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 1000 })
], optionalAuth, asyncHandler(serviceCatalogController.getAllServices));

// Get service by ID
router.get('/:id', optionalAuth, asyncHandler(serviceCatalogController.getServiceById));

module.exports = router;
