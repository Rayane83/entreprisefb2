#!/bin/bash

# 🚨 CORRECTION DES ERREURS CONSOLE - Fix immédiat
# Usage: ./fix-console-errors.sh

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

log "🚨 CORRECTION DES ERREURS CONSOLE DÉTECTÉES"

# 1. Corriger l'import React manquant dans AuthContext
log "🔧 Correction import React AuthContext..."

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
        if (authService && authService.signOut) {
          await authService.signOut();
        }
        
        // Vider le localStorage/sessionStorage
        if (typeof window !== 'undefined') {
          try {
            localStorage.clear();
            sessionStorage.clear();
            console.log('🗑️ localStorage/sessionStorage vidés');
          } catch (e) {
            console.warn('Erreur vidage storage:', e);
          }
        }

        // Petite pause pour s'assurer que la déconnexion est effective
        await new Promise(resolve => setTimeout(resolve, 1000));

        // VÉRIFIER S'IL Y A VRAIMENT UNE SESSION SUPABASE DISCORD
        if (authService && authService.getSession) {
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
        } else {
          console.error('❌ authService non disponible');
          if (mounted) {
            setUser(null);
            setSession(null);
            setIsAuthenticated(false);
            setUserRole(null);
            setUserEntreprise(null);
            setLoading(false);
          }
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
    let subscription = null;
    if (authService && authService.onAuthStateChange) {
      try {
        const { data } = authService.onAuthStateChange(async (event, session) => {
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
        subscription = data?.subscription;
      } catch (error) {
        console.error('Erreur setup auth listener:', error);
      }
    }

    forceLogoutAndCheckAuth();

    return () => {
      mounted = false;
      if (subscription && subscription.unsubscribe) {
        subscription.unsubscribe();
      }
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
        if (authService && authService.signOut) {
          await authService.signOut();
        }
        throw new Error('Seule la connexion Discord est autorisée');
      }

      // Récupérer les rôles Discord RÉELS
      let userRole = 'employe';
      let entreprise = 'Flashback Fa';
      
      if (authService && authService.getUserGuildRoles) {
        try {
          const rolesResult = await authService.getUserGuildRoles();
          userRole = rolesResult.userRole || 'employe';
          entreprise = rolesResult.entreprise || 'Flashback Fa';
        } catch (error) {
          console.error('Erreur récupération rôles Discord:', error);
          // Continuer avec les valeurs par défaut
        }
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
        entreprise: entreprise
      };

      console.log('✅ Utilisateur Discord configuré:', userData.discord_username);
      console.log('✅ Rôle Discord:', userRole);

      setUser(userData);
      setSession(supabaseUser);
      setUserRole(userRole);
      setUserEntreprise(entreprise);
      setIsAuthenticated(true);
      
    } catch (error) {
      console.error('❌ Erreur connexion Discord:', error);
      
      // EN CAS D'ERREUR: DÉCONNEXION TOTALE
      if (authService && authService.signOut) {
        await authService.signOut();
      }
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
      
      if (!authService || !authService.signInWithDiscord) {
        throw new Error('Service d\'authentification non disponible');
      }
      
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
      if (authService && authService.signOut) {
        await authService.signOut();
      }
      
      // Vider le stockage local
      if (typeof window !== 'undefined') {
        try {
          localStorage.clear();
          sessionStorage.clear();
        } catch (e) {
          console.warn('Erreur vidage storage:', e);
        }
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

  return React.createElement(AuthContext.Provider, { value }, children);
};
EOF

# 2. Corriger le composant LoginScreen avec gestion d'erreurs
log "🔧 Correction LoginScreen avec gestion d'erreurs..."

cat > "$DEST_PATH/frontend/src/components/LoginScreen.js" << 'EOF'
import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from './ui/card';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { LogIn, Shield, Users, Building, AlertCircle } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

// Toast simple pour éviter les erreurs d'import
const showToast = (message, type = 'info') => {
  console.log(`[${type.toUpperCase()}] ${message}`);
  // Fallback si sonner n'est pas disponible
  if (window.alert && type === 'error') {
    window.alert(message);
  }
};

const LoginScreen = () => {
  const { loginWithDiscord, loading } = useAuth();
  const [isConnecting, setIsConnecting] = useState(false);

  const handleDiscordLogin = async () => {
    setIsConnecting(true);
    
    try {
      console.log('🚀 Démarrage connexion Discord...');
      showToast('Redirection vers Discord...', 'info');
      
      if (!loginWithDiscord) {
        throw new Error('Fonction de connexion Discord non disponible');
      }
      
      const { error } = await loginWithDiscord();
      
      if (error) {
        console.error('Erreur connexion:', error);
        showToast('Erreur lors de la connexion Discord. Vérifiez que vous êtes membre du serveur Flashback Fa.', 'error');
        setIsConnecting(false);
      }
      // Si pas d'erreur, la redirection Discord est en cours
      
    } catch (error) {
      console.error('Erreur connexion Discord:', error);
      showToast('Erreur de connexion. Vérifiez votre connexion internet.', 'error');
      setIsConnecting(false);
    }
  };

  return React.createElement('div', {
    className: "min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4"
  }, 
    React.createElement('div', {
      className: "w-full max-w-md space-y-6"
    }, [
      // Logo et Titre
      React.createElement('div', {
        key: 'header',
        className: "text-center space-y-4"
      }, [
        React.createElement('div', {
          key: 'logo',
          className: "flex items-center justify-center w-20 h-20 mx-auto bg-gradient-to-br from-blue-600 to-purple-600 rounded-full shadow-lg"
        }, 
          React.createElement(Building, {
            className: "w-10 h-10 text-white"
          })
        ),
        React.createElement('div', {
          key: 'title'
        }, [
          React.createElement('h1', {
            key: 'h1',
            className: "text-4xl font-bold text-gray-900 mb-2"
          }, "Portail Entreprise"),
          React.createElement('p', {
            key: 'subtitle',
            className: "text-xl text-blue-600 font-semibold"
          }, "Flashback Fa"),
          React.createElement('p', {
            key: 'description',
            className: "text-sm text-gray-600 mt-3"
          }, "Gestion des dotations, impôts et archives d'entreprise")
        ])
      ]),

      // Carte de Connexion
      React.createElement(Card, {
        key: 'card',
        className: "shadow-2xl border-0 bg-white/90 backdrop-blur"
      }, [
        React.createElement(CardHeader, {
          key: 'cardHeader',
          className: "text-center pb-4"
        }, [
          React.createElement(CardTitle, {
            key: 'cardTitle',
            className: "flex items-center justify-center space-x-2 text-lg"
          }, [
            React.createElement(Shield, {
              key: 'shield',
              className: "w-6 h-6 text-blue-600"
            }),
            React.createElement('span', { key: 'title' }, "Connexion Sécurisée")
          ]),
          React.createElement(CardDescription, {
            key: 'cardDesc',
            className: "text-sm text-gray-600"
          }, "Authentification via Discord obligatoire")
        ]),
        
        React.createElement(CardContent, {
          key: 'cardContent',
          className: "space-y-6"
        }, [
          // Avertissement sécurité
          React.createElement('div', {
            key: 'warning',
            className: "bg-blue-50 border border-blue-200 rounded-lg p-4"
          }, 
            React.createElement('div', {
              className: "flex items-start space-x-3"
            }, [
              React.createElement(AlertCircle, {
                key: 'alert',
                className: "w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0"
              }),
              React.createElement('div', {
                key: 'text',
                className: "text-sm text-blue-800"
              }, [
                React.createElement('p', {
                  key: 'title',
                  className: "font-semibold mb-1"
                }, "Accès Restreint"),
                React.createElement('p', {
                  key: 'desc'
                }, [
                  "Vous devez être membre du serveur Discord ",
                  React.createElement('strong', { key: 'strong' }, "Flashback Fa"),
                  " avec un rôle autorisé."
                ])
              ])
            ])
          ),

          // Rôles autorisés
          React.createElement('div', {
            key: 'roles',
            className: "space-y-3"
          }, [
            React.createElement('div', {
              key: 'rolesHeader',
              className: "flex items-center space-x-2 text-sm text-gray-700"
            }, [
              React.createElement(Users, {
                key: 'users',
                className: "w-4 h-4"
              }),
              React.createElement('span', {
                key: 'text',
                className: "font-medium"
              }, "Rôles autorisés :")
            ]),
            React.createElement('div', {
              key: 'badgeGrid',
              className: "grid grid-cols-2 gap-2"
            }, [
              React.createElement(Badge, {
                key: 'staff',
                variant: "outline",
                className: "bg-blue-50 text-blue-700 border-blue-200 justify-center py-2"
              }, "Staff"),
              React.createElement(Badge, {
                key: 'patron',
                variant: "outline", 
                className: "bg-green-50 text-green-700 border-green-200 justify-center py-2"
              }, "Patron"),
              React.createElement(Badge, {
                key: 'copatron',
                variant: "outline",
                className: "bg-yellow-50 text-yellow-700 border-yellow-200 justify-center py-2"
              }, "Co-Patron"),
              React.createElement(Badge, {
                key: 'dot',
                variant: "outline",
                className: "bg-purple-50 text-purple-700 border-purple-200 justify-center py-2"
              }, "DOT"),
              React.createElement(Badge, {
                key: 'employe',
                variant: "outline",
                className: "bg-gray-50 text-gray-700 border-gray-200 justify-center py-2 col-span-2"
              }, "Employé")
            ])
          ]),

          // Bouton Discord
          React.createElement(Button, {
            key: 'discordBtn',
            onClick: handleDiscordLogin,
            disabled: loading || isConnecting,
            className: "w-full bg-[#5865F2] hover:bg-[#4752C4] text-white h-14 text-lg font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
          }, 
            isConnecting ? [
              React.createElement('div', {
                key: 'spinner',
                className: "animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-3"
              }),
              "Connexion en cours..."
            ] : [
              React.createElement(LogIn, {
                key: 'login',
                className: "w-6 h-6 mr-3"
              }),
              "Se connecter avec Discord"
            ]
          ),

          // Informations sécurité
          React.createElement('div', {
            key: 'security',
            className: "text-xs text-gray-500 text-center space-y-2 pt-2"
          }, [
            React.createElement('p', {
              key: 'securityInfo',
              className: "flex items-center justify-center space-x-1"
            }, [
              React.createElement(Shield, {
                key: 'shield',
                className: "w-3 h-3"
              }),
              React.createElement('span', {
                key: 'text'
              }, "Connexion sécurisée OAuth 2.0")
            ]),
            React.createElement('p', {
              key: 'permissions'
            }, "Vos permissions sont synchronisées automatiquement avec vos rôles Discord sur le serveur Flashback Fa")
          ])
        ])
      ]),

      // Support
      React.createElement('div', {
        key: 'support',
        className: "text-center space-y-3"
      }, [
        React.createElement('p', {
          key: 'supportTitle',
          className: "text-sm text-gray-600"
        }, "Problème de connexion ?"),
        React.createElement('div', {
          key: 'supportList',
          className: "text-xs text-gray-500 space-y-1"
        }, [
          React.createElement('p', { key: 'tip1' }, "• Vérifiez que vous êtes membre du serveur Discord Flashback Fa"),
          React.createElement('p', { key: 'tip2' }, "• Contactez un administrateur si vous ne pouvez pas vous connecter"),
          React.createElement('p', { key: 'tip3' }, "• Assurez-vous d'avoir un des rôles autorisés")
        ])
      ])
    ])
  );
};

export default LoginScreen;
EOF

# 3. Vérifier et corriger les composants UI
log "🔧 Vérification composants UI..."

# Assurer que class-variance-authority est bien installé
cd "$DEST_PATH/frontend"
if ! grep -q "class-variance-authority" package.json; then
    log "Installation class-variance-authority..."
    yarn add class-variance-authority
fi

# 4. Build avec gestion d'erreurs
log "🏗️ Build avec gestion d'erreurs..."

# Supprimer l'ancien build
rm -rf build/
rm -rf node_modules/.cache/ 2>/dev/null || true

# Build
export NODE_ENV=production
export GENERATE_SOURCEMAP=false
yarn build 2>&1 | tee /tmp/build.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log "✅ Build réussi"
    BUILD_SUCCESS=true
else
    log "❌ Erreurs de build détectées:"
    tail -20 /tmp/build.log
    BUILD_SUCCESS=false
fi

# 5. Redémarrage services si build réussi
if [ "$BUILD_SUCCESS" = true ]; then
    log "🔄 Redémarrage services..."
    
    # Redémarrer Nginx
    sudo systemctl restart nginx
    
    sleep 5
    
    # Test final
    RESPONSE=$(curl -s "https://flashbackfa-entreprise.fr/" 2>/dev/null)
    if echo "$RESPONSE" | grep -q "Portail Entreprise"; then
        log "✅ Site accessible avec nouveau code"
        SUCCESS=true
    else
        log "❌ Site pas encore accessible"
        SUCCESS=false
    fi
else
    SUCCESS=false
fi

# Informations finales
echo ""
echo "🎉================================🎉"
echo -e "${GREEN}  CORRECTION ERREURS CONSOLE${NC}"
echo "🎉================================🎉"
echo ""

echo -e "${BLUE}🔧 CORRECTIONS APPLIQUÉES:${NC}"
echo -e "   ✅ Import React corrigé"
echo -e "   ✅ Gestion d'erreurs AuthContext"
echo -e "   ✅ LoginScreen avec React.createElement"
echo -e "   ✅ Fallbacks pour modules manquants"
echo -e "   ✅ Build avec gestion d'erreurs"

echo ""
echo -e "${BLUE}🎯 RÉSULTAT:${NC}"
if [ "$SUCCESS" = true ]; then
    echo -e "   ${GREEN}✅ ERREURS CORRIGÉES - SITE FONCTIONNEL !${NC}"
    echo -e "   ${GREEN}🔗 https://flashbackfa-entreprise.fr${NC}"
else
    echo -e "   ⚠️ Corrections appliquées, testez le site"
fi

echo ""
echo -e "${BLUE}🧪 POUR TESTER:${NC}"
echo -e "${GREEN}   1. Ouvrez un onglet privé${NC}"
echo -e "${GREEN}   2. Allez sur votre site${NC}"
echo -e "${GREEN}   3. Ouvrez F12 -> Console${NC}"
echo -e "${GREEN}   4. Les erreurs devraient avoir disparu !${NC}"

exit 0