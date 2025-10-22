import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Container } from 'react-bootstrap';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import CustomerRoute from './components/CustomerRoute';
import AdminRoute from './components/AdminRoute';
import Navbar from './components/Layout/Navbar';
import Sidebar from './components/Layout/Sidebar';
import CustomerNavbar from './components/Layout/CustomerNavbar';
import Landing from './pages/Landing';
import Login from './pages/Login';
import Register from './pages/Register';
import Profile from './pages/Profile';
import Settings from './pages/Settings';
import Dashboard from './pages/Dashboard';
import Hotels from './pages/Hotels';
import Rooms from './pages/Rooms';
import Bookings from './pages/Bookings';
import Guests from './pages/Guests';
import Employees from './pages/Employees';
import Services from './pages/Services';
import Billing from './pages/Billing';
import Reports from './pages/Reports';
import CustomerPortal from './pages/CustomerPortal';
import './App.css';

function App() {
  return (
    <Router>
      <AuthProvider>
  <div className="App">
          <Routes>
            {/* Public Routes */}
            <Route path="/" element={<Landing />} />
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            
            {/* Customer Portal - Only for Customer role */}
            <Route path="/customer/*" element={
              <CustomerRoute>
                <CustomerNavbar />
                <Routes>
                  <Route path="/" element={<CustomerPortal />} />
                  <Route path="/booking" element={<CustomerPortal />} />
                  <Route path="*" element={<Navigate to="/customer" replace />} />
                </Routes>
              </CustomerRoute>
            } />

            {/* Admin Dashboard - For all roles EXCEPT Customer */}
            <Route path="/admin/*" element={
              <AdminRoute>
                <Navbar />
                <div className="d-flex">
                  <Sidebar />
                  <div className="content-wrapper flex-grow-1">
                    <Container fluid>
                      <Routes>
                        <Route path="/" element={<Dashboard />} />
                        <Route path="/dashboard" element={<Dashboard />} />
                        <Route path="/profile" element={<Profile />} />
                        <Route path="/settings" element={<Settings />} />
                        <Route path="/hotels" element={<Hotels />} />
                        <Route path="/rooms" element={<Rooms />} />
                        <Route path="/bookings" element={<Bookings />} />
                        <Route path="/guests" element={<Guests />} />
                        <Route path="/employees" element={<Employees />} />
                        <Route path="/services" element={<Services />} />
                        <Route path="/billing" element={<Billing />} />
                        <Route path="/reports" element={<Reports />} />
                        <Route path="*" element={<Navigate to="/admin" replace />} />
                      </Routes>
                    </Container>
                  </div>
                </div>
              </AdminRoute>
            } />
          </Routes>
        </div>
      </AuthProvider>
    </Router>
  );
}

export default App;