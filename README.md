https://nadeeshanj.github.io/Database-Project/

# SkyNest Hotel Management System - Frontend# Hotel Management System - Frontend



Modern React-based hotel management application for the SkyNest chain (Colombo, Kandy, Galle branches).Database Lab Project in Semester 3 - Hotel Reservation and Guest Services Management System



## 🚀 Live Production## Overview



- **Website**: https://nadeeshanj.github.io/Database-Project/This is a comprehensive React-based frontend application for managing hotel operations including guest management, reservations, room management, services, and reporting. The application provides an intuitive and modern user interface for hotel staff to efficiently manage daily operations.

- **Status**: Production Ready ✅

- **Backend API**: https://skynest-backend-api.onrender.com## Features



## 🎯 Features### 🏨 Core Management Modules

- **Dashboard**: Overview of hotel statistics and quick actions

### Core Modules- **Guest Management**: Add, edit, view, and search guest information

- **Dashboard**: Real-time statistics, revenue charts, and quick actions- **Reservation Management**: Handle bookings, check-ins, and check-outs

- **Bookings**: Reservation management with check-in/check-out- **Room Management**: Monitor room status, availability, and pricing

- **Guests**: Complete guest profile management- **Service Management**: Track and manage guest service requests

- **Rooms**: Room availability, status tracking, and pricing- **Reports & Analytics**: Generate comprehensive reports and view performance metrics

- **Hotels**: Branch management (Colombo, Kandy, Galle)

- **Services**: Guest service requests and tracking### 🎨 UI/UX Features

- **Billing**: Payment processing and adjustments- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices

- **Reports**: Analytics, revenue, and occupancy reports- **Modern Interface**: Clean and professional design with Bootstrap styling

- **Staff**: Employee management and role assignment- **Interactive Components**: Dynamic forms, modals, and data tables

- **Search & Filter**: Advanced search and filtering capabilities

### UI/UX- **Real-time Updates**: Live status updates and notifications

- **Responsive Design**: Mobile, tablet, and desktop support

- **Modern Theme**: Sapphire Stream Whisper color scheme### 🔧 Technical Features

- **Role-Based Access**: Different views for Admin, Manager, Receptionist, Accountant, Customer- **React Router**: Client-side routing for single-page application

- **Branch Filtering**: Filter data by hotel branch- **Bootstrap Integration**: Professional styling and responsive components

- **Real-time Updates**: Live data from cloud database- **API Integration**: Ready for backend API connection

- **State Management**: Efficient state handling with React hooks

## 🛠️ Tech Stack- **Error Handling**: Comprehensive error handling and user feedback

- **Utility Functions**: Helper functions for date formatting, validation, etc.

- **Framework**: React 18

- **Routing**: React Router DOM v6## Project Structure

- **Styling**: Custom CSS with modern design system

- **Icons**: React Icons (Font Awesome)```

- **HTTP Client**: Axiossrc/

- **Authentication**: JWT-based auth with protected routes├── components/           # Reusable UI components

- **Deployment**: GitHub Pages with GitHub Actions CI/CD│   ├── Layout/          # Navigation and layout components

│   │   ├── Navbar.js    # Top navigation bar

## 📁 Project Structure│   │   └── Sidebar.js   # Side navigation menu

│   └── Common/          # Shared utility components

```│       ├── LoadingSpinner.js

src/│       ├── ErrorMessage.js

├── components/│       └── ConfirmDialog.js

│   ├── Layout/├── pages/               # Main application pages

│   │   ├── Navbar.js           # Top navigation│   ├── Dashboard.js     # Main dashboard with statistics

│   │   └── Sidebar.js          # Side menu│   ├── Guests.js        # Guest management page

│   ├── Common/│   ├── Reservations.js  # Reservation management page

│   │   ├── LoadingSpinner.js│   ├── Rooms.js         # Room management page

│   │   └── ErrorMessage.js│   ├── Services.js      # Service request management

│   ├── ProtectedRoute.js       # Route authentication│   └── Reports.js       # Reports and analytics page

│   └── BackendIntegrationTest.js├── services/            # API integration layer

├── pages/│   ├── apiClient.js     # Axios configuration and interceptors

│   ├── Dashboard.js            # Main dashboard│   └── api.js           # API endpoint functions

│   ├── Bookings.js            # Reservation management├── utils/               # Utility functions

│   ├── Guests.js              # Guest management│   ├── dateUtils.js     # Date formatting and calculations

│   ├── Rooms.js               # Room management│   └── helpers.js       # General helper functions

│   ├── Hotels.js              # Branch management├── App.js               # Main application component

│   ├── Services.js            # Service requests├── App.css              # Application-specific styles

│   ├── Billing.js             # Payment processing├── index.js             # Application entry point

│   ├── Reports.js             # Analytics└── index.css            # Global styles

│   ├── Staff.js               # Employee management```

│   └── Login.js               # Authentication

├── context/## Getting Started

│   └── AuthContext.js          # Authentication state

├── services/### Prerequisites

│   └── api.js                  # API integration- Node.js (version 14 or higher)

├── utils/- npm or yarn package manager

│   └── helpers.js              # Utility functions

└── data/### Installation

    └── mockData.js             # Sample data

```1. **Clone the repository**

   ```bash

## 🚀 Getting Started   git clone <repository-url>

   cd Database-Project

### Prerequisites   ```

- Node.js 14+

- npm or yarn2. **Install dependencies**

   ```bash

### Installation   npm install

   ```

```bash

# Install dependencies3. **Configure environment variables**

npm install   - Copy `.env` file and update API endpoints as needed

   - Set `REACT_APP_API_URL` to your backend API URL

# Start development server

npm start4. **Start the development server**

```   ```bash

   npm start

### Environment Variables   ```



Create `.env.development` for local development:5. **Open the application**

```env   - Navigate to `http://localhost:3000` in your browser

REACT_APP_API_BASE=http://localhost:5000

```### Available Scripts



Production (`.env.production`):- `npm start`: Start development server

```env- `npm build`: Build production bundle

REACT_APP_API_BASE=https://skynest-backend-api.onrender.com- `npm test`: Run test suite

```- `npm run eject`: Eject from Create React App (irreversible)



## 🔐 Default Credentials## Usage Guide



**Admin Account**:### Dashboard

- Username: `admin`- View key performance indicators and statistics

- Password: `password123`- Quick access to common actions

- Recent reservations and activities overview

**Branch Managers**:

- `manager_colombo` / `password123`### Guest Management

- `manager_kandy` / `password123`- Add new guests with complete information

- `manager_galle` / `password123`- Search and filter guest records

- Edit existing guest details

**Receptionists**:- View guest history and status

- `recept_colombo` / `password123`

- `recept_kandy` / `password123`### Reservation Management

- `recept_galle` / `password123`- Create new reservations

- Manage check-ins and check-outs

## 📦 Deployment- Update reservation status

- View reservation analytics

Automatically deployed to GitHub Pages on push to `main` branch.

### Room Management

```bash- Monitor room availability and status

# Build and deploy manually- Update room information and pricing

npm run deploy- Manage room amenities

```- Track maintenance and cleaning status



## 🎨 Theme### Service Management

- Handle guest service requests

**Sapphire Stream Whisper**:- Assign services to staff members

- Primary: Deep Ocean Blue (#1a2332)- Track service completion status

- Secondary: Coral Whisper (#ff6b6b)- Manage service priorities

- Accent: Soft Sage (#a8dadc)

- Warm: Champagne Gold (#f4a261)### Reports & Analytics

- Generate occupancy reports

## 📝 API Endpoints- View revenue analytics

- Export data in various formats

See backend README for complete API documentation.- Track performance metrics



Key endpoints:## API Integration

- `POST /api/auth/login` - Authentication

- `GET /api/bookings` - Bookings listThe application is designed to work with a RESTful backend API. Key API endpoints include:

- `GET /api/guests/all` - Guests list

- `GET /api/rooms` - Rooms list- `GET /api/guests` - Retrieve guest list

- `GET /api/reports/dashboard-summary` - Dashboard data- `POST /api/guests` - Create new guest

- `GET /api/reservations` - Retrieve reservations

## 🧪 Testing- `POST /api/reservations` - Create new reservation

- `GET /api/rooms` - Retrieve room information

```bash- `GET /api/services` - Retrieve service requests

npm test- `GET /api/reports/dashboard` - Get dashboard statistics

```

Update the `REACT_APP_API_URL` in your `.env` file to connect to your backend.

## 📄 License

## Customization

Proprietary - Database Project

### Styling

## 👥 Authors- Modify `src/index.css` for global styles

- Update `src/App.css` for application-specific styles

Database Project Team- Bootstrap variables can be customized for theming


### Components
- Add new pages in the `src/pages` directory
- Create reusable components in `src/components`
- Update routing in `src/App.js`

### API Integration
- Modify `src/services/api.js` to add new endpoints
- Update `src/services/apiClient.js` for authentication logic

## Technologies Used

- **React 18**: Latest React features and hooks
- **React Router DOM**: Client-side routing
- **Bootstrap 5**: UI framework and styling
- **React Bootstrap**: Bootstrap components for React
- **React Icons**: Icon library
- **Axios**: HTTP client for API requests
- **React DatePicker**: Date selection components

## Development Roadmap

### Phase 1 (Current)
- ✅ Basic project structure
- ✅ Core UI components
- ✅ Page layouts and navigation
- ✅ Sample data and interactions

### Phase 2 (Next)
- 🔄 Backend API integration
- 🔄 Authentication and authorization
- 🔄 Real-time notifications
- 🔄 Advanced reporting features

### Phase 3 (Future)
- ⏳ Mobile application
- ⏳ Advanced analytics dashboard
- ⏳ Integration with external services
- ⏳ Multi-language support

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation for common solutions

## Acknowledgments

- React community for excellent documentation
- Bootstrap team for the UI framework
- All contributors and supporters of this project
#   T e s t   p i p e l i n e   t r i g g e r 
 

 
