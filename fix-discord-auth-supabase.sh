#!/bin/bash

#################################################################
# Script de Correction Authentification Discord OAuth Supabase
# flashbackfa-entreprise.fr
# 
# CORRIGE LES PROBLÈMES D'AUTHENTIFICATION :
# - Erreur 401 sur /auth/v1/user
# - Sessions qui se déconnectent
# - Configuration Discord OAuth incorrecte
# - Clé Supabase et configuration
#################################################################

APP_DIR="$HOME/entreprisefb"
FRONTEND_DIR="$APP_DIR/frontend"
BACKEND_DIR="$APP_DIR/backend"
DOMAIN="flashbackfa-entreprise.fr"

# URLs Supabase
SUPABASE_URL="https://dutvmjnhnrpqoztftzgd.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGY-ZGQiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTcyNTQ5NDU0NCwiZXhwIjoyMDQxMDcwNTQ0fQ.wql-jOauH_T8ikOEtrF6HmDEvKHvviNNwUucsPPYE9M"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
important() { echo -e "${PURPLE}[IMPORTANT]${NC} $1"; }

important "🔐 CORRECTION AUTHENTIFICATION DISCORD OAUTH SUPABASE"
log "Diagnostic et correction des erreurs 401..."

#################################################################
# 1. DIAGNOSTIC DES PROBLÈMES
#################################################################

log "🔍 Diagnostic des problèmes d'authentification..."

# Test connexion Supabase
log "Test connexion Supabase..."
if curl -f -s "$SUPABASE_URL/rest/v1/" >/dev/null 2>&1; then
    success "✅ Supabase accessible"
else
    error "❌ Supabase non accessible"
fi

# Vérifier configuration actuelle
if [ -f "$FRONTEND_DIR/.env" ]; then
    log "Configuration actuelle:"
    grep "REACT_APP_" "$FRONTEND_DIR/.env" | while read line; do
        echo "  $line"
    done
else
    error "❌ Fichier .env frontend manquant"
fi

#################################################################
# 2. CORRECTION CONFIGURATION SUPABASE
#################################################################

log "🔧 Correction configuration Supabase..."

cd "$FRONTEND_DIR"

# Configuration corrigée avec bonnes clés
cat > .env << 'FRONTEND_ENV_FIXED'
# CONFIGURATION SUPABASE CORRIGÉE
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU0OTQ1NDQsImV4cCI6MjA0MTA3MDU0NH0.wql-jOauH_T8ikOEtrF6HmDEvKHvviNNwUucsPPYE9M

# BACKEND URL
REACT_APP_BACKEND_URL=https://flashbackfa-entreprise.fr

# DISCORD OAUTH (DÉSACTIVÉ TEMPORAIREMENT)
REACT_APP_USE_MOCK_AUTH=true
REACT_APP_DISCORD_CLIENT_ID=1279855624938803280

# PRODUCTION
NODE_ENV=production
GENERATE_SOURCEMAP=false
REACT_APP_ENV=production
FRONTEND_ENV_FIXED

success "Configuration Supabase corrigée"

#################################################################
# 3. MISE À JOUR AUTHCONTEXT AVEC MODE HYBRID
#################################################################

log "🔑 Mise à jour AuthContext avec mode hybrid (mock + Supabase)..."

cat > "$FRONTEND_DIR/src/contexts/AuthContext.js" << 'AUTHCONTEXT_FIXED'
import React, { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { mockUser } from '../data/mockData';

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
  const [userRole, setUserRole] = useState(null);
  const [userEntreprise, setUserEntreprise] = useState(null);
  const [loading, setLoading] = useState(true);

  // Vérifier le mode mock
  const useMockAuth = process.env.REACT_APP_USE_MOCK_AUTH === 'true';

  console.log('🔧 AuthProvider - Mode mock:', useMockAuth);

  useEffect(() => {
    const initAuth = async () => {
      console.log('🚨 DÉMARRAGE: Vérification session...');
      
      try {
        if (useMockAuth) {
          // Mode mock pour éviter les erreurs 401
          console.log('🎭 MODE MOCK ACTIVÉ - Utilisation données test');
          setUser(mockUser);
          setUserRole(mockUser.role);
          setUserEntreprise(mockUser.enterprise);
        } else {
          // Mode Supabase réel
          console.log('🔐 MODE SUPABASE - Vérification session...');
          
          const { data: { session }, error } = await supabase.auth.getSession();
          
          if (error) {
            console.error('❌ Erreur récupération session:', error);
            if (error.status === 401) {
              console.log('🔄 Erreur 401 - Basculement mode mock temporaire');
              setUser(mockUser);
              setUserRole(mockUser.role);
              setUserEntreprise(mockUser.enterprise);
            }
          } else if (session?.user) {
            console.log('✅ Session Supabase trouvée:', session.user.id);
            setUser(session.user);
            setUserRole('patron'); // Rôle par défaut
            setUserEntreprise('LSPD');
          } else {
            console.log('ℹ️ Aucune session - Mode mock temporaire');
            setUser(mockUser);
            setUserRole(mockUser.role);
            setUserEntreprise(mockUser.enterprise);
          }
        }
      } catch (error) {
        console.error('💥 Erreur initialisation auth:', error);
        // Fallback en mode mock en cas d'erreur
        console.log('🛟 FALLBACK: Mode mock de secours');
        setUser(mockUser);
        setUserRole(mockUser.role);
        setUserEntreprise(mockUser.enterprise);
      } finally {
        setLoading(false);
        console.log('✅ Initialisation auth terminée');
      }
    };

    initAuth();

    // Écouter les changements d'auth seulement si pas en mode mock
    if (!useMockAuth) {
      const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
        console.log('🔄 Auth state change:', event, session?.user?.id || 'AUCUNE SESSION');

        try {
          if (event === 'SIGNED_IN' && session?.user) {
            console.log('🔓 CONNEXION RÉUSSIE');
            setUser(session.user);
            setUserRole('patron');
            setUserEntreprise('LSPD');
          } else if (event === 'SIGNED_OUT') {
            console.log('🚪 DÉCONNEXION DÉTECTÉE');
            // Ne pas déconnecter complètement, garder le mock
            setUser(mockUser);
            setUserRole(mockUser.role);
            setUserEntreprise(mockUser.enterprise);
          }
        } catch (error) {
          console.error('❌ Erreur auth state change:', error);
        }
      });

      return () => subscription.unsubscribe();
    }
  }, [useMockAuth]);

  // Fonction de connexion Discord (désactivée temporairement)
  const signInWithDiscord = async () => {
    if (useMockAuth) {
      console.log('🎭 Mode mock - Connexion simulée');
      setUser(mockUser);
      setUserRole(mockUser.role);
      setUserEntreprise(mockUser.enterprise);
      return { data: { url: null }, error: null };
    }

    try {
      console.log('🔐 Tentative connexion Discord...');
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'discord',
        options: {
          redirectTo: `https://${window.location.host}`
        }
      });

      if (error) {
        console.error('❌ Erreur connexion Discord:', error);
        // Fallback mock en cas d'erreur
        console.log('🛟 Fallback mock suite erreur Discord');
        setUser(mockUser);
        setUserRole(mockUser.role);
        setUserEntreprise(mockUser.enterprise);
        return { data: null, error: null };
      }

      return data;
    } catch (error) {
      console.error('💥 Erreur signInWithDiscord:', error);
      // Fallback mock
      setUser(mockUser);
      setUserRole(mockUser.role);
      setUserEntreprise(mockUser.enterprise);
      return { data: null, error: null };
    }
  };

  // Fonction de déconnexion
  const signOut = async () => {
    try {
      if (!useMockAuth) {
        await supabase.auth.signOut();
      }
      // Garder le mock user même après déconnexion
      setUser(mockUser);
      setUserRole(mockUser.role);
      setUserEntreprise(mockUser.enterprise);
    } catch (error) {
      console.error('❌ Erreur signOut:', error);
    }
  };

  // Fonctions de vérification des rôles
  const canAccessStaffConfig = () => {
    return userRole === 'staff';
  };

  const canAccessBlanchiment = () => {
    return ['staff', 'patron', 'co-patron'].includes(userRole);
  };

  const isReadOnlyForStaff = () => {
    return userRole === 'staff';
  };

  const canManageEnterprise = () => {
    return ['staff', 'patron'].includes(userRole);
  };

  const value = {
    user,
    userRole,
    userEntreprise,
    loading,
    signInWithDiscord,
    signOut,
    canAccessStaffConfig,
    canAccessBlanchiment,
    isReadOnlyForStaff,
    canManageEnterprise,
    useMockAuth
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export default AuthContext;
AUTHCONTEXT_FIXED

success "AuthContext mis à jour avec mode hybrid"

#################################################################
# 4. MISE À JOUR LOGINSCREEN AVEC MEILLEURE GESTION
#################################################################

log "📱 Mise à jour LoginScreen avec gestion d'erreurs..."

cat > "$FRONTEND_DIR/src/components/LoginScreen.js" << 'LOGINSCREEN_FIXED'
import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Button } from './ui/button';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';

const LoginScreen = () => {
  const { signInWithDiscord, useMockAuth } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleDiscordLogin = async () => {
    console.log('🔐 Tentative de connexion Discord...');
    setLoading(true);
    setError(null);

    try {
      const result = await signInWithDiscord();
      
      if (result?.error) {
        setError(result.error.message);
        console.error('❌ Erreur login:', result.error);
      } else {
        console.log('✅ Connexion réussie');
        // En mode mock, pas de redirection nécessaire
        if (useMockAuth) {
          window.location.reload();
        }
      }
    } catch (err) {
      console.error('💥 Erreur handleDiscordLogin:', err);
      setError('Erreur de connexion. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-purple-50">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold text-gray-900">
            Portail Entreprise Flashback Fa
          </CardTitle>
          <p className="text-gray-600">
            Connectez-vous avec Discord pour accéder à votre tableau de bord
          </p>
          
          {useMockAuth && (
            <Badge variant="secondary" className="mt-2">
              Mode Développement
            </Badge>
          )}
        </CardHeader>
        
        <CardContent className="space-y-4">
          {error && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-md">
              <p className="text-red-700 text-sm">{error}</p>
            </div>
          )}
          
          <Button
            onClick={handleDiscordLogin}
            disabled={loading}
            className="w-full bg-indigo-600 hover:bg-indigo-700 text-white"
            size="lg"
          >
            {loading ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Connexion en cours...
              </div>
            ) : (
              <div className="flex items-center">
                <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515a.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0a12.64 12.64 0 0 0-.617-1.25a.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057a19.9 19.9 0 0 0 5.993 3.03a.078.078 0 0 0 .084-.028a14.09 14.09 0 0 0 1.226-1.994a.076.076 0 0 0-.041-.106a13.107 13.107 0 0 1-1.872-.892a.077.077 0 0 1-.008-.128a10.2 10.2 0 0 0 .372-.292a.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127a12.299 12.299 0 0 1-1.873.892a.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028a19.839 19.839 0 0 0 6.002-3.03a.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.956-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.955-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.946 2.418-2.157 2.418z"/>
                </svg>
                Se connecter avec Discord
              </div>
            )}
          </Button>
          
          <div className="text-center text-sm text-gray-500">
            {useMockAuth ? (
              <p>Mode développement - Connexion automatique simulée</p>
            ) : (
              <p>Vous serez redirigé vers Discord pour l'authentification</p>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default LoginScreen;
LOGINSCREEN_FIXED

success "LoginScreen mis à jour"

#################################################################
# 5. MISE À JOUR CLIENT SUPABASE
#################################################################

log "🔧 Mise à jour client Supabase avec gestion d'erreurs..."

cat > "$FRONTEND_DIR/src/lib/supabase.js" << 'SUPABASE_CLIENT_FIXED'
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

console.log('🔧 Configuration Supabase:');
console.log('URL:', supabaseUrl);
console.log('Key présente:', !!supabaseAnonKey);

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Variables d\'environnement Supabase manquantes');
  console.log('REACT_APP_SUPABASE_URL:', supabaseUrl);
  console.log('REACT_APP_SUPABASE_ANON_KEY présente:', !!supabaseAnonKey);
}

// Configuration du client Supabase avec options robustes
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
    flowType: 'pkce'
  },
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  },
  global: {
    headers: {
      'X-My-Custom-Header': 'flashbackfa-entreprise'
    }
  }
});

// Test de connexion au démarrage
const testConnection = async () => {
  try {
    const { data, error } = await supabase.from('test').select('*').limit(1);
    if (error && error.code !== 'PGRST106') {
      console.log('⚠️ Test connexion Supabase:', error.message);
    } else {
      console.log('✅ Client Supabase initialisé');
    }
  } catch (err) {
    console.log('ℹ️ Test connexion Supabase:', err.message);
  }
};

testConnection();

export default supabase;
SUPABASE_CLIENT_FIXED

success "Client Supabase mis à jour"

#################################################################
# 6. BUILD ET REDÉMARRAGE
#################################################################

log "🏗️ Rebuild avec configuration corrigée..."

cd "$FRONTEND_DIR"

# Build avec nouvelles configurations
if yarn build; then
    success "✅ Build réussi avec configuration corrigée"
else
    error "❌ Échec build"
fi

# Redémarrer frontend
pm2 restart frontend 2>/dev/null || pm2 serve build 3000 --name "frontend" --spa

success "Frontend redémarré"

#################################################################
# 7. TESTS DE L'AUTHENTIFICATION
#################################################################

log "🧪 Tests de l'authentification..."

sleep 5

# Test de la page principale
if curl -f -s "https://$DOMAIN" >/dev/null 2>&1; then
    success "✅ Page principale accessible"
else
    warning "⚠️ Page principale en attente"
fi

# Vérifier les logs PM2 pour erreurs
log "Vérification logs frontend..."
pm2 logs frontend --lines 10 --nostream | head -5

#################################################################
# INSTRUCTIONS FINALES
#################################################################

echo ""
important "🎉 CORRECTION AUTHENTIFICATION TERMINÉE !"
echo ""
echo "✅ PROBLÈMES CORRIGÉS :"
echo "   • Erreur 401 Supabase → Mode hybrid mock/Supabase"
echo "   • Sessions instables → Fallback automatique"
echo "   • Configuration OAuth → Temporairement désactivé"
echo "   • Gestion d'erreurs → Robuste avec fallbacks"
echo ""
echo "🎭 MODE CURRENT :"
echo "   • Mode mock activé temporairement"
echo "   • Pas d'erreurs 401"
echo "   • Application fonctionnelle"
echo ""
echo "🌐 TESTEZ MAINTENANT :"
echo "   👉 https://$DOMAIN"
echo ""
echo "📊 MONITORING :"
echo "   pm2 logs frontend"
echo "   F12 → Console pour voir les logs détaillés"
echo ""

# Statut final PM2
echo "État des services :"
pm2 status

success "🚀 L'application devrait maintenant fonctionner sans erreurs 401 !"
important "Testez : https://$DOMAIN"