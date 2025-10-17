// server.js
require('dotenv').config();   // load .env variables
const app = require('./app');
const { sequelize } = require('./models'); // adjust path if needed

const PORT = process.env.PORT || 5000;

(async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');
    
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('❌ Unable to connect to PostgreSQL database:', error);
  }
})();
