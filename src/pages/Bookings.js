import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Button, Table, Badge, Modal, Form, Alert } from 'react-bootstrap';
import { FaCalendarCheck, FaPlus, FaEdit, FaEye, FaSearch, FaFilter } from 'react-icons/fa';

const API_URL = 'http://localhost:5000/api/bookings'; // ✅ adjust if your prefix differs


const Bookings = () => {
  const [bookings, setBookings] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [selectedBooking, setSelectedBooking] = useState(null);
  const [modalType, setModalType] = useState('add');
  const [filterStatus, setFilterStatus] = useState('All');
  const [loading, setLoading] = useState(true);


  // Sample bookings data for SkyNest Hotels
  const sampleBookings = [
    {
      id: 'BK001',
      guestName: 'John Smith',
      guestEmail: 'john.smith@email.com',
      guestPhone: '+1-555-0123',
      hotelBranch: 'SkyNest Colombo',
      roomNumber: '301',
      roomType: 'Suite',
      checkInDate: '2024-01-15',
      checkOutDate: '2024-01-18',
      nights: 3,
      adults: 2,
      children: 1,
      status: 'Confirmed',
      paymentMethod: 'Credit Card',
      totalAmount: 45000,
      paidAmount: 45000,
      bookingDate: '2024-01-10',
      specialRequests: 'Late check-in, sea view preferred'
    },
    {
      id: 'BK002',
      guestName: 'Sarah Johnson',
      guestEmail: 'sarah.j@email.com',
      guestPhone: '+1-555-0124',
      hotelBranch: 'SkyNest Kandy',
      roomNumber: '205',
      roomType: 'Double',
      checkInDate: '2024-01-20',
      checkOutDate: '2024-01-23',
      nights: 3,
      adults: 2,
      children: 0,
      status: 'Checked-In',
      paymentMethod: 'Cash',
      totalAmount: 27000,
      paidAmount: 27000,
      bookingDate: '2024-01-12',
      specialRequests: 'Ground floor room'
    },
    {
      id: 'BK003',
      guestName: 'Michael Brown',
      guestEmail: 'mike.brown@email.com',
      guestPhone: '+1-555-0125',
      hotelBranch: 'SkyNest Galle',
      roomNumber: '102',
      roomType: 'Single',
      checkInDate: '2024-01-25',
      checkOutDate: '2024-01-27',
      nights: 2,
      adults: 1,
      children: 0,
      status: 'Pending Payment',
      paymentMethod: 'Bank Transfer',
      totalAmount: 16000,
      paidAmount: 8000,
      bookingDate: '2024-01-14',
      specialRequests: 'Early check-in'
    },
    {
      id: 'BK004',
      guestName: 'Emily Davis',
      guestEmail: 'emily.davis@email.com',
      guestPhone: '+1-555-0126',
      hotelBranch: 'SkyNest Colombo',
      roomNumber: '415',
      roomType: 'Double',
      checkInDate: '2024-01-12',
      checkOutDate: '2024-01-15',
      nights: 3,
      adults: 2,
      children: 2,
      status: 'Checked-Out',
      paymentMethod: 'Credit Card',
      totalAmount: 33000,
      paidAmount: 33000,
      bookingDate: '2024-01-08',
      specialRequests: 'Extra bed for children'
    },
    {
      id: 'BK005',
      guestName: 'David Wilson',
      guestEmail: 'david.wilson@email.com',
      guestPhone: '+1-555-0127',
      hotelBranch: 'SkyNest Kandy',
      roomNumber: '308',
      roomType: 'Suite',
      checkInDate: '2024-02-01',
      checkOutDate: '2024-02-05',
      nights: 4,
      adults: 2,
      children: 0,
      status: 'Confirmed',
      paymentMethod: 'Credit Card',
      totalAmount: 60000,
      paidAmount: 30000,
      bookingDate: '2024-01-16',
      specialRequests: 'Honeymoon package'
    }
  ];

  useEffect(() => {
    const fetchBookings = async () => {
      try {
        const res = await fetch(`${API_URL}/booking/all`, {
          headers: { 'Content-Type': 'application/json' }
        });

        if (!res.ok) throw new Error('Backend not responding');
        const data = await res.json();

        // adjust shape if your backend returns {success, bookings:[]}
        setBookings(data.bookings || []);
      } catch (err) {
        console.warn('⚠️ Using sample data because backend not reachable:', err.message);
        setBookings(sampleBookings); // fallback
      } finally {
        setLoading(false);
      }
    };

    fetchBookings();
  }, []);
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
    <Container fluid className="py-4">
      <Row className="mb-4">
        <Col>
          <div className="d-flex justify-content-between align-items-center">
            <div>
              <h2 className="mb-1">Bookings Management</h2>
              <p className="text-muted">Manage hotel room bookings across all SkyNest branches</p>
            </div>
            <Button 
              variant="primary" 
              onClick={() => handleShowModal('add')}
              className="d-flex align-items-center"
            >
            <Button variant="primary" onClick={() => handleCreateBooking({
              room_id: 1,
              check_in_date: '2025-11-01',
              check_out_date: '2025-11-03',
              booked_rate: 20000,
              advance_payment: 5000,
              preferred_payment_method: 'Cash'
            })}>
              Create Booking
            </Button>

              <FaPlus className="me-2" />
              New Booking
            </Button>
          </div>
        </Col>
      </Row>

      {/* Booking Statistics */}
      <Row className="mb-4">
        <Col md={3}>
          <Card className="text-center h-100">
            <Card.Body>
              <h3 className="text-primary">{bookings.length}</h3>
              <p className="mb-0 text-muted">Total Bookings</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center h-100">
            <Card.Body>
              <h3 className="text-success">
                {bookings.filter(b => b.status === 'Checked-In').length}
              </h3>
              <p className="mb-0 text-muted">Current Guests</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center h-100">
            <Card.Body>
              <h3 className="text-warning">
                {bookings.filter(b => b.status === 'Pending Payment').length}
              </h3>
              <p className="mb-0 text-muted">Pending Payments</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center h-100">
            <Card.Body>
              <h3 className="text-info">
                {formatCurrency(bookings.reduce((sum, b) => sum + b.totalAmount, 0))}
              </h3>
              <p className="mb-0 text-muted">Total Revenue</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Filters */}
      <Row className="mb-3">
        <Col md={6}>
          <Form.Group>
            <Form.Label>Filter by Status</Form.Label>
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
      <Row>
        <Col>
          <Card>
            <Card.Header>
              <h5 className="mb-0">Bookings List ({filteredBookings.length})</h5>
            </Card.Header>
            <Card.Body>
              <Table responsive striped hover>
                <thead>
                  <tr>
                    <th>Booking ID</th>
                    <th>Guest Name</th>
                    <th>Hotel/Room</th>
                    <th>Check-in</th>
                    <th>Check-out</th>
                    <th>Nights</th>
                    <th>Guests</th>
                    <th>Amount</th>
                    <th>Payment</th>
                    <th>Status</th>
                    <th>Actions</th>
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