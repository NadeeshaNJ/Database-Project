import React, { useState, useEffect } from 'react';
import { Modal, Form, Button, Row, Col, Alert, Spinner } from 'react-bootstrap';
import { apiUrl } from '../../utils/api';
import { useBranch } from '../../context/BranchContext';

const NewReservationModal = ({ show, onHide, onSuccess }) => {
  const { selectedBranchId } = useBranch();
  const [formData, setFormData] = useState({
    guest_id: '',
    room_id: '',
    check_in_date: '',
    check_out_date: '',
    num_adults: 1,
    num_children: 0,
    special_requests: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  // Dropdown data
  const [guests, setGuests] = useState([]);
  const [rooms, setRooms] = useState([]);
  const [loadingGuests, setLoadingGuests] = useState(false);
  const [loadingRooms, setLoadingRooms] = useState(false);

  // Fetch guests and rooms when modal opens
  useEffect(() => {
    if (show) {
      fetchGuests();
      fetchRooms();
    }
  }, [show, selectedBranchId]);

  const fetchGuests = async () => {
    try {
      setLoadingGuests(true);
      const response = await fetch(apiUrl('/api/guests/all?limit=1000'));
      const data = await response.json();
      
      if (data.success && data.data && data.data.guests) {
        setGuests(data.data.guests);
      }
    } catch (err) {
      console.error('Error fetching guests:', err);
    } finally {
      setLoadingGuests(false);
    }
  };

  const fetchRooms = async () => {
    try {
      setLoadingRooms(true);
      let url = '/api/rooms?limit=1000&status=Available';
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success && data.data && data.data.rooms) {
        setRooms(data.data.rooms);
      }
    } catch (err) {
      console.error('Error fetching rooms:', err);
    } finally {
      setLoadingRooms(false);
    }
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // Validation
    if (new Date(formData.check_out_date) <= new Date(formData.check_in_date)) {
      setError('Check-out date must be after check-in date');
      setLoading(false);
      return;
    }

    try {
      // Get auth token from localStorage
      const storedUser = localStorage.getItem('skyNestUser');
      const user = storedUser ? JSON.parse(storedUser) : null;
      const token = user?.token;

      if (!token) {
        setError('Authentication required. Please login again.');
        setLoading(false);
        return;
      }

      const response = await fetch(apiUrl('/api/bookings'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (data.success) {
        // Reset form
        setFormData({
          guest_id: '',
          room_id: '',
          check_in_date: '',
          check_out_date: '',
          num_adults: 1,
          num_children: 0,
          special_requests: ''
        });
        if (onSuccess) onSuccess();
        onHide();
      } else {
        setError(data.error || 'Failed to create reservation');
      }
    } catch (err) {
      setError('Failed to connect to server');
      console.error('Error creating reservation:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal show={show} onHide={onHide} size="lg">
      <Modal.Header closeButton>
        <Modal.Title>New Reservation</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {error && <Alert variant="danger">{error}</Alert>}
        
        <Form onSubmit={handleSubmit}>
          <Row>
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Guest *</Form.Label>
                {loadingGuests ? (
                  <div className="text-center py-2">
                    <Spinner animation="border" size="sm" />
                  </div>
                ) : (
                  <Form.Select
                    name="guest_id"
                    value={formData.guest_id}
                    onChange={handleChange}
                    required
                  >
                    <option value="">Select a guest</option>
                    {guests.map(guest => (
                      <option key={guest.guest_id} value={guest.guest_id}>
                        {guest.full_name} ({guest.email})
                      </option>
                    ))}
                  </Form.Select>
                )}
                <Form.Text className="text-muted">
                  If guest doesn't exist, add them first using "Add New Guest"
                </Form.Text>
              </Form.Group>
            </Col>
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Room *</Form.Label>
                {loadingRooms ? (
                  <div className="text-center py-2">
                    <Spinner animation="border" size="sm" />
                  </div>
                ) : (
                  <Form.Select
                    name="room_id"
                    value={formData.room_id}
                    onChange={handleChange}
                    required
                  >
                    <option value="">Select a room</option>
                    {rooms.map(room => (
                      <option key={room.room_id} value={room.room_id}>
                        {room.room_number} - {room.room_type_name} (Rs {parseFloat(room.daily_rate).toLocaleString()}/night)
                      </option>
                    ))}
                  </Form.Select>
                )}
              </Form.Group>
            </Col>
          </Row>

          <Row>
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Check-in Date *</Form.Label>
                <Form.Control
                  type="date"
                  name="check_in_date"
                  value={formData.check_in_date}
                  onChange={handleChange}
                  min={new Date().toISOString().split('T')[0]}
                  required
                />
              </Form.Group>
            </Col>
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Check-out Date *</Form.Label>
                <Form.Control
                  type="date"
                  name="check_out_date"
                  value={formData.check_out_date}
                  onChange={handleChange}
                  min={formData.check_in_date || new Date().toISOString().split('T')[0]}
                  required
                />
              </Form.Group>
            </Col>
          </Row>

          <Row>
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Number of Adults *</Form.Label>
                <Form.Control
                  type="number"
                  name="num_adults"
                  value={formData.num_adults}
                  onChange={handleChange}
                  min="1"
                  max="10"
                  required
                />
              </Form.Group>
            </Col>
            <Col md={6}>
              <Form.Group className="mb-3">
                <Form.Label>Number of Children</Form.Label>
                <Form.Control
                  type="number"
                  name="num_children"
                  value={formData.num_children}
                  onChange={handleChange}
                  min="0"
                  max="10"
                />
              </Form.Group>
            </Col>
          </Row>

          <Form.Group className="mb-3">
            <Form.Label>Special Requests</Form.Label>
            <Form.Control
              as="textarea"
              rows={3}
              name="special_requests"
              value={formData.special_requests}
              onChange={handleChange}
              placeholder="Any special requests or notes..."
            />
          </Form.Group>

          <div className="d-flex justify-content-end gap-2 mt-4">
            <Button variant="secondary" onClick={onHide} disabled={loading}>
              Cancel
            </Button>
            <Button variant="success" type="submit" disabled={loading || loadingGuests || loadingRooms}>
              {loading ? 'Creating Reservation...' : 'Create Reservation'}
            </Button>
          </div>
        </Form>
      </Modal.Body>
    </Modal>
  );
};

export default NewReservationModal;
