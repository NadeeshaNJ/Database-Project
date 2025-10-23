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
      console.log('🔍 BranchContext - User logged in:', user.username);
      console.log('🔍 BranchContext - User role:', user.role, '(type:', typeof user.role, ')');
      console.log('🔍 BranchContext - User branch_id:', user.branch_id, '(type:', typeof user.branch_id, ')');
      console.log('🔍 BranchContext - Is Admin check:', user.role === 'Admin', user.role === 'admin');
      
      // Check if user has a branch_id (could be string or number)
      const hasBranchId = user.branch_id !== null && user.branch_id !== undefined && user.branch_id !== '';
      
      // CRITICAL: Admin should NEVER be locked, even if they have a branch_id
      if (user.role !== 'Admin' && hasBranchId) {
        console.log(`🔒 User locked to branch ${user.branch_id}`);
        // Convert to number if it's a string
        const branchId = typeof user.branch_id === 'string' ? parseInt(user.branch_id, 10) : user.branch_id;
        setSelectedBranchId(branchId);
      } else if (user.role === 'Admin') {
        console.log('👑 Admin user - can access all branches (branch_id ignored)');
        setSelectedBranchId('All');
      } else {
        console.log('🌐 User has no branch restriction - showing all branches');
        setSelectedBranchId('All');
      }
    } else {
      // User logged out - reset to 'All'
      console.log('🚪 User logged out - resetting branch to All');
      setSelectedBranchId('All');
    }
  }, [user]);

  // Fetch branches on mount
  useEffect(() => {
    const fetchBranches = async () => {
      try {
        const response = await fetch(`${apiUrl}/branches`);
        const data = await response.json();
        
        if (data.success && data.data && data.data.branches) {
          console.log('🏢 Fetched branches:', data.data.branches.length);
          setBranches(data.data.branches);
        } else {
          console.warn('⚠️ No branches in response');
          setBranches([]);
        }
      } catch (err) {
        console.error('❌ Error fetching branches:', err.message);
        setBranches([]);
      } finally {
        setLoading(false);
      }
    };

    fetchBranches();
  }, []);

  // Prevent non-admin users from changing branch
  const handleSetSelectedBranchId = (branchId) => {
    // CRITICAL FIX: Admin should ALWAYS be able to change branch
    if (user && user.role === 'Admin') {
      console.log('👑 Admin changing branch to:', branchId);
      setSelectedBranchId(branchId);
      return;
    }
    
    const hasBranchId = user?.branch_id !== null && user?.branch_id !== undefined && user?.branch_id !== '';
    
    if (user && user.role !== 'Admin' && hasBranchId) {
      console.warn('⚠️ Non-admin users cannot change branch');
      return; // Silently ignore attempt to change branch
    }
    
    setSelectedBranchId(branchId);
  };

  // Calculate isLocked based on current user state
  // CRITICAL FIX: Admin should NEVER be locked, regardless of branch_id
  const hasBranchId = user?.branch_id !== null && user?.branch_id !== undefined && user?.branch_id !== '';
  const isLocked = user && user.role !== 'Admin' && hasBranchId; // Admin is never locked
  const isNotAdmin = user ? user.role !== 'Admin' : false;

  // Find the selected branch with proper type comparison
  const selectedBranch = selectedBranchId === 'All' ? null : 
    branches.find(b => b.branch_id === selectedBranchId || b.branch_id === String(selectedBranchId)) || null;

  const value = {
    selectedBranchId,
    setSelectedBranchId: handleSetSelectedBranchId,
    branches,
    loading,
    selectedBranch,
    isLocked,
    isNotAdmin
  };

  return (
    <BranchContext.Provider value={value}>
      {children}
    </BranchContext.Provider>
  );
};
