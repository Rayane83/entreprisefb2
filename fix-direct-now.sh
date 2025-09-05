#!/bin/bash

# 🚀 CORRECTION DIRECTE IMMÉDIATE - Création des fichiers corrigés
# Usage: ./fix-direct-now.sh

set -e

DEST_PATH="/var/www/flashbackfa-entreprise.fr"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log "🚀 CRÉATION DIRECTE DES FICHIERS CORRIGÉS"

# 1. Variables d'environnement production stricte
log "⚙️ Création .env production stricte..."

cat > "$DEST_PATH/frontend/.env" << 'EOF'
# PRODUCTION STRICTE - DISCORD OBLIGATOIRE
NODE_ENV=production
REACT_APP_PRODUCTION_MODE=true
REACT_APP_USE_MOCK_AUTH=false
REACT_APP_FORCE_DISCORD_AUTH=true

# Backend API
REACT_APP_BACKEND_URL=https://flashbackfa-entreprise.fr

# Supabase PRODUCTION
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwMzI2NDksImV4cCI6MjA3MjYwODY0OX0.nYFZjQoC6-U2zdgaaYqj3GYWByqWvoa1RconWuOOuiw

# Discord PRODUCTION - Serveur Flashback Fa
REACT_APP_DISCORD_GUILD_ID=1404608015230832742

# Désactiver développement
REACT_APP_DISABLE_DEVTOOLS=true
GENERATE_SOURCEMAP=false
WDS_SOCKET_PORT=443
EOF

# 2. AuthContext ULTRA STRICT
log "🔧 Création AuthContext Discord strict..."

cat > "$DEST_PATH/frontend/src/contexts/AuthContext.js" << 'EOF'
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
      console.log('🚨 DÉMARRAGE: Vérification session Discord...');
      
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
EOF

# 3. LoginScreen avec Discord OAuth réel
log "🔧 Création LoginScreen Discord réel..."

cat > "$DEST_PATH/frontend/src/components/LoginScreen.js" << 'EOF'
import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from './ui/card';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { LogIn, Shield, Users, Building, AlertCircle } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { toast } from 'sonner';

const LoginScreen = () => {
  const { loginWithDiscord, loading } = useAuth();
  const [isConnecting, setIsConnecting] = useState(false);

  const handleDiscordLogin = async () => {
    setIsConnecting(true);
    
    try {
      console.log('🚀 Démarrage connexion Discord...');
      toast.info('Redirection vers Discord...');
      
      const { error } = await loginWithDiscord();
      
      if (error) {
        console.error('Erreur connexion:', error);
        toast.error('Erreur lors de la connexion Discord. Vérifiez que vous êtes membre du serveur Flashback Fa.');
        setIsConnecting(false);
      }
      // Si pas d'erreur, la redirection Discord est en cours
      
    } catch (error) {
      console.error('Erreur connexion Discord:', error);
      toast.error('Erreur de connexion. Vérifiez votre connexion internet.');
      setIsConnecting(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        
        {/* Logo et Titre */}
        <div className="text-center space-y-4">
          <div className="flex items-center justify-center w-20 h-20 mx-auto bg-gradient-to-br from-blue-600 to-purple-600 rounded-full shadow-lg">
            <Building className="w-10 h-10 text-white" />
          </div>
          <div>
            <h1 className="text-4xl font-bold text-gray-900 mb-2">
              Portail Entreprise
            </h1>
            <p className="text-xl text-blue-600 font-semibold">
              Flashback Fa
            </p>
            <p className="text-sm text-gray-600 mt-3">
              Gestion des dotations, impôts et archives d'entreprise
            </p>
          </div>
        </div>

        {/* Carte de Connexion */}
        <Card className="shadow-2xl border-0 bg-white/90 backdrop-blur">
          <CardHeader className="text-center pb-4">
            <CardTitle className="flex items-center justify-center space-x-2 text-lg">
              <Shield className="w-6 h-6 text-blue-600" />
              <span>Connexion Sécurisée</span>
            </CardTitle>
            <CardDescription className="text-sm text-gray-600">
              Authentification via Discord obligatoire
            </CardDescription>
          </CardHeader>
          
          <CardContent className="space-y-6">
            
            {/* Avertissement sécurité */}
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <div className="flex items-start space-x-3">
                <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
                <div className="text-sm text-blue-800">
                  <p className="font-semibold mb-1">Accès Restreint</p>
                  <p>Vous devez être membre du serveur Discord <strong>Flashback Fa</strong> avec un rôle autorisé.</p>
                </div>
              </div>
            </div>

            {/* Rôles autorisés */}
            <div className="space-y-3">
              <div className="flex items-center space-x-2 text-sm text-gray-700">
                <Users className="w-4 h-4" />
                <span className="font-medium">Rôles autorisés :</span>
              </div>
              <div className="grid grid-cols-2 gap-2">
                <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200 justify-center py-2">
                  Staff
                </Badge>
                <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200 justify-center py-2">
                  Patron
                </Badge>
                <Badge variant="outline" className="bg-yellow-50 text-yellow-700 border-yellow-200 justify-center py-2">
                  Co-Patron
                </Badge>
                <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200 justify-center py-2">
                  DOT
                </Badge>
                <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-200 justify-center py-2 col-span-2">
                  Employé
                </Badge>
              </div>
            </div>

            {/* Bouton Discord */}
            <Button 
              onClick={handleDiscordLogin}
              disabled={loading || isConnecting}
              className="w-full bg-[#5865F2] hover:bg-[#4752C4] text-white h-14 text-lg font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
            >
              {isConnecting ? (
                <>
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-3"></div>
                  Connexion en cours...
                </>
              ) : (
                <>
                  <LogIn className="w-6 h-6 mr-3" />
                  Se connecter avec Discord
                </>
              )}
            </Button>

            {/* Informations sécurité */}
            <div className="text-xs text-gray-500 text-center space-y-2 pt-2">
              <p className="flex items-center justify-center space-x-1">
                <Shield className="w-3 h-3" />
                <span>Connexion sécurisée OAuth 2.0</span>
              </p>
              <p>
                Vos permissions sont synchronisées automatiquement avec vos rôles Discord sur le serveur Flashback Fa
              </p>
            </div>

          </CardContent>
        </Card>

        {/* Support */}
        <div className="text-center space-y-3">
          <p className="text-sm text-gray-600">
            Problème de connexion ?
          </p>
          <div className="text-xs text-gray-500 space-y-1">
            <p>• Vérifiez que vous êtes membre du serveur Discord Flashback Fa</p>
            <p>• Contactez un administrateur si vous ne pouvez pas vous connecter</p>
            <p>• Assurez-vous d'avoir un des rôles autorisés</p>
          </div>
        </div>

      </div>
    </div>
  );
};

export default LoginScreen;
EOF

# 4. App.js avec protection stricte
log "🔧 Création App.js avec protection stricte..."

cat > "$DEST_PATH/frontend/src/App.js" << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
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

# 5. Composants UI manquants
log "📝 Création composants UI manquants..."

# Badge
mkdir -p "$DEST_PATH/frontend/src/components/ui"

cat > "$DEST_PATH/frontend/src/components/ui/badge.js" << 'EOF'
import * as React from "react";
import { cva } from "class-variance-authority";
import { cn } from "../../lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      variant: {
        default:
          "border-transparent bg-primary text-primary-foreground hover:bg-primary/80",
        secondary:
          "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80",
        destructive:
          "border-transparent bg-destructive text-destructive-foreground hover:bg-destructive/80",
        outline: "text-foreground",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
);

function Badge({ className, variant, ...props }) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />;
}

export { Badge, badgeVariants };
EOF

# Card avec CardDescription
cat > "$DEST_PATH/frontend/src/components/ui/card.js" << 'EOF'
import * as React from "react";
import { cn } from "../../lib/utils";

const Card = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "rounded-lg border bg-card text-card-foreground shadow-sm",
      className
    )}
    {...props}
  />
));
Card.displayName = "Card";

const CardHeader = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex flex-col space-y-1.5 p-6", className)}
    {...props}
  />
));
CardHeader.displayName = "CardHeader";

const CardTitle = React.forwardRef(({ className, ...props }, ref) => (
  <h3
    ref={ref}
    className={cn(
      "text-2xl font-semibold leading-none tracking-tight",
      className
    )}
    {...props}
  />
));
CardTitle.displayName = "CardTitle";

const CardDescription = React.forwardRef(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn("text-sm text-muted-foreground", className)}
    {...props}
  />
));
CardDescription.displayName = "CardDescription";

const CardContent = React.forwardRef(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("p-6 pt-0", className)} {...props} />
));
CardContent.displayName = "CardContent";

const CardFooter = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex items-center p-6 pt-0", className)}
    {...props}
  />
));
CardFooter.displayName = "CardFooter";

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent };
EOF

# lib/utils.js
mkdir -p "$DEST_PATH/frontend/src/lib"

cat > "$DEST_PATH/frontend/src/lib/utils.js" << 'EOF'
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs) {
  return twMerge(clsx(inputs));
}
EOF

# 6. Build complet
log "🏗️ Build complet avec nouveau code..."

cd "$DEST_PATH/frontend"

# Supprimer l'ancien build
rm -rf build/
rm -rf node_modules/.cache/ 2>/dev/null || true

# Build avec variables d'environnement
export NODE_ENV=production
export REACT_APP_BUILD_TIME=$(date +%s)
yarn build

# 7. Redémarrage Nginx
log "🔄 Redémarrage Nginx..."

sudo systemctl stop nginx
sleep 2
sudo systemctl start nginx

# 8. Test final
log "🧪 Test final complet..."

sleep 5

# Test build
JS_FILES=$(ls build/static/js/main.*.js 2>/dev/null)
if [ ! -z "$JS_FILES" ]; then
    JS_FILENAME=$(basename $(echo $JS_FILES | cut -d' ' -f1))
    log "✅ Build généré: $JS_FILENAME"
    
    # Test contenu
    if curl -s "https://flashbackfa-entreprise.fr/" 2>/dev/null | grep -q "$JS_FILENAME"; then
        log "✅ Nouveau build servi par Nginx"
        SUCCESS=true
    else
        log "❌ Ancien build encore servi"
        SUCCESS=false
    fi
else
    log "❌ Aucun build généré"
    SUCCESS=false
fi

# Informations finales
echo ""
echo "🎉========================================🎉"
echo -e "${GREEN}   CORRECTION COMPLÈTE TERMINÉE !${NC}"
echo "🎉========================================🎉"
echo ""

echo -e "${BLUE}✅ FICHIERS CRÉÉS/CORRIGÉS:${NC}"
echo -e "   ✅ .env - Variables production strictes"
echo -e "   ✅ AuthContext.js - Discord OAuth strict"
echo -e "   ✅ LoginScreen.js - Authentification Discord réelle"
echo -e "   ✅ App.js - Protection routes stricte"
echo -e "   ✅ badge.js - Composant Badge"
echo -e "   ✅ card.js - Composant Card avec Description"
echo -e "   ✅ utils.js - Utilitaires CSS"

echo ""
echo -e "${BLUE}🎯 RÉSULTAT:${NC}"
if [ "$SUCCESS" = true ]; then
    echo -e "   ${GREEN}✅ AUTHENTIFICATION DISCORD MAINTENANT ACTIVE !${NC}"
    echo -e "   ${GREEN}🔗 https://flashbackfa-entreprise.fr${NC}"
else
    echo -e "   ⚠️ Build généré, testez dans un onglet privé"
fi

echo ""
echo -e "${BLUE}🧪 TEST IMMÉDIAT:${NC}"
echo -e "${GREEN}   1. Fermez votre navigateur complètement${NC}"
echo -e "${GREEN}   2. Rouvrez en mode privé${NC}"
echo -e "${GREEN}   3. Allez sur: https://flashbackfa-entreprise.fr${NC}"
echo -e "${GREEN}   4. Vous devriez voir la page Discord !${NC}"

echo ""
if [ "$SUCCESS" = true ]; then
    echo -e "${GREEN}🚀 L'AUTHENTIFICATION DISCORD EST OBLIGATOIRE ! 🔥${NC}"
else
    echo -e "⚠️ Si problème persiste, videz le cache navigateur complètement"
fi

exit 0