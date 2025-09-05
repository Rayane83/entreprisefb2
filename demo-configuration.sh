#!/bin/bash

# 🎬 Script de démonstration - Configuration Discord OAuth
# Montre comment utiliser les nouveaux scripts de configuration

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_demo_header() {
    clear
    echo -e "${PURPLE}"
    echo "=================================================================================================="
    echo "🎬 DÉMONSTRATION - CONFIGURATION SÉCURISÉE DISCORD OAUTH"
    echo "=================================================================================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[ÉTAPE $1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

demo_configuration() {
    print_demo_header
    
    echo -e "${YELLOW}Cette démonstration vous montre les nouvelles fonctionnalités de sécurité${NC}"
    echo -e "${YELLOW}pour la configuration des tokens Discord OAuth dans l'application.${NC}"
    echo ""
    
    print_step "1" "Vérification de l'état actuel"
    
    # Vérifier l'état des fichiers .env
    if [[ -f "/app/backend/.env" ]] && [[ -f "/app/frontend/.env" ]]; then
        print_success "Fichiers .env trouvés"
        
        # Vérifier s'ils sont configurés
        backend_client_id=$(grep "^DISCORD_CLIENT_ID=" /app/backend/.env | cut -d'=' -f2)
        if [[ -z "$backend_client_id" ]]; then
            print_info "Configuration Discord: Non configurée (sécurisé)"
        else
            print_info "Configuration Discord: Déjà configurée"
        fi
    else
        echo -e "${RED}❌ Fichiers .env manquants${NC}"
        return 1
    fi
    
    echo ""
    print_step "2" "Fonctionnalités de sécurité implémentées"
    
    echo "🔒 **Sécurité des tokens :**"
    echo "   • Saisie masquée pour les secrets Discord"
    echo "   • Validation automatique des formats"
    echo "   • Sauvegarde automatique des fichiers .env"
    echo "   • Génération automatique de clés JWT sécurisées"
    echo ""
    
    echo "✅ **Validation automatique :**"
    echo "   • Client ID: Format 18-19 chiffres"
    echo "   • Client Secret: Minimum 20 caractères"
    echo "   • Bot Token: Validation optionnelle"
    echo ""
    
    echo "🛡️ **Protection des données :**"
    echo "   • Pas de tokens en dur dans le code"
    echo "   • Configuration demandée à l'utilisateur"
    echo "   • Fichiers .env exclus du contrôle de version"
    echo ""
    
    print_step "3" "Scripts disponibles"
    
    echo "🚀 **./run-app.sh** - Lancement intelligent:"
    echo "   • Détecte automatiquement la configuration Discord"
    echo "   • Propose la configuration si manquante"
    echo "   • Démarre tous les services automatiquement"
    echo "   • Mode développement avec authentification mock"
    echo ""
    
    echo "🔧 **./configure-discord-tokens.sh** - Configuration sécurisée:"
    echo "   • Guide étape par étape pour Discord Developer Portal"
    echo "   • Validation en temps réel des tokens"
    echo "   • Sauvegarde automatique des configurations"
    echo "   • Activation automatique du mode production"
    echo ""
    
    print_step "4" "Avantages de la nouvelle approche"
    
    echo "🔐 **Sécurité renforcée :**"
    echo "   ✅ Aucun token en dur dans le code source"
    echo "   ✅ Configuration demandée de manière sécurisée"
    echo "   ✅ Validation automatique des formats"
    echo "   ✅ Sauvegardes automatiques avec timestamp"
    echo ""
    
    echo "🚀 **Facilité d'utilisation :**"
    echo "   ✅ Un seul script pour tout configurer"
    echo "   ✅ Guide intégré pour Discord Developer Portal"
    echo "   ✅ Lancement intelligent de l'application"
    echo "   ✅ Mode développement et production"
    echo ""
    
    echo "🛠️ **Maintenance simplifiée :**"
    echo "   ✅ Scripts réutilisables et documentés"
    echo "   ✅ Gestion d'erreurs complète"
    echo "   ✅ Logs et monitoring intégrés"
    echo "   ✅ Compatibilité avec tous les environnements"
    echo ""
    
    print_step "5" "Démonstration pratique"
    
    echo ""
    echo -e "${BLUE}Voulez-vous voir une démonstration des scripts ? (simulation)${NC}"
    echo "1. Simulation de configuration Discord"
    echo "2. Simulation de lancement d'application"
    echo "3. Passer à l'utilisation réelle"
    echo ""
    
    while true; do
        echo -n "Votre choix [1/2/3]: "
        read -r demo_choice
        
        case $demo_choice in
            1)
                echo ""
                print_info "=== SIMULATION CONFIGURATION DISCORD ==="
                echo ""
                echo "$ ./configure-discord-tokens.sh"
                echo ""
                echo "🔐 CONFIGURATION DISCORD OAUTH - PORTAIL ENTREPRISE FLASHBACK FA"
                echo "Ce script configure votre application avec les tokens Discord OAuth."
                echo ""
                echo "📋 GUIDE CRÉATION APPLICATION DISCORD"
                echo "1. 🌐 Rendez-vous sur: https://discord.com/developers/applications"
                echo "2. 🆕 Créer une nouvelle application..."
                echo ""
                echo "🔑 DISCORD CLIENT ID"
                echo "Entrez votre Discord Client ID: [SAISIE UTILISATEUR]"
                echo "✅ Client ID valide: 123456789012345678"
                echo ""
                echo "🔐 DISCORD CLIENT SECRET"
                echo "Entrez votre Discord Client Secret: [SAISIE MASQUÉE]"
                echo "✅ Client Secret valide (32 caractères)"
                echo ""
                echo "🎉 CONFIGURATION TERMINÉE !"
                echo "✅ Backend configuré"
                echo "✅ Frontend configuré"
                echo "✅ Mode authentification Discord activé"
                echo ""
                break
                ;;
            2)
                echo ""
                print_info "=== SIMULATION LANCEMENT APPLICATION ==="
                echo ""
                echo "$ ./run-app.sh"
                echo ""
                echo "🚀 LANCEMENT - PORTAIL ENTREPRISE FLASHBACK FA v2.0.0"
                echo "ℹ️  Vérification de la configuration..."
                echo "✅ Configuration Discord OAuth détectée"
                echo "ℹ️  Démarrage des services..."
                echo "✅ Base de données MySQL active"
                echo "✅ Backend FastAPI opérationnel (port 8001)"
                echo "✅ Frontend React opérationnel (port 3000)"
                echo ""
                echo "🌟 APPLICATION DÉMARRÉE AVEC SUCCÈS !"
                echo "📱 Application: http://localhost:3000"
                echo "🔧 API Backend: http://localhost:8001"
                echo "🔐 Discord OAuth configuré et actif"
                echo ""
                break
                ;;
            3)
                echo ""
                print_info "Prêt pour l'utilisation réelle !"
                break
                ;;
            *)
                echo -e "${RED}Choix invalide. Tapez 1, 2 ou 3.${NC}"
                ;;
        esac
    done
    
    echo ""
    print_step "6" "Utilisation réelle"
    
    echo -e "${GREEN}🎉 La démonstration est terminée !${NC}"
    echo ""
    echo -e "${YELLOW}Pour utiliser l'application en mode production :${NC}"
    echo ""
    echo "1. **Configuration Discord :**"
    echo "   ./configure-discord-tokens.sh"
    echo ""
    echo "2. **Lancement de l'application :**"
    echo "   ./run-app.sh"
    echo ""
    echo "3. **Accès à l'application :**"
    echo "   http://localhost:3000"
    echo ""
    
    echo -e "${BLUE}Voulez-vous lancer la configuration réelle maintenant ? [y/N]:${NC}"
    read -r launch_real
    
    if [[ $launch_real =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Lancement de la configuration réelle..."
        exec ./run-app.sh
    else
        echo ""
        echo -e "${PURPLE}Démonstration terminée ! Les scripts sont prêts à être utilisés.${NC}"
    fi
}

# Vérifier qu'on est dans le bon répertoire
if [[ ! -f "./run-app.sh" ]] || [[ ! -f "./configure-discord-tokens.sh" ]]; then
    echo -e "${RED}❌ Ce script doit être exécuté depuis /app avec les scripts de configuration${NC}"
    exit 1
fi

# Lancer la démonstration
demo_configuration "$@"