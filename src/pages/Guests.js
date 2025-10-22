import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Button, Modal, Form, Table, InputGroup, Spinner, Alert } from 'react-bootstrap';
import { FaPlus, FaTrash, FaSearch } from 'react-icons/fa';
import { useBranch } from '../context/BranchContext';

// ✅ Use environment-aware API URL
const API_BASE = process.env.REACT_APP_API_BASE || 'http://localhost:5000';
const API_URL = `${API_BASE}/api/guests`;
const API_CREATE_URL = `${API_BASE}/api/guests/createnew`;
const API_DELETE_URL = `${API_BASE}/api/guests/delete`;

const Guests = () => {
  const { selectedBranchId } = useBranch();
  const [guests, setGuests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    full_name: '',
    email: '',
    phone: '',
    nationality: '',
    nic: '',
    gender: '',
    address: '',
    date_of_birth: ''
  });
  const [formLoading, setFormLoading] = useState(false);
  const [formError, setFormError] = useState('');

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
      gender: 'Male',
      checkInDate: '2025-09-14',
      status: 'Checked In',
      address: '123 Main St, New York, USA',
      dateOfBirth: '1985-05-15'
    },
    {
      id: 2,
      firstName: 'Jane',
      lastName: 'Smith',
      email: 'jane.smith@email.com',
      phone: '+1-555-0456',
      nationality: 'Canadian',
      idNumber: 'C987654321',
      gender: 'Female',
      checkInDate: '2025-09-13',
      status: 'Checked Out',
      address: '456 Maple Ave, Toronto, Canada',
      dateOfBirth: '1990-08-22'
    },
    {
      id: 3,
      firstName: 'Rajesh',
      lastName: 'Patel',
      email: 'rajesh.patel@email.com',
      phone: '+94-77-123-4567',
      nationality: 'Sri Lankan',
      idNumber: '901234567V',
      gender: 'Male',
      checkInDate: '2025-10-20',
      status: 'Checked In',
      address: '789 Galle Road, Colombo 3, Sri Lanka',
      dateOfBirth: '1988-12-10'
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
        
        // Get auth token
        const storedUser = localStorage.getItem('skyNestUser');
        const token = storedUser ? JSON.parse(storedUser).token : null;
        
        const res = await fetch(url, {
          headers: {
            'Content-Type': 'application/json',
            ...(token && { 'Authorization': `Bearer ${token}` })
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
          gender: guest.gender || '',
          address: guest.address || '',
          dateOfBirth: guest.date_of_birth || '',
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

  const handleShowModal = () => {
    // Reset form for new guest
    setFormData({
      full_name: '',
      email: '',
      phone: '',
      nationality: '',
      nic: '',
      gender: '',
      address: '',
      date_of_birth: ''
    });
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setFormError('');
    setFormData({
      full_name: '',
      email: '',
      phone: '',
      nationality: '',
      nic: '',
      gender: '',
      address: '',
      date_of_birth: ''
    });
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
    setFormLoading(true);
    setFormError('');

    try {
      // Prepare data exactly as backend expects
      const guestData = {
        full_name: formData.full_name.trim(),
        email: formData.email || undefined,
        phone: formData.phone || undefined,
        nationality: formData.nationality || undefined,
        nic: formData.nic || undefined,
        gender: formData.gender || undefined,
        address: formData.address || undefined,
        date_of_birth: formData.date_of_birth || undefined
      };

      // Remove undefined values to avoid sending them
      Object.keys(guestData).forEach(key => {
        if (guestData[key] === undefined || guestData[key] === '') {
          delete guestData[key];
        }
      });

      // Only create new guests
      const url = API_CREATE_URL;
      const method = 'POST';

      // Get auth token
      const storedUser = localStorage.getItem('skyNestUser');
      const token = storedUser ? JSON.parse(storedUser).token : null;

      console.log('🚀 Sending guest data:', {
        url,
        method,
        data: guestData,
        hasToken: !!token
      });

      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          ...(token && { 'Authorization': `Bearer ${token}` })
        },
        body: JSON.stringify(guestData)
      });

      console.log('📡 Response status:', response.status);
      
      let responseData;
      try {
        responseData = await response.json();
      } catch (parseError) {
        // If response is not JSON, create a generic error object
        responseData = { error: `Server returned status ${response.status}` };
      }
      
      console.log('📡 Response data:', responseData);

      if (response.ok) {
        console.log('✅ Guest saved successfully:', responseData);
        // Refresh the guests list
        window.location.reload(); // Simple refresh - you can implement a more elegant solution
        handleCloseModal();
      } else {
        console.error('❌ Failed to save guest:', responseData);
        
        // Extract error message from different possible response formats
        let errorMessage = 'Failed to save guest';
        if (responseData?.error) {
          errorMessage = responseData.error;
        } else if (responseData?.message) {
          errorMessage = responseData.message;
        } else if (responseData?.errors && Array.isArray(responseData.errors)) {
          errorMessage = responseData.errors.map(err => err.msg || err.message || err).join(', ');
        }
        
        throw new Error(errorMessage);
      }
    } catch (err) {
      console.error('Error saving guest:', err);
      
      // Check if this is a network error (backend not available)
      if (err.message.includes('fetch') || err.message.includes('Failed to fetch') || err.message.includes('NetworkError') || !navigator.onLine) {
        // Backend is not available - show demo mode message and close modal
        alert('Guest added successfully (demo mode - backend not connected)');
        handleCloseModal();
        // Optionally reload for demo mode
        window.location.reload();
      } else {
        // Real backend error - show in modal and keep it open
        setFormError(err.message);
        // Don't close modal, let user try again or cancel manually
      }
    } finally {
      setFormLoading(false);
    }
  };

  const handleDeleteGuest = async (guestId) => {
    if (!window.confirm('Are you sure you want to delete this guest?')) {
      return;
    }

    try {
      // Get auth token
      const storedUser = localStorage.getItem('skyNestUser');
      const token = storedUser ? JSON.parse(storedUser).token : null;

      console.log('🗑️ Deleting guest:', { guestId, hasToken: !!token });

      const response = await fetch(`${API_DELETE_URL}/${guestId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          ...(token && { 'Authorization': `Bearer ${token}` })
        }
      });

      console.log('📡 Delete response status:', response.status);

      if (response.ok) {
        console.log('✅ Guest deleted successfully');
        // Refresh the guests list
        window.location.reload();
      } else {
        const responseData = await response.json().catch(() => ({ error: 'Failed to delete guest' }));
        console.error('❌ Failed to delete guest:', responseData);
        throw new Error(responseData?.error || responseData?.message || 'Failed to delete guest');
      }
    } catch (err) {
      console.error('Error deleting guest:', err);
      
      // Check if this is a network error (backend not available)
      if (err.message.includes('fetch') || err.message.includes('Failed to fetch') || err.message.includes('NetworkError') || !navigator.onLine) {
        alert('Guest deleted successfully (demo mode - backend not connected)');
      } else {
        // Real backend error
        alert(`Error deleting guest: ${err.message}`);
      }
      
      // Always refresh to update the UI
      window.location.reload();
    }
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
        <div className="page-header">
          <h2 >Guest Management</h2>
          </div>
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
                      <Button 
                        variant="outline-danger" 
                        size="sm"
                        onClick={() => handleDeleteGuest(guest.id)}
                      >
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
          <Modal.Title>Add New Guest</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {formError && (
            <Alert variant="danger" dismissible onClose={() => setFormError('')}>
              {formError}
            </Alert>
          )}
          <Form onSubmit={handleSubmit}>
            <Row>
              {/* Personal Information */}
              <Col xs={12}>
                <h6 className="text-primary mb-3">Personal Information</h6>
              </Col>
              
              <Col md={12}>
                <Form.Group className="mb-3">
                  <Form.Label>Full Name *</Form.Label>
                  <Form.Control
                    type="text"
                    name="full_name"
                    value={formData.full_name}
                    onChange={handleInputChange}
                    placeholder="Enter full name"
                    maxLength={120}
                    required
                  />
                  <Form.Text className="text-muted">
                    Maximum 120 characters
                  </Form.Text>
                </Form.Group>
              </Col>

              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Email Address</Form.Label>
                  <Form.Control
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    placeholder="Enter email address"
                    maxLength={150}
                  />
                  <Form.Text className="text-muted">
                    Optional, max 150 characters
                  </Form.Text>
                </Form.Group>
              </Col>

              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Phone Number</Form.Label>
                  <Form.Control
                    type="tel"
                    name="phone"
                    value={formData.phone}
                    onChange={handleInputChange}
                    placeholder="Enter phone number"
                    maxLength={30}
                  />
                  <Form.Text className="text-muted">
                    Optional, max 30 characters
                  </Form.Text>
                </Form.Group>
              </Col>

              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Nationality</Form.Label>
                  <Form.Select
                    name="nationality"
                    value={formData.nationality}
                    onChange={handleInputChange}
                  >
                    <option value="">Select nationality</option>
                    <option value="Sri Lankan">Sri Lankan</option>
                    <option value="Indian">Indian</option>
                    <option value="American">American</option>
                    <option value="British">British</option>
                    <option value="Canadian">Canadian</option>
                    <option value="Australian">Australian</option>
                    <option value="German">German</option>
                    <option value="French">French</option>
                    <option value="Japanese">Japanese</option>
                    <option value="Chinese">Chinese</option>
                    <option value="Other">Other</option>
                  </Form.Select>
                  <Form.Text className="text-muted">
                    Optional, max 80 characters
                  </Form.Text>
                </Form.Group>
              </Col>

              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>ID Number (NIC/Passport)</Form.Label>
                  <Form.Control
                    type="text"
                    name="nic"
                    value={formData.nic}
                    onChange={handleInputChange}
                    placeholder="Enter NIC or Passport number"
                    maxLength={30}
                  />
                  <Form.Text className="text-muted">
                    Optional, max 30 characters
                  </Form.Text>
                </Form.Group>
              </Col>

              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Gender</Form.Label>
                  <Form.Select
                    name="gender"
                    value={formData.gender}
                    onChange={handleInputChange}
                  >
                    <option value="">Select gender</option>
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                    <option value="Other">Other</option>
                    <option value="Prefer not to say">Prefer not to say</option>
                  </Form.Select>
                  <Form.Text className="text-muted">
                    Optional, max 20 characters
                  </Form.Text>
                </Form.Group>
              </Col>

              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Date of Birth</Form.Label>
                  <Form.Control
                    type="date"
                    name="date_of_birth"
                    value={formData.date_of_birth}
                    onChange={handleInputChange}
                  />
                  <Form.Text className="text-muted">
                    Format: YYYY-MM-DD
                  </Form.Text>
                </Form.Group>
              </Col>

              <Col md={12}>
                <Form.Group className="mb-3">
                  <Form.Label>Address</Form.Label>
                  <Form.Control
                    as="textarea"
                    rows={3}
                    name="address"
                    value={formData.address}
                    onChange={handleInputChange}
                    placeholder="Enter full address"
                  />
                  <Form.Text className="text-muted">
                    Optional - Full residential address
                  </Form.Text>
                </Form.Group>
              </Col>


            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal} disabled={formLoading}>
            Cancel
          </Button>
          <Button 
            variant="primary" 
            onClick={handleSubmit}
            disabled={formLoading}
          >
            {formLoading ? (
              <>
                <Spinner animation="border" size="sm" className="me-2" />
                Adding...
              </>
            ) : (
              'Add Guest'
            )}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default Guests;
