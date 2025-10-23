import React from 'react';
import { Alert } from 'react-bootstrap';

const ErrorMessage = ({ message, variant = 'danger', onClose }) => {
  const getAlertStyles = () => {
    switch(variant) {
      case 'danger':
        return {
          background: '#f8d7da',
          color: '#721c24',
          border: '1px solid #f5c6cb',
          borderLeft: '4px solid #dc3545'
        };
      case 'warning':
        return {
          background: '#fff3cd',
          color: '#856404',
          border: '1px solid #ffeaa7',
          borderLeft: '4px solid #f59e0b'
        };
      case 'success':
        return {
          background: '#d4edda',
          color: '#155724',
          border: '1px solid #c3e6cb',
          borderLeft: '4px solid #28a745'
        };
      case 'info':
        return {
          background: '#d1ecf1',
          color: '#0c5460',
          border: '1px solid #bee5eb',
          borderLeft: '4px solid #1976d2'
        };
      default:
        return {
          background: '#f8d7da',
          color: '#721c24',
          border: '1px solid #f5c6cb',
          borderLeft: '4px solid #dc3545'
        };
    }
  };

  return (
    <Alert 
      variant={variant} 
      dismissible={onClose ? true : false} 
      onClose={onClose}
      style={{
        ...getAlertStyles(),
        borderRadius: '8px',
        padding: '16px 20px',
        fontSize: '1rem',
        fontWeight: '500',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
      }}
    >
      {message}
    </Alert>
  );
};

export default ErrorMessage;