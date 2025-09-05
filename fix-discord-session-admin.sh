#!/bin/bash

# 🔧 CORRECTION Session Discord + Redirection Admin automatique
# Usage: ./fix-discord-session-admin.sh

set -e

DEST_PATH="/var/www/flashbackfa-entreprise.fr"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log "🔧 CORRECTION Session Discord + Redirection Admin pour ID 462716512252329996"

# 1. AuthContext corrigé - NE PAS forcer la déconnexion si session Discord valide
log "🔧 AuthContext - Conserver session Discord valide..."

cat > "$DEST_PATH/frontend/src/contexts/AuthContext.js" << 'EOF'
import React, { createContext, useContext, useState, useEffect } from 'react';

let authService = null;
try {
  const authModule = require('../services/authService');
  authService = authModule.authService || authModule.default;
} catch (error) {
  console.error('❌ Erreur import authService:', error);
}

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
  const [error, setError] = useState(null);

  useEffect(() => {
    let mounted = true;

    const initializeAuth = async () => {
      console.log('🚨 INITIALISATION AUTHENTIFICATION...');
      
      try {
        if (!authService) {
          throw new Error('Service d\'authentification non disponible');
        }

        // NE PAS forcer la déconnexion - Vérifier directement s'il y a une session
        if (authService.getSession) {
          const { session, error } = await authService.getSession();
          
          if (error) {
            console.error('❌ Erreur vérification session:', error);
            setError(error.message);
          }

          if (session?.user && mounted) {
            console.log('✅ SESSION DISCORD EXISTANTE:', session.user.email);
            // NE PAS DÉCONNECTER - Traiter directement la session
            await handleUserLogin(session.user);
          } else if (mounted) {
            console.log('❌ AUCUNE SESSION - LOGIN DISCORD REQUIS');
            resetAuthState();
          }
        } else {
          console.error('❌ Fonction getSession non disponible');
          if (mounted) {
            resetAuthState();
          }
        }
      } catch (error) {
        console.error('❌ Erreur initialisation auth:', error);
        setError(error.message);
        if (mounted) {
          resetAuthState();
        }
      }
    };

    // Écouter les changements d'authentification
    let subscription = null;
    if (authService && authService.onAuthStateChange) {
      try {
        const { data } = authService.onAuthStateChange(async (event, session) => {
          console.log('🔄 Auth state change:', event, session ? 'Session présente' : 'Pas de session');
          
          if (!mounted) return;

          if (event === 'SIGNED_IN' && session?.user) {
            console.log('✅ CONNEXION DISCORD DÉTECTÉE - TRAITEMENT...');
            await handleUserLogin(session.user);
          } else if (event === 'SIGNED_OUT') {
            console.log('🚪 DÉCONNEXION DÉTECTÉE');
            resetAuthState();
          }
        });
        subscription = data?.subscription;
      } catch (error) {
        console.error('❌ Erreur setup auth listener:', error);
      }
    }

    initializeAuth();

    return () => {
      mounted = false;
      if (subscription && subscription.unsubscribe) {
        subscription.unsubscribe();
      }
    };
  }, []);

  const resetAuthState = () => {
    setUser(null);
    setSession(null);
    setIsAuthenticated(false);
    setUserRole(null);
    setUserEntreprise(null);
    setLoading(false);
  };

  const handleUserLogin = async (supabaseUser) => {
    setLoading(true);
    setError(null);
    
    try {
      console.log('🔐 Traitement connexion utilisateur:', supabaseUser.email);
      console.log('👤 Provider:', supabaseUser.app_metadata?.provider);
      console.log('🆔 Discord ID:', supabaseUser.user_metadata?.provider_id);
      
      // Vérification Discord
      if (supabaseUser.app_metadata?.provider !== 'discord') {
        console.error('❌ Connexion non-Discord détectée');
        throw new Error('Seule la connexion Discord est autorisée');
      }

      // Récupérer l'ID Discord de l'utilisateur
      const discordId = supabaseUser.user_metadata?.provider_id || 
                       supabaseUser.user_metadata?.sub ||
                       supabaseUser.user_metadata?.id;

      console.log('🆔 ID Discord détecté:', discordId);

      // VÉRIFICATION ID ADMIN SPÉCIFIQUE
      let userRole = 'employe';
      let isAdmin = false;
      
      if (discordId === '462716512252329996') {
        console.log('🔥 ADMIN DÉTECTÉ - ID DISCORD CORRESPONDANT');
        userRole = 'admin';
        isAdmin = true;
      } else {
        // Récupérer les rôles normaux
        if (authService && authService.getUserGuildRoles) {
          try {
            const rolesResult = await authService.getUserGuildRoles();
            userRole = rolesResult.userRole || 'employe';
          } catch (error) {
            console.warn('⚠️ Erreur récupération rôles, utilisation valeur par défaut:', error);
          }
        }
      }

      // Créer l'objet utilisateur
      const userData = {
        id: supabaseUser.id,
        email: supabaseUser.email,
        discord_username: supabaseUser.user_metadata?.full_name || 
                         supabaseUser.user_metadata?.name || 
                         supabaseUser.user_metadata?.preferred_username || 
                         'Utilisateur Discord',
        discord_id: discordId,
        avatar_url: supabaseUser.user_metadata?.avatar_url,
        entreprise: 'Flashback Fa',
        isAdmin: isAdmin
      };

      console.log('✅ Utilisateur configuré:', userData.discord_username, 'Rôle:', userRole, 'Admin:', isAdmin);

      setUser(userData);
      setSession(supabaseUser);
      setUserRole(userRole);
      setUserEntreprise('Flashback Fa');
      setIsAuthenticated(true);

      // REDIRECTION AUTOMATIQUE POUR L'ADMIN
      if (isAdmin) {
        console.log('🔥 REDIRECTION ADMIN AUTOMATIQUE VERS /superadmin');
        setTimeout(() => {
          if (window.location.pathname !== '/superadmin') {
            window.location.href = '/superadmin';
          }
        }, 2000); // Délai de 2 secondes pour laisser le temps à l'interface de se charger
      }
      
    } catch (error) {
      console.error('❌ Erreur traitement connexion:', error);
      setError(error.message);
      
      // NE PAS DÉCONNECTER automatiquement - laisser l'utilisateur réessayer
      resetAuthState();
    } finally {
      setLoading(false);
    }
  };

  const loginWithDiscord = async () => {
    try {
      setLoading(true);
      setError(null);
      console.log('🚀 Tentative connexion Discord...');
      
      if (!authService || !authService.signInWithDiscord) {
        throw new Error('Service d\'authentification Discord non disponible. Vérifiez la configuration Supabase.');
      }
      
      const { error } = await authService.signInWithDiscord();
      if (error) {
        console.error('❌ Erreur connexion Discord:', error);
        setError(error.message);
        setLoading(false);
        return { error };
      }
      
      console.log('🔄 Redirection Discord en cours...');
      return { error: null };
    } catch (error) {
      console.error('❌ Erreur loginWithDiscord:', error);
      setError(error.message);
      setLoading(false);
      return { error };
    }
  };

  const logout = async () => {
    try {
      console.log('🚪 Déconnexion...');
      setError(null);
      
      if (authService && authService.signOut) {
        await authService.signOut();
      }
      
      // Vider le stockage local
      if (typeof window !== 'undefined') {
        try {
          localStorage.clear();
          sessionStorage.clear();
        } catch (e) {
          console.warn('⚠️ Erreur vidage storage:', e);
        }
      }
      
      resetAuthState();
      
      // Rediriger vers la page d'accueil après déconnexion
      window.location.href = '/';
    } catch (error) {
      console.error('❌ Erreur déconnexion:', error);
      setError(error.message);
    }
  };

  // Fonctions de vérification des rôles
  const canAccessDotation = () => {
    return ['patron', 'co-patron', 'staff', 'dot', 'admin'].includes(userRole);
  };

  const canAccessImpot = () => {
    return ['patron', 'co-patron', 'staff', 'admin'].includes(userRole);
  };

  const canAccessBlanchiment = () => {
    return ['patron', 'co-patron', 'staff', 'admin'].includes(userRole);
  };

  const canAccessStaffConfig = () => {
    return ['staff', 'admin'].includes(userRole);
  };

  const canAccessCompanyConfig = () => {
    return ['patron', 'co-patron', 'admin'].includes(userRole);
  };

  const canAccessSuperadmin = () => {
    return ['admin'].includes(userRole);
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
    error,
    loginWithDiscord,
    logout,
    canAccessDotation,
    canAccessImpot,
    canAccessBlanchiment,
    canAccessStaffConfig,
    canAccessCompanyConfig,
    canAccessSuperadmin,
    isReadOnlyForStaff
  };

  return React.createElement(AuthContext.Provider, { value }, children);
};

export default AuthProvider;
EOF

# 2. App.js avec redirection admin automatique
log "🔧 App.js avec redirection admin..."

cat > "$DEST_PATH/frontend/src/App.js" << 'EOF'
import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { Toaster } from 'sonner';
import LoginScreen from './components/LoginScreen';
import Index from './pages/Index';
import CompanyConfig from './pages/CompanyConfig';
import Superadmin from './pages/Superadmin';
import NotFound from './pages/NotFound';
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

// Composant de redirection admin
const AdminRedirect = () => {
  const { user, userRole } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    if (user && userRole === 'admin' && location.pathname === '/') {
      console.log('🔥 ADMIN DÉTECTÉ - REDIRECTION AUTOMATIQUE VERS /superadmin');
      setTimeout(() => {
        navigate('/superadmin');
      }, 1500);
    }
  }, [user, userRole, navigate, location.pathname]);

  return null;
};

// Protection des routes
const ProtectedRoute = ({ children, adminOnly = false }) => {
  const { isAuthenticated, loading, user, userRole } = useAuth();

  console.log('🛡️ ProtectedRoute - Auth:', isAuthenticated, 'Loading:', loading, 'User:', user?.discord_username || 'AUCUN', 'Role:', userRole);

  if (loading) {
    return <LoadingScreen />;
  }

  // SI PAS AUTHENTIFIÉ: ÉCRAN DE CONNEXION DISCORD
  if (!isAuthenticated || !user) {
    console.log('❌ Pas authentifié - Affichage LoginScreen');
    return <LoginScreen />;
  }

  // SI ROUTE ADMIN ET PAS ADMIN: REDIRECTION
  if (adminOnly && userRole !== 'admin') {
    console.log('❌ Accès admin requis - Redirection vers accueil');
    return <Navigate to="/" replace />;
  }

  console.log('✅ Authentifié - Affichage contenu protégé');
  return (
    <>
      <AdminRedirect />
      {children}
    </>
  );
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
                    <Index />
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
              
              {/* Administration - ACCÈS ADMIN SEULEMENT */}
              <Route 
                path="/superadmin" 
                element={
                  <ProtectedRoute adminOnly={true}>
                    <Superadmin />
                  </ProtectedRoute>
                } 
              />
              
              <Route 
                path="/superstaff" 
                element={
                  <ProtectedRoute adminOnly={true}>
                    <Superadmin />
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
EOF

# 3. Service d'authentification - NE PAS forcer la déconnexion des sessions Discord valides
log "🔧 Service d'authentification - Préserver sessions Discord..."

cat > "$DEST_PATH/frontend/src/services/authService.js" << 'EOF'
import { supabase } from '../lib/supabase';

export const authService = {
  // Connexion Discord OAuth
  async signInWithDiscord() {
    try {
      console.log('🚀 Lancement OAuth Discord...');
      
      if (!supabase) {
        throw new Error('Client Supabase non initialisé');
      }

      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'discord',
        options: {
          redirectTo: `${window.location.origin}`,
          scopes: 'identify guilds'
        }
      });

      if (error) {
        console.error('❌ Erreur OAuth Discord:', error);
        throw error;
      }

      console.log('✅ Redirection Discord initiée');
      return { data, error: null };
    } catch (error) {
      console.error('❌ Erreur signInWithDiscord:', error);
      return { data: null, error };
    }
  },

  // Déconnexion
  async signOut() {
    try {
      if (!supabase) {
        console.warn('⚠️ Client Supabase non disponible pour signOut');
        return { error: null };
      }

      console.log('🚪 Déconnexion Supabase...');
      const { error } = await supabase.auth.signOut();
      if (error) {
        console.error('Erreur déconnexion:', error);
      } else {
        console.log('✅ Déconnexion Supabase réussie');
      }
      return { error };
    } catch (error) {
      console.error('❌ Erreur signOut:', error);
      return { error };
    }
  },

  // Récupérer session actuelle SANS la supprimer
  async getSession() {
    try {
      if (!supabase) {
        console.warn('⚠️ Client Supabase non disponible pour getSession');
        return { session: null, error: new Error('Client Supabase non disponible') };
      }

      const { data: { session }, error } = await supabase.auth.getSession();
      if (error) {
        console.error('❌ Erreur getSession:', error);
        throw error;
      }
      
      if (session) {
        console.log('🔍 Session Discord trouvée:', session.user?.email, 'ID:', session.user?.user_metadata?.provider_id);
      } else {
        console.log('🔍 Aucune session trouvée');
      }
      
      return { session, error: null };
    } catch (error) {
      console.error('❌ Erreur récupération session:', error);
      return { session: null, error };
    }
  },

  // Écouter changements d'auth
  onAuthStateChange(callback) {
    try {
      if (!supabase) {
        console.warn('⚠️ Client Supabase non disponible pour onAuthStateChange');
        return { data: { subscription: { unsubscribe: () => {} } } };
      }

      return supabase.auth.onAuthStateChange((event, session) => {
        console.log('🔄 Auth state change:', event, session?.user?.email || 'Pas de session');
        if (callback) {
          try {
            callback(event, session);
          } catch (error) {
            console.error('❌ Erreur callback auth state change:', error);
          }
        }
      });
    } catch (error) {
      console.error('❌ Erreur onAuthStateChange:', error);
      return { data: { subscription: { unsubscribe: () => {} } } };
    }
  },

  // Récupérer les rôles Discord
  async getUserGuildRoles(guildId = '1404608015230832742') {
    try {
      console.log('🔍 Récupération rôles Discord...');
      
      const { session, error } = await this.getSession();
      if (error || !session?.user) {
        console.log('❌ Pas de session pour récupérer les rôles');
        return { roles: [], userRole: 'employe', entreprise: 'Flashback Fa', error: 'Pas de session' };
      }

      const user = session.user;
      const discordId = user.user_metadata?.provider_id || user.user_metadata?.sub;

      // VÉRIFICATION ID ADMIN SPÉCIFIQUE
      if (discordId === '462716512252329996') {
        console.log('🔥 ID ADMIN DÉTECTÉ:', discordId);
        return {
          roles: [{ name: 'Admin', color: '#dc2626' }],
          userRole: 'admin',
          entreprise: 'Flashback Fa',
          error: null
        };
      }

      console.log('👤 Utilisateur normal Discord ID:', discordId);

      // Pour les autres utilisateurs, utiliser les rôles par défaut
      return this.getFallbackRoles(user);

    } catch (error) {
      console.error('❌ Erreur récupération rôles:', error);
      return { roles: [], userRole: 'employe', entreprise: 'Flashback Fa', error: error.message };
    }
  },

  // Rôles de secours basés sur l'email
  getFallbackRoles(user) {
    const mockRoles = {
      'staff': { name: 'Staff', color: '#3b82f6' },
      'patron': { name: 'Patron', color: '#16a34a' },
      'co-patron': { name: 'Co-Patron', color: '#eab308' },
      'dot': { name: 'DOT', color: '#a855f7' },
      'employe': { name: 'Employé', color: '#64748b' }
    };

    // Déterminer le rôle basé sur l'email
    let userRole = 'employe';
    const email = user.email?.toLowerCase() || '';
    
    if (email.includes('admin') || email.includes('staff')) userRole = 'staff';
    else if (email.includes('patron') && email.includes('co')) userRole = 'co-patron';
    else if (email.includes('patron')) userRole = 'patron';
    else if (email.includes('dot')) userRole = 'dot';

    console.log('🎭 Rôle attribué basé sur email:', userRole, 'pour', email);

    return { 
      roles: [mockRoles[userRole]], 
      userRole,
      entreprise: 'Flashback Fa',
      error: null 
    };
  }
};

export default authService;
EOF

# 4. Build avec les corrections
log "🏗️ Build avec corrections session..."

cd "$DEST_PATH/frontend"
rm -rf build/
yarn build

# 5. Redémarrage services
log "🔄 Redémarrage services..."

sudo systemctl restart nginx
sleep 5

# Test final
NEW_JS=$(ls build/static/js/main.*.js 2>/dev/null | xargs -n 1 basename | head -1)
log "✅ Nouveau build: $NEW_JS"

echo ""
echo "🎉=======================================🎉"
echo -e "${GREEN}  CORRECTIONS APPLIQUÉES - ID ADMIN${NC}"
echo "🎉=======================================🎉"
echo ""

echo -e "${BLUE}✅ CORRECTIONS:${NC}"
echo -e "   ✅ Session Discord préservée (pas de déconnexion forcée)"
echo -e "   ✅ ID Discord 462716512252329996 = ADMIN automatique"
echo -e "   ✅ Redirection automatique vers /superadmin pour votre ID"
echo -e "   ✅ Protection routes avec accès admin"

echo ""
echo -e "${BLUE}🎯 COMPORTEMENT ATTENDU:${NC}"
echo -e "   1. Vous vous connectez via Discord"
echo -e "   2. Votre ID 462716512252329996 est détecté"
echo -e "   3. Rôle 'admin' attribué automatiquement"
echo -e "   4. Redirection automatique vers /superadmin après 2 secondes"
echo -e "   5. Accès total à la configuration des guilds"

echo ""
echo -e "${GREEN}🚀 TESTEZ MAINTENANT:${NC}"
echo -e "${GREEN}   Onglet privé -> https://flashbackfa-entreprise.fr${NC}"
echo -e "${GREEN}   Connectez-vous Discord -> Redirection admin automatique !${NC}"

exit 0