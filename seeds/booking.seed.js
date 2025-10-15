const { Booking, Room, Guest, User } = require('../models');
const moment = require('moment');

const seedBookings = async () => {
  try {
    console.log('📅 Seeding bookings...');
    
    // Get sample data
    const rooms = await Room.findAll();
    const guests = await Guest.findAll();
    const users = await User.findAll();

    const bookings = [
      {
        guest_id: guests[0].id,
        room_id: rooms[1].id, // Room 102
        check_in: moment().add(2, 'days').format('YYYY-MM-DD'),
        check_out: moment().add(5, 'days').format('YYYY-MM-DD'),
        total_amount: 89.99 * 3,
        status: 'confirmed',
        adults: 1,
        children: 0,
        special_requests: 'Early check-in requested',
        created_by: users[0].id
      },
      {
        guest_id: guests[1].id,
        room_id: rooms[2].id, // Room 201
        check_in: moment().add(1, 'days').format('YYYY-MM-DD'),
        check_out: moment().add(3, 'days').format('YYYY-MM-DD'),
        total_amount: 129.99 * 2,
        status: 'confirmed',
        adults: 2,
        children: 0,
        special_requests: 'Honeymoon suite, please add champagne',
        created_by: users[1].id
      },
      {
        guest_id: guests[2].id,
        room_id: rooms[4].id, // Room 301
        check_in: moment().subtract(1, 'days').format('YYYY-MM-DD'),
        check_out: moment().add(2, 'days').format('YYYY-MM-DD'),
        total_amount: 199.99 * 3,
        status: 'checked_in',
        adults: 2,
        children: 1,
        special_requests: 'Extra bed for child',
        created_by: users[2].id
      },
      {
        guest_id: guests[3].id,
        room_id: rooms[3].id, // Room 202
        check_in: moment().subtract(3, 'days').format('YYYY-MM-DD'),
        check_out: moment().subtract(1, 'days').format('YYYY-MM-DD'),
        total_amount: 139.99 * 2,
        status: 'checked_out',
        adults: 2,
        children: 0,
        special_requests: null,
        created_by: users[0].id
      }
    ];

    for (const bookingData of bookings) {
      await Booking.findOrCreate({
        where: {
          guest_id: bookingData.guest_id,
          room_id: bookingData.room_id,
          check_in: bookingData.check_in
        },
        defaults: bookingData
      });
    }

    console.log(`✅ ${bookings.length} bookings seeded`);
  } catch (error) {
    console.error('❌ Error seeding bookings:', error);
    throw error;
  }
};

module.exports = seedBookings;