import React from 'react';
import { Navbar as BootstrapNavbar, Nav, Container, NavDropdown, Badge, Form } from 'react-bootstrap';
import { FaBed, FaUser, FaCog, FaSignOutAlt, FaBuilding, FaMapMarkerAlt, FaBars } from 'react-icons/fa';
import { useAuth } from '../../context/AuthContext';
import { useBranch } from '../../context/BranchContext';
import { useNavigate } from 'react-router-dom';

const Navbar = ({ onMenuToggle }) => {
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
    <BootstrapNavbar 
      expand="lg" 
      fixed="top" 
      style={{
        background: 'linear-gradient(90deg, #1a237e 0%, #0d47a1 100%)',
        boxShadow: '0 2px 10px rgba(0,0,0,0.1)',
        padding: '8px 0'
      }}
    >
      <Container fluid>
        {/* Hamburger Menu Button for Mobile */}
        <button
          onClick={onMenuToggle}
          className="sidebar-toggle-btn"
          style={{
            background: 'transparent',
            border: 'none',
            color: 'white',
            fontSize: '1.5rem',
            cursor: 'pointer',
            marginRight: '15px',
            padding: '5px 10px',
            display: 'none'
          }}
        >
          <FaBars />
        </button>
        
        <BootstrapNavbar.Brand 
          href="/admin" 
          style={{
            display: 'flex',
            alignItems: 'center',
            fontSize: '1.4rem',
            fontWeight: 'bold',
            color: 'white'
          }}
        >
          <FaBed style={{ color: 'white', marginRight: '10px', fontSize: '1.5rem' }} />          
          <strong style={{ color: 'white' }}>SkyNest Hotels</strong>
        </BootstrapNavbar.Brand>
        <BootstrapNavbar.Toggle aria-controls="basic-navbar-nav" />
        <BootstrapNavbar.Collapse id="basic-navbar-nav">
          <Nav className="ms-auto align-items-center">
            {user && (
              <>
                {/* Global Branch Selector - Disabled for non-admin users */}
                <div className="me-3 branch-selector-wrapper">
                  {shouldShowDropdown ? (
                    /* Admin or unlocked - show dropdown */
                    <Form.Select 
                      value={selectedBranchId} 
                      onChange={(e) => setSelectedBranchId(e.target.value)}
                      className="branch-selector"
                      style={{ 
                        minWidth: '180px',
                        maxWidth: '100%',
                        backgroundColor: 'rgba(255, 255, 255, 0.2)', 
                        color: 'white', 
                        border: '1px solid rgba(255, 255, 255, 0.3)',
                        fontSize: '14px',
                        cursor: 'pointer',
                        borderRadius: '6px',
                        padding: '8px 12px',
                        fontWeight: '500'
                      }}
                      title="Select branch"
                    >
                      <option value="All" style={{ background: '#1a237e', color: 'white' }}>🏢 All Branches</option>
                      {branches.map(branch => (
                        <option key={branch.branch_id} value={branch.branch_id} style={{ background: '#1a237e', color: 'white' }}>
                          📍 {branch.branch_name}
                        </option>
                      ))}
                    </Form.Select>
                  ) : (
                    /* Locked to specific branch - show as badge */
                    <Badge 
                      style={{ 
                        fontSize: '14px',
                        background: 'rgba(255, 255, 255, 0.2)',
                        color: 'white',
                        padding: '10px 16px',
                        borderRadius: '6px',
                        fontWeight: '500',
                        border: '1px solid rgba(255, 255, 255, 0.3)'
                      }}
                    >
                      <FaMapMarkerAlt className="me-2" />
                      {getCurrentBranchName()}
                    </Badge>
                  )}
                </div>
                
                <NavDropdown 
                  title={
                    <span style={{ color: 'white', fontWeight: '500', fontSize: '1rem' }}>
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