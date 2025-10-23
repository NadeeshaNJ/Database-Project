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
      case 'Admin': return 'danger';
      case 'Manager': return 'primary';
      case 'Receptionist': return 'success';
      case 'Accountant': return 'warning';
      case 'Customer': return 'info';
      default: return 'secondary';
    }
  };

  return (
    <Container fluid className="py-4">
      <Row className="mb-4">
        <Col>
          <div style={{
            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            padding: '2rem',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(0,0,0,0.1)',
            color: 'white'
          }}>
            <h2 className="mb-1" style={{ color: 'white', fontWeight: '700' }}>
              <FaUser className="me-2" />
              My Profile
            </h2>
            <p style={{ marginBottom: 0, color: 'rgba(255, 255, 255, 0.9)' }}>View and manage your account information</p>
          </div>
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
          <Card style={{
            border: 'none',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
          }}>
            <Card.Body className="text-center">
              <div className="mb-3">
                <div 
                  className="rounded-circle text-white d-inline-flex align-items-center justify-content-center"
                  style={{ 
                    width: '120px', 
                    height: '120px', 
                    fontSize: '48px',
                    background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                    boxShadow: '0 4px 15px rgba(26, 35, 126, 0.3)'
                  }}
                >
                  <FaUser />
                </div>
              </div>
              <h4 style={{ color: '#1a237e', fontWeight: '700' }}>{user?.name}</h4>
              <p className="text-muted mb-2">{user?.email}</p>
              <Badge bg={getRoleBadgeColor(user?.role)} className="mb-3">
                {user?.role}
              </Badge>
              
              <div className="mt-4 text-start">
                <ListGroup variant="flush">
                  <ListGroup.Item>
                    <FaHotel className="me-2" style={{ color: '#1976d2' }} />
                    <strong>Branch:</strong> {user?.branch_name || 'N/A'}
                  </ListGroup.Item>
                  <ListGroup.Item>
                    <FaPhone className="me-2" style={{ color: '#1976d2' }} />
                    <strong>Phone:</strong> {user?.phone}
                  </ListGroup.Item>
                  <ListGroup.Item>
                    <FaBriefcase className="me-2" style={{ color: '#1976d2' }} />
                    <strong>Role:</strong> {user?.role}
                  </ListGroup.Item>
                </ListGroup>
              </div>
            </Card.Body>
          </Card>

          {/* Permissions Card */}
          <Card className="mt-3" style={{
            border: 'none',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
          }}>
            <Card.Header style={{
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              color: 'white',
              border: 'none',
              borderRadius: '1rem 1rem 0 0',
              padding: '1rem 1.5rem',
              fontWeight: '600'
            }}>
              <FaShieldAlt className="me-2" />
              <strong>Permissions</strong>
            </Card.Header>
            <Card.Body>
              <div className="d-flex flex-wrap gap-2">
                {user?.permissions?.includes('all') ? (
                  <Badge bg="danger">All Permissions</Badge>
                ) : (
                  user?.permissions?.map((perm, index) => (
                    <Badge key={index} style={{
                      background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)'
                    }}>
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
          <Card className="mb-4" style={{
            border: 'none',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
          }}>
            <Card.Header className="d-flex justify-content-between align-items-center" style={{
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              color: 'white',
              border: 'none',
              borderRadius: '1rem 1rem 0 0',
              padding: '1rem 1.5rem'
            }}>
              <div style={{ fontWeight: '600' }}>
                <FaUser className="me-2" />
                <strong>Personal Information</strong>
              </div>
              {!editing && (
                <Button 
                  size="sm"
                  onClick={() => setEditing(true)}
                  style={{
                    background: 'white',
                    color: '#1a237e',
                    border: 'none',
                    fontWeight: '600',
                    padding: '0.5rem 1rem',
                    transition: 'all 0.3s ease'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.transform = 'translateY(-2px)';
                    e.currentTarget.style.boxShadow = '0 4px 10px rgba(0,0,0,0.2)';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.transform = 'translateY(0)';
                    e.currentTarget.style.boxShadow = 'none';
                  }}
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
                    <Button 
                      type="submit"
                      style={{
                        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                        border: 'none',
                        fontWeight: '600',
                        padding: '0.5rem 1.5rem',
                        boxShadow: '0 4px 10px rgba(26, 35, 126, 0.3)',
                        transition: 'all 0.3s ease'
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.transform = 'translateY(-2px)';
                        e.currentTarget.style.boxShadow = '0 6px 15px rgba(25, 118, 210, 0.4)';
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.transform = 'translateY(0)';
                        e.currentTarget.style.boxShadow = '0 4px 10px rgba(26, 35, 126, 0.3)';
                      }}
                    >
                      <FaSave className="me-2" />
                      Save Changes
                    </Button>
                    <Button 
                      type="button" 
                      variant="secondary" 
                      onClick={handleCancel}
                      style={{
                        fontWeight: '600',
                        padding: '0.5rem 1.5rem'
                      }}
                    >
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
                    <p className="mb-0"><strong>{user?.branch_name || 'N/A'}</strong></p>
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
                    <p className="mb-0"><strong>#{user?.user_id}</strong></p>
                  </Col>
                </Row>
              )}
            </Card.Body>
          </Card>

          {/* Security Settings Card */}
          <Card style={{
            border: 'none',
            borderRadius: '1rem',
            boxShadow: '0 4px 15px rgba(0,0,0,0.1)'
          }}>
            <Card.Header style={{
              background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
              color: 'white',
              border: 'none',
              borderRadius: '1rem 1rem 0 0',
              padding: '1rem 1.5rem',
              fontWeight: '600'
            }}>
              <FaKey className="me-2" />
              <strong>Security Settings</strong>
            </Card.Header>
            <Card.Body>
              <Row>
                <Col md={6} className="mb-3">
                  <h6 style={{ color: '#1a237e', fontWeight: '600' }}>Password</h6>
                  <p className="text-muted small mb-2">Last changed: Never</p>
                  <Button 
                    variant="outline-primary" 
                    size="sm"
                    style={{
                      borderColor: '#1976d2',
                      color: '#1976d2',
                      fontWeight: '600'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.background = '#1976d2';
                      e.currentTarget.style.color = 'white';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.background = 'transparent';
                      e.currentTarget.style.color = '#1976d2';
                    }}
                  >
                    <FaKey className="me-2" />
                    Change Password
                  </Button>
                </Col>
                <Col md={6} className="mb-3">
                  <h6 style={{ color: '#1a237e', fontWeight: '600' }}>Two-Factor Authentication</h6>
                  <p className="text-muted small mb-2">Not enabled</p>
                  <Button 
                    variant="outline-success" 
                    size="sm"
                    style={{
                      fontWeight: '600'
                    }}
                  >
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
