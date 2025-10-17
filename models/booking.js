const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;
const { BOOKING_STATUS } = require('../utils/enums');

const Booking = sequelize.define('Booking', {
  booking_id: {
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
  pre_booking_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'pre_bookings',
      key: 'pre_booking_id'
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
  check_in_date: {
    type: DataTypes.DATE,
    allowNull: false
  },
  check_out_date: {
    type: DataTypes.DATE,
    allowNull: false,
    validate: {
      isAfterCheckIn(value) {
        if (value <= this.check_in_date) {
          throw new Error('Check-out date must be after check-in date');
        }
      }
    }
  },
  status: {
    type: DataTypes.ENUM(...Object.values(BOOKING_STATUS)),
    allowNull: false,
    defaultValue: BOOKING_STATUS.BOOKED
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'booking',
  schema: 'public',
  timestamps: false,
  underscored: true,
  freezeTableName: true
});

module.exports = Booking;