# Hotel Management System - Frontend

Database Lab Project in Semester 3 - Hotel Reservation and Guest Services Management System

## Overview

This is a comprehensive React-based frontend application for managing hotel operations including guest management, reservations, room management, services, and reporting. The application provides an intuitive and modern user interface for hotel staff to efficiently manage daily operations.

## Features

### 🏨 Core Management Modules
- **Dashboard**: Overview of hotel statistics and quick actions
- **Guest Management**: Add, edit, view, and search guest information
- **Reservation Management**: Handle bookings, check-ins, and check-outs
- **Room Management**: Monitor room status, availability, and pricing
- **Service Management**: Track and manage guest service requests
- **Reports & Analytics**: Generate comprehensive reports and view performance metrics

### 🎨 UI/UX Features
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Modern Interface**: Clean and professional design with Bootstrap styling
- **Interactive Components**: Dynamic forms, modals, and data tables
- **Search & Filter**: Advanced search and filtering capabilities
- **Real-time Updates**: Live status updates and notifications

### 🔧 Technical Features
- **React Router**: Client-side routing for single-page application
- **Bootstrap Integration**: Professional styling and responsive components
- **API Integration**: Ready for backend API connection
- **State Management**: Efficient state handling with React hooks
- **Error Handling**: Comprehensive error handling and user feedback
- **Utility Functions**: Helper functions for date formatting, validation, etc.

## Project Structure

```
src/
├── components/           # Reusable UI components
│   ├── Layout/          # Navigation and layout components
│   │   ├── Navbar.js    # Top navigation bar
│   │   └── Sidebar.js   # Side navigation menu
│   └── Common/          # Shared utility components
│       ├── LoadingSpinner.js
│       ├── ErrorMessage.js
│       └── ConfirmDialog.js
├── pages/               # Main application pages
│   ├── Dashboard.js     # Main dashboard with statistics
│   ├── Guests.js        # Guest management page
│   ├── Reservations.js  # Reservation management page
│   ├── Rooms.js         # Room management page
│   ├── Services.js      # Service request management
│   └── Reports.js       # Reports and analytics page
├── services/            # API integration layer
│   ├── apiClient.js     # Axios configuration and interceptors
│   └── api.js           # API endpoint functions
├── utils/               # Utility functions
│   ├── dateUtils.js     # Date formatting and calculations
│   └── helpers.js       # General helper functions
├── App.js               # Main application component
├── App.css              # Application-specific styles
├── index.js             # Application entry point
└── index.css            # Global styles
```

## Getting Started

### Prerequisites
- Node.js (version 14 or higher)
- npm or yarn package manager

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Database-Project
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   - Copy `.env` file and update API endpoints as needed
   - Set `REACT_APP_API_URL` to your backend API URL

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
- `npm run eject`: Eject from Create React App (irreversible)

## Usage Guide

### Dashboard
- View key performance indicators and statistics
- Quick access to common actions
- Recent reservations and activities overview

### Guest Management
- Add new guests with complete information
- Search and filter guest records
- Edit existing guest details
- View guest history and status

### Reservation Management
- Create new reservations
- Manage check-ins and check-outs
- Update reservation status
- View reservation analytics

### Room Management
- Monitor room availability and status
- Update room information and pricing
- Manage room amenities
- Track maintenance and cleaning status

### Service Management
- Handle guest service requests
- Assign services to staff members
- Track service completion status
- Manage service priorities

### Reports & Analytics
- Generate occupancy reports
- View revenue analytics
- Export data in various formats
- Track performance metrics

## API Integration

The application is designed to work with a RESTful backend API. Key API endpoints include:

- `GET /api/guests` - Retrieve guest list
- `POST /api/guests` - Create new guest
- `GET /api/reservations` - Retrieve reservations
- `POST /api/reservations` - Create new reservation
- `GET /api/rooms` - Retrieve room information
- `GET /api/services` - Retrieve service requests
- `GET /api/reports/dashboard` - Get dashboard statistics

Update the `REACT_APP_API_URL` in your `.env` file to connect to your backend.

## Customization

### Styling
- Modify `src/index.css` for global styles
- Update `src/App.css` for application-specific styles
- Bootstrap variables can be customized for theming

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
