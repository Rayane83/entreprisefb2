#!/bin/bash

#################################################################
# Script de Correction VPS - flashbackfa-entreprise.fr
# 
# Corrige les problèmes Python et backend
#################################################################

APP_DIR="$HOME/entreprisefb"
BACKEND_DIR="$APP_DIR/backend"
VENV_DIR="$BACKEND_DIR/venv"
DOMAIN="flashbackfa-entreprise.fr"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

log "🔧 Correction des problèmes backend..."

#################################################################
# 1. ARRÊTER LE BACKEND DÉFAILLANT
#################################################################

log "🛑 Arrêt du backend défaillant..."
pm2 stop backend 2>/dev/null || true
pm2 delete backend 2>/dev/null || true
success "Backend arrêté"

#################################################################
# 2. CONFIGURATION ENVIRONNEMENT VIRTUEL PYTHON
#################################################################

log "🐍 Configuration environnement virtuel Python..."

cd "$BACKEND_DIR"

# Supprimer l'ancien environnement virtuel s'il existe
if [ -d "$VENV_DIR" ]; then
    rm -rf "$VENV_DIR"
fi

# Créer un nouvel environnement virtuel
python3 -m venv "$VENV_DIR"

# Activer l'environnement virtuel
source "$VENV_DIR/bin/activate"

# Mettre à jour pip dans le venv
pip install --upgrade pip

success "Environnement virtuel créé"

#################################################################
# 3. INSTALLATION DES DÉPENDANCES PYTHON
#################################################################

log "📦 Installation des dépendances backend..."

# Installer les dépendances dans le venv
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    # Installer les dépendances essentielles manuellement
    pip install fastapi uvicorn pymongo python-multipart python-dotenv
fi

success "Dépendances Python installées"

#################################################################
# 4. CORRECTION DU BACKEND SERVER
#################################################################

log "🔧 Vérification de la configuration backend..."

# Vérifier/créer le fichier .env backend
if [ ! -f ".env" ]; then
    cat > .env << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=flashbackfa_db
CORS_ORIGINS=*
EOF
    log "Fichier .env backend créé"
fi

# Vérifier que le server.py existe
if [ ! -f "server.py" ]; then
    error "❌ Fichier server.py manquant !"
    exit 1
fi

success "Configuration backend vérifiée"

#################################################################
# 5. TEST DU BACKEND
#################################################################

log "🧪 Test du backend..."

# Test rapide du backend
cd "$BACKEND_DIR"
source "$VENV_DIR/bin/activate"

# Démarrer le backend en arrière-plan pour test
timeout 10s python server.py &
BACKEND_PID=$!

sleep 3

# Tester si le backend répond
if curl -f -s "http://localhost:8001/health" >/dev/null 2>&1; then
    success "✅ Backend fonctionne correctement"
    BACKEND_WORKS=true
else
    warning "⚠️ Backend ne répond pas sur le port 8001"
    BACKEND_WORKS=false
fi

# Arrêter le test backend
kill $BACKEND_PID 2>/dev/null || true
wait $BACKEND_PID 2>/dev/null || true

#################################################################
# 6. CONFIGURATION PM2 AVEC VENV
#################################################################

log "🚀 Configuration PM2 avec environnement virtuel..."

cd "$BACKEND_DIR"

# Créer un script de démarrage qui active le venv
cat > start_backend.sh << EOF
#!/bin/bash
source "$VENV_DIR/bin/activate"
cd "$BACKEND_DIR"
python server.py
EOF

chmod +x start_backend.sh

# Redémarrer le backend avec le nouveau script
pm2 start start_backend.sh --name "backend"

success "Backend redémarré avec venv"

#################################################################
# 7. CORRECTION NGINX
#################################################################

log "🌐 Correction configuration Nginx..."

# Supprimer les anciennes configurations conflictuelles
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/flashbackfa-entreprise.fr

# Créer une nouvelle configuration propre
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # Frontend (React build)
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Handle client-side routing
        try_files \$uri \$uri/ @fallback;
    }

    location @fallback {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8001/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Backend health check
    location /health {
        proxy_pass http://localhost:8001/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Activer la nouvelle configuration
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Tester et recharger nginx
if sudo nginx -t; then
    sudo systemctl reload nginx
    success "Nginx reconfiguré"
else
    error "❌ Erreur configuration Nginx"
fi

#################################################################
# 8. VÉRIFICATIONS FINALES
#################################################################

log "✅ Vérifications finales..."

sleep 5

# Vérifier l'état des services
echo "État des services PM2:"
pm2 status

echo ""

# Tester les endpoints
if curl -f -s "http://localhost:8001/health" >/dev/null 2>&1; then
    success "✅ Backend local OK (port 8001)"
else
    error "❌ Backend local ne répond pas"
    log "Logs backend:"
    pm2 logs backend --lines 10 --nostream
fi

if curl -f -s "http://localhost:3000" >/dev/null 2>&1; then
    success "✅ Frontend local OK (port 3000)"
else
    warning "⚠️ Frontend local ne répond pas"
fi

if curl -f -s "https://$DOMAIN/health" >/dev/null 2>&1; then
    success "✅ Backend public OK (https://$DOMAIN/health)"
else
    warning "⚠️ Backend public ne répond pas"
fi

if curl -f -s "https://$DOMAIN" >/dev/null 2>&1; then
    success "✅ Frontend public OK (https://$DOMAIN)"
else
    warning "⚠️ Frontend public ne répond pas"
fi

#################################################################
# RÉSUMÉ
#################################################################

echo ""
success "🎉 Correction terminée !"
echo ""
echo "🌐 Testez votre application:"
echo "   👉 https://$DOMAIN"
echo ""
echo "🔧 Commandes de diagnostic:"
echo "   pm2 status              # État des services"
echo "   pm2 logs backend        # Logs backend détaillés"
echo "   pm2 logs frontend       # Logs frontend"
echo "   sudo nginx -t           # Test configuration Nginx"
echo ""

if [ "$BACKEND_WORKS" = true ]; then
    success "✅ Backend corrigé et fonctionnel !"
else
    warning "⚠️ Backend nécessite encore des ajustements"
    echo "Consultez les logs: pm2 logs backend"
fi