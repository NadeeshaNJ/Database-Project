import React, { useState } from 'react';
import { Container, Row, Col, Card, Form, Button, Badge, Alert, ListGroup } from 'react-bootstrap';
import { FaUser, FaEnvelope, FaPhone, FaHotel, FaBriefcase, FaEdit, FaSave, FaTimes, FaKey, FaShieldAlt } from 'react-icons/fa';
import { useAuth } from '../context/AuthContext';

const Profile = () => {
  const { user, updateProfile } = useAuth();
  const [editing, setEditing] = useState(false);
  const [formData, setFormData] = useState({
    name: user?.name || '',
    email: user?.email || '',
    phone: user?.phone || ''
  });
  const [success, setSuccess] = useState('');

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    updateProfile(formData);
    setSuccess('Profile updated successfully!');
    setEditing(false);
    setTimeout(() => setSuccess(''), 3000);
  };

  const handleCancel = () => {
    setFormData({
      name: user?.name || '',
      email: user?.email || '',
      phone: user?.phone || ''
    });
    setEditing(false);
  };

  const getRoleBadgeColor = (role) => {
    switch (role) {
      case 'Administrator': return 'danger';
      case 'Hotel Manager': return 'primary';
      case 'Receptionist': return 'success';
      default: return 'secondary';
    }
  };

  return (
    <Container fluid className="py-4">
      <Row className="mb-4">
        <Col>
          <h2 className="mb-1">My Profile</h2>
          <p className="text-muted">View and manage your account information</p>
        </Col>
      </Row>

      {success && (
        <Alert variant="success" dismissible onClose={() => setSuccess('')}>
          {success}
        </Alert>
      )}

      <Row>
        {/* Profile Overview Card */}
        <Col lg={4} className="mb-4">
          <Card className="shadow-sm">
            <Card.Body className="text-center">
              <div className="mb-3">
                <div 
                  className="rounded-circle bg-primary text-white d-inline-flex align-items-center justify-content-center"
                  style={{ width: '120px', height: '120px', fontSize: '48px' }}
                >
                  <FaUser />
                </div>
              </div>
              <h4>{user?.name}</h4>
              <p className="text-muted mb-2">{user?.email}</p>
              <Badge bg={getRoleBadgeColor(user?.role)} className="mb-3">
                {user?.role}
              </Badge>
              
              <div className="mt-4 text-start">
                <ListGroup variant="flush">
                  <ListGroup.Item>
                    <FaHotel className="me-2 text-primary" />
                    <strong>Hotel:</strong> {user?.hotel}
                  </ListGroup.Item>
                  <ListGroup.Item>
                    <FaPhone className="me-2 text-primary" />
                    <strong>Phone:</strong> {user?.phone}
                  </ListGroup.Item>
                  <ListGroup.Item>
                    <FaBriefcase className="me-2 text-primary" />
                    <strong>Role:</strong> {user?.role}
                  </ListGroup.Item>
                </ListGroup>
              </div>
            </Card.Body>
          </Card>

          {/* Permissions Card */}
          <Card className="shadow-sm mt-3">
            <Card.Header>
              <FaShieldAlt className="me-2" />
              <strong>Permissions</strong>
            </Card.Header>
            <Card.Body>
              <div className="d-flex flex-wrap gap-2">
                {user?.permissions?.includes('all') ? (
                  <Badge bg="danger">All Permissions</Badge>
                ) : (
                  user?.permissions?.map((perm, index) => (
                    <Badge key={index} bg="primary">
                      {perm.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                    </Badge>
                  ))
                )}
              </div>
            </Card.Body>
          </Card>
        </Col>

        {/* Profile Information Card */}
        <Col lg={8}>
          <Card className="shadow-sm mb-4">
            <Card.Header className="d-flex justify-content-between align-items-center">
              <div>
                <FaUser className="me-2" />
                <strong>Personal Information</strong>
              </div>
              {!editing && (
                <Button 
                  variant="outline-primary" 
                  size="sm"
                  onClick={() => setEditing(true)}
                >
                  <FaEdit className="me-2" />
                  Edit Profile
                </Button>
              )}
            </Card.Header>
            <Card.Body>
              {editing ? (
                <Form onSubmit={handleSubmit}>
                  <Row>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Full Name</Form.Label>
                        <Form.Control
                          type="text"
                          name="name"
                          value={formData.name}
                          onChange={handleChange}
                          required
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Email Address</Form.Label>
                        <Form.Control
                          type="email"
                          name="email"
                          value={formData.email}
                          onChange={handleChange}
                          required
                        />
                      </Form.Group>
                    </Col>
                  </Row>
                  <Row>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Phone Number</Form.Label>
                        <Form.Control
                          type="tel"
                          name="phone"
                          value={formData.phone}
                          onChange={handleChange}
                          required
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Hotel Branch</Form.Label>
                        <Form.Control
                          type="text"
                          value={user?.hotel}
                          disabled
                          readOnly
                        />
                        <Form.Text className="text-muted">
                          Contact administrator to change hotel assignment
                        </Form.Text>
                      </Form.Group>
                    </Col>
                  </Row>
                  <div className="d-flex gap-2">
                    <Button type="submit" variant="primary">
                      <FaSave className="me-2" />
                      Save Changes
                    </Button>
                    <Button type="button" variant="secondary" onClick={handleCancel}>
                      <FaTimes className="me-2" />
                      Cancel
                    </Button>
                  </div>
                </Form>
              ) : (
                <Row>
                  <Col md={6} className="mb-3">
                    <label className="text-muted small">Full Name</label>
                    <p className="mb-0"><strong>{user?.name}</strong></p>
                  </Col>
                  <Col md={6} className="mb-3">
                    <label className="text-muted small">Email Address</label>
                    <p className="mb-0"><strong>{user?.email}</strong></p>
                  </Col>
                  <Col md={6} className="mb-3">
                    <label className="text-muted small">Phone Number</label>
                    <p className="mb-0"><strong>{user?.phone}</strong></p>
                  </Col>
                  <Col md={6} className="mb-3">
                    <label className="text-muted small">Hotel Branch</label>
                    <p className="mb-0"><strong>{user?.hotel}</strong></p>
                  </Col>
                  <Col md={6} className="mb-3">
                    <label className="text-muted small">Role</label>
                    <p className="mb-0">
                      <Badge bg={getRoleBadgeColor(user?.role)}>
                        {user?.role}
                      </Badge>
                    </p>
                  </Col>
                  <Col md={6} className="mb-3">
                    <label className="text-muted small">User ID</label>
                    <p className="mb-0"><strong>#{user?.id}</strong></p>
                  </Col>
                </Row>
              )}
            </Card.Body>
          </Card>

          {/* Security Settings Card */}
          <Card className="shadow-sm">
            <Card.Header>
              <FaKey className="me-2" />
              <strong>Security Settings</strong>
            </Card.Header>
            <Card.Body>
              <Row>
                <Col md={6} className="mb-3">
                  <h6>Password</h6>
                  <p className="text-muted small mb-2">Last changed: Never</p>
                  <Button variant="outline-primary" size="sm">
                    <FaKey className="me-2" />
                    Change Password
                  </Button>
                </Col>
                <Col md={6} className="mb-3">
                  <h6>Two-Factor Authentication</h6>
                  <p className="text-muted small mb-2">Not enabled</p>
                  <Button variant="outline-success" size="sm">
                    <FaShieldAlt className="me-2" />
                    Enable 2FA
                  </Button>
                </Col>
              </Row>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
};

export default Profile;
