#!/bin/bash

# 🚀 Script de lancement rapide - Portail Entreprise Flashback Fa v2.0.0
# Vérifie la configuration Discord et lance l'application

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
    echo "🚀 LANCEMENT - PORTAIL ENTREPRISE FLASHBACK FA v2.0.0"
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

# Vérifier si Discord est configuré
check_discord_config() {
    local backend_env="$BACKEND_DIR/.env"
    local frontend_env="$FRONTEND_DIR/.env"
    
    if [[ ! -f "$backend_env" ]] || [[ ! -f "$frontend_env" ]]; then
        return 1
    fi
    
    # Vérifier si les Client IDs sont configurés
    local backend_client_id=$(grep "^DISCORD_CLIENT_ID=" "$backend_env" | cut -d'=' -f2)
    local frontend_client_id=$(grep "^REACT_APP_DISCORD_CLIENT_ID=" "$frontend_env" | cut -d'=' -f2)
    
    if [[ -z "$backend_client_id" ]] || [[ -z "$frontend_client_id" ]]; then
        return 1
    fi
    
    # Vérifier si ce sont de vrais IDs (pas vides)
    if [[ "$backend_client_id" =~ ^[0-9]{18,19}$ ]] && [[ "$frontend_client_id" =~ ^[0-9]{18,19}$ ]]; then
        return 0
    fi
    
    return 1
}

# Vérifier les services
check_services() {
    local all_services_ok=true
    
    # Vérifier MySQL/MariaDB
    if ! pgrep -x "mysqld\|mariadbd" > /dev/null; then
        print_warning "Base de données MySQL non démarrée"
        print_info "Démarrage de MariaDB..."
        service mariadb start
        sleep 2
    fi
    
    if pgrep -x "mysqld\|mariadbd" > /dev/null; then
        print_success "Base de données MySQL active"
    else
        print_error "Impossible de démarrer la base de données"
        all_services_ok=false
    fi
    
    # Vérifier/Démarrer les services avec supervisor
    if command -v supervisorctl >/dev/null 2>&1; then
        print_info "Redémarrage des services..."
        sudo supervisorctl restart backend frontend
        sleep 3
        
        # Vérifier le backend
        if curl -s http://localhost:8001/health > /dev/null 2>&1; then
            print_success "Backend FastAPI opérationnel (port 8001)"
        else
            print_warning "Backend non accessible, vérifiez les logs"
            all_services_ok=false
        fi
        
        # Vérifier le frontend
        if curl -s http://localhost:3000 > /dev/null 2>&1; then
            print_success "Frontend React opérationnel (port 3000)"
        else
            print_warning "Frontend non accessible, vérifiez les logs"
            all_services_ok=false
        fi
    else
        print_error "supervisorctl non trouvé"
        all_services_ok=false
    fi
    
    return $([ "$all_services_ok" = true ] && echo 0 || echo 1)
}

# Afficher les informations d'accès
show_app_info() {
    echo ""
    echo -e "${GREEN}=================================================================================================="
    echo "🌟 APPLICATION DÉMARRÉE AVEC SUCCÈS !"
    echo "=================================================================================================="
    echo -e "${NC}"
    
    echo "📱 Accès à l'application:"
    echo "   🌐 Application: http://localhost:3000"
    echo "   🔧 API Backend: http://localhost:8001"
    echo "   📚 Documentation API: http://localhost:8001/docs"
    echo "   💊 Status Santé: http://localhost:8001/health"
    echo ""
    
    if check_discord_config; then
        echo "🔐 Authentification:"
        echo "   ✅ Discord OAuth configuré et actif"
        echo "   🔗 Connectez-vous via Discord sur l'interface"
    else
        echo "🔐 Authentification:"
        echo "   ⚠️  Mode développement (authentification mock)"
        echo "   🔧 Pour configurer Discord: ./configure-discord-tokens.sh"
    fi
    
    echo ""
    echo "📊 Monitoring:"
    echo "   📋 Logs Backend: tail -f /var/log/supervisor/backend.*.log"
    echo "   📋 Logs Frontend: tail -f /var/log/supervisor/frontend.*.log"
    echo "   📈 Status Services: sudo supervisorctl status"
    echo ""
    
    echo "🛠️  Utilitaires:"
    echo "   🔄 Redémarrer: sudo supervisorctl restart all"
    echo "   🛑 Arrêter: sudo supervisorctl stop all"
    echo "   ⚙️  Config Discord: ./configure-discord-tokens.sh"
    echo ""
}

main() {
    print_header
    
    print_info "Vérification de la configuration..."
    
    # Vérifier la configuration Discord
    if check_discord_config; then
        print_success "Configuration Discord OAuth détectée"
        echo "   🔑 Authentification Discord activée"
    else
        echo ""
        print_warning "Aucune configuration Discord OAuth trouvée"
        echo ""
        echo -e "${YELLOW}Options:${NC}"
        echo "1. 🔧 Configurer Discord OAuth maintenant (production)"
        echo "2. 🎭 Continuer en mode développement (mock auth)"
        echo ""
        
        while true; do
            echo -n "Votre choix [1/2]: "
            read -r choice
            
            case $choice in
                1)
                    echo ""
                    print_info "Lancement de la configuration Discord..."
                    ./configure-discord-tokens.sh
                    break
                    ;;
                2)
                    echo ""
                    print_info "Mode développement activé"
                    # S'assurer que le mode mock est bien activé
                    if [[ -f "/app/frontend/.env" ]]; then
                        sed -i 's/REACT_APP_USE_MOCK_AUTH=false/REACT_APP_USE_MOCK_AUTH=true/' /app/frontend/.env
                        sed -i 's/REACT_APP_FORCE_DISCORD_AUTH=true/REACT_APP_FORCE_DISCORD_AUTH=false/' /app/frontend/.env
                    fi
                    break
                    ;;
                *)
                    print_error "Choix invalide. Tapez 1 ou 2."
                    ;;
            esac
        done
    fi
    
    echo ""
    print_info "Démarrage des services..."
    
    if check_services; then
        show_app_info
        
        # Proposer d'ouvrir le navigateur
        echo -n "Ouvrir l'application dans votre navigateur ? [y/N]: "
        read -r open_browser
        
        if [[ $open_browser =~ ^[Yy]$ ]]; then
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "http://localhost:3000" >/dev/null 2>&1 &
                print_success "Navigateur ouvert"
            elif command -v open >/dev/null 2>&1; then
                open "http://localhost:3000" >/dev/null 2>&1 &
                print_success "Navigateur ouvert"
            else
                print_info "Ouvrez manuellement: http://localhost:3000"
            fi
        fi
        
        echo ""
        echo -e "${GREEN}🎉 Application prête ! Bon développement ! 🚀${NC}"
        
    else
        echo ""
        print_error "Problème lors du démarrage des services"
        echo ""
        echo -e "${YELLOW}Dépannage:${NC}"
        echo "• Logs backend: tail -f /var/log/supervisor/backend.*.log"
        echo "• Logs frontend: tail -f /var/log/supervisor/frontend.*.log"
        echo "• Status services: sudo supervisorctl status"
        echo "• Redémarrage: sudo supervisorctl restart all"
        echo ""
        exit 1
    fi
}

# Détecter le répertoire de l'application automatiquement
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Vérifier qu'on est dans un répertoire d'application valide
if [[ ! -d "$SCRIPT_DIR/backend" ]] || [[ ! -d "$SCRIPT_DIR/frontend" ]]; then
    echo -e "${RED}❌ Ce script doit être exécuté depuis le répertoire racine de l'application${NC}"
    echo -e "${RED}   Répertoires backend/ et frontend/ introuvables dans: $SCRIPT_DIR${NC}"
    exit 1
fi

# Définir les chemins dynamiquement
APP_DIR="$SCRIPT_DIR"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"

# Lancer l'application
main "$@"