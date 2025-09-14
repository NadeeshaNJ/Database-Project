import React from 'react';
import { Alert } from 'react-bootstrap';

const ErrorMessage = ({ message, variant = 'danger', onClose }) => {
  return (
    <Alert variant={variant} dismissible={onClose ? true : false} onClose={onClose}>
      {message}
    </Alert>
  );
};

export default ErrorMessage;