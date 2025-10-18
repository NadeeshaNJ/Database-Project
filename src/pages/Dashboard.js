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
      color: 'primary' 
    },
    { 
      title: "Today's Check-ins", 
      value: dashboardData.today?.today_checkins || '0', 
      icon: FaCalendarAlt, 
      color: 'success' 
    },
    { 
      title: 'Available Rooms', 
      value: `${dashboardData.rooms?.available_rooms || '0'}/${dashboardData.rooms?.total_rooms || '0'}`, 
      icon: FaBed, 
      color: 'info' 
    },
    { 
      title: "Today's Check-ins", 
      value: dashboardData.today?.today_checkins || '0', 
      icon: FaConciergeBell, 
      color: 'warning' 
    },
    { 
      title: 'Monthly Revenue', 
      value: `Rs ${parseFloat(dashboardData.monthly?.monthly_revenue || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}`, 
      icon: FaDollarSign, 
      color: 'success' 
    },
    { 
      title: 'Monthly Bookings', 
      value: dashboardData.monthly?.monthly_bookings || '0', 
      icon: FaChartLine, 
      color: 'primary' 
    }
  ];

  const rowStyle = {
    backgroundColor: '#AAA59F'
  };

  return (
    <div>
      <h2 className="mb-4" style={{ color: '#FFFFFF' }}>Dashboard</h2>
      
      <Row>
        {stats.map((stat, index) => {
          const IconComponent = stat.icon;
          return (
            <Col md={4} lg={2} key={index} className="mb-4">
              
              <Card className="card-custom h-100" style={{ backgroundColor: '#FFFFFF', border: '2px solid #749DD0' }}>
                <Card.Body className="text-center">
                  <IconComponent 
                    size={40} 
                    className={`text-${stat.color} mb-3`} 
                  />
                  <Card.Title className="h5">{stat.title}</Card.Title>
                  <Card.Text className="h3 text-primary mb-0">
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
          <Card className="card-custom">
            <Card.Header>
              <h5 className="mb-0">Recent Reservations</h5>
            </Card.Header>
            <Card.Body>
              <div className="table-container">
                <table className="table table-hover mb-0">
                  <thead className="table-light">
                    <tr>
                      <th>Guest Name</th>
                      <th>Room</th>
                      <th>Check-in</th>
                      <th>Check-out</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recentBookings.length > 0 ? (
                      recentBookings.map((booking) => (
                        <tr key={booking.booking_id} style={rowStyle}>
                          <td>{booking.guest_name}</td>
                          <td>{booking.room_number}</td>
                          <td>{new Date(booking.check_in_date).toLocaleDateString()}</td>
                          <td>{new Date(booking.check_out_date).toLocaleDateString()}</td>
                          <td>
                            <span className={`badge bg-${getStatusBadge(booking.status)}`}>
                              {booking.status}
                            </span>
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan="5" className="text-center">No recent reservations</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </Card.Body>
          </Card>
        </Col>
        
        <Col md={4}>
          <Card className="card-custom">
            <Card.Header>
              <h5 className="mb-0">Quick Actions</h5>
            </Card.Header>
            <Card.Body>
              <div className="d-grid gap-2">
                {/* Only Admin, Manager, and Receptionist can add guests */}
                {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                  <button 
                    className="btn btn-primary-custom"
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