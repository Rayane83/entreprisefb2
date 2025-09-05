#!/bin/bash

# 🚀 Script de démarrage pour Portail Entreprise Flashback Fa v2.0.0
# Vérifie la configuration et démarre l'application

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
    echo "🚀 PORTAIL ENTREPRISE FLASHBACK FA - DÉMARRAGE APPLICATION"
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
    local backend_env="/app/backend/.env"
    local frontend_env="/app/frontend/.env"
    
    if [[ ! -f "$backend_env" ]] || [[ ! -f "$frontend_env" ]]; then
        return 1
    fi
    
    # Vérifier si les tokens Discord sont configurés
    local client_id_backend=$(grep "^DISCORD_CLIENT_ID=" "$backend_env" | cut -d'=' -f2)
    local client_id_frontend=$(grep "^REACT_APP_DISCORD_CLIENT_ID=" "$frontend_env" | cut -d'=' -f2)
    
    if [[ -z "$client_id_backend" ]] || [[ -z "$client_id_frontend" ]]; then
        return 1
    fi
    
    return 0
}

# Vérifier les services
check_services() {
    local all_good=true
    
    # Vérifier MySQL/MariaDB
    if ! pgrep -x "mysqld\|mariadbd" > /dev/null; then
        print_error "Base de données MySQL/MariaDB non démarrée"
        all_good=false
    else
        print_success "Base de données active"
    fi
    
    # Vérifier le backend
    if ! curl -s http://localhost:8001/health > /dev/null 2>&1; then
        print_warning "Backend FastAPI non accessible sur le port 8001"
    else
        print_success "Backend FastAPI opérationnel"
    fi
    
    # Vérifier le frontend
    if ! curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_warning "Frontend React non accessible sur le port 3000"
    else
        print_success "Frontend React opérationnel"
    fi
    
    return 0
}

# Démarrer les services
start_services() {
    print_info "Démarrage des services..."
    
    # Démarrer MySQL si nécessaire
    if ! pgrep -x "mysqld\|mariadbd" > /dev/null; then
        print_info "Démarrage de la base de données..."
        service mariadb start
        sleep 2
    fi
    
    # Démarrer/redémarrer les services supervisord
    if command -v supervisorctl >/dev/null 2>&1; then
        print_info "Redémarrage des services avec supervisorctl..."
        sudo supervisorctl restart backend
        sudo supervisorctl restart frontend
        sleep 3
    else
        print_warning "supervisorctl non trouvé, démarrage manuel nécessaire"
        return 1
    fi
    
    return 0
}

# Afficher les informations d'accès
show_access_info() {
    echo ""
    echo -e "${GREEN}=================================================================================================="
    echo "🌟 APPLICATION DÉMARRÉE AVEC SUCCÈS !"
    echo "=================================================================================================="
    echo -e "${NC}"
    
    echo "📱 Accès à l'application:"
    echo "   🌐 Frontend: http://localhost:3000"
    echo "   🔧 API Backend: http://localhost:8001"
    echo "   📚 Documentation API: http://localhost:8001/docs"
    echo "   💊 Health Check: http://localhost:8001/health"
    echo ""
    
    echo "🔐 Authentification:"
    if check_discord_config; then
        echo "   ✅ Discord OAuth configuré et prêt"
        echo "   🔗 Testez la connexion sur http://localhost:3000"
    else
        echo "   ⚠️  Discord OAuth non configuré (mode mock actif)"
        echo "   🔧 Exécutez ./setup-discord.sh pour configurer Discord"
    fi
    echo ""
    
    echo "📊 Monitoring:"
    echo "   📋 Logs Backend: tail -f /var/log/supervisor/backend.*.log"
    echo "   📋 Logs Frontend: tail -f /var/log/supervisor/frontend.*.log"
    echo "   📈 Status Services: sudo supervisorctl status"
    echo ""
    
    echo "🛠️  Commandes utiles:"
    echo "   🔄 Redémarrer: sudo supervisorctl restart all"
    echo "   🛑 Arrêter: sudo supervisorctl stop all"
    echo "   ⚙️  Configurer Discord: ./setup-discord.sh"
    echo ""
}

# Script principal
main() {
    print_header
    
    echo -e "${BLUE}Vérification de la configuration...${NC}"
    echo ""
    
    # Vérifier la configuration Discord
    if ! check_discord_config; then
        print_warning "Configuration Discord OAuth manquante"
        echo ""
        echo -e "${YELLOW}Options disponibles:${NC}"
        echo "1. Configurer Discord OAuth maintenant (recommandé pour production)"
        echo "2. Continuer en mode mock (développement/test uniquement)"
        echo ""
        echo -n "Votre choix (1/2): "
        read -r choice
        
        case $choice in
            1)
                echo ""
                print_info "Lancement de la configuration Discord..."
                ./setup-discord.sh
                ;;
            2)
                echo ""
                print_info "Continuation en mode mock..."
                # S'assurer que le mode mock est activé
                sed -i 's/REACT_APP_USE_MOCK_AUTH=false/REACT_APP_USE_MOCK_AUTH=true/' /app/frontend/.env
                sed -i 's/REACT_APP_FORCE_DISCORD_AUTH=true/REACT_APP_FORCE_DISCORD_AUTH=false/' /app/frontend/.env
                ;;
            *)
                print_error "Choix invalide"
                exit 1
                ;;
        esac
    else
        print_success "Configuration Discord OAuth détectée"
    fi
    
    echo ""
    print_info "Vérification et démarrage des services..."
    
    # Démarrer les services
    if start_services; then
        sleep 5
        
        # Vérifier que tout fonctionne
        echo ""
        print_info "Vérification de l'état des services..."
        check_services
        
        # Afficher les informations d'accès
        show_access_info
        
        # Ouvrir automatiquement dans le navigateur (optionnel)
        echo -n "Voulez-vous ouvrir l'application dans votre navigateur ? (y/N): "
        read -r open_browser
        
        if [[ $open_browser =~ ^[Yy]$ ]]; then
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "http://localhost:3000" >/dev/null 2>&1 &
            elif command -v open >/dev/null 2>&1; then
                open "http://localhost:3000" >/dev/null 2>&1 &
            else
                print_info "Veuillez ouvrir manuellement http://localhost:3000 dans votre navigateur"
            fi
        fi
        
    else
        print_error "Erreur lors du démarrage des services"
        echo ""
        echo -e "${YELLOW}Dépannage:${NC}"
        echo "1. Vérifiez les logs: tail -f /var/log/supervisor/*.log"
        echo "2. Vérifiez supervisor: sudo supervisorctl status"
        echo "3. Redémarrez manuellement: sudo supervisorctl restart all"
        exit 1
    fi
}

# Vérifier si le script est exécuté depuis le bon répertoire
if [[ ! -f "setup-discord.sh" ]] || [[ ! -d "backend" ]] || [[ ! -d "frontend" ]]; then
    print_error "Ce script doit être exécuté depuis le répertoire racine de l'application (/app)"
    exit 1
fi

# Lancer le script principal
main "$@"