// const express = require('express');
// const router = express.Router();
// const { authenticateToken } = require('../middleware/auth');
// const { authorize } = require('../middleware/authorize'); // ❌ INCORRECT IMPORT NAME AND FILE

// We assume authorizeRoles is available, likely exported from '../middleware/auth.js'
// Let's modify the imports to reflect the correct function name:

const express = require('express');
const router = express.Router();
// FIX: Import the correct authorization function (authorizeRoles)
const { authenticateToken, authorizeRoles } = require('../middleware/auth'); 
// Ensure your auth.js exports authorizeRoles

const {
    getAllServiceUsages,
    getServiceUsagesByBooking,
    createServiceUsage,
    deleteMostRecentServiceUsage,
    getServiceUsageSummary
} = require('../controllers/serviceUsageController');


// --- Routes (Using the correct authorizeRoles function) ---

// Get all service usages with filters
router.get('/all', 
    authenticateToken, 
    // FIX: Use the correct function name
    authorizeRoles('Admin', 'Manager', 'Receptionist', 'Accountant'), 
    getAllServiceUsages
);

// Get service usage summary (for reports)
router.get('/summary', 
    authenticateToken, 
    // FIX: Use the correct function name
    authorizeRoles('Admin', 'Manager', 'Accountant'),
    getServiceUsageSummary
);

// Get service usages by booking ID
router.get('/booking/:bookingId', 
    authenticateToken, 
    // FIX: Use the correct function name
    authorizeRoles('Admin', 'Manager', 'Receptionist', 'Accountant'),
    getServiceUsagesByBooking
);



// Create new service usage
router.post('/newservicerequest', 
    authenticateToken, 
    // FIX: Use the correct function name
    authorizeRoles('Manager','Receptionist','Admin'),
    createServiceUsage
);



// Delete service usage
router.delete('/delete/:id/service/:serviceId', 
    authenticateToken, 
    // FIX: Use the correct function name (assuming deleteMostRecentServiceUsage is the name)
    authorizeRoles('Admin', 'Manager'),
    deleteMostRecentServiceUsage
);

module.exports = router;