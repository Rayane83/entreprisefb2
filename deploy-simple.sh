#!/bin/bash

# 🚀 SCRIPT DE DÉPLOIEMENT SIMPLE - Version sans erreurs
# Portail Entreprise Flashback Fa

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Auto-détection répertoire
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"

echo -e "${BLUE}🚀 DÉPLOIEMENT SIMPLE - PORTAIL ENTREPRISE FLASHBACK FA${NC}"
echo "Répertoire: $APP_DIR"
echo ""

# 1. Configuration base de données
print_info "Configuration base de données..."
if command -v mysql >/dev/null 2>&1; then
    sudo mysql -u root 2>/dev/null <<'EOF' || mysql -u root 2>/dev/null <<'EOF' || true
CREATE DATABASE IF NOT EXISTS flashback_fa_enterprise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'flashback_user'@'localhost' IDENTIFIED BY 'FlashbackFA_2024!';
GRANT ALL PRIVILEGES ON flashback_fa_enterprise.* TO 'flashback_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    print_success "Base de données configurée"
else
    print_warning "MySQL non disponible"
fi

# 2. Installation dépendances Backend
if [[ -f "$BACKEND_DIR/requirements.txt" ]]; then
    print_info "Installation dépendances Python..."
    cd "$BACKEND_DIR"
    pip3 install --user -r requirements.txt --quiet 2>/dev/null || pip3 install --user -r requirements.txt
    print_success "Dépendances Python installées"
fi

# 3. Installation dépendances Frontend
if [[ -f "$FRONTEND_DIR/package.json" ]]; then
    print_info "Installation dépendances Node.js..."
    cd "$FRONTEND_DIR"
    if command -v yarn >/dev/null 2>&1; then
        yarn install --silent 2>/dev/null || yarn install
    elif command -v npm >/dev/null 2>&1; then
        npm install --silent 2>/dev/null || npm install
    fi
    print_success "Dépendances Node.js installées"
fi

cd "$APP_DIR"

# 4. Création fichiers .env
print_info "Création fichiers .env..."

# Backend .env
cat > "$BACKEND_DIR/.env" <<'EOF'
DATABASE_URL=mysql+pymysql://flashback_user:FlashbackFA_2024!@localhost/flashback_fa_enterprise
DISCORD_CLIENT_ID=
DISCORD_CLIENT_SECRET=
DISCORD_BOT_TOKEN=
DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback
JWT_SECRET_KEY=super_secret_jwt_key_change_in_production_2024!
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=http://localhost:3000
ENABLE_METRICS=true
LOG_LEVEL=INFO
EOF

# Frontend .env
cat > "$FRONTEND_DIR/.env" <<'EOF'
REACT_APP_BACKEND_URL=http://localhost:8000
REACT_APP_DISCORD_CLIENT_ID=
REACT_APP_DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback
REACT_APP_APP_NAME=Portail Entreprise Flashback Fa
REACT_APP_VERSION=2.0.0
REACT_APP_USE_MOCK_AUTH=true
REACT_APP_FORCE_DISCORD_AUTH=false
EOF

print_success "Fichiers .env créés"

# 5. Configuration Supervisor
print_info "Configuration Supervisor..."
sudo mkdir -p /var/log/supervisor 2>/dev/null || true

sudo tee /etc/supervisor/conf.d/flashback-app.conf > /dev/null <<EOF
[program:flashback-backend]
command=/usr/bin/python3 server.py
directory=$BACKEND_DIR
user=$(whoami)
autostart=true
autorestart=true
startretries=3
redirect_stderr=true
stdout_logfile=/var/log/supervisor/flashback-backend.out.log
stderr_logfile=/var/log/supervisor/flashback-backend.err.log
environment=PYTHONPATH="$BACKEND_DIR",PYTHONUNBUFFERED="1",PATH="/usr/bin:/usr/local/bin:/home/$(whoami)/.local/bin"
stopwaitsecs=30

[program:flashback-frontend]
command=/usr/bin/yarn start
directory=$FRONTEND_DIR
user=$(whoami)
autostart=true
autorestart=true
startretries=3
redirect_stderr=true
stdout_logfile=/var/log/supervisor/flashback-frontend.out.log
stderr_logfile=/var/log/supervisor/flashback-frontend.err.log
environment=PATH="/usr/bin:/usr/local/bin",PORT="3000"
stopwaitsecs=30

[group:flashback-stack]
programs=flashback-backend,flashback-frontend
priority=999
EOF

sudo supervisorctl reread 2>/dev/null || true
sudo supervisorctl update 2>/dev/null || true
print_success "Configuration Supervisor créée"

# 6. Démarrage services
print_info "Démarrage des services..."
sudo supervisorctl stop all 2>/dev/null || true

if sudo supervisorctl start flashback-backend flashback-frontend 2>/dev/null; then
    print_success "Services Supervisor démarrés"
else
    print_warning "Échec Supervisor - démarrage manuel"
    
    # Démarrage manuel
    cd "$BACKEND_DIR"
    python3 server.py &
    BACKEND_PID=$!
    echo "$BACKEND_PID" > "$APP_DIR/.backend_pid"
    print_info "Backend démarré manuellement (PID: $BACKEND_PID)"
    
    cd "$FRONTEND_DIR"
    if command -v yarn >/dev/null 2>&1; then
        yarn start &
    else
        npm start &
    fi
    FRONTEND_PID=$!
    echo "$FRONTEND_PID" > "$APP_DIR/.frontend_pid"
    print_info "Frontend démarré manuellement (PID: $FRONTEND_PID)"
    
    cd "$APP_DIR"
fi

# 7. Vérification santé
print_info "Vérification santé du système..."
sleep 5

if curl -s -f http://localhost:8000/health/live >/dev/null 2>&1; then
    print_success "Backend accessible (http://localhost:8000)"
else
    print_warning "Backend non accessible"
fi

if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
    print_success "Frontend accessible (http://localhost:3000)"
else
    print_warning "Frontend non accessible"
fi

# 8. Rapport final
echo ""
echo -e "${GREEN}🎉 DÉPLOIEMENT TERMINÉ !${NC}"
echo ""
echo -e "${BLUE}📱 ACCÈS APPLICATION:${NC}"
echo "   🌐 Interface: http://localhost:3000"
echo "   🔧 API: http://localhost:8000"
echo "   📚 Documentation: http://localhost:8000/docs"
echo "   💊 Health Check: http://localhost:8000/health/live"
echo ""
echo -e "${BLUE}🛠️  COMMANDES UTILES:${NC}"
echo "   📋 Status: sudo supervisorctl status"
echo "   🔄 Restart: sudo supervisorctl restart flashback-backend flashback-frontend"
echo "   📋 Logs Backend: sudo tail -f /var/log/supervisor/flashback-backend.out.log"
echo "   📋 Logs Frontend: sudo tail -f /var/log/supervisor/flashback-frontend.out.log"
echo "   ⚙️  Config Discord: ./configure-discord-tokens.sh"
echo ""
echo -e "${GREEN}✨ APPLICATION PRÊTE ! ✨${NC}"
echo "Mode: Développement avec authentification simulée"
echo "Répertoire: $APP_DIR"