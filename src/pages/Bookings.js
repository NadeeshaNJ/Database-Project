import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Button, Table, Badge, Modal, Form, Alert, Spinner, Tabs, Tab } from 'react-bootstrap';
import { FaCalendarCheck, FaPlus, FaEdit, FaEye, FaSearch, FaFilter, FaCheckCircle, FaClock } from 'react-icons/fa';
import { apiUrl } from '../utils/api';
import { useBranch } from '../context/BranchContext';

const Bookings = () => {
  const { selectedBranchId } = useBranch();
  const [bookings, setBookings] = useState([]);
  const [preBookings, setPreBookings] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [selectedBooking, setSelectedBooking] = useState(null);
  const [modalType, setModalType] = useState('add');
  const [filterStatus, setFilterStatus] = useState('All');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState('bookings');

  // Fetch bookings and pre-bookings from backend
  useEffect(() => {
    fetchBookings();
    fetchPreBookings();
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

  const fetchPreBookings = async () => {
    try {
      setError('');
      
      let url = '/api/bookings/pre-bookings?';
      if (selectedBranchId !== 'All') {
        url += `branch_id=${selectedBranchId}`;
      }
      
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success && data.data && data.data.preBookings) {
        const transformedPreBookings = data.data.preBookings.map(pb => ({
          id: `PB${String(pb.pre_booking_id).padStart(3, '0')}`,
          preBookingId: pb.pre_booking_id,
          guestName: pb.guest_name,
          guestEmail: pb.guest_email,
          guestPhone: pb.guest_phone,
          hotelBranch: `SkyNest ${pb.branch_name}`,
          roomNumber: pb.room_number,
          roomType: pb.room_type,
          checkInDate: pb.expected_check_in?.split('T')[0],
          checkOutDate: pb.expected_check_out?.split('T')[0],
          capacity: parseInt(pb.capacity) || 2,
          method: pb.prebooking_method,
          pricePerNight: parseFloat(pb.price_per_night) || 0,
          createdAt: pb.created_at?.split('T')[0]
        }));
        
        setPreBookings(transformedPreBookings);
      }
    } catch (err) {
      console.error('Error fetching pre-bookings:', err);
    }
  };

  const handleConfirmPreBooking = async (preBooking) => {
    if (!window.confirm(`Confirm pre-booking ${preBooking.id} and convert it to a confirmed booking?`)) {
      return;
    }

    try {
      const user = JSON.parse(localStorage.getItem('skyNestUser'));
      const response = await fetch(apiUrl(`/api/bookings/pre-booking/${preBooking.preBookingId}/confirm`), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${user?.token}`
        },
        body: JSON.stringify({
          num_adults: preBooking.capacity,
          num_children: 0,
          special_requests: ''
        })
      });

      const data = await response.json();
      
      if (data.success) {
        alert(`✅ ${data.message}`);
        // Refresh both lists
        fetchBookings();
        fetchPreBookings();
      } else {
        alert(`❌ ${data.error || 'Failed to confirm pre-booking'}`);
      }
    } catch (err) {
      console.error('Error confirming pre-booking:', err);
      alert('❌ Failed to confirm pre-booking');
    }
  };

  const handleCreateBooking = async (newBookingData) => {
  try {
    const res = await fetch(`${API_URL}/confirmed`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // If you use auth token later:
        // 'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify(newBookingData)
    });

    if (!res.ok) throw new Error('Failed to create booking');
    const data = await res.json();

    setBookings(prev => [...prev, data.booking]); // add to UI
    alert('✅ Booking created successfully!');
  } catch (err) {
    alert('❌ ' + err.message);
  }
};

  const handleShowModal = (type, booking = null) => {
    setModalType(type);
    setSelectedBooking(booking);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedBooking(null);
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
    <Container fluid className="py-4" style={{ minHeight: '100vh' }}>
      {/* Page Header */}
      <Row className="mb-4">
        <Col>
          <div className="page-header">
            <div className="d-flex justify-content-between align-items-center">
              <div>
                <h2 className="mb-1">Bookings Management</h2>
                <p style={{ marginBottom: 0 }}>
                  Manage hotel room bookings across all SkyNest branches
                </p>
              </div>
              <Button 
                variant="primary"
                onClick={() => handleShowModal('add')}
              >
                <FaPlus className="me-2" />
                New Booking
              </Button>
            </div>
          </div>
        </Col>
      </Row>

      {/* Booking Statistics */}
      <Row className="mb-4">
        <Col md={3}>
          <Card className="stat-card h-100">
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
          <Card className="stat-card h-100">
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
          <Card className="stat-card h-100">
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
          <Card className="stat-card h-100">
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

      {/* Tabs for Bookings and Pre-Bookings */}
      <Row>
        <Col>
          <Card>
            <Card.Body>
              <Tabs
                activeKey={activeTab}
                onSelect={(k) => setActiveTab(k)}
                className="mb-3"
              >
                <Tab eventKey="bookings" title={
                  <span><FaCalendarCheck className="me-2" />Confirmed Bookings ({bookings.length})</span>
                }>
                  {/* Filters */}
                  <Row className="mb-3">
                    <Col md={6}>
                      <Form.Group>
                        <Form.Label style={{ color: '#2c3e50', fontWeight: '600', marginBottom: '8px' }}>
                          Filter by Status
                        </Form.Label>
                        <Form.Select 
                          value={filterStatus} 
                          onChange={(e) => setFilterStatus(e.target.value)}
                        >
                          <option value="All">All Bookings</option>
                          <option value="Confirmed">Confirmed</option>
                          <option value="Checked-In">Checked-In</option>
                          <option value="Checked-Out">Checked-Out</option>
                          <option value="Pending Payment">Pending Payment</option>
                          <option value="Cancelled">Cancelled</option>
                        </Form.Select>
                      </Form.Group>
                    </Col>
                  </Row>

                  {/* Bookings Table */}
                  <Card>
            <Card.Header style={{ background: '#f8f9fa', borderBottom: '1px solid #e0e6ed' }}>
              <h5 className="mb-0" style={{ fontWeight: '700', color: '#2c3e50' }}>
                Bookings List ({filteredBookings.length})
              </h5>
            </Card.Header>
            <Card.Body style={{ padding: 0 }}>
              <div style={{ overflowX: 'auto' }}>
                <Table responsive style={{ marginBottom: 0 }}>
                  <thead style={{ backgroundColor: '#f8f9fa', borderBottom: '2px solid #e0e6ed' }}>
                    <tr>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Booking ID</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Guest Name</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Hotel/Room</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Check-in</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Check-out</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Nights</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Guests</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Amount</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Payment</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Status</th>
                      <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Actions</th>
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
                      <td>
                        <div className="d-flex gap-1">
                          <Button
                            variant="outline-primary"
                            size="sm"
                            onClick={() => handleShowModal('view', booking)}
                          >
                            <FaEye />
                          </Button>
                          <Button
                            variant="outline-secondary"
                            size="sm"
                            onClick={() => handleShowModal('edit', booking)}
                          >
                            <FaEdit />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </Table>
              </div>
            </Card.Body>
          </Card>
                </Tab>

                <Tab eventKey="pre-bookings" title={
                  <span><FaClock className="me-2" />Pre-Bookings ({preBookings.length})</span>
                }>
                  {/* Pre-Bookings Table */}
                  <Card>
                    <Card.Header style={{ background: '#f8f9fa', borderBottom: '1px solid #e0e6ed' }}>
                      <h5 className="mb-0" style={{ fontWeight: '700', color: '#2c3e50' }}>
                        Pending Pre-Bookings ({preBookings.length})
                      </h5>
                    </Card.Header>
                    <Card.Body style={{ padding: 0 }}>
                      <div style={{ overflowX: 'auto' }}>
                        <Table responsive style={{ marginBottom: 0 }}>
                          <thead style={{ backgroundColor: '#f8f9fa', borderBottom: '2px solid #e0e6ed' }}>
                            <tr>
                              <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Pre-Booking ID</th>
                              <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Guest Name</th>
                              <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Hotel/Room</th>
                              <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Expected Check-in</th>
                              <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Expected Check-out</th>
                              <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Capacity</th>
                              <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Method</th>
                              <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Created</th>
                              <th style={{ padding: '16px', fontWeight: '600', color: '#5a6c7d', fontSize: '0.85rem', letterSpacing: '0.5px', textTransform: 'uppercase', border: 'none' }}>Actions</th>
                            </tr>
                          </thead>
                          <tbody>
                            {preBookings.length === 0 ? (
                              <tr>
                                <td colSpan="9" className="text-center py-4">
                                  <p className="text-muted mb-0">No pending pre-bookings</p>
                                </td>
                              </tr>
                            ) : (
                              preBookings.map((preBooking) => (
                                <tr key={preBooking.id}>
                                  <td>
                                    <strong>{preBooking.id}</strong>
                                  </td>
                                  <td>
                                    <div>
                                      <strong>{preBooking.guestName}</strong>
                                      <br />
                                      <small className="text-muted">{preBooking.guestEmail}</small>
                                    </div>
                                  </td>
                                  <td>
                                    <div>
                                      <strong>{preBooking.hotelBranch}</strong>
                                      <br />
                                      <small>Room {preBooking.roomNumber} ({preBooking.roomType})</small>
                                    </div>
                                  </td>
                                  <td>{new Date(preBooking.checkInDate).toLocaleDateString()}</td>
                                  <td>{new Date(preBooking.checkOutDate).toLocaleDateString()}</td>
                                  <td>{preBooking.capacity} guests</td>
                                  <td>
                                    <Badge bg="info">{preBooking.method}</Badge>
                                  </td>
                                  <td>{new Date(preBooking.createdAt).toLocaleDateString()}</td>
                                  <td>
                                    <Button
                                      variant="success"
                                      size="sm"
                                      onClick={() => handleConfirmPreBooking(preBooking)}
                                    >
                                      <FaCheckCircle className="me-1" />
                                      Confirm Booking
                                    </Button>
                                  </td>
                                </tr>
                              ))
                            )}
                          </tbody>
                        </Table>
                      </div>
                    </Card.Body>
                  </Card>
                </Tab>
              </Tabs>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Modal for Add/Edit/View Booking */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>
            {modalType === 'add' && 'New Booking'}
            {modalType === 'edit' && 'Edit Booking'}
            {modalType === 'view' && 'Booking Details'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {selectedBooking && modalType === 'view' ? (
            <Row>
              <Col md={6}>
                <h6>Guest Information</h6>
                <p><strong>Name:</strong> {selectedBooking.guestName}</p>
                <p><strong>Email:</strong> {selectedBooking.guestEmail}</p>
                <p><strong>Phone:</strong> {selectedBooking.guestPhone}</p>
                
                <h6 className="mt-4">Booking Details</h6>
                <p><strong>Booking ID:</strong> {selectedBooking.id}</p>
                <p><strong>Booking Date:</strong> {new Date(selectedBooking.bookingDate).toLocaleDateString()}</p>
                <p><strong>Status:</strong> 
                  <Badge bg={getStatusColor(selectedBooking.status)} className="ms-2">
                    {selectedBooking.status}
                  </Badge>
                </p>
              </Col>
              <Col md={6}>
                <h6>Stay Information</h6>
                <p><strong>Hotel:</strong> {selectedBooking.hotelBranch}</p>
                <p><strong>Room:</strong> {selectedBooking.roomNumber} ({selectedBooking.roomType})</p>
                <p><strong>Check-in:</strong> {new Date(selectedBooking.checkInDate).toLocaleDateString()}</p>
                <p><strong>Check-out:</strong> {new Date(selectedBooking.checkOutDate).toLocaleDateString()}</p>
                <p><strong>Nights:</strong> {selectedBooking.nights}</p>
                <p><strong>Guests:</strong> {selectedBooking.adults} Adults, {selectedBooking.children} Children</p>
                
                <h6 className="mt-4">Payment Information</h6>
                <p><strong>Total Amount:</strong> {formatCurrency(selectedBooking.totalAmount)}</p>
                <p><strong>Paid Amount:</strong> {formatCurrency(selectedBooking.paidAmount)}</p>
                <p><strong>Balance:</strong> {formatCurrency(selectedBooking.totalAmount - selectedBooking.paidAmount)}</p>
                <p><strong>Payment Method:</strong> {selectedBooking.paymentMethod}</p>
                
                {selectedBooking.specialRequests && (
                  <>
                    <h6 className="mt-4">Special Requests</h6>
                    <p>{selectedBooking.specialRequests}</p>
                  </>
                )}
              </Col>
            </Row>
          ) : (
            <Form>
              <Row>
                <Col md={6}>
                  <h6>Guest Information</h6>
                  <Form.Group className="mb-3">
                    <Form.Label>Guest Name</Form.Label>
                    <Form.Control
                      type="text"
                      defaultValue={selectedBooking?.guestName || ''}
                      placeholder="Enter guest name"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Email</Form.Label>
                    <Form.Control
                      type="email"
                      defaultValue={selectedBooking?.guestEmail || ''}
                      placeholder="Enter email address"
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Phone</Form.Label>
                    <Form.Control
                      type="tel"
                      defaultValue={selectedBooking?.guestPhone || ''}
                      placeholder="Enter phone number"
                    />
                  </Form.Group>
                  
                  <h6 className="mt-4">Stay Details</h6>
                  <Form.Group className="mb-3">
                    <Form.Label>Hotel Branch</Form.Label>
                    <Form.Select defaultValue={selectedBooking?.hotelBranch || ''}>
                      <option value="">Select hotel branch</option>
                      <option value="SkyNest Colombo">SkyNest Colombo</option>
                      <option value="SkyNest Kandy">SkyNest Kandy</option>
                      <option value="SkyNest Galle">SkyNest Galle</option>
                    </Form.Select>
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Room Type</Form.Label>
                    <Form.Select defaultValue={selectedBooking?.roomType || ''}>
                      <option value="">Select room type</option>
                      <option value="Single">Single</option>
                      <option value="Double">Double</option>
                      <option value="Suite">Suite</option>
                    </Form.Select>
                  </Form.Group>
                </Col>
                <Col md={6}>
                  <h6>Booking Information</h6>
                  <Form.Group className="mb-3">
                    <Form.Label>Check-in Date</Form.Label>
                    <Form.Control
                      type="date"
                      defaultValue={selectedBooking?.checkInDate || ''}
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Check-out Date</Form.Label>
                    <Form.Control
                      type="date"
                      defaultValue={selectedBooking?.checkOutDate || ''}
                    />
                  </Form.Group>
                  <Row>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Adults</Form.Label>
                        <Form.Control
                          type="number"
                          min="1"
                          defaultValue={selectedBooking?.adults || 1}
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Children</Form.Label>
                        <Form.Control
                          type="number"
                          min="0"
                          defaultValue={selectedBooking?.children || 0}
                        />
                      </Form.Group>
                    </Col>
                  </Row>
                  <Form.Group className="mb-3">
                    <Form.Label>Payment Method</Form.Label>
                    <Form.Select defaultValue={selectedBooking?.paymentMethod || ''}>
                      <option value="">Select payment method</option>
                      <option value="Credit Card">Credit Card</option>
                      <option value="Cash">Cash</option>
                      <option value="Bank Transfer">Bank Transfer</option>
                    </Form.Select>
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Special Requests</Form.Label>
                    <Form.Control
                      as="textarea"
                      rows={3}
                      defaultValue={selectedBooking?.specialRequests || ''}
                      placeholder="Enter any special requests"
                    />
                  </Form.Group>
                </Col>
              </Row>
            </Form>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Close
          </Button>
          {modalType !== 'view' && (
            <Button variant="primary">
              {modalType === 'add' ? 'Create Booking' : 'Save Changes'}
            </Button>
          )}
        </Modal.Footer>
      </Modal>
    </Container>
  );
};

export default Bookings;