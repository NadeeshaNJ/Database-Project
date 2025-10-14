import React, { createContext, useState, useContext, useEffect } from 'react';

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
    // Simulate API call
    // In production, this would call your backend API
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        // Demo credentials
        const demoUsers = [
          {
            id: 1,
            email: 'admin@skynest.com',
            password: 'admin123',
            name: 'Admin User',
            role: 'Administrator',
            hotel: 'All Branches',
            phone: '+94 77 123 4567',
            avatar: null,
            permissions: ['all']
          },
          {
            id: 2,
            email: 'manager.colombo@skynest.com',
            password: 'manager123',
            name: 'Anura Perera',
            role: 'Hotel Manager',
            hotel: 'SkyNest Colombo',
            phone: '+94 11 234 5678',
            avatar: null,
            permissions: ['manage_rooms', 'manage_bookings', 'view_reports']
          },
          {
            id: 3,
            email: 'receptionist@skynest.com',
            password: 'reception123',
            name: 'Shalini Fernando',
            role: 'Receptionist',
            hotel: 'SkyNest Kandy',
            phone: '+94 81 234 5678',
            avatar: null,
            permissions: ['view_rooms', 'manage_bookings', 'view_guests']
          }
        ];

        const foundUser = demoUsers.find(
          u => u.email === email && u.password === password
        );

        if (foundUser) {
          const { password, ...userWithoutPassword } = foundUser;
          setUser(userWithoutPassword);
          localStorage.setItem('skyNestUser', JSON.stringify(userWithoutPassword));
          resolve(userWithoutPassword);
        } else {
          reject(new Error('Invalid email or password'));
        }
      }, 1000);
    });
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
