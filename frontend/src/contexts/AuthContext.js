import React, { createContext, useContext, useState, useEffect } from 'react';
import { mockUser, mockUserRoles } from '../data/mockData';
import authService from '../services/authService';

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
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [userRole, setUserRole] = useState('employe');
  const [userEntreprise, setUserEntreprise] = useState('');

  useEffect(() => {
    let mounted = true;

    // Vérifier la session actuelle
    const getInitialSession = async () => {
      try {
        const { session, error } = await authService.getSession();
        
        if (error) {
          console.error('Erreur récupération session:', error);
          setLoading(false);
          return;
        }

        if (session?.user && mounted) {
          await handleUserLogin(session.user);
        } else if (mounted) {
          // Pas de session, utiliser utilisateur mock pour le développement
          const mockUser = {
            id: '12345',
            email: 'patron@lspd.com',
            discord_username: 'Jean Dupont',
            entreprise: 'LSPD'
          };
          setUser(mockUser);
          setIsAuthenticated(true);
          setLoading(false);
        }
      } catch (error) {
        console.error('Erreur initialisation session:', error);
        if (mounted) {
          setLoading(false);
        }
      }
    };

    // Écouter les changements d'authentification
    const { data: { subscription } } = authService.onAuthStateChange(async (event, session) => {
      console.log('Auth state change:', event, session?.user?.email);
      
      if (!mounted) return;

      if (event === 'SIGNED_IN' && session?.user) {
        await handleUserLogin(session.user);
      } else if (event === 'SIGNED_OUT') {
        setUser(null);
        setIsAuthenticated(false);
        setUserRole(null);
        setUserEntreprise(null);
        setLoading(false);
      }
    });

    getInitialSession();

    // Cleanup
    return () => {
      mounted = false;
      subscription?.unsubscribe();
    };
  }, []);

  // Gérer la connexion utilisateur
  const handleUserLogin = async (supabaseUser) => {
    setLoading(true);
    
    try {
      // Récupérer les rôles Discord
      const { userRole, entreprise, error } = await authService.getUserGuildRoles();
      
      if (error) {
        console.error('Erreur récupération rôles:', error);
      }

      // Créer l'objet utilisateur complet
      const userData = {
        id: supabaseUser.id,
        email: supabaseUser.email,
        discord_username: supabaseUser.user_metadata?.full_name || supabaseUser.user_metadata?.name || 'Utilisateur',
        discord_id: supabaseUser.user_metadata?.provider_id || supabaseUser.user_metadata?.sub,
        avatar_url: supabaseUser.user_metadata?.avatar_url,
        entreprise: entreprise || 'LSPD'
      };

      setUser(userData);
      setUserRole(userRole || 'employe');
      setUserEntreprise(entreprise || 'LSPD');
      setIsAuthenticated(true);
      
    } catch (error) {
      console.error('Erreur traitement connexion:', error);
      // En cas d'erreur, définir des valeurs par défaut
      setUser({
        id: supabaseUser.id,
        email: supabaseUser.email,
        discord_username: 'Utilisateur',
        entreprise: 'LSPD'
      });
      setUserRole('employe');
      setUserEntreprise('LSPD');
      setIsAuthenticated(true);
    } finally {
      setLoading(false);
    }
  };

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
    isAuthenticated,
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