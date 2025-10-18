import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Spinner, Container } from 'react-bootstrap';

/**
 * CustomerRoute - Only allows Customer role to access
 * Redirects all other roles to admin dashboard
 */
const CustomerRoute = ({ children }) => {
  const { user, isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <Container className="d-flex justify-content-center align-items-center" style={{ minHeight: '100vh' }}>
        <div className="text-center">
          <Spinner animation="border" variant="primary" />
          <p className="mt-3">Loading...</p>
        </div>
      </Container>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  // If not a customer, redirect to admin dashboard
  if (user?.role !== 'Customer') {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
};

export default CustomerRoute;
