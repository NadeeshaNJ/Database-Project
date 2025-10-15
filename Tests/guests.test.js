const request = require('supertest');
const app = require('../app');
const { Guest, User } = require('../models');

describe('Guests API', () => {
  let authToken;
  let testGuestId;

  beforeAll(async () => {
    // Login to get token
    const user = await User.create({
      username: 'guesttest',
      email: 'guesttest@example.com',
      password: 'password123',
      role: 'receptionist'
    });

    const response = await request(app)
      .post('/api/auth/login')
      .send({
        username: 'guesttest',
        password: 'password123'
      });

    authToken = response.body.data.token;

    // Create a test guest
    const guest = await Guest.create({
      first_name: 'Test',
      last_name: 'Guest',
      email: 'testguest@example.com',
      phone: '+1-555-0000'
    });
    testGuestId = guest.id;
  });

  describe('GET /api/guests', () => {
    it('should get all guests', async () => {
      const response = await request(app)
        .get('/api/guests')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should search guests by name', async () => {
      const response = await request(app)
        .get('/api/guests?search=Test')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
    });
  });

  describe('PUT /api/guests/:id', () => {
    it('should update a guest', async () => {
      const updateData = {
        phone: '+1-555-1111',
        address: '123 Test Street'
      };

      const response = await request(app)
        .put(`/api/guests/${testGuestId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.phone).toBe('+1-555-1111');
    });
  });
});