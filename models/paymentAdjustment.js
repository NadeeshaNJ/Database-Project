const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;
const { ADJUSTMENT_TYPE } = require('../utils/enums');

const PaymentAdjustment = sequelize.define('PaymentAdjustment', {
  adjustment_id: {
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
  type: {
    type: DataTypes.ENUM(...Object.values(ADJUSTMENT_TYPE)),
    allowNull: false
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false
  },
  reference_note: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'payment_adjustments',
  timestamps: true
});

module.exports = PaymentAdjustment;
