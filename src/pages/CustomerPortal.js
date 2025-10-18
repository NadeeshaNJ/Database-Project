import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Form, Button, Alert, Spinner } from 'react-bootstrap';
import { FaCalendarAlt, FaUsers, FaBed, FaMapMarkerAlt, FaCheckCircle, FaInfoCircle, FaDoorOpen } from 'react-icons/fa';
import { useAuth } from '../context/AuthContext';
import { apiUrl } from '../utils/api';
import './CustomerPortal.css';

const CustomerPortal = () => {
  const { user } = useAuth();
  const [branches, setBranches] = useState([]);
  const [roomTypes, setRoomTypes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });

  // Form state - Customer selects room type, backend auto-assigns room
  const [formData, setFormData] = useState({
    branch_id: '',
    room_type_id: '', // Customer selects type, backend finds available room
    capacity: 2,
    expected_check_in: '',
    expected_check_out: '',
    prebooking_method: 'Online'
  });

  useEffect(() => {
    fetchBranches();
    fetchRoomTypes();
  }, []);

  const fetchBranches = async () => {
    try {
      const token = user?.token || JSON.parse(localStorage.getItem('skyNestUser'))?.token;
      const response = await fetch(apiUrl('/api/branches'), {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      if (response.ok) {
        const result = await response.json();
        console.log('Branches API Response:', result);
        
        if (result.success && result.data && Array.isArray(result.data.branches)) {
          setBranches(result.data.branches);
        } else if (Array.isArray(result)) {
          setBranches(result);
        } else {
          console.error('Unexpected branches data format:', result);
          setBranches([]);
        }
      }
    } catch (error) {
      console.error('Error fetching branches:', error);
      setBranches([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchRoomTypes = async () => {
    try {
      const token = user?.token || JSON.parse(localStorage.getItem('skyNestUser'))?.token;
      const response = await fetch(apiUrl('/api/rooms/types/summary'), {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      if (response.ok) {
        const result = await response.json();
        console.log('Room Types API Response:', result);
        
        if (result.success && Array.isArray(result.data)) {
          setRoomTypes(result.data);
        } else if (Array.isArray(result)) {
          setRoomTypes(result);
        } else {
          console.error('Unexpected room types data format:', result);
          setRoomTypes([]);
        }
      }
    } catch (error) {
      console.error('Error fetching room types:', error);
      setRoomTypes([]);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setMessage({ type: '', text: '' });

    // Validation
    if (!formData.branch_id || !formData.room_type_id || !formData.expected_check_in || !formData.expected_check_out || !formData.capacity) {
      setMessage({ type: 'danger', text: 'Please fill in all required fields.' });
      setSubmitting(false);
      return;
    }

    if (new Date(formData.expected_check_out) <= new Date(formData.expected_check_in)) {
      setMessage({ type: 'danger', text: 'Check-out date must be after check-in date.' });
      setSubmitting(false);
      return;
    }

    try {
      const token = user?.token || JSON.parse(localStorage.getItem('skyNestUser'))?.token;
      
      // Create pre-booking - backend will auto-assign room and mark it unavailable
      const preBookingData = {
        guest_id: user?.user_id || user?.id,
        branch_id: parseInt(formData.branch_id),
        room_type_id: parseInt(formData.room_type_id),
        capacity: parseInt(formData.capacity),
        prebooking_method: 'Online',
        expected_check_in: formData.expected_check_in,
        expected_check_out: formData.expected_check_out
      };

      console.log('Submitting pre-booking:', preBookingData);

      const response = await fetch(apiUrl('/api/bookings/pre-booking'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(preBookingData)
      });

      const result = await response.json();
      console.log('Pre-booking response:', result);

      if (response.ok && result.success) {
        setMessage({ 
          type: 'success', 
          text: `🎉 ${result.message || 'Pre-booking confirmed!'} Your reservation has been secured.` 
        });
        
        // Reset form
        setFormData({
          branch_id: '',
          room_type_id: '',
          capacity: 2,
          expected_check_in: '',
          expected_check_out: '',
          prebooking_method: 'Online'
        });
      } else {
        setMessage({ 
          type: 'danger', 
          text: result.error || 'Failed to submit pre-booking. Please try again.' 
        });
      }
    } catch (error) {
      console.error('Error submitting pre-booking:', error);
      setMessage({ 
        type: 'danger', 
        text: 'An error occurred while submitting your request. Please try again later.' 
      });
    } finally {
      setSubmitting(false);
    }
  };

  // Get minimum date (today)
  const today = new Date().toISOString().split('T')[0];

  if (loading) {
    return (
      <Container className="customer-portal-loading">
        <div className="text-center">
          <Spinner animation="border" variant="primary" />
          <p className="mt-3">Loading booking portal...</p>
        </div>
      </Container>
    );
  }

  return (
    <div className="customer-portal">
      {/* Hero Section */}
      <div className="hero-section">
        <Container>
          <Row className="justify-content-center">
            <Col lg={10} xl={8}>
              <div className="hero-content text-center">
                <h1 className="display-4 mb-3">
                  Welcome to SkyNest Hotels, {user?.name || user?.username}!
                </h1>
                <p className="lead mb-4">
                  Book your perfect stay with us. Choose your preferred room type and we'll automatically reserve the best available room for you.
                </p>
              </div>
            </Col>
          </Row>
        </Container>
      </div>

      {/* Booking Form Section */}
      <Container className="booking-section">
        <Row className="justify-content-center">
          <Col lg={10} xl={8}>
            {/* Info Alert */}
            <Alert variant="info" className="mb-4">
              <FaInfoCircle className="me-2" />
              <strong>Instant Confirmation!</strong> Select your preferred room type, and our system will automatically find and reserve the best available room for your dates. Your room will be marked as unavailable for others immediately.
            </Alert>

            {/* Message Alert */}
            {message.text && (
              <Alert variant={message.type} className="mb-4" dismissible onClose={() => setMessage({ type: '', text: '' })}>
                {message.text}
              </Alert>
            )}

            <Card className="booking-card shadow">
              <Card.Body className="p-4 p-md-5">
                <h2 className="mb-4 text-center">
                  <FaCalendarAlt className="me-2" />
                  Book Your Stay
                </h2>

                <Form onSubmit={handleSubmit}>
                  <Row>
                    {/* Branch Selection */}
                    <Col md={6} className="mb-3">
                      <Form.Group>
                        <Form.Label>
                          <FaMapMarkerAlt className="me-2" />
                          Select Location *
                        </Form.Label>
                        <Form.Select
                          name="branch_id"
                          value={formData.branch_id}
                          onChange={handleInputChange}
                          required
                        >
                          <option value="">Choose a location...</option>
                          {branches.map(branch => (
                            <option key={branch.branch_id} value={branch.branch_id}>
                              {branch.branch_name}
                            </option>
                          ))}
                        </Form.Select>
                      </Form.Group>
                    </Col>

                    {/* Room Type Selection */}
                    <Col md={6} className="mb-3">
                      <Form.Group>
                        <Form.Label>
                          <FaBed className="me-2" />
                          Select Room Type *
                        </Form.Label>
                        <Form.Select
                          name="room_type_id"
                          value={formData.room_type_id}
                          onChange={handleInputChange}
                          required
                        >
                          <option value="">Choose room type...</option>
                          {roomTypes.map(type => (
                            <option key={type.room_type_id} value={type.room_type_id}>
                              {type.type_name} - Rs {parseFloat(type.daily_rate).toLocaleString()}/night 
                              {type.available_rooms > 0 && ` (${type.available_rooms} available)`}
                            </option>
                          ))}
                        </Form.Select>
                        <Form.Text className="text-muted">
                          We'll automatically assign the best available room of this type
                        </Form.Text>
                      </Form.Group>
                    </Col>

                    {/* Check-in Date */}
                    <Col md={6} className="mb-3">
                      <Form.Group>
                        <Form.Label>Check-in Date *</Form.Label>
                        <Form.Control
                          type="date"
                          name="expected_check_in"
                          value={formData.expected_check_in}
                          onChange={handleInputChange}
                          min={today}
                          required
                        />
                      </Form.Group>
                    </Col>

                    {/* Check-out Date */}
                    <Col md={6} className="mb-3">
                      <Form.Group>
                        <Form.Label>Check-out Date *</Form.Label>
                        <Form.Control
                          type="date"
                          name="expected_check_out"
                          value={formData.expected_check_out}
                          onChange={handleInputChange}
                          min={formData.expected_check_in || today}
                          required
                        />
                      </Form.Group>
                    </Col>

                    {/* Number of Guests (Capacity) */}
                    <Col md={12} className="mb-3">
                      <Form.Group>
                        <Form.Label>
                          <FaUsers className="me-2" />
                          Number of Guests *
                        </Form.Label>
                        <Form.Control
                          type="number"
                          name="capacity"
                          value={formData.capacity}
                          onChange={handleInputChange}
                          min="1"
                          max="10"
                          required
                        />
                        <Form.Text className="text-muted">
                          Total guests (adults + children)
                        </Form.Text>
                      </Form.Group>
                    </Col>

                    {/* Info Note */}
                    <Col xs={12} className="mb-4">
                      <Alert variant="light" className="mb-0">
                        <FaDoorOpen className="me-2" />
                        <small>
                          <strong>How it works:</strong> Once you submit this form, we will find the best available room of your selected type and automatically reserve it for your dates
                        </small>
                      </Alert>
                    </Col>

                    {/* Submit Button */}
                    <Col xs={12} className="text-center">
                      <Button 
                        variant="primary" 
                        size="lg" 
                        type="submit" 
                        disabled={submitting}
                        className="px-5"
                      >
                        {submitting ? (
                          <>
                            <Spinner animation="border" size="sm" className="me-2" />
                            Processing...
                          </>
                        ) : (
                          <>
                            <FaCheckCircle className="me-2" />
                            Reserve Room Now
                          </>
                        )}
                      </Button>
                    </Col>
                  </Row>
                </Form>
              </Card.Body>
            </Card>

            {/* Features Section */}
            <Row className="mt-5 features-section">
              <Col md={4} className="text-center mb-4 mb-md-0">
                <div className="feature-icon mb-3">
                  <FaCheckCircle size={40} className="text-success" />
                </div>
                <h5>Instant Confirmation</h5>
                <p className="text-muted">Automatic room assignment and confirmation</p>
              </Col>
              <Col md={4} className="text-center mb-4 mb-md-0">
                <div className="feature-icon mb-3">
                  <FaBed size={40} className="text-primary" />
                </div>
                <h5>Best Available Room</h5>
                <p className="text-muted">We select the perfect room for you</p>
              </Col>
              <Col md={4} className="text-center">
                <div className="feature-icon mb-3">
                  <FaMapMarkerAlt size={40} className="text-info" />
                </div>
                <h5>Prime Locations</h5>
                <p className="text-muted">Three beautiful branches to choose from</p>
              </Col>
            </Row>
          </Col>
        </Row>
      </Container>
    </div>
  );
};

export default CustomerPortal;
