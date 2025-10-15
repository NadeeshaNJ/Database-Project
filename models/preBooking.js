const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;
const { PREBOOKING_METHOD } = require('../utils/enums');

const PreBooking = sequelize.define('PreBooking', {
  pre_booking_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  guest_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'guests',
      key: 'guest_id'
    }
  },
  room_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'rooms',
      key: 'room_id'
    }
  },
  capacity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: {
      min: 1
    }
  },
  prebooking_method: {
    type: DataTypes.ENUM(...Object.values(PREBOOKING_METHOD)),
    allowNull: false
  },
  expected_check_in: {
    type: DataTypes.DATE,
    allowNull: false
  },
  expected_check_out: {
    type: DataTypes.DATE,
    allowNull: false,
    validate: {
      isAfterCheckIn(value) {
        if (value <= this.expected_check_in) {
          throw new Error('Expected check-out must be after expected check-in');
        }
      }
    }
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'pre_bookings',
  timestamps: true
});

module.exports = PreBooking;
