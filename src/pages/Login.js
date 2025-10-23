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
        navigate('/admin');
      }
    } catch (err) {
      console.error('❌ Login error:', err);
      setError(err.message || 'Failed to login');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page" style={{ 
      minHeight: '100vh', 
      background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
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
                  background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                  color: 'white',
                  padding: '40px'
                }}>
                  <div className="h-100 d-flex flex-column justify-content-center">
                    <div className="text-center mb-4">
                      <FaHotel size={80} className="mb-3" style={{ color: 'white', filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.2))' }} />
                      <h2 className="fw-bold" style={{ 
                        color: 'white !important', 
                        fontSize: '2.5rem',
                        textShadow: '0 2px 4px rgba(0,0,0,0.3)',
                        letterSpacing: '1px'
                      }}>SkyNest Hotels</h2>
                      <p className="lead" style={{ 
                        color: 'white !important', 
                        fontSize: '1.1rem',
                        fontWeight: '500',
                        textShadow: '0 1px 2px rgba(0,0,0,0.2)'
                      }}>Hotel Reservation & Guest Services</p>
                      <p className="small" style={{ 
                        color: 'white !important', 
                        fontSize: '0.95rem',
                        fontWeight: '400',
                        opacity: 0.95
                      }}>Management System</p>
                    </div>
                    
                    <div className="mt-5">
                      <h5 className="mb-3" style={{ 
                        color: 'white !important', 
                        fontSize: '1.3rem',
                        fontWeight: '600',
                        textShadow: '0 1px 2px rgba(0,0,0,0.2)'
                      }}>Our Locations</h5>
                      <ul className="list-unstyled" style={{ 
                        color: 'white !important',
                        fontSize: '1.05rem',
                        fontWeight: '400'
                      }}>
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
                      <FaHotel size={50} style={{ color: '#1976d2' }} />
                      <h3 className="mt-2" style={{ color: '#1a237e', fontWeight: 'bold' }}>SkyNest Hotels</h3>
                    </div>

                    <h3 className="mb-4 text-center" style={{ color: '#1a237e', fontWeight: '600' }}>Welcome Back</h3>
                    
                    {error && (
                      <Alert variant="danger" dismissible onClose={() => setError('')}>
                        {error}
                      </Alert>
                    )}

                    <Form onSubmit={handleSubmit}>
                      <Form.Group className="mb-3">
                        <Form.Label style={{ color: '#1a237e', fontWeight: '600' }}>
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
                        <Form.Label style={{ color: '#1a237e', fontWeight: '600' }}>
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
                            background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                            border: 'none',
                            fontWeight: '600',
                            padding: '12px',
                            transition: 'all 0.3s ease'
                          }}
                          onMouseEnter={(e) => {
                            if (!loading) {
                              e.target.style.transform = 'translateY(-2px)';
                              e.target.style.boxShadow = '0 4px 12px rgba(25, 118, 210, 0.4)';
                            }
                          }}
                          onMouseLeave={(e) => {
                            if (!loading) {
                              e.target.style.transform = 'translateY(0)';
                              e.target.style.boxShadow = 'none';
                            }
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

                    {/* Additional Links */}
                    <div className="mt-4 text-center">
                      <p className="mb-2">
                        <small style={{ color: '#495057' }}>
                          Don't have an account?{' '}
                          <a href="/register" style={{ color: '#1976d2', fontWeight: 'bold', textDecoration: 'none' }}>
                            Register as Customer
                          </a>
                        </small>
                      </p>
                      <p className="mb-0">
                        <small>
                          <a href="/" style={{ color: '#0d47a1', textDecoration: 'none', fontWeight: '600' }}>
                            ← Back to Home
                          </a>
                        </small>
                      </p>
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
