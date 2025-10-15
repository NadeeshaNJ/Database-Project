# Backend Integration Guide

## Overview
This document describes how the frontend (`Database-Project`) is integrated with the backend (`Database-Project-Backend`) without modifying the backend folder structure.

## ✅ Integration Complete

### 1. API Configuration Updated

**Files Modified:**
- `.env` - Updated backend API URL from port 3001 to 5000
- `src/services/apiClient.js` - Updated default API URL
- `src/services/api.js` - Completely rewritten to match backend routes

**Configuration:**
```
Backend URL: http://localhost:5000/api
Frontend URL: http://localhost:3000 (default React port)
```

### 2. Backend Structure (Read-Only)

**Backend Location:** `c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend`

**Backend Features:**
- **Port:** 5000 (configured in server.js)
- **Database:** PostgreSQL with Sequelize ORM
- **Authentication:** JWT-based with bcryptjs
- **CORS:** Enabled for `http://localhost:3000`

**Available Routes:**
```
/api/auth/*        - Authentication endpoints
/api/rooms/*       - Room management
/api/bookings/*    - Booking/Pre-booking management
/api/guests/*      - Guest management
/api/payments/*    - Payment processing
```

### 3. API Service Structure

The frontend now uses the following API modules:

#### **authAPI**
- `login(credentials)` - User login
- `registerStaff(staffData)` - Register staff member
- `registerCustomer(customerData)` - Register customer
- `getProfile()` - Get current user profile
- `updateStaffProfile(data)` - Update staff profile
- `updateCustomerProfile(data)` - Update customer profile
- `logout()` - Client-side logout

#### **guestAPI**
- `getAllGuests(params)` - Get all guests with filters
- `getGuestById(id)` - Get guest details
- `createGuest(data)` - Create new guest
- `updateGuest(id, data)` - Update guest
- `deleteGuest(id)` - Delete guest
- `searchGuests(term)` - Search guests

#### **roomAPI**
- `getAllRooms(params)` - Get all rooms with filters
- `getRoomById(id)` - Get room details
- `createRoom(data)` - Create new room (admin/manager)
- `updateRoom(id, data)` - Update room (admin/manager)
- `deleteRoom(id)` - Delete room (admin only)
- `getRoomAvailability(startDate, endDate)` - Check availability
- `updateRoomStatus(id, status)` - Update room status
- `getRoomTypesSummary()` - Get room types summary

#### **bookingAPI**
- `getAllPreBookings(params)` - Get all pre-bookings
- `getAllBookings(params)` - Get all confirmed bookings
- `getBookingById(id)` - Get booking details
- `createPreBooking(data)` - Create pre-booking
- `createBooking(data)` - Create confirmed booking
- `cancelCreatedBooking(bookingId)` - Cancel booking
- `cancelBooking(id, reason)` - Cancel with reason
- `checkIn(id)` - Check-in guest
- `checkOut(id)` - Check-out guest
- `getTodayCheckIns()` - Get today's check-ins
- `getTodayCheckOuts()` - Get today's check-outs

#### **paymentAPI**
- `getAllPayments(params)` - Get all payments
- `getPaymentById(id)` - Get payment details
- `createPayment(data)` - Create payment
- `getPaymentsByBooking(bookingId)` - Get booking payments
- `getPaymentSummary(startDate, endDate)` - Get payment summary

#### **reportAPI**
- `getOccupancyReport(startDate, endDate)` - Occupancy report
- `getRevenueReport(startDate, endDate)` - Revenue report
- `getGuestReport(startDate, endDate)` - Guest report
- `getDashboardStats()` - Dashboard statistics
- `exportReport(type, format, startDate, endDate)` - Export report

## 🚀 How to Run

### Terminal 1: Backend Server
```powershell
cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
npm start
# Or for development with auto-reload:
# npm run dev
```

**Expected Output:**
```
🚀 Hotel Management System Backend is running!
📍 Port: 5000
🌍 Environment: development
📊 Database: [your_db_name]
🕒 Time: [current_time]
```

### Terminal 2: Frontend Development Server
```powershell
cd "c:\Users\nadee\Documents\Database-Project"
npm start
```

**Expected Output:**
```
Compiled successfully!

You can now view hotel-management-frontend in the browser.

  Local:            http://localhost:3000
  On Your Network:  http://[your-ip]:3000
```

## 🔧 Environment Setup

### Frontend (.env)
```env
REACT_APP_API_URL=http://localhost:5000/api
REACT_APP_APP_NAME=Hotel Management System
REACT_APP_VERSION=1.0.0
REACT_APP_ENV=development
REACT_APP_DEBUG=true
```

### Backend (.env) - Already Configured
The backend should already have its `.env` file configured. Key settings:
```env
PORT=5000
NODE_ENV=development
JWT_SECRET=[your-secret]
FRONTEND_URL=http://localhost:3000
DB_HOST=localhost
DB_NAME=[your-db]
DB_USER=[your-user]
DB_PASSWORD=[your-password]
```

## 📝 Usage Examples

### Login Example
```javascript
import { authAPI } from './services/api';

const handleLogin = async () => {
  try {
    const response = await authAPI.login({
      username: 'admin',
      password: 'password123'
    });
    
    // Token is automatically stored in localStorage
    console.log('User:', response.data.user);
    console.log('Token:', response.data.token);
  } catch (error) {
    console.error('Login failed:', error.response?.data?.error);
  }
};
```

### Get Rooms with Filters
```javascript
import { roomAPI } from './services/api';

const fetchRooms = async () => {
  try {
    const response = await roomAPI.getAllRooms({
      status: 'available',
      room_type: 'deluxe',
      page: 1,
      limit: 10
    });
    
    console.log('Rooms:', response.data);
  } catch (error) {
    console.error('Error:', error);
  }
};
```

### Create Booking
```javascript
import { bookingAPI } from './services/api';

const createBooking = async () => {
  try {
    const response = await bookingAPI.createBooking({
      room_id: 1,
      check_in_date: '2025-10-20',
      check_out_date: '2025-10-25',
      booked_rate: 150.00,
      guest_id: 5,
      advance_payment: 75.00,
      preferred_payment_method: 'Card'
    });
    
    console.log('Booking created:', response.data);
  } catch (error) {
    console.error('Error:', error.response?.data);
  }
};
```

## 🔐 Authentication Flow

1. **Login:** User submits credentials to `/api/auth/login`
2. **Token Storage:** JWT token is stored in `localStorage` as `authToken`
3. **Auto-Injection:** `apiClient.js` automatically adds token to all requests
4. **Auto-Redirect:** If 401 error occurs, user is redirected to `/login`

## 🎯 Key Differences from Backend

### Booking Status Values
**Backend Enum:** `'Booked', 'Checked-In', 'Checked-Out', 'Cancelled'`

Make sure your frontend uses these exact values (case-sensitive).

### Role Values
**Backend Enum:** `'Admin', 'Receptionist', 'Manager', 'Accountant', 'Customer'`

Use these exact role names in your frontend.

### Payment Methods
**Backend Enum:** `'Cash', 'Card', 'Online', 'BankTransfer'`

### Room Types
**Backend Enum:** `'single', 'double', 'suite', 'deluxe', 'executive'`

## 🐛 Troubleshooting

### Issue: CORS Error
**Solution:** Backend already configured to allow `http://localhost:3000`

### Issue: 401 Unauthorized
**Solution:** Check if token is stored in localStorage and valid

### Issue: Connection Refused
**Solution:** Make sure backend is running on port 5000

### Issue: Database Connection Error
**Solution:** Check backend `.env` file for correct database credentials

## 📚 Additional Files

- `src/services/api.backup.js` - Original API file backup
- `src/services/api.updated.js` - Reference copy of updated API
- `.env.example` - Example environment variables

## 🎨 No Frontend Changes Required

The integration is **plug-and-play**. Your existing React components will work with the updated API services without modification to:
- Component logic
- State management
- UI/UX design
- Styling

Simply update your components to use the new API methods when needed.

## 📞 Support

If you encounter any issues:
1. Check that both servers are running
2. Verify environment variables are set correctly
3. Check browser console for detailed error messages
4. Check backend terminal for server-side errors

---

**Integration Status:** ✅ Complete
**Last Updated:** October 15, 2025
**Backend Version:** 1.0.0
**Frontend Version:** 1.0.0
