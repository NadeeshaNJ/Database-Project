const { sequelize } = require('../models');

// Global test setup
beforeAll(async () => {
  // Sync test database
  await sequelize.sync({ force: true });
});

afterAll(async () => {
  // Close database connection
  await sequelize.close();
});

// Global test timeout
jest.setTimeout(30000);