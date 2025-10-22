import React from 'react';
import { Nav } from 'react-bootstrap';
import { Link, useLocation } from 'react-router-dom';
import { 
  FaTachometerAlt, 
  FaBuilding,
  FaBed, 
  FaCalendarCheck,
  FaUsers, 
  FaUserTie,
  FaConciergeBell, 
  FaReceipt,
  FaChartBar 
} from 'react-icons/fa';

const Sidebar = () => {
  const location = useLocation();

  const menuItems = [
    { path: '/admin/dashboard', icon: FaTachometerAlt, label: 'Dashboard' },
    { path: '/admin/hotels', icon: FaBuilding, label: 'Hotel Branches' },
    { path: '/admin/rooms', icon: FaBed, label: 'Rooms' },
    { path: '/admin/bookings', icon: FaCalendarCheck, label: 'Bookings' },
    { path: '/admin/guests', icon: FaUsers, label: 'Guests' },
    { path: '/admin/employees', icon: FaUserTie, label: 'Employees' },
    { path: '/admin/services', icon: FaConciergeBell, label: 'Services' },
    { path: '/admin/billing', icon: FaReceipt, label: 'Billing' },
    { path: '/admin/reports', icon: FaChartBar, label: 'Reports' }
  ];

  return (
    <div style={{
      background: 'linear-gradient(180deg, #1a237e 0%, #0d47a1 100%)',
      minHeight: '100vh',
      width: '250px',
      position: 'fixed',
      left: 0,
      top: '56px',
      bottom: 0,
      overflowY: 'auto',
      boxShadow: '2px 0 10px rgba(0,0,0,0.1)',
      zIndex: 1000
    }}>
      <Nav className="flex-column" style={{ padding: '20px 0' }}>
        {menuItems.map((item, index) => {
          const IconComponent = item.icon;
          const isActive = location.pathname === item.path;
          
          return (
            <Link
              key={index}
              to={item.path}
              style={{
                display: 'flex',
                alignItems: 'center',
                padding: '14px 24px',
                color: isActive ? 'white' : 'rgba(255, 255, 255, 0.8)',
                textDecoration: 'none',
                fontSize: '1rem',
                fontWeight: isActive ? '600' : '500',
                background: isActive ? 'rgba(255, 255, 255, 0.15)' : 'transparent',
                borderLeft: isActive ? '4px solid #1976d2' : '4px solid transparent',
                transition: 'all 0.3s ease',
                marginBottom: '4px'
              }}
              onMouseEnter={(e) => {
                if (!isActive) {
                  e.currentTarget.style.background = 'rgba(255, 255, 255, 0.1)';
                  e.currentTarget.style.color = 'white';
                  e.currentTarget.style.paddingLeft = '28px';
                }
              }}
              onMouseLeave={(e) => {
                if (!isActive) {
                  e.currentTarget.style.background = 'transparent';
                  e.currentTarget.style.color = 'rgba(255, 255, 255, 0.8)';
                  e.currentTarget.style.paddingLeft = '24px';
                }
              }}
            >
              <IconComponent style={{ marginRight: '12px', fontSize: '1.2rem' }} />
              {item.label}
            </Link>
          );
        })}
      </Nav>
    </div>
  );
};

export default Sidebar;