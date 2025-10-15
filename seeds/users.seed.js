const { User } = require('../models');
const { hashPassword } = require('../utils/helpers');

const seedUsers = async () => {
  try {
    console.log('👥 Seeding users...');
    
    const users = [
      {
        username: 'admin',
        email: 'admin@hotel.com',
        password: await hashPassword('admin123'),
        role: 'admin',
        is_active: true
      },
      {
        username: 'manager',
        email: 'manager@hotel.com',
        password: await hashPassword('manager123'),
        role: 'manager',
        is_active: true
      },
      {
        username: 'reception',
        email: 'reception@hotel.com',
        password: await hashPassword('reception123'),
        role: 'receptionist',
        is_active: true
      },
      {
        username: 'staff1',
        email: 'staff1@hotel.com',
        password: await hashPassword('staff123'),
        role: 'receptionist',
        is_active: true
      }
    ];

    for (const userData of users) {
      await User.findOrCreate({
        where: { email: userData.email },
        defaults: userData
      });
    }

    console.log(`✅ ${users.length} users seeded`);
  } catch (error) {
    console.error('❌ Error seeding users:', error);
    throw error;
  }
};

module.exports = seedUsers;