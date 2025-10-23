import React from 'react';
import { Navbar, Container, Nav, Dropdown } from 'react-bootstrap';
import { FaUser, FaSignOutAlt, FaHome } from 'react-icons/fa';
import { useAuth } from '../../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import './CustomerNavbar.css';

const CustomerNavbar = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <Navbar 
      expand="lg" 
      style={{
        background: 'linear-gradient(90deg, #1a237e 0%, #0d47a1 100%)',
        boxShadow: '0 2px 10px rgba(0,0,0,0.1)',
        padding: '12px 0'
      }}
    >
      <Container fluid>
        <Navbar.Brand 
          href="/customer" 
          style={{
            display: 'flex',
            alignItems: 'center',
            fontSize: '1.4rem',
            fontWeight: 'bold',
            color: 'white'
          }}
        >
          <FaHome style={{ color: 'white', marginRight: '10px', fontSize: '1.5rem' }} />
          <span style={{ color: 'white' }}>SkyNest Hotels</span>
        </Navbar.Brand>

        <Navbar.Toggle aria-controls="customer-navbar" style={{ borderColor: 'rgba(255,255,255,0.3)' }} />
        
        <Navbar.Collapse id="customer-navbar" className="justify-content-end">
          <Nav>
            <Dropdown align="end">
              <Dropdown.Toggle 
                style={{
                  background: 'rgba(255, 255, 255, 0.2)',
                  border: '1px solid rgba(255, 255, 255, 0.3)',
                  color: 'white',
                  fontWeight: '500',
                  padding: '8px 16px',
                  borderRadius: '6px',
                  fontSize: '1rem',
                  transition: 'all 0.3s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = 'rgba(255, 255, 255, 0.3)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'rgba(255, 255, 255, 0.2)';
                }}
                id="user-dropdown"
              >
                <FaUser className="me-2" />
                {user?.name || user?.username}
              </Dropdown.Toggle>

              <Dropdown.Menu>
                <Dropdown.Item disabled>
                  <small className="text-muted">Signed in as</small>
                  <br />
                  <strong>{user?.username}</strong>
                </Dropdown.Item>
                <Dropdown.Divider />
                <Dropdown.Item onClick={handleLogout}>
                  <FaSignOutAlt className="me-2" />
                  Logout
                </Dropdown.Item>
              </Dropdown.Menu>
            </Dropdown>
          </Nav>
        </Navbar.Collapse>
      </Container>
    </Navbar>
  );
};

export default CustomerNavbar;
