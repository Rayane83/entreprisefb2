#!/bin/bash

# 🚀 Script de Déploiement Corrigé - Portail Entreprise Flashback Fa
# Usage: ./deploy-fixed.sh [domain] [destination_path]

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Vérification des paramètres
if [ $# -lt 2 ]; then
    error "Usage: $0 <domain> <destination_path>\nExemple: $0 flashbackfa-entreprise.fr /var/www/flashbackfa-entreprise.fr"
fi

DOMAIN=$1
DEST_PATH=$2
CURRENT_DIR=$(pwd)

log "🚀 Démarrage du déploiement pour $DOMAIN"
log "📁 Dossier actuel: $CURRENT_DIR"
log "📁 Destination: $DEST_PATH"

# Vérification des prérequis
check_requirements() {
    log "🔍 Vérification des prérequis..."
    
    command -v node >/dev/null 2>&1 || error "Node.js n'est pas installé"
    command -v python3 >/dev/null 2>&1 || error "Python3 n'est pas installé"
    command -v nginx >/dev/null 2>&1 || error "Nginx n'est pas installé"
    command -v pm2 >/dev/null 2>&1 || error "PM2 n'est pas installé"
    
    # Vérifier que nous sommes dans le bon dossier
    if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
        error "Ce script doit être exécuté depuis le dossier du projet (contenant backend/ et frontend/)"
    fi
    
    log "✅ Tous les prérequis sont installés"
}

# Copier les fichiers du projet
copy_project_files() {
    log "📂 Copie des fichiers du projet..."
    
    # Créer le dossier de destination
    sudo mkdir -p "$DEST_PATH"
    sudo chown -R $USER:$USER "$DEST_PATH"
    
    # Copier les fichiers (exclure node_modules, venv, .git)
    rsync -av --exclude='node_modules' --exclude='venv' --exclude='.git' --exclude='build' \
          "$CURRENT_DIR/" "$DEST_PATH/"
    
    log "✅ Fichiers copiés vers $DEST_PATH"
}

# Installation des dépendances
install_dependencies() {
    log "📦 Installation des dépendances..."
    
    # Backend
    cd "$DEST_PATH/backend"
    if [ ! -d "venv" ]; then
        log "Création de l'environnement virtuel Python..."
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    pip install -r requirements.txt
    
    # Frontend
    cd "$DEST_PATH/frontend"
    yarn install --production=false
    
    log "✅ Dépendances installées"
}

# Configuration des variables d'environnement RÉELLES
setup_env() {
    log "⚙️ Configuration des variables d'environnement PRODUCTION..."
    
    # Backend .env
    log "Configuration backend pour PRODUCTION..."
    cat > "$DEST_PATH/backend/.env" << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=portail_entreprise_prod
PORT=8001
HOST=0.0.0.0
ENV=production
DEBUG=false
ALLOWED_ORIGINS=["https://$DOMAIN", "https://www.$DOMAIN"]
EOF
    
    # Frontend .env pour PRODUCTION (sans fallback mock)
    log "Configuration frontend pour PRODUCTION avec authentification Discord RÉELLE..."
    cat > "$DEST_PATH/frontend/.env" << EOF
# Backend API
REACT_APP_BACKEND_URL=https://$DOMAIN

# Supabase PRODUCTION
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwMzI2NDksImV4cCI6MjA3MjYwODY0OX0.nYFZjQoC6-U2zdgaaYqj3GYWByqWvoa1RconWuOOuiw

# Discord PRODUCTION - Guild Flashback Fa
REACT_APP_DISCORD_GUILD_ID=1404608015230832742

# Mode PRODUCTION (pas de données mock)
NODE_ENV=production
REACT_APP_USE_MOCK_AUTH=false
REACT_APP_PRODUCTION_MODE=true
EOF
    
    log "✅ Variables d'environnement PRODUCTION configurées"
}

# Mise à jour du AuthContext pour la production
update_auth_context() {
    log "🔧 Configuration AuthContext pour la PRODUCTION..."
    
    # Créer une version production du AuthContext
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
  const [userRole, setUserRole] = useState('employe');
  const [userEntreprise, setUserEntreprise] = useState('');

  // MODE PRODUCTION - PAS DE DONNÉES MOCK
  const isProduction = process.env.REACT_APP_PRODUCTION_MODE === 'true';

  useEffect(() => {
    let mounted = true;

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
          // EN PRODUCTION : Pas d'utilisateur mock, rediriger vers login
          if (isProduction) {
            setUser(null);
            setIsAuthenticated(false);
            setLoading(false);
          } else {
            // Mode développement : utiliser utilisateur mock
            const mockUser = {
              id: '12345',
              email: 'patron@lspd.com',
              discord_username: 'Jean Dupont',
              entreprise: 'LSPD'
            };
            setUser(mockUser);
            setIsAuthenticated(true);
            setUserRole('patron');
            setUserEntreprise('LSPD');
            setLoading(false);
          }
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

    return () => {
      mounted = false;
      subscription?.unsubscribe();
    };
  }, [isProduction]);

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
        entreprise: entreprise || 'Flashback Fa'
      };

      setUser(userData);
      setUserRole(userRole || 'employe');
      setUserEntreprise(entreprise || 'Flashback Fa');
      setIsAuthenticated(true);
      
    } catch (error) {
      console.error('Erreur traitement connexion:', error);
      // En production, ne pas créer d'utilisateur par défaut
      if (!isProduction) {
        setUser({
          id: supabaseUser.id,
          email: supabaseUser.email,
          discord_username: 'Utilisateur',
          entreprise: 'Flashback Fa'
        });
        setUserRole('employe');
        setUserEntreprise('Flashback Fa');
        setIsAuthenticated(true);
      }
    } finally {
      setLoading(false);
    }
  };

  // Connexion Discord
  const loginWithDiscord = async () => {
    try {
      const { error } = await authService.signInWithDiscord();
      if (error) {
        console.error('Erreur connexion Discord:', error);
        return { error };
      }
      return { error: null };
    } catch (error) {
      console.error('Erreur connexion Discord:', error);
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
    canAccessDotationConfig,
    isProduction
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
EOF
    
    log "✅ AuthContext configuré pour la PRODUCTION"
}

# Build du frontend
build_frontend() {
    log "🏗️ Build du frontend pour la PRODUCTION..."
    
    cd "$DEST_PATH/frontend"
    yarn build
    
    log "✅ Frontend buildé pour la production"
}

# Configuration Nginx
setup_nginx() {
    log "🌐 Configuration Nginx..."
    
    # Création du fichier de configuration
    sudo tee /etc/nginx/sites-available/flashbackfa-entreprise > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # Frontend
    location / {
        root $DEST_PATH/frontend/build;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF
    
    # Activation du site
    sudo ln -sf /etc/nginx/sites-available/flashbackfa-entreprise /etc/nginx/sites-enabled/
    
    # Supprimer la config par défaut
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test de la configuration
    sudo nginx -t || error "Configuration Nginx invalide"
    
    sudo systemctl reload nginx
    
    log "✅ Nginx configuré"
}

# Configuration PM2
setup_pm2() {
    log "🔄 Configuration PM2..."
    
    # Création du fichier ecosystem
    cat > "$DEST_PATH/ecosystem.config.js" << EOF
module.exports = {
  apps: [
    {
      name: 'flashbackfa-backend',
      cwd: '$DEST_PATH/backend',
      script: 'venv/bin/python',
      args: '-m uvicorn server:app --host 0.0.0.0 --port 8001',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 8001
      },
      log_file: '$DEST_PATH/logs/backend.log',
      out_file: '$DEST_PATH/logs/backend-out.log',
      error_file: '$DEST_PATH/logs/backend-error.log',
      time: true
    }
  ]
};
EOF
    
    # Création du dossier logs
    mkdir -p "$DEST_PATH/logs"
    
    # Arrêt des anciens processus
    pm2 delete flashbackfa-backend 2>/dev/null || true
    
    # Démarrage
    cd "$DEST_PATH"
    pm2 start ecosystem.config.js
    pm2 save
    
    log "✅ PM2 configuré et démarré"
}

# Configuration SSL
setup_ssl() {
    log "🔒 Configuration SSL avec Let's Encrypt..."
    
    if ! command -v certbot &> /dev/null; then
        log "Installation de Certbot..."
        sudo apt update
        sudo apt install certbot python3-certbot-nginx -y
    fi
    
    # Obtention du certificat
    sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN" || warn "Échec de la configuration SSL automatique"
    
    log "✅ SSL configuré (ou tentative effectuée)"
}

# Tests de vérification
run_tests() {
    log "🧪 Tests de vérification..."
    
    # Test backend
    sleep 5
    if curl -f -s "http://localhost:8001/api/" > /dev/null; then
        log "✅ Backend accessible"
    else
        warn "⚠️ Backend pourrait ne pas être accessible"
    fi
    
    # Test frontend (fichiers)
    if [ -f "$DEST_PATH/frontend/build/index.html" ]; then
        log "✅ Frontend buildé"
    else
        error "❌ Frontend non buildé"
    fi
    
    # Test Nginx
    if sudo nginx -t > /dev/null 2>&1; then
        log "✅ Configuration Nginx valide"
    else
        error "❌ Configuration Nginx invalide"
    fi
}

# Affichage des informations finales
show_final_info() {
    log "🎉 Déploiement PRODUCTION terminé !"
    echo ""
    echo -e "${BLUE}📋 Informations de déploiement PRODUCTION:${NC}"
    echo -e "   🌐 Application: https://$DOMAIN"
    echo -e "   🔧 API: https://$DOMAIN/api/"
    echo -e "   📁 Projet: $DEST_PATH"
    echo -e "   🔐 Mode: PRODUCTION (authentification Discord requise)"
    echo ""
    echo -e "${BLUE}📊 Commandes utiles:${NC}"
    echo -e "   pm2 status                         # Statut des processus"
    echo -e "   pm2 logs flashbackfa-backend      # Logs backend"
    echo -e "   pm2 restart flashbackfa-backend   # Redémarrer backend"
    echo -e "   sudo systemctl status nginx       # Statut Nginx"
    echo ""
    echo -e "${YELLOW}⚠️ IMPORTANT - Configuration Discord OAuth:${NC}"
    echo -e "   1. Aller sur https://discord.com/developers/applications"
    echo -e "   2. Créer/configurer votre application Discord"
    echo -e "   3. Ajouter le redirect URL: https://dutvmjnhnrpqoztftzgd.supabase.co/auth/v1/callback"
    echo -e "   4. Configurer Discord OAuth dans Supabase Dashboard"
    echo -e "   5. Exécuter les scripts SQL dans Supabase"
    echo ""
    echo -e "${GREEN}✅ L'application est maintenant en PRODUCTION avec authentification Discord réelle !${NC}"
}

# Exécution du déploiement
main() {
    check_requirements
    copy_project_files
    install_dependencies
    setup_env
    update_auth_context
    build_frontend
    setup_nginx
    setup_pm2
    setup_ssl
    run_tests
    show_final_info
}

# Gestion des erreurs
trap 'error "❌ Une erreur est survenue pendant le déploiement"' ERR

# Exécution
main
EOF