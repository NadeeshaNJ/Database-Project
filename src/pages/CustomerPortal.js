import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Form, Button, Alert, Spinner, Badge } from 'react-bootstrap';
import { FaCalendarAlt, FaUsers, FaBed, FaMapMarkerAlt, FaCheckCircle, FaInfoCircle } from 'react-icons/fa';
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

  // Form state
  const [formData, setFormData] = useState({
    branch_id: '',
    room_type_id: '',
    check_in_date: '',
    check_out_date: '',
    num_adults: 1,
    num_children: 0,
    special_requests: ''
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
        
        // Backend returns: {success: true, data: {branches: [...], total: X}}
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
        
        // Backend returns: {success: true, data: [...]}
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
    if (!formData.branch_id || !formData.room_type_id || !formData.check_in_date || !formData.check_out_date) {
      setMessage({ type: 'danger', text: 'Please fill in all required fields.' });
      setSubmitting(false);
      return;
    }

    if (new Date(formData.check_out_date) <= new Date(formData.check_in_date)) {
      setMessage({ type: 'danger', text: 'Check-out date must be after check-in date.' });
      setSubmitting(false);
      return;
    }

    try {
      const token = user?.token || JSON.parse(localStorage.getItem('skyNestUser'))?.token;
      
      // Create pre-booking
      const preBookingData = {
        guest_id: user?.user_id || user?.id,
        branch_id: parseInt(formData.branch_id),
        room_type_id: parseInt(formData.room_type_id),
        check_in_date: formData.check_in_date,
        check_out_date: formData.check_out_date,
        num_adults: parseInt(formData.num_adults),
        num_children: parseInt(formData.num_children),
        special_requests: formData.special_requests || null,
        status: 'Pending'
      };

      const response = await fetch(apiUrl('/api/bookings/pre-booking'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(preBookingData)
      });

      const result = await response.json();

      if (response.ok) {
        setMessage({ 
          type: 'success', 
          text: '🎉 Pre-booking request submitted successfully! Our team will contact you shortly to confirm your reservation.' 
        });
        
        // Reset form
        setFormData({
          branch_id: '',
          room_type_id: '',
          check_in_date: '',
          check_out_date: '',
          num_adults: 1,
          num_children: 0,
          special_requests: ''
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
                  Book your perfect stay with us. Choose from our luxurious rooms across three stunning locations.
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
              This is a <strong>pre-booking request</strong>. Our team will review your request and contact you to confirm availability and finalize your reservation.
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
                          Select Branch *
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
                              {branch.branch_name} - {branch.location}
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
                          Room Type *
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
                            </option>
                          ))}
                        </Form.Select>
                      </Form.Group>
                    </Col>

                    {/* Check-in Date */}
                    <Col md={6} className="mb-3">
                      <Form.Group>
                        <Form.Label>Check-in Date *</Form.Label>
                        <Form.Control
                          type="date"
                          name="check_in_date"
                          value={formData.check_in_date}
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
                          name="check_out_date"
                          value={formData.check_out_date}
                          onChange={handleInputChange}
                          min={formData.check_in_date || today}
                          required
                        />
                      </Form.Group>
                    </Col>

                    {/* Number of Adults */}
                    <Col md={6} className="mb-3">
                      <Form.Group>
                        <Form.Label>
                          <FaUsers className="me-2" />
                          Number of Adults *
                        </Form.Label>
                        <Form.Control
                          type="number"
                          name="num_adults"
                          value={formData.num_adults}
                          onChange={handleInputChange}
                          min="1"
                          max="10"
                          required
                        />
                      </Form.Group>
                    </Col>

                    {/* Number of Children */}
                    <Col md={6} className="mb-3">
                      <Form.Group>
                        <Form.Label>
                          <FaUsers className="me-2" />
                          Number of Children
                        </Form.Label>
                        <Form.Control
                          type="number"
                          name="num_children"
                          value={formData.num_children}
                          onChange={handleInputChange}
                          min="0"
                          max="10"
                        />
                      </Form.Group>
                    </Col>

                    {/* Special Requests */}
                    <Col xs={12} className="mb-4">
                      <Form.Group>
                        <Form.Label>Special Requests</Form.Label>
                        <Form.Control
                          as="textarea"
                          rows={3}
                          name="special_requests"
                          value={formData.special_requests}
                          onChange={handleInputChange}
                          placeholder="Any special requirements? (e.g., early check-in, high floor, etc.)"
                        />
                      </Form.Group>
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
                            Submitting...
                          </>
                        ) : (
                          <>
                            <FaCheckCircle className="me-2" />
                            Submit Pre-Booking Request
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
                <h5>Easy Booking</h5>
                <p className="text-muted">Simple and quick booking process</p>
              </Col>
              <Col md={4} className="text-center mb-4 mb-md-0">
                <div className="feature-icon mb-3">
                  <FaBed size={40} className="text-primary" />
                </div>
                <h5>Luxury Rooms</h5>
                <p className="text-muted">Comfortable and well-equipped rooms</p>
              </Col>
              <Col md={4} className="text-center">
                <div className="feature-icon mb-3">
                  <FaMapMarkerAlt size={40} className="text-info" />
                </div>
                <h5>Prime Locations</h5>
                <p className="text-muted">Three beautiful locations to choose from</p>
              </Col>
            </Row>
          </Col>
        </Row>
      </Container>
    </div>
  );
};

export default CustomerPortal;
