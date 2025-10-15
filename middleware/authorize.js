// // In middleware/authorize.js (Populate this file)

// // The actual authorization logic is usually in auth.js, but for simplicity, 
// // let's assume it's imported here:
// const { authorizeRoles } = require('./auth'); // Assuming auth.js contains authorizeRoles

// // Export authorizeRoles under the name 'authorize' to satisfy the router import
// module.exports = {
//     authorize: authorizeRoles 
// };