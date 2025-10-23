import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Button, Modal, Form, Table, InputGroup, Spinner, Alert } from 'react-bootstrap';
import { FaPlus, FaEdit, FaTrash, FaSearch, FaCalendarAlt } from 'react-icons/fa';
import { apiUrl } from '../utils/api';
import { useBranch } from '../context/BranchContext';

const Reservations = () => {
  const { selectedBranchId } = useBranch();
  const [showModal, setShowModal] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedReservation, setSelectedReservation] = useState(null);
  const [reservations, setReservations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    confirmed: 0,
    pending: 0,
    checkins_today: 0
  });
  const [error, setError] = useState('');

  useEffect(() => {
    fetchReservations();
    fetchStats();
  }, [selectedBranchId]);

  const fetchReservations = async () => {
    try {
      setLoading(true);
      setError('');
      let url = '/api/bookings?limit=1000';
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success && data.data && data.data.bookings) {
        setReservations(data.data.bookings);
      }
    } catch (err) {
      console.error('Error fetching reservations:', err);
      setError('Failed to load reservations');
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      let url = '/api/reports/dashboard-summary';
      if (selectedBranchId !== 'All') {
        url += `?branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success && data.data) {
        // Calculate stats from reservations
        let confirmedCount = reservations.filter(r => r.status === 'Confirmed').length;
        let pendingCount = reservations.filter(r => r.status === 'Pending').length;
        
        setStats({
          total: reservations.length,
          confirmed: confirmedCount,
          pending: pendingCount,
          checkins_today: data.data.today?.today_checkins || 0
        });
      }
    } catch (err) {
      console.error('Error fetching stats:', err);
    }
  };

  const handleShowModal = (reservation = null) => {
    setSelectedReservation(reservation);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedReservation(null);
  };

  const filteredReservations = reservations.filter(reservation =>
    (reservation.guest_name && reservation.guest_name.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (reservation.room_number && reservation.room_number.includes(searchTerm)) ||
    (reservation.room_type && reservation.room_type.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const calculateNights = (checkIn, checkOut) => {
    const start = new Date(checkIn);
    const end = new Date(checkOut);
    const diffTime = Math.abs(end - start);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  };

  const getStatusBadge = (status) => {
    const statusClasses = {
      'Confirmed': 'bg-success',
      'Checked-In': 'bg-primary',
      'Checked-Out': 'bg-secondary',
      'Pending': 'bg-warning',
      'Cancelled': 'bg-danger',
      'Booked': 'bg-success'
    };
    return <span className={`badge ${statusClasses[status] || 'bg-secondary'}`}>{status}</span>;
  };

  // Update stats when reservations change
  useEffect(() => {
    if (reservations.length > 0) {
      const confirmed = reservations.filter(r => r.status === 'Confirmed' || r.status === 'Booked').length;
      const pending = reservations.filter(r => r.status === 'Pending').length;
      const today = new Date().toISOString().split('T')[0];
      const checkinsToday = reservations.filter(r => r.check_in_date === today).length;
      
      setStats({
        total: reservations.length,
        confirmed: confirmed,
        pending: pending,
        checkins_today: checkinsToday
      });
    }
  }, [reservations]);

  return (
    <div>
      {error && (
        <Alert variant="danger" dismissible onClose={() => setError('')}>
          {error}
        </Alert>
      )}

      <div className="mb-4 p-4 rounded-3" style={{
        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
        color: 'white',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
      }}>
        <Row className="align-items-center">
          <Col>
            <div className="d-flex align-items-center">
              <FaCalendarAlt size={32} className="me-3" />
              <div>
                <h2 className="mb-0">Reservation Management</h2>
                <p className="mb-0 opacity-75">Manage all hotel reservations and bookings</p>
              </div>
            </div>
          </Col>
          <Col xs="auto">
            <Button 
              onClick={() => handleShowModal()}
              style={{
                background: 'white',
                color: '#1a237e',
                border: 'none',
                padding: '10px 24px',
                borderRadius: '8px',
                fontWeight: '600',
                boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                transition: 'all 0.3s ease'
              }}
              onMouseOver={(e) => {
                e.currentTarget.style.transform = 'translateY(-2px)';
                e.currentTarget.style.boxShadow = '0 4px 8px rgba(0,0,0,0.15)';
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
              }}
            >
              <FaPlus className="me-2" />
              New Reservation
            </Button>
          </Col>
        </Row>
      </div>

      <Row className="mb-4">
        <Col md={3}>
          <Card className="text-center border-0 shadow-sm" style={{
            borderRadius: '12px',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease',
            cursor: 'pointer'
          }}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.1)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
          }}>
            <Card.Body style={{
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              borderRadius: '12px',
              padding: '24px',
              color: 'white'
            }}>
              <h4 style={{ fontSize: '2.5rem', fontWeight: '700', marginBottom: '8px' }}>{stats.total}</h4>
              <p className="mb-0" style={{ fontSize: '0.95rem', opacity: 0.9 }}>Total Reservations</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center border-0 shadow-sm" style={{
            borderRadius: '12px',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease',
            cursor: 'pointer'
          }}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.1)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
          }}>
            <Card.Body style={{
              background: 'linear-gradient(135deg, #388e3c 0%, #4caf50 100%)',
              borderRadius: '12px',
              padding: '24px',
              color: 'white'
            }}>
              <h4 style={{ fontSize: '2.5rem', fontWeight: '700', marginBottom: '8px' }}>{stats.confirmed}</h4>
              <p className="mb-0" style={{ fontSize: '0.95rem', opacity: 0.9 }}>Confirmed</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center border-0 shadow-sm" style={{
            borderRadius: '12px',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease',
            cursor: 'pointer'
          }}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.1)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
          }}>
            <Card.Body style={{
              background: 'linear-gradient(135deg, #f57c00 0%, #ff9800 100%)',
              borderRadius: '12px',
              padding: '24px',
              color: 'white'
            }}>
              <h4 style={{ fontSize: '2.5rem', fontWeight: '700', marginBottom: '8px' }}>{stats.pending}</h4>
              <p className="mb-0" style={{ fontSize: '0.95rem', opacity: 0.9 }}>Pending</p>
            </Card.Body>
          </Card>
        </Col>
        <Col md={3}>
          <Card className="text-center border-0 shadow-sm" style={{
            borderRadius: '12px',
            transition: 'transform 0.3s ease, box-shadow 0.3s ease',
            cursor: 'pointer'
          }}
          onMouseOver={(e) => {
            e.currentTarget.style.transform = 'translateY(-5px)';
            e.currentTarget.style.boxShadow = '0 8px 16px rgba(0,0,0,0.1)';
          }}
          onMouseOut={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
          }}>
            <Card.Body style={{
              background: 'linear-gradient(135deg, #0288d1 0%, #03a9f4 100%)',
              borderRadius: '12px',
              padding: '24px',
              color: 'white'
            }}>
              <h4 style={{ fontSize: '2.5rem', fontWeight: '700', marginBottom: '8px' }}>{stats.checkins_today}</h4>
              <p className="mb-0" style={{ fontSize: '0.95rem', opacity: 0.9 }}>Check-ins Today</p>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      <Card className="border-0 shadow-sm" style={{ borderRadius: '12px' }}>
        <Card.Header style={{
          background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
          color: 'white',
          borderRadius: '12px 12px 0 0',
          padding: '20px'
        }}>
          <Row className="align-items-center">
            <Col>
              <h5 className="mb-0" style={{ fontWeight: '600', fontSize: '1.25rem' }}>Reservation List</h5>
            </Col>
            <Col xs="auto">
              <InputGroup>
                <InputGroup.Text style={{
                  background: 'white',
                  border: 'none',
                  borderRadius: '8px 0 0 8px'
                }}>
                  <FaSearch style={{ color: '#1a237e' }} />
                </InputGroup.Text>
                <Form.Control
                  type="text"
                  placeholder="Search reservations..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  style={{
                    border: 'none',
                    borderRadius: '0 8px 8px 0',
                    padding: '8px 16px'
                  }}
                />
              </InputGroup>
            </Col>
          </Row>
        </Card.Header>
        <Card.Body className="p-0">
          {loading ? (
            <div className="text-center py-5">
              <Spinner animation="border" style={{ color: '#1a237e' }} />
              <p className="mt-3" style={{ color: '#1a237e', fontWeight: '500' }}>Loading reservations...</p>
            </div>
          ) : (
          <div className="table-container">
            <Table responsive hover className="mb-0">
              <thead style={{
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                color: 'white'
              }}>
                <tr>
                  <th style={{ borderBottom: 'none', padding: '16px' }}>Booking ID</th>
                  <th style={{ borderBottom: 'none', padding: '16px' }}>Guest Name</th>
                  <th style={{ borderBottom: 'none', padding: '16px' }}>Room</th>
                  <th style={{ borderBottom: 'none', padding: '16px' }}>Room Type</th>
                  <th style={{ borderBottom: 'none', padding: '16px' }}>Check-in</th>
                  <th style={{ borderBottom: 'none', padding: '16px' }}>Check-out</th>
                  <th style={{ borderBottom: 'none', padding: '16px' }}>Nights</th>
                  <th style={{ borderBottom: 'none', padding: '16px' }}>Total Amount</th>
                  <th style={{ borderBottom: 'none', padding: '16px' }}>Status</th>
                  <th style={{ borderBottom: 'none', padding: '16px' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredReservations.length > 0 ? (
                  filteredReservations.map((reservation) => (
                    <tr key={reservation.booking_id}>
                      <td>#{reservation.booking_id}</td>
                      <td>{reservation.guest_name}</td>
                      <td>{reservation.room_number}</td>
                      <td>{reservation.room_type}</td>
                      <td>{new Date(reservation.check_in_date).toLocaleDateString()}</td>
                      <td>{new Date(reservation.check_out_date).toLocaleDateString()}</td>
                      <td>{calculateNights(reservation.check_in_date, reservation.check_out_date)}</td>
                      <td>Rs {parseFloat(reservation.room_estimate || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
                      <td>{getStatusBadge(reservation.status)}</td>
                      <td>
                        <Button
                          variant="outline-primary"
                          size="sm"
                          className="me-2"
                          onClick={() => handleShowModal(reservation)}
                        >
                          <FaEdit />
                        </Button>
                        <Button variant="outline-danger" size="sm">
                          <FaTrash />
                        </Button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="10" className="text-center">No reservations found</td>
                  </tr>
                )}
              </tbody>
            </Table>
          </div>
          )}
        </Card.Body>
      </Card>

      {/* Add/Edit Reservation Modal */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton style={{
          background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
          color: 'white',
          borderRadius: '8px 8px 0 0'
        }}>
          <Modal.Title style={{ fontWeight: '600' }}>
            {selectedReservation ? 'Edit Reservation' : 'New Reservation'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Guest Name</Form.Label>
                  <Form.Control
                    type="text"
                    defaultValue={selectedReservation?.guest_name || ''}
                    placeholder="Enter guest name"
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Room Number</Form.Label>
                  <Form.Control
                    type="text"
                    defaultValue={selectedReservation?.room_number || ''}
                    placeholder="Enter room number"
                  />
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Check-in Date</Form.Label>
                  <Form.Control
                    type="date"
                    defaultValue={selectedReservation?.check_in_date ? new Date(selectedReservation.check_in_date).toISOString().split('T')[0] : ''}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Check-out Date</Form.Label>
                  <Form.Control
                    type="date"
                    defaultValue={selectedReservation?.check_out_date ? new Date(selectedReservation.check_out_date).toISOString().split('T')[0] : ''}
                  />
                </Form.Group>
              </Col>
            </Row>
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Status</Form.Label>
                  <Form.Select defaultValue={selectedReservation?.status || ''}>
                    <option value="Pending">Pending</option>
                    <option value="Confirmed">Confirmed</option>
                    <option value="Booked">Booked</option>
                    <option value="Checked-In">Checked In</option>
                    <option value="Checked-Out">Checked Out</option>
                    <option value="Cancelled">Cancelled</option>
                  </Form.Select>
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Total Amount (Rs)</Form.Label>
                  <Form.Control
                    type="number"
                    placeholder="Enter total amount"
                    defaultValue={selectedReservation?.room_estimate || ''}
                  />
                </Form.Group>
              </Col>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button 
            variant="secondary" 
            onClick={handleCloseModal}
            style={{
              borderRadius: '8px',
              padding: '10px 24px',
              fontWeight: '500'
            }}
          >
            Cancel
          </Button>
          <Button 
            style={{
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              border: 'none',
              borderRadius: '8px',
              padding: '10px 24px',
              fontWeight: '600',
              transition: 'transform 0.3s ease, box-shadow 0.3s ease'
            }}
            onMouseOver={(e) => {
              e.currentTarget.style.transform = 'translateY(-2px)';
              e.currentTarget.style.boxShadow = '0 4px 8px rgba(26, 35, 126, 0.3)';
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = 'none';
            }}
          >
            {selectedReservation ? 'Update Reservation' : 'Create Reservation'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default Reservations;