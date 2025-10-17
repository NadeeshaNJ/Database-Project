const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;

const RoomType = sequelize.define('RoomType', {
  room_type_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true
  },
  capacity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: {
      min: 1
    }
  },
  daily_rate: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    validate: {
      min: 0
    }
  }
}, {
  tableName: 'room_type',
  schema: 'public',
  timestamps: false,
  underscored: true,
  freezeTableName: true
});

module.exports = RoomType;
