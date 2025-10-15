# SkyNest Hotels - Authentication System

## Demo Login Credentials

The system comes with three pre-configured demo accounts for testing:

### 1. Administrator Account
- **Email:** `admin@skynest.com`
- **Password:** `admin123`
- **Role:** Administrator
- **Access:** All Branches
- **Permissions:** Full system access

### 2. Hotel Manager Account
- **Email:** `manager.colombo@skynest.com`
- **Password:** `manager123`
- **Role:** Hotel Manager
- **Access:** SkyNest Colombo
- **Permissions:** Manage rooms, bookings, view reports

### 3. Receptionist Account
- **Email:** `receptionist@skynest.com`
- **Password:** `reception123`
- **Role:** Receptionist
- **Access:** SkyNest Kandy
- **Permissions:** View rooms, manage bookings, view guests

## Features

### Authentication
- ✅ Secure login system with demo credentials
- ✅ Protected routes requiring authentication
- ✅ Session persistence using localStorage
- ✅ Role-based access control
- ✅ Automatic redirect to login for unauthenticated users

### User Profile
- ✅ View and edit personal information
- ✅ Profile overview with avatar placeholder
- ✅ Role and permission display
- ✅ Hotel branch assignment
- ✅ Security settings (password change, 2FA placeholders)

### Settings
- ✅ General settings (currency, timezone, date format, language)
- ✅ Notification preferences (email alerts, booking notifications, system alerts)
- ✅ Appearance settings (theme, sidebar, compact view)
- ✅ Security settings (2FA, session timeout, password expiry)
- ✅ Hotel preferences (check-in/out times, booking limits)
- ✅ System information (admin only)

### Navigation
- ✅ User dropdown in navbar
- ✅ Profile access from navigation
- ✅ Settings access from navigation
- ✅ Logout functionality
- ✅ Current hotel branch display
- ✅ User name and role visibility

## How to Use

1. **Start the Application**
   ```bash
   npm start
   ```

2. **Access the Login Page**
   - The app will automatically redirect to `/login` if not authenticated
   - Or navigate to `http://localhost:3000/login`

3. **Login with Demo Credentials**
   - Use any of the demo accounts listed above
   - Click the "Use" button next to credentials for quick entry

4. **Explore the System**
   - After login, you'll be redirected to the dashboard
   - Access your profile from the user dropdown in the navbar
   - Navigate through different modules based on your permissions

5. **Profile Management**
   - Click on your name in the navbar
   - Select "My Profile" to view/edit your information
   - Update name, email, and phone number
   - View your permissions and role

6. **Logout**
   - Click on your name in the navbar
   - Select "Logout" to end your session

## Security Notes

⚠️ **Development Mode:** These are demo credentials for development and testing purposes only.

For production deployment:
- Replace demo authentication with proper backend API
- Implement secure password hashing (bcrypt, etc.)
- Add JWT or session-based authentication
- Enable HTTPS
- Implement rate limiting
- Add CAPTCHA for login attempts
- Enable two-factor authentication
- Regular security audits

## File Structure

```
src/
├── context/
│   └── AuthContext.js          # Authentication context and logic
├── components/
│   ├── ProtectedRoute.js       # Route protection component
│   └── Layout/
│       └── Navbar.js            # Updated with user dropdown
├── pages/
│   ├── Login.js                 # Login page
│   ├── Profile.js               # User profile page
│   └── Settings.js              # System settings page
└── App.js                       # Updated with auth provider
```

## Settings Page Features

### General Settings
- **Hotel Name:** Configure the main hotel name
- **Currency:** Select currency (LKR, USD, EUR, GBP)
- **Timezone:** Set system timezone
- **Date Format:** Choose preferred date format
- **Language:** Select interface language (English, Sinhala, Tamil)

### Notification Preferences
- **Email Notifications:** Toggle email alerts on/off
- **Booking Alerts:** New booking notifications
- **Check-in/out Reminders:** Automatic reminders
- **Payment Alerts:** Payment notification settings
- **Maintenance Alerts:** System maintenance notifications
- **Daily Reports:** Receive daily summary reports

### Appearance Settings
- **Theme:** Light or Dark mode
- **Sidebar:** Collapse sidebar by default
- **Compact View:** Use compact interface layout
- **Avatars:** Show/hide user avatars

### Security Settings
- **Two-Factor Authentication:** Enable 2FA for extra security
- **Session Timeout:** Configure auto-logout time
- **Password Expiry:** Set password change frequency
- **Login Notifications:** Get alerted on new logins

### Hotel Preferences
- **Check-in Time:** Default check-in time (14:00)
- **Check-out Time:** Default check-out time (12:00)
- **Early Check-in:** Allow early check-ins
- **Late Check-out:** Allow late check-outs
- **Booking Limits:** Min/max booking duration
- **Default Room Status:** New room default status

### System Information (Admin Only)
- **System Version:** Current HRGSMS version
- **Database Status:** Connection status
- **Server Status:** Server health check
- **Last Backup:** Backup information
- **User Statistics:** Total users and active sessions
- **System Actions:** Backup, user management, logs, cache

## Technologies Used

- **React Context API** for state management
- **React Router** for navigation and protected routes
- **localStorage** for session persistence
- **Bootstrap** for UI components with Tabs
- **React Icons** for icons
