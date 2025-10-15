const { Guest } = require('../models');

const seedGuests = async () => {
  try {
    console.log('👤 Seeding guests...');
    
    const guests = [
      {
        first_name: 'John',
        last_name: 'Smith',
        email: 'john.smith@example.com',
        phone: '+1-555-0101',
        address: '123 Main Street, New York, NY 10001',
        city: 'New York',
        country: 'USA',
        date_of_birth: '1985-03-15',
        id_type: 'passport',
        id_number: 'P12345678',
        preferences: { newsletter: true, smoking: false, accessibility: false }
      },
      {
        first_name: 'Maria',
        last_name: 'Garcia',
        email: 'maria.garcia@example.com',
        phone: '+1-555-0102',
        address: '456 Oak Avenue, Los Angeles, CA 90210',
        city: 'Los Angeles',
        country: 'USA',
        date_of_birth: '1990-07-22',
        id_type: 'driver_license',
        id_number: 'DL98765432',
        preferences: { newsletter: false, smoking: false, accessibility: true }
      },
      {
        first_name: 'David',
        last_name: 'Johnson',
        email: 'david.johnson@example.com',
        phone: '+1-555-0103',
        address: '789 Pine Road, Chicago, IL 60601',
        city: 'Chicago',
        country: 'USA',
        date_of_birth: '1978-11-30',
        id_type: 'national_id',
        id_number: 'NID45678901',
        preferences: { newsletter: true, smoking: true, accessibility: false }
      },
      {
        first_name: 'Sarah',
        last_name: 'Williams',
        email: 'sarah.williams@example.com',
        phone: '+1-555-0104',
        address: '321 Elm Street, Miami, FL 33101',
        city: 'Miami',
        country: 'USA',
        date_of_birth: '1992-05-18',
        id_type: 'passport',
        id_number: 'P87654321',
        preferences: { newsletter: true, smoking: false, accessibility: false }
      },
      {
        first_name: 'James',
        last_name: 'Brown',
        email: 'james.brown@example.com',
        phone: '+1-555-0105',
        address: '654 Cedar Lane, Seattle, WA 98101',
        city: 'Seattle',
        country: 'USA',
        date_of_birth: '1988-09-12',
        id_type: 'driver_license',
        id_number: 'DL23456789',
        preferences: { newsletter: false, smoking: false, accessibility: true }
      }
    ];

    for (const guestData of guests) {
      await Guest.findOrCreate({
        where: { email: guestData.email },
        defaults: guestData
      });
    }

    console.log(`✅ ${guests.length} guests seeded`);
  } catch (error) {
    console.error('❌ Error seeding guests:', error);
    throw error;
  }
};

module.exports = seedGuests;