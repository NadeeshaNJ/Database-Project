import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Spinner } from 'react-bootstrap';
import { FaUsers, FaCalendarAlt, FaBed, FaConciergeBell, FaDollarSign, FaChartLine } from 'react-icons/fa';
import { apiUrl } from '../utils/api';
import { useBranch } from '../context/BranchContext';
import { useAuth } from '../context/AuthContext';
import AddGuestModal from '../components/Modals/AddGuestModal';
import NewReservationModal from '../components/Modals/NewReservationModal';
import RoomStatusModal from '../components/Modals/RoomStatusModal';
import ServiceRequestModal from '../components/Modals/ServiceRequestModal';

const Dashboard = () => {
  const { selectedBranchId } = useBranch();
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [dashboardData, setDashboardData] = useState(null);
  const [recentBookings, setRecentBookings] = useState([]);
  
  // Debug: Log user role
  useEffect(() => {
    if (user) {
      console.log('👤 Dashboard User Info:');
      console.log('- Full User Object:', user);
      console.log('- Role:', user.role);
      console.log('- Username:', user.username);
    }
  }, [user]);
  
  // Modal states
  const [showAddGuestModal, setShowAddGuestModal] = useState(false);
  const [showNewReservationModal, setShowNewReservationModal] = useState(false);
  const [showRoomStatusModal, setShowRoomStatusModal] = useState(false);
  const [showServiceRequestModal, setShowServiceRequestModal] = useState(false);

  useEffect(() => {
    fetchDashboardData();
    fetchRecentBookings();
  }, [selectedBranchId]);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      let url = '/api/reports/dashboard-summary';
      if (selectedBranchId !== 'All') {
        url += `?branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      if (data.success) {
        setDashboardData(data.data);
      }
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchRecentBookings = async () => {
    try {
      let url = '/api/bookings?limit=5&sort=created_at&order=desc';
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      if (data.success && data.data && data.data.bookings) {
        setRecentBookings(data.data.bookings);
      }
    } catch (error) {
      console.error('Error fetching recent bookings:', error);
    }
  };

  const handleModalSuccess = () => {
    // Refresh dashboard data after successful action
    fetchDashboardData();
    fetchRecentBookings();
  };

  const getStatusBadge = (status) => {
    const statusColors = {
      'Confirmed': 'success',
      'Checked-in': 'primary',
      'Checked-out': 'secondary',
      'Cancelled': 'danger',
      'Pending': 'warning'
    };
    return statusColors[status] || 'secondary';
  };

  if (loading || !dashboardData) {
    return (
      <div className="text-center py-5">
        <Spinner animation="border" />
        <p className="mt-3">Loading dashboard...</p>
      </div>
    );
  }

  const stats = [
    { 
      title: 'Current Guests', 
      value: dashboardData.today?.current_guests || '0', 
      icon: FaUsers, 
      color: '#667eea',
      gradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
    },
    { 
      title: "Today's Check-ins", 
      value: dashboardData.today?.today_checkins || '0', 
      icon: FaCalendarAlt, 
      color: '#0d47a1',
      gradient: 'linear-gradient(135deg, #0d47a1 0%, #1976d2 100%)'
    },
    { 
      title: 'Available Rooms', 
      value: `${dashboardData.rooms?.available_rooms || '0'}/${dashboardData.rooms?.total_rooms || '0'}`, 
      icon: FaBed, 
      color: '#1a237e',
      gradient: 'linear-gradient(135deg, #1a237e 0%, #283593 100%)'
    },
    { 
      title: 'Pending Services', 
      value: dashboardData.today?.today_checkins || '0', 
      icon: FaConciergeBell, 
      color: '#48547C',
      gradient: 'linear-gradient(135deg, #48547C 0%, #749DD0 100%)'
    },
    { 
      title: 'Monthly Revenue', 
      value: `Rs ${parseFloat(dashboardData.monthly?.monthly_revenue || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}`, 
      icon: FaDollarSign, 
      color: '#10b981',
      gradient: 'linear-gradient(135deg, #10b981 0%, #059669 100%)'
    },
    { 
      title: 'Monthly Bookings', 
      value: dashboardData.monthly?.monthly_bookings || '0', 
      icon: FaChartLine, 
      color: '#667eea',
      gradient: 'linear-gradient(135deg, #764ba2 0%, #667eea 100%)'
    }
  ];

  return (
    <div style={{ minHeight: '100vh', padding: '20px' }}>
      {/* Page Header */}
      <div className="page-header">
        <h2>Dashboard Overview</h2>
        <p>Welcome back! Here's what's happening today.</p>
      </div>
      
      <Row>
        {stats.map((stat, index) => {
          const IconComponent = stat.icon;
          return (
            <Col md={4} lg={2} key={index} className="mb-4">
              <Card className="stat-card h-100" style={{ cursor: 'pointer' }}>
                <Card.Body className="text-center" style={{ padding: '24px 16px' }}>
                  <div style={{
                    width: '60px',
                    height: '60px',
                    margin: '0 auto 16px',
                    background: 'rgba(255, 255, 255, 0.2)',
                    borderRadius: '16px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <IconComponent size={30} style={{ color: 'white' }} />
                  </div>
                  <Card.Title style={{ 
                    color: 'rgba(255, 255, 255, 0.9)', 
                    fontSize: '0.85rem',
                    fontWeight: '600',
                    marginBottom: '12px'
                  }}>
                    {stat.title}
                  </Card.Title>
                  <Card.Text style={{ 
                    color: 'white', 
                    fontSize: '1.6rem',
                    fontWeight: '700',
                    marginBottom: 0
                  }}>
                    {stat.value}
                  </Card.Text>
                </Card.Body>
              </Card>
            </Col>
          );
        })}
      </Row>

      <Row className="mt-4">
        <Col md={8}>
          <Card className="h-100">
            <Card.Header style={{ background: '#f8f9fa', borderBottom: '1px solid #e0e6ed' }}>
              <h5 className="mb-0" style={{ fontWeight: '700', color: '#2c3e50' }}>
                Recent Reservations
              </h5>
            </Card.Header>
            <Card.Body style={{ padding: '20px' }}>
              <div style={{ overflowX: 'auto' }}>
                <table className="table table-hover mb-0">
                  <thead style={{ backgroundColor: '#f8f9fa', borderBottom: '2px solid #e0e6ed' }}>
                    <tr>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Guest Name</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Room</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Check-in</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Check-out</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recentBookings.length > 0 ? (
                      recentBookings.map((booking, idx) => (
                        <tr key={booking.booking_id} style={{ borderBottom: '1px solid #e0e6ed' }}>
                          <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>{booking.guest_name}</td>
                          <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>{booking.room_number}</td>
                          <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>{new Date(booking.check_in_date).toLocaleDateString()}</td>
                          <td style={{ padding: '16px', color: '#2c3e50', fontWeight: '500' }}>{new Date(booking.check_out_date).toLocaleDateString()}</td>
                          <td style={{ padding: '16px' }}>
                            <span className={`badge bg-${booking.status === 'Confirmed' ? 'success' : booking.status === 'Pending' ? 'warning' : 'info'}`}>
                              {booking.status}
                            </span>
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan="5" className="text-center" style={{ padding: '40px', color: '#7f8c8d' }}>
                          No recent reservations
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={4}>
          <Card className="h-100">
            <Card.Header style={{ background: '#f8f9fa', borderBottom: '1px solid #e0e6ed' }}>
              <h5 className="mb-0" style={{ fontWeight: '700', color: '#2c3e50' }}>
                Quick Actions
              </h5>
            </Card.Header>
            <Card.Body style={{ padding: '20px' }}>
              <div className="d-grid gap-3">
                {/* Only Admin, Manager, and Receptionist can add guests */}
                {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                  <button 
                    className="btn btn-primary"
                    onClick={() => setShowAddGuestModal(true)}
                  >
                    <FaUsers className="me-2" />
                    Add New Guest
                  </button>
                )}
                
                {/* Everyone except Accountant can create reservations */}
                {user && user.role !== 'Accountant' && (
                  <button 
                    className="btn btn-success"
                    onClick={() => setShowNewReservationModal(true)}
                  >
                    <FaCalendarAlt className="me-2" />
                    New Reservation
                  </button>
                )}
                
                {/* Only Admin, Manager, and Receptionist can view room status */}
                {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                  <button 
                    className="btn btn-info"
                    onClick={() => setShowRoomStatusModal(true)}
                  >
                    <FaBed className="me-2" />
                    Room Status
                  </button>
                )}
                
                {/* Only Admin, Manager, and Receptionist can create service requests */}
                {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                  <button 
                    className="btn btn-warning"
                    onClick={() => setShowServiceRequestModal(true)}
                  >
                    <FaConciergeBell className="me-2" />
                    Service Request
                  </button>
                )}
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Modals */}
      <AddGuestModal 
        show={showAddGuestModal} 
        onHide={() => setShowAddGuestModal(false)}
        onSuccess={handleModalSuccess}
      />
      <NewReservationModal 
        show={showNewReservationModal} 
        onHide={() => setShowNewReservationModal(false)}
        onSuccess={handleModalSuccess}
      />
      <RoomStatusModal 
        show={showRoomStatusModal} 
        onHide={() => setShowRoomStatusModal(false)}
      />
      <ServiceRequestModal 
        show={showServiceRequestModal} 
        onHide={() => setShowServiceRequestModal(false)}
        onSuccess={handleModalSuccess}
      />
    </div>
  );
};

export default Dashboard;