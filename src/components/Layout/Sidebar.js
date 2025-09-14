import React from 'react';
import { Nav } from 'react-bootstrap';
import { Link, useLocation } from 'react-router-dom';
import { 
  FaTachometerAlt, 
  FaUsers, 
  FaCalendarAlt, 
  FaBed, 
  FaConciergeBell, 
  FaChartBar 
} from 'react-icons/fa';

const Sidebar = () => {
  const location = useLocation();

  const menuItems = [
    { path: '/dashboard', icon: FaTachometerAlt, label: 'Dashboard' },
    { path: '/guests', icon: FaUsers, label: 'Guests' },
    { path: '/reservations', icon: FaCalendarAlt, label: 'Reservations' },
    { path: '/rooms', icon: FaBed, label: 'Rooms' },
    { path: '/services', icon: FaConciergeBell, label: 'Services' },
    { path: '/reports', icon: FaChartBar, label: 'Reports' }
  ];

  return (
    <div className="sidebar">
      <Nav className="flex-column">
        {menuItems.map((item, index) => {
          const IconComponent = item.icon;
          const isActive = location.pathname === item.path;
          
          return (
            <Link
              key={index}
              to={item.path}
              className={`nav-link-sidebar ${isActive ? 'active' : ''}`}
            >
              <IconComponent className="me-2" />
              {item.label}
            </Link>
          );
        })}
      </Nav>
    </div>
  );
};

export default Sidebar;