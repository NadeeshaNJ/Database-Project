# ✅ Integration Verification Checklist

Use this checklist to verify that your frontend-backend integration is working correctly.

---

## 📋 Pre-Flight Checks

### Backend Setup
- [ ] Backend server is installed
  ```powershell
  cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
  npm install
  ```

- [ ] Backend `.env` file exists and is configured
  ```powershell
  # Check if .env exists
  Test-Path "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend\.env"
  ```

- [ ] Database is running and accessible
  - PostgreSQL server is running
  - Database credentials in `.env` are correct
  - Database schema is created

- [ ] Backend dependencies are installed
  ```powershell
  # Should show a list of packages
  cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
  npm list --depth=0
  ```

### Frontend Setup
- [ ] Frontend dependencies are installed
  ```powershell
  cd "c:\Users\nadee\Documents\Database-Project"
  npm install
  ```

- [ ] Frontend `.env` file exists
  ```powershell
  Test-Path "c:\Users\nadee\Documents\Database-Project\.env"
  ```

- [ ] Frontend `.env` has correct backend URL
  ```
  REACT_APP_API_URL=http://localhost:5000/api
  ```

---

## 🚀 Server Startup Checks

### Start Backend
- [ ] Backend starts without errors
  ```powershell
  cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
  npm start
  ```

- [ ] Backend shows startup message
  ```
  Expected output:
  🚀 Hotel Management System Backend is running!
  📍 Port: 5000
  🌍 Environment: development
  📊 Database: [your_db_name]
  ```

- [ ] Backend health check responds
  ```powershell
  # In a new terminal
  curl http://localhost:5000/api/health
  ```
  Expected: `{"success":true,"message":"Hotel Management API is running",...}`

### Start Frontend
- [ ] Frontend starts without errors
  ```powershell
  cd "c:\Users\nadee\Documents\Database-Project"
  npm start
  ```

- [ ] Frontend opens in browser at `http://localhost:3000`

- [ ] No console errors in browser (F12 → Console tab)

---

## 🔌 Connection Tests

### Test 1: Health Check
- [ ] Open browser console (F12)
- [ ] Run this command:
  ```javascript
  fetch('http://localhost:5000/api/health')
    .then(r => r.json())
    .then(console.log)
  ```
- [ ] Should see: `{success: true, message: "Hotel Management API is running", ...}`

### Test 2: CORS Check
- [ ] In browser console, run:
  ```javascript
  fetch('http://localhost:5000/api/health', {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' }
  })
  .then(r => r.json())
  .then(console.log)
  .catch(console.error)
  ```
- [ ] Should NOT see CORS error
- [ ] Should receive response successfully

### Test 3: API Client Check
- [ ] In browser console at `http://localhost:3000`:
  ```javascript
  import { roomAPI } from './services/api';
  roomAPI.getAllRooms().then(console.log).catch(console.error);
  ```
- [ ] Should receive response (might be 401 if auth required)
- [ ] Should NOT see "Network Error" or "Connection Refused"

---

## 🔐 Authentication Tests

### Test 4: Login Endpoint
- [ ] Use test component OR browser console:
  ```javascript
  fetch('http://localhost:5000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: 'test-username',
      password: 'test-password'
    })
  })
  .then(r => r.json())
  .then(console.log);
  ```
- [ ] Should receive response (success or error, not network failure)

### Test 5: Token Storage
- [ ] After successful login, check localStorage:
  ```javascript
  console.log(localStorage.getItem('authToken'));
  ```
- [ ] Should see JWT token string

### Test 6: Authenticated Request
- [ ] After login, test authenticated endpoint:
  ```javascript
  import { guestAPI } from './services/api';
  guestAPI.getAllGuests().then(console.log).catch(console.error);
  ```
- [ ] Should receive data (not 401 error)

---

## 🧪 API Endpoint Tests

### Test 7: Rooms API
- [ ] Get all rooms:
  ```javascript
  import { roomAPI } from './services/api';
  roomAPI.getAllRooms().then(r => console.log(r.data));
  ```
- [ ] Should return rooms array

### Test 8: Guests API (Auth Required)
- [ ] Login first, then:
  ```javascript
  import { guestAPI } from './services/api';
  guestAPI.getAllGuests().then(r => console.log(r.data));
  ```
- [ ] Should return guests array

### Test 9: Bookings API (Auth Required)
- [ ] Login first, then:
  ```javascript
  import { bookingAPI } from './services/api';
  bookingAPI.getAllBookings().then(r => console.log(r.data));
  ```
- [ ] Should return bookings array

### Test 10: Payments API (Auth Required)
- [ ] Login first, then:
  ```javascript
  import { paymentAPI } from './services/api';
  paymentAPI.getAllPayments().then(r => console.log(r.data));
  ```
- [ ] Should return payments array

---

## 🎨 Frontend Component Tests

### Test 11: Login Page
- [ ] Navigate to `/login`
- [ ] Login form is visible
- [ ] Can submit login form
- [ ] Errors are displayed if credentials invalid
- [ ] Redirects to dashboard on success

### Test 12: Protected Routes
- [ ] Try accessing protected route without login
- [ ] Should redirect to login page
- [ ] After login, should access protected route

### Test 13: Data Loading
- [ ] Navigate to Rooms page
- [ ] Loading spinner appears
- [ ] Data loads from backend
- [ ] Data displays correctly

### Test 14: Error Handling
- [ ] Stop backend server
- [ ] Try to fetch data in frontend
- [ ] Should show error message
- [ ] Should not crash application

---

## 🔧 Configuration Verification

### Backend Configuration
- [ ] Check backend port:
  ```powershell
  cd "c:\Users\nadee\Documents\database_project-backend\Database-Project-Backend"
  Get-Content server.js | Select-String "PORT"
  ```
  Expected: `const PORT = process.env.PORT || 5000;`

- [ ] Check CORS configuration:
  ```powershell
  Get-Content app.js | Select-String "FRONTEND_URL"
  ```
  Expected: `process.env.FRONTEND_URL || 'http://localhost:3000'`

### Frontend Configuration
- [ ] Check API URL:
  ```powershell
  cd "c:\Users\nadee\Documents\Database-Project"
  Get-Content .env | Select-String "API_URL"
  ```
  Expected: `REACT_APP_API_URL=http://localhost:5000/api`

- [ ] Check apiClient.js:
  ```powershell
  Get-Content src\services\apiClient.js | Select-String "localhost:5000"
  ```
  Expected: Found

---

## 📊 Integration Test Component

### Test 15: Use Test Component
- [ ] Add test component to your app:
  ```javascript
  import BackendIntegrationTest from './components/BackendIntegrationTest';
  
  // In your App.js or test page
  <BackendIntegrationTest />
  ```

- [ ] Click "Run Tests" button

- [ ] Verify results:
  - [ ] ✓ Health check passes
  - [ ] ✓ Rooms API responds (may require auth)
  - [ ] ⚠ Guests API shows auth warning OR ✓ passes if logged in
  - [ ] ⚠ Bookings API shows auth warning OR ✓ passes if logged in

---

## 🐛 Troubleshooting Checks

### If Backend Won't Start
- [ ] Check if port 5000 is already in use:
  ```powershell
  netstat -ano | findstr :5000
  ```

- [ ] Check database connection in backend terminal

- [ ] Check `.env` file for database credentials

### If Frontend Won't Connect
- [ ] Check browser console for CORS errors

- [ ] Verify backend is running: `curl http://localhost:5000/api/health`

- [ ] Verify `.env` has correct URL

- [ ] Clear browser cache and localStorage

### If Authentication Fails
- [ ] Check if JWT_SECRET is set in backend `.env`

- [ ] Check token in localStorage: `localStorage.getItem('authToken')`

- [ ] Check if token is expired (try login again)

- [ ] Check backend terminal for authentication errors

### If API Calls Fail
- [ ] Check Network tab in browser DevTools (F12)

- [ ] Look for 401, 403, 404, or 500 errors

- [ ] Check backend terminal for error logs

- [ ] Verify API endpoint exists in backend routes

---

## ✅ Final Verification

### All Systems Go!
- [ ] ✅ Backend running on port 5000
- [ ] ✅ Frontend running on port 3000
- [ ] ✅ Database connected
- [ ] ✅ Health check passes
- [ ] ✅ CORS working
- [ ] ✅ Authentication working
- [ ] ✅ API calls successful
- [ ] ✅ No console errors
- [ ] ✅ Test component shows all green

---

## 📝 Notes

### Success Criteria
All items should be checked ✅ for full integration confirmation.

### If Issues Persist
1. Review `BACKEND_INTEGRATION_GUIDE.md`
2. Check `INTEGRATION_SUMMARY.md`
3. Review backend and frontend terminal logs
4. Check browser console for errors

### Contact
If you need help, ensure you have:
- Backend terminal output
- Frontend terminal output
- Browser console errors
- Network tab from DevTools

---

**Checklist Version:** 1.0
**Last Updated:** October 15, 2025
**Status:** Ready for verification
