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
      model: 'bookings',
      key: 'booking_id'
    }
  },
  service_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'services',
      key: 'service_id'
    }
  },
  used_on: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'service_usages',
  timestamps: true
});

module.exports = ServiceUsage;
