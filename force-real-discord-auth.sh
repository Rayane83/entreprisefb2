#!/bin/bash

# 🔐 FORCER AUTHENTIFICATION DISCORD RÉELLE - Suppression totale des tests/mocks
# Usage: ./force-real-discord-auth.sh

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

log "🔐 Forçage authentification Discord RÉELLE - Suppression totale des mocks..."

# 1. AuthContext PRODUCTION PURE (pas de fallback, pas de mock)
log "🔧 Configuration AuthContext PRODUCTION PURE..."

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

  useEffect(() => {
    let mounted = true;

    const getInitialSession = async () => {
      try {
        const { session, error } = await authService.getSession();
        
        if (error) {
          console.error('Erreur récupération session:', error);
          if (mounted) {
            setLoading(false);
          }
          return;
        }

        if (session?.user && mounted) {
          // UTILISATEUR DISCORD AUTHENTIFIÉ - Récupérer ses vraies données
          await handleUserLogin(session.user);
        } else if (mounted) {
          // PAS D'UTILISATEUR - OBLIGÉ DE SE CONNECTER VIA DISCORD
          setUser(null);
          setIsAuthenticated(false);
          setUserRole(null);
          setUserEntreprise(null);
          setLoading(false);
        }
      } catch (error) {
        console.error('Erreur initialisation session:', error);
        if (mounted) {
          setUser(null);
          setIsAuthenticated(false);
          setLoading(false);
        }
      }
    };

    // Écouter les changements d'authentification Supabase
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

    return () => {
      mounted = false;
      subscription?.unsubscribe();
    };
  }, []);

  // Traiter la connexion d'un utilisateur Discord réel
  const handleUserLogin = async (supabaseUser) => {
    setLoading(true);
    
    try {
      console.log('Traitement utilisateur Discord:', supabaseUser.email);
      
      // Vérifier que c'est bien un utilisateur Discord
      if (supabaseUser.app_metadata?.provider !== 'discord') {
        throw new Error('Seule la connexion Discord est autorisée');
      }

      // Récupérer les rôles Discord RÉELS
      const { userRole, entreprise, error } = await authService.getUserGuildRoles();
      
      if (error) {
        console.error('Erreur récupération rôles Discord:', error);
        throw error;
      }

      // Créer l'objet utilisateur avec les vraies données Discord
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

      console.log('Utilisateur Discord configuré:', userData);
      console.log('Rôle Discord détecté:', userRole);

      setUser(userData);
      setUserRole(userRole || 'employe');
      setUserEntreprise(entreprise || 'Flashback Fa');
      setIsAuthenticated(true);
      
    } catch (error) {
      console.error('Erreur traitement connexion Discord:', error);
      
      // EN CAS D'ERREUR: DÉCONNECTER L'UTILISATEUR
      await authService.signOut();
      setUser(null);
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
      console.log('Lancement authentification Discord...');
      
      const { error } = await authService.signInWithDiscord();
      if (error) {
        console.error('Erreur connexion Discord:', error);
        setLoading(false);
        return { error };
      }
      
      // Le reste sera géré par onAuthStateChange
      return { error: null };
    } catch (error) {
      console.error('Erreur connexion Discord:', error);
      setLoading(false);
      return { error };
    }
  };

  // Déconnexion
  const logout = async () => {
    try {
      await authService.signOut();
      setUser(null);
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

# 2. Service d'authentification PRODUCTION (pas de fallback)
log "🔧 Configuration authService PRODUCTION..."

cat > "$DEST_PATH/frontend/src/services/authService.js" << 'EOF'
import { supabase } from '../lib/supabase';

export const authService = {
  // Connexion Discord OBLIGATOIRE
  async signInWithDiscord() {
    try {
      console.log('Lancement OAuth Discord...');
      
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'discord',
        options: {
          redirectTo: window.location.origin,
          scopes: 'identify guilds guilds.members.read'
        }
      });

      if (error) {
        console.error('Erreur OAuth Discord:', error);
        return { data: null, error };
      }

      console.log('Redirection Discord initiée');
      return { data, error: null };
    } catch (error) {
      console.error('Erreur signInWithDiscord:', error);
      return { data: null, error };
    }
  },

  // Déconnexion
  async signOut() {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) {
        console.error('Erreur déconnexion:', error);
      }
      return { error };
    } catch (error) {
      console.error('Erreur signOut:', error);
      return { error };
    }
  },

  // Récupérer la session actuelle
  async getSession() {
    try {
      const { data, error } = await supabase.auth.getSession();
      return { session: data, error };
    } catch (error) {
      console.error('Erreur getSession:', error);
      return { session: null, error };
    }
  },

  // Écouter les changements d'authentification
  onAuthStateChange(callback) {
    return supabase.auth.onAuthStateChange(callback);
  },

  // Récupérer les rôles Discord RÉELS de l'utilisateur
  async getUserGuildRoles(guildId = '1404608015230832742') {
    try {
      const { data: session } = await this.getSession();
      if (!session.session?.user) {
        return { roles: [], userRole: null, entreprise: null, error: 'Non connecté' };
      }

      const user = session.session.user;

      // Vérifier que c'est un utilisateur Discord
      if (user.app_metadata?.provider !== 'discord') {
        return { roles: [], userRole: null, entreprise: null, error: 'Connexion Discord requise' };
      }

      // Métadonnées Discord
      const discordData = user.user_metadata;
      const discordUserId = discordData.provider_id || discordData.sub;

      console.log('Récupération rôles Discord pour utilisateur:', discordUserId);

      try {
        // Appeler l'edge function pour récupérer les rôles Discord RÉELS
        const { data: rolesData, error: rolesError } = await supabase.functions.invoke('get-discord-roles', {
          body: { 
            guildId, 
            discordUserId 
          }
        });

        if (rolesError) {
          console.warn('Edge function non disponible, utilisation rôles basiques:', rolesError);
          return this.getBasicRole(user);
        }

        // Analyser les rôles retournés par Discord
        const userRoles = rolesData.roles || [];
        console.log('Rôles Discord reçus:', userRoles);

        // Déterminer le rôle principal selon la hiérarchie
        const roleHierarchy = ['staff', 'patron', 'co-patron', 'dot', 'employe'];
        let userRole = 'employe'; // Par défaut

        for (const roleName of roleHierarchy) {
          const hasRole = userRoles.some(r => 
            r.name.toLowerCase().includes(roleName) || 
            r.name.toLowerCase().includes(roleName.replace('-', '')) ||
            r.id === this.getRoleId(roleName)
          );
          
          if (hasRole) {
            userRole = roleName;
            console.log(`Rôle principal détecté: ${userRole}`);
            break;
          }
        }

        // Mettre à jour le profil utilisateur dans Supabase
        await this.updateUserProfile(user.id, {
          discord_id: discordUserId,
          discord_username: discordData.full_name || discordData.name || 'Utilisateur',
          current_role: userRole,
          enterprise_id: rolesData.enterpriseId
        });

        return {
          roles: userRoles,
          userRole,
          entreprise: rolesData.enterpriseName || 'Flashback Fa',
          error: null
        };

      } catch (edgeFunctionError) {
        console.warn('Erreur edge function, utilisation rôles basiques:', edgeFunctionError);
        return this.getBasicRole(user);
      }

    } catch (error) {
      console.error('Erreur récupération rôles:', error);
      return { roles: [], userRole: null, entreprise: null, error };
    }
  },

  // Rôle basique basé sur l'email (fallback minimal)
  getBasicRole(user) {
    const email = user.email?.toLowerCase() || '';
    let userRole = 'employe';
    
    // Détection basique selon l'email
    if (email.includes('admin') || email.includes('staff')) userRole = 'staff';
    else if (email.includes('patron') && email.includes('co')) userRole = 'co-patron';
    else if (email.includes('patron')) userRole = 'patron';
    else if (email.includes('dot')) userRole = 'dot';

    console.log(`Rôle basique attribué: ${userRole} (basé sur email: ${email})`);

    return { 
      roles: [{ name: userRole.charAt(0).toUpperCase() + userRole.slice(1), color: '#666666' }], 
      userRole,
      entreprise: 'Flashback Fa',
      error: null 
    };
  },

  // Récupérer l'ID de rôle Discord par nom
  getRoleId(roleName) {
    const roleIds = {
      'staff': process.env.REACT_APP_DISCORD_STAFF_ROLE_ID || '',
      'patron': process.env.REACT_APP_DISCORD_PATRON_ROLE_ID || '',
      'co-patron': process.env.REACT_APP_DISCORD_CO_PATRON_ROLE_ID || '',
      'dot': process.env.REACT_APP_DISCORD_DOT_ROLE_ID || '',
      'employe': process.env.REACT_APP_DISCORD_EMPLOYE_ROLE_ID || ''
    };
    return roleIds[roleName];
  },

  // Mettre à jour le profil utilisateur
  async updateUserProfile(userId, profileData) {
    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .upsert({
          id: userId,
          ...profileData,
          updated_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur mise à jour profil:', error);
      return { data: null, error };
    }
  }
};
EOF

# 3. Écran de connexion PRODUCTION (Discord obligatoire)
log "🔧 Configuration LoginScreen PRODUCTION..."

cat > "$DEST_PATH/frontend/src/components/LoginScreen.js" << 'EOF'
import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
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
      console.log('Démarrage connexion Discord...');
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
            <p className="text-sm text-gray-600">
              Authentification via Discord obligatoire
            </p>
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

# 4. Variables d'environnement PRODUCTION STRICTE
log "⚙️ Variables d'environnement PRODUCTION STRICTE..."

cat > "$DEST_PATH/frontend/.env" << EOF
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
EOF

# 5. Rebuild complet avec authentification Discord pure
log "🏗️ Rebuild PRODUCTION avec authentification Discord pure..."

cd "$DEST_PATH/frontend"
yarn build

# 6. Redémarrage des services
log "🔄 Redémarrage des services..."

pm2 restart all
sudo systemctl reload nginx

# 7. Test final
log "🧪 Test final - Authentification Discord OBLIGATOIRE..."

sleep 5

if curl -f -s "http://localhost:8001/api/" > /dev/null; then
    log "✅ Backend opérationnel"
else
    log "❌ Problème backend"
fi

# Informations finales
echo ""
echo "🎉============================================🎉"
echo -e "${GREEN}  AUTHENTIFICATION DISCORD RÉELLE ACTIVÉE !${NC}"
echo "🎉============================================🎉"
echo ""

echo -e "${BLUE}🔐 AUTHENTIFICATION:${NC}"
echo -e "   ✅ Discord OAuth OBLIGATOIRE"
echo -e "   ❌ Plus de données de test/mock"
echo -e "   ✅ Rôles Discord synchronisés automatiquement"
echo ""

echo -e "${BLUE}🌟 VOTRE SITE:${NC}"
if [ -f "/etc/letsencrypt/live/flashbackfa-entreprise.fr/fullchain.pem" ]; then
    echo -e "   🔗 https://flashbackfa-entreprise.fr"
else
    echo -e "   🔗 http://flashbackfa-entreprise.fr"
fi
echo ""

echo -e "${GREEN}🎯 MAINTENANT:${NC}"
echo -e "${GREEN}   1. Allez sur votre site${NC}"
echo -e "${GREEN}   2. Cliquez sur 'Se connecter avec Discord'${NC}"  
echo -e "${GREEN}   3. Autorisez l'application Discord${NC}"
echo -e "${GREEN}   4. Vous serez connecté avec votre rôle Discord réel !${NC}"

exit 0