import React from 'react';
import { Navbar as BootstrapNavbar, Nav, Container, NavDropdown, Badge, Form } from 'react-bootstrap';
import { FaBed, FaUser, FaCog, FaSignOutAlt, FaBuilding, FaMapMarkerAlt } from 'react-icons/fa';
import { useAuth } from '../../context/AuthContext';
import { useBranch } from '../../context/BranchContext';
import { useNavigate } from 'react-router-dom';

const Navbar = () => {
  const { user, logout } = useAuth();
  const { selectedBranchId, setSelectedBranchId, branches } = useBranch();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const handleProfile = () => {
    navigate('/profile');
  };

  const handleSettings = () => {
    navigate('/settings');
  };

  return (
    <BootstrapNavbar bg="dark" variant="dark" expand="lg" fixed="top" className="navbar-custom">
      <Container fluid>
        <BootstrapNavbar.Brand href="/" className="d-flex align-items-center">
          <FaBed className="me-2" />
          <strong>SkyNest Hotels</strong>
        </BootstrapNavbar.Brand>
        <BootstrapNavbar.Toggle aria-controls="basic-navbar-nav" />
        <BootstrapNavbar.Collapse id="basic-navbar-nav">
          <Nav className="ms-auto align-items-center">
            {user && (
              <>
                {/* Global Branch Selector */}
                <div className="me-3">
                  <Form.Select 
                    value={selectedBranchId} 
                    onChange={(e) => setSelectedBranchId(e.target.value)}
                    style={{ 
                      width: '200px', 
                      backgroundColor: '#495057', 
                      color: 'white', 
                      border: '1px solid #6c757d',
                      fontSize: '14px'
                    }}
                  >
                    <option value="All">🏢 All Branches</option>
                    {branches.map(branch => (
                      <option key={branch.branch_id} value={branch.branch_id}>
                        📍 {branch.branch_name}
                      </option>
                    ))}
                  </Form.Select>
                </div>
                
                <NavDropdown 
                  title={
                    <span className="text-light">
                      <FaUser className="me-2" />
                      {user.name}
                    </span>
                  } 
                  id="user-dropdown"
                  align="end"
                >
                  <NavDropdown.Item onClick={handleProfile}>
                    <FaUser className="me-2" />
                    My Profile
                  </NavDropdown.Item>
                  <NavDropdown.Item onClick={handleSettings}>
                    <FaCog className="me-2" />
                    Settings
                  </NavDropdown.Item>
                  <NavDropdown.Divider />
                  <NavDropdown.Item onClick={handleLogout}>
                    <FaSignOutAlt className="me-2" />
                    Logout
                  </NavDropdown.Item>
                </NavDropdown>
              </>
            )}
          </Nav>
        </BootstrapNavbar.Collapse>
      </Container>
    </BootstrapNavbar>
  );
};

export default Navbar;