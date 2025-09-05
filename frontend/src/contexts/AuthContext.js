import React, { createContext, useContext, useState, useEffect } from 'react';
import { authService } from '../services/authService';

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

    const forceLogoutAndCheckAuth = async () => {
      console.log('🚨 DÉMARRAGE: Vérification session...');
      
      // VÉRIFIER SI ON EST EN MODE MOCK
      const useMockAuth = process.env.REACT_APP_USE_MOCK_AUTH === 'true';
      const forceDiscord = process.env.REACT_APP_FORCE_DISCORD_AUTH === 'true';
      
      if (useMockAuth && !forceDiscord) {
        console.log('🎭 MODE MOCK ACTIVÉ - Connexion automatique');
        
        // Créer un utilisateur mock
        const mockUser = {
          id: 'mock-user-id',
          email: 'mockuser@flashbackfa.discord',
          discord_username: 'Utilisateur Test',
          discord_id: '123456789012345678',
          avatar_url: 'https://cdn.discordapp.com/embed/avatars/0.png',
          entreprise: 'LSPD'
        };
        
        setUser(mockUser);
        setSession({ user: mockUser });
        setUserRole('staff'); // Rôle staff pour accéder à toutes les fonctionnalités
        setUserEntreprise('LSPD');
        setIsAuthenticated(true);
        setLoading(false);
        
        console.log('✅ Utilisateur mock connecté:', mockUser.discord_username);
        return;
      }
      
      try {
        // FORCER LA SUPPRESSION DE TOUTE SESSION EXISTANTE NON-DISCORD
        await authService.signOut();
        
        // Vider le localStorage/sessionStorage
        if (typeof window !== 'undefined') {
          localStorage.clear();
          sessionStorage.clear();
          console.log('🗑️ localStorage/sessionStorage vidés');
        }

        // Petite pause pour s'assurer que la déconnexion est effective
        await new Promise(resolve => setTimeout(resolve, 1000));

        // VÉRIFIER S'IL Y A VRAIMENT UNE SESSION SUPABASE DISCORD
        const { session, error } = await authService.getSession();
        
        console.log('🔍 Session Supabase:', session?.user?.email || 'AUCUNE');
        
        if (error) {
          console.error('Erreur vérification session:', error);
        }

        if (session?.user && mounted) {
          console.log('✅ SESSION DISCORD VALIDE DÉTECTÉE');
          await handleUserLogin(session.user);
        } else if (mounted) {
          console.log('❌ AUCUNE SESSION - REDIRECTION LOGIN DISCORD OBLIGATOIRE');
          
          // FORCER L'ÉTAT DE DÉCONNEXION
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
          // EN CAS D'ERREUR: DÉCONNEXION FORCÉE
          setUser(null);
          setSession(null);
          setIsAuthenticated(false);
          setUserRole(null); 
          setUserEntreprise(null);
          setLoading(false);
        }
      }
    };

    // Écouter les changements d'authentification Supabase
    const { data: { subscription } } = authService.onAuthStateChange(async (event, session) => {
      console.log('🔄 Auth state change:', event, session?.user?.email || 'AUCUNE SESSION');
      
      if (!mounted) return;

      if (event === 'SIGNED_IN' && session?.user) {
        console.log('✅ CONNEXION DISCORD DÉTECTÉE');
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

    forceLogoutAndCheckAuth();

    return () => {
      mounted = false;
      subscription?.unsubscribe();
    };
  }, []);

  // Traitement utilisateur Discord RÉEL uniquement
  const handleUserLogin = async (supabaseUser) => {
    setLoading(true);
    
    try {
      console.log('🔐 Traitement connexion Discord:', supabaseUser.email);
      
      // VÉRIFICATION STRICTE: Doit être Discord
      if (supabaseUser.app_metadata?.provider !== 'discord') {
        console.error('❌ Connexion non-Discord détectée, déconnexion forcée');
        await authService.signOut();
        throw new Error('Seule la connexion Discord est autorisée');
      }

      // Récupérer les rôles Discord RÉELS
      const { userRole, entreprise, error } = await authService.getUserGuildRoles();
      
      if (error) {
        console.error('Erreur récupération rôles Discord:', error);
        // Ne pas faire throw, utiliser rôle par défaut
      }

      // Données utilisateur RÉELLES Discord
      const userData = {
        id: supabaseUser.id,
        email: supabaseUser.email,
        discord_username: supabaseUser.user_metadata?.full_name || 
                         supabaseUser.user_metadata?.name || 
                         supabaseUser.user_metadata?.preferred_username || 
                         'Utilisateur Discord',
        discord_id: supabaseUser.user_metadata?.provider_id || 
                   supabaseUser.user_metadata?.sub,
        avatar_url: supabaseUser.user_metadata?.avatar_url,
        entreprise: entreprise || 'Flashback Fa'
      };

      console.log('✅ Utilisateur Discord configuré:', userData.discord_username);
      console.log('✅ Rôle Discord:', userRole);

      setUser(userData);
      setSession(supabaseUser);
      setUserRole(userRole || 'employe');
      setUserEntreprise(entreprise || 'Flashback Fa');
      setIsAuthenticated(true);
      
    } catch (error) {
      console.error('❌ Erreur connexion Discord:', error);
      
      // EN CAS D'ERREUR: DÉCONNEXION TOTALE
      await authService.signOut();
      setUser(null);
      setSession(null);
      setIsAuthenticated(false);
      setUserRole(null);
      setUserEntreprise(null);
    } finally {
      setLoading(false);
    }
  };

  // Connexion Discord OBLIGATOIRE
  const loginWithDiscord = async () => {
    try {
      setLoading(true);
      console.log('🚀 Lancement authentification Discord...');
      
      const { error } = await authService.signInWithDiscord();
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
      await authService.signOut();
      
      // Vider le stockage local
      if (typeof window !== 'undefined') {
        localStorage.clear();
        sessionStorage.clear();
      }
      
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