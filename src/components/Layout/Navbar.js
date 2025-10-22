import React from 'react';
import { Navbar as BootstrapNavbar, Nav, Container, NavDropdown, Badge, Form } from 'react-bootstrap';
import { FaBed, FaUser, FaCog, FaSignOutAlt, FaBuilding, FaMapMarkerAlt } from 'react-icons/fa';
import { useAuth } from '../../context/AuthContext';
import { useBranch } from '../../context/BranchContext';
import { useNavigate } from 'react-router-dom';

const Navbar = () => {
  const { user, logout } = useAuth();
  const { selectedBranchId, setSelectedBranchId, branches, isLocked, selectedBranch } = useBranch();
  const navigate = useNavigate();

  // Debug logging
  console.log('🔍 Navbar Debug:');
  console.log('  - user:', user);
  console.log('  - user.role:', user?.role);
  console.log('  - user.branch_id:', user?.branch_id);
  console.log('  - isLocked:', isLocked);
  console.log('  - selectedBranchId:', selectedBranchId);
  console.log('  - selectedBranch:', selectedBranch);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const handleProfile = () => {
    navigate('/admin/profile');
  };

  const handleSettings = () => {
    navigate('/admin/settings');
  };

  // Get branch name for display
  const getCurrentBranchName = () => {
    if (selectedBranchId === 'All') return 'All Branches';
    // Use the already-calculated selectedBranch from context (handles type conversion)
    return selectedBranch ? selectedBranch.branch_name : 'Unknown Branch';
  };

  // Extra safety: Admin should NEVER be locked, regardless of isLocked value
  const shouldShowDropdown = user?.role === 'Admin' || !isLocked;

  console.log('🎨 Navbar Render Decision:', {
    userRole: user?.role,
    isAdmin: user?.role === 'Admin',
    isLocked: isLocked,
    shouldShowDropdown: shouldShowDropdown
  });

  return (
    <BootstrapNavbar bg="dark" variant="dark" expand="lg" fixed="top" className="navbar-custom">
      <Container fluid>
        <BootstrapNavbar.Brand href="/admin" className="d-flex align-items-center">
          <FaBed style={{ color: '#87CEEB' }} className="me-2" />          
          <strong style={{ color: '#87CEEB' }}>SkyNest Hotels</strong>
        </BootstrapNavbar.Brand>
        <BootstrapNavbar.Toggle aria-controls="basic-navbar-nav" />
        <BootstrapNavbar.Collapse id="basic-navbar-nav">
          <Nav className="ms-auto align-items-center">
            {user && (
              <>
                {/* Global Branch Selector - Disabled for non-admin users */}
                <div className="me-3">
                  {shouldShowDropdown ? (
                    /* Admin or unlocked - show dropdown */
                    <Form.Select 
                      value={selectedBranchId} 
                      onChange={(e) => setSelectedBranchId(e.target.value)}
                      style={{ 
                        width: '200px', 
                        backgroundColor: '#495057', 
                        color: 'white', 
                        border: '1px solid #6c757d',
                        fontSize: '14px',
                        cursor: 'pointer'
                      }}
                      title="Select branch"
                    >
                      <option value="All">🏢 All Branches</option>
                      {branches.map(branch => (
                        <option key={branch.branch_id} value={branch.branch_id}>
                          📍 {branch.branch_name}
                        </option>
                      ))}
                    </Form.Select>
                  ) : (
                    /* Locked to specific branch - show as badge */
                    <Badge 
                      bg="primary" 
                      className="px-3 py-2"
                      style={{ fontSize: '14px' }}
                    >
                      <FaMapMarkerAlt className="me-2" />
                      {getCurrentBranchName()}
                    </Badge>
                  )}
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