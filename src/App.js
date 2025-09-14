import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Container } from 'react-bootstrap';
import Navbar from './components/Layout/Navbar';
import Sidebar from './components/Layout/Sidebar';
import Dashboard from './pages/Dashboard';
import Guests from './pages/Guests';
import Reservations from './pages/Reservations';
import Rooms from './pages/Rooms';
import Services from './pages/Services';
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
                <Route path="/guests" element={<Guests />} />
                <Route path="/reservations" element={<Reservations />} />
                <Route path="/rooms" element={<Rooms />} />
                <Route path="/services" element={<Services />} />
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