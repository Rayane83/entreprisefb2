#!/bin/bash

# 🚀 Script de lancement portable - Portail Entreprise Flashback Fa
# Fonctionne depuis n'importe quel répertoire

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Détecter le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"

print_header() {
    echo -e "${PURPLE}"
    echo "=================================================================================================="
    echo "🚀 LANCEMENT - PORTAIL ENTREPRISE FLASHBACK FA v2.0.0"
    echo "   Répertoire: $APP_DIR"
    echo "=================================================================================================="
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Vérifier la structure de l'application
check_app_structure() {
    if [[ ! -d "$BACKEND_DIR" ]] || [[ ! -d "$FRONTEND_DIR" ]]; then
        print_error "Structure d'application invalide"
        echo "Répertoires requis manquants dans: $APP_DIR"
        echo "  - backend/ : $([ -d "$BACKEND_DIR" ] && echo "✅" || echo "❌")"
        echo "  - frontend/ : $([ -d "$FRONTEND_DIR" ] && echo "✅" || echo "❌")"
        exit 1
    fi
    print_success "Structure d'application valide détectée"
}

# Vérifier les services
check_and_start_services() {
    print_info "Vérification et démarrage des services..."
    
    # Vérifier supervisor
    if ! command -v supervisorctl >/dev/null 2>&1; then
        print_warning "supervisorctl non trouvé, tentative de démarrage manuel..."
        return 1
    fi
    
    # Redémarrer les services
    print_info "Redémarrage des services avec supervisorctl..."
    if sudo supervisorctl restart backend frontend 2>/dev/null; then
        sleep 3
        print_success "Services redémarrés avec supervisorctl"
        
        # Vérifier le statut
        print_info "Statut des services:"
        sudo supervisorctl status | grep -E "(backend|frontend)"
        
        return 0
    else
        print_warning "Échec du redémarrage avec supervisorctl"
        return 1
    fi
}

# Vérifier la connectivité
test_connectivity() {
    print_info "Test de connectivité..."
    
    local backend_ok=false
    local frontend_ok=false
    
    # Test backend
    if curl -s -f http://localhost:8001/health >/dev/null 2>&1; then
        print_success "Backend accessible (http://localhost:8001)"
        backend_ok=true
    else
        print_warning "Backend non accessible (http://localhost:8001)"
    fi
    
    # Test frontend  
    if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
        print_success "Frontend accessible (http://localhost:3000)"
        frontend_ok=true
    else
        print_warning "Frontend non accessible (http://localhost:3000)"
    fi
    
    if $backend_ok && $frontend_ok; then
        return 0
    else
        return 1
    fi
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
    
    echo "📊 Monitoring:"
    echo "   📋 Status Services: sudo supervisorctl status"
    echo "   📋 Logs Backend: tail -f /var/log/supervisor/backend.*.log"
    echo "   📋 Logs Frontend: tail -f /var/log/supervisor/frontend.*.log"
    echo ""
    
    echo "🛠️  Utilitaires:"
    echo "   🔄 Redémarrer: sudo supervisorctl restart backend frontend"
    echo "   🛑 Arrêter: sudo supervisorctl stop backend frontend"
    echo ""
}

# Fonction principale
main() {
    print_header
    
    # Vérifications préliminaires
    check_app_structure
    
    # Démarrage des services
    if check_and_start_services; then
        # Test de connectivité
        sleep 2
        if test_connectivity; then
            show_access_info
            print_success "🎉 Application démarrée avec succès ! 🚀"
        else
            print_warning "Services démarrés mais problèmes de connectivité détectés"
            echo ""
            echo -e "${YELLOW}Dépannage:${NC}"
            echo "• Logs backend: tail -f /var/log/supervisor/backend.*.log"
            echo "• Logs frontend: tail -f /var/log/supervisor/frontend.*.log"
            echo "• Redémarrage: sudo supervisorctl restart backend frontend"
        fi
    else
        print_error "Impossible de démarrer les services avec supervisorctl"
        echo ""
        echo -e "${YELLOW}Solutions alternatives:${NC}"
        echo "1. Vérifier supervisor: sudo supervisorctl status"
        echo "2. Démarrage manuel backend: cd $BACKEND_DIR && python3 server.py"
        echo "3. Démarrage manuel frontend: cd $FRONTEND_DIR && yarn start"
    fi
    
    echo ""
    echo -e "${BLUE}Répertoire de l'application: $APP_DIR${NC}"
}

# Lancer l'application
main "$@"