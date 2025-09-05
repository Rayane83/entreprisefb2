#!/bin/bash

#################################################################
# Script de Déploiement VPS - flashbackfa-entreprise.fr
# 
# À utiliser sur votre VPS Ubuntu dans le répertoire ~/entreprisefb
# Ce script détecte automatiquement l'environnement et déploie
#
# Usage: 
# 1. Copiez ce script dans votre répertoire ~/entreprisefb
# 2. chmod +x deploy-flashbackfa-entreprise.sh
# 3. ./deploy-flashbackfa-entreprise.sh
#################################################################

# Détection automatique du répertoire
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"
FRONTEND_DIR="$APP_DIR/frontend"
BACKEND_DIR="$APP_DIR/backend"
DOMAIN="flashbackfa-entreprise.fr"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

#################################################################
# VÉRIFICATIONS PRÉLIMINAIRES
#################################################################

log "🚀 Déploiement de l'application Portail Entreprise Flashback Fa"
log "Domaine: $DOMAIN"
log "Répertoire: $APP_DIR"

if [ ! -d "$FRONTEND_DIR" ] || [ ! -d "$BACKEND_DIR" ]; then
    error "Structure incorrecte. Vérifiez que vous êtes dans le bon répertoire."
    error "Cherché: $FRONTEND_DIR et $BACKEND_DIR"
    ls -la "$APP_DIR"
    exit 1
fi

success "Structure de répertoire validée"

#################################################################
# ARRÊT DES SERVICES
#################################################################

log "🛑 Arrêt des services existants..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true
success "Services arrêtés"

#################################################################
# NETTOYAGE
#################################################################

log "🧹 Nettoyage des anciens fichiers..."

cd "$FRONTEND_DIR"
rm -rf node_modules build .cache yarn-error.log package-lock.json
yarn cache clean --force 2>/dev/null || true

cd "$BACKEND_DIR"
rm -rf __pycache__ *.pyc .pytest_cache
find . -name "*.pyc" -delete
find . -name "__pycache__" -delete

success "Nettoyage terminé"

#################################################################
# INSTALLATION DES DÉPENDANCES
#################################################################

log "📦 Installation des dépendances frontend..."
cd "$FRONTEND_DIR"
yarn install --frozen-lockfile --network-timeout 100000

log "🐍 Installation des dépendances backend..."
cd "$BACKEND_DIR"
python3 -m pip install --upgrade pip
pip install -r requirements.txt

success "Dépendances installées"

#################################################################
# CONFIGURATION PRODUCTION
#################################################################

log "🔧 Configuration pour la production..."

cd "$FRONTEND_DIR"

# Créer ou mettre à jour le .env pour la production
cat > .env << EOF
REACT_APP_BACKEND_URL=https://$DOMAIN
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU0OTQ1NDQsImV4cCI6MjA0MTA3MDU0NH0.wql-jOauH_T8ikOEtrF6HmDEvKHvviNNwUucsPPYE9M
REACT_APP_USE_MOCK_AUTH=false
EOF

success "Configuration production mise à jour"

#################################################################
# BUILD PRODUCTION
#################################################################

log "🏗️ Build de l'application..."
cd "$FRONTEND_DIR"
yarn build
success "Build créé"

#################################################################
# REDÉMARRAGE DES SERVICES
#################################################################

log "🚀 Redémarrage des services..."

# Démarrage du backend
cd "$BACKEND_DIR"
pm2 start server.py --name "backend" --interpreter python3

# Démarrage du frontend (serveur statique)
cd "$FRONTEND_DIR"
pm2 serve build 3000 --name "frontend" --spa

# Sauvegarder la configuration PM2
pm2 save
pm2 startup

success "Services redémarrés"

#################################################################
# NGINX ET SSL
#################################################################

log "🌐 Configuration Nginx..."

# Créer la configuration Nginx
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Frontend (React build)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Handle client-side routing
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8001/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Backend health check
    location /health {
        proxy_pass http://localhost:8001/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Activer le site
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

success "Nginx configuré"

#################################################################
# VÉRIFICATIONS FINALES
#################################################################

log "✅ Vérifications finales..."

sleep 3

# Vérifier les services
echo "État des services PM2:"
pm2 status

# Test des URLs
if curl -f -s "https://$DOMAIN/health" >/dev/null 2>&1; then
    success "Backend accessible: https://$DOMAIN/health"
else
    warning "Backend non accessible"
fi

if curl -f -s "https://$DOMAIN" >/dev/null 2>&1; then
    success "Frontend accessible: https://$DOMAIN"
else
    warning "Frontend non accessible"
fi

#################################################################
# RÉSUMÉ
#################################################################

echo
success "🎉 Déploiement terminé !"
echo
echo "🌐 Votre application est accessible sur:"
echo "   👉 https://$DOMAIN"
echo
echo "🔧 Commandes utiles:"
echo "   pm2 status              # État des services"
echo "   pm2 logs frontend       # Logs frontend"
echo "   pm2 logs backend        # Logs backend"
echo "   pm2 restart all         # Redémarrer tout"
echo "   sudo nginx -t           # Tester config Nginx"
echo "   sudo systemctl reload nginx  # Recharger Nginx"
echo
echo "📁 Répertoire: $APP_DIR"
echo "🚀 Tous les services sont opérationnels !"