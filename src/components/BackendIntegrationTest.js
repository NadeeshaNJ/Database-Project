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
      case 'warning': return '#ffc107';
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
    backgroundColor: '#f8f9fa',
    padding: '40px 20px',
    fontFamily: 'Arial, sans-serif'
  },
  card: {
    maxWidth: '900px',
    margin: '0 auto',
    backgroundColor: 'white',
    borderRadius: '8px',
    boxShadow: '0 2px 10px rgba(0,0,0,0.1)',
    padding: '30px'
  },
  title: {
    color: '#333',
    marginBottom: '10px',
    fontSize: '28px'
  },
  subtitle: {
    color: '#666',
    marginBottom: '20px',
    fontSize: '16px'
  },
  button: {
    backgroundColor: '#007bff',
    color: 'white',
    border: 'none',
    borderRadius: '5px',
    padding: '12px 30px',
    fontSize: '16px',
    cursor: 'pointer',
    marginBottom: '20px',
    transition: 'background-color 0.3s'
  },
  info: {
    backgroundColor: '#e7f3ff',
    padding: '15px',
    borderRadius: '5px',
    borderLeft: '4px solid #007bff',
    marginBottom: '20px'
  },
  results: {
    marginTop: '30px'
  },
  resultsTitle: {
    color: '#333',
    marginBottom: '15px'
  },
  resultItem: {
    backgroundColor: '#f8f9fa',
    padding: '15px',
    borderRadius: '5px',
    borderLeft: '4px solid',
    marginBottom: '15px'
  },
  resultHeader: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    marginBottom: '8px'
  },
  testName: {
    fontSize: '16px',
    color: '#333'
  },
  resultMessage: {
    color: '#555',
    margin: '5px 0'
  },
  details: {
    marginTop: '10px'
  },
  summary: {
    cursor: 'pointer',
    color: '#007bff',
    fontSize: '14px',
    fontWeight: 'bold'
  },
  pre: {
    backgroundColor: '#f4f4f4',
    padding: '10px',
    borderRadius: '4px',
    overflow: 'auto',
    fontSize: '12px',
    marginTop: '10px'
  },
  instructions: {
    marginTop: '30px',
    backgroundColor: '#fff3cd',
    padding: '15px',
    borderRadius: '5px',
    borderLeft: '4px solid #ffc107'
  }
};

export default BackendIntegrationTest;
