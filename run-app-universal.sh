#!/bin/bash

# 🚀 Lanceur Universel - Portail Entreprise Flashback Fa
# Compatible avec tous les environnements (local, VPS, conteneur)

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Auto-détection de l'environnement
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"

print_header() {
    echo -e "${PURPLE}"
    echo "=================================================================================================="
    echo "🚀 LANCEUR UNIVERSEL - PORTAIL ENTREPRISE FLASHBACK FA v2.0.0"
    echo "   Environnement détecté automatiquement"
    echo "   Répertoire: $APP_DIR"
    echo "=================================================================================================="
    echo -e "${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Détection de l'environnement
detect_environment() {
    local env_type=""
    
    # Vérifier si on est dans un conteneur
    if [[ -f /.dockerenv ]]; then
        env_type="docker"
    # Vérifier si c'est un VPS/serveur avec systemd
    elif systemctl --version >/dev/null 2>&1; then
        env_type="vps"
    # Vérifier si c'est l'environnement Emergent
    elif [[ -d "/app" ]] && supervisorctl --version >/dev/null 2>&1; then
        env_type="emergent"
    else
        env_type="local"
    fi
    
    echo "$env_type"
}

# Démarrage adapté à l'environnement
start_services_by_environment() {
    local env=$(detect_environment)
    
    print_info "Environnement détecté: $env"
    
    case $env in
        "emergent"|"docker")
            start_with_supervisor
            ;;
        "vps")
            start_with_systemd_supervisor
            ;;
        "local")
            start_manually
            ;;
        *)
            print_warning "Environnement non reconnu, tentative démarrage manuel"
            start_manually
            ;;
    esac
}

# Démarrage avec Supervisor (Emergent/Docker)
start_with_supervisor() {
    print_info "Démarrage avec Supervisor (mode Emergent/Docker)"
    
    # Vérifier et redémarrer les services existants
    if supervisorctl status backend >/dev/null 2>&1; then
        sudo supervisorctl restart backend frontend
        print_success "Services Supervisor redémarrés"
    else
        print_warning "Services Supervisor non configurés, démarrage manuel"
        start_manually
        return
    fi
    
    sleep 3
    
    # Vérifier le statut
    sudo supervisorctl status | grep -E "(backend|frontend)"
}

# Démarrage avec Supervisor sur VPS
start_with_systemd_supervisor() {
    print_info "Démarrage avec Supervisor (mode VPS)"
    
    # S'assurer que supervisor est actif
    if ! systemctl is-active --quiet supervisor; then
        print_info "Démarrage de Supervisor..."
        sudo systemctl start supervisor
    fi
    
    # Vérifier si nos services existent
    if sudo supervisorctl status flashback-backend >/dev/null 2>&1; then
        sudo supervisorctl restart flashback-backend flashback-frontend
        print_success "Services flashback redémarrés"
    else
        print_warning "Services flashback non configurés, utilisation du déploiement complet"
        if [[ -f "$APP_DIR/deploy-vps-complete.sh" ]]; then
            "$APP_DIR/deploy-vps-complete.sh"
            return
        else
            start_manually
            return
        fi
    fi
    
    sleep 3
    
    # Vérifier le statut
    sudo supervisorctl status | grep -E "(flashback|backend|frontend)"
}

# Démarrage manuel (développement local)
start_manually() {
    print_info "Démarrage manuel (mode développement)"
    
    # Vérifier les dépendances
    check_dependencies
    
    print_info "Démarrage du backend..."
    cd "$BACKEND_DIR"
    if [[ -f "server.py" ]]; then
        python3 server.py &
        BACKEND_PID=$!
        echo "Backend PID: $BACKEND_PID"
        sleep 2
    else
        print_error "server.py non trouvé dans $BACKEND_DIR"
        return 1
    fi
    
    print_info "Démarrage du frontend..."
    cd "$FRONTEND_DIR"
    if [[ -f "package.json" ]]; then
        if command -v yarn >/dev/null 2>&1; then
            yarn start &
        else
            npm start &
        fi
        FRONTEND_PID=$!
        echo "Frontend PID: $FRONTEND_PID"
        sleep 2
    else
        print_error "package.json non trouvé dans $FRONTEND_DIR"
        return 1
    fi
    
    cd "$APP_DIR"
    
    print_success "Services démarrés manuellement"
    echo "Backend PID: $BACKEND_PID"
    echo "Frontend PID: $FRONTEND_PID"
    
    # Créer un fichier de PIDs pour l'arrêt
    echo "$BACKEND_PID $FRONTEND_PID" > .app_pids
}

# Vérification des dépendances
check_dependencies() {
    print_info "Vérification des dépendances..."
    
    # Backend Python
    if [[ -f "$BACKEND_DIR/requirements.txt" ]]; then
        cd "$BACKEND_DIR"
        if ! python3 -c "import fastapi, uvicorn, sqlalchemy" >/dev/null 2>&1; then
            print_info "Installation des dépendances Python..."
            pip3 install --user -r requirements.txt
        fi
        print_success "Dépendances Python OK"
    fi
    
    # Frontend Node
    if [[ -f "$FRONTEND_DIR/package.json" ]]; then
        cd "$FRONTEND_DIR"
        if [[ ! -d "node_modules" ]]; then
            print_info "Installation des dépendances Node.js..."
            if command -v yarn >/dev/null 2>&1; then
                yarn install
            else
                npm install
            fi
        fi
        print_success "Dépendances Node.js OK"
    fi
    
    cd "$APP_DIR"
}

# Test de connectivité
test_connectivity() {
    print_info "Test de connectivité..."
    
    local backend_ok=false
    local frontend_ok=false
    
    # Attendre que les services démarrent
    sleep 5
    
    # Test backend
    for i in {1..10}; do
        if curl -s -f http://localhost:8001/health >/dev/null 2>&1; then
            print_success "Backend accessible (http://localhost:8001)"
            backend_ok=true
            break
        fi
        sleep 1
    done
    
    # Test frontend
    for i in {1..10}; do
        if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
            print_success "Frontend accessible (http://localhost:3000)"
            frontend_ok=true
            break
        fi
        sleep 1
    done
    
    if ! $backend_ok; then
        print_warning "Backend non accessible après 10 tentatives"
    fi
    
    if ! $frontend_ok; then
        print_warning "Frontend non accessible après 10 tentatives"
    fi
    
    return $([ "$backend_ok" = true ] && [ "$frontend_ok" = true ] && echo 0 || echo 1)
}

# Afficher les informations d'accès
show_access_info() {
    echo ""
    echo -e "${GREEN}=================================================================================================="
    echo "🌟 APPLICATION PRÊTE !"
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
    
    local env=$(detect_environment)
    case $env in
        "emergent"|"docker")
            echo "📊 Monitoring (Supervisor):"
            echo "   📋 Status: sudo supervisorctl status"
            echo "   🔄 Redémarrer: sudo supervisorctl restart backend frontend"
            ;;
        "vps")
            echo "📊 Monitoring (VPS):"
            echo "   📋 Status: sudo supervisorctl status"
            echo "   🔄 Redémarrer: sudo supervisorctl restart flashback-backend flashback-frontend"
            ;;
        "local")
            echo "📊 Monitoring (Manuel):"
            echo "   🛑 Arrêter: kill \$(cat .app_pids) 2>/dev/null || true"
            echo "   🔄 Redémarrer: $0"
            ;;
    esac
    
    echo ""
    echo "🚀 Répertoire: $APP_DIR"
    echo "🌍 Environnement: $(detect_environment)"
}

# Fonction principale
main() {
    print_header
    
    # Vérifier la structure de l'application
    if [[ ! -d "$BACKEND_DIR" ]] || [[ ! -d "$FRONTEND_DIR" ]]; then
        print_error "Structure d'application invalide"
        echo "Répertoires requis:"
        echo "  - backend/ : $([ -d "$BACKEND_DIR" ] && echo "✅" || echo "❌")"
        echo "  - frontend/ : $([ -d "$FRONTEND_DIR" ] && echo "✅" || echo "❌")"
        exit 1
    fi
    
    # Démarrer selon l'environnement
    start_services_by_environment
    
    # Tester la connectivité
    if test_connectivity; then
        show_access_info
        print_success "🎉 Application démarrée avec succès ! 🚀"
    else
        print_warning "Application démarrée mais problèmes de connectivité détectés"
        show_access_info
        echo ""
        echo -e "${YELLOW}Dépannage:${NC}"
        echo "• Vérifiez les logs des services"
        echo "• Vérifiez que les ports 3000 et 8001 sont libres"
        echo "• Relancez le script après quelques minutes"
    fi
}

# Point d'entrée
main "$@"