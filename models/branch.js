const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;

const Branch = sequelize.define('Branch', {
  branch_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  branch_name: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true
  },
  contact_number: {
    type: DataTypes.STRING(20),
    allowNull: false
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: false
  }
}, {
  tableName: 'branches',
  timestamps: true
});

module.exports = Branch;
