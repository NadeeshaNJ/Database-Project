const request = require('supertest');
const app = require('../app');
const { Booking, Room, Guest, User } = require('../models');
const moment = require('moment');

describe('Bookings API', () => {
  let authToken;
  let testBookingId;
  let testRoomId;
  let testGuestId;

  beforeAll(async () => {
    // Login to get token
    const user = await User.create({
      username: 'bookingtest',
      email: 'bookingtest@example.com',
      password: 'password123',
      role: 'receptionist'
    });

    const response = await request(app)
      .post('/api/auth/login')
      .send({
        username: 'bookingtest',
        password: 'password123'
      });

    authToken = response.body.data.token;

    // Create test data
    const room = await Room.create({
      room_number: '888',
      room_type: 'double',
      price_per_night: 129.99,
      max_occupancy: 2
    });
    testRoomId = room.id;

    const guest = await Guest.create({
      first_name: 'Test',
      last_name: 'Guest',
      email: 'testguest@example.com',
      phone: '+1-555-0999'
    });
    testGuestId = guest.id;
  });

  describe('POST /api/bookings', () => {
    it('should create a new booking', async () => {
      const bookingData = {
        guest_id: testGuestId,
        room_id: testRoomId,
        check_in: moment().add(7, 'days').format('YYYY-MM-DD'),
        check_out: moment().add(9, 'days').format('YYYY-MM-DD'),
        adults: 2,
        children: 0,
        special_requests: 'Test booking'
      };

      const response = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${authToken}`)
        .send(bookingData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('confirmed');
      testBookingId = response.body.data.id;
    });
  });

  describe('GET /api/bookings', () => {
    it('should get all bookings', async () => {
      const response = await request(app)
        .get('/api/bookings')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });
  });

  describe('POST /api/bookings/:id/checkin', () => {
    it('should check in a guest', async () => {
      const response = await request(app)
        .post(`/api/bookings/${testBookingId}/checkin`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('checked_in');
    });
  });
});