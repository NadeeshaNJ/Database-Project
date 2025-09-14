import React from 'react';
import { Navbar as BootstrapNavbar, Nav, Container } from 'react-bootstrap';
import { FaHotel, FaUser, FaCog } from 'react-icons/fa';

const Navbar = () => {
  return (
    <BootstrapNavbar bg="dark" variant="dark" expand="lg" className="navbar-custom">
      <Container fluid>
        <BootstrapNavbar.Brand href="/" className="d-flex align-items-center">
          <FaHotel className="me-2" />
          Hotel Management System
        </BootstrapNavbar.Brand>
        <BootstrapNavbar.Toggle aria-controls="basic-navbar-nav" />
        <BootstrapNavbar.Collapse id="basic-navbar-nav">
          <Nav className="ms-auto">
            <Nav.Link href="#profile" className="d-flex align-items-center">
              <FaUser className="me-1" />
              Profile
            </Nav.Link>
            <Nav.Link href="#settings" className="d-flex align-items-center">
              <FaCog className="me-1" />
              Settings
            </Nav.Link>
          </Nav>
        </BootstrapNavbar.Collapse>
      </Container>
    </BootstrapNavbar>
  );
};

export default Navbar;