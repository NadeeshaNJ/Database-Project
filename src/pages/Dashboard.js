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
    <div style={{ 
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #f8f9fa 0%, #e3f2fd 100%)',
      padding: '20px'
    }}>
      <div style={{
        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
        padding: '30px',
        borderRadius: '15px',
        marginBottom: '30px',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
      }}>
        <h2 className="mb-0" style={{ color: '#FFFFFF', fontWeight: 'bold' }}>
          Dashboard Overview
        </h2>
        <p style={{ color: '#90caf9', marginBottom: 0, marginTop: '5px' }}>
          Welcome back! Here's what's happening today.
        </p>
      </div>
      
      <Row>
        {stats.map((stat, index) => {
          const IconComponent = stat.icon;
          return (
            <Col md={4} lg={2} key={index} className="mb-4">
              <Card 
                style={{ 
                  background: stat.gradient,
                  border: 'none',
                  borderRadius: '15px',
                  boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                  transition: 'transform 0.3s, box-shadow 0.3s',
                  cursor: 'pointer',
                  height: '100%'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = 'translateY(-5px)';
                  e.currentTarget.style.boxShadow = '0 8px 15px rgba(0,0,0,0.2)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = 'translateY(0)';
                  e.currentTarget.style.boxShadow = '0 4px 6px rgba(0,0,0,0.1)';
                }}
              >
                <Card.Body className="text-center" style={{ padding: '20px' }}>
                  <IconComponent 
                    size={40} 
                    style={{ color: 'white', marginBottom: '15px' }}
                  />
                  <Card.Title style={{ 
                    color: 'white', 
                    fontSize: '0.9rem',
                    fontWeight: '600',
                    marginBottom: '10px'
                  }}>
                    {stat.title}
                  </Card.Title>
                  <Card.Text style={{ 
                    color: 'white', 
                    fontSize: '1.8rem',
                    fontWeight: 'bold',
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
          <Card style={{ 
            border: 'none',
            borderRadius: '15px',
            boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
            overflow: 'hidden'
          }}>
            <Card.Header style={{
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              color: 'white',
              padding: '20px',
              border: 'none'
            }}>
              <h5 className="mb-0" style={{ fontWeight: 'bold' }}>Recent Reservations</h5>
            </Card.Header>
            <Card.Body style={{ padding: 0 }}>
              <div className="table-container">
                <table className="table table-hover mb-0">
                  <thead style={{ 
                    backgroundColor: '#f8f9fa',
                    borderBottom: '2px solid #e0e0e0'
                  }}>
                    <tr>
                      <th style={{ padding: '15px', fontWeight: '600', color: '#333' }}>Guest Name</th>
                      <th style={{ padding: '15px', fontWeight: '600', color: '#333' }}>Room</th>
                      <th style={{ padding: '15px', fontWeight: '600', color: '#333' }}>Check-in</th>
                      <th style={{ padding: '15px', fontWeight: '600', color: '#333' }}>Check-out</th>
                      <th style={{ padding: '15px', fontWeight: '600', color: '#333' }}>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recentBookings.length > 0 ? (
                      recentBookings.map((booking, idx) => (
                        <tr 
                          key={booking.booking_id} 
                          style={{ 
                            backgroundColor: idx % 2 === 0 ? '#ffffff' : '#f8f9fa',
                            transition: 'background-color 0.2s'
                          }}
                          onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#e3f2fd'}
                          onMouseLeave={(e) => e.currentTarget.style.backgroundColor = idx % 2 === 0 ? '#ffffff' : '#f8f9fa'}
                        >
                          <td style={{ padding: '15px', color: '#333' }}>{booking.guest_name}</td>
                          <td style={{ padding: '15px', color: '#333' }}>{booking.room_number}</td>
                          <td style={{ padding: '15px', color: '#333' }}>{new Date(booking.check_in_date).toLocaleDateString()}</td>
                          <td style={{ padding: '15px', color: '#333' }}>{new Date(booking.check_out_date).toLocaleDateString()}</td>
                          <td style={{ padding: '15px' }}>
                            <span className={`badge bg-${getStatusBadge(booking.status)}`}>
                              {booking.status}
                            </span>
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan="5" className="text-center" style={{ padding: '30px', color: '#999' }}>
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
          <Card style={{ 
            border: 'none',
            borderRadius: '15px',
            boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
          }}>
            <Card.Header style={{
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              color: 'white',
              padding: '20px',
              border: 'none',
              borderTopLeftRadius: '15px',
              borderTopRightRadius: '15px'
            }}>
              <h5 className="mb-0" style={{ fontWeight: 'bold' }}>Quick Actions</h5>
            </Card.Header>
            <Card.Body style={{ padding: '20px' }}>
              <div className="d-grid gap-3">
                {/* Only Admin, Manager, and Receptionist can add guests */}
                {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                  <button 
                    style={{
                      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                      border: 'none',
                      padding: '12px 20px',
                      borderRadius: '8px',
                      color: 'white',
                      fontWeight: '600',
                      transition: 'transform 0.2s, box-shadow 0.2s',
                      cursor: 'pointer'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.transform = 'translateY(-2px)';
                      e.currentTarget.style.boxShadow = '0 4px 8px rgba(102, 126, 234, 0.4)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.transform = 'translateY(0)';
                      e.currentTarget.style.boxShadow = 'none';
                    }}
                    onClick={() => setShowAddGuestModal(true)}
                  >
                    <FaUsers className="me-2" />
                    Add New Guest
                  </button>
                )}
                
                {/* Everyone except Accountant can create reservations */}
                {user && user.role !== 'Accountant' && (
                  <button 
                    style={{
                      background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                      border: 'none',
                      padding: '12px 20px',
                      borderRadius: '8px',
                      color: 'white',
                      fontWeight: '600',
                      transition: 'transform 0.2s, box-shadow 0.2s',
                      cursor: 'pointer'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.transform = 'translateY(-2px)';
                      e.currentTarget.style.boxShadow = '0 4px 8px rgba(16, 185, 129, 0.4)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.transform = 'translateY(0)';
                      e.currentTarget.style.boxShadow = 'none';
                    }}
                    onClick={() => setShowNewReservationModal(true)}
                  >
                    <FaCalendarAlt className="me-2" />
                    New Reservation
                  </button>
                )}
                
                {/* Only Admin, Manager, and Receptionist can view room status */}
                {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                  <button 
                    style={{
                      background: 'linear-gradient(135deg, #0d47a1 0%, #1976d2 100%)',
                      border: 'none',
                      padding: '12px 20px',
                      borderRadius: '8px',
                      color: 'white',
                      fontWeight: '600',
                      transition: 'transform 0.2s, box-shadow 0.2s',
                      cursor: 'pointer'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.transform = 'translateY(-2px)';
                      e.currentTarget.style.boxShadow = '0 4px 8px rgba(13, 71, 161, 0.4)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.transform = 'translateY(0)';
                      e.currentTarget.style.boxShadow = 'none';
                    }}
                    onClick={() => setShowRoomStatusModal(true)}
                  >
                    <FaBed className="me-2" />
                    Room Status
                  </button>
                )}
                
                {/* Only Admin, Manager, and Receptionist can create service requests */}
                {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                  <button 
                    style={{
                      background: 'linear-gradient(135deg, #48547C 0%, #749DD0 100%)',
                      border: 'none',
                      padding: '12px 20px',
                      borderRadius: '8px',
                      color: 'white',
                      fontWeight: '600',
                      transition: 'transform 0.2s, box-shadow 0.2s',
                      cursor: 'pointer'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.transform = 'translateY(-2px)';
                      e.currentTarget.style.boxShadow = '0 4px 8px rgba(72, 84, 124, 0.4)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.transform = 'translateY(0)';
                      e.currentTarget.style.boxShadow = 'none';
                    }}
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