import React, { useState, useEffect } from 'react';
import { Modal, Form, Button, Row, Col, Alert, Spinner, Badge } from 'react-bootstrap';
import { apiUrl } from '../../utils/api';
import { useBranch } from '../../context/BranchContext';

const ServiceRequestModal = ({ show, onHide, onSuccess }) => {
  const { selectedBranchId } = useBranch();
  const [formData, setFormData] = useState({
    booking_id: '',
    service_id: '',
    qty: 1,
    used_on: new Date().toISOString().split('T')[0]
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  // Dropdown data
  const [bookings, setBookings] = useState([]);
  const [services, setServices] = useState([]);
  const [loadingBookings, setLoadingBookings] = useState(false);
  const [loadingServices, setLoadingServices] = useState(false);
  const [selectedService, setSelectedService] = useState(null);

  // Fetch bookings and services when modal opens
  useEffect(() => {
    if (show) {
      fetchActiveBookings();
      fetchServices();
    }
  }, [show, selectedBranchId]);

  const fetchActiveBookings = async () => {
    try {
      setLoadingBookings(true);
      let url = '/api/bookings?limit=1000&status=Checked-In';
      if (selectedBranchId !== 'All') {
        url += `&branch_id=${selectedBranchId}`;
      }
      const response = await fetch(apiUrl(url));
      const data = await response.json();
      
      if (data.success && data.data && data.data.bookings) {
        setBookings(data.data.bookings);
      }
    } catch (err) {
      console.error('Error fetching bookings:', err);
    } finally {
      setLoadingBookings(false);
    }
  };

  const fetchServices = async () => {
    try {
      setLoadingServices(true);
      const response = await fetch(apiUrl('/api/services?limit=1000'));
      const data = await response.json();
      
      if (data.success && data.data && data.data.services) {
        setServices(data.data.services.filter(s => s.active));
      }
    } catch (err) {
      console.error('Error fetching services:', err);
    } finally {
      setLoadingServices(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });

    // If service is selected, store service details for display
    if (name === 'service_id') {
      const service = services.find(s => s.service_id === parseInt(value));
      setSelectedService(service);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

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

      const response = await fetch(apiUrl('/api/service-usage'), {
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
          booking_id: '',
          service_id: '',
          qty: 1,
          used_on: new Date().toISOString().split('T')[0]
        });
        setSelectedService(null);
        if (onSuccess) onSuccess();
        onHide();
      } else {
        setError(data.error || 'Failed to create service request');
      }
    } catch (err) {
      setError('Failed to connect to server');
      console.error('Error creating service request:', err);
    } finally {
      setLoading(false);
    }
  };

  // Calculate total price
  const totalPrice = selectedService 
    ? (parseFloat(selectedService.unit_price) * formData.qty).toFixed(2)
    : '0.00';

  return (
    <Modal show={show} onHide={onHide} size="lg">
      <Modal.Header closeButton>
        <Modal.Title>Service Request</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        {error && <Alert variant="danger">{error}</Alert>}
        
        <Form onSubmit={handleSubmit}>
          <Row>
            <Col md={12}>
              <Form.Group className="mb-3">
                <Form.Label>Active Booking *</Form.Label>
                {loadingBookings ? (
                  <div className="text-center py-2">
                    <Spinner animation="border" size="sm" />
                  </div>
                ) : (
                  <Form.Select
                    name="booking_id"
                    value={formData.booking_id}
                    onChange={handleChange}
                    required
                  >
                    <option value="">Select a checked-in booking</option>
                    {bookings.map(booking => (
                      <option key={booking.booking_id} value={booking.booking_id}>
                        Booking #{booking.booking_id} - {booking.guest_name} - Room {booking.room_number}
                      </option>
                    ))}
                  </Form.Select>
                )}
                <Form.Text className="text-muted">
                  Only checked-in bookings are shown
                </Form.Text>
              </Form.Group>
            </Col>
          </Row>

          <Row>
            <Col md={8}>
              <Form.Group className="mb-3">
                <Form.Label>Service *</Form.Label>
                {loadingServices ? (
                  <div className="text-center py-2">
                    <Spinner animation="border" size="sm" />
                  </div>
                ) : (
                  <Form.Select
                    name="service_id"
                    value={formData.service_id}
                    onChange={handleChange}
                    required
                  >
                    <option value="">Select a service</option>
                    {services.map(service => (
                      <option key={service.service_id} value={service.service_id}>
                        {service.name} - Rs {parseFloat(service.unit_price).toLocaleString()} ({service.category})
                      </option>
                    ))}
                  </Form.Select>
                )}
              </Form.Group>
            </Col>
            <Col md={4}>
              <Form.Group className="mb-3">
                <Form.Label>Quantity *</Form.Label>
                <Form.Control
                  type="number"
                  name="qty"
                  value={formData.qty}
                  onChange={handleChange}
                  min="1"
                  max="100"
                  required
                />
              </Form.Group>
            </Col>
          </Row>

          <Row>
            <Col md={12}>
              <Form.Group className="mb-3">
                <Form.Label>Service Date *</Form.Label>
                <Form.Control
                  type="date"
                  name="used_on"
                  value={formData.used_on}
                  onChange={handleChange}
                  max={new Date().toISOString().split('T')[0]}
                  required
                />
              </Form.Group>
            </Col>
          </Row>

          {/* Service Details Display */}
          {selectedService && (
            <Alert variant="info">
              <Row>
                <Col md={6}>
                  <strong>Service:</strong> {selectedService.name}<br />
                  <strong>Category:</strong> <Badge bg="secondary">{selectedService.category}</Badge><br />
                  <strong>Unit Price:</strong> Rs {parseFloat(selectedService.unit_price).toLocaleString()}
                </Col>
                <Col md={6}>
                  <strong>Quantity:</strong> {formData.qty}<br />
                  <strong>Tax Rate:</strong> {parseFloat(selectedService.tax_rate_percent).toFixed(2)}%<br />
                  <strong className="text-primary">Total Price:</strong> <strong className="text-primary">Rs {parseFloat(totalPrice).toLocaleString()}</strong>
                </Col>
              </Row>
            </Alert>
          )}

          <div className="d-flex justify-content-end gap-2 mt-4">
            <Button variant="secondary" onClick={onHide} disabled={loading}>
              Cancel
            </Button>
            <Button variant="warning" type="submit" disabled={loading || loadingBookings || loadingServices}>
              {loading ? 'Creating Request...' : 'Create Service Request'}
            </Button>
          </div>
        </Form>
      </Modal.Body>
    </Modal>
  );
};

export default ServiceRequestModal;
