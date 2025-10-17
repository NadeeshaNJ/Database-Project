import React, { createContext, useState, useContext, useEffect } from 'react';
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
  const [selectedBranchId, setSelectedBranchId] = useState('All');
  const [branches, setBranches] = useState([]);
  const [loading, setLoading] = useState(true);

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

  const value = {
    selectedBranchId,
    setSelectedBranchId,
    branches,
    loading,
    selectedBranch: Array.isArray(branches) ? branches.find(b => b.branch_id === selectedBranchId) || null : null
  };

  return (
    <BranchContext.Provider value={value}>
      {children}
    </BranchContext.Provider>
  );
};
