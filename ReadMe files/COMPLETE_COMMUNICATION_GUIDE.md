# 🔐 Complete Frontend-Backend-Database Communication Guide for SkyNest Hotel Management System

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Authentication Flow (JWT & Password Hashing)](#2-authentication-flow-jwt--password-hashing)
3. [HTTP Communication](#3-http-communication)
4. [Database Operations](#4-database-operations)
5. [Real-time Updates & Dynamic Data](#5-real-time-updates--dynamic-data)
6. [Security Mechanisms](#6-security-mechanisms)
7. [Complete Request-Response Cycle Examples](#7-complete-request-response-cycle-examples)
8. [Summary Diagram](#8-summary-diagram)

---

## 1. Architecture Overview

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│                 │  HTTP   │                  │  SQL    │                 │
│   FRONTEND      │◄───────►│    BACKEND       │◄───────►│   DATABASE      │
│   (React.js)    │ Request │  (Node.js +      │ Queries │  (PostgreSQL)   │
│                 │Response │   Express.js)    │         │                 │
└─────────────────┘         └──────────────────┘         └─────────────────┘
     Port 3000                   Port 5000                    Port 5432

     Browser                     Server                       Database
```

### Tech Stack Used:
- **Frontend**: React.js (JavaScript framework)
- **Backend**: Node.js with Express.js (REST API)
- **Database**: PostgreSQL (Relational database)
- **Authentication**: JWT (JSON Web Tokens)
- **Password Security**: bcrypt (Hashing algorithm)
- **HTTP Client**: Axios (Frontend) / fetch API
- **Database Client**: pg (node-postgres) + Sequelize ORM

---

## 2. Authentication Flow (JWT & Password Hashing)

### 2.1 Password Hashing with bcrypt

**What is Password Hashing?**
- Converts plain text passwords into irreversible encrypted strings
- Uses a "salt" (random data) to make each hash unique
- Even same passwords produce different hashes

**How it works in your project:**

#### During User Registration:
```javascript
// Backend: routers/auth.js (Registration)

// Step 1: User sends plain password
const plainPassword = "admin123";

// Step 2: Backend hashes the password using bcrypt
const bcrypt = require('bcrypt');
const saltRounds = 10; // Complexity level (higher = more secure but slower)

const hashedPassword = await bcrypt.hash(plainPassword, saltRounds);
// Result: "$2b$10$XqJ5KpS.4vN7hQ8mZGz.3OuYx9R1zK5wP3qT7mL0nB2cV6dH8fE9g"
//         ↑      ↑  ↑                              ↑
//         |      |  |                              |
//    Algorithm  Cost  Salt (22 chars)         Hash (31 chars)

// Step 3: Store ONLY the hashed password in database
await pool.query(
  'INSERT INTO user_account (username, password_hash, role) VALUES ($1, $2, $3)',
  [username, hashedPassword, role]
);
```

#### During Login:
```javascript
// Backend: routers/auth.js (Login)

// Step 1: Retrieve stored hash from database
const user = await User.findOne({ where: { username } });
const storedHash = user.password_hash;
// "$2b$10$XqJ5KpS.4vN7hQ8mZGz.3OuYx9R1zK5wP3qT7mL0nB2cV6dH8fE9g"

// Step 2: User sends plain password during login
const loginPassword = "admin123";

// Step 3: Compare plain password with stored hash
const isMatch = await bcrypt.compare(loginPassword, storedHash);
// bcrypt extracts the salt from the hash, re-hashes the input, and compares

if (isMatch) {
  // Password correct - proceed to generate JWT
} else {
  // Password incorrect - reject login
}
```

**Why bcrypt is secure:**
- **One-way function**: Cannot reverse-engineer the original password
- **Salt**: Prevents rainbow table attacks (precomputed hash databases)
- **Cost factor**: Adjustable complexity makes brute-force attacks slow
- **Timing-safe**: Compare function prevents timing attacks

---

### 2.2 JWT (JSON Web Tokens)

**What is JWT?**
A digitally signed token that proves user identity without storing session data on the server.

**JWT Structure:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI0MSIsInJvbGUiOiJBZG1pbiIsImlhdCI6MTYwOTY1MTIwLCJleHAiOjE3NjEwNTE1MjB9.XqJ5KpS4vN7hQ8mZGz3OuYx9R1zK5wP3qT
        ↑ HEADER                      ↑ PAYLOAD                                              ↑ SIGNATURE
```

**Three Parts:**

1. **Header** (Algorithm & Token Type):
   ```json
   {
     "alg": "HS256",  // HMAC SHA-256
     "typ": "JWT"
   }
   ```

2. **Payload** (User Data):
   ```json
   {
     "userId": "41",
     "role": "Admin",
     "branchId": null,
     "iat": 1609651520,  // Issued At (timestamp)
     "exp": 1761051520   // Expiration (timestamp)
   }
   ```

3. **Signature** (Verification):
   ```javascript
   HMACSHA256(
     base64UrlEncode(header) + "." + base64UrlEncode(payload),
     SECRET_KEY  // "your-secret-key-here" (stored in .env)
   )
   ```

**Complete JWT Flow in Your Project:**

#### Step 1: User Login
```javascript
// Frontend: src/pages/Login.js

const handleLogin = async (e) => {
  e.preventDefault();
  
  // Send credentials to backend
  const response = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: 'admin',
      password: 'admin123'
    })
  });
  
  const data = await response.json();
  // data = { token: "eyJhbGc...", user: {...} }
};
```

#### Step 2: Backend Generates JWT
```javascript
// Backend: routers/auth.js

const jwt = require('jsonwebtoken');

// After password verification succeeds...
const payload = {
  userId: user.user_id,
  role: user.role,
  branchId: employee?.branch_id || null,
  employeeId: employee?.employee_id || null
};

const token = jwt.sign(
  payload,                        // Data to encode
  process.env.JWT_SECRET,         // Secret key (e.g., "your-secret-key-here")
  { expiresIn: '24h' }           // Token expires in 24 hours
);

res.json({
  success: true,
  token: token,  // "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  user: {
    userId: user.user_id,
    username: user.username,
    role: user.role,
    branchId: employee?.branch_id || null
  }
});
```

#### Step 3: Frontend Stores Token
```javascript
// Frontend: src/context/AuthContext.js

const login = async (credentials) => {
  const response = await fetch('/api/auth/login', {...});
  const data = await response.json();
  
  // Store token in localStorage (persists across browser sessions)
  localStorage.setItem('token', data.token);
  localStorage.setItem('user', JSON.stringify(data.user));
  
  // Update React state
  setUser(data.user);
  setToken(data.token);
};
```

**localStorage vs sessionStorage:**
```javascript
// localStorage - Data persists even after browser closes
localStorage.setItem('token', 'abc123');
localStorage.getItem('token');  // "abc123" (available after restart)

// sessionStorage - Data deleted when browser tab closes
sessionStorage.setItem('token', 'abc123');
sessionStorage.getItem('token');  // null (after tab close)
```

#### Step 4: Frontend Sends Token with Every Request
```javascript
// Frontend: src/utils/api.js

export const fetchWithAuth = async (endpoint, options = {}) => {
  // Retrieve token from localStorage
  const token = localStorage.getItem('token');
  
  // Add token to Authorization header
  const response = await fetch(apiUrl(endpoint), {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${token}`,  // ← JWT sent here
      'Content-Type': 'application/json'
    }
  });
  
  return response;
};

// Usage example:
const hotels = await fetchWithAuth('/api/branches');
```

**HTTP Request Headers:**
```
GET /api/branches HTTP/1.1
Host: localhost:5000
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

#### Step 5: Backend Verifies Token (Middleware)
```javascript
// Backend: middlewares/authMiddleware.js

const jwt = require('jsonwebtoken');

const authenticateToken = (req, res, next) => {
  // Extract token from Authorization header
  const authHeader = req.headers['authorization'];
  // "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  
  const token = authHeader && authHeader.split(' ')[1];
  // Split by space: ["Bearer", "eyJhbGc..."]
  //                    [0]        [1] ← take this
  
  if (!token) {
    return res.status(401).json({ error: 'Access denied. No token provided.' });
  }
  
  try {
    // Verify token signature and decode payload
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    /* decoded = {
         userId: "41",
         role: "Admin",
         branchId: null,
         iat: 1609651520,
         exp: 1761051520
       } */
    
    // Check if token is expired
    if (decoded.exp < Date.now() / 1000) {
      return res.status(401).json({ error: 'Token expired' });
    }
    
    // Attach user data to request object
    req.user = decoded;
    
    // Continue to next middleware/route handler
    next();
    
  } catch (err) {
    return res.status(403).json({ error: 'Invalid token' });
  }
};

module.exports = authenticateToken;
```

#### Step 6: Protected Routes Use Middleware
```javascript
// Backend: routers/branches.js

const express = require('express');
const router = express.Router();
const authenticateToken = require('../middlewares/authMiddleware');

// Public route (no authentication)
router.get('/api/public/hotels', (req, res) => {
  // Anyone can access this
});

// Protected route (requires authentication)
router.get('/api/branches', authenticateToken, async (req, res) => {
  // authenticateToken runs FIRST
  // If token is valid, req.user is populated
  // If token is invalid, request is rejected before reaching here
  
  const userId = req.user.userId;    // From JWT payload
  const userRole = req.user.role;    // From JWT payload
  const branchId = req.user.branchId; // From JWT payload
  
  // Fetch branches based on user's role and branch
  const branches = await fetchBranches(branchId);
  res.json({ success: true, data: { branches } });
});

module.exports = router;
```

**Token Expiration Handling:**
```javascript
// Frontend: src/context/AuthContext.js

useEffect(() => {
  const checkTokenExpiration = () => {
    const token = localStorage.getItem('token');
    
    if (token) {
      try {
        // Decode token without verification (just to read expiration)
        const decoded = JSON.parse(atob(token.split('.')[1]));
        const currentTime = Date.now() / 1000;
        
        if (decoded.exp < currentTime) {
          // Token expired - logout user
          logout();
          alert('Session expired. Please login again.');
        }
      } catch (error) {
        logout();
      }
    }
  };
  
  // Check every minute
  const interval = setInterval(checkTokenExpiration, 60000);
  return () => clearInterval(interval);
}, []);
```

---

## 3. HTTP Communication

### 3.1 HTTP Request Methods

Your project uses these HTTP methods:

```javascript
// GET - Retrieve data (Read)
GET /api/branches
GET /api/bookings?status=confirmed

// POST - Create new data (Create)
POST /api/auth/login
POST /api/bookings

// PUT - Update entire resource (Update)
PUT /api/bookings/123

// PATCH - Update partial resource (Update)
PATCH /api/rooms/456/status

// DELETE - Remove data (Delete)
DELETE /api/bookings/789
```

### 3.2 Complete HTTP Request-Response Cycle

**Example: Fetching Hotel Branches**

#### Frontend Request:
```javascript
// Frontend: src/pages/Hotels.js (lines 21-54)

const fetchBranches = async () => {
  try {
    setLoading(true);
    setError('');
    
    // Send HTTP GET request
    const response = await fetch(apiUrl('/api/branches'), {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('token')}`,
        'Content-Type': 'application/json'
      }
    });
    
    /* 
    Actual HTTP Request sent:
    
    GET /api/branches HTTP/1.1
    Host: localhost:5000
    Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
    Content-Type: application/json
    Accept: application/json
    User-Agent: Mozilla/5.0...
    */
    
    // Parse JSON response
    const data = await response.json();
    
    /* 
    data = {
      success: true,
      data: {
        branches: [
          {
            branch_id: 1,
            branch_name: "Colombo",
            branch_code: "COL",
            address: "123 Galle Road, Colombo",
            contact_number: "011-234-5678",
            manager_name: "John Manager",
            total_rooms: 50,
            available_rooms: 23
          },
          // ... more branches
        ]
      }
    }
    */
    
    if (data.success && data.data && data.data.branches) {
      setHotels(data.data.branches);
    }
    
  } catch (err) {
    console.error('Error:', err);
    setError('Failed to connect to server');
  } finally {
    setLoading(false);
  }
};
```

#### Backend Processing:
```javascript
// Backend: routers/branches.js

const express = require('express');
const router = express.Router();
const { executeQuery } = require('../config/database');
const authenticateToken = require('../middlewares/authMiddleware');

router.get('/api/branches', authenticateToken, async (req, res) => {
  /*
  Request Flow:
  1. Express receives HTTP request
  2. authenticateToken middleware runs first
     - Verifies JWT token
     - Populates req.user with { userId, role, branchId }
  3. If authentication passes, this handler executes
  */
  
  try {
    const userRole = req.user.role;
    const userBranchId = req.user.branchId;
    
    let query;
    let params = [];
    
    // Role-based filtering
    if (userRole === 'Admin') {
      // Admin sees ALL branches
      query = `
        SELECT 
          b.branch_id,
          b.branch_name,
          b.branch_code,
          b.address,
          b.contact_number,
          COUNT(DISTINCT r.room_id) as total_rooms,
          COUNT(DISTINCT CASE WHEN r.status = 'Available' THEN r.room_id END) as available_rooms,
          e.name as manager_name
        FROM branch b
        LEFT JOIN room r ON b.branch_id = r.branch_id
        LEFT JOIN employee e ON b.branch_id = e.branch_id AND e.role = 'Manager'
        GROUP BY b.branch_id, b.branch_name, b.branch_code, b.address, b.contact_number, e.name
        ORDER BY b.branch_name
      `;
    } else {
      // Other roles see ONLY their branch
      query = `
        SELECT 
          b.branch_id,
          b.branch_name,
          b.branch_code,
          b.address,
          b.contact_number,
          COUNT(DISTINCT r.room_id) as total_rooms,
          COUNT(DISTINCT CASE WHEN r.status = 'Available' THEN r.room_id END) as available_rooms,
          e.name as manager_name
        FROM branch b
        LEFT JOIN room r ON b.branch_id = r.branch_id
        LEFT JOIN employee e ON b.branch_id = e.branch_id AND e.role = 'Manager'
        WHERE b.branch_id = $1
        GROUP BY b.branch_id, b.branch_name, b.branch_code, b.address, b.contact_number, e.name
      `;
      params = [userBranchId];
    }
    
    // Execute SQL query
    const result = await executeQuery(query, params);
    
    /* 
    SQL Query Result from PostgreSQL:
    
    result.rows = [
      {
        branch_id: 1,
        branch_name: 'Colombo',
        branch_code: 'COL',
        address: '123 Galle Road, Colombo',
        contact_number: '011-234-5678',
        total_rooms: '50',      // String from database
        available_rooms: '23',  // String from database
        manager_name: 'John Manager'
      },
      // ... more rows
    ]
    */
    
    // Send HTTP response
    res.status(200).json({
      success: true,
      data: {
        branches: result.rows,
        count: result.rowCount
      }
    });
    
    /*
    Actual HTTP Response:
    
    HTTP/1.1 200 OK
    Content-Type: application/json
    Content-Length: 1234
    
    {
      "success": true,
      "data": {
        "branches": [...],
        "count": 3
      }
    }
    */
    
  } catch (error) {
    console.error('Error fetching branches:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch branches'
    });
  }
});

module.exports = router;
```

#### Database Query Execution:
```javascript
// Backend: config/database.js

const { Pool } = require('pg');

// PostgreSQL connection pool
const pool = new Pool({
  user: process.env.DB_USER,       // 'postgres'
  host: process.env.DB_HOST,       // 'localhost'
  database: process.env.DB_NAME,   // 'skynest_db'
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432,
  max: 20,                          // Maximum 20 concurrent connections
  idleTimeoutMillis: 30000,        // Close idle connections after 30s
  connectionTimeoutMillis: 2000    // Fail after 2s if no connection
});

const executeQuery = async (query, params = []) => {
  const client = await pool.connect();  // Get connection from pool
  
  try {
    console.log('Executing SQL:', query);
    console.log('Parameters:', params);
    
    /* 
    Query sent to PostgreSQL:
    
    SELECT 
      b.branch_id,
      b.branch_name,
      ...
    FROM branch b
    LEFT JOIN room r ON b.branch_id = r.branch_id
    ...
    */
    
    const result = await client.query(query, params);
    
    /* 
    PostgreSQL returns:
    
    {
      command: 'SELECT',
      rowCount: 3,
      rows: [
        { branch_id: 1, branch_name: 'Colombo', ... },
        { branch_id: 2, branch_name: 'Kandy', ... },
        { branch_id: 3, branch_name: 'Galle', ... }
      ],
      fields: [...],
      _parsers: [...],
      _types: {...}
    }
    */
    
    return result;
    
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  } finally {
    client.release();  // Return connection to pool
  }
};

module.exports = { pool, executeQuery };
```

---

### 3.3 HTTP Status Codes Used

```javascript
// Success Codes
200 OK          // Request successful (GET, PUT, PATCH)
201 Created     // Resource created successfully (POST)
204 No Content  // Success but no content to return (DELETE)

// Client Error Codes
400 Bad Request          // Invalid data sent
401 Unauthorized         // No token or invalid token
403 Forbidden            // Token valid but insufficient permissions
404 Not Found            // Resource doesn't exist
409 Conflict             // Duplicate entry (e.g., username exists)
422 Unprocessable Entity // Validation error

// Server Error Codes
500 Internal Server Error  // Unexpected server error
503 Service Unavailable    // Database down

// Example usage in backend:
router.post('/api/bookings', async (req, res) => {
  const { room_id, guest_id, check_in_date } = req.body;
  
  // Validation error
  if (!room_id || !guest_id) {
    return res.status(400).json({ 
      success: false, 
      error: 'Missing required fields' 
    });
  }
  
  // Check if room is available
  const room = await Room.findByPk(room_id);
  if (!room) {
    return res.status(404).json({ 
      success: false, 
      error: 'Room not found' 
    });
  }
  
  if (room.status !== 'Available') {
    return res.status(409).json({ 
      success: false, 
      error: 'Room is not available' 
    });
  }
  
  try {
    const booking = await Booking.create({ room_id, guest_id, check_in_date });
    return res.status(201).json({ 
      success: true, 
      data: booking 
    });
  } catch (error) {
    return res.status(500).json({ 
      success: false, 
      error: 'Database error' 
    });
  }
});
```

---

## 4. Database Operations

### 4.1 PostgreSQL Database Schema

```sql
-- Branch Table
CREATE TABLE branch (
  branch_id SERIAL PRIMARY KEY,
  branch_name VARCHAR(100) NOT NULL,
  branch_code VARCHAR(10) UNIQUE NOT NULL,
  address TEXT,
  contact_number VARCHAR(20)
);

-- Room Table
CREATE TABLE room (
  room_id SERIAL PRIMARY KEY,
  branch_id INTEGER REFERENCES branch(branch_id),
  room_number VARCHAR(10) NOT NULL,
  room_type VARCHAR(50),
  price_per_night DECIMAL(10, 2),
  status VARCHAR(20) DEFAULT 'Available',
  UNIQUE(branch_id, room_number)
);

-- Guest Table
CREATE TABLE guest (
  guest_id SERIAL PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(20),
  id_number VARCHAR(50),
  nationality VARCHAR(100)
);

-- User Account Table (For Authentication)
CREATE TABLE user_account (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL,
  guest_id INTEGER REFERENCES guest(guest_id)
);

-- Employee Table
CREATE TABLE employee (
  employee_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES user_account(user_id),
  branch_id INTEGER REFERENCES branch(branch_id),
  name VARCHAR(200) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(20),
  hire_date DATE
);

-- Booking Table
CREATE TABLE booking (
  booking_id SERIAL PRIMARY KEY,
  guest_id INTEGER REFERENCES guest(guest_id),
  room_id INTEGER REFERENCES room(room_id),
  check_in_date DATE NOT NULL,
  check_out_date DATE NOT NULL,
  total_amount DECIMAL(10, 2),
  status VARCHAR(20) DEFAULT 'Pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4.2 SQL Query Types Used

#### SELECT (Read):
```javascript
// Simple SELECT
const query = `
  SELECT branch_id, branch_name, address 
  FROM branch 
  WHERE branch_id = $1
`;
const result = await executeQuery(query, [1]);
// Returns: [{ branch_id: 1, branch_name: 'Colombo', address: '...' }]

// SELECT with JOIN
const query = `
  SELECT 
    b.booking_id,
    g.first_name || ' ' || g.last_name as guest_name,
    r.room_number,
    b.check_in_date,
    b.status
  FROM booking b
  INNER JOIN guest g ON b.guest_id = g.guest_id
  INNER JOIN room r ON b.room_id = r.room_id
  WHERE b.branch_id = $1
  ORDER BY b.created_at DESC
  LIMIT 10
`;

// SELECT with aggregation
const query = `
  SELECT 
    branch_id,
    COUNT(*) as total_bookings,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_booking_value
  FROM booking
  WHERE check_in_date >= $1
  GROUP BY branch_id
  HAVING COUNT(*) > 5
`;
```

#### INSERT (Create):
```javascript
// Single INSERT
const query = `
  INSERT INTO guest (first_name, last_name, email, phone, nationality, id_number)
  VALUES ($1, $2, $3, $4, $5, $6)
  RETURNING guest_id, first_name, last_name
`;
const params = ['John', 'Doe', 'john@example.com', '077-1234567', 'Sri Lankan', 'NIC123'];
const result = await executeQuery(query, params);
// Returns: [{ guest_id: 101, first_name: 'John', last_name: 'Doe' }]

// INSERT with transaction
const client = await pool.connect();
try {
  await client.query('BEGIN');
  
  // Insert guest
  const guestResult = await client.query(
    'INSERT INTO guest (first_name, last_name, email) VALUES ($1, $2, $3) RETURNING guest_id',
    ['Jane', 'Smith', 'jane@example.com']
  );
  const guestId = guestResult.rows[0].guest_id;
  
  // Insert booking using the new guest_id
  await client.query(
    'INSERT INTO booking (guest_id, room_id, check_in_date, check_out_date) VALUES ($1, $2, $3, $4)',
    [guestId, 201, '2025-10-25', '2025-10-28']
  );
  
  await client.query('COMMIT');
} catch (error) {
  await client.query('ROLLBACK');
  throw error;
} finally {
  client.release();
}
```

#### UPDATE:
```javascript
// Simple UPDATE
const query = `
  UPDATE room 
  SET status = $1 
  WHERE room_id = $2
  RETURNING room_id, room_number, status
`;
const result = await executeQuery(query, ['Occupied', 201]);

// UPDATE with conditions
const query = `
  UPDATE booking
  SET status = 'Confirmed', total_amount = $1
  WHERE booking_id = $2 AND status = 'Pending'
  RETURNING booking_id, status, total_amount
`;
```

#### DELETE:
```javascript
// Soft DELETE (mark as inactive)
const query = `
  UPDATE user_account 
  SET is_active = false 
  WHERE user_id = $1
`;

// Hard DELETE (permanent removal)
const query = `
  DELETE FROM booking 
  WHERE booking_id = $1 AND status = 'Cancelled'
  RETURNING booking_id
`;
```

### 4.3 Sequelize ORM (Alternative to Raw SQL)

```javascript
// Backend: models/User.js

const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;

const User = sequelize.define('User', {
  user_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  username: {
    type: DataTypes.STRING(100),
    unique: true,
    allowNull: false
  },
  password_hash: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  role: {
    type: DataTypes.STRING(50),
    allowNull: false
  }
}, {
  tableName: 'user_account',
  timestamps: false
});

module.exports = User;

// Using Sequelize in routes:
router.get('/api/users', async (req, res) => {
  // Equivalent to: SELECT * FROM user_account WHERE role = 'Manager'
  const managers = await User.findAll({
    where: { role: 'Manager' },
    attributes: ['user_id', 'username', 'role'], // SELECT only these fields
    order: [['username', 'ASC']]
  });
  
  res.json({ success: true, data: managers });
});

// With JOIN using Sequelize:
router.get('/api/employees', async (req, res) => {
  const employees = await Employee.findAll({
    include: [
      {
        model: User,
        attributes: ['username', 'role']
      },
      {
        model: Branch,
        attributes: ['branch_name']
      }
    ]
  });
  
  /* Generates SQL:
  SELECT 
    e.*, 
    u.username, u.role, 
    b.branch_name
  FROM employee e
  LEFT JOIN user_account u ON e.user_id = u.user_id
  LEFT JOIN branch b ON e.branch_id = b.branch_id
  */
});
```

---

## 5. Real-time Updates & Dynamic Data

### 5.1 React State Management

**How frontend updates dynamically:**

```javascript
// Frontend: src/pages/Hotels.js

const Hotels = () => {
  // useState creates reactive state
  const [hotels, setHotels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  /* 
  How React State Works:
  
  1. Initial render: hotels = []
  2. User visits page
  3. useEffect runs → fetchBranches()
  4. setHotels([{...}, {...}]) called
  5. React detects state change
  6. React re-renders component with new hotels data
  7. UI updates automatically
  */
  
  useEffect(() => {
    fetchBranches(); // Runs on component mount
  }, []); // Empty array = run only once
  
  const fetchBranches = async () => {
    setLoading(true);  // UI shows spinner
    
    const response = await fetch(apiUrl('/api/branches'));
    const data = await response.json();
    
    setHotels(data.data.branches);  // UI updates with hotel cards
    setLoading(false);              // UI hides spinner
  };
  
  // UI automatically updates when state changes
  return (
    <div>
      {loading && <Spinner />}
      {!loading && hotels.map(hotel => (
        <Card key={hotel.id}>
          <Card.Title>{hotel.name}</Card.Title>
          <p>Available: {hotel.availableRooms}</p>
        </Card>
      ))}
    </div>
  );
};
```

**React Re-rendering Flow:**
```
State Change (setHotels)
    ↓
React compares new state with old state
    ↓
Detects difference
    ↓
Schedules re-render
    ↓
Calls Hotels() function again
    ↓
Returns new JSX with updated data
    ↓
React updates only changed parts of DOM
    ↓
Browser displays updated UI
```

### 5.2 Context API for Global State

```javascript
// Frontend: src/context/AuthContext.js

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  
  // Load user from localStorage on app start
  useEffect(() => {
    const storedUser = localStorage.getItem('user');
    const storedToken = localStorage.getItem('token');
    
    if (storedUser && storedToken) {
      setUser(JSON.parse(storedUser));
      setToken(storedToken);
    }
  }, []);
  
  const login = async (credentials) => {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials)
    });
    const data = await response.json();
    
    // Update global state
    setUser(data.user);
    setToken(data.token);
    
    // Persist to localStorage
    localStorage.setItem('user', JSON.stringify(data.user));
    localStorage.setItem('token', data.token);
  };
  
  const logout = () => {
    setUser(null);
    setToken(null);
    localStorage.removeItem('user');
    localStorage.removeItem('token');
  };
  
  // Provide global state to all components
  return (
    <AuthContext.Provider value={{ user, token, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

// Any component can access user/token:
const Hotels = () => {
  const { user, token } = useContext(AuthContext);
  
  // user = { userId: 41, role: 'Admin', branchId: null }
  // token = "eyJhbGc..."
};
```

**Why Context API?**
- Avoids prop drilling (passing props through many levels)
- Global state accessible anywhere
- User data available across all pages without re-fetching

### 5.3 Automatic Data Refresh

```javascript
// Polling: Check for updates every 30 seconds
useEffect(() => {
  const interval = setInterval(() => {
    fetchBranches(); // Refresh data
  }, 30000); // 30 seconds
  
  return () => clearInterval(interval); // Cleanup on unmount
}, []);

// Refresh on focus
useEffect(() => {
  const handleFocus = () => {
    fetchBranches(); // Refresh when user returns to tab
  };
  
  window.addEventListener('focus', handleFocus);
  return () => window.removeEventListener('focus', handleFocus);
}, []);

// Manual refresh button
const handleRefresh = () => {
  setLoading(true);
  fetchBranches();
};

<Button onClick={handleRefresh}>
  <FaSync /> Refresh
</Button>
```

---

## 6. Security Mechanisms

### 6.1 Input Validation & Sanitization

```javascript
// Backend: Validation example

const { body, validationResult } = require('express-validator');

router.post('/api/bookings',
  // Validation middleware
  [
    body('guest_id').isInt().withMessage('Invalid guest ID'),
    body('room_id').isInt().withMessage('Invalid room ID'),
    body('check_in_date').isISO8601().withMessage('Invalid check-in date'),
    body('check_out_date').isISO8601().withMessage('Invalid check-out date')
      .custom((value, { req }) => {
        if (new Date(value) <= new Date(req.body.check_in_date)) {
          throw new Error('Check-out must be after check-in');
        }
        return true;
      })
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ 
        success: false, 
        errors: errors.array() 
      });
    }
    
    // Sanitize inputs (prevent SQL injection)
    const { guest_id, room_id, check_in_date, check_out_date } = req.body;
    
    // Use parameterized queries (safe from SQL injection)
    const query = `
      INSERT INTO booking (guest_id, room_id, check_in_date, check_out_date)
      VALUES ($1, $2, $3, $4)
      RETURNING booking_id
    `;
    
    // PostgreSQL automatically escapes parameters
    const result = await executeQuery(query, [guest_id, room_id, check_in_date, check_out_date]);
    
    res.status(201).json({ success: true, data: result.rows[0] });
  }
);
```

**SQL Injection Prevention:**
```javascript
// ❌ UNSAFE (vulnerable to SQL injection)
const unsafe = `SELECT * FROM users WHERE username = '${username}'`;
// If username = "admin' OR '1'='1", entire users table is exposed

// ✅ SAFE (parameterized query)
const safe = `SELECT * FROM users WHERE username = $1`;
const result = await executeQuery(safe, [username]);
// PostgreSQL escapes the parameter, preventing injection
```

### 6.2 CORS (Cross-Origin Resource Sharing)

```javascript
// Backend: server.js

const cors = require('cors');

app.use(cors({
  origin: 'http://localhost:3000',  // Only allow frontend
  credentials: true,                 // Allow cookies/auth headers
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

/* 
Without CORS:
Browser blocks requests from localhost:3000 to localhost:5000
Error: "CORS policy: No 'Access-Control-Allow-Origin' header"

With CORS:
Server adds headers to response:
  Access-Control-Allow-Origin: http://localhost:3000
  Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE
  Access-Control-Allow-Headers: Content-Type, Authorization
  
Browser allows the request
*/
```

### 6.3 Rate Limiting

```javascript
// Backend: Prevent brute-force attacks

const rateLimit = require('express-rate-limit');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Max 5 login attempts
  message: 'Too many login attempts. Please try again later.',
  standardHeaders: true,
  legacyHeaders: false
});

router.post('/api/auth/login', loginLimiter, async (req, res) => {
  // Login logic
});

/*
How it works:
1. User attempts login
2. Middleware increments counter for user's IP
3. If counter > 5 in 15 minutes, reject request
4. After 15 minutes, counter resets
*/
```

### 6.4 Environment Variables (.env)

```bash
# Backend: .env file (NEVER commit to Git)

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=skynest_db
DB_USER=postgres
DB_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your-super-secret-key-here-min-32-chars
JWT_EXPIRES_IN=24h

# Server
PORT=5000
NODE_ENV=development

# Frontend
REACT_APP_API_URL=http://localhost:5000
```

```javascript
// Backend: config/database.js

require('dotenv').config(); // Load .env variables

const pool = new Pool({
  host: process.env.DB_HOST,       // Read from .env
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD
});

// Frontend: src/utils/api.js

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';
```

---

## 7. Complete Request-Response Cycle Examples

### Example 1: User Login Flow (Step-by-Step)

```
┌──────────────────────────────────────────────────────────────────────────┐
│ FRONTEND (Browser)                                                       │
└──────────────────────────────────────────────────────────────────────────┘

1. User enters credentials:
   Username: "admin"
   Password: "admin123"

2. User clicks "Login" button

3. React event handler triggers:
   ```javascript
   const handleLogin = async (e) => {
     e.preventDefault();
     
     const response = await fetch('http://localhost:5000/api/auth/login', {
       method: 'POST',
       headers: { 'Content-Type': 'application/json' },
       body: JSON.stringify({ username: 'admin', password: 'admin123' })
     });
     
     const data = await response.json();
   };
   ```

4. HTTP Request sent to backend:
   ```
   POST /api/auth/login HTTP/1.1
   Host: localhost:5000
   Content-Type: application/json
   Content-Length: 52
   
   {"username":"admin","password":"admin123"}
   ```

┌──────────────────────────────────────────────────────────────────────────┐
│ BACKEND (Node.js/Express)                                                │
└──────────────────────────────────────────────────────────────────────────┘

5. Express receives request and routes to handler:
   ```javascript
   router.post('/api/auth/login', async (req, res) => {
     const { username, password } = req.body;
   ```

6. Fetch user from database:
   ```javascript
   const user = await User.findOne({ 
     where: { username: 'admin' } 
   });
   ```

7. Database query sent:
   ```sql
   SELECT user_id, username, password_hash, role 
   FROM user_account 
   WHERE username = 'admin';
   ```

┌──────────────────────────────────────────────────────────────────────────┐
│ DATABASE (PostgreSQL)                                                    │
└──────────────────────────────────────────────────────────────────────────┘

8. PostgreSQL executes query and returns:
   ```javascript
   {
     user_id: 41,
     username: 'admin',
     password_hash: '$2b$10$XqJ5KpS.4vN7hQ8mZGz.3OuYx9R1zK5wP3qT7mL0nB2cV6dH8fE9g',
     role: 'Admin'
   }
   ```

┌──────────────────────────────────────────────────────────────────────────┐
│ BACKEND (Node.js/Express)                                                │
└──────────────────────────────────────────────────────────────────────────┘

9. Verify password with bcrypt:
   ```javascript
   const isValid = await bcrypt.compare('admin123', user.password_hash);
   // true
   ```

10. Fetch employee data (if applicable):
    ```javascript
    const employee = await Employee.findOne({ where: { user_id: 41 } });
    // null (admin has no employee record)
    ```

11. Generate JWT token:
    ```javascript
    const token = jwt.sign(
      { 
        userId: 41, 
        role: 'Admin', 
        branchId: null 
      },
      'your-secret-key-here',
      { expiresIn: '24h' }
    );
    // "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    ```

12. Send HTTP response:
    ```javascript
    res.json({
      success: true,
      token: token,
      user: {
        userId: 41,
        username: 'admin',
        role: 'Admin',
        branchId: null
      }
    });
    ```

13. HTTP Response sent to frontend:
    ```
    HTTP/1.1 200 OK
    Content-Type: application/json
    
    {
      "success": true,
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "user": {
        "userId": 41,
        "username": "admin",
        "role": "Admin",
        "branchId": null
      }
    }
    ```

┌──────────────────────────────────────────────────────────────────────────┐
│ FRONTEND (Browser)                                                       │
└──────────────────────────────────────────────────────────────────────────┘

14. React receives response and stores data:
    ```javascript
    const data = await response.json();
    
    // Store in localStorage
    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
    
    // Update React state
    setUser(data.user);
    setToken(data.token);
    ```

15. React Router redirects to dashboard:
    ```javascript
    navigate('/admin');
    ```

16. Dashboard page loads and displays user info:
    ```jsx
    <h2>Welcome, {user.username}!</h2>
    ```

**Total Time:** ~150-300ms
```

---

### Example 2: Fetching Hotel Branches with Authentication

```
┌──────────────────────────────────────────────────────────────────────────┐
│ FRONTEND (React Component)                                               │
└──────────────────────────────────────────────────────────────────────────┘

1. Hotels page loads:
   ```javascript
   useEffect(() => {
     fetchBranches();
   }, []);
   ```

2. Fetch function executes:
   ```javascript
   const fetchBranches = async () => {
     const token = localStorage.getItem('token');
     
     const response = await fetch('http://localhost:5000/api/branches', {
       headers: {
         'Authorization': `Bearer ${token}`
       }
     });
   };
   ```

3. HTTP Request sent:
   ```
   GET /api/branches HTTP/1.1
   Host: localhost:5000
   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

┌──────────────────────────────────────────────────────────────────────────┐
│ BACKEND (Express Middleware)                                             │
└──────────────────────────────────────────────────────────────────────────┘

4. Request enters Express server

5. authenticateToken middleware runs FIRST:
   ```javascript
   const authenticateToken = (req, res, next) => {
     const authHeader = req.headers['authorization'];
     const token = authHeader && authHeader.split(' ')[1];
     
     try {
       const decoded = jwt.verify(token, process.env.JWT_SECRET);
       // { userId: 41, role: 'Admin', branchId: null }
       
       req.user = decoded;  // Attach to request
       next();              // Continue to route handler
     } catch (err) {
       return res.status(403).json({ error: 'Invalid token' });
     }
   };
   ```

6. Route handler executes:
   ```javascript
   router.get('/api/branches', authenticateToken, async (req, res) => {
     const userRole = req.user.role;     // 'Admin'
     const userBranchId = req.user.branchId; // null
   ```

7. Build SQL query based on role:
   ```javascript
   if (userRole === 'Admin') {
     query = `SELECT * FROM branch`;  // Get all branches
   } else {
     query = `SELECT * FROM branch WHERE branch_id = $1`;
     params = [userBranchId];  // Get only user's branch
   }
   ```

┌──────────────────────────────────────────────────────────────────────────┐
│ DATABASE (PostgreSQL)                                                    │
└──────────────────────────────────────────────────────────────────────────┘

8. Execute SQL query:
   ```sql
   SELECT 
     b.branch_id,
     b.branch_name,
     b.branch_code,
     b.address,
     b.contact_number,
     COUNT(r.room_id) as total_rooms,
     COUNT(CASE WHEN r.status = 'Available' THEN 1 END) as available_rooms
   FROM branch b
   LEFT JOIN room r ON b.branch_id = r.branch_id
   GROUP BY b.branch_id
   ORDER BY b.branch_name;
   ```

9. PostgreSQL returns results:
   ```javascript
   [
     {
       branch_id: 1,
       branch_name: 'Colombo',
       branch_code: 'COL',
       address: '123 Galle Road, Colombo',
       contact_number: '011-234-5678',
       total_rooms: 50,
       available_rooms: 23
     },
     {
       branch_id: 2,
       branch_name: 'Kandy',
       branch_code: 'KAN',
       address: '456 Peradeniya Road, Kandy',
       contact_number: '081-223-4567',
       total_rooms: 35,
       available_rooms: 12
     },
     {
       branch_id: 3,
       branch_name: 'Galle',
       branch_code: 'GAL',
       address: '789 Fort Road, Galle',
       contact_number: '091-234-5678',
       total_rooms: 28,
       available_rooms: 8
     }
   ]
   ```

┌──────────────────────────────────────────────────────────────────────────┐
│ BACKEND (Express)                                                        │
└──────────────────────────────────────────────────────────────────────────┘

10. Format and send response:
    ```javascript
    res.status(200).json({
      success: true,
      data: {
        branches: result.rows,
        count: result.rowCount
      }
    });
    ```

11. HTTP Response:
    ```
    HTTP/1.1 200 OK
    Content-Type: application/json
    
    {
      "success": true,
      "data": {
        "branches": [...],
        "count": 3
      }
    }
    ```

┌──────────────────────────────────────────────────────────────────────────┐
│ FRONTEND (React)                                                         │
└──────────────────────────────────────────────────────────────────────────┘

12. React receives response:
    ```javascript
    const data = await response.json();
    ```

13. Transform data to match frontend format:
    ```javascript
    const transformedBranches = data.data.branches.map(branch => ({
      id: branch.branch_id,
      name: `SkyNest ${branch.branch_name}`,
      location: branch.branch_name,
      address: branch.address,
      phone: branch.contact_number,
      totalRooms: parseInt(branch.total_rooms),
      availableRooms: parseInt(branch.available_rooms),
      status: 'Active'
    }));
    ```

14. Update React state:
    ```javascript
    setHotels(transformedBranches);
    setLoading(false);
    ```

15. React re-renders component with new data

16. Browser displays hotel cards:
    ```jsx
    {hotels.map((hotel) => (
      <Card key={hotel.id}>
        <Card.Header>{hotel.name}</Card.Header>
        <Card.Body>
          <p>Total Rooms: {hotel.totalRooms}</p>
          <p>Available: {hotel.availableRooms}</p>
        </Card.Body>
      </Card>
    ))}
    ```

**Total Time:** ~200-400ms
```

---

## 8. Summary Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     COMPLETE SYSTEM FLOW                                │
└─────────────────────────────────────────────────────────────────────────┘

1. USER ACTION
   └─> Clicks button in browser

2. FRONTEND (React)
   ├─> Event handler triggered
   ├─> Retrieves JWT from localStorage
   ├─> Sends HTTP request with Authorization header
   └─> await fetch('http://localhost:5000/api/...', { headers: { Authorization: 'Bearer token' } })

3. NETWORK
   └─> HTTP request travels over TCP/IP

4. BACKEND (Node.js/Express)
   ├─> Express receives request
   ├─> CORS middleware checks origin
   ├─> Body parser parses JSON
   ├─> authenticateToken middleware:
   │   ├─> Extracts JWT from header
   │   ├─> Verifies signature with SECRET_KEY
   │   ├─> Decodes payload
   │   ├─> Checks expiration
   │   └─> Attaches user data to req.user
   ├─> Route handler executes:
   │   ├─> Validates inputs
   │   ├─> Builds SQL query
   │   └─> Calls database
   
5. DATABASE (PostgreSQL)
   ├─> Receives parameterized SQL query
   ├─> Executes query
   ├─> Returns rows
   └─> Connection returned to pool

6. BACKEND (Response)
   ├─> Formats data as JSON
   ├─> Adds CORS headers
   ├─> Sends HTTP response with status code
   └─> res.json({ success: true, data: {...} })

7. NETWORK
   └─> HTTP response travels back

8. FRONTEND (React)
   ├─> Receives response
   ├─> Parses JSON
   ├─> Updates state (setData(...))
   ├─> React detects state change
   ├─> Re-renders component
   └─> Browser updates DOM

9. BROWSER
   └─> User sees updated UI

┌─────────────────────────────────────────────────────────────────────────┐
│                        SECURITY LAYERS                                  │
└─────────────────────────────────────────────────────────────────────────┘

Layer 1: HTTPS (SSL/TLS)
   └─> Encrypts data in transit

Layer 2: CORS
   └─> Only allows requests from trusted origins

Layer 3: JWT Authentication
   └─> Verifies user identity

Layer 4: Role-Based Access Control (RBAC)
   └─> Checks user permissions

Layer 5: Input Validation
   └─> Prevents malicious data

Layer 6: Parameterized Queries
   └─> Prevents SQL injection

Layer 7: Password Hashing (bcrypt)
   └─> Protects passwords at rest

Layer 8: Rate Limiting
   └─> Prevents brute-force attacks
```

---

## Key Takeaways

1. **Password Security**: bcrypt hashes passwords irreversibly with salts
2. **JWT Authentication**: Stateless tokens prove identity without server-side sessions
3. **HTTP Communication**: REST API with standard methods (GET, POST, PUT, DELETE)
4. **Database Queries**: Parameterized queries prevent SQL injection
5. **React State**: useState/useEffect trigger automatic UI updates
6. **Middleware**: Express middleware chains process requests sequentially
7. **Security**: Multiple layers (CORS, JWT, validation, rate limiting)
8. **Async/Await**: Handles asynchronous operations cleanly
9. **Context API**: Shares global state (user, token) across components
10. **Environment Variables**: Keeps secrets out of code

---

## Additional Resources

### Related Documentation Files:
- `AUTHENTICATION.md` - Detailed authentication system documentation
- `BACKEND_DATABASE_SETUP.md` - Database setup and configuration
- `BACKEND_INTEGRATION_GUIDE.md` - Backend API integration guide
- `ARCHITECTURE_DIAGRAM.md` - System architecture overview

### Useful Commands:

```bash
# Start Backend Server
cd Database-Back
npm install
npm start

# Start Frontend Development Server
cd Database-Project
npm install
npm start

# Access PostgreSQL Database
psql -U postgres -d skynest_db

# View Backend Logs
cd Database-Back
npm start | tee logs.txt

# Test API Endpoints
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

---

**This architecture provides a secure, scalable, and maintainable hotel management system!** 🏨🔐

**Created:** October 22, 2025  
**Project:** SkyNest Hotel Management System  
**Version:** 1.0
