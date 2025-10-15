const jwt = require('jsonwebtoken');
const { User } = require('../models');

/**
 * Ensures the request has a valid, unexpired token and attaches the decoded
 * user data (including userId, role, and guestId) to req.user.
 */
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({ 
        success: false,
        error: 'Access token required' 
      });
    }

    // 1. Verify and Decode the token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // 2. Attach the DECODED JWT payload to req.user
    // This payload already contains userId, role, and guestId (if present in the token).
    // This allows controllers to access req.user.guestId, req.user.userId, etc., without
    // needing another complex database query here.
    req.user = decoded; 
    
    // Optional Security Check: Verify user still exists in the database
    // We only select essential, existing columns (user_id, username)
    const user = await User.findByPk(decoded.userId, {
      attributes: ['user_id', 'username']
    });

    if (!user) {
      return res.status(401).json({ 
        success: false,
        error: 'Invalid token or user not found in database'
      });
    }

    // Since the database does not have an 'is_active' column, we remove that faulty check entirely.
    
    next();
  } catch (error) {
    // This catches JWT errors (expired, tampered, invalid signature)
    // The previous error of 'user inactive' is now resolved.
    return res.status(403).json({ 
      success: false,
      error: 'Invalid or expired token' 
    });
  }
};

/**
 * Authorizes the user based on their role included in the JWT payload.
 */
// In middleware/auth.js

// const authorizeRoles = (...roles) => {
//   return (req, res, next) => {
    
//     // 1. Check 1: Ensure the user object is attached and has a role property.
//     // We must return a clear error if the role is truly missing from the token.
//     if (!req.user || req.user.role === undefined || req.user.role === null) {
//         return res.status(403).json({ 
//             success: false,
//             error: 'Access denied. User role not defined in token.' // More specific message
//         });
//     }

//     // 2. Perform Case-Insensitive Comparison
//     // Ensure the role is treated as a string before calling toLowerCase().
//     const userRole = String(req.user.role).toLowerCase(); 
//     const allowedRoles = roles.map(role => String(role).toLowerCase()); // Also convert allowed roles to strings

//     if (!allowedRoles.includes(userRole)) { 
//       return res.status(403).json({ 
//         success: false,
//         error: 'Access denied. Insufficient permissions.' 
//       });
//     }

//     next();
//   };
// };

const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    // 1. Ensure req.user and req.user.role exist
    if (!req.user || !req.user.role) {
      return res.status(403).json({
        success: false,
        error: 'Access denied. User role not defined in token.'
      });
    }

    // 2. Normalize user role: trim spaces and lowercase
    const userRole = String(req.user.role).trim().toLowerCase();

    // 3. Normalize allowed roles
    const allowedRoles = roles.map(role => String(role).trim().toLowerCase());

    // 4. Debug: log roles (remove or comment out in production)
    console.log(`DEBUG: userRole="${userRole}", allowedRoles=[${allowedRoles.join(', ')}]`);

    // 5. Check if the user's role exists in allowedRoles
    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({
        success: false,
        error: `Access denied. User role "${req.user.role}" insufficient.`
      });
    }

    next();
  };
};

module.exports = { authorizeRoles };




/**
 * Optionally authenticates a token if one is present, but allows the request to continue if not.
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // Optionally verify user existence again, but primarily attach the payload data
      const user = await User.findByPk(decoded.userId, {
        attributes: ['user_id', 'username']
      });

      if (user) {
        req.user = decoded;
      }
    }
    next();
  } catch (error) {
    // Do not throw an error if token is invalid/expired; just proceed without req.user
    next();
  }
};

module.exports = { 
  authenticateToken, 
  authorizeRoles, 
  optionalAuth 
};