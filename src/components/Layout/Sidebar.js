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