import React, { createContext, useContext, useState, useEffect } from 'react';
import newAuthService from '../services/newAuthService';

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
  const [userRole, setUserRole] = useState(null);
  const [userEntreprise, setUserEntreprise] = useState(null);

  useEffect(() => {
    let mounted = true;

    const initializeAuth = async () => {
      console.log('🚨 DÉMARRAGE: Vérification session avec nouveau backend...');
      
      // VÉRIFIER SI ON EST EN MODE MOCK (conservé pour compatibilité de développement)
      const useMockAuth = process.env.REACT_APP_USE_MOCK_AUTH === 'true';
      const forceDiscord = process.env.REACT_APP_FORCE_DISCORD_AUTH === 'true';
      
      if (useMockAuth && !forceDiscord) {
        console.log('🎭 MODE MOCK ACTIVÉ - Connexion automatique');
        
        const mockUser = {
          id: 'mock-user-id',
          email: 'mockuser@flashbackfa.discord',
          discord_username: 'Utilisateur Test',
          discord_id: '123456789012345678',
          avatar_url: 'https://cdn.discordapp.com/embed/avatars/0.png',
          role: 'patron',
          enterprise_id: 'mock-enterprise'
        };
        
        setUser(mockUser);
        setSession({ user: mockUser });
        setUserRole('patron');
        setUserEntreprise('LSPD');
        setIsAuthenticated(true);
        setLoading(false);
        
        console.log('✅ Utilisateur mock connecté:', mockUser.discord_username);
        return;
      }
      
      try {
        // Vérifier s'il y a une session valide avec le nouveau backend
        const { session, error } = await newAuthService.getSession();
        
        if (error) {
          console.error('Erreur vérification session:', error);
        }

        if (session?.user && mounted) {
          console.log('✅ SESSION VALIDE DÉTECTÉE - Backend FastAPI');
          await handleUserLogin(session.user);
        } else if (mounted) {
          console.log('❌ AUCUNE SESSION - Authentification requise');
          
          setUser(null);
          setSession(null);
          setIsAuthenticated(false);
          setUserRole(null);
          setUserEntreprise(null);
          setLoading(false);
        }
      } catch (error) {
        console.error('Erreur vérification authentification:', error);
        if (mounted) {
          setUser(null);
          setSession(null);
          setIsAuthenticated(false);
          setUserRole(null); 
          setUserEntreprise(null);
          setLoading(false);
        }
      }
    };

    // Écouter les changements d'authentification du nouveau service
    const { data: { subscription } } = newAuthService.onAuthStateChange(async (event, session) => {
      console.log('🔄 Auth state change (FastAPI):', event, session?.user?.discord_username || 'AUCUNE SESSION');
      
      if (!mounted) return;

      if (event === 'SIGNED_IN' && session?.user) {
        console.log('✅ CONNEXION DÉTECTÉE - Backend FastAPI');
        await handleUserLogin(session.user);
      } else if (event === 'SIGNED_OUT') {
        console.log('🚪 DÉCONNEXION DÉTECTÉE');
        setUser(null);
        setSession(null);
        setIsAuthenticated(false);
        setUserRole(null);
        setUserEntreprise(null);
        setLoading(false);
      }
    });

    initializeAuth();

    return () => {
      mounted = false;
      subscription?.unsubscribe();
    };
  }, []);

  // Traitement utilisateur avec le nouveau backend
  const handleUserLogin = async (userData) => {
    setLoading(true);
    
    try {
      console.log('🔐 Traitement connexion utilisateur:', userData.discord_username);

      // Récupérer les rôles depuis le backend
      const { userRole, entreprise, error } = await newAuthService.getUserGuildRoles();
      
      if (error) {
        console.error('Erreur récupération rôles:', error);
        // Continuer avec les données utilisateur de base
      }

      console.log('✅ Utilisateur configuré:', userData.discord_username);
      console.log('✅ Rôle:', userData.role);

      setUser(userData);
      setSession({ user: userData });
      setUserRole(userData.role || userRole || 'employe');
      setUserEntreprise(entreprise || userData.enterprise_id || 'Flashback Fa');
      setIsAuthenticated(true);
      
    } catch (error) {
      console.error('❌ Erreur traitement connexion:', error);
      
      // EN CAS D'ERREUR: DÉCONNEXION
      await newAuthService.signOut();
      setUser(null);
      setSession(null);
      setIsAuthenticated(false);
      setUserRole(null);
      setUserEntreprise(null);
    } finally {
      setLoading(false);
    }
  };

  // Connexion Discord avec nouveau backend
  const loginWithDiscord = async () => {
    try {
      setLoading(true);
      console.log('🚀 Lancement authentification Discord...');
      
      const { error } = await newAuthService.signInWithDiscord();
      if (error) {
        console.error('Erreur connexion Discord:', error);
        setLoading(false);
        return { error };
      }
      
      console.log('🔄 Redirection Discord en cours...');
      return { error: null };
    } catch (error) {
      console.error('Erreur connexion Discord:', error);
      setLoading(false);
      return { error };
    }
  };

  // Déconnexion complète
  const logout = async () => {
    try {
      console.log('🚪 Déconnexion...');
      await newAuthService.signOut();
      
      setUser(null);
      setSession(null);
      setIsAuthenticated(false);
      setUserRole(null);
      setUserEntreprise(null);
    } catch (error) {
      console.error('Erreur déconnexion:', error);
    }
  };

  // Fonctions de vérification des rôles
  const canAccessDotation = () => {
    return ['patron', 'co-patron', 'staff', 'dot'].includes(userRole);
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
    loginWithDiscord,
    logout,
    canAccessDotation,
    canAccessImpot,
    canAccessBlanchiment,
    canAccessStaffConfig,
    canAccessCompanyConfig,
    isReadOnlyForStaff
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};