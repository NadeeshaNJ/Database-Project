import React from 'react';
import { Modal, Button } from 'react-bootstrap';

const ConfirmDialog = ({ show, onHide, onConfirm, title, message, variant = 'danger' }) => {
  return (
    <Modal show={show} onHide={onHide} centered>
      <Modal.Header 
        closeButton 
        style={{
          background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
          color: 'white',
          borderBottom: '2px solid #1976d2'
        }}
      >
        <Modal.Title style={{ color: 'white', fontWeight: 'bold' }}>{title}</Modal.Title>
      </Modal.Header>
      <Modal.Body style={{ padding: '24px', fontSize: '1rem', color: '#333' }}>
        <p style={{ margin: 0 }}>{message}</p>
      </Modal.Body>
      <Modal.Footer style={{ borderTop: '1px solid #e2e8f0', padding: '16px 24px' }}>
        <Button 
          onClick={onHide}
          style={{
            background: '#6c757d',
            border: 'none',
            padding: '10px 24px',
            borderRadius: '6px',
            fontWeight: '500',
            transition: 'all 0.3s ease'
          }}
          onMouseEnter={(e) => e.target.style.background = '#5a6268'}
          onMouseLeave={(e) => e.target.style.background = '#6c757d'}
        >
          Cancel
        </Button>
        <Button 
          onClick={onConfirm}
          style={{
            background: variant === 'danger' ? '#dc3545' : 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
            border: 'none',
            padding: '10px 24px',
            borderRadius: '6px',
            fontWeight: '500',
            transition: 'all 0.3s ease'
          }}
          onMouseEnter={(e) => {
            e.target.style.background = variant === 'danger' ? '#c82333' : '#0d47a1';
          }}
          onMouseLeave={(e) => {
            e.target.style.background = variant === 'danger' ? '#dc3545' : 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)';
          }}
        >
          Confirm
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

export default ConfirmDialog;