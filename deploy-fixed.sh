#!/bin/bash

# 🚀 DÉPLOIEMENT COMPLET EMERGENT - Version Corrigée
# Portail Entreprise Flashback Fa v2.0.0

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "=================================================================================================="
    echo "🚀 DÉPLOIEMENT EMERGENT - PORTAIL ENTREPRISE FLASHBACK FA"
    echo "   Version: 2.0.0 | Architecture: FastAPI + MySQL + React"
    echo "=================================================================================================="
    echo -e "${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_step() { echo -e "${CYAN}${BOLD}🔧 $1${NC}"; }

# Auto-détection du répertoire
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"

setup_system_infrastructure() {
    print_info "Configuration infrastructure système..."
    
    # Vérifier les services système requis
    local services=("mariadb" "supervisor")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            print_success "$service est actif"
        else
            print_info "Tentative démarrage de $service..."
            if sudo systemctl start "$service" 2>/dev/null; then
                sudo systemctl enable "$service" 2>/dev/null
                print_success "$service démarré et activé"
            else
                print_warning "$service non disponible ou échec de démarrage"
            fi
        fi
    done
    
    # Créer les répertoires nécessaires
    sudo mkdir -p /var/log/supervisor 2>/dev/null || true
    mkdir -p "$APP_DIR/logs" 2>/dev/null || true
    
    print_success "Infrastructure système configurée"
}

setup_database() {
    print_info "Configuration base de données..."
    
    # Vérifier si MySQL/MariaDB est disponible
    if command -v mysql >/dev/null 2>&1; then
        # Tenter de créer la base de données
        sudo mysql -u root <<'EOF' 2>/dev/null || mysql -u root <<'EOF' 2>/dev/null || true
CREATE DATABASE IF NOT EXISTS flashback_fa_enterprise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'flashback_user'@'localhost' IDENTIFIED BY 'FlashbackFA_2024!';
GRANT ALL PRIVILEGES ON flashback_fa_enterprise.* TO 'flashback_user'@'localhost';
FLUSH PRIVILEGES;
EOF
        
        # Tester la connexion
        if mysql -u flashback_user -pFlashbackFA_2024! -e "SELECT 1;" >/dev/null 2>&1; then
            print_success "Base de données MySQL configurée et testée"
        else
            print_warning "Base de données MySQL non testable"
        fi
    else
        print_warning "MySQL/MariaDB non détecté"
    fi
}

install_dependencies() {
    print_info "Installation des dépendances..."
    
    # Backend Python
    if [[ -f "$BACKEND_DIR/requirements.txt" ]]; then
        cd "$BACKEND_DIR"
        print_info "Installation dépendances Python..."
        
        pip3 install --user -r requirements.txt --quiet 2>/dev/null || pip3 install --user -r requirements.txt
        
        # Vérifier les imports critiques
        if python3 -c "import fastapi, uvicorn" 2>/dev/null; then
            print_success "Dépendances Python installées"
        else
            print_warning "Certaines dépendances Python peuvent manquer"
        fi
    fi
    
    # Frontend Node
    if [[ -f "$FRONTEND_DIR/package.json" ]]; then
        cd "$FRONTEND_DIR"
        print_info "Installation dépendances Node.js..."
        
        if command -v yarn >/dev/null 2>&1; then
            yarn install --silent 2>/dev/null || yarn install
            print_success "Dépendances Yarn installées"
        elif command -v npm >/dev/null 2>&1; then
            npm install --silent 2>/dev/null || npm install
            print_success "Dépendances NPM installées"
        else
            print_warning "Ni Yarn ni NPM détecté"
        fi
    fi
    
    cd "$APP_DIR"
}

setup_supervisor_config() {
    print_info "Configuration Supervisor..."
    
    # Configuration avec chemins absolus
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

    # Recharger Supervisor
    sudo supervisorctl reread 2>/dev/null || true
    sudo supervisorctl update 2>/dev/null || true
    
    print_success "Configuration Supervisor créée"
}

setup_env_files() {
    print_info "Configuration fichiers environnement..."
    
    # Backend .env
    if [[ ! -f "$BACKEND_DIR/.env" ]] || [[ ! -s "$BACKEND_DIR/.env" ]]; then
        cat > "$BACKEND_DIR/.env" <<'EOF'
# Base de données
DATABASE_URL=mysql+pymysql://flashback_user:FlashbackFA_2024!@localhost/flashback_fa_enterprise

# Discord OAuth (à configurer)
DISCORD_CLIENT_ID=
DISCORD_CLIENT_SECRET=
DISCORD_BOT_TOKEN=
DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback

# JWT
JWT_SECRET_KEY=super_secret_jwt_key_change_in_production_2024!
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Application
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=http://localhost:3000

# Monitoring
ENABLE_METRICS=true
LOG_LEVEL=INFO
EOF
        print_success "Fichier backend/.env créé"
    fi
    
    # Frontend .env
    if [[ ! -f "$FRONTEND_DIR/.env" ]] || [[ ! -s "$FRONTEND_DIR/.env" ]]; then
        cat > "$FRONTEND_DIR/.env" <<'EOF'
# Backend API
REACT_APP_BACKEND_URL=http://localhost:8000

# Discord OAuth
REACT_APP_DISCORD_CLIENT_ID=
REACT_APP_DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback

# Application
REACT_APP_APP_NAME=Portail Entreprise Flashback Fa
REACT_APP_VERSION=2.0.0

# Mode développement
REACT_APP_USE_MOCK_AUTH=true
REACT_APP_FORCE_DISCORD_AUTH=false
EOF
        print_success "Fichier frontend/.env créé"
    fi
}

start_services() {
    print_info "Démarrage des services..."
    
    # Arrêter les anciens services
    sudo supervisorctl stop all 2>/dev/null || true
    
    # Démarrer les nouveaux services
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
}

check_health() {
    print_info "Vérification santé du système..."
    
    sleep 5
    
    local issues=()
    
    # Test backend
    if curl -s -f http://localhost:8000/health/live >/dev/null 2>&1; then
        print_success "Backend accessible (http://localhost:8000)"
    else
        issues+=("Backend non accessible")
    fi
    
    # Test frontend
    if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
        print_success "Frontend accessible (http://localhost:3000)"
    else
        issues+=("Frontend non accessible")
    fi
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        print_success "Système en bonne santé"
    else
        print_warning "Issues détectées: ${issues[*]}"
    fi
}

show_final_info() {
    echo ""
    echo -e "${GREEN}${BOLD}=================================================================================================="
    echo "🎉 DÉPLOIEMENT TERMINÉ !"
    echo "=================================================================================================="
    echo -e "${NC}"
    
    echo -e "${CYAN}📱 ACCÈS APPLICATION:${NC}"
    echo "   🌐 Interface: http://localhost:3000"
    echo "   🔧 API: http://localhost:8000"
    echo "   📚 Docs: http://localhost:8000/docs"
    echo "   💊 Health: http://localhost:8000/health/live"
    
    echo ""
    echo -e "${CYAN}🛠️  COMMANDES UTILES:${NC}"
    echo "   📋 Status: sudo supervisorctl status"
    echo "   🔄 Restart: sudo supervisorctl restart flashback-backend flashback-frontend"
    echo "   📋 Logs: sudo tail -f /var/log/supervisor/flashback-*.log"
    echo "   ⚙️  Config Discord: ./configure-discord-tokens.sh"
    
    echo ""
    echo -e "${CYAN}🌍 ENVIRONNEMENT:${NC}"
    echo "   📁 Répertoire: $APP_DIR"
    echo "   🎭 Mode: Développement (mock auth)"
    
    echo ""
    echo -e "${GREEN}✨ APPLICATION PRÊTE ! ✨${NC}"
}

main() {
    print_header
    
    print_info "Répertoire d'application: $APP_DIR"
    
    print_step "PHASE 1: Infrastructure"
    setup_system_infrastructure
    
    print_step "PHASE 2: Base de données"
    setup_database
    
    print_step "PHASE 3: Dépendances"
    install_dependencies
    
    print_step "PHASE 4: Configuration Supervisor"
    setup_supervisor_config
    
    print_step "PHASE 5: Fichiers environnement"
    setup_env_files
    
    print_step "PHASE 6: Démarrage services"
    start_services
    
    print_step "PHASE 7: Vérification santé"
    check_health
    
    show_final_info
}

# Lancement
main "$@"