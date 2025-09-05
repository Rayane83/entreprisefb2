#!/bin/bash

# 🚀 Déploiement propre - Portail Entreprise Flashback Fa v2.0.0
# Nettoie tout et installe la nouvelle architecture FastAPI + MySQL

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
    echo "🚀 DÉPLOIEMENT COMPLET - PORTAIL ENTREPRISE FLASHBACK FA v2.0.0"
    echo "🔄 MIGRATION SUPABASE → FASTAPI + MYSQL + SQLALCHEMY"
    echo "=================================================================================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[ÉTAPE $1] $2${NC}"
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

# Fonction pour nettoyer l'ancien système
cleanup_old_system() {
    print_step "1" "Nettoyage du système existant"
    
    # Arrêter tous les services
    if command -v supervisorctl >/dev/null 2>&1; then
        sudo supervisorctl stop all || true
        print_info "Services supervisord arrêtés"
    fi
    
    # Sauvegarder les anciens .env s'ils existent
    if [[ -f "backend/.env" ]]; then
        cp backend/.env backend/.env.old.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        print_info "Ancien backend/.env sauvegardé"
    fi
    
    if [[ -f "frontend/.env" ]]; then
        cp frontend/.env frontend/.env.old.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
        print_info "Ancien frontend/.env sauvegardé"  
    fi
    
    # Nettoyer les anciens scripts de déploiement
    rm -f deploy-*.sh fix-*.sh launch-*.sh enable-*.sh force-*.sh clean-*.sh 2>/dev/null || true
    rm -f switch-*.sh restart-*.sh verify-*.sh diagnose-*.sh prepare-*.sh 2>/dev/null || true
    print_info "Anciens scripts de déploiement supprimés"
    
    # Nettoyer les anciens fichiers
    rm -f *.md.backup* DIAGNOSTIC_* INTEGRATION_* LoginScreen-production.js 2>/dev/null || true
    print_info "Fichiers temporaires nettoyés"
    
    print_success "Nettoyage terminé"
}

# Installation des dépendances système
install_system_dependencies() {
    print_step "2" "Installation des dépendances système"
    
    # Mise à jour du système
    sudo apt-get update -qq
    
    # Installation des paquets système nécessaires
    sudo apt-get install -y \
        mariadb-server \
        python3-pip \
        python3-venv \
        python3-dev \
        default-libmysqlclient-dev \
        build-essential \
        pkg-config \
        supervisor \
        nginx \
        curl \
        wget \
        unzip \
        openssl \
        2>/dev/null || true
    
    print_success "Dépendances système installées"
    
    # Configuration et démarrage de MariaDB
    sudo systemctl start mariadb || service mariadb start
    sudo systemctl enable mariadb 2>/dev/null || true
    
    print_success "MariaDB configuré et démarré"
}

# Configuration de la base de données MySQL
setup_database() {
    print_step "3" "Configuration de la base de données MySQL"
    
    # Création de la base de données et de l'utilisateur
    mysql -u root <<EOF
DROP DATABASE IF EXISTS flashback_fa_enterprise;
CREATE DATABASE flashback_fa_enterprise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP USER IF EXISTS 'flashback_user'@'localhost';
CREATE USER 'flashback_user'@'localhost' IDENTIFIED BY 'FlashbackFA_2024!';
GRANT ALL PRIVILEGES ON flashback_fa_enterprise.* TO 'flashback_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    print_success "Base de données MySQL configurée"
}

# Configuration du backend FastAPI
setup_backend() {
    print_step "4" "Configuration du backend FastAPI"
    
    # Créer le répertoire backend et ses sous-répertoires
    mkdir -p backend/{routes,utils,alembic/versions}
    
    # Créer requirements.txt
    cat > backend/requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn==0.24.0
python-dotenv==1.0.0
starlette==0.27.0
pydantic==2.5.0

# Base de données MySQL + SQLAlchemy
sqlalchemy==2.0.23
alembic==1.13.1
pymysql==1.1.0
mysqlclient==2.2.0

# Authentification Discord OAuth + JWT
httpx==0.25.2
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6

# Upload fichiers et export
aiofiles==23.2.1
openpyxl==3.1.2
reportlab==4.0.7
weasyprint==60.2

# CORS et middleware
bcrypt==4.1.2
EOF

    # Installation des dépendances Python
    cd backend
    python3 -m pip install -r requirements.txt
    cd ..
    
    print_success "Dépendances backend installées"
}

# Création des fichiers de configuration
create_config_files() {
    print_step "5" "Création des fichiers de configuration"
    
    # Backend .env
    cat > backend/.env << 'EOF'
# Base de données MySQL
DATABASE_URL=mysql+pymysql://flashback_user:FlashbackFA_2024!@localhost/flashback_fa_enterprise

# Authentification Discord OAuth (configuré par ./configure-discord-tokens.sh)
DISCORD_CLIENT_ID=
DISCORD_CLIENT_SECRET=
DISCORD_BOT_TOKEN=
DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback

# JWT Configuration
JWT_SECRET_KEY=super_secret_jwt_key_change_in_production_2024!
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
JWT_REFRESH_EXPIRATION_DAYS=7

# Application
API_HOST=0.0.0.0
API_PORT=8001
API_DEBUG=False
API_VERSION=v2.0.0

# CORS Origins
CORS_ORIGINS=http://localhost:3000,https://your-domain.com

# Upload de fichiers
UPLOAD_DIR=/home/ubuntu/entreprisefb2/backend/uploads
MAX_FILE_SIZE=10485760
ALLOWED_EXTENSIONS=pdf,doc,docx,jpg,jpeg,png,gif

# Logs
LOG_LEVEL=INFO
EOF
    
    # Frontend .env
    cat > frontend/.env << 'EOF'
# Backend API URL
REACT_APP_BACKEND_URL=http://localhost:8001

# Discord OAuth Configuration (configuré par ./configure-discord-tokens.sh)
REACT_APP_DISCORD_CLIENT_ID=
REACT_APP_DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback

# Application Configuration
REACT_APP_APP_NAME=Portail Entreprise Flashback Fa
REACT_APP_VERSION=2.0.0

# Development/Testing
REACT_APP_USE_MOCK_AUTH=true
REACT_APP_FORCE_DISCORD_AUTH=false
REACT_APP_DEBUG=true
EOF
    
    print_success "Fichiers de configuration créés"
}

# Configuration Alembic
setup_alembic() {
    print_step "6" "Configuration des migrations Alembic"
    
    cd backend
    
    # Initialiser Alembic
    alembic init alembic 2>/dev/null || true
    
    # Configuration alembic.ini
    cat > alembic.ini << 'EOF'
[alembic]
script_location = alembic
prepend_sys_path = .
sqlalchemy.url = mysql+pymysql://flashback_user:FlashbackFA_2024!@localhost/flashback_fa_enterprise

[post_write_hooks]

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
EOF
    
    cd ..
    print_success "Alembic configuré"
}

# Configuration Supervisor
setup_supervisor() {
    print_step "7" "Configuration Supervisor"
    
    # Configuration backend
    sudo tee /etc/supervisor/conf.d/backend.conf > /dev/null << EOF
[program:backend]
command=/usr/bin/python3 server.py
directory=/home/ubuntu/entreprisefb2/backend
user=ubuntu
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/backend.out.log
stderr_logfile=/var/log/supervisor/backend.err.log
environment=PATH="/usr/bin:/usr/local/bin"
EOF
    
    # Configuration frontend
    sudo tee /etc/supervisor/conf.d/frontend.conf > /dev/null << EOF
[program:frontend]
command=/usr/bin/yarn start
directory=/home/ubuntu/entreprisefb2/frontend
user=ubuntu
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/frontend.out.log
stderr_logfile=/var/log/supervisor/frontend.err.log
environment=PATH="/usr/bin:/usr/local/bin:/home/ubuntu/.nvm/versions/node/v18.17.0/bin",NODE_ENV="development"
EOF
    
    # Recharger supervisor
    sudo supervisorctl reread
    sudo supervisorctl update
    
    print_success "Supervisor configuré"
}

# Installation des scripts sécurisés
install_secure_scripts() {
    print_step "8" "Installation des scripts de configuration sécurisée"
    
    # Script de configuration Discord
    cat > configure-discord-tokens.sh << 'EOF'
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

validate_client_id() {
    local client_id=$1
    if [[ $client_id =~ ^[0-9]{18,19}$ ]]; then
        return 0
    fi
    return 1
}

validate_token() {
    local token=$1
    if [[ ${#token} -ge 20 ]]; then
        return 0
    fi
    return 1
}

update_env_safely() {
    local file=$1
    local key=$2
    local value=$3
    
    cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
    
    local escaped_value=$(printf '%s\n' "$value" | sed 's/[[\.*^$()+?{|]/\\&/g')
    
    if grep -q "^${key}=" "$file"; then
        sed -i "s/^${key}=.*/${key}=${escaped_value}/" "$file"
    else
        echo "${key}=${escaped_value}" >> "$file"
    fi
}

main() {
    print_header
    
    echo -e "${YELLOW}Ce script configure votre application avec les tokens Discord OAuth.${NC}"
    echo -e "${YELLOW}Créez d'abord une application sur https://discord.com/developers/applications${NC}"
    echo ""
    
    BACKEND_ENV="backend/.env"
    FRONTEND_ENV="frontend/.env"
    
    if [[ ! -f "$BACKEND_ENV" ]] || [[ ! -f "$FRONTEND_ENV" ]]; then
        print_error "Fichiers .env introuvables !"
        exit 1
    fi
    
    print_success "Fichiers de configuration trouvés"
    
    echo ""
    echo -e "${PURPLE}📋 GUIDE DISCORD DEVELOPER PORTAL${NC}"
    echo "1. Allez sur: https://discord.com/developers/applications"
    echo "2. Créez une 'New Application'"
    echo "3. Dans OAuth2 → General: Copiez Client ID et Client Secret"
    echo "4. Dans OAuth2 → General: Ajoutez redirect http://localhost:3000/auth/callback"
    echo "5. Optionnel: Dans Bot, créez un bot et copiez le token"
    echo ""
    
    read -p "Appuyez sur [Entrée] quand c'est fait..."
    
    # Configuration Client ID
    while true; do
        echo ""
        echo -e "${BLUE}🔑 DISCORD CLIENT ID${NC}"
        echo -n "Entrez votre Discord Client ID: "
        read -r DISCORD_CLIENT_ID
        
        if validate_client_id "$DISCORD_CLIENT_ID"; then
            print_success "Client ID valide: $DISCORD_CLIENT_ID"
            break
        else
            print_error "Client ID invalide. Doit être 18-19 chiffres."
        fi
    done
    
    # Configuration Client Secret
    while true; do
        echo ""
        echo -e "${BLUE}🔐 DISCORD CLIENT SECRET${NC}"
        echo -n "Entrez votre Discord Client Secret (masqué): "
        read -rs DISCORD_CLIENT_SECRET
        echo
        
        if validate_token "$DISCORD_CLIENT_SECRET"; then
            print_success "Client Secret valide"
            break
        else
            print_error "Client Secret trop court."
        fi
    done
    
    # Configuration Bot Token
    echo ""
    echo -e "${BLUE}🤖 DISCORD BOT TOKEN (Optionnel)${NC}"
    echo -n "Bot Token (optionnel, masqué): "
    read -rs DISCORD_BOT_TOKEN
    echo
    
    if [[ -n "$DISCORD_BOT_TOKEN" ]]; then
        print_success "Bot Token configuré"
    else
        print_warning "Pas de Bot Token"
        DISCORD_BOT_TOKEN=""
    fi
    
    print_info "Mise à jour des configurations..."
    
    # Mise à jour des fichiers
    update_env_safely "$BACKEND_ENV" "DISCORD_CLIENT_ID" "$DISCORD_CLIENT_ID"
    update_env_safely "$BACKEND_ENV" "DISCORD_CLIENT_SECRET" "$DISCORD_CLIENT_SECRET"
    update_env_safely "$BACKEND_ENV" "DISCORD_BOT_TOKEN" "$DISCORD_BOT_TOKEN"
    
    update_env_safely "$FRONTEND_ENV" "REACT_APP_DISCORD_CLIENT_ID" "$DISCORD_CLIENT_ID"
    update_env_safely "$FRONTEND_ENV" "REACT_APP_USE_MOCK_AUTH" "false"
    update_env_safely "$FRONTEND_ENV" "REACT_APP_FORCE_DISCORD_AUTH" "true"
    
    # Générer JWT secret
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || head /dev/urandom | tr -dc A-Za-z0-9 | head -c 43)
    update_env_safely "$BACKEND_ENV" "JWT_SECRET_KEY" "${JWT_SECRET}"
    
    echo ""
    echo -e "${GREEN}🎉 CONFIGURATION TERMINÉE !${NC}"
    echo "✅ Discord OAuth configuré"
    echo "✅ Mode production activé"
    echo ""
    
    echo -n "Redémarrer les services ? [y/N]: "
    read -r restart_choice
    
    if [[ $restart_choice =~ ^[Yy]$ ]]; then
        sudo supervisorctl restart backend frontend
        echo -e "${GREEN}🌟 Application prête sur http://localhost:3000${NC}"
    fi
}

main "$@"
EOF
    
    chmod +x configure-discord-tokens.sh
    
    # Script de lancement
    cat > run-app.sh << 'EOF'
#!/bin/bash

# 🚀 Lancement - Portail Entreprise Flashback Fa v2.0.0

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${PURPLE}"
    echo "🚀 PORTAIL ENTREPRISE FLASHBACK FA v2.0.0"
    echo -e "${NC}"
}

check_discord_config() {
    local backend_env="backend/.env"
    local client_id=$(grep "^DISCORD_CLIENT_ID=" "$backend_env" | cut -d'=' -f2)
    
    if [[ "$client_id" =~ ^[0-9]{18,19}$ ]]; then
        return 0
    fi
    return 1
}

main() {
    print_header
    
    if check_discord_config; then
        echo -e "${GREEN}✅ Configuration Discord détectée${NC}"
    else
        echo -e "${YELLOW}⚠️  Configuration Discord manquante${NC}"
        echo ""
        echo "1. Configurer Discord OAuth (production)"
        echo "2. Mode développement (mock)"
        echo ""
        read -p "Votre choix [1/2]: " choice
        
        case $choice in
            1)
                ./configure-discord-tokens.sh
                ;;
            2)
                sed -i 's/REACT_APP_USE_MOCK_AUTH=false/REACT_APP_USE_MOCK_AUTH=true/' frontend/.env
                sed -i 's/REACT_APP_FORCE_DISCORD_AUTH=true/REACT_APP_FORCE_DISCORD_AUTH=false/' frontend/.env
                ;;
        esac
    fi
    
    echo -e "${BLUE}ℹ️  Démarrage des services...${NC}"
    
    # Démarrer MariaDB
    sudo systemctl start mariadb || service mariadb start
    
    # Démarrer les services
    sudo supervisorctl restart backend frontend
    sleep 3
    
    echo ""
    echo -e "${GREEN}🌟 APPLICATION PRÊTE !${NC}"
    echo "🌐 Frontend: http://localhost:3000"
    echo "🔧 Backend: http://localhost:8001"
    echo ""
}

main "$@"
EOF
    
    chmod +x run-app.sh
    
    print_success "Scripts sécurisés installés"
}

# Fonction principale de déploiement
main() {
    print_header
    
    echo -e "${YELLOW}Ce script va nettoyer et redéployer complètement l'application.${NC}"
    echo -e "${YELLOW}Toutes les anciennes configurations seront sauvegardées.${NC}"
    echo ""
    
    read -p "Continuer le déploiement ? [y/N]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Déploiement annulé."
        exit 0
    fi
    
    cleanup_old_system
    install_system_dependencies
    setup_database
    setup_backend
    create_config_files
    setup_alembic
    setup_supervisor
    install_secure_scripts
    
    echo ""
    echo -e "${GREEN}=================================================================================================="
    echo "🎉 DÉPLOIEMENT TERMINÉ AVEC SUCCÈS !"
    echo "=================================================================================================="
    echo -e "${NC}"
    
    echo "📋 Prochaines étapes:"
    echo ""
    echo "1. **Lancer l'application :**"
    echo "   ./run-app.sh"
    echo ""
    echo "2. **Configurer Discord OAuth (production) :**"
    echo "   ./configure-discord-tokens.sh"
    echo ""
    echo "3. **Accès :**"
    echo "   🌐 Application: http://localhost:3000"
    echo "   🔧 API: http://localhost:8001"
    echo ""
    
    echo -e "${BLUE}Voulez-vous lancer l'application maintenant ? [y/N]:${NC}"
    read -r launch_now
    
    if [[ $launch_now =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${GREEN}🚀 Lancement de l'application...${NC}"
        ./run-app.sh
    else
        echo ""
        echo -e "${PURPLE}Déploiement terminé ! Lancez avec: ./run-app.sh${NC}"
    fi
}

# Vérifier qu'on est dans le bon répertoire
if [[ ! -d "frontend" ]] && [[ ! -d "backend" ]]; then
    echo -e "${RED}❌ Exécutez ce script depuis votre répertoire de projet${NC}"
    exit 1
fi

main "$@"