const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;
const { PAYMENT_METHOD } = require('../utils/enums');

const Payment = sequelize.define('Payment', {
  payment_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  booking_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'bookings',
      key: 'booking_id'
    }
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    validate: {
      min: 0
    }
  },
  method: {
    type: DataTypes.ENUM(...Object.values(PAYMENT_METHOD)),
    allowNull: false
  },
  paid_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  },
  payment_reference: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  advance_payment: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  tax_rate_percent: {
    type: DataTypes.DECIMAL(5, 2),
    allowNull: false,
    defaultValue: 0
  }
}, {
  tableName: 'payments',
  timestamps: true
});

module.exports = Payment;