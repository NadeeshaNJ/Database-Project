import React, { useState, useEffect } from 'react';
import { Row, Col, Spinner, Alert } from 'react-bootstrap';
import { 
  FaUsers, 
  FaCalendarAlt, 
  FaBed, 
  FaConciergeBell, 
  FaDollarSign, 
  FaChartLine, 
  FaFilter, 
  FaEye, 
  FaEdit,
  FaHotel 
} from 'react-icons/fa';
import { apiUrl } from '../utils/api';
import { useBranch } from '../context/BranchContext';
import { useAuth } from '../context/AuthContext';
import AddGuestModal from '../components/Modals/AddGuestModal';
import NewReservationModal from '../components/Modals/NewReservationModal';
import RoomStatusModal from '../components/Modals/RoomStatusModal';
import ServiceRequestModal from '../components/Modals/ServiceRequestModal';

const Dashboard = () => {
  const { user } = useAuth();
  const { selectedBranchId } = useBranch();
  const [dashboardData, setDashboardData] = useState(null);
  const [recentBookings, setRecentBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  // Modal states
  const [showAddGuestModal, setShowAddGuestModal] = useState(false);
  const [showNewReservationModal, setShowNewReservationModal] = useState(false);
  const [showRoomStatusModal, setShowRoomStatusModal] = useState(false);
  const [showServiceRequestModal, setShowServiceRequestModal] = useState(false);

  // Fetch dashboard data
  useEffect(() => {
    fetchDashboardData();
    fetchRecentBookings();
  }, [selectedBranchId]);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      let url = '/api/reports/dashboard-summary';
      if (selectedBranchId && selectedBranchId !== 'All') {
        url += `?branch_id=${selectedBranchId}`;
      }
      
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success) {
        setDashboardData(data.data);
        setLoading(false);
      } else {
        throw new Error(data.message || 'Failed to fetch dashboard data');
      }
    } catch (err) {
      console.error('Error fetching dashboard data:', err);
      setError('Failed to load dashboard data. Please try again.');
      setLoading(false);
    }
  };

  const fetchRecentBookings = async () => {
    try {
      let url = '/api/bookings?limit=5&sort=created_at&order=desc';
      if (selectedBranchId && selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success && data.data && data.data.bookings) {
        setRecentBookings(data.data.bookings);
      }
    } catch (err) {
      console.error('Error fetching recent bookings:', err);
    }
  };

  const handleModalSuccess = () => {
    fetchDashboardData();
    fetchRecentBookings();
  };

  const handleQuickAction = (action) => {
    switch (action) {
      case 'addGuest':
        setShowAddGuestModal(true);
        break;
      case 'newReservation':
        setShowNewReservationModal(true);
        break;
      case 'roomStatus':
        setShowRoomStatusModal(true);
        break;
      case 'serviceRequest':
        setShowServiceRequestModal(true);
        break;
      default:
        break;
    }
  };

  if (loading || !dashboardData) {
    return (
      <div style={{
        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'white'
      }}>
        <div style={{ textAlign: 'center' }}>
          <Spinner animation="border" style={{ width: '4rem', height: '4rem', marginBottom: '20px' }} />
          <h3>Loading Dashboard...</h3>
        </div>
      </div>
    );
  }

  const stats = [
    { 
      title: 'Current Guests', 
      value: dashboardData.today?.current_guests || '0', 
      icon: FaUsers, 
      color: '#1976d2'
    },
    { 
      title: "Today's Check-ins", 
      value: dashboardData.today?.today_checkins || '0', 
      icon: FaCalendarAlt, 
      color: '#1976d2'
    },
    { 
      title: 'Available Rooms', 
      value: `${dashboardData.rooms?.available_rooms || '0'}/${dashboardData.rooms?.total_rooms || '0'}`, 
      icon: FaBed, 
      color: '#1976d2'
    },
    { 
      title: 'Pending Services', 
      value: dashboardData.today?.today_checkins || '0', 
      icon: FaConciergeBell, 
      color: '#1976d2'
    },
    { 
      title: 'Monthly Revenue', 
      value: `Rs ${parseFloat(dashboardData.monthly?.monthly_revenue || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}`, 
      icon: FaDollarSign, 
      color: '#10b981'
    },
    { 
      title: 'Monthly Bookings', 
      value: dashboardData.monthly?.monthly_bookings || '0', 
      icon: FaChartLine, 
      color: '#1976d2'
    }
  ];

  return (
    <div style={{ backgroundColor: '#f8f9fa', minHeight: '100vh' }}>
      {/* Hero Header Section - Matching Landing Page */}
      <div style={{
        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
        color: 'white',
        padding: '40px 0 30px 0',
        position: 'relative',
        overflow: 'hidden'
      }}>
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundImage: 'url(https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=1920)',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          opacity: 0.2
        }}></div>
        
        <div className="container" style={{ position: 'relative', zIndex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '10px' }}>
            <FaHotel size={50} />
            <div>
              <h1 style={{ fontSize: '2.5rem', fontWeight: 'bold', marginBottom: '8px' }}>
                Dashboard
              </h1>
              <p style={{ fontSize: '1.1rem', marginBottom: 0 }}>
                Welcome back, {user?.name || 'Admin'}! Here's your hotel overview.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="container" style={{ marginTop: '20px' }}>
          <Alert variant="danger" onClose={() => setError(null)} dismissible>
            {error}
          </Alert>
        </div>
      )}

      {/* Stats Grid */}
      <div className="container" style={{ marginTop: '30px', marginBottom: '30px' }}>
        <Row className="g-4 mb-4">
          {stats.map((stat, index) => {
            const IconComponent = stat.icon;
            return (
              <Col lg={2} md={4} sm={6} key={index}>
                <div
                  style={{
                    background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                    borderRadius: '12px',
                    padding: '24px 20px',
                    boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                    transition: 'transform 0.3s, box-shadow 0.3s',
                    cursor: 'pointer',
                    height: '100%',
                    textAlign: 'center',
                    border: '1px solid rgba(255, 255, 255, 0.1)'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.transform = 'translateY(-10px)';
                    e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.2)';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.transform = 'translateY(0)';
                    e.currentTarget.style.boxShadow = '0 4px 6px rgba(0,0,0,0.1)';
                  }}
                >
                  <div style={{ 
                    color: 'rgba(255, 255, 255, 0.9)', 
                    marginBottom: '15px',
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center'
                  }}>
                    <div style={{
                      width: '60px',
                      height: '60px',
                      background: 'rgba(255, 255, 255, 0.2)',
                      borderRadius: '12px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      backdropFilter: 'blur(10px)'
                    }}>
                      <IconComponent size={32} style={{ color: 'white' }} />
                    </div>
                  </div>
                  <div style={{
                    fontSize: '2rem',
                    fontWeight: 'bold',
                    color: 'white',
                    marginBottom: '8px'
                  }}>
                    {stat.value}
                  </div>
                  <div style={{
                    fontSize: '0.875rem',
                    color: 'rgba(255, 255, 255, 0.9)',
                    fontWeight: '600',
                    letterSpacing: '0.5px'
                  }}>
                    {stat.title}
                  </div>
                </div>
              </Col>
            );
          })}
        </Row>
      </div>

      {/* Content Section */}
      <div className="container" style={{ paddingTop: '20px', paddingBottom: '60px' }}>
        <Row className="g-4">
          <Col xl={8} lg={7}>
            {/* Recent Bookings Card - Matching Landing Page Style */}
            <div style={{
              background: 'white',
              borderRadius: '8px',
              overflow: 'hidden',
              boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
              height: '100%',
              border: '1px solid #e2e8f0'
            }}>
              <div style={{
                padding: '24px',
                borderBottom: '2px solid #1976d2',
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)'
              }}>
                <h3 style={{ 
                  margin: 0,
                  fontSize: '1.5rem',
                  fontWeight: 'bold',
                  color: 'white',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px'
                }}>
                  <FaCalendarAlt size={24} style={{ color: 'white' }} />
                  Recent Bookings
                </h3>
              </div>
              
              <div style={{ padding: '0' }}>
                {recentBookings.length > 0 ? (
                  <div style={{ maxHeight: '400px', overflowY: 'auto' }}>
                    {recentBookings.map((booking, idx) => (
                      <div 
                        key={booking.booking_id}
                        style={{
                          padding: '20px 24px',
                          borderBottom: idx === recentBookings.length - 1 ? 'none' : '1px solid #f1f5f9',
                          transition: 'background 0.2s ease',
                          cursor: 'pointer'
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.background = '#f8f9fa';
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.background = 'transparent';
                        }}
                      >
                        <div style={{ 
                          display: 'flex', 
                          alignItems: 'center', 
                          justifyContent: 'space-between',
                          flexWrap: 'wrap',
                          gap: '12px'
                        }}>
                          <div style={{ flex: 1 }}>
                            <div style={{
                              fontSize: '1.1rem',
                              fontWeight: 'bold',
                              color: '#333',
                              marginBottom: '4px'
                            }}>
                              {booking.guest_name}
                            </div>
                            <div style={{
                              fontSize: '0.9rem',
                              color: '#666',
                              display: 'flex',
                              gap: '16px',
                              flexWrap: 'wrap'
                            }}>
                              <span><strong>Room:</strong> {booking.room_number}</span>
                              <span><strong>Check-in:</strong> {new Date(booking.check_in_date).toLocaleDateString()}</span>
                              <span><strong>Check-out:</strong> {new Date(booking.check_out_date).toLocaleDateString()}</span>
                            </div>
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                            <span style={{
                              padding: '6px 12px',
                              borderRadius: '20px',
                              fontSize: '0.75rem',
                              fontWeight: 'bold',
                              textTransform: 'capitalize',
                              background: booking.status === 'Confirmed' 
                                ? '#d4edda' 
                                : booking.status === 'Pending'
                                ? '#fff3cd'
                                : '#d1ecf1',
                              color: booking.status === 'Confirmed' 
                                ? '#155724' 
                                : booking.status === 'Pending'
                                ? '#856404'
                                : '#0c5460'
                            }}>
                              {booking.status}
                            </span>
                            <div style={{ display: 'flex', gap: '8px' }}>
                              <button style={{
                                background: '#1976d2',
                                border: 'none',
                                borderRadius: '6px',
                                padding: '6px 10px',
                                color: 'white',
                                cursor: 'pointer',
                                transition: 'opacity 0.2s ease'
                              }}
                              onMouseEnter={(e) => e.target.style.opacity = '0.8'}
                              onMouseLeave={(e) => e.target.style.opacity = '1'}
                              >
                                <FaEye size={14} />
                              </button>
                              <button style={{
                                background: '#f59e0b',
                                border: 'none',
                                borderRadius: '6px',
                                padding: '6px 10px',
                                color: 'white',
                                cursor: 'pointer',
                                transition: 'opacity 0.2s ease'
                              }}
                              onMouseEnter={(e) => e.target.style.opacity = '0.8'}
                              onMouseLeave={(e) => e.target.style.opacity = '1'}
                              >
                                <FaEdit size={14} />
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div style={{ padding: '40px', textAlign: 'center', color: '#666' }}>
                    <p>No recent bookings found.</p>
                  </div>
                )}
              </div>
            </div>
          </Col>
          
          <Col xl={4} lg={5}>
            {/* Quick Actions Card - Matching Landing Page Style */}
            <div style={{
              background: 'white',
              borderRadius: '8px',
              overflow: 'hidden',
              boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
              height: '100%',
              border: '1px solid #e2e8f0'
            }}>
              <div style={{
                padding: '24px',
                borderBottom: '2px solid #1976d2',
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)'
              }}>
                <h3 style={{ 
                  margin: 0,
                  fontSize: '1.5rem',
                  fontWeight: 'bold',
                  color: 'white',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px'
                }}>
                  <FaConciergeBell size={24} style={{ color: 'white' }} />
                  Quick Actions
                </h3>
              </div>
              
              <div style={{ padding: '24px' }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  {/* Only Admin, Manager, and Receptionist can add guests */}
                  {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                    <button 
                      onClick={() => handleQuickAction('addGuest')}
                      style={{
                        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                        color: 'white',
                        border: 'none',
                        borderRadius: '8px',
                        padding: '16px 20px',
                        fontSize: '1rem',
                        fontWeight: 'bold',
                        transition: 'all 0.3s ease',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'flex-start',
                        gap: '12px',
                        cursor: 'pointer',
                        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                        width: '100%',
                        textAlign: 'left'
                      }}
                      onMouseEnter={(e) => {
                        e.target.style.transform = 'translateY(-2px)';
                        e.target.style.boxShadow = '0 4px 8px rgba(0,0,0,0.2)';
                      }}
                      onMouseLeave={(e) => {
                        e.target.style.transform = 'translateY(0)';
                        e.target.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
                      }}
                    >
                      <FaUsers size={20} />
                      <span>Add New Guest</span>
                    </button>
                  )}
                  
                  {/* Everyone except Accountant can create reservations */}
                  {user && user.role !== 'Accountant' && (
                    <button 
                      onClick={() => handleQuickAction('newReservation')}
                      style={{
                        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                        color: 'white',
                        border: 'none',
                        borderRadius: '8px',
                        padding: '16px 20px',
                        fontSize: '1rem',
                        fontWeight: 'bold',
                        transition: 'all 0.3s ease',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'flex-start',
                        gap: '12px',
                        cursor: 'pointer',
                        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                        width: '100%',
                        textAlign: 'left'
                      }}
                      onMouseEnter={(e) => {
                        e.target.style.transform = 'translateY(-2px)';
                        e.target.style.boxShadow = '0 4px 8px rgba(0,0,0,0.2)';
                      }}
                      onMouseLeave={(e) => {
                        e.target.style.transform = 'translateY(0)';
                        e.target.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
                      }}
                    >
                      <FaCalendarAlt size={20} />
                      <span>New Reservation</span>
                    </button>
                  )}
                  
                  {/* Only Admin, Manager, and Receptionist can view room status */}
                  {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                    <button 
                      onClick={() => handleQuickAction('roomStatus')}
                      style={{
                        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                        color: 'white',
                        border: 'none',
                        borderRadius: '8px',
                        padding: '16px 20px',
                        fontSize: '1rem',
                        fontWeight: 'bold',
                        transition: 'all 0.3s ease',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'flex-start',
                        gap: '12px',
                        cursor: 'pointer',
                        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                        width: '100%',
                        textAlign: 'left'
                      }}
                      onMouseEnter={(e) => {
                        e.target.style.transform = 'translateY(-2px)';
                        e.target.style.boxShadow = '0 4px 8px rgba(0,0,0,0.2)';
                      }}
                      onMouseLeave={(e) => {
                        e.target.style.transform = 'translateY(0)';
                        e.target.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
                      }}
                    >
                      <FaBed size={20} />
                      <span>Room Status</span>
                    </button>
                  )}
                  
                  {/* Only Admin, Manager, and Receptionist can create service requests */}
                  {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                    <button 
                      onClick={() => handleQuickAction('serviceRequest')}
                      style={{
                        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                        color: 'white',
                        border: 'none',
                        borderRadius: '8px',
                        padding: '16px 20px',
                        fontSize: '1rem',
                        fontWeight: 'bold',
                        transition: 'all 0.3s ease',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'flex-start',
                        gap: '12px',
                        cursor: 'pointer',
                        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                        width: '100%',
                        textAlign: 'left'
                      }}
                      onMouseEnter={(e) => {
                        e.target.style.transform = 'translateY(-2px)';
                        e.target.style.boxShadow = '0 4px 8px rgba(0,0,0,0.2)';
                      }}
                      onMouseLeave={(e) => {
                        e.target.style.transform = 'translateY(0)';
                        e.target.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
                      }}
                    >
                      <FaConciergeBell size={20} />
                      <span>Service Request</span>
                    </button>
                  )}
                </div>
              </div>
            </div>
          </Col>
        </Row>
      </div>

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