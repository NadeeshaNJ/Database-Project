import React, { useState } from 'react';
import { Container, Row, Col, Card, Form, Button, Alert, Spinner } from 'react-bootstrap';
import { useNavigate } from 'react-router-dom';
import { apiUrl } from '../utils/api';

const Register = () => {
  const [form, setForm] = useState({
    username: '',
    email: '',
    password: '',
    full_name: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const navigate = useNavigate();

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);

    try {
  const res = await fetch(apiUrl('/api/auth/register/customer'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: form.username,
          email: form.email,
          password: form.password,
          role: 'Customer',
          full_name: form.full_name
        })
      });

      const data = await res.json();
      if (res.ok && data.success) {
        setSuccess('Registration successful — you can now log in');
        setTimeout(() => navigate('/login'), 1200);
      } else {
        setError(data.error || (data.errors && data.errors.map(e=>e.msg).join(', ')) || 'Registration failed');
      }
    } catch (err) {
      setError(err.message || 'Registration failed');
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
          <Col md={8} lg={6}>
            <Card className="shadow-lg border-0" style={{ 
              borderRadius: '12px',
              overflow: 'hidden'
            }}>
              <div style={{
                background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                padding: '2rem',
                textAlign: 'center'
              }}>
                <h3 className="mb-0" style={{ 
                  color: 'white', 
                  fontWeight: '700',
                  fontSize: '1.75rem'
                }}>Create an Account</h3>
                <p style={{ color: 'rgba(255, 255, 255, 0.9)', marginBottom: 0, marginTop: '0.5rem' }}>
                  Join SkyNest Hotels
                </p>
              </div>
              <Card.Body className="p-4">
                {error && <Alert variant="danger">{error}</Alert>}
                {success && <Alert variant="success">{success}</Alert>}
                <Form onSubmit={handleSubmit}>
                  <Form.Group className="mb-3">
                    <Form.Label style={{ fontWeight: '600', color: '#1a237e' }}>Full Name</Form.Label>
                    <Form.Control 
                      name="full_name" 
                      value={form.full_name} 
                      onChange={handleChange} 
                      required 
                      style={{
                        padding: '0.75rem',
                        borderRadius: '8px',
                        border: '2px solid #e0e6ed',
                        transition: 'all 0.3s ease'
                      }}
                      onFocus={(e) => {
                        e.target.style.borderColor = '#1976d2';
                        e.target.style.boxShadow = '0 0 0 0.2rem rgba(25, 118, 210, 0.25)';
                      }}
                      onBlur={(e) => {
                        e.target.style.borderColor = '#e0e6ed';
                        e.target.style.boxShadow = 'none';
                      }}
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label style={{ fontWeight: '600', color: '#1a237e' }}>Username</Form.Label>
                    <Form.Control 
                      name="username" 
                      value={form.username} 
                      onChange={handleChange} 
                      required 
                      style={{
                        padding: '0.75rem',
                        borderRadius: '8px',
                        border: '2px solid #e0e6ed',
                        transition: 'all 0.3s ease'
                      }}
                      onFocus={(e) => {
                        e.target.style.borderColor = '#1976d2';
                        e.target.style.boxShadow = '0 0 0 0.2rem rgba(25, 118, 210, 0.25)';
                      }}
                      onBlur={(e) => {
                        e.target.style.borderColor = '#e0e6ed';
                        e.target.style.boxShadow = 'none';
                      }}
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label style={{ fontWeight: '600', color: '#1a237e' }}>Email</Form.Label>
                    <Form.Control 
                      type="email" 
                      name="email" 
                      value={form.email} 
                      onChange={handleChange} 
                      required 
                      style={{
                        padding: '0.75rem',
                        borderRadius: '8px',
                        border: '2px solid #e0e6ed',
                        transition: 'all 0.3s ease'
                      }}
                      onFocus={(e) => {
                        e.target.style.borderColor = '#1976d2';
                        e.target.style.boxShadow = '0 0 0 0.2rem rgba(25, 118, 210, 0.25)';
                      }}
                      onBlur={(e) => {
                        e.target.style.borderColor = '#e0e6ed';
                        e.target.style.boxShadow = 'none';
                      }}
                    />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label style={{ fontWeight: '600', color: '#1a237e' }}>Password</Form.Label>
                    <Form.Control 
                      type="password" 
                      name="password" 
                      value={form.password} 
                      onChange={handleChange} 
                      required 
                      style={{
                        padding: '0.75rem',
                        borderRadius: '8px',
                        border: '2px solid #e0e6ed',
                        transition: 'all 0.3s ease'
                      }}
                      onFocus={(e) => {
                        e.target.style.borderColor = '#1976d2';
                        e.target.style.boxShadow = '0 0 0 0.2rem rgba(25, 118, 210, 0.25)';
                      }}
                      onBlur={(e) => {
                        e.target.style.borderColor = '#e0e6ed';
                        e.target.style.boxShadow = 'none';
                      }}
                    />
                  </Form.Group>

                  <div className="d-grid mt-4">
                    <Button 
                      type="submit" 
                      disabled={loading}
                      style={{
                        background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
                        border: 'none',
                        padding: '0.75rem',
                        fontSize: '1.1rem',
                        fontWeight: '600',
                        borderRadius: '8px',
                        boxShadow: '0 4px 15px rgba(26, 35, 126, 0.4)',
                        transition: 'all 0.3s ease'
                      }}
                      onMouseEnter={(e) => {
                        if (!loading) {
                          e.currentTarget.style.transform = 'translateY(-2px)';
                          e.currentTarget.style.boxShadow = '0 6px 20px rgba(25, 118, 210, 0.5)';
                        }
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.transform = 'translateY(0)';
                        e.currentTarget.style.boxShadow = '0 4px 15px rgba(26, 35, 126, 0.4)';
                      }}
                    >
                      {loading ? (
                        <>
                          <Spinner as="span" animation="border" size="sm" className="me-2" />
                          Creating...
                        </>
                      ) : 'Create Account'}
                    </Button>
                  </div>
                </Form>
                <div className="mt-3 text-center">
                  <small className="text-muted">
                    Already have an account? {' '}
                    <a 
                      href="/login" 
                      style={{ 
                        color: '#1976d2', 
                        textDecoration: 'none',
                        fontWeight: '600'
                      }}
                      onMouseEnter={(e) => e.target.style.textDecoration = 'underline'}
                      onMouseLeave={(e) => e.target.style.textDecoration = 'none'}
                    >
                      Sign in
                    </a>
                  </small>
                </div>
              </Card.Body>
            </Card>
          </Col>
        </Row>
      </Container>
    </div>
  );
};

export default Register;
