import React, { createContext, useContext, useState, useEffect } from 'react';
import { mockUser, mockUserRoles } from '../data/mockData';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState('employe');
  const [userEntreprise, setUserEntreprise] = useState('');

  useEffect(() => {
    // Simulate auth check with mock data
    setTimeout(() => {
      const isLoggedIn = localStorage.getItem('mockLoggedIn');
      if (isLoggedIn === 'true') {
        setUser(mockUser);
        setSession({ user: mockUser });
        setUserRole(mockUser.role);
        setUserEntreprise(mockUser.entreprise);
      }
      setLoading(false);
    }, 1000);
  }, []);

  const login = () => {
    localStorage.setItem('mockLoggedIn', 'true');
    setUser(mockUser);
    setSession({ user: mockUser });
    setUserRole(mockUser.role);
    setUserEntreprise(mockUser.entreprise);
  };

  const logout = () => {
    localStorage.removeItem('mockLoggedIn');
    setUser(null);
    setSession(null);
    setUserRole('employe');
    setUserEntreprise('');
  };

  const canAccessDotation = () => {
    return ['patron', 'co-patron', 'staff'].includes(userRole);
  };

  const canAccessImpot = () => {
    return ['patron', 'co-patron', 'staff'].includes(userRole);
  };

  const canAccessBlanchiment = () => {
    return ['patron', 'co-patron', 'staff'].includes(userRole);
  };

  const canAccessStaffConfig = () => {
    return userRole === 'staff';
  };

  const canAccessCompanyConfig = () => {
    return ['patron', 'co-patron'].includes(userRole);
  };

  const isReadOnlyForStaff = () => {
    return userRole === 'staff';
  };

  const value = {
    user,
    session,
    loading,
    userRole,
    userEntreprise,
    login,
    logout,
    canAccessDotation,
    canAccessImpot,
    canAccessBlanchiment,
    canAccessStaffConfig,
    canAccessCompanyConfig,
    isReadOnlyForStaff
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};