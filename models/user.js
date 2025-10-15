// const { DataTypes } = require('sequelize');
// const sequelize = require('../config/database').sequelize;
// const bcrypt = require('bcryptjs');

// const User = sequelize.define('User', {
//   user_id: { 
//     type: DataTypes.INTEGER,
//     primaryKey: true,
//     autoIncrement: true
//   },
//   username: {
//     type: DataTypes.STRING(50),
//     unique: true,
//     allowNull: false,
//     validate: { notEmpty: true }
//   },
//   password_hash: { // Corrected column name from previous steps
//     type: DataTypes.STRING(255),
//     allowNull: false,
//     field: 'password_hash'
//   },
//   role: {
//     type: DataTypes.ENUM('admin', 'receptionist', 'manager', 'customer'),
//     defaultValue: 'receptionist',
//     validate: { isIn: [['admin', 'receptionist', 'manager', 'customer']] }
//   },
//   // CRITICAL FIX 1: Remove the incorrect 'is_active' column.
//   // CRITICAL FIX 2: Add 'guest_id' to map to the 'guest' table.
//   guest_id: { 
//     type: DataTypes.INTEGER,
//     allowNull: true, // Null for employees/admins, not null for customers
//     references: {
//         model: 'guest', // The model name or table name
//         key: 'guest_id'
//     }
//   }
// }, {
//   tableName: 'user_account', 
//   schema: 'public', // FIX from previous step
//   timestamps: true,
//   underscored: true,
//   freezeTableName: true,
//   // createdAt: 'created_at',
//   // updatedAt: 'updated_at',
//   hooks: {
//     beforeCreate: async (user) => {
//       if (user.password_hash) {
//         user.password_hash = await bcrypt.hash(user.password_hash, 12);
//       }
//     },
//     beforeUpdate: async (user) => {
//       if (user.changed('password_hash')) {
//         user.password_hash = await bcrypt.hash(user.password_hash, 12);
//       }
//     }
//   }
// });

// // Instance method to check password
// User.prototype.validatePassword = async function(password) {
//   return await bcrypt.compare(password, this.password_hash);
// };

// // No longer relying on is_active in the model.
// // User.findActive = function() { return this.findAll({ where: { is_active: true } }); };

// module.exports = User;

const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;
const bcrypt = require('bcryptjs');

const User = sequelize.define('User', {
  user_id: { 
    type: DataTypes.BIGINT, // Matches bigserial
    primaryKey: true,
    autoIncrement: true
  },
  username: {
    type: DataTypes.STRING(60), // Matches schema length
    unique: true,
    allowNull: false,
    validate: { notEmpty: true }
  },
  // The 'email' field is NOT in the public.user_account table (it's in guest/employee) and is removed.
  
  password_hash: {
    type: DataTypes.STRING(100), // Matches schema length
    allowNull: false,
    // Removed redundant `field: 'password_hash'`
  },
  role: {
    // CRITICAL FIX: Use the full ENUM list defined in your public.user_role type
    type: DataTypes.ENUM('Admin', 'Manager', 'Receptionist', 'Accountant', 'Customer'),
    allowNull: false
  },
  guest_id: { 
    type: DataTypes.BIGINT, // Matches bigint
    allowNull: true, // Can be null for Employees/Admins
    references: {
        model: 'guest',
        key: 'guest_id'
    }
  }
}, {
  tableName: 'user_account', 
  schema: 'public',
  // CRITICAL FIX: Must be false as these columns are not in the DB schema
  timestamps: false, 
  underscored: true,
  freezeTableName: true,
  hooks: {
    beforeCreate: async (user) => {
      // Logic relies on the user object having the 'password_hash' property
      if (user.password_hash) {
        user.password_hash = await bcrypt.hash(user.password_hash, 12);
      }
    },
    beforeUpdate: async (user) => {
      if (user.changed('password_hash')) {
        user.password_hash = await bcrypt.hash(user.password_hash, 12);
      }
    }
  }
});

// Instance method to check password
User.prototype.validatePassword = async function(password) {
  return await bcrypt.compare(password, this.password_hash);
};

module.exports = User;