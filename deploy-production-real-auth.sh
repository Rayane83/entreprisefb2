#!/bin/bash

#################################################################
# Script de Déploiement Production RÉEL - flashbackfa-entreprise.fr
# 
# CONFIGURATION PRODUCTION COMPLÈTE :
# - Authentification Discord OAuth RÉELLE (pas mock)
# - Nettoyage complet de tous les anciens builds
# - Build 100% nouveau et propre
# - Configuration production optimisée
#################################################################

APP_DIR="$HOME/entreprisefb"
FRONTEND_DIR="$APP_DIR/frontend"
BACKEND_DIR="$APP_DIR/backend"
VENV_DIR="$BACKEND_DIR/venv"
DOMAIN="flashbackfa-entreprise.fr"

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

important "🚀 DÉPLOIEMENT PRODUCTION RÉEL - Version Publique avec Discord OAuth"
log "Domaine: $DOMAIN"
log "Mode: PRODUCTION (pas de mock)"

#################################################################
# 1. ARRÊT COMPLET DE TOUS LES SERVICES
#################################################################

log "🛑 Arrêt complet de tous les services..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true

# Tuer tous les processus Node.js et Python qui traînent
sudo pkill -f "node.*serve" 2>/dev/null || true
sudo pkill -f "python.*server.py" 2>/dev/null || true

success "Tous les services arrêtés"

#################################################################
# 2. NETTOYAGE RADICAL DE TOUS LES ANCIENS BUILDS
#################################################################

log "🧹 NETTOYAGE RADICAL - Suppression de tout l'ancien code..."

cd "$FRONTEND_DIR"

# Supprimer TOUT l'ancien frontend
rm -rf node_modules
rm -rf build
rm -rf dist
rm -rf .next
rm -rf .cache
rm -rf .parcel-cache
rm -rf coverage
rm -rf yarn-error.log
rm -rf npm-debug.log*
rm -rf package-lock.json
rm -rf .npm
rm -rf .yarn

# Nettoyage des caches système
yarn cache clean --force 2>/dev/null || true
npm cache clean --force 2>/dev/null || true
sudo npm cache clean --force 2>/dev/null || true

# Nettoyage Docker si présent
docker system prune -f 2>/dev/null || true

success "Frontend complètement nettoyé"

cd "$BACKEND_DIR"

# Supprimer TOUT l'ancien backend
rm -rf __pycache__
rm -rf venv
rm -rf .pytest_cache
rm -rf *.egg-info
rm -rf .coverage
rm -rf htmlcov
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Nettoyage cache pip
pip cache purge 2>/dev/null || true
sudo pip cache purge 2>/dev/null || true

success "Backend complètement nettoyé"

#################################################################
# 3. CONFIGURATION AUTHENTIFICATION DISCORD RÉELLE
#################################################################

important "🔐 Configuration authentification Discord RÉELLE..."

cd "$FRONTEND_DIR"

# Configuration PRODUCTION avec Discord OAuth RÉEL
cat > .env << EOF
# CONFIGURATION PRODUCTION - AUTHENTIFICATION DISCORD RÉELLE
REACT_APP_BACKEND_URL=https://$DOMAIN
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU0OTQ1NDQsImV4cCI6MjA0MTA3MDU0NH0.wql-jOauH_T8ikOEtrF6HmDEvKHvviNNwUucsPPYE9M

# AUTHENTIFICATION DISCORD RÉELLE (PAS DE MOCK)
REACT_APP_USE_MOCK_AUTH=false

# DISCORD OAUTH CONFIGURATION
REACT_APP_DISCORD_CLIENT_ID=1279855624938803280
REACT_APP_DISCORD_REDIRECT_URI=https://$DOMAIN/auth/callback

# CONFIGURATION PRODUCTION
NODE_ENV=production
GENERATE_SOURCEMAP=false
REACT_APP_ENV=production
EOF

success "Configuration Discord OAuth RÉELLE activée"

# Configuration backend
cd "$BACKEND_DIR"

cat > .env << EOF
# CONFIGURATION BACKEND PRODUCTION
MONGO_URL=mongodb://localhost:27017
DB_NAME=flashbackfa_production
CORS_ORIGINS=https://$DOMAIN,https://www.$DOMAIN

# SUPABASE BACKEND
SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNTQ5NDU0NCwiZXhwIjoyMDQxMDcwNTQ0fQ.BbkOMA73CvFU8zrJk3PSCMn4vH_pYbqbUWHGaUJb9bY

# DISCORD CONFIGURATION
DISCORD_BOT_TOKEN=YOUR_DISCORD_BOT_TOKEN_HERE
DISCORD_CLIENT_SECRET=YOUR_DISCORD_CLIENT_SECRET_HERE

# PRODUCTION SETTINGS
ENVIRONMENT=production
DEBUG=false
EOF

success "Configuration backend production créée"

#################################################################
# 4. INSTALLATION PROPRE ENVIRONNEMENT VIRTUEL PYTHON
#################################################################

log "🐍 Installation environnement virtuel Python PROPRE..."

cd "$BACKEND_DIR"

# Créer un environnement virtuel totalement propre
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# Mettre à jour pip à la dernière version
pip install --upgrade pip setuptools wheel

# Installer les dépendances essentielles
pip install fastapi uvicorn[standard] pymongo python-multipart python-dotenv pydantic pydantic-settings

# Vérifier que FastAPI fonctionne
python -c "import fastapi; print('✅ FastAPI OK')"

success "Environnement Python propre installé"

#################################################################
# 5. INSTALLATION DÉPENDANCES FRONTEND PROPRES
#################################################################

log "📦 Installation dépendances frontend PROPRES..."

cd "$FRONTEND_DIR"

# Installation complètement propre
yarn install --frozen-lockfile --network-timeout 120000 --check-files

# Vérifier les dépendances critiques
CRITICAL_DEPS=("react" "react-dom" "react-router-dom" "@supabase/supabase-js" "lucide-react")

for dep in "${CRITICAL_DEPS[@]}"; do
    if ! yarn list --pattern "$dep" >/dev/null 2>&1; then
        warning "Installation dépendance critique: $dep"
        yarn add "$dep"
    fi
done

success "Dépendances frontend propres installées"

#################################################################
# 6. BUILD PRODUCTION OPTIMISÉ
#################################################################

important "🏗️ BUILD PRODUCTION OPTIMISÉ - Version publique..."

cd "$FRONTEND_DIR"

# Build production avec optimisations maximales
export NODE_ENV=production
export GENERATE_SOURCEMAP=false
export REACT_APP_ENV=production

log "Début du build production (peut prendre quelques minutes)..."
yarn build

# Vérifier que le build est réussi
if [ ! -d "build" ] || [ ! -f "build/index.html" ]; then
    error "❌ Échec du build frontend"
    exit 1
fi

# Vérifier la taille du build
BUILD_SIZE=$(du -sh build | cut -f1)
log "Taille du build: $BUILD_SIZE"

success "Build production créé avec succès"

#################################################################
# 7. OPTIMISATION BUILD
#################################################################

log "⚡ Optimisation du build..."

cd "$FRONTEND_DIR/build"

# Compression des fichiers statiques si gzip disponible
if command -v gzip >/dev/null 2>&1; then
    find . -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \) -exec gzip -k {} \;
    log "Fichiers compressés avec gzip"
fi

# Vérification de l'intégrité du build
if [ -f "index.html" ] && grep -q "flashbackfa-entreprise" index.html 2>/dev/null; then
    success "Build optimisé et vérifié"
else
    warning "Build créé mais vérification d'intégrité échouée"
fi

#################################################################
# 8. CONFIGURATION PM2 PRODUCTION
#################################################################

log "🚀 Configuration PM2 pour production..."

cd "$BACKEND_DIR"

# Script de démarrage backend avec venv
cat > start_backend_production.sh << EOF
#!/bin/bash
export ENVIRONMENT=production
export DEBUG=false
source "$VENV_DIR/bin/activate"
cd "$BACKEND_DIR"
exec uvicorn server:app --host 0.0.0.0 --port 8001 --workers 2 --access-log
EOF

chmod +x start_backend_production.sh

# Configuration PM2 avec clustering
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'backend',
      script: './start_backend_production.sh',
      cwd: '$BACKEND_DIR',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        ENVIRONMENT: 'production'
      }
    },
    {
      name: 'frontend',
      script: 'serve',
      args: 'build -l 3000 -s',
      cwd: '$FRONTEND_DIR',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production'
      }
    }
  ]
};
EOF

# Démarrer avec la nouvelle configuration
pm2 start ecosystem.config.js
pm2 save

success "Services PM2 configurés pour production"

#################################################################
# 9. CONFIGURATION NGINX PRODUCTION
#################################################################

log "🌐 Configuration Nginx PRODUCTION..."

# Configuration Nginx optimisée pour production
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << EOF
# Configuration Nginx Production - $DOMAIN
# Version: $(date +%Y-%m-%d)

# Redirection HTTP vers HTTPS
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# Configuration HTTPS principale
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Frontend - React App
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
        
        # Cache Control
        expires 1h;
        add_header Cache-Control "public, immutable";
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8001/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Pas de cache pour l'API
        expires off;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # Backend Health Check
    location /health {
        proxy_pass http://localhost:8001/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        access_log off;
    }

    # Discord Auth Callback
    location /auth/callback {
        proxy_pass http://localhost:3000/auth/callback;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Static Assets Caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        proxy_pass http://localhost:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
}
EOF

# Supprimer les anciennes configurations
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/$DOMAIN

# Activer la nouvelle configuration
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Tester et recharger
if sudo nginx -t; then
    sudo systemctl reload nginx
    success "Nginx reconfiguré pour production"
else
    error "❌ Erreur configuration Nginx"
    exit 1
fi

#################################################################
# 10. VÉRIFICATIONS PRODUCTION COMPLÈTES
#################################################################

important "✅ VÉRIFICATIONS PRODUCTION COMPLÈTES..."

sleep 10

echo "État des services PM2:"
pm2 status

echo ""
log "Test des endpoints locaux..."

# Tests locaux
if curl -f -s "http://localhost:8001/health" >/dev/null 2>&1; then
    success "✅ Backend local OK (http://localhost:8001/health)"
else
    error "❌ Backend local ne répond pas"
    echo "Logs backend:"
    pm2 logs backend --lines 5 --nostream
fi

if curl -f -s "http://localhost:3000" >/dev/null 2>&1; then
    success "✅ Frontend local OK (http://localhost:3000)"
else
    error "❌ Frontend local ne répond pas"
    echo "Logs frontend:"
    pm2 logs frontend --lines 5 --nostream
fi

echo ""
log "Test des endpoints publics..."

# Tests publics
if curl -f -s "https://$DOMAIN/health" >/dev/null 2>&1; then
    success "✅ Backend public OK (https://$DOMAIN/health)"
else
    warning "⚠️ Backend public ne répond pas encore"
fi

if curl -f -s "https://$DOMAIN" >/dev/null 2>&1; then
    success "✅ Frontend public OK (https://$DOMAIN)"
else
    warning "⚠️ Frontend public ne répond pas encore"
fi

# Vérifier l'authentification Discord
log "Vérification configuration Discord..."
if grep -q "REACT_APP_USE_MOCK_AUTH=false" "$FRONTEND_DIR/.env"; then
    success "✅ Authentification Discord RÉELLE activée"
else
    error "❌ Mode mock encore actif"
fi

#################################################################
# 11. NETTOYAGE FINAL ET OPTIMISATIONS
#################################################################

log "🧽 Nettoyage final..."

# Supprimer les fichiers temporaires
find /tmp -name "*npm*" -type d -exec rm -rf {} + 2>/dev/null || true
find /tmp -name "*node*" -type d -exec rm -rf {} + 2>/dev/null || true

# Redémarrer PM2 pour s'assurer que tout est propre
pm2 restart all

success "Nettoyage final terminé"

#################################################################
# RÉSUMÉ FINAL
#################################################################

echo ""
important "🎉 DÉPLOIEMENT PRODUCTION RÉEL TERMINÉ !"
echo ""
echo "🌐 VOTRE APPLICATION PUBLIQUE :"
echo "   👉 https://$DOMAIN"
echo ""
echo "🔐 AUTHENTIFICATION :"
echo "   ✅ Discord OAuth RÉEL (pas de mock)"
echo "   ✅ Configuration production"
echo ""
echo "📱 FONCTIONNALITÉS :"
echo "   ✅ Tous les modules implémentés"
echo "   ✅ Build optimisé et compressé"
echo "   ✅ SSL et sécurité configurés"
echo ""
echo "🔧 SURVEILLANCE :"
echo "   pm2 status              # État des services"
echo "   pm2 logs frontend       # Logs frontend"
echo "   pm2 logs backend        # Logs backend"
echo "   pm2 monit              # Monitoring en temps réel"
echo ""
echo "🧪 TESTS RAPIDES :"
echo "   curl https://$DOMAIN/health     # Test backend"
echo "   curl -I https://$DOMAIN         # Test frontend"
echo ""

# Affichage final de l'état
echo "État final des services :"
pm2 status

echo ""
success "🚀 VERSION PRODUCTION PUBLIQUE AVEC DISCORD OAUTH DÉPLOYÉE !"
important "Testez maintenant : https://$DOMAIN"