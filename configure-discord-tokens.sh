#!/bin/bash

# 🔐 Configuration sécurisée des tokens Discord OAuth
# Portail Entreprise Flashback Fa v2.0.0

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
    echo "🔐 CONFIGURATION DISCORD OAUTH - PORTAIL ENTREPRISE FLASHBACK FA"
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

# Validation Client ID Discord (18-19 digits)
validate_client_id() {
    local client_id=$1
    if [[ $client_id =~ ^[0-9]{18,19}$ ]]; then
        return 0
    fi
    return 1
}

# Validation token Discord (minimum 20 caractères)
validate_token() {
    local token=$1
    if [[ ${#token} -ge 20 ]]; then
        return 0
    fi
    return 1
}

# Mise à jour sécurisée des fichiers .env
update_env_safely() {
    local file=$1
    local key=$2
    local value=$3
    
    # Créer une sauvegarde avec timestamp
    cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Échapper les caractères spéciaux dans la valeur
    local escaped_value=$(printf '%s\n' "$value" | sed 's/[[\.*^$()+?{|]/\\&/g')
    
    # Remplacer ou ajouter la ligne
    if grep -q "^${key}=" "$file"; then
        sed -i "s/^${key}=.*/${key}=${escaped_value}/" "$file"
    else
        echo "${key}=${escaped_value}" >> "$file"
    fi
}

main() {
    print_header
    
    echo -e "${YELLOW}Ce script configure votre application avec les tokens Discord OAuth.${NC}"
    echo -e "${YELLOW}Assurez-vous d'avoir créé une application Discord au préalable.${NC}"
    echo ""
    
    # Vérifier les fichiers .env
    BACKEND_ENV="$SCRIPT_DIR/backend/.env"
    FRONTEND_ENV="$SCRIPT_DIR/frontend/.env"
    
    if [[ ! -f "$BACKEND_ENV" ]] || [[ ! -f "$FRONTEND_ENV" ]]; then
        print_error "Fichiers .env introuvables ! Vérifiez que l'application est correctement installée."
        exit 1
    fi
    
    print_success "Fichiers de configuration trouvés"
    
    echo ""
    echo -e "${PURPLE}=================================================================================================="
    echo "📋 GUIDE CRÉATION APPLICATION DISCORD"
    echo "=================================================================================================="
    echo -e "${NC}"
    echo "1. 🌐 Rendez-vous sur: https://discord.com/developers/applications"
    echo ""
    echo "2. 🆕 Créer une nouvelle application:"
    echo "   • Cliquez sur 'New Application'"
    echo "   • Nom suggéré: 'Portail Flashback Fa Production'"
    echo ""
    echo "3. ⚙️  Configuration OAuth2:"
    echo "   • Allez dans l'onglet 'OAuth2' → 'General'"
    echo "   • Copiez le CLIENT ID (18-19 chiffres)"
    echo "   • Générez et copiez le CLIENT SECRET"
    echo "   • Dans 'Redirects', ajoutez: http://localhost:3000/auth/callback"
    echo ""
    echo "4. 🎯 Permissions OAuth2:"
    echo "   • Allez dans 'OAuth2' → 'URL Generator'"
    echo "   • Scopes: identify, email, guilds"
    echo "   • Redirect URL: http://localhost:3000/auth/callback"
    echo ""
    echo "5. 🤖 Bot (Optionnel pour récupération des rôles):"
    echo "   • Allez dans l'onglet 'Bot'"
    echo "   • Créez un bot et copiez le TOKEN"
    echo ""
    
    read -p "Appuyez sur [Entrée] une fois votre application Discord créée..."
    
    echo ""
    print_info "Configuration des tokens Discord"
    
    # Configuration Client ID
    while true; do
        echo ""
        echo -e "${BLUE}🔑 DISCORD CLIENT ID${NC}"
        echo "C'est un nombre de 18-19 chiffres visible dans l'onglet 'General'"
        echo ""
        echo -n "Entrez votre Discord Client ID: "
        read -r DISCORD_CLIENT_ID
        
        if validate_client_id "$DISCORD_CLIENT_ID"; then
            print_success "Client ID valide: $DISCORD_CLIENT_ID"
            break
        else
            print_error "Client ID invalide. Doit être un nombre de 18-19 chiffres."
            echo -e "${YELLOW}Exemple: 123456789012345678${NC}"
        fi
    done
    
    # Configuration Client Secret
    while true; do
        echo ""
        echo -e "${BLUE}🔐 DISCORD CLIENT SECRET${NC}"
        echo "Visible dans 'OAuth2' → 'General' (générez-en un nouveau si nécessaire)"
        echo ""
        echo -n "Entrez votre Discord Client Secret (la saisie sera masquée): "
        read -rs DISCORD_CLIENT_SECRET
        echo
        
        if validate_token "$DISCORD_CLIENT_SECRET"; then
            print_success "Client Secret valide (${#DISCORD_CLIENT_SECRET} caractères)"
            break
        else
            print_error "Client Secret trop court. Doit faire au moins 20 caractères."
        fi
    done
    
    # Configuration Bot Token (optionnel)
    echo ""
    echo -e "${BLUE}🤖 DISCORD BOT TOKEN (Optionnel)${NC}"
    echo "Permet la récupération automatique des rôles Discord des utilisateurs."
    echo "Si vous n'avez pas de bot, laissez vide (l'application fonctionnera quand même)."
    echo ""
    echo -n "Entrez votre Discord Bot Token (optionnel, saisie masquée): "
    read -rs DISCORD_BOT_TOKEN
    echo
    
    if [[ -n "$DISCORD_BOT_TOKEN" ]]; then
        if validate_token "$DISCORD_BOT_TOKEN"; then
            print_success "Bot Token configuré (${#DISCORD_BOT_TOKEN} caractères)"
        else
            print_warning "Bot Token court, mais on continue..."
        fi
    else
        print_warning "Pas de Bot Token - Les rôles Discord ne seront pas récupérés automatiquement"
        DISCORD_BOT_TOKEN=""
    fi
    
    echo ""
    print_info "Mise à jour des fichiers de configuration..."
    
    # Mise à jour Backend .env
    update_env_safely "$BACKEND_ENV" "DISCORD_CLIENT_ID" "$DISCORD_CLIENT_ID"
    update_env_safely "$BACKEND_ENV" "DISCORD_CLIENT_SECRET" "$DISCORD_CLIENT_SECRET"
    update_env_safely "$BACKEND_ENV" "DISCORD_BOT_TOKEN" "$DISCORD_BOT_TOKEN"
    print_success "Backend configuré"
    
    # Mise à jour Frontend .env
    update_env_safely "$FRONTEND_ENV" "REACT_APP_DISCORD_CLIENT_ID" "$DISCORD_CLIENT_ID"
    print_success "Frontend configuré"
    
    # Désactiver le mode mock
    update_env_safely "$FRONTEND_ENV" "REACT_APP_USE_MOCK_AUTH" "false"
    update_env_safely "$FRONTEND_ENV" "REACT_APP_FORCE_DISCORD_AUTH" "true"
    print_success "Mode authentification Discord activé"
    
    # Générer une clé JWT sécurisée
    print_info "Génération d'une clé JWT sécurisée..."
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || head /dev/urandom | tr -dc A-Za-z0-9 | head -c 43)
    update_env_safely "$BACKEND_ENV" "JWT_SECRET_KEY" "${JWT_SECRET}"
    print_success "Clé JWT générée et configurée"
    
    echo ""
    echo -e "${GREEN}=================================================================================================="
    echo "🎉 CONFIGURATION DISCORD TERMINÉE !"
    echo "=================================================================================================="
    echo -e "${NC}"
    
    echo "📋 Récapitulatif:"
    echo "   • Discord Client ID: $DISCORD_CLIENT_ID"
    echo "   • Discord Client Secret: ✅ Configuré"
    echo "   • Discord Bot Token: $([ -n "$DISCORD_BOT_TOKEN" ] && echo "✅ Configuré" || echo "⚠️  Non fourni")"
    echo "   • JWT Secret Key: ✅ Généré automatiquement"
    echo "   • Mode Mock: ❌ Désactivé"
    echo "   • Redirect URI: http://localhost:3000/auth/callback"
    echo ""
    
    echo -e "${BLUE}🚀 Prochaines étapes:${NC}"
    echo ""
    echo "1. Redémarrer l'application:"
    echo "   sudo supervisorctl restart backend frontend"
    echo ""
    echo "2. Tester la connexion:"
    echo "   http://localhost:3000"
    echo ""
    echo "3. Surveiller les logs:"
    echo "   tail -f /var/log/supervisor/backend.*.log"
    echo ""
    
    print_warning "SÉCURITÉ: Vos tokens ont été sauvegardés. Ne les partagez JAMAIS publiquement !"
    
    echo ""
    echo -n "Voulez-vous redémarrer l'application maintenant ? [y/N]: "
    read -r restart_choice
    
    if [[ $restart_choice =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Redémarrage de l'application..."
        
        if command -v supervisorctl >/dev/null 2>&1; then
            sudo supervisorctl restart backend frontend
            sleep 3
            print_success "Application redémarrée !"
            echo ""
            echo -e "${GREEN}🌟 Votre application est prête ! Allez sur: http://localhost:3000${NC}"
        else
            print_warning "supervisorctl introuvable. Redémarrez manuellement."
        fi
    else
        echo ""
        print_warning "N'oubliez pas de redémarrer pour activer les nouveaux paramètres !"
    fi
    
    echo ""
    echo -e "${PURPLE}Configuration Discord OAuth terminée avec succès ! 🎉${NC}"
}

# Détecter le répertoire de l'application automatiquement
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Vérifier qu'on est dans un répertoire d'application valide
if [[ ! -d "$SCRIPT_DIR/backend" ]] || [[ ! -d "$SCRIPT_DIR/frontend" ]]; then
    echo -e "${RED}❌ Erreur: Ce script doit être exécuté depuis le répertoire racine de l'application${NC}"
    echo -e "${RED}   Répertoires backend/ et frontend/ introuvables dans: $SCRIPT_DIR${NC}"
    exit 1
fi

# Lancer la configuration
main "$@"