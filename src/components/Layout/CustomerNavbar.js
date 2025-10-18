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
    <Navbar bg="dark" variant="dark" expand="lg" className="customer-navbar shadow-sm">
      <Container fluid>
        <Navbar.Brand href="/customer" className="d-flex align-items-center">
          <div className="logo-container">
            <FaHome className="me-2" />
            <span className="brand-text">SkyNest Hotels</span>
          </div>
        </Navbar.Brand>

        <Navbar.Toggle aria-controls="customer-navbar" />
        
        <Navbar.Collapse id="customer-navbar" className="justify-content-end">
          <Nav>
            <Dropdown align="end">
              <Dropdown.Toggle variant="outline-light" id="user-dropdown" className="user-dropdown-toggle">
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
