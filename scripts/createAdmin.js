// Script to create an admin user directly using Sequelize models
require('dotenv').config();
const { User, sequelize } = require('../models');

const username = process.env.ADMIN_USERNAME || 'superadmin';
const email = process.env.ADMIN_EMAIL || 'admin@skynest.local';
const password = process.env.ADMIN_PASSWORD || 'AdminPass123!';
const role = process.env.ADMIN_ROLE || 'Admin';

const run = async () => {
  try {
    await sequelize.authenticate();
    console.log('DB connected');

    const [user, created] = await User.findOrCreate({
      where: { username },
      defaults: {
        username,
        // Model expects password_hash property; hooks will hash this value beforeCreate
        password_hash: password,
        role,
        guest_id: null
      }
    });

    if (created) {
      console.log(`Created admin user: ${username}`);
    } else {
      console.log(`Admin user already exists: ${username}`);
    }

    console.log('User id:', user.user_id || user.id || '<unknown>');
    process.exit(0);
  } catch (err) {
    console.error('Error creating admin user:', err);
    process.exit(1);
  }
};

run();
