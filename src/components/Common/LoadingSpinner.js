import React from 'react';
import { Spinner } from 'react-bootstrap';

const LoadingSpinner = ({ message = 'Loading...' }) => {
  return (
    <div 
      className="d-flex flex-column align-items-center justify-content-center" 
      style={{ padding: '40px' }}
    >
      <Spinner 
        animation="border" 
        style={{ 
          color: '#1976d2',
          width: '3rem',
          height: '3rem',
          borderWidth: '4px'
        }} 
      />
      <p 
        className="mt-3" 
        style={{ 
          color: '#0d47a1', 
          fontSize: '1.1rem',
          fontWeight: '500',
          margin: '16px 0 0 0'
        }}
      >
        {message}
      </p>
    </div>
  );
};

export default LoadingSpinner;