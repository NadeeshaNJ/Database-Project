import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Spinner, Container } from 'react-bootstrap';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <Container className="d-flex justify-content-center align-items-center" style={{ minHeight: '100vh' }}>
        <div className="text-center">
          <Spinner 
            animation="border" 
            style={{ 
              color: '#1976d2',
              width: '3rem',
              height: '3rem',
              borderWidth: '4px'
            }} 
          />
          <p className="mt-3" style={{ color: '#0d47a1', fontSize: '1.1rem', fontWeight: '500' }}>Loading...</p>
        </div>
      </Container>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return children;
};

export default ProtectedRoute;
