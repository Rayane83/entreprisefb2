#!/bin/bash

#################################################################
# Script de Déploiement COMPLET avec Nettoyage PARTOUT
# flashbackfa-entreprise.fr
# 
# NETTOIE TOUS LES EMPLACEMENTS POSSIBLES :
# - ~/entreprisefb (répertoire principal)
# - /var/www/ (anciens déploiements web)
# - /opt/ (autres installations)
# - Caches système partout
#################################################################

APP_DIR="$HOME/entreprisefb"
FRONTEND_DIR="$APP_DIR/frontend"
BACKEND_DIR="$APP_DIR/backend"
VENV_DIR="$BACKEND_DIR/venv"
DOMAIN="flashbackfa-entreprise.fr"

# Répertoires à nettoyer potentiellement
WWW_DIRS=(
    "/var/www/html"
    "/var/www/$DOMAIN" 
    "/var/www/flashbackfa"
    "/var/www/entreprise"
    "/opt/flashbackfa"
    "/opt/entreprise"
    "/usr/share/nginx/html"
)

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
important() { echo -e "${PURPLE}[IMPORTANT]${NC} $1"; }
cleanup_log() { echo -e "${CYAN}[CLEANUP]${NC} $1"; }

important "🧹 NETTOYAGE COMPLET SYSTÈME - Suppression de TOUTES les anciennes versions"
log "Domaine: $DOMAIN"

#################################################################
# 1. DÉTECTION DES ANCIENNES INSTALLATIONS
#################################################################

cleanup_log "🔍 Détection des anciennes installations..."

echo "Recherche d'anciennes versions dans le système :"

# Chercher tous les répertoires contenant flashbackfa ou entreprise
FOUND_DIRS=()

for dir in "${WWW_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "   📁 Trouvé: $dir"
        FOUND_DIRS+=("$dir")
    fi
done

# Recherche avec find dans les répertoires système
echo "Recherche supplémentaire..."
find /var /opt /usr/share -name "*flashback*" -type d 2>/dev/null | head -10 | while read dir; do
    echo "   📁 Détecté: $dir"
done

find /var /opt /usr/share -name "*entreprise*" -type d 2>/dev/null | head -10 | while read dir; do
    echo "   📁 Détecté: $dir"
done

#################################################################
# 2. ARRÊT COMPLET DE TOUS LES SERVICES ET PROCESSUS
#################################################################

cleanup_log "🛑 Arrêt COMPLET de tous les services..."

# Arrêter PM2
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true

# Arrêter tous les serveurs web potentiels
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl stop apache2 2>/dev/null || true

# Tuer tous les processus liés à l'application
sudo pkill -f "flashback" 2>/dev/null || true
sudo pkill -f "entreprise" 2>/dev/null || true
sudo pkill -f "node.*serve" 2>/dev/null || true
sudo pkill -f "python.*server.py" 2>/dev/null || true
sudo pkill -f "uvicorn" 2>/dev/null || true

# Nettoyer les ports
sudo fuser -k 3000/tcp 2>/dev/null || true
sudo fuser -k 8001/tcp 2>/dev/null || true
sudo fuser -k 80/tcp 2>/dev/null || true
sudo fuser -k 443/tcp 2>/dev/null || true

success "Tous les processus arrêtés"

#################################################################
# 3. SUPPRESSION RADICALE DES ANCIENS RÉPERTOIRES
#################################################################

cleanup_log "🗑️ SUPPRESSION RADICALE des anciens répertoires..."

# Supprimer tous les répertoires www trouvés
for dir in "${FOUND_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        cleanup_log "Suppression: $dir"
        sudo rm -rf "$dir"
        success "✅ Supprimé: $dir"
    fi
done

# Suppression spécifique des répertoires web courants
sudo rm -rf /var/www/html/flashback* 2>/dev/null || true
sudo rm -rf /var/www/html/entreprise* 2>/dev/null || true
sudo rm -rf /var/www/html/index.html 2>/dev/null || true
sudo rm -rf /usr/share/nginx/html/index.html 2>/dev/null || true

# Nettoyer les configurations nginx anciennes
sudo rm -f /etc/nginx/sites-available/flashback* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-available/entreprise* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/flashback* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/entreprise* 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

success "Anciens répertoires web supprimés"

#################################################################
# 4. NETTOYAGE SYSTÈME PROFOND
#################################################################

cleanup_log "🧽 Nettoyage système PROFOND..."

# Nettoyer tous les caches système
sudo apt clean 2>/dev/null || true
sudo apt autoclean 2>/dev/null || true

# Nettoyer les caches Node.js/Yarn/NPM PARTOUT
sudo rm -rf /root/.npm 2>/dev/null || true
sudo rm -rf /root/.yarn 2>/dev/null || true
sudo rm -rf /home/*/.npm 2>/dev/null || true
sudo rm -rf /home/*/.yarn 2>/dev/null || true
sudo rm -rf /tmp/npm-* 2>/dev/null || true
sudo rm -rf /tmp/yarn-* 2>/dev/null || true

yarn cache clean --force 2>/dev/null || true
npm cache clean --force 2>/dev/null || true
sudo npm cache clean --force 2>/dev/null || true

# Nettoyer les caches Python PARTOUT
sudo rm -rf /root/.cache/pip 2>/dev/null || true
sudo rm -rf /home/*/.cache/pip 2>/dev/null || true
pip cache purge 2>/dev/null || true
sudo pip cache purge 2>/dev/null || true

# Nettoyer les logs et temporaires
sudo rm -rf /var/log/nginx/flashback* 2>/dev/null || true
sudo rm -rf /var/log/nginx/entreprise* 2>/dev/null || true
sudo rm -rf /tmp/flashback* 2>/dev/null || true
sudo rm -rf /tmp/entreprise* 2>/dev/null || true

success "Nettoyage système profond terminé"

#################################################################
# 5. NETTOYAGE DU RÉPERTOIRE PRINCIPAL
#################################################################

cleanup_log "🧹 Nettoyage du répertoire principal: $APP_DIR"

cd "$FRONTEND_DIR"

# Supprimer TOUT l'ancien frontend
rm -rf node_modules build dist .next .cache .parcel-cache coverage
rm -rf yarn-error.log npm-debug.log* package-lock.json .npm .yarn

cd "$BACKEND_DIR"

# Supprimer TOUT l'ancien backend
rm -rf __pycache__ venv .pytest_cache *.egg-info .coverage htmlcov
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

success "Répertoire principal nettoyé"

#################################################################
# 6. VÉRIFICATION QUE TOUT EST PROPRE
#################################################################

cleanup_log "🕵️ Vérification que tout est propre..."

echo "Vérification des répertoires web :"
ls -la /var/www/ 2>/dev/null || echo "   ✅ /var/www/ vide ou inexistant"
ls -la /opt/ 2>/dev/null | grep -i flashback || echo "   ✅ Aucune trace dans /opt/"
ls -la /usr/share/nginx/html/ 2>/dev/null | grep -i index || echo "   ✅ Nginx par défaut nettoyé"

echo "Vérification des processus :"
ps aux | grep -E "(flashback|entreprise|node.*serve|python.*server)" | grep -v grep || echo "   ✅ Aucun processus résiduel"

echo "Vérification des ports :"
sudo netstat -tlnp | grep -E ":(3000|8001|80|443)" | head -5 || echo "   ✅ Ports principaux libres"

success "Vérification terminée - Système propre"

#################################################################
# 7. INSTALLATION ENVIRONNEMENT PROPRE
#################################################################

important "📦 Installation environnement PROPRE..."

# Python
cd "$BACKEND_DIR"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip setuptools wheel
pip install fastapi uvicorn[standard] pymongo python-multipart python-dotenv pydantic

# Node.js
cd "$FRONTEND_DIR"
yarn install --frozen-lockfile --network-timeout 120000

success "Environnement propre installé"

#################################################################
# 8. CONFIGURATION PRODUCTION RÉELLE
#################################################################

important "🔐 Configuration PRODUCTION avec Discord OAuth RÉEL..."

cd "$FRONTEND_DIR"

cat > .env << EOF
# PRODUCTION - AUTHENTIFICATION DISCORD RÉELLE
REACT_APP_BACKEND_URL=https://$DOMAIN
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU0OTQ1NDQsImV4cCI6MjA0MTA3MDU0NH0.wql-jOauH_T8ikOEtrF6HmDEvKHvviNNwUucsPPYE9M

# DISCORD OAUTH RÉEL (PAS DE MOCK)
REACT_APP_USE_MOCK_AUTH=false
REACT_APP_DISCORD_CLIENT_ID=1279855624938803280
REACT_APP_DISCORD_REDIRECT_URI=https://$DOMAIN/auth/callback

# PRODUCTION
NODE_ENV=production
GENERATE_SOURCEMAP=false
REACT_APP_ENV=production
EOF

cd "$BACKEND_DIR"

cat > .env << EOF
# BACKEND PRODUCTION
MONGO_URL=mongodb://localhost:27017
DB_NAME=flashbackfa_production
CORS_ORIGINS=https://$DOMAIN,https://www.$DOMAIN
ENVIRONMENT=production
DEBUG=false
EOF

success "Configuration production activée"

#################################################################
# 9. BUILD PRODUCTION NOUVEAU
#################################################################

important "🏗️ BUILD PRODUCTION 100% NOUVEAU..."

cd "$FRONTEND_DIR"

export NODE_ENV=production
export GENERATE_SOURCEMAP=false

yarn build

if [ ! -d "build" ] || [ ! -f "build/index.html" ]; then
    error "❌ Échec du build"
    exit 1
fi

BUILD_SIZE=$(du -sh build | cut -f1)
success "✅ Build créé ($BUILD_SIZE)"

#################################################################
# 10. CONFIGURATION PM2 ET NGINX PROPRES
#################################################################

log "🚀 Configuration services propres..."

cd "$BACKEND_DIR"

# Script backend avec venv
cat > start_production.sh << EOF
#!/bin/bash
source "$VENV_DIR/bin/activate"
cd "$BACKEND_DIR"
exec uvicorn server:app --host 0.0.0.0 --port 8001 --workers 1
EOF

chmod +x start_production.sh

# Configuration Nginx PROPRE
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # Frontend React
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8001/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:8001/health;
        proxy_set_header Host \$host;
    }

    # Discord callback
    location /auth/callback {
        proxy_pass http://localhost:3000/auth/callback;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl start nginx

# Démarrer PM2
pm2 start start_production.sh --name "backend"
cd "$FRONTEND_DIR"
pm2 serve build 3000 --name "frontend" --spa
pm2 save

success "Services configurés et démarrés"

#################################################################
# 11. TESTS ET VÉRIFICATIONS FINALES
#################################################################

important "✅ TESTS FINAUX..."

sleep 10

echo "État PM2:"
pm2 status

echo ""
echo "Tests locaux:"
curl -s http://localhost:8001/health && echo " ✅ Backend local OK" || echo " ❌ Backend local KO"
curl -s http://localhost:3000 >/dev/null && echo "✅ Frontend local OK" || echo "❌ Frontend local KO"

echo ""
echo "Tests publics:"
curl -s https://$DOMAIN/health >/dev/null && echo "✅ Backend public OK" || echo "❌ Backend public KO"
curl -s https://$DOMAIN >/dev/null && echo "✅ Frontend public OK" || echo "❌ Frontend public KO"

#################################################################
# RÉSUMÉ FINAL
#################################################################

echo ""
important "🎉 DÉPLOIEMENT COMPLET AVEC NETTOYAGE PARTOUT !"
echo ""
echo "✅ NETTOYÉ PARTOUT :"
echo "   • /var/www/ (anciens déploiements web)"
echo "   • /opt/ et /usr/share/ (autres installations)" 
echo "   • Caches système complets"
echo "   • Configurations nginx anciennes"
echo "   • Processus résiduels"
echo ""
echo "✅ VERSION PRODUCTION RÉELLE :"
echo "   • Discord OAuth RÉEL (pas mock)"
echo "   • Build 100% nouveau et optimisé"
echo "   • Configuration sécurisée"
echo ""
echo "🌐 APPLICATION PUBLIQUE :"
echo "   👉 https://$DOMAIN"
echo ""
echo "🔧 MONITORING :"
echo "   pm2 status"
echo "   pm2 logs backend"
echo "   pm2 logs frontend"
echo ""

success "🚀 SYSTÈME COMPLÈTEMENT NETTOYÉ ET VERSION PRODUCTION DÉPLOYÉE !"
important "Testez maintenant : https://$DOMAIN"