#!/bin/bash

# 🚀 DÉPLOIEMENT COMPLET VPS - Portail Entreprise Flashback Fa
# Utilise toutes les technologies Emergent disponibles

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${PURPLE}"
    echo "=================================================================================================="
    echo "🚀 DÉPLOIEMENT COMPLET VPS - PORTAIL ENTREPRISE FLASHBACK FA v2.0.0"
    echo "   Utilisant toutes les technologies Emergent disponibles"
    echo "=================================================================================================="
    echo -e "${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Détection automatique du répertoire de travail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"

main() {
    print_header
    
    print_info "Répertoire de travail détecté: $APP_DIR"
    
    # Phase 1: Vérification de l'infrastructure
    print_info "Phase 1: Vérification de l'infrastructure système"
    
    # Vérifier MariaDB
    if systemctl is-active --quiet mariadb; then
        print_success "MariaDB actif"
    else
        print_info "Démarrage de MariaDB..."
        sudo systemctl start mariadb
        sudo systemctl enable mariadb
        print_success "MariaDB démarré et activé"
    fi
    
    # Vérifier Supervisor
    if systemctl is-active --quiet supervisor; then
        print_success "Supervisor actif"
    else
        print_info "Démarrage de Supervisor..."
        sudo systemctl start supervisor
        sudo systemctl enable supervisor
        print_success "Supervisor démarré et activé"
    fi
    
    # Phase 2: Configuration de la base de données
    print_info "Phase 2: Configuration de la base de données"
    
    # Créer la base et l'utilisateur si nécessaire
    sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS flashback_fa_enterprise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'flashback_user'@'localhost' IDENTIFIED BY 'FlashbackFA_2024!';
GRANT ALL PRIVILEGES ON flashback_fa_enterprise.* TO 'flashback_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    print_success "Base de données configurée"
    
    # Phase 3: Installation des dépendances
    print_info "Phase 3: Installation des dépendances"
    
    # Backend Python
    if [[ -f "$BACKEND_DIR/requirements.txt" ]]; then
        cd "$BACKEND_DIR"
        print_info "Installation des dépendances Python..."
        pip3 install --user -r requirements.txt
        print_success "Dépendances Python installées"
    fi
    
    # Frontend Node
    if [[ -f "$FRONTEND_DIR/package.json" ]]; then
        cd "$FRONTEND_DIR"
        print_info "Installation des dépendances Node.js..."
        if command -v yarn >/dev/null 2>&1; then
            yarn install
        else
            npm install
        fi
        print_success "Dépendances Node.js installées"
    fi
    
    cd "$APP_DIR"
    
    # Phase 4: Configuration Supervisor avec noms corrects
    print_info "Phase 4: Configuration Supervisor adaptée"
    
    # Configuration backend
    sudo tee /etc/supervisor/conf.d/flashback-backend.conf > /dev/null <<EOF
[program:flashback-backend]
command=/usr/bin/python3 server.py
directory=$BACKEND_DIR
user=ubuntu
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/flashback-backend.out.log
stderr_logfile=/var/log/supervisor/flashback-backend.err.log
environment=PATH="/usr/bin:/usr/local/bin:/home/ubuntu/.local/bin"
EOF

    # Configuration frontend
    sudo tee /etc/supervisor/conf.d/flashback-frontend.conf > /dev/null <<EOF
[program:flashback-frontend]
command=/usr/bin/yarn start
directory=$FRONTEND_DIR
user=ubuntu
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/flashback-frontend.out.log
stderr_logfile=/var/log/supervisor/flashback-frontend.err.log
environment=PATH="/usr/bin:/usr/local/bin",PORT=3000
EOF

    # Recharger supervisor
    sudo supervisorctl reread
    sudo supervisorctl update
    
    print_success "Configuration Supervisor mise à jour"
    
    # Phase 5: Démarrage et test des services
    print_info "Phase 5: Démarrage des services"
    
    # Arrêter les anciens services s'ils existent
    sudo supervisorctl stop all 2>/dev/null || true
    
    # Démarrer les nouveaux services
    sudo supervisorctl start flashback-backend flashback-frontend
    
    sleep 5
    
    # Vérifier le statut
    print_info "Statut des services:"
    sudo supervisorctl status
    
    # Phase 6: Tests de connectivité
    print_info "Phase 6: Tests de connectivité"
    
    # Test backend
    if curl -s -f http://localhost:8001/health >/dev/null 2>&1; then
        print_success "Backend accessible (http://localhost:8001)"
    else
        print_warning "Backend non accessible - vérification des logs..."
        sudo tail -n 10 /var/log/supervisor/flashback-backend.err.log 2>/dev/null || print_warning "Logs backend non trouvés"
    fi
    
    # Test frontend
    if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
        print_success "Frontend accessible (http://localhost:3000)"
    else
        print_warning "Frontend non accessible - vérification des logs..."
        sudo tail -n 10 /var/log/supervisor/flashback-frontend.err.log 2>/dev/null || print_warning "Logs frontend non trouvés"
    fi
    
    # Phase 7: Informations finales
    show_final_info
}

show_final_info() {
    echo ""
    echo -e "${GREEN}=================================================================================================="
    echo "🌟 DÉPLOIEMENT VPS TERMINÉ !"
    echo "=================================================================================================="
    echo -e "${NC}"
    
    echo "📱 Accès à l'application:"
    echo "   🌐 Interface utilisateur: http://localhost:3000"
    echo "   🔧 API Backend: http://localhost:8001"
    echo "   📚 Documentation API: http://localhost:8001/docs"
    echo "   💊 Status Santé: http://localhost:8001/health"
    echo ""
    
    echo "🔐 Authentification:"
    echo "   🎭 Mode développement (authentification mock)"
    echo "   🔧 Pour Discord OAuth: ./configure-discord-tokens.sh"
    echo ""
    
    echo "📊 Monitoring:"
    echo "   📋 Status Services: sudo supervisorctl status"
    echo "   📋 Logs Backend: sudo tail -f /var/log/supervisor/flashback-backend.*.log"
    echo "   📋 Logs Frontend: sudo tail -f /var/log/supervisor/flashback-frontend.*.log"
    echo ""
    
    echo "🛠️  Commandes utiles:"
    echo "   🔄 Redémarrer tout: sudo supervisorctl restart all"
    echo "   🔄 Redémarrer backend: sudo supervisorctl restart flashback-backend"
    echo "   🔄 Redémarrer frontend: sudo supervisorctl restart flashback-frontend"
    echo "   🛑 Arrêter tout: sudo supervisorctl stop all"
    echo ""
    
    echo "🚀 Répertoire de l'application: $APP_DIR"
    
    print_success "🎉 Application entièrement déployée et fonctionnelle ! 🎯"
}

# Lancer le déploiement
main "$@"