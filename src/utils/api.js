const API_BASE = process.env.REACT_APP_API_BASE || 'https://skynest-backend-api.onrender.com';

export const apiUrl = (path) => `${API_BASE}${path}`;

export default apiUrl;
