import React, { createContext, useState, useContext, useEffect } from 'react';
import { jwtDecode } from 'jwt-decode';
import { apiUrl } from '../utils/api';

const AuthContext = createContext(null);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is already logged in (from localStorage)
    const storedUser = localStorage.getItem('skyNestUser');
    if (storedUser) {
      setUser(JSON.parse(storedUser));
    }
    setLoading(false);
  }, []);
  
  const login = async (email, password) => {
    const demoUsers = [
      {
        user_id: 1,
        username: 'admin',
        email: 'admin@skynest.com',
        password: 'admin123',
        name: 'Admin User',
        role: 'Admin',
        branch_id: null,
        branch_name: 'All Branches',
        phone: '+94 77 123 4567',
        avatar: null,
        permissions: ['all']
      },
      {
        user_id: 2,
        username: 'manager_colombo',
        email: 'manager.colombo@skynest.com',
        password: 'manager123',
        name: 'Anura Perera',
        role: 'Manager',
        branch_id: 1,
        branch_name: 'SkyNest Colombo',
        phone: '+94 11 234 5678',
        avatar: null,
        permissions: ['manage_rooms', 'manage_bookings', 'view_reports']
      },
      {
        user_id: 3,
        username: 'receptionist_kandy',
        email: 'receptionist@skynest.com',
        password: 'reception123',
        name: 'Shalini Fernando',
        role: 'Receptionist',
        branch_id: 2,
        branch_name: 'SkyNest Kandy',
        phone: '+94 81 234 5678',
        avatar: null,
        permissions: ['view_rooms', 'manage_bookings', 'view_guests']
      },
      {
        user_id: 4,
        username: 'accountant',
        email: 'accountant@skynest.com',
        password: 'accountant123',
        name: 'Rajitha Silva',
        role: 'Accountant',
        branch_id: 3,
        branch_name: 'SkyNest Galle',
        phone: '+94 91 234 5678',
        avatar: null,
        permissions: ['view_bookings', 'manage_billing', 'view_reports', 'manage_payments']
      }
    ];

    try {
      // call backend API - backend expects `username` (can be email) and `password`
      const response = await fetch(apiUrl('/api/auth/login'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: email, password })
      });

      const result = await response.json();

      if (response.ok && result && result.success) {
        const token = result.data?.token;
        const serverUser = result.data?.user || {};
        // decode token to get payload claims if needed
        let decoded = {};
        try { decoded = jwtDecode(token); } catch (e) { /* ignore decode errors */ }

        // Merge decoded token and server user data
        // Server user data takes priority to ensure correct role
        const fullUser = { ...decoded, ...serverUser, token };
        
        // Debug logging
        console.log('🔍 Login Debug:');
        console.log('- Server User:', serverUser);
        console.log('- Decoded Token:', decoded);
        console.log('- Full User Object:', fullUser);
        console.log('- Final Role:', fullUser.role);
        
        setUser(fullUser);
        localStorage.setItem('skyNestUser', JSON.stringify(fullUser));
        return fullUser;
      }

      // Backend returned non-OK or success=false -> throw the actual error
      console.error('⚠️ Backend login failed:', result);
      throw new Error(result?.error || 'Invalid credentials');
    } catch (error) {
      // If it's a network error, try demo mode, otherwise throw the error
      if (error.message && !error.message.includes('fetch')) {
        // This is a login error from backend, not network issue
        throw error;
      }
      
      // Network error -> fallback to demo users
      console.warn('⚠️ Backend not reachable — using demo mode', error?.message || error);
      const foundUser = demoUsers.find(u => (u.email === email || u.username === email) && u.password === password);
      if (!foundUser) throw new Error('Backend unreachable and no matching demo credentials');

      const userWithoutPassword = { ...foundUser };
      delete userWithoutPassword.password;
      setUser(userWithoutPassword);
      localStorage.setItem('skyNestUser', JSON.stringify(userWithoutPassword));
      return userWithoutPassword;
    }
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('skyNestUser');
  };

  const updateProfile = (updatedData) => {
    const updatedUser = { ...user, ...updatedData };
    setUser(updatedUser);
    localStorage.setItem('skyNestUser', JSON.stringify(updatedUser));
  };

  const value = {
    user,
    login,
    logout,
    updateProfile,
    loading,
    isAuthenticated: !!user
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
