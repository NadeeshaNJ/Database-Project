import React from 'react';
import { Navbar as BootstrapNavbar, Nav, Container } from 'react-bootstrap';
import { FaBed, FaUser, FaCog, FaSignOutAlt } from 'react-icons/fa';

const Navbar = () => {
  return (
    <BootstrapNavbar bg="dark" variant="dark" expand="lg" className="navbar-custom">
      <Container fluid>
        <BootstrapNavbar.Brand href="/" className="d-flex align-items-center">
          <FaBed className="me-2" />
          <strong>SkyNest Hotels</strong>
          <span className="ms-2 badge bg-primary">HRGSMS</span>
        </BootstrapNavbar.Brand>
        <BootstrapNavbar.Toggle aria-controls="basic-navbar-nav" />
        <BootstrapNavbar.Collapse id="basic-navbar-nav">
          <Nav className="ms-auto">
            <Nav.Link href="#profile" className="d-flex align-items-center">
              <FaUser className="me-1" />
              Hotel Manager
            </Nav.Link>
            <Nav.Link href="#settings" className="d-flex align-items-center">
              <FaCog className="me-1" />
              Settings
            </Nav.Link>
            <Nav.Link href="#logout" className="d-flex align-items-center">
              <FaSignOutAlt className="me-1" />
              Logout
            </Nav.Link>
          </Nav>
        </BootstrapNavbar.Collapse>
      </Container>
    </BootstrapNavbar>
  );
};

export default Navbar;