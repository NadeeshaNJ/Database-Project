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

  console.log('🔍 CustomerRoute - User role:', user?.role);
  console.log('🔍 CustomerRoute - Checking access for:', user);

  // If not a customer, redirect to admin dashboard (case-insensitive check)
  const userRole = user?.role?.toLowerCase();
  
  if (userRole !== 'customer') {
    console.log('⚠️ Not a customer, redirecting to dashboard');
    return <Navigate to="/dashboard" replace />;
  }

  console.log('✅ Customer access granted');
  return children;
};

export default CustomerRoute;
