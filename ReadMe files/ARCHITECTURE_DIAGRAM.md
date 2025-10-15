# 🏗️ System Architecture - Frontend & Backend Integration

## System Overview
```
┌─────────────────────────────────────────────────────────────────────────┐
│                        USER BROWSER                                      │
│                     http://localhost:3000                                │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ HTTP Requests
                             │
┌────────────────────────────▼────────────────────────────────────────────┐
│                     REACT FRONTEND                                       │
│                  (Database-Project)                                      │
│                                                                          │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────┐            │
│  │  Components    │  │   Services   │  │   Context       │            │
│  │  - Pages       │◄─┤   - api.js   │◄─┤   - AuthContext │            │
│  │  - Layout      │  │   - apiClient│  │                 │            │
│  │  - Common      │  └──────┬───────┘  └─────────────────┘            │
│  └────────────────┘         │                                           │
│                             │ Axios HTTP Client                         │
│                             │ + JWT Token Auto-Injection                │
└─────────────────────────────┼───────────────────────────────────────────┘
                             │
                             │ HTTP Requests with JWT
                             │ Content-Type: application/json
                             │ Authorization: Bearer <token>
                             │
┌────────────────────────────▼────────────────────────────────────────────┐
│                     EXPRESS BACKEND                                      │
│              (Database-Project-Backend)                                  │
│                   http://localhost:5000                                  │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────┐          │
│  │                  MIDDLEWARE LAYER                         │          │
│  │  - CORS (allows localhost:3000)                          │          │
│  │  - Helmet (security headers)                             │          │
│  │  - Morgan (logging)                                       │          │
│  │  - JWT Authentication (verify token)                     │          │
│  │  - Role Authorization (check permissions)                │          │
│  └───────────────────────┬──────────────────────────────────┘          │
│                          │                                               │
│  ┌───────────────────────▼──────────────────────────────────┐          │
│  │                  ROUTER LAYER                             │          │
│  │  /api/auth/*     - Authentication routes                 │          │
│  │  /api/guests/*   - Guest management routes               │          │
│  │  /api/rooms/*    - Room management routes                │          │
│  │  /api/bookings/* - Booking/Pre-booking routes            │          │
│  │  /api/payments/* - Payment processing routes             │          │
│  └───────────────────────┬──────────────────────────────────┘          │
│                          │                                               │
│  ┌───────────────────────▼──────────────────────────────────┐          │
│  │                 CONTROLLER LAYER                          │          │
│  │  - authController    - Authentication logic              │          │
│  │  - guestController   - Guest business logic              │          │
│  │  - roomController    - Room business logic               │          │
│  │  - bookingController - Booking business logic            │          │
│  │  - paymentController - Payment business logic            │          │
│  └───────────────────────┬──────────────────────────────────┘          │
│                          │                                               │
│  ┌───────────────────────▼──────────────────────────────────┐          │
│  │                   MODEL LAYER                             │          │
│  │  - User (Sequelize Model)                                │          │
│  │  - Guest (Sequelize Model)                               │          │
│  │  - Room (Sequelize Model)                                │          │
│  │  - Booking (Sequelize Model)                             │          │
│  │  - Payment (Sequelize Model)                             │          │
│  │  - PreBooking (Sequelize Model)                          │          │
│  │  + More models...                                        │          │
│  └───────────────────────┬──────────────────────────────────┘          │
│                          │                                               │
└──────────────────────────┼───────────────────────────────────────────────┘
                          │
                          │ SQL Queries via Sequelize ORM
                          │
┌──────────────────────────▼───────────────────────────────────────────────┐
│                    POSTGRESQL DATABASE                                    │
│                                                                           │
│  Tables:                                                                  │
│  - user_account      - guest           - room                            │
│  - employee          - booking         - pre_booking                     │
│  - payment           - payment_adjustment                                │
│  - service_usage     - room_type       - branch                          │
│  + More tables...                                                        │
└───────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Examples

### 1️⃣ User Login Flow
```
User (Browser)
    │
    │ 1. Enter credentials
    ▼
React Component (Login.js)
    │
    │ 2. Call authAPI.login({ username, password })
    ▼
API Service (api.js)
    │
    │ 3. POST /api/auth/login
    ▼
API Client (apiClient.js)
    │
    │ 4. axios.post('http://localhost:5000/api/auth/login', data)
    ▼
Backend Router (routers/auth.js)
    │
    │ 5. Route to login handler
    ▼
Backend Controller (controllers/authcontroller.js)
    │
    │ 6. Validate credentials
    │ 7. Generate JWT token
    ▼
User Model (models/user.js)
    │
    │ 8. Query database
    ▼
PostgreSQL Database
    │
    │ 9. Return user record
    ▼
Backend Controller
    │
    │ 10. Return { success: true, token, user }
    ▼
API Client (apiClient.js)
    │
    │ 11. Store token in localStorage
    │ 12. Return response to component
    ▼
React Component
    │
    │ 13. Update UI, redirect to dashboard
    ▼
User (Browser) - Logged In ✅
```

### 2️⃣ Fetching Rooms Flow
```
User (Browser)
    │
    │ 1. Visit Rooms page
    ▼
React Component (Rooms.js)
    │
    │ 2. useEffect(() => fetchRooms())
    │ 3. Call roomAPI.getAllRooms({ status: 'available' })
    ▼
API Service (api.js)
    │
    │ 4. GET /api/rooms?status=available
    ▼
API Client (apiClient.js)
    │
    │ 5. Intercept request
    │ 6. Add Authorization: Bearer <token>
    │ 7. axios.get('http://localhost:5000/api/rooms', { params: { status: 'available' }})
    ▼
Backend Middleware (middleware/auth.js)
    │
    │ 8. Verify JWT token
    │ 9. Decode user info
    ▼
Backend Router (routers/rooms.js)
    │
    │ 10. Route to getAllRooms handler
    ▼
Backend Controller (controllers/roomcontroller.js)
    │
    │ 11. Build query with filters
    │ 12. Call Room.findAll({ where: { status: 'available' }})
    ▼
Room Model (models/room.js)
    │
    │ 13. Query database with Sequelize
    ▼
PostgreSQL Database
    │
    │ 14. Return room records
    ▼
Backend Controller
    │
    │ 15. Format response
    │ 16. Return { success: true, rooms: [...] }
    ▼
API Client (apiClient.js)
    │
    │ 17. Return response to component
    ▼
React Component (Rooms.js)
    │
    │ 18. Update state: setRooms(response.data.rooms)
    │ 19. Re-render UI with room data
    ▼
User (Browser) - Sees Room List ✅
```

### 3️⃣ Creating a Booking Flow
```
User (Browser)
    │
    │ 1. Fill booking form
    │ 2. Click "Create Booking"
    ▼
React Component (Bookings.js)
    │
    │ 3. Validate form data
    │ 4. Call bookingAPI.createBooking(formData)
    ▼
API Service (api.js)
    │
    │ 5. POST /api/bookings/confirmed
    ▼
API Client (apiClient.js)
    │
    │ 6. Add Authorization header
    │ 7. axios.post('http://localhost:5000/api/bookings/confirmed', data)
    ▼
Backend Middleware
    │
    │ 8. Verify JWT token
    │ 9. Check role authorization
    │ 10. Validate request body
    ▼
Backend Router (routers/booking.js)
    │
    │ 11. Route to createBooking handler
    ▼
Backend Controller (controllers/bookingcontroller.js)
    │
    │ 12. Start database transaction
    │ 13. Create booking record
    │ 14. Update room status
    │ 15. Create payment record
    │ 16. Commit transaction
    ▼
Models (Booking, Room, Payment)
    │
    │ 17. Execute SQL INSERT queries
    ▼
PostgreSQL Database
    │
    │ 18. Save records and return IDs
    ▼
Backend Controller
    │
    │ 19. Return { success: true, booking: {...} }
    ▼
API Client
    │
    │ 20. Return response
    ▼
React Component
    │
    │ 21. Show success message
    │ 22. Refresh booking list
    │ 23. Clear form
    ▼
User (Browser) - Booking Created ✅
```

## Security Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     SECURITY LAYERS                          │
└─────────────────────────────────────────────────────────────┘

1. CORS Protection
   ├─ Only allows requests from http://localhost:3000
   └─ Blocks requests from other origins

2. Helmet Security Headers
   ├─ X-Content-Type-Options
   ├─ X-Frame-Options
   ├─ X-XSS-Protection
   └─ Content-Security-Policy

3. JWT Authentication
   ├─ Token generated on login
   ├─ Token stored in localStorage
   ├─ Token sent in Authorization header
   └─ Token verified on every request

4. Role-Based Authorization
   ├─ Admin: Full access
   ├─ Manager: Management operations
   ├─ Receptionist: Front desk operations
   ├─ Accountant: Financial operations
   └─ Customer: Guest portal only

5. Input Validation
   ├─ express-validator on backend
   ├─ Sanitization of inputs
   ├─ Type checking
   └─ Format validation

6. Error Handling
   ├─ No sensitive data in error messages
   ├─ Generic error responses to client
   ├─ Detailed logs on server
   └─ Auto-logout on 401
```

## Environment Configuration

```
┌────────────────────────────────────────────────────┐
│              FRONTEND (.env)                        │
├────────────────────────────────────────────────────┤
│ REACT_APP_API_URL=http://localhost:5000/api       │
│ REACT_APP_APP_NAME=Hotel Management System        │
│ REACT_APP_VERSION=1.0.0                           │
│ REACT_APP_ENV=development                         │
└────────────────────────────────────────────────────┘
                     │
                     │ HTTP Requests
                     ▼
┌────────────────────────────────────────────────────┐
│              BACKEND (.env)                         │
├────────────────────────────────────────────────────┤
│ PORT=5000                                          │
│ NODE_ENV=development                               │
│ JWT_SECRET=<your-secret>                           │
│ JWT_EXPIRES_IN=1h                                  │
│ FRONTEND_URL=http://localhost:3000                 │
│                                                    │
│ DB_HOST=localhost                                  │
│ DB_NAME=<database-name>                            │
│ DB_USER=<database-user>                            │
│ DB_PASSWORD=<database-password>                    │
│ DB_PORT=5432                                       │
└────────────────────────────────────────────────────┘
```

## API Response Format

```javascript
// Success Response
{
  "success": true,
  "data": { /* response data */ },
  "message": "Operation successful"
}

// Error Response
{
  "success": false,
  "error": "Error message",
  "details": [ /* optional error details */ ]
}

// Authentication Response
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "admin",
    "role": "Admin"
  }
}
```

## Key Features

### ✅ Implemented
- [x] JWT Authentication
- [x] Auto token injection
- [x] Auto logout on 401
- [x] CORS configuration
- [x] Role-based authorization
- [x] Input validation
- [x] Error handling
- [x] Request logging
- [x] Security headers
- [x] Database transactions

### 🎯 Integration Benefits
- ✅ **Type Safety**: Consistent API methods
- ✅ **Error Handling**: Centralized error management
- ✅ **Authentication**: Automatic token handling
- ✅ **Security**: Multiple security layers
- ✅ **Scalability**: Easy to add new endpoints
- ✅ **Maintainability**: Clear separation of concerns
- ✅ **Documentation**: Well-documented API

---

**Visual guide for the integrated Hotel Management System**
**Last Updated:** October 15, 2025
