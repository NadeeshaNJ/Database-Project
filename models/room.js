const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;
const { ROOM_STATUS } = require('../utils/enums');

const Room = sequelize.define('Room', {
  room_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  room_type_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'room_types',
      key: 'room_type_id'
    }
  },
  room_number: {
    type: DataTypes.STRING(10),
    unique: true,
    allowNull: false,
    validate: {
      notEmpty: true
    }
  },
  status: {
    type: DataTypes.ENUM(...Object.values(ROOM_STATUS)),
    allowNull: false,
    defaultValue: ROOM_STATUS.AVAILABLE
  }
}, {
  tableName: 'room',
  schema: 'public',
  timestamps: false,
  underscored: true,
  freezeTableName: true
});

module.exports = Room;