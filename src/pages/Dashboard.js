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
      <div 
        style={{ 
          minHeight: '100vh',
          background: 'linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
        }}
      >
        <div style={{
          background: 'white',
          borderRadius: '20px',
          padding: '48px 40px',
          textAlign: 'center',
          boxShadow: '0 10px 40px rgba(0, 0, 0, 0.1)',
          border: '1px solid rgba(226, 232, 240, 0.8)',
          maxWidth: '400px',
          position: 'relative'
        }}>
          <div style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            height: '4px',
            background: 'linear-gradient(90deg, #3b82f6, #1e40af, #1d4ed8)',
            borderRadius: '20px 20px 0 0'
          }} />
          
          <div style={{
            width: '56px',
            height: '56px',
            border: '4px solid #f1f5f9',
            borderTop: '4px solid #3b82f6',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
            margin: '0 auto 24px'
          }}></div>
          
          <h3 style={{ 
            color: '#1e293b',
            margin: '0 0 8px 0',
            fontSize: '1.5rem',
            fontWeight: '600'
          }}>
            Loading Dashboard
          </h3>
          <p style={{ 
            color: '#64748b',
            margin: 0,
            fontSize: '1rem'
          }}>
            Please wait while we prepare your data...
          </p>
        </div>
        
        <style>
          {`
            @keyframes spin {
              from { transform: rotate(0deg); }
              to { transform: rotate(360deg); }
            }
          `}
        </style>
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
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      padding: '24px',
      fontFamily: "'Poppins', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    }}>
      {/* Stunning Header */}
      <div style={{
        background: 'rgba(255, 255, 255, 0.15)',
        backdropFilter: 'blur(20px)',
        borderRadius: '24px',
        padding: '40px',
        marginBottom: '32px',
        border: '1px solid rgba(255, 255, 255, 0.2)',
        boxShadow: '0 8px 32px rgba(0, 0, 0, 0.1)',
        position: 'relative',
        overflow: 'hidden'
      }}>
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'linear-gradient(45deg, rgba(255,255,255,0.1) 25%, transparent 25%, transparent 75%, rgba(255,255,255,0.1) 75%)',
          backgroundSize: '20px 20px',
          opacity: 0.3
        }} />
        
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'relative' }}>
          <div>
            <h1 style={{ 
              margin: '0 0 12px 0',
              fontSize: '3rem',
              fontWeight: '800',
              background: 'linear-gradient(135deg, #fff, #f8fafc)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
              letterSpacing: '-0.02em',
              textShadow: '0 4px 8px rgba(0,0,0,0.1)'
            }}>
              Hotel Dashboard
            </h1>
            <p style={{ 
              margin: 0,
              fontSize: '1.125rem',
              color: 'rgba(255, 255, 255, 0.9)',
              fontWeight: '500'
            }}>
              Welcome back! Here's your beautiful overview for today ✨
            </p>
          </div>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '20px'
          }}>
            <div style={{
              padding: '12px 20px',
              background: 'rgba(255, 255, 255, 0.2)',
              borderRadius: '16px',
              fontSize: '0.9rem',
              color: 'white',
              fontWeight: '600',
              backdropFilter: 'blur(10px)',
              border: '1px solid rgba(255, 255, 255, 0.3)'
            }}>
              {new Date().toLocaleDateString('en-US', { 
                weekday: 'long',
                month: 'long', 
                day: 'numeric' 
              })}
            </div>
            <div style={{
              width: '60px',
              height: '60px',
              background: 'linear-gradient(135deg, #ff6b6b, #4ecdc4)',
              borderRadius: '20px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontSize: '1.25rem',
              fontWeight: '700',
              boxShadow: '0 8px 20px rgba(0, 0, 0, 0.2)',
              border: '3px solid rgba(255, 255, 255, 0.3)'
            }}>
              {user?.username?.charAt(0).toUpperCase() || 'U'}
            </div>
          </div>
        </div>
      </div>
      
      {/* Beautiful Stats Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
        gap: '24px',
        marginBottom: '40px'
      }}>
        {stats.map((stat, index) => {
          const IconComponent = stat.icon;
          const gradients = [
            { 
              bg: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              shadow: 'rgba(102, 126, 234, 0.4)',
              icon: '#fff'
            },
            { 
              bg: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
              shadow: 'rgba(240, 147, 251, 0.4)',
              icon: '#fff'
            },
            { 
              bg: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
              shadow: 'rgba(79, 172, 254, 0.4)',
              icon: '#fff'
            },
            { 
              bg: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
              shadow: 'rgba(67, 233, 123, 0.4)',
              icon: '#fff'
            },
            { 
              bg: 'linear-gradient(135deg, #fa709a 0%, #fee140 100%)',
              shadow: 'rgba(250, 112, 154, 0.4)',
              icon: '#fff'
            },
            { 
              bg: 'linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)',
              shadow: 'rgba(168, 237, 234, 0.4)',
              icon: '#333'
            }
          ];
          const gradient = gradients[index % gradients.length];
          
          return (
            <div
              key={index}
              style={{
                background: gradient.bg,
                borderRadius: '24px',
                padding: '32px 24px',
                position: 'relative',
                overflow: 'hidden',
                cursor: 'pointer',
                transition: 'all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)',
                boxShadow: `0 10px 30px ${gradient.shadow}`,
                border: '1px solid rgba(255, 255, 255, 0.2)'
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-8px) scale(1.02)';
                e.currentTarget.style.boxShadow = `0 20px 40px ${gradient.shadow}`;
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0) scale(1)';
                e.currentTarget.style.boxShadow = `0 10px 30px ${gradient.shadow}`;
              }}
            >
              {/* Decorative elements */}
              <div style={{
                position: 'absolute',
                top: '-50%',
                right: '-50%',
                width: '100%',
                height: '100%',
                background: 'radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%)',
                borderRadius: '50%'
              }} />
              
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
                <div style={{
                  width: '56px',
                  height: '56px',
                  background: 'rgba(255, 255, 255, 0.2)',
                  borderRadius: '16px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  backdropFilter: 'blur(10px)',
                  border: '1px solid rgba(255, 255, 255, 0.3)'
                }}>
                  <IconComponent size={28} style={{ color: gradient.icon }} />
                </div>
                <div style={{
                  padding: '6px 12px',
                  background: 'rgba(255, 255, 255, 0.2)',
                  borderRadius: '20px',
                  fontSize: '0.75rem',
                  color: 'rgba(255, 255, 255, 0.9)',
                  fontWeight: '600',
                  textTransform: 'uppercase',
                  letterSpacing: '0.5px',
                  backdropFilter: 'blur(10px)'
                }}>
                  Live
                </div>
              </div>
              
              <div style={{
                fontSize: '2.5rem',
                fontWeight: '800',
                color: 'white',
                marginBottom: '8px',
                lineHeight: '1.1',
                textShadow: '0 2px 10px rgba(0,0,0,0.1)'
              }}>
                {stat.value}
              </div>
              
              <div style={{
                fontSize: '1rem',
                color: 'rgba(255, 255, 255, 0.9)',
                fontWeight: '600',
                lineHeight: '1.4'
              }}>
                {stat.title}
              </div>
            </div>
          );
        })}
      </div>

      {/* Professional Content Layout */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '32px' }}>
        {/* Reservations Table */}
        <div style={{
          background: 'white',
          borderRadius: '16px',
          overflow: 'hidden',
          boxShadow: '0 4px 20px rgba(0, 0, 0, 0.08)',
          border: '1px solid rgba(226, 232, 240, 0.8)'
        }}>
          <div style={{
            background: 'linear-gradient(135deg, #f8fafc, #f1f5f9)',
            padding: '24px 32px',
            borderBottom: '1px solid #e2e8f0'
          }}>
            <h3 style={{ 
              margin: 0,
              fontSize: '1.25rem',
              fontWeight: '600',
              color: '#1e293b',
              display: 'flex',
              alignItems: 'center',
              gap: '12px'
            }}>
              <FaCalendarAlt size={20} style={{ color: '#3b82f6' }} />
              Recent Reservations
            </h3>
          </div>
          
          <div style={{ padding: '0' }}>
            {recentBookings.length > 0 ? (
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ background: '#f8fafc' }}>
                      <th style={{ 
                        padding: '16px 24px', 
                        textAlign: 'left',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#475569',
                        borderBottom: '1px solid #e2e8f0'
                      }}>Guest</th>
                      <th style={{ 
                        padding: '16px 24px', 
                        textAlign: 'left',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#475569',
                        borderBottom: '1px solid #e2e8f0'
                      }}>Room</th>
                      <th style={{ 
                        padding: '16px 24px', 
                        textAlign: 'left',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#475569',
                        borderBottom: '1px solid #e2e8f0'
                      }}>Check-in</th>
                      <th style={{ 
                        padding: '16px 24px', 
                        textAlign: 'left',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#475569',
                        borderBottom: '1px solid #e2e8f0'
                      }}>Check-out</th>
                      <th style={{ 
                        padding: '16px 24px', 
                        textAlign: 'left',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#475569',
                        borderBottom: '1px solid #e2e8f0'
                      }}>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recentBookings.map((booking, idx) => (
                      <tr 
                        key={booking.booking_id}
                        style={{ 
                          borderBottom: '1px solid #f1f5f9',
                          transition: 'background-color 0.2s ease'
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.backgroundColor = '#f8fafc';
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.backgroundColor = 'transparent';
                        }}
                      >
                        <td style={{ 
                          padding: '16px 24px',
                          fontSize: '0.875rem',
                          fontWeight: '600',
                          color: '#1e293b'
                        }}>
                          {booking.guest_name}
                        </td>
                        <td style={{ 
                          padding: '16px 24px',
                          fontSize: '0.875rem',
                          color: '#64748b'
                        }}>
                          {booking.room_number}
                        </td>
                        <td style={{ 
                          padding: '16px 24px',
                          fontSize: '0.875rem',
                          color: '#64748b'
                        }}>
                          {new Date(booking.check_in_date).toLocaleDateString()}
                        </td>
                        <td style={{ 
                          padding: '16px 24px',
                          fontSize: '0.875rem',
                          color: '#64748b'
                        }}>
                          {new Date(booking.check_out_date).toLocaleDateString()}
                        </td>
                        <td style={{ padding: '16px 24px' }}>
                          <span style={{
                            padding: '6px 12px',
                            borderRadius: '6px',
                            fontSize: '0.75rem',
                            fontWeight: '600',
                            textTransform: 'uppercase',
                            letterSpacing: '0.05em',
                            background: booking.status === 'Confirmed' 
                              ? '#dcfce7' : booking.status === 'Pending' 
                              ? '#fef3c7' : '#dbeafe',
                            color: booking.status === 'Confirmed' 
                              ? '#16a34a' : booking.status === 'Pending' 
                              ? '#ca8a04' : '#2563eb'
                          }}>
                            {booking.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div style={{
                textAlign: 'center',
                padding: '80px 40px',
                color: '#94a3b8'
              }}>
                <FaCalendarAlt size={48} style={{ color: '#d1d5db', marginBottom: '16px' }} />
                <h4 style={{ 
                  margin: '0 0 8px 0',
                  fontSize: '1.125rem',
                  fontWeight: '600',
                  color: '#64748b'
                }}>
                  No Recent Reservations
                </h4>
                <p style={{ margin: 0, fontSize: '0.875rem' }}>
                  New reservations will appear here
                </p>
              </div>
            )}
          </div>
        </div>
        
        {/* Professional Actions Panel */}
        <div style={{
          background: 'white',
          borderRadius: '16px',
          overflow: 'hidden',
          boxShadow: '0 4px 20px rgba(0, 0, 0, 0.08)',
          border: '1px solid rgba(226, 232, 240, 0.8)',
          height: 'fit-content'
        }}>
          <div style={{
            background: 'linear-gradient(135deg, #f8fafc, #f1f5f9)',
            padding: '24px 32px',
            borderBottom: '1px solid #e2e8f0'
          }}>
            <h3 style={{ 
              margin: 0,
              fontSize: '1.25rem',
              fontWeight: '600',
              color: '#1e293b',
              display: 'flex',
              alignItems: 'center',
              gap: '12px'
            }}>
              <FaConciergeBell size={20} style={{ color: '#3b82f6' }} />
              Quick Actions
            </h3>
          </div>
          
          <div style={{ padding: '32px' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {/* Only Admin, Manager, and Receptionist can add guests */}
              {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                <button 
                  style={{
                    background: 'linear-gradient(135deg, #3b82f6, #2563eb)',
                    color: 'white',
                    border: 'none',
                    borderRadius: '12px',
                    padding: '16px 20px',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'flex-start',
                    gap: '12px',
                    cursor: 'pointer',
                    boxShadow: '0 4px 12px rgba(59, 130, 246, 0.25)',
                    width: '100%'
                  }}
                  onClick={() => setShowAddGuestModal(true)}
                  onMouseEnter={(e) => {
                    e.target.style.transform = 'translateY(-2px)';
                    e.target.style.boxShadow = '0 8px 20px rgba(59, 130, 246, 0.35)';
                  }}
                  onMouseLeave={(e) => {
                    e.target.style.transform = 'translateY(0)';
                    e.target.style.boxShadow = '0 4px 12px rgba(59, 130, 246, 0.25)';
                  }}
                >
                  <FaUsers size={18} />
                  <span>Add New Guest</span>
                </button>
              )}
              
              {/* Everyone except Accountant can create reservations */}
              {user && user.role !== 'Accountant' && (
                <button 
                  style={{
                    background: 'linear-gradient(135deg, #10b981, #059669)',
                    color: 'white',
                    border: 'none',
                    borderRadius: '12px',
                    padding: '16px 20px',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'flex-start',
                    gap: '12px',
                    cursor: 'pointer',
                    boxShadow: '0 4px 12px rgba(16, 185, 129, 0.25)',
                    width: '100%'
                  }}
                  onClick={() => setShowNewReservationModal(true)}
                  onMouseEnter={(e) => {
                    e.target.style.transform = 'translateY(-2px)';
                    e.target.style.boxShadow = '0 8px 20px rgba(16, 185, 129, 0.35)';
                  }}
                  onMouseLeave={(e) => {
                    e.target.style.transform = 'translateY(0)';
                    e.target.style.boxShadow = '0 4px 12px rgba(16, 185, 129, 0.25)';
                  }}
                >
                  <FaCalendarAlt size={18} />
                  <span>New Reservation</span>
                </button>
              )}
              
              {/* Only Admin, Manager, and Receptionist can view room status */}
              {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                <button 
                  style={{
                    background: 'linear-gradient(135deg, #8b5cf6, #7c3aed)',
                    color: 'white',
                    border: 'none',
                    borderRadius: '12px',
                    padding: '16px 20px',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'flex-start',
                    gap: '12px',
                    cursor: 'pointer',
                    boxShadow: '0 4px 12px rgba(139, 92, 246, 0.25)',
                    width: '100%'
                  }}
                  onClick={() => setShowRoomStatusModal(true)}
                  onMouseEnter={(e) => {
                    e.target.style.transform = 'translateY(-2px)';
                    e.target.style.boxShadow = '0 8px 20px rgba(139, 92, 246, 0.35)';
                  }}
                  onMouseLeave={(e) => {
                    e.target.style.transform = 'translateY(0)';
                    e.target.style.boxShadow = '0 4px 12px rgba(139, 92, 246, 0.25)';
                  }}
                >
                  <FaBed size={18} />
                  <span>Room Status</span>
                </button>
              )}
              
              {/* Only Admin, Manager, and Receptionist can create service requests */}
              {user && ['Admin', 'Manager', 'Receptionist'].includes(user.role) && (
                <button 
                  style={{
                    background: 'linear-gradient(135deg, #f59e0b, #d97706)',
                    color: 'white',
                    border: 'none',
                    borderRadius: '12px',
                    padding: '16px 20px',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'flex-start',
                    gap: '12px',
                    cursor: 'pointer',
                    boxShadow: '0 4px 12px rgba(245, 158, 11, 0.25)',
                    width: '100%'
                  }}
                  onClick={() => setShowServiceRequestModal(true)}
                  onMouseEnter={(e) => {
                    e.target.style.transform = 'translateY(-2px)';
                    e.target.style.boxShadow = '0 8px 20px rgba(245, 158, 11, 0.35)';
                  }}
                  onMouseLeave={(e) => {
                    e.target.style.transform = 'translateY(0)';
                    e.target.style.boxShadow = '0 4px 12px rgba(245, 158, 11, 0.25)';
                  }}
                >
                  <FaConciergeBell size={18} />
                  <span>Service Request</span>
                </button>
              )}
            </div>
          </div>
        </div>
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