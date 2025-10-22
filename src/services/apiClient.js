import axios from 'axios';

// Base API configuration
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for adding auth tokens
apiClient.interceptors.request.use(
  (config) => {
    // Check both possible token storage locations
    let token = localStorage.getItem('authToken');
    
    // If not found, check the skyNestUser object
    if (!token) {
      const skyNestUser = localStorage.getItem('skyNestUser');
      if (skyNestUser) {
        try {
          const userData = JSON.parse(skyNestUser);
          token = userData.token;
        } catch (e) {
          console.error('Error parsing skyNestUser:', e);
        }
      }
    }
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for handling errors
apiClient.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized access - clear all auth-related data
      localStorage.removeItem('authToken');
      localStorage.removeItem('user');
      localStorage.removeItem('skyNestUser');
      // Redirect to login page - check if we're on GitHub Pages or local
      const basePath = process.env.PUBLIC_URL || '';
      window.location.href = `${basePath}/login`;
    }
    return Promise.reject(error);
  }
);

export default apiClient;