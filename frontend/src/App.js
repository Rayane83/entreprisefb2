import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { Toaster } from 'sonner';
import LoginScreen from './components/LoginScreen';
import Dashboard from './pages/Dashboard';
import CompanyConfig from './pages/CompanyConfig';
import Superadmin from './pages/Superadmin';
import EnterpriseManagement from './pages/EnterpriseManagement';
import NotFound from './pages/NotFound';
import AuthCallback from './pages/AuthCallback';
import './App.css';
import './index.css';

const queryClient = new QueryClient();

// Écran de chargement
const LoadingScreen = () => (
  <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
    <div className="text-center">
      <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
      <p className="mt-4 text-lg text-gray-600">Vérification de l'authentification Discord...</p>
    </div>
  </div>
);

// Protection des routes - STRICTE
const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, loading, user } = useAuth();

  console.log('🛡️ ProtectedRoute - Auth:', isAuthenticated, 'Loading:', loading, 'User:', user?.discord_username || 'AUCUN');

  if (loading) {
    return <LoadingScreen />;
  }

  // SI PAS AUTHENTIFIÉ: ÉCRAN DE CONNEXION DISCORD OBLIGATOIRE
  if (!isAuthenticated || !user) {
    console.log('❌ Pas authentifié - Affichage LoginScreen');
    return <LoginScreen />;
  }

  console.log('✅ Authentifié - Affichage contenu protégé');
  return children;
};

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <div className="App">
          <Router>
            <Routes>
              {/* Route principale protégée */}
              <Route 
                path="/" 
                element={
                  <ProtectedRoute>
                    <Dashboard />
                  </ProtectedRoute>
                } 
              />
              
              {/* Configuration entreprise */}
              <Route 
                path="/patron-config" 
                element={
                  <ProtectedRoute>
                    <CompanyConfig />
                  </ProtectedRoute>
                } 
              />
              
              {/* Administration */}
              <Route 
                path="/superadmin" 
                element={
                  <ProtectedRoute>
                    <Superadmin />
                  </ProtectedRoute>
                } 
              />
              
              <Route 
                path="/superstaff" 
                element={
                  <ProtectedRoute>
                    <Superadmin />
                  </ProtectedRoute>
                } 
              />
              
              {/* Gestion des entreprises */}
              <Route 
                path="/enterprise-management" 
                element={
                  <ProtectedRoute>
                    <EnterpriseManagement />
                  </ProtectedRoute>
                } 
              />
              
              {/* Pages d'erreur */}
              <Route path="/404" element={<NotFound />} />
              <Route path="*" element={<Navigate to="/404" replace />} />
            </Routes>
            
            {/* Notifications toast */}
            <Toaster position="top-center" richColors />
          </Router>
        </div>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;