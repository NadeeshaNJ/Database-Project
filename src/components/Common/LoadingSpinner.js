import React from 'react';
import { Spinner } from 'react-bootstrap';

const LoadingSpinner = ({ message = 'Loading...' }) => {
  return (
    <div className="d-flex flex-column align-items-center justify-content-center p-4">
      <Spinner animation="border" variant="primary" />
      <p className="mt-2 text-muted">{message}</p>
    </div>
  );
};

export default LoadingSpinner;