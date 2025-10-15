# 🚀 Quick Start - Frontend + Backend Integration

## ✅ Integration Complete!

Your frontend is now connected to your backend. **No backend files were modified.**

## 📁 Project Structure

```
Database-Project/              (Frontend - React)
├── src/
│   ├── services/
│   │   ├── api.js            ✅ UPDATED - New API endpoints
│   │   ├── apiClient.js      ✅ UPDATED - Port changed to 5000
│   │   └── api.backup.js     📄 Backup of original
│   └── components/
│       └── BackendIntegrationTest.js  🧪 NEW - Test component
├── .env                       ✅ UPDATED - Backend URL
├── start-servers.ps1          🆕 NEW - Launcher script
└── BACKEND_INTEGRATION_GUIDE.md  📚 Full documentation

Database-Project-Backend/      (Backend - Node.js + PostgreSQL)
└── [NO CHANGES - Read Only]  🔒 Backend untouched
```

## 🎯 What Changed?

### ✅ Modified Files (Frontend Only):
1. **`.env`** - Backend URL: `http://localhost:5000/api`
2. **`src/services/apiClient.js`** - Updated default port to 5000
3. **`src/services/api.js`** - Complete rewrite to match backend routes

### 🆕 New Files:
1. **`BACKEND_INTEGRATION_GUIDE.md`** - Complete integration documentation
2. **`start-servers.ps1`** - PowerShell launcher for both servers
3. **`src/components/BackendIntegrationTest.js`** - Test component
4. **`src/services/api.backup.js`** - Backup of original API file

### 🔒 Unchanged:
- **Backend folder** - Completely untouched
- **Frontend components** - Your existing components work as-is
- **Frontend styling** - All themes and styles preserved

## 🚀 How to Run

### Option 1: Quick Launcher (Recommended)
```powershell
cd "c:\Users\nadee\Documents\Database-Project"
.\start-servers.ps1
```
Then select option 3 to start both servers.

### Option 2: Manual Start

**Terminal 1 - Backend:**
```powershell
cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
npm start
```

**Terminal 2 - Frontend:**
```powershell
cd "c:\Users\nadee\Documents\Database-Project"
npm start
```

### Expected Result:
- ✅ Backend running on: http://localhost:5000
- ✅ Frontend running on: http://localhost:3000

## 🧪 Test the Integration

### Method 1: Using Test Component
1. Add this to your `src/App.js` temporarily:
```javascript
import BackendIntegrationTest from './components/BackendIntegrationTest';

// Inside your App component:
<BackendIntegrationTest />
```

2. Visit http://localhost:3000 and click "Run Tests"

### Method 2: Browser Console
```javascript
// Open browser console on http://localhost:3000
fetch('http://localhost:5000/api/health')
  .then(r => r.json())
  .then(console.log);
```

## 📚 Available APIs

### Authentication
```javascript
import { authAPI } from './services/api';

authAPI.login({ username, password })
authAPI.registerStaff(staffData)
authAPI.registerCustomer(customerData)
authAPI.getProfile()
authAPI.updateStaffProfile(data)
authAPI.updateCustomerProfile(data)
```

### Guests
```javascript
import { guestAPI } from './services/api';

guestAPI.getAllGuests(params)
guestAPI.getGuestById(id)
guestAPI.createGuest(data)
guestAPI.updateGuest(id, data)
guestAPI.deleteGuest(id)
```

### Rooms
```javascript
import { roomAPI } from './services/api';

roomAPI.getAllRooms(params)
roomAPI.getRoomById(id)
roomAPI.createRoom(data)
roomAPI.updateRoom(id, data)
roomAPI.getRoomAvailability(startDate, endDate)
roomAPI.updateRoomStatus(id, status)
```

### Bookings
```javascript
import { bookingAPI } from './services/api';

bookingAPI.getAllBookings(params)
bookingAPI.createPreBooking(data)
bookingAPI.createBooking(data)
bookingAPI.checkIn(id)
bookingAPI.checkOut(id)
bookingAPI.cancelBooking(id, reason)
```

### Payments
```javascript
import { paymentAPI } from './services/api';

paymentAPI.getAllPayments(params)
paymentAPI.createPayment(data)
paymentAPI.getPaymentsByBooking(bookingId)
```

## 🔐 Authentication Flow

1. **Login:**
```javascript
const response = await authAPI.login({ username, password });
// Token automatically stored in localStorage
```

2. **Auto Token Injection:**
All subsequent API calls automatically include the token in headers.

3. **Auto Logout on 401:**
If token expires, user is automatically redirected to login.

## ⚠️ Important Enums (Must Match Backend)

### Booking Status
```javascript
'Booked', 'Checked-In', 'Checked-Out', 'Cancelled'
```

### User Roles
```javascript
'Admin', 'Receptionist', 'Manager', 'Accountant', 'Customer'
```

### Payment Methods
```javascript
'Cash', 'Card', 'Online', 'BankTransfer'
```

### Room Types
```javascript
'single', 'double', 'suite', 'deluxe', 'executive'
```

## 🐛 Troubleshooting

### Backend not responding?
```powershell
# Check if backend is running
curl http://localhost:5000/api/health
```

### CORS errors?
Backend is already configured for `http://localhost:3000`

### 401 Unauthorized?
```javascript
// Check token
console.log(localStorage.getItem('authToken'));

// Re-login
await authAPI.login({ username, password });
```

### Connection refused?
Make sure:
1. Backend is running on port 5000
2. Frontend is running on port 3000
3. .env file has correct API URL

## 📖 Documentation

For detailed information, see:
- **`BACKEND_INTEGRATION_GUIDE.md`** - Complete integration guide
- **Backend folder README** - Backend documentation

## 🎉 You're Ready!

Your frontend and backend are now integrated. Start coding! 🚀

---

**Need Help?**
1. Check `BACKEND_INTEGRATION_GUIDE.md`
2. Use the test component to diagnose issues
3. Check both terminal outputs for errors
