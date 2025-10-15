const app = require('./app');
const { testConnection, syncDatabase } = require('./models');
require('dotenv').config();
const { User } = require('./models');

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // Test database connection
    await testConnection();
    
    // Sync database models
    //await syncDatabase(process.env.NODE_ENV === 'development');
    const forceSync = process.env.NODE_ENV === 'development' && process.env.FORCE_SYNC === 'true';
    await syncDatabase(forceSync);

    // Start server
    app.listen(PORT, () => {
      console.log(`
🚀 Hotel Management System Backend is running!
📍 Port: ${PORT}
🌍 Environment: ${process.env.NODE_ENV || 'development'}
📊 Database: ${process.env.DB_NAME|| 'development'}
🕒 Time: ${new Date().toLocaleString()}
      `);
    });
    //checkDatabase();
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// const checkDatabase = async () => {//This is just to check db connection and user table
//   try {
//     const users = await User.findAll();
//     console.log('📋 Users in database:', users.map(u => ({
//       id: u.user_id,
//       username: u.username,
//       password: u.password_hash
//     })));
//   } catch (error) {
//     console.error('❌ Database check failed:', error);
//   }
// };

// when we terminate connection it hadle rest like closing db connections
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down server gracefully...');
  process.exit(0);
});

//when cant handle error in promises it will handle here
process.on('unhandledRejection', (err) => {
  console.error('Unhandled Promise Rejection:', err);
  process.exit(1);
});

startServer();
