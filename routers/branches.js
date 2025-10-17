const express = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const branchController = require('../controllers/branchController');

const router = express.Router();

// Get all branches
router.get('/', asyncHandler(branchController.getAllBranches));

// Get branch by ID
router.get('/:id', asyncHandler(branchController.getBranchById));

module.exports = router;
