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
      const parsedUser = JSON.parse(storedUser);
      console.log('📦 Loaded user from localStorage:', parsedUser);
      console.log('📦 Stored branch_id:', parsedUser.branch_id);
      setUser(parsedUser);
    }
    setLoading(false);
  }, []);
  
  const login = async (email, password) => {
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
        // Server user data takes priority to ensure correct role and branch_id
        const fullUser = { 
          ...decoded, 
          ...serverUser, 
          token,
          // CRITICAL: Ensure branch_id is set from server response (takes priority)
          branch_id: serverUser.branch_id || decoded.branchId || null,
          // Also ensure user_id is set correctly
          user_id: serverUser.user_id || decoded.userId || null
        };
        
        // Debug logging
        console.log('🔍 Login Debug:');
        console.log('- Server User:', serverUser);
        console.log('- Server User branch_id:', serverUser.branch_id);
        console.log('- Decoded Token:', decoded);
        console.log('- Decoded branchId:', decoded.branchId);
        console.log('- Full User Object:', fullUser);
        console.log('- Final Role:', fullUser.role);
        console.log('- Final Branch ID:', fullUser.branch_id);
        
        setUser(fullUser);
        localStorage.setItem('skyNestUser', JSON.stringify(fullUser));
        return fullUser;
      }

      // Backend returned non-OK or success=false -> throw the actual error
      console.error('⚠️ Backend login failed:', result);
      throw new Error(result?.error || 'Invalid credentials');
    } catch (error) {
      // Re-throw the error - no fallback to demo users
      console.error('❌ Login error:', error);
      throw error;
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
