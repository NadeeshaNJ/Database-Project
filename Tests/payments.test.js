const request = require('supertest');
const app = require('../app');
const { Payment, Booking, Room, Guest, User } = require('../models');

describe('Payments API', () => {
  let authToken;
  let testPaymentId;
  let testBookingId;

  beforeAll(async () => {
    // Login to get token
    const user = await User.create({
      username: 'paymenttest',
      email: 'paymenttest@example.com',
      password: 'password123',
      role: 'admin'
    });

    const response = await request(app)
      .post('/api/auth/login')
      .send({
        username: 'paymenttest',
        password: 'password123'
      });

    authToken = response.body.data.token;

    // Create test booking for payment
    const room = await Room.create({
      room_number: '777',
      room_type: 'single',
      price_per_night: 99.99,
      max_occupancy: 1
    });

    const guest = await Guest.create({
      first_name: 'Payment',
      last_name: 'Test',
      email: 'payment@example.com'
    });

    const booking = await Booking.create({
      guest_id: guest.id,
      room_id: room.id,
      check_in: new Date(),
      check_out: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
      total_amount: 199.98,
      status: 'confirmed',
      created_by: user.id
    });
    testBookingId = booking.id;
  });

  describe('POST /api/payments', () => {
    it('should create a new payment', async () => {
      const paymentData = {
        booking_id: testBookingId,
        amount: 199.98,
        payment_method: 'credit_card',
        payment_status: 'completed'
      };

      const response = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send(paymentData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.payment_status).toBe('completed');
      testPaymentId = response.body.data.id;
    });
  });

  describe('GET /api/payments', () => {
    it('should get all payments', async () => {
      const response = await request(app)
        .get('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });
  });
});