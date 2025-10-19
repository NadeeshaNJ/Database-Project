import React, { useState } from 'react';
import { Container, Row, Col, Card, Form, Button, Alert, Spinner } from 'react-bootstrap';
import { FaHotel, FaUser, FaLock, FaSignInAlt } from 'react-icons/fa';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';

const Login = () => {
  const [identifier, setIdentifier] = useState(''); // username only
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const loggedInUser = await login(identifier, password);
      
      console.log('🔍 Login successful - User:', loggedInUser);
      console.log('🔍 User role:', loggedInUser?.role);
      console.log('🔍 Role type:', typeof loggedInUser?.role);
      
      // Redirect based on role (case-insensitive check)
      const userRole = loggedInUser?.role?.toLowerCase();
      
      if (userRole === 'customer') {
        console.log('✅ Redirecting to customer portal');
        navigate('/customer');
      } else {
        console.log('✅ Redirecting to admin dashboard');
        navigate('/dashboard');
      }
    } catch (err) {
      console.error('❌ Login error:', err);
      setError(err.message || 'Failed to login');
    } finally {
      setLoading(false);
    }
  };
  const demoCredentials = [
    { username: 'admin', password: 'password123', role: 'Admin' },
    { username: 'manager_colombo', password: 'password123', role: 'Manager - Colombo' },
    { username: 'recept_colombo', password: 'password123', role: 'Receptionist - Colombo' },
    { username: 'accountant_colombo', password: 'password123', role: 'Accountant - Colombo' }
  ];

  return (
    <div className="login-page" style={{ 
      minHeight: '100vh', 
      background: 'linear-gradient(135deg, #48547C 0%, #749DD0 100%)',
      display: 'flex',
      alignItems: 'center',
      padding: '20px'
    }}>
      <Container>
        <Row className="justify-content-center">
          <Col md={10} lg={8}>
            <Card className="shadow-lg border-0" style={{ borderRadius: '15px', overflow: 'hidden' }}>
              <Row className="g-0">
                {/* Left Side - Branding */}
                <Col md={6} className="d-none d-md-block" style={{
                  background: 'linear-gradient(135deg, #48547C 0%, #749DD0 100%)',
                  color: 'white',
                  padding: '40px'
                }}>
                  <div className="h-100 d-flex flex-column justify-content-center">
                    <div className="text-center mb-4">
                      <FaHotel size={80} className="mb-3" />
                      <h2 className="fw-bold">SkyNest Hotels</h2>
                      <p className="lead">Hotel Reservation & Guest Services</p>
                      <p className="small">Management System</p>
                    </div>
                    
                    <div className="mt-5">
                      <h5 className="mb-3">Our Locations</h5>
                      <ul className="list-unstyled">
                        <li className="mb-2">🏖️ Colombo - Beach Resort</li>
                        <li className="mb-2">⛰️ Kandy - Mountain View</li>
                        <li className="mb-2">🏰 Galle - Historic Fort</li>
                      </ul>
                    </div>
                  </div>
                </Col>

                {/* Right Side - Login Form */}
                <Col md={6}>
                  <Card.Body className="p-4 p-md-5">
                    <div className="text-center d-md-none mb-4">
                      <FaHotel size={50} style={{ color: '#749DD0' }} />
                      <h3 className="mt-2">SkyNest Hotels</h3>
                    </div>

                    <h3 className="mb-4 text-center">Welcome Back</h3>
                    
                    {error && (
                      <Alert variant="danger" dismissible onClose={() => setError('')}>
                        {error}
                      </Alert>
                    )}

                    <Form onSubmit={handleSubmit}>
                      <Form.Group className="mb-3">
                        <Form.Label>
                          <FaUser className="me-2" />
                          Username
                        </Form.Label>
                        <Form.Control
                          type="text"
                          placeholder="Enter username"
                          value={identifier}
                          onChange={(e) => setIdentifier(e.target.value)}
                          required
                          size="lg"
                        />
                      </Form.Group>

                      <Form.Group className="mb-4">
                        <Form.Label>
                          <FaLock className="me-2" />
                          Password
                        </Form.Label>
                        <Form.Control
                          type="password"
                          placeholder="Enter password"
                          value={password}
                          onChange={(e) => setPassword(e.target.value)}
                          required
                          size="lg"
                        />
                      </Form.Group>

                      <div className="d-grid mb-3">
                        <Button 
                          variant="primary" 
                          type="submit" 
                          size="lg"
                          disabled={loading}
                          style={{
                            background: 'linear-gradient(135deg, #749DD0 0%, #92AAD1 100%)',
                            border: 'none'
                          }}
                        >
                          {loading ? (
                            <>
                              <Spinner
                                as="span"
                                animation="border"
                                size="sm"
                                className="me-2"
                              />
                              Signing in...
                            </>
                          ) : (
                            <>
                              <FaSignInAlt className="me-2" />
                              Sign In
                            </>
                          )}
                        </Button>
                      </div>
                    </Form>

                    {/* Demo Credentials */}
                    <div className="mt-4 pt-4 border-top">
                      <small className="text-muted d-block mb-2">Demo Credentials:</small>
                      {demoCredentials.map((cred, index) => (
                        <div key={index} className="small mb-2 p-2 bg-light rounded">
                          <strong>{cred.role}:</strong><br />
                          <code className="text-primary">{cred.username}</code><br />
                          <code className="text-secondary">{cred.password}</code>
                          <Button
                            size="sm"
                            variant="outline-primary"
                            className="ms-2"
                            onClick={() => {
                              setIdentifier(cred.username);
                              setPassword(cred.password);
                            }}
                          >
                            Use
                          </Button>
                        </div>
                      ))}
                    </div>
                  </Card.Body>
                </Col>
              </Row>
            </Card>
          </Col>
        </Row>
      </Container>
    </div>
  );
};

export default Login;
