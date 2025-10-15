const request = require('supertest');
const app = require('../app');
const { Room, User } = require('../models');

describe('Rooms API', () => {
  let authToken;
  let testRoomId;

  beforeAll(async () => {
    // Login to get token
    const user = await User.create({
      username: 'roomtest',
      email: 'roomtest@example.com',
      password: 'password123',
      role: 'admin'
    });

    const response = await request(app)
      .post('/api/auth/login')
      .send({
        username: 'roomtest',
        password: 'password123'
      });

    authToken = response.body.data.token;

    // Create a test room
    const room = await Room.create({
      room_number: '999',
      room_type: 'single',
      price_per_night: 99.99,
      max_occupancy: 1,
      description: 'Test room'
    });
    testRoomId = room.id;
  });

  describe('GET /api/rooms', () => {
    it('should get all rooms', async () => {
      const response = await request(app)
        .get('/api/rooms')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should filter rooms by type', async () => {
      const response = await request(app)
        .get('/api/rooms?room_type=single')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      response.body.data.forEach(room => {
        expect(room.room_type).toBe('single');
      });
    });
  });

  describe('POST /api/rooms', () => {
    it('should create a new room', async () => {
      const newRoom = {
        room_number: '1000',
        room_type: 'double',
        price_per_night: 149.99,
        max_occupancy: 2,
        description: 'New test room'
      };

      const response = await request(app)
        .post('/api/rooms')
        .set('Authorization', `Bearer ${authToken}`)
        .send(newRoom)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.room_number).toBe('1000');
    });
  });

  describe('PUT /api/rooms/:id', () => {
    it('should update a room', async () => {
      const updateData = {
        price_per_night: 109.99,
        description: 'Updated test room'
      };

      const response = await request(app)
        .put(`/api/rooms/${testRoomId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.price_per_night).toBe('109.99');
    });
  });
});