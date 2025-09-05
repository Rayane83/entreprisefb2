#!/bin/bash

# 🔐 Script d'initialisation Discord OAuth pour Portail Entreprise Flashback Fa
# Version 2.0.0 - Configuration sécurisée des tokens Discord

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Fonction pour afficher les headers
print_header() {
    echo -e "${PURPLE}"
    echo "=================================================================================================="
    echo "🚀 CONFIGURATION DISCORD OAUTH - PORTAIL ENTREPRISE FLASHBACK FA v2.0.0"
    echo "=================================================================================================="
    echo -e "${NC}"
}

# Fonction pour afficher les étapes
print_step() {
    echo -e "${BLUE}[ÉTAPE] $1${NC}"
}

# Fonction pour afficher les succès
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Fonction pour afficher les avertissements
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Fonction pour afficher les erreurs
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Fonction pour valider un Client ID Discord
validate_client_id() {
    local client_id=$1
    if [[ ! $client_id =~ ^[0-9]{18,19}$ ]]; then
        return 1
    fi
    return 0
}

# Fonction pour valider un token/secret Discord
validate_token() {
    local token=$1
    if [[ ${#token} -lt 20 ]]; then
        return 1
    fi
    return 0
}

# Fonction pour sauvegarder de manière sécurisée dans .env
update_env_file() {
    local file=$1
    local key=$2
    local value=$3
    
    # Créer une sauvegarde
    cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Mettre à jour la valeur
    if grep -q "^${key}=" "$file"; then
        # Remplacer la ligne existante
        sed -i "s/^${key}=.*/${key}=${value}/" "$file"
    else
        # Ajouter la ligne si elle n'existe pas
        echo "${key}=${value}" >> "$file"
    fi
}

# Fonction principale
main() {
    print_header
    
    echo -e "${YELLOW}Ce script va configurer votre application avec les tokens Discord OAuth.${NC}"
    echo -e "${YELLOW}Assurez-vous d'avoir créé une application Discord avant de continuer.${NC}"
    echo ""
    
    # Vérifier les fichiers .env
    BACKEND_ENV="/app/backend/.env"
    FRONTEND_ENV="/app/frontend/.env"
    
    if [[ ! -f "$BACKEND_ENV" ]]; then
        print_error "Fichier $BACKEND_ENV introuvable !"
        exit 1
    fi
    
    if [[ ! -f "$FRONTEND_ENV" ]]; then
        print_error "Fichier $FRONTEND_ENV introuvable !"
        exit 1
    fi
    
    print_step "Vérification des fichiers de configuration"
    print_success "Fichiers .env trouvés"
    
    echo ""
    echo -e "${PURPLE}=================================================================================================="
    echo "📋 GUIDE RAPIDE - CRÉATION APPLICATION DISCORD"
    echo "=================================================================================================="
    echo -e "${NC}"
    echo "1. Allez sur https://discord.com/developers/applications"
    echo "2. Cliquez sur 'New Application' et donnez un nom (ex: 'Portail Flashback Fa')"
    echo "3. Dans l'onglet 'OAuth2' → 'General':"
    echo "   - Copiez le CLIENT ID"
    echo "   - Copiez le CLIENT SECRET"
    echo "   - Ajoutez cette URL de redirection: http://localhost:3000/auth/callback"
    echo "4. Dans l'onglet 'OAuth2' → 'URL Generator':"
    echo "   - Scopes: identify, email, guilds"
    echo "   - Redirect URL: http://localhost:3000/auth/callback"
    echo "5. (Optionnel) Dans l'onglet 'Bot', créez un bot et copiez le TOKEN"
    echo ""
    
    read -p "Appuyez sur Entrée pour continuer une fois que vous avez créé votre application Discord..."
    
    echo ""
    print_step "Configuration des tokens Discord"
    
    # Demander le Client ID
    while true; do
        echo ""
        echo -e "${BLUE}🔑 DISCORD CLIENT ID${NC}"
        echo "Le Client ID est un nombre de 18-19 chiffres visible dans l'onglet 'General' de votre application Discord."
        echo -n "Entrez votre Discord Client ID: "
        read -r DISCORD_CLIENT_ID
        
        if validate_client_id "$DISCORD_CLIENT_ID"; then
            print_success "Client ID valide: $DISCORD_CLIENT_ID"
            break
        else
            print_error "Client ID invalide. Il doit être composé de 18-19 chiffres."
        fi
    done
    
    # Demander le Client Secret
    while true; do
        echo ""
        echo -e "${BLUE}🔐 DISCORD CLIENT SECRET${NC}"
        echo "Le Client Secret est visible dans l'onglet 'OAuth2' → 'General' (cliquez sur 'Reset Secret' si nécessaire)."
        echo -n "Entrez votre Discord Client Secret: "
        read -rs DISCORD_CLIENT_SECRET
        echo
        
        if validate_token "$DISCORD_CLIENT_SECRET"; then
            print_success "Client Secret valide (${#DISCORD_CLIENT_SECRET} caractères)"
            break
        else
            print_error "Client Secret invalide. Il doit faire au moins 20 caractères."
        fi
    done
    
    # Demander le Bot Token (optionnel)
    echo ""
    echo -e "${BLUE}🤖 DISCORD BOT TOKEN (Optionnel)${NC}"
    echo "Le Bot Token permet de récupérer les rôles des utilisateurs dans les serveurs Discord."
    echo "Si vous n'en avez pas, laissez vide (l'app fonctionnera quand même)."
    echo -n "Entrez votre Discord Bot Token (ou laissez vide): "
    read -rs DISCORD_BOT_TOKEN
    echo
    
    if [[ -n "$DISCORD_BOT_TOKEN" ]]; then
        if validate_token "$DISCORD_BOT_TOKEN"; then
            print_success "Bot Token valide (${#DISCORD_BOT_TOKEN} caractères)"
        else
            print_warning "Bot Token potentiellement invalide, mais configuration continue..."
        fi
    else
        print_warning "Bot Token non fourni - les rôles Discord ne seront pas récupérés automatiquement"
        DISCORD_BOT_TOKEN=""
    fi
    
    echo ""
    print_step "Mise à jour des fichiers de configuration"
    
    # Mettre à jour le backend .env
    update_env_file "$BACKEND_ENV" "DISCORD_CLIENT_ID" "$DISCORD_CLIENT_ID"
    update_env_file "$BACKEND_ENV" "DISCORD_CLIENT_SECRET" "$DISCORD_CLIENT_SECRET"
    update_env_file "$BACKEND_ENV" "DISCORD_BOT_TOKEN" "$DISCORD_BOT_TOKEN"
    print_success "Backend .env mis à jour"
    
    # Mettre à jour le frontend .env
    update_env_file "$FRONTEND_ENV" "REACT_APP_DISCORD_CLIENT_ID" "$DISCORD_CLIENT_ID"
    print_success "Frontend .env mis à jour"
    
    # Désactiver le mode mock pour utiliser la vraie authentification
    update_env_file "$FRONTEND_ENV" "REACT_APP_USE_MOCK_AUTH" "false"
    update_env_file "$FRONTEND_ENV" "REACT_APP_FORCE_DISCORD_AUTH" "true"
    print_success "Mode authentification Discord activé"
    
    echo ""
    print_step "Génération des clés de sécurité"
    
    # Générer une clé JWT sécurisée
    JWT_SECRET=$(openssl rand -base64 32 | tr -d '\n')
    update_env_file "$BACKEND_ENV" "JWT_SECRET_KEY" "$JWT_SECRET"
    print_success "Clé JWT générée et configurée"
    
    echo ""
    echo -e "${GREEN}=================================================================================================="
    echo "🎉 CONFIGURATION TERMINÉE AVEC SUCCÈS !"
    echo "=================================================================================================="
    echo -e "${NC}"
    
    echo "📋 Récapitulatif de la configuration:"
    echo "   • Discord Client ID: $DISCORD_CLIENT_ID"
    echo "   • Discord Client Secret: [Configuré]"
    echo "   • Discord Bot Token: $([ -n "$DISCORD_BOT_TOKEN" ] && echo "[Configuré]" || echo "[Non fourni]")"
    echo "   • JWT Secret: [Généré automatiquement]"
    echo "   • Mode Mock: Désactivé"
    echo "   • Redirect URI: http://localhost:3000/auth/callback"
    echo ""
    
    echo -e "${BLUE}🚀 Prochaines étapes:${NC}"
    echo "1. Redémarrer les services:"
    echo "   sudo supervisorctl restart backend"
    echo "   sudo supervisorctl restart frontend"
    echo ""
    echo "2. Tester la connexion Discord:"
    echo "   http://localhost:3000"
    echo ""
    echo "3. Vérifier les logs en cas de problème:"
    echo "   tail -f /var/log/supervisor/backend.*.log"
    echo "   tail -f /var/log/supervisor/frontend.*.log"
    echo ""
    
    print_warning "IMPORTANT: Les fichiers .env ont été sauvegardés avec un timestamp"
    print_warning "Ne partagez JAMAIS vos tokens Discord publiquement"
    
    echo ""
    echo -n "Voulez-vous redémarrer les services maintenant ? (y/N): "
    read -r RESTART_SERVICES
    
    if [[ $RESTART_SERVICES =~ ^[Yy]$ ]]; then
        echo ""
        print_step "Redémarrage des services"
        
        if command -v supervisorctl >/dev/null 2>&1; then
            sudo supervisorctl restart backend
            sudo supervisorctl restart frontend
            print_success "Services redémarrés"
            
            echo ""
            echo -e "${GREEN}🌟 Application prête ! Rendez-vous sur http://localhost:3000${NC}"
        else
            print_warning "supervisorctl non trouvé, redémarrez manuellement les services"
        fi
    else
        echo ""
        print_warning "N'oubliez pas de redémarrer les services pour appliquer les changements"
    fi
    
    echo ""
    echo -e "${PURPLE}Configuration terminée ! L'application est prête pour l'authentification Discord.${NC}"
}

# Lancer le script principal
main "$@"