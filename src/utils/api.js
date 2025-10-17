const API_BASE = process.env.REACT_APP_API_BASE || 'http://localhost:5000';

export const apiUrl = (path) => `${API_BASE}${path}`;

export default apiUrl;
