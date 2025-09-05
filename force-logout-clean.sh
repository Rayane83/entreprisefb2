#!/bin/bash

# 🚨 FORCER DÉCONNEXION COMPLÈTE - Suppression totale des sessions mock
# Usage: ./force-logout-clean.sh

set -e

DEST_PATH="/var/www/flashbackfa-entreprise.fr"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log "🚨 SUPPRESSION TOTALE DES SESSIONS MOCK ET FORÇAGE DÉCONNEXION..."

# 1. AuthContext ULTRA STRICT - Zéro fallback, zéro mock
log "🔧 AuthContext ULTRA STRICT - Suppression totale fallback..."

cat > "$DEST_PATH/frontend/src/contexts/AuthContext.js" << 'EOF'
import { createContext, useContext, useState, useEffect } from 'react';
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

  // FORCER LA DÉCONNEXION AU DÉMARRAGE
  useEffect(() => {
    let mounted = true;

    const forceLogoutAndCheckAuth = async () => {
      console.log('🚨 DÉMARRAGE: Vérification session...');
      
      try {
        // FORCER LA SUPPRESSION DE TOUTE SESSION EXISTANTE
        await authService.signOut();
        
        // Vider le localStorage/sessionStorage
        if (typeof window !== 'undefined') {
          localStorage.clear();
          sessionStorage.clear();
          console.log('🗑️ localStorage/sessionStorage vidés');
        }

        // Petite pause pour s'assurer que la déconnexion est effective
        await new Promise(resolve => setTimeout(resolve, 1000));

        // VÉRIFIER S'IL Y A VRAIMENT UNE SESSION SUPABASE
        const { session, error } = await authService.getSession();
        
        console.log('🔍 Session Supabase:', session?.user?.email || 'AUCUNE');
        
        if (error) {
          console.error('Erreur vérification session:', error);
        }

        if (session?.user && mounted) {
          console.log('✅ SESSION DISCORD VALIDE DÉTECTÉE');
          await handleUserLogin(session.user);
        } else if (mounted) {
          console.log('❌ AUCUNE SESSION - REDIRECTION LOGIN OBLIGATOIRE');
          
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
        throw error;
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
  const isReadOnlyForStaff = () => {
    return userRole === 'staff';
  };

  const canAccessStaffConfig = () => {
    return userRole === 'staff';
  };

  const canAccessCompanyConfig = () => {
    return ['patron', 'co-patron'].includes(userRole);
  };

  const canAccessDotationConfig = () => {
    return ['staff', 'patron', 'co-patron', 'dot'].includes(userRole);
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
    isReadOnlyForStaff,
    canAccessStaffConfig,
    canAccessCompanyConfig,
    canAccessDotationConfig
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
EOF

# 2. App.js avec vérification stricte d'authentification
log "🔧 App.js avec vérification ultra-stricte..."

cat > "$DEST_PATH/frontend/src/App.js" << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { Toaster } from 'sonner';
import LoginScreen from './components/LoginScreen';
import Index from './pages/Index';
import CompanyConfig from './pages/CompanyConfig';
import Superadmin from './pages/Superadmin';
import NotFound from './pages/NotFound';
import './App.css';

// Écran de chargement
const LoadingScreen = () => (
  <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
    <div className="text-center">
      <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
      <p className="mt-4 text-lg text-gray-600">Vérification de l'authentification...</p>
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

  // SI PAS AUTHENTIFIÉ: ÉCRAN DE CONNEXION OBLIGATOIRE
  if (!isAuthenticated || !user) {
    console.log('❌ Pas authentifié - Affichage LoginScreen');
    return <LoginScreen />;
  }

  console.log('✅ Authentifié - Affichage contenu protégé');
  return children;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="App">
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
              path="/company-config" 
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
            
            {/* Pages d'erreur */}
            <Route path="/404" element={<NotFound />} />
            <Route path="*" element={<Navigate to="/404" replace />} />
          </Routes>
          
          {/* Notifications toast */}
          <Toaster position="top-center" richColors />
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
EOF

# 3. Variables d'environnement avec mode DEBUG
log "⚙️ Variables d'environnement avec mode DEBUG..."

cat > "$DEST_PATH/frontend/.env" << EOF
# PRODUCTION ULTRA-STRICTE - DEBUG MODE
NODE_ENV=production
REACT_APP_PRODUCTION_MODE=true
REACT_APP_USE_MOCK_AUTH=false
REACT_APP_FORCE_DISCORD_AUTH=true
REACT_APP_DEBUG_AUTH=true

# Backend API
REACT_APP_BACKEND_URL=https://flashbackfa-entreprise.fr

# Supabase PRODUCTION
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwMzI2NDksImV4cCI6MjA3MjYwODY0OX0.nYFZjQoC6-U2zdgaaYqj3GYWByqWvoa1RconWuOOuiw

# Discord PRODUCTION
REACT_APP_DISCORD_GUILD_ID=1404608015230832742

# Forcer l'absence de cache
REACT_APP_BUILD_TIME=$(date +%s)
GENERATE_SOURCEMAP=false
EOF

# 4. Suppression TOTALE du build et rebuild
log "🗑️ Suppression TOTALE build et rebuild ULTRA-PROPRE..."

cd "$DEST_PATH/frontend"

# Supprimer tout
rm -rf build/
rm -rf node_modules/.cache/
rm -rf .cache/
rm -rf dist/

# Rebuild avec timestamp unique
export REACT_APP_BUILD_TIME=$(date +%s)
yarn build

# 5. Arrêter et redémarrer Nginx complètement 
log "🔄 Redémarrage complet Nginx..."

sudo systemctl stop nginx
sleep 3
sudo systemctl start nginx

# 6. Test du nouveau build
log "🧪 Test du nouveau build ULTRA-STRICT..."

sleep 5

# Test avec curl pour vérifier le contenu
RESPONSE=$(curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" "https://flashbackfa-entreprise.fr/" 2>/dev/null || echo "erreur")

if echo "$RESPONSE" | grep -q "Se connecter avec Discord"; then
    log "✅ Page de connexion Discord détectée"
    DISCORD_LOGIN_DETECTED=true
else
    log "❌ Page de connexion Discord PAS détectée"
    DISCORD_LOGIN_DETECTED=false
    
    # Debug
    echo "🔍 Contenu reçu (premiers 500 caractères):"
    echo "$RESPONSE" | head -c 500
fi

# 7. Informations finales avec debug
echo ""
echo "🎉================================================🎉"
echo -e "${GREEN}    DÉCONNEXION FORCÉE ET REBUILD ULTRA-STRICT${NC}"
echo "🎉================================================🎉"
echo ""

echo -e "${BLUE}🚨 ACTIONS DRASTIQUES EFFECTUÉES:${NC}"
echo -e "   ✅ AuthContext sans AUCUN fallback/mock"
echo -e "   ✅ Déconnexion forcée au démarrage"
echo -e "   ✅ localStorage/sessionStorage vidés"
echo -e "   ✅ Vérification stricte Discord OAuth"
echo -e "   ✅ Build complet avec timestamp unique"
echo -e "   ✅ Nginx redémarré complètement"

echo ""
echo -e "${BLUE}🔐 AUTHENTIFICATION:${NC}"
if [ "$DISCORD_LOGIN_DETECTED" = true ]; then
    echo -e "   ✅ Page de connexion Discord DÉTECTÉE"
else
    echo -e "   ❌ Page de connexion Discord PAS DÉTECTÉE"
fi

echo ""
echo -e "${BLUE}🎯 POUR VOIR LE CHANGEMENT:${NC}"
echo -e "${RED}   1. FERMEZ COMPLÈTEMENT VOTRE NAVIGATEUR${NC}"
echo -e "${RED}   2. ROUVREZ UN NOUVEL ONGLET PRIVÉ${NC}"
echo -e "${RED}   3. Allez sur: https://flashbackfa-entreprise.fr${NC}"
echo -e "${RED}   4. Ouvrez les outils développeur (F12)${NC}"
echo -e "${RED}   5. Regardez la console pour les logs de debug${NC}"

echo ""
echo -e "${YELLOW}💡 LOGS DE DEBUG:${NC}"
echo -e "   Ouvrez F12 -> Console pour voir:"
echo -e "   • '🚨 DÉMARRAGE: Vérification session...'"
echo -e "   • '❌ AUCUNE SESSION - REDIRECTION LOGIN OBLIGATOIRE'"
echo -e "   • '🛡️ ProtectedRoute - Auth: false'"

echo ""
if [ "$DISCORD_LOGIN_DETECTED" = true ]; then
    echo -e "${GREEN}🚀 PAGE DE CONNEXION DISCORD MAINTENANT ACTIVE !${NC}"
else
    echo -e "${RED}⚠️ SI VOUS VOYEZ ENCORE L'ANCIEN SITE:${NC}"
    echo -e "${RED}   Videz COMPLÈTEMENT le cache navigateur ou utilisez un autre navigateur${NC}"
fi

exit 0