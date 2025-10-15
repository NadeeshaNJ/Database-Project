import React, { createContext, useState, useContext, useEffect } from 'react';
import { jwtDecode } from 'jwt-decode';

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
  try {
    // call your backend API
    const response = await fetch('http://localhost:5000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identifier: email, password }) // matches backend code that checks username/email
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Login failed');
    }

    // ✅ decode the JWT to get user info
    const decodedUser = jwtDecode(data.token);

    // optional: include user object returned by backend
    const fullUser = {
      ...decodedUser,
      ...data.user, // merge backend’s user info
      token: data.token
    };

    // ✅ save to context and localStorage
    setUser(fullUser);
    localStorage.setItem('skyNestUser', JSON.stringify(fullUser));

    return fullUser;
  } catch (error) {
    throw error;
  }
};


  //   return new Promise((resolve, reject) => {
  //     setTimeout(() => {
  //       // Demo credentials matching ERD user_role enum
  //       const demoUsers = [
  //         {
  //           user_id: 1,
  //           username: 'admin',
  //           email: 'admin@skynest.com',
  //           password: 'admin123',
  //           name: 'Admin User',
  //           role: 'Admin',
  //           branch_id: null,
  //           branch_name: 'All Branches',
  //           phone: '+94 77 123 4567',
  //           avatar: null,
  //           permissions: ['all']
  //         },
  //         {
  //           user_id: 2,
  //           username: 'manager_colombo',
  //           email: 'manager.colombo@skynest.com',
  //           password: 'manager123',
  //           name: 'Anura Perera',
  //           role: 'Manager',
  //           branch_id: 1,
  //           branch_name: 'SkyNest Colombo',
  //           phone: '+94 11 234 5678',
  //           avatar: null,
  //           permissions: ['manage_rooms', 'manage_bookings', 'view_reports']
  //         },
  //         {
  //           user_id: 3,
  //           username: 'receptionist_kandy',
  //           email: 'receptionist@skynest.com',
  //           password: 'reception123',
  //           name: 'Shalini Fernando',
  //           role: 'Receptionist',
  //           branch_id: 2,
  //           branch_name: 'SkyNest Kandy',
  //           phone: '+94 81 234 5678',
  //           avatar: null,
  //           permissions: ['view_rooms', 'manage_bookings', 'view_guests']
  //         },
  //         {
  //           user_id: 4,
  //           username: 'accountant',
  //           email: 'accountant@skynest.com',
  //           password: 'accountant123',
  //           name: 'Rajitha Silva',
  //           role: 'Accountant',
  //           branch_id: 3,
  //           branch_name: 'SkyNest Galle',
  //           phone: '+94 91 234 5678',
  //           avatar: null,
  //           permissions: ['view_bookings', 'manage_billing', 'view_reports', 'manage_payments']
  //         }
  //       ];

  //       const foundUser = demoUsers.find(
  //         u => u.email === email && u.password === password
  //       );

  //       if (foundUser) {
  //         const { password, ...userWithoutPassword } = foundUser;
  //         setUser(userWithoutPassword);
  //         localStorage.setItem('skyNestUser', JSON.stringify(userWithoutPassword));
  //         resolve(userWithoutPassword);
  //       } else {
  //         reject(new Error('Invalid email or password'));
  //       }
  //     }, 1000);
  //   });
  // };

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
