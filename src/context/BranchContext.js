import React, { createContext, useState, useContext, useEffect } from 'react';
import { useAuth } from './AuthContext';
import { apiUrl } from '../utils/api';

const BranchContext = createContext();

export const useBranch = () => {
  const context = useContext(BranchContext);
  if (!context) {
    throw new Error('useBranch must be used within a BranchProvider');
  }
  return context;
};

export const BranchProvider = ({ children }) => {
  const { user } = useAuth();
  const [selectedBranchId, setSelectedBranchId] = useState('All');
  const [branches, setBranches] = useState([]);
  const [loading, setLoading] = useState(true);

  // Initialize branch based on user role
  useEffect(() => {
    if (user) {
      console.log('🔍 BranchContext - User object:', user);
      console.log('🔍 BranchContext - User role:', user.role);
      console.log('🔍 BranchContext - User branch_id:', user.branch_id);
      
      // If user is not Admin and has a branch_id, lock them to their branch
      if (user.role !== 'Admin' && user.branch_id) {
        console.log(`🔒 User ${user.name || user.username} locked to branch ${user.branch_id}`);
        setSelectedBranchId(user.branch_id);
      } else if (user.role === 'Admin') {
        console.log('👑 Admin user - can access all branches');
        setSelectedBranchId('All');
      } else {
        console.warn('⚠️ Non-admin user but no branch_id found!', {
          role: user.role,
          branch_id: user.branch_id,
          user: user
        });
      }
    }
  }, [user]);

  // Fetch branches on mount
  useEffect(() => {
    const fetchBranches = async () => {
      try {
        const response = await fetch(apiUrl('/api/branches'));
        const data = await response.json();
        
        if (data.success && data.data && data.data.branches) {
          setBranches(data.data.branches);
        } else {
          setBranches([]);
        }
      } catch (err) {
        console.error('Error fetching branches:', err);
        setBranches([]);
      } finally {
        setLoading(false);
      }
    };

    fetchBranches();
  }, []);

  // Prevent non-admin users from changing branch
  const handleSetSelectedBranchId = (branchId) => {
    if (user && user.role !== 'Admin' && user.branch_id) {
      console.warn('⚠️ Non-admin users cannot change branch');
      return; // Silently ignore attempt to change branch
    }
    setSelectedBranchId(branchId);
  };

  const value = {
    selectedBranchId,
    setSelectedBranchId: handleSetSelectedBranchId,
    branches,
    loading,
    selectedBranch: Array.isArray(branches) ? branches.find(b => b.branch_id === selectedBranchId) || null : null,
    isLocked: user && user.role !== 'Admin' && user.branch_id ? true : false
  };

  return (
    <BranchContext.Provider value={value}>
      {children}
    </BranchContext.Provider>
  );
};
