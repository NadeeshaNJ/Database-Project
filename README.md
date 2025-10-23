# SkyNest Hotel Management System - Frontend

Database Lab Project in Semester 3 - Hotel Reservation and Guest Services Management System

##  Live Production

- **Website**: https://nadeeshanj.github.io/Database-Project/
- **Status**: Production Ready 
- **Backend API**: https://skynest-backend-api.onrender.com

## Overview

This is a comprehensive React-based frontend application for managing hotel operations including guest management, reservations, room management, services, and reporting. Modern React application for the SkyNest chain (Colombo, Kandy, Galle branches). The application provides an intuitive and modern user interface for hotel staff to efficiently manage daily operations.

##  Features

###  Core Management Modules
- **Dashboard**: Real-time statistics, revenue charts, and quick actions
- **Guest Management**: Add, edit, view, and search guest information
- **Reservation Management**: Handle bookings, check-ins, and check-outs
- **Room Management**: Monitor room status, availability, and pricing
- **Service Management**: Track and manage guest service requests
- **Reports & Analytics**: Generate comprehensive reports and view performance metrics
- **Branch Management**: Multi-location support (Colombo, Kandy, Galle)
- **Billing**: Payment processing and adjustments
- **Staff**: Employee management and role assignment

###  UI/UX Features
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Modern Interface**: Clean and professional design with Bootstrap styling
- **Interactive Components**: Dynamic forms, modals, and data tables
- **Search & Filter**: Advanced search and filtering capabilities
- **Real-time Updates**: Live status updates and notifications
- **Modern Theme**: Sapphire Stream Whisper color scheme

###  Technical Features
- **Role-Based Access**: Different views for Admin, Manager, Receptionist, Accountant, Customer
- **Branch Filtering**: Filter data by hotel branch
- **React Router**: Client-side routing for single-page application
- **Bootstrap Integration**: Professional styling and responsive components
- **API Integration**: RESTful backend API connection
- **State Management**: Efficient state handling with React hooks and Context API
- **Error Handling**: Comprehensive error handling and user feedback
- **JWT Authentication**: Secure token-based authentication
- **Deployment**: GitHub Pages with GitHub Actions CI/CD

##  Tech Stack

- **Framework**: React 18
- **Routing**: React Router DOM v6
- **Styling**: Custom CSS with Bootstrap 5
- **Icons**: React Icons (Font Awesome)
- **HTTP Client**: Axios
- **Authentication**: JWT-based auth with protected routes
- **Deployment**: GitHub Pages

##  Project Structure

```
src/
 components/           # Reusable UI components
    Layout/          # Navigation and layout components
       Navbar.js    # Top navigation bar
       Sidebar.js   # Side navigation menu
    Common/          # Shared utility components
       LoadingSpinner.js
       ErrorMessage.js
       ConfirmDialog.js
    ProtectedRoute.js       # Route authentication
    BackendIntegrationTest.js
 pages/               # Main application pages
    Dashboard.js     # Main dashboard with statistics
    Guests.js        # Guest management page
    Reservations.js  # Reservation management page
    Rooms.js         # Room management page
    Services.js      # Service request management
    Billing.js       # Payment processing
    Reports.js       # Reports and analytics page
    Staff.js         # Employee management
    Login.js         # Authentication
 context/             # React Context for state management
    AuthContext.js   # Authentication state
    BranchContext.js # Branch selection state
 services/            # API integration layer
    apiClient.js     # Axios configuration and interceptors
    api.js           # API endpoint functions
 utils/               # Utility functions
    dateUtils.js     # Date formatting and calculations
    helpers.js       # General helper functions
 data/
    mockData.js      # Sample data
 App.js               # Main application component
 App.css              # Application-specific styles
 index.js             # Application entry point
 index.css            # Global styles
```

##  Getting Started

### Prerequisites
- Node.js (version 14 or higher)
- npm or yarn package manager

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/NadeeshaNJ/Database-Project.git
   cd Database-Project
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   
   Create `.env.development` for local development:
   ```env
   REACT_APP_API_BASE=http://localhost:5000
   REACT_APP_API_URL=http://localhost:5000/api
   REACT_APP_APP_NAME=Hotel Management System
   REACT_APP_VERSION=1.0.0
   REACT_APP_ENV=development
   REACT_APP_DEBUG=true
   ```
   
   Production (`.env.production`):
   ```env
   REACT_APP_API_BASE=https://skynest-backend-api.onrender.com
   ```

4. **Start the development server**
   ```bash
   npm start
   ```

5. **Open the application**
   - Navigate to `http://localhost:3000` in your browser

### Available Scripts

- `npm start`: Start development server
- `npm build`: Build production bundle
- `npm test`: Run test suite
- `npm run deploy`: Deploy to GitHub Pages

##  Default Credentials

**Admin Account**:
- Username: `admin`
- Password: `password123`

**Branch Managers**:
- `manager_colombo` / `password123`
- `manager_kandy` / `password123`
- `manager_galle` / `password123`

**Receptionists**:
- `recept_colombo` / `password123`
- `recept_kandy` / `password123`
- `recept_galle` / `password123`

##  Deployment

Automatically deployed to GitHub Pages on push to `main` branch.

```bash
# Build and deploy manually
npm run deploy
```

##  Theme

**Sapphire Stream Whisper**:
- Primary: Deep Ocean Blue (#1a2332)
- Secondary: Coral Whisper (#ff6b6b)
- Accent: Soft Sage (#a8dadc)
- Warm: Champagne Gold (#f4a261)

##  API Integration

The application is designed to work with a RESTful backend API. Key API endpoints include:

- `POST /api/auth/login` - Authentication
- `GET /api/guests` - Retrieve guest list
- `POST /api/guests` - Create new guest
- `GET /api/bookings` - Bookings list
- `POST /api/reservations` - Create new reservation
- `GET /api/rooms` - Rooms list
- `GET /api/services` - Service requests
- `GET /api/reports/dashboard-summary` - Dashboard data

See backend README for complete API documentation.

Update the `REACT_APP_API_BASE` in your `.env` file to connect to your backend.

##  Testing

```bash
npm test
```

##  License

Proprietary - Database Project

##  Authors

Database Project Team

## Acknowledgments

- React community for excellent documentation
- Bootstrap team for the UI framework
- All contributors and supporters of this project
