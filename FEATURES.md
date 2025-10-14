# SkyNest Hotels Management System - Complete Feature Guide

## 🏨 Overview
SkyNest Hotels HRGSMS (Hotel Reservation and Guest Services Management System) is a comprehensive hotel management solution for managing three hotel branches in Sri Lanka: Colombo, Kandy, and Galle.

## 🔐 Authentication & User Management

### Login System
- **Secure Authentication:** Protected routes with session management
- **Demo Accounts:** 3 pre-configured accounts (Admin, Manager, Receptionist)
- **Session Persistence:** Stay logged in using localStorage
- **Auto-redirect:** Unauthenticated users redirected to login

### User Roles & Permissions
1. **Administrator** - Full system access to all branches
2. **Hotel Manager** - Manage rooms, bookings, and view reports for assigned branch
3. **Receptionist** - View rooms, manage bookings, view guests for assigned branch

### Demo Credentials
```
Admin:         admin@skynest.com / admin123
Manager:       manager.colombo@skynest.com / manager123
Receptionist:  receptionist@skynest.com / reception123
```

## 📋 Core Modules

### 1. Dashboard
- Quick overview of hotel operations
- Key metrics and statistics
- Recent activity feed
- Quick action buttons

### 2. Hotels Management
- **3 Hotel Branches:**
  - SkyNest Colombo (Beach Resort)
  - SkyNest Kandy (Mountain View)
  - SkyNest Galle (Historic Fort)
- Branch details: Address, phone, email, manager
- Occupancy rates and room counts
- Amenities and facilities
- Add/Edit/View hotel information

### 3. Rooms Management
- **Room Types:** Single, Double, Suite
- **Sample Rooms:** 10 rooms across 3 branches
- **Pricing:**
  - Single: LKR 7,000 - 8,000/night
  - Double: LKR 10,000 - 12,000/night
  - Suite: LKR 18,000 - 20,000/night
- **Features:**
  - Room status tracking (Available, Occupied, Maintenance, Cleaning)
  - Capacity and floor information
  - Amenities management (WiFi, AC, TV, Mini Bar, etc.)
  - Room size and view details
  - Grid and table views
  - Advanced filtering by hotel, status, and type
  - Occupancy rate statistics

### 4. Bookings Management
- Complete booking lifecycle (Reserved → Checked In → Checked Out)
- Guest information tracking
- Check-in/out date management
- Payment status integration
- Room assignment
- Booking filtering and search
- Prevent double-booking
- Booking history

### 5. Guests Management
- Guest profiles and contact information
- Booking history per guest
- Preferences and special requests
- Document management
- Guest loyalty tracking

### 6. Services Management
- Service catalogue
- Usage tracking
- Pricing management
- Service categories
- Link to bookings
- Service reports

### 7. Billing System
- **Checkout Calculations:**
  - Room charges
  - Service charges
  - Tax computation
  - Total amount calculation
- **Payment Tracking:**
  - Partial payments support
  - Outstanding dues management
  - Payment history
  - Payment methods (Cash, Card, Transfer)
- **Bills Management:**
  - Generate bills
  - View payment status
  - Print/export capabilities

### 8. Reports Module
- Room occupancy reports
- Billing summary reports
- Service usage reports
- Revenue reports
- Customer trend analysis
- Date range filtering
- Export capabilities

## ⚙️ Settings System

### General Settings
- Hotel name configuration
- Currency selection (LKR, USD, EUR, GBP)
- Timezone settings
- Date format preferences
- Language selection (English, Sinhala, Tamil)

### Notification Preferences
- **Email Notifications:** Enable/disable email alerts
- **Booking Alerts:** New bookings, modifications, cancellations
- **Check-in/out Reminders:** Automatic reminders
- **Payment Alerts:** Payment confirmations and due reminders
- **Maintenance Alerts:** Room maintenance notifications
- **System Alerts:** Low inventory, system updates
- **Daily Reports:** Automated daily summaries

### Appearance Settings
- **Theme:** Light/Dark mode toggle
- **Sidebar:** Collapse/expand by default
- **Compact View:** Dense UI layout option
- **Avatars:** Show/hide user profile pictures

### Security Settings
- **Two-Factor Authentication:** Enable 2FA
- **Session Timeout:** Configure auto-logout (15, 30, 60, 120 minutes, or never)
- **Password Expiry:** Set password change interval (30, 60, 90, 180 days, or never)
- **Login Notifications:** Alert on new login attempts

### Hotel Preferences
- **Check-in Time:** Default 14:00, customizable
- **Check-out Time:** Default 12:00, customizable
- **Early Check-in:** Enable/disable option
- **Late Check-out:** Enable/disable option
- **Minimum Booking Days:** Default 1 day
- **Maximum Booking Days:** Default 30 days
- **Default Room Status:** New room default state

### System Information (Admin Only)
- System version: HRGSMS v1.0.0
- Database connection status
- Server health monitoring
- Last backup timestamp
- User statistics (total users, active sessions)
- System actions:
  - Database backup
  - User management
  - View system logs
  - Clear cache

## 👤 User Profile

### Profile Management
- View personal information
- Edit name, email, phone number
- Role and permission display
- Hotel branch assignment
- User ID and status

### Security Options
- Change password
- Enable two-factor authentication
- View login history
- Manage active sessions

## 🎨 UI/UX Features

### Navigation
- **Top Navbar:**
  - SkyNest Hotels branding with HRGSMS badge
  - Current hotel branch display
  - User dropdown menu
  - Profile and settings access
  - Logout functionality

- **Side Sidebar:**
  - Dashboard
  - Hotels
  - Rooms
  - Bookings
  - Guests
  - Services
  - Billing
  - Reports

### Design System
- **Bootstrap 5:** Responsive components
- **React Icons:** Comprehensive icon library
- **Color Coding:**
  - Success: Available, Paid
  - Primary: Occupied, Active
  - Warning: Pending, Reserved
  - Danger: Cancelled, Overdue
  - Info: Checked In, Processing

### Responsive Design
- Mobile-friendly layouts
- Tablet optimization
- Desktop full-width views
- Adaptive grid systems

## 🔧 Technical Stack

### Frontend
- **React 18:** Latest React features
- **React Router v6:** Client-side routing
- **Bootstrap 5:** UI framework
- **React Icons:** Icon library
- **React Context API:** State management

### Authentication
- Context-based auth system
- Protected routes
- localStorage session persistence
- Role-based access control

### Data Management
- Sample data for development
- Ready for backend API integration
- JSON data structures
- State management with hooks

## 📦 Getting Started

### Installation
```bash
npm install
```

### Development
```bash
npm start
```
Application runs on `http://localhost:3000`

### Login
1. Navigate to `http://localhost:3000`
2. Auto-redirected to `/login`
3. Use demo credentials
4. Explore the system

## 🚀 Future Enhancements

### Planned Features
- [ ] Backend API integration
- [ ] Real-time notifications
- [ ] Advanced reporting with charts
- [ ] Email system integration
- [ ] SMS notifications
- [ ] Online booking portal
- [ ] Payment gateway integration
- [ ] Multi-language support
- [ ] Mobile app
- [ ] Calendar integration
- [ ] Housekeeping management
- [ ] Inventory management
- [ ] Staff scheduling
- [ ] Customer loyalty program

### Security Enhancements
- [ ] JWT authentication
- [ ] Real 2FA implementation
- [ ] Password encryption (bcrypt)
- [ ] Rate limiting
- [ ] CAPTCHA
- [ ] Security audit logs
- [ ] HTTPS enforcement

## 📝 Key Features Summary

✅ **Authentication System** - Secure login with role-based access
✅ **3 Hotel Branches** - Colombo, Kandy, Galle
✅ **Room Management** - 10 rooms with 3 types across branches
✅ **Booking System** - Complete lifecycle management
✅ **Billing System** - Checkout, payments, partial payments
✅ **User Profiles** - Edit info, view permissions
✅ **Settings System** - 6 comprehensive setting categories
✅ **Responsive Design** - Works on all devices
✅ **Demo Data** - Pre-loaded for testing
✅ **Protected Routes** - Secure page access
✅ **User Roles** - Admin, Manager, Receptionist
✅ **Currency Support** - LKR with multi-currency option
✅ **Notification System** - Customizable alerts
✅ **Theme Support** - Light/Dark mode ready

## 📞 Support

For questions or issues:
- Review documentation in `/AUTHENTICATION.md`
- Check demo credentials
- Verify all dependencies are installed
- Ensure npm start is running successfully

---

**SkyNest Hotels HRGSMS v1.0.0**  
*Hotel Reservation and Guest Services Management System*  
© 2025 SkyNest Hotels. All rights reserved.
