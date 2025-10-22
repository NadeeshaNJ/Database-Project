import React, { useEffect, useState } from 'react';
import { authAPI, roomAPI, guestAPI, bookingAPI } from '../services/api';

/**
 * Backend Integration Test Component
 * Use this component to test if your frontend is properly connected to the backend
 */
const BackendIntegrationTest = () => {
  const [results, setResults] = useState({});
  const [loading, setLoading] = useState(false);

  const addResult = (test, status, message, data = null) => {
    setResults(prev => ({
      ...prev,
      [test]: { status, message, data, timestamp: new Date().toISOString() }
    }));
  };

  const testBackendConnection = async () => {
    setLoading(true);
    setResults({});

    // Test 1: Health Check
    try {
      const response = await fetch('http://localhost:5000/api/health');
      const data = await response.json();
      addResult('health', 'success', 'Backend is running', data);
    } catch (error) {
      addResult('health', 'error', 'Cannot connect to backend', error.message);
    }

    // Test 2: Get Rooms (No Auth Required)
    try {
      const response = await roomAPI.getAllRooms({ limit: 5 });
      addResult('rooms', 'success', `Found ${response.data?.rooms?.length || 0} rooms`, response.data);
    } catch (error) {
      addResult('rooms', 'error', 'Failed to fetch rooms', error.response?.data || error.message);
    }

    // Test 3: Get Guests (Auth Required)
    try {
      const response = await guestAPI.getAllGuests({ limit: 5 });
      addResult('guests', 'success', `Found ${response.data?.guests?.length || 0} guests`, response.data);
    } catch (error) {
      if (error.response?.status === 401) {
        addResult('guests', 'warning', 'Authentication required (expected)', error.response?.data);
      } else {
        addResult('guests', 'error', 'Failed to fetch guests', error.response?.data || error.message);
      }
    }

    // Test 4: Get Bookings (Auth Required)
    try {
      const response = await bookingAPI.getAllBookings({ limit: 5 });
      addResult('bookings', 'success', `Found ${response.data?.bookings?.length || 0} bookings`, response.data);
    } catch (error) {
      if (error.response?.status === 401) {
        addResult('bookings', 'warning', 'Authentication required (expected)', error.response?.data);
      } else {
        addResult('bookings', 'error', 'Failed to fetch bookings', error.response?.data || error.message);
      }
    }

    setLoading(false);
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'success': return '#28a745';
      case 'warning': return '#f59e0b';
      case 'error': return '#dc3545';
      default: return '#6c757d';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'success': return '✓';
      case 'warning': return '⚠';
      case 'error': return '✗';
      default: return '?';
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h2 style={styles.title}>🔧 Backend Integration Test</h2>
        <p style={styles.subtitle}>Test your frontend connection to the backend API</p>
        
        <button 
          onClick={testBackendConnection} 
          disabled={loading}
          style={styles.button}
        >
          {loading ? 'Testing...' : 'Run Tests'}
        </button>

        <div style={styles.info}>
          <p><strong>Backend URL:</strong> http://localhost:5000/api</p>
          <p><strong>Expected Status:</strong> Backend must be running on port 5000</p>
        </div>

        {Object.keys(results).length > 0 && (
          <div style={styles.results}>
            <h3 style={styles.resultsTitle}>Test Results:</h3>
            
            {Object.entries(results).map(([test, result]) => (
              <div 
                key={test} 
                style={{
                  ...styles.resultItem,
                  borderLeftColor: getStatusColor(result.status)
                }}
              >
                <div style={styles.resultHeader}>
                  <span style={{ color: getStatusColor(result.status), fontSize: '20px' }}>
                    {getStatusIcon(result.status)}
                  </span>
                  <strong style={styles.testName}>{test.toUpperCase()}</strong>
                </div>
                <p style={styles.resultMessage}>{result.message}</p>
                {result.data && (
                  <details style={styles.details}>
                    <summary style={styles.summary}>View Response Data</summary>
                    <pre style={styles.pre}>
                      {JSON.stringify(result.data, null, 2)}
                    </pre>
                  </details>
                )}
              </div>
            ))}
          </div>
        )}

        <div style={styles.instructions}>
          <h4>📝 Instructions:</h4>
          <ol>
            <li>Make sure the backend server is running on port 5000</li>
            <li>Click "Run Tests" to test the connection</li>
            <li>Green (✓) = Success</li>
            <li>Yellow (⚠) = Warning (usually auth required)</li>
            <li>Red (✗) = Error</li>
          </ol>
        </div>
      </div>
    </div>
  );
};

const styles = {
  container: {
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)',
    padding: '40px 20px',
    fontFamily: 'Arial, sans-serif'
  },
  card: {
    maxWidth: '900px',
    margin: '0 auto',
    backgroundColor: 'white',
    borderRadius: '12px',
    boxShadow: '0 4px 20px rgba(0,0,0,0.1)',
    padding: '40px',
    border: '1px solid #e2e8f0'
  },
  title: {
    color: '#1a237e',
    marginBottom: '10px',
    fontSize: '32px',
    fontWeight: 'bold'
  },
  subtitle: {
    color: '#666',
    marginBottom: '30px',
    fontSize: '16px'
  },
  button: {
    background: 'linear-gradient(135deg, #1a237e 0%, #0d47a1 100%)',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    padding: '14px 32px',
    fontSize: '16px',
    fontWeight: '600',
    cursor: 'pointer',
    marginBottom: '25px',
    transition: 'all 0.3s ease',
    boxShadow: '0 2px 8px rgba(25, 118, 210, 0.3)'
  },
  info: {
    background: 'rgba(25, 118, 210, 0.08)',
    padding: '20px',
    borderRadius: '8px',
    borderLeft: '4px solid #1976d2',
    marginBottom: '25px'
  },
  results: {
    marginTop: '30px'
  },
  resultsTitle: {
    color: '#1a237e',
    marginBottom: '20px',
    fontSize: '24px',
    fontWeight: 'bold'
  },
  resultItem: {
    backgroundColor: '#f8f9fa',
    padding: '20px',
    borderRadius: '8px',
    borderLeft: '4px solid',
    marginBottom: '15px',
    boxShadow: '0 2px 4px rgba(0,0,0,0.05)'
  },
  resultHeader: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    marginBottom: '10px'
  },
  testName: {
    fontSize: '18px',
    color: '#1a237e',
    fontWeight: 'bold'
  },
  resultMessage: {
    color: '#555',
    margin: '8px 0',
    fontSize: '15px'
  },
  details: {
    marginTop: '12px'
  },
  summary: {
    cursor: 'pointer',
    color: '#1976d2',
    fontSize: '14px',
    fontWeight: 'bold'
  },
  pre: {
    backgroundColor: '#f4f4f4',
    padding: '15px',
    borderRadius: '6px',
    overflow: 'auto',
    fontSize: '12px',
    marginTop: '10px',
    border: '1px solid #e2e8f0'
  },
  instructions: {
    marginTop: '30px',
    background: 'rgba(245, 158, 11, 0.1)',
    padding: '20px',
    borderRadius: '8px',
    borderLeft: '4px solid #f59e0b'
  }
};

export default BackendIntegrationTest;
