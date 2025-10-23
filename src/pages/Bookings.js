import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Button, Table, Badge, Alert, Spinner } from 'react-bootstrap';
import { FaCalendarCheck, FaSearch, FaFilter } from 'react-icons/fa';
import { apiUrl } from '../utils/api';
import { useBranch } from '../context/BranchContext';

const Bookings = () => {
  const { selectedBranchId } = useBranch();
  const [bookings, setBookings] = useState([]);
  const [filterStatus, setFilterStatus] = useState('All');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Fetch bookings from backend
  useEffect(() => {
    fetchBookings();
  }, [filterStatus, selectedBranchId]);

  const fetchBookings = async () => {
    try {
      setLoading(true);
      setError('');
      
      // Build URL with filters
      let url = '/api/bookings?limit=1000';
      if (filterStatus !== 'All') {
        url += `&status=${filterStatus}`;
      }
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success && data.data && data.data.bookings) {
        // Transform backend data to match frontend format
        const transformedBookings = data.data.bookings.map(booking => ({
          id: `BK${String(booking.booking_id).padStart(3, '0')}`,
          bookingId: booking.booking_id,
          guestName: booking.guest_name,
          guestEmail: booking.guest_email,
          guestPhone: booking.guest_phone,
          hotelBranch: `SkyNest ${booking.branch_name}`,
          roomNumber: booking.room_number,
          roomType: booking.room_type,
          checkInDate: booking.check_in_date?.split('T')[0],
          checkOutDate: booking.check_out_date?.split('T')[0],
          nights: parseInt(booking.nights) || 0,
          status: booking.status,
          paymentMethod: booking.preferred_payment_method || 'N/A',
          totalAmount: parseFloat(booking.room_estimate) || 0,
          paidAmount: parseFloat(booking.advance_payment) || 0,
          discount: parseFloat(booking.discount_amount) || 0,
          lateFee: parseFloat(booking.late_fee_amount) || 0,
          bookedRate: parseFloat(booking.booked_rate) || 0,
          taxRate: parseFloat(booking.tax_rate_percent) || 0,
          bookingDate: booking.created_at?.split('T')[0],
          adults: 2, // Default values since not in database
          children: 0,
          specialRequests: ''
        }));
        
        setBookings(transformedBookings);
      } else {
        setError(data.error || 'Failed to fetch bookings');
      }
    } catch (err) {
      console.error('Error fetching bookings:', err);
      setError('Failed to connect to server. Please ensure the backend is running.');
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'Confirmed': return 'primary';
      case 'Checked-In': return 'success';
      case 'Checked-Out': return 'info';
      case 'Pending Payment': return 'warning';
      case 'Cancelled': return 'danger';
      default: return 'secondary';
    }
  };

  const getPaymentStatus = (booking) => {
    if (booking.paidAmount >= booking.totalAmount) return 'Paid';
    if (booking.paidAmount > 0) return 'Partial';
    return 'Unpaid';
  };

  const getPaymentStatusColor = (booking) => {
    const status = getPaymentStatus(booking);
    switch (status) {
      case 'Paid': return 'success';
      case 'Partial': return 'warning';
      case 'Unpaid': return 'danger';
      default: return 'secondary';
    }
  };

  const filteredBookings = filterStatus === 'All' 
    ? bookings 
    : bookings.filter(booking => booking.status === filterStatus);

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-LK', {
      style: 'currency',
      currency: 'LKR'
    }).format(amount);
  };

  return (
    <Container fluid className="py-4" style={{ 
      minHeight: '100vh',
      backgroundColor: '#f8f9fa'
    }}>
      {/* Page Header */}
      <div style={{
        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
        color: 'white',
        padding: '30px',
        borderRadius: '12px',
        marginBottom: '30px',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
      }}>
        <div>
          <h2 style={{ margin: 0, fontSize: '2rem', fontWeight: 'bold', marginBottom: '8px' }}>Bookings Management</h2>
          <p style={{ marginBottom: 0, fontSize: '1.1rem', opacity: 0.9 }}>
            Manage hotel room bookings across all SkyNest branches
          </p>
        </div>
      </div>

      {/* Booking Statistics */}
      <Row className="mb-4">
        <Col md={3}>
          <Card style={{
            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            border: 'none',
            borderRadius: '12px',
            boxShadow: '0 4px 12px rgba(26, 35, 126, 0.2)',
            color: 'white',
            height: '100%'
          }}>
            <Card.Body className="text-center">
              <h3 style={{ color: 'white', fontWeight: '700', fontSize: '2.5rem' }}>
                {bookings.length}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0, fontWeight: '500' }}>
                Total Bookings
              </p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card style={{
            background: 'linear-gradient(135deg, #1976d2 0%, #0d47a1 100%)',
            border: 'none',
            borderRadius: '12px',
            boxShadow: '0 4px 12px rgba(25, 118, 210, 0.2)',
            color: 'white',
            height: '100%'
          }}>
            <Card.Body className="text-center">
              <h3 style={{ color: 'white', fontWeight: '700', fontSize: '2.5rem' }}>
                {bookings.filter(b => b.status === 'Checked-In').length}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0, fontWeight: '500' }}>
                Current Guests
              </p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card style={{
            background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
            border: 'none',
            borderRadius: '12px',
            boxShadow: '0 4px 12px rgba(245, 158, 11, 0.2)',
            color: 'white',
            height: '100%'
          }}>
            <Card.Body className="text-center">
              <h3 style={{ color: 'white', fontWeight: '700', fontSize: '2.5rem' }}>
                {bookings.filter(b => b.status === 'Pending Payment').length}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0, fontWeight: '500' }}>
                Pending Payments
              </p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card style={{
            background: 'linear-gradient(135deg, #28a745 0%, #218838 100%)',
            border: 'none',
            borderRadius: '12px',
            boxShadow: '0 4px 12px rgba(40, 167, 69, 0.2)',
            color: 'white',
            height: '100%'
          }}>
            <Card.Body className="text-center">
              <h3 style={{ color: 'white', fontWeight: '700', fontSize: '2.5rem' }}>
                {formatCurrency(bookings.reduce((sum, b) => sum + b.totalAmount, 0))}
              </h3>
              <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0, fontWeight: '500' }}>
                Total Revenue
              </p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Filters */}
      <Row className="mb-3">
        <Col md={6}>
          <div>
            <label style={{ color: '#1a237e', fontWeight: '600', marginBottom: '8px', display: 'block' }}>
              Filter by Status
            </label>
            <select 
              className="form-select"
              value={filterStatus} 
              onChange={(e) => setFilterStatus(e.target.value)}
              style={{
                borderColor: '#1976d2',
                borderRadius: '8px',
                padding: '10px'
              }}
            >
              <option value="All">All Bookings</option>
              <option value="Confirmed">Confirmed</option>
              <option value="Checked-In">Checked-In</option>
              <option value="Checked-Out">Checked-Out</option>
              <option value="Pending Payment">Pending Payment</option>
              <option value="Cancelled">Cancelled</option>
            </select>
          </div>
        </Col>
      </Row>

      {/* Bookings Table */}
      <Row>
        <Col>
          <Card style={{
            background: 'white',
            borderRadius: '12px',
            border: '1px solid #e2e8f0',
            boxShadow: '0 2px 8px rgba(0,0,0,0.08)'
          }}>
            <Card.Header style={{ 
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              borderBottom: '2px solid #1976d2',
              borderRadius: '12px 12px 0 0'
            }}>
              <h5 className="mb-0" style={{ fontWeight: '700', color: 'white' }}>
                Bookings List ({filteredBookings.length})
              </h5>
            </Card.Header>
            <Card.Body style={{ padding: 0 }}>
              <div style={{ overflowX: 'auto' }}>
                <Table responsive style={{ marginBottom: 0 }}>
                  <thead style={{ backgroundColor: '#f8f9fa', borderBottom: '2px solid #1976d2' }}>
                    <tr>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#1a237e', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Booking ID</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#1a237e', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Guest Name</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#1a237e', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Hotel/Room</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#1a237e', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Check-in</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#1a237e', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Check-out</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#1a237e', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Nights</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#1a237e', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Guests</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#1a237e', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Amount</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#1a237e', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Payment</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#1a237e', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Status</th>
                    </tr>
                </thead>
                <tbody>
                  {filteredBookings.map((booking) => (
                    <tr key={booking.id}>
                      <td>
                        <strong>{booking.id}</strong>
                      </td>
                      <td>
                        <div>
                          <strong>{booking.guestName}</strong>
                          <br />
                          <small className="text-muted">{booking.guestEmail}</small>
                        </div>
                      </td>
                      <td>
                        <div>
                          <strong>{booking.hotelBranch}</strong>
                          <br />
                          <small>Room {booking.roomNumber} ({booking.roomType})</small>
                        </div>
                      </td>
                      <td>{new Date(booking.checkInDate).toLocaleDateString()}</td>
                      <td>{new Date(booking.checkOutDate).toLocaleDateString()}</td>
                      <td>{booking.nights}</td>
                      <td>
                        {booking.adults}A
                        {booking.children > 0 && `, ${booking.children}C`}
                      </td>
                      <td>{formatCurrency(booking.totalAmount)}</td>
                      <td>
                        <Badge bg={getPaymentStatusColor(booking)}>
                          {getPaymentStatus(booking)}
                        </Badge>
                        <br />
                        <small>{formatCurrency(booking.paidAmount)}</small>
                      </td>
                      <td>
                        <Badge bg={getStatusColor(booking.status)}>
                          {booking.status}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Table>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
};

export default Bookings;