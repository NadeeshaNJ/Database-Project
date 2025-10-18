import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Button, Modal, Form, Table, InputGroup, Spinner, Alert } from 'react-bootstrap';
import { FaPlus, FaEdit, FaTrash, FaSearch } from 'react-icons/fa';
import { useBranch } from '../context/BranchContext';

// ✅ Use environment-aware API URL
const API_BASE = process.env.REACT_APP_API_BASE || 'http://localhost:5000';
const API_URL = `${API_BASE}/api/guests`;

const Guests = () => {
  const { selectedBranchId } = useBranch();
  const [guests, setGuests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [selectedGuest, setSelectedGuest] = useState(null);

  // ✅ fallback demo data
  const demoGuests = [
    {
      id: 1,
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@email.com',
      phone: '+1-555-0123',
      nationality: 'American',
      idNumber: 'P123456789',
      checkInDate: '2025-09-14',
      status: 'Checked In'
    },
    {
      id: 2,
      firstName: 'Jane',
      lastName: 'Smith',
      email: 'jane.smith@email.com',
      phone: '+1-555-0456',
      nationality: 'Canadian',
      idNumber: 'C987654321',
      checkInDate: '2025-09-13',
      status: 'Checked Out'
    }
  ];

  // ✅ Fetch guests from backend
  useEffect(() => {
    const fetchGuests = async () => {
      try {
        setLoading(true);
        
        // Build URL with branch filter
        let url = `${API_URL}/all?limit=1000`;
        if (selectedBranchId !== 'All') {
          url += `&branch_id=${selectedBranchId}`;
        }
        
        const res = await fetch(url, {
          headers: {
            'Content-Type': 'application/json',
          }
        });

        if (!res.ok) throw new Error('Backend unavailable');
        const response = await res.json();
        
        // Transform database data to match UI format
        const transformedGuests = response.data.guests.map(guest => ({
          id: guest.guest_id,
          firstName: guest.full_name ? guest.full_name.split(' ')[0] : '',
          lastName: guest.full_name ? guest.full_name.split(' ').slice(1).join(' ') : '',
          email: guest.email || 'N/A',
          phone: guest.phone || 'N/A',
          nationality: guest.nationality || 'N/A',
          idNumber: guest.nic || 'N/A',
          checkInDate: guest.last_check_in || 'N/A',
          status: guest.current_booking_id ? 'Checked In' : 
                  (guest.total_bookings > 0 ? 'Checked Out' : 'No Bookings'),
          totalBookings: guest.total_bookings || 0
        }));
        
        setGuests(transformedGuests);
        setError(null);
      } catch (err) {
        console.warn('⚠️ Backend not connected, using demo data');
        setGuests(demoGuests);
        setError('Running in demo mode (backend not connected)');
      } finally {
        setLoading(false);
      }
    };

    fetchGuests();
  }, [selectedBranchId]); // Re-fetch when global branch filter changes

  // ✅ Search filter (works locally or with backend)
  const filteredGuests = guests.filter((guest) =>
    `${guest.firstName} ${guest.lastName}`.toLowerCase().includes(searchTerm.toLowerCase()) ||
    guest.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    guest.phone.includes(searchTerm)
  );

  const handleShowModal = (guest = null) => {
    setSelectedGuest(guest);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedGuest(null);
  };

  const getStatusBadge = (status) => {
    const statusClasses = {
      'Checked In': 'bg-success',
      'Checked Out': 'bg-secondary',
      'Reserved': 'bg-primary'
    };
    return <span className={`badge ${statusClasses[status]}`}>{status}</span>;
  };

  return (
    <div>
      <Row className="mb-4">
        <Col>
          <h2>Guest Management</h2>
        </Col>
        <Col xs="auto">
          <Button variant="primary" onClick={() => handleShowModal()}>
            <FaPlus className="me-2" />
            Add New Guest
          </Button>
        </Col>
      </Row>

      {error && <Alert variant="warning">{error}</Alert>}

      <Card>
        <Card.Header>
          <Row className="align-items-center mb-3">
            <Col md={12}>
              <Form.Label>Search</Form.Label>
              <InputGroup>
                <InputGroup.Text><FaSearch /></InputGroup.Text>
                <Form.Control
                  type="text"
                  placeholder="Search guests..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </InputGroup>
            </Col>
          </Row>
          <Row className="align-items-center">
            <Col>
              <h5 className="mb-0">Guest List</h5>
            </Col>
          </Row>
        </Card.Header>
        <Card.Body className="p-0">
          {loading ? (
            <div className="text-center py-5">
              <Spinner animation="border" variant="primary" />
              <p className="mt-2 text-muted">Loading guests...</p>
            </div>
          ) : (
            <Table responsive hover className="mb-0">
              <thead className="table-light">
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Phone</th>
                  <th>Nationality</th>
                  <th>ID Number</th>
                  <th>Check-in Date</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredGuests.map((guest) => (
                  <tr key={guest.id}>
                    <td>{`${guest.firstName} ${guest.lastName}`}</td>
                    <td>{guest.email}</td>
                    <td>{guest.phone}</td>
                    <td>{guest.nationality}</td>
                    <td>{guest.idNumber}</td>
                    <td>{guest.checkInDate}</td>
                    <td>{getStatusBadge(guest.status)}</td>
                    <td>
                      <Button variant="outline-primary" size="sm" onClick={() => handleShowModal(guest)} className="me-2">
                        <FaEdit />
                      </Button>
                      <Button variant="outline-danger" size="sm">
                        <FaTrash />
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </Table>
          )}
        </Card.Body>
      </Card>

      {/* Add/Edit Guest Modal */}
      <Modal show={showModal} onHide={handleCloseModal} size="lg">
        <Modal.Header closeButton>
          <Modal.Title>{selectedGuest ? 'Edit Guest' : 'Add New Guest'}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            {/* your existing form fields */}
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Cancel
          </Button>
          <Button variant="primary">
            {selectedGuest ? 'Update Guest' : 'Add Guest'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default Guests;
