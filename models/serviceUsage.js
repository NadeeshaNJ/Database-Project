const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;

const ServiceUsage = sequelize.define('ServiceUsage', {
  service_usage_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  booking_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'booking',
      key: 'booking_id'
    }
  },
  service_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'service',
      key: 'service_id'
    }
  },
  quantity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1
  },
  total_price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false
  },
  used_on: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'service_usage',
  timestamps: false,
  underscored: true
});

module.exports = ServiceUsage;
