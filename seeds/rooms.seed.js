const { Room } = require('../models');

const seedRooms = async () => {
  try {
    console.log('🏨 Seeding rooms...');
    
    const rooms = [
      {
        room_number: '101',
        room_type: 'single',
        price_per_night: 89.99,
        max_occupancy: 1,
        floor: 1,
        amenities: ['wifi', 'tv', 'ac', 'work_desk'],
        description: 'Cozy single room perfect for solo travelers',
        status: 'available'
      },
      {
        room_number: '102',
        room_type: 'single',
        price_per_night: 89.99,
        max_occupancy: 1,
        floor: 1,
        amenities: ['wifi', 'tv', 'ac', 'work_desk'],
        description: 'Comfortable single room with city view',
        status: 'available'
      },
      {
        room_number: '201',
        room_type: 'double',
        price_per_night: 129.99,
        max_occupancy: 2,
        floor: 2,
        amenities: ['wifi', 'tv', 'ac', 'minibar', 'hairdryer'],
        description: 'Spacious double room with queen bed',
        status: 'available'
      },
      {
        room_number: '202',
        room_type: 'double',
        price_per_night: 139.99,
        max_occupancy: 2,
        floor: 2,
        amenities: ['wifi', 'tv', 'ac', 'minibar', 'hairdryer', 'balcony'],
        has_balcony: true,
        description: 'Double room with private balcony',
        status: 'available'
      },
      {
        room_number: '301',
        room_type: 'suite',
        price_per_night: 199.99,
        max_occupancy: 3,
        floor: 3,
        amenities: ['wifi', 'tv', 'ac', 'minibar', 'jacuzzi', 'sofa', 'work_desk'],
        description: 'Luxury suite with separate living area',
        status: 'available'
      },
      {
        room_number: '302',
        room_type: 'deluxe',
        price_per_night: 179.99,
        max_occupancy: 2,
        floor: 3,
        amenities: ['wifi', 'tv', 'ac', 'minibar', 'balcony', 'sea_view'],
        has_balcony: true,
        has_sea_view: true,
        description: 'Deluxe room with stunning sea view',
        status: 'available'
      },
      {
        room_number: '401',
        room_type: 'executive',
        price_per_night: 249.99,
        max_occupancy: 2,
        floor: 4,
        amenities: ['wifi', 'tv', 'ac', 'minibar', 'balcony', 'sea_view', 'jacuzzi'],
        has_balcony: true,
        has_sea_view: true,
        description: 'Executive suite with premium amenities',
        status: 'available'
      },
      {
        room_number: '103',
        room_type: 'single',
        price_per_night: 89.99,
        max_occupancy: 1,
        floor: 1,
        amenities: ['wifi', 'tv', 'ac', 'work_desk'],
        description: 'Standard single room',
        status: 'maintenance'
      }
    ];

    for (const roomData of rooms) {
      await Room.findOrCreate({
        where: { room_number: roomData.room_number },
        defaults: roomData
      });
    }

    console.log(`✅ ${rooms.length} rooms seeded`);
  } catch (error) {
    console.error('❌ Error seeding rooms:', error);
    throw error;
  }
};

module.exports = seedRooms;