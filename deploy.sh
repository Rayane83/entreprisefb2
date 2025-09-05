#!/bin/bash

# 🚀 Script de Déploiement Automatique - Portail Entreprise Flashback Fa
# Usage: ./deploy.sh [domain] [project_path]

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
    error "Usage: $0 <domain> <project_path>\nExemple: $0 portail.example.com /var/www/portail-entreprise"
fi

DOMAIN=$1
PROJECT_PATH=$2
CURRENT_DIR=$(pwd)

log "🚀 Démarrage du déploiement pour $DOMAIN"
log "📁 Chemin du projet: $PROJECT_PATH"

# Vérification des prérequis
check_requirements() {
    log "🔍 Vérification des prérequis..."
    
    command -v node >/dev/null 2>&1 || error "Node.js n'est pas installé"
    command -v python3 >/dev/null 2>&1 || error "Python3 n'est pas installé"
    command -v nginx >/dev/null 2>&1 || error "Nginx n'est pas installé"
    command -v pm2 >/dev/null 2>&1 || error "PM2 n'est pas installé"
    
    log "✅ Tous les prérequis sont installés"
}

# Installation des dépendances
install_dependencies() {
    log "📦 Installation des dépendances..."
    
    # Backend
    cd "$PROJECT_PATH/backend"
    if [ ! -d "venv" ]; then
        log "Création de l'environnement virtuel Python..."
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    pip install -r requirements.txt
    
    # Frontend
    cd "$PROJECT_PATH/frontend"
    if [ ! -f "yarn.lock" ]; then
        yarn install
    else
        yarn install --frozen-lockfile
    fi
    
    log "✅ Dépendances installées"
}

# Configuration des variables d'environnement
setup_env() {
    log "⚙️ Configuration des variables d'environnement..."
    
    # Backend .env
    if [ ! -f "$PROJECT_PATH/backend/.env" ]; then
        log "Création du fichier .env backend..."
        cat > "$PROJECT_PATH/backend/.env" << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=portail_entreprise
PORT=8001
HOST=0.0.0.0
ENV=production
DEBUG=false
ALLOWED_ORIGINS=["https://$DOMAIN"]
EOF
    fi
    
    # Frontend .env
    if [ ! -f "$PROJECT_PATH/frontend/.env" ]; then
        log "Création du fichier .env frontend..."
        cat > "$PROJECT_PATH/frontend/.env" << EOF
REACT_APP_BACKEND_URL=https://$DOMAIN
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwMzI2NDksImV4cCI6MjA3MjYwODY0OX0.nYFZjQoC6-U2zdgaaYqj3GYWByqWvoa1RconWuOOuiw
REACT_APP_DISCORD_GUILD_ID=1404608015230832742
NODE_ENV=production
EOF
    fi
    
    log "✅ Variables d'environnement configurées"
}

# Build du frontend
build_frontend() {
    log "🏗️ Build du frontend..."
    
    cd "$PROJECT_PATH/frontend"
    yarn build
    
    log "✅ Frontend buildé"
}

# Configuration Nginx
setup_nginx() {
    log "🌐 Configuration Nginx..."
    
    # Création du fichier de configuration
    sudo tee /etc/nginx/sites-available/portail-entreprise > /dev/null << EOF
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
        root $PROJECT_PATH/frontend/build;
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
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF
    
    # Activation du site
    sudo ln -sf /etc/nginx/sites-available/portail-entreprise /etc/nginx/sites-enabled/
    
    # Test de la configuration
    sudo nginx -t || error "Configuration Nginx invalide"
    
    sudo systemctl reload nginx
    
    log "✅ Nginx configuré"
}

# Configuration PM2
setup_pm2() {
    log "🔄 Configuration PM2..."
    
    # Création du fichier ecosystem
    cat > "$PROJECT_PATH/ecosystem.config.js" << EOF
module.exports = {
  apps: [
    {
      name: 'portail-backend',
      cwd: '$PROJECT_PATH/backend',
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
      log_file: '$PROJECT_PATH/logs/backend.log',
      out_file: '$PROJECT_PATH/logs/backend-out.log',
      error_file: '$PROJECT_PATH/logs/backend-error.log',
      time: true
    }
  ]
};
EOF
    
    # Création du dossier logs
    mkdir -p "$PROJECT_PATH/logs"
    
    # Arrêt des anciens processus
    pm2 delete portail-backend 2>/dev/null || true
    
    # Démarrage
    cd "$PROJECT_PATH"
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

# Création du script de mise à jour
create_update_script() {
    log "📝 Création du script de mise à jour..."
    
    cat > "$PROJECT_PATH/update.sh" << 'EOF'
#!/bin/bash
set -e

log() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

log "🔄 Mise à jour du Portail Entreprise..."

# Git pull
git pull origin main

# Backend
cd backend
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Frontend
cd frontend
yarn install
yarn build
cd ..

# Redémarrage
pm2 restart portail-backend
sudo systemctl reload nginx

log "✅ Mise à jour terminée !"
EOF
    
    chmod +x "$PROJECT_PATH/update.sh"
    
    log "✅ Script de mise à jour créé : $PROJECT_PATH/update.sh"
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
    if [ -f "$PROJECT_PATH/frontend/build/index.html" ]; then
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
    log "🎉 Déploiement terminé !"
    echo ""
    echo -e "${BLUE}📋 Informations de déploiement:${NC}"
    echo -e "   🌐 Frontend: https://$DOMAIN"
    echo -e "   🔧 API: https://$DOMAIN/api/"
    echo -e "   📁 Projet: $PROJECT_PATH"
    echo ""
    echo -e "${BLUE}📊 Commandes utiles:${NC}"
    echo -e "   pm2 status                    # Statut des processus"
    echo -e "   pm2 logs portail-backend     # Logs backend"
    echo -e "   pm2 restart portail-backend  # Redémarrer backend"
    echo -e "   sudo systemctl status nginx  # Statut Nginx"
    echo -e "   $PROJECT_PATH/update.sh      # Mise à jour"
    echo ""
    echo -e "${YELLOW}⚠️ N'oubliez pas:${NC}"
    echo -e "   1. Configurer votre DNS pour pointer vers ce serveur"
    echo -e "   2. Exécuter les scripts SQL Supabase"
    echo -e "   3. Configurer Discord OAuth dans Supabase"
}

# Exécution du déploiement
main() {
    check_requirements
    install_dependencies
    setup_env
    build_frontend
    setup_nginx
    setup_pm2
    setup_ssl
    create_update_script
    run_tests
    show_final_info
}

# Gestion des erreurs
trap 'error "❌ Une erreur est survenue pendant le déploiement"' ERR

# Exécution
main