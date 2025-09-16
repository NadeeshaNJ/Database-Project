import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Container } from 'react-bootstrap';
import Navbar from './components/Layout/Navbar';
import Sidebar from './components/Layout/Sidebar';
import Dashboard from './pages/Dashboard';
import Hotels from './pages/Hotels';
import Rooms from './pages/Rooms';
import Bookings from './pages/Bookings';
import Guests from './pages/Guests';
import Services from './pages/Services';
import Billing from './pages/Billing';
import Reports from './pages/Reports';
import './App.css';

function App() {
  return (
    <Router>
      <div className="App">
        <Navbar />
        <div className="d-flex">
          <Sidebar />
          <div className="content-wrapper flex-grow-1">
            <Container fluid>
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/dashboard" element={<Dashboard />} />
                <Route path="/hotels" element={<Hotels />} />
                <Route path="/rooms" element={<Rooms />} />
                <Route path="/bookings" element={<Bookings />} />
                <Route path="/guests" element={<Guests />} />
                <Route path="/services" element={<Services />} />
                <Route path="/billing" element={<Billing />} />
                <Route path="/reports" element={<Reports />} />
              </Routes>
            </Container>
          </div>
        </div>
      </div>
    </Router>
  );
}

export default App;