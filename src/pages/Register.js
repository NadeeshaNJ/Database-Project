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
    <div className="login-page" style={{ minHeight: '100vh', background: 'linear-gradient(135deg, #48547C 0%, #749DD0 100%)', display: 'flex', alignItems: 'center', padding: '20px' }}>
      <Container>
        <Row className="justify-content-center">
          <Col md={8} lg={6}>
            <Card className="shadow-lg border-0" style={{ borderRadius: '12px' }}>
              <Card.Body className="p-4">
                <h3 className="mb-4 text-center">Create an account</h3>
                {error && <Alert variant="danger">{error}</Alert>}
                {success && <Alert variant="success">{success}</Alert>}
                <Form onSubmit={handleSubmit}>
                  <Form.Group className="mb-3">
                    <Form.Label>Full name</Form.Label>
                    <Form.Control name="full_name" value={form.full_name} onChange={handleChange} required />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Username</Form.Label>
                    <Form.Control name="username" value={form.username} onChange={handleChange} required />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Email</Form.Label>
                    <Form.Control type="email" name="email" value={form.email} onChange={handleChange} required />
                  </Form.Group>
                  <Form.Group className="mb-3">
                    <Form.Label>Password</Form.Label>
                    <Form.Control type="password" name="password" value={form.password} onChange={handleChange} required />
                  </Form.Group>

                  <div className="d-grid">
                    <Button type="submit" disabled={loading} variant="primary">
                      {loading ? (
                        <>
                          <Spinner as="span" animation="border" size="sm" className="me-2" />
                          Creating...
                        </>
                      ) : 'Create account'}
                    </Button>
                  </div>
                </Form>
                <div className="mt-3 text-center">
                  <small className="text-muted">Already have an account? <a href="/login">Sign in</a></small>
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
