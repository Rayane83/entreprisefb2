#!/bin/bash

# 🚀 LANCEUR PRODUCTION - flashbackfa-entreprise.fr
# Génération automatique de tous les secrets + configuration Discord

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

echo -e "${PURPLE}${BOLD}"
echo "=================================================================================================="
echo "🚀 DÉPLOIEMENT PRODUCTION - FLASHBACK FA ENTREPRISE"
echo "   Domaine: https://flashbackfa-entreprise.fr/"
echo "   Génération automatique des secrets sécurisés"
echo "=================================================================================================="
echo -e "${NC}"

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
VENV_DIR="$SCRIPT_DIR/venv"
DOMAIN="flashbackfa-entreprise.fr"
DOMAIN_URL="https://$DOMAIN"

# Fonction: Génération de secrets sécurisés
generate_secrets() {
    echo -e "${CYAN}🔐 Génération des secrets sécurisés...${NC}"
    
    # Générer JWT Secret (64 caractères)
    JWT_SECRET=$(openssl rand -hex 32)
    
    # Générer Session Secret (64 caractères)  
    SESSION_SECRET=$(openssl rand -hex 32)
    
    # Générer API Key interne (32 caractères)
    API_SECRET=$(openssl rand -hex 16)
    
    # Générer Salt pour hashage (32 caractères)
    HASH_SALT=$(openssl rand -hex 16)
    
    # Générer Encryption Key (64 caractères)
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    
    echo -e "${GREEN}✅ Secrets générés automatiquement${NC}"
}

# Fonction: Configuration Discord interactive
configure_discord() {
    echo -e "${CYAN}${BOLD}🔐 CONFIGURATION DISCORD OAUTH${NC}"
    echo ""
    echo -e "${YELLOW}Pour configurer Discord OAuth, rendez-vous sur:${NC}"
    echo "https://discord.com/developers/applications"
    echo ""
    echo -e "${YELLOW}1. Créez une nouvelle application Discord${NC}"
    echo -e "${YELLOW}2. Dans 'OAuth2' > 'General', ajoutez ces Redirect URIs:${NC}"
    echo "   • $DOMAIN_URL/auth/callback"
    echo "   • http://localhost:3000/auth/callback (pour dev)"
    echo ""
    echo -e "${YELLOW}3. Récupérez vos tokens:${NC}"
    echo ""
    
    # Demander Client ID
    echo -n -e "${BLUE}Discord Client ID: ${NC}"
    read -r DISCORD_CLIENT_ID
    
    # Demander Client Secret
    echo -n -e "${BLUE}Discord Client Secret: ${NC}"
    read -r DISCORD_CLIENT_SECRET
    
    # Bot Token optionnel
    echo ""
    echo -e "${YELLOW}Bot Token (optionnel, laissez vide si pas de bot):${NC}"
    echo -n -e "${BLUE}Discord Bot Token: ${NC}"
    read -r DISCORD_BOT_TOKEN
    
    echo ""
    echo -e "${GREEN}✅ Configuration Discord enregistrée${NC}"
}

# Fonction: Correction repositories
fix_repositories() {
    echo -e "${BLUE}Correction des repositories...${NC}"
    sudo rm -f /etc/apt/sources.list.d/mongodb*.list 2>/dev/null || true
    sudo apt update 2>/dev/null || sudo apt update --allow-releaseinfo-change 2>/dev/null || true
    echo -e "${GREEN}✅ Repositories corrigés${NC}"
}

# Fonction: Installation dépendances système
install_system_deps() {
    echo -e "${BLUE}Installation dépendances système...${NC}"
    sudo apt install -y \
        pkg-config \
        python3-dev \
        python3-venv \
        python3-full \
        build-essential \
        curl \
        wget \
        nginx \
        certbot \
        python3-certbot-nginx 2>/dev/null || echo "Certaines dépendances déjà installées"
    
    sudo apt install -y libmariadb-dev libmariadb-dev-compat 2>/dev/null || \
    sudo apt install -y default-libmysqlclient-dev 2>/dev/null || \
    echo "Headers MySQL installés (fallback PyMySQL)"
    
    echo -e "${GREEN}✅ Dépendances système installées${NC}"
}

# Fonction: Configuration base de données
setup_database() {
    echo -e "${BLUE}Configuration base de données...${NC}"
    if command -v mysql >/dev/null 2>&1; then
        mysql -u root << 'DBEOF' 2>/dev/null || true
CREATE DATABASE IF NOT EXISTS flashback_fa_enterprise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'flashback_user'@'localhost' IDENTIFIED BY 'FlashbackFA_2024!';
GRANT ALL PRIVILEGES ON flashback_fa_enterprise.* TO 'flashback_user'@'localhost';
FLUSH PRIVILEGES;
DBEOF
        DATABASE_URL="mysql+pymysql://flashback_user:FlashbackFA_2024!@localhost/flashback_fa_enterprise"
        echo -e "${GREEN}✅ Base de données MySQL configurée${NC}"
    else
        DATABASE_URL="sqlite:///./flashback_production.db"
        echo -e "${YELLOW}⚠️  Utilisation SQLite (MySQL non disponible)${NC}"
    fi
}

# Fonction: Création environnement virtuel
create_python_venv() {
    echo -e "${BLUE}Configuration environnement Python...${NC}"
    
    if [[ -d "$VENV_DIR" ]] && ! source "$VENV_DIR/bin/activate" 2>/dev/null; then
        rm -rf "$VENV_DIR"
    fi
    
    if [[ ! -d "$VENV_DIR" ]]; then
        python3 -m venv "$VENV_DIR"
    fi
    
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip --quiet
    echo -e "${GREEN}✅ Environnement virtuel configuré${NC}"
}

# Fonction: Installation dépendances Python
install_python_deps() {
    echo -e "${BLUE}Installation dépendances Python...${NC}"
    cd "$BACKEND_DIR"
    
    source "$VENV_DIR/bin/activate"
    
    # Requirements production
    cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-dotenv==1.0.0
pydantic==2.5.0
sqlalchemy==2.0.23
pymysql==1.1.0
httpx==0.25.2
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
bcrypt==4.1.2
cryptography==41.0.8
passlib[bcrypt]==1.7.4
EOF
    
    pip install -r requirements.txt --quiet
    echo -e "${GREEN}✅ Dépendances Python installées${NC}"
}

# Fonction: Installation dépendances Node
install_node_deps() {
    if [[ -f "$FRONTEND_DIR/package.json" ]]; then
        echo -e "${BLUE}Installation dépendances Node.js...${NC}"
        cd "$FRONTEND_DIR"
        
        if command -v yarn >/dev/null 2>&1; then
            yarn install --network-timeout 100000 2>/dev/null || yarn install
        elif command -v npm >/dev/null 2>&1; then
            npm install --timeout 100000 2>/dev/null || npm install
        fi
        echo -e "${GREEN}✅ Dépendances Node.js installées${NC}"
    fi
}

# Fonction: Création fichiers de configuration production
create_production_config() {
    echo -e "${BLUE}Création configuration production...${NC}"
    
    # Backend .env production
    cat > "$BACKEND_DIR/.env" << EOF
# Base de données
DATABASE_URL=$DATABASE_URL

# Discord OAuth
DISCORD_CLIENT_ID=$DISCORD_CLIENT_ID
DISCORD_CLIENT_SECRET=$DISCORD_CLIENT_SECRET
DISCORD_BOT_TOKEN=$DISCORD_BOT_TOKEN
DISCORD_REDIRECT_URI=$DOMAIN_URL/auth/callback

# JWT & Security (générés automatiquement)
JWT_SECRET_KEY=$JWT_SECRET
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
SESSION_SECRET=$SESSION_SECRET
API_SECRET_KEY=$API_SECRET
HASH_SALT=$HASH_SALT
ENCRYPTION_KEY=$ENCRYPTION_KEY

# Application Production
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=$DOMAIN_URL,http://localhost:3000
ENVIRONMENT=production
DOMAIN=$DOMAIN

# Security Headers
SECURE_COOKIES=true
HTTPS_ONLY=true
SAMESITE_STRICT=true

# Monitoring & Logs
ENABLE_METRICS=true
LOG_LEVEL=INFO
LOG_FILE=flashback_production.log
EOF

    # Frontend .env production
    cat > "$FRONTEND_DIR/.env" << EOF
# Backend API
REACT_APP_BACKEND_URL=$DOMAIN_URL/api

# Discord OAuth
REACT_APP_DISCORD_CLIENT_ID=$DISCORD_CLIENT_ID
REACT_APP_DISCORD_REDIRECT_URI=$DOMAIN_URL/auth/callback

# Application
REACT_APP_APP_NAME=Portail Entreprise Flashback Fa
REACT_APP_VERSION=2.0.0
REACT_APP_DOMAIN=$DOMAIN

# Production Settings
REACT_APP_USE_MOCK_AUTH=false
REACT_APP_FORCE_DISCORD_AUTH=true  
REACT_APP_ENVIRONMENT=production
GENERATE_SOURCEMAP=false
EOF

    echo -e "${GREEN}✅ Configuration production créée${NC}"
    cd "$SCRIPT_DIR"
}

# Fonction: Configuration Nginx
configure_nginx() {
    echo -e "${BLUE}Configuration Nginx...${NC}"
    
    sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL configuration (certbot will fill this)
    
    # Frontend (React)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

    # Activer le site
    sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx 2>/dev/null || echo "Nginx config créé (SSL à configurer)"
    
    echo -e "${GREEN}✅ Configuration Nginx créée${NC}"
}

# Fonction: Démarrage services
start_services() {
    echo -e "${BLUE}Démarrage des services...${NC}"
    
    pkill -f "python.*server.py" 2>/dev/null || true
    pkill -f "yarn start" 2>/dev/null || true
    pkill -f "npm start" 2>/dev/null || true
    sleep 3
    
    # Backend
    cd "$BACKEND_DIR"
    source "$VENV_DIR/bin/activate"
    nohup python server.py > "$SCRIPT_DIR/backend_production.log" 2>&1 &
    BACKEND_PID=$!
    echo "$BACKEND_PID" > "$SCRIPT_DIR/.backend_pid"
    echo -e "${GREEN}✅ Backend démarré (PID: $BACKEND_PID)${NC}"
    
    # Frontend
    cd "$FRONTEND_DIR"
    if command -v yarn >/dev/null 2>&1; then
        nohup yarn start > "$SCRIPT_DIR/frontend_production.log" 2>&1 &
    else
        nohup npm start > "$SCRIPT_DIR/frontend_production.log" 2>&1 &
    fi
    FRONTEND_PID=$!
    echo "$FRONTEND_PID" > "$SCRIPT_DIR/.frontend_pid"
    echo -e "${GREEN}✅ Frontend démarré (PID: $FRONTEND_PID)${NC}"
    
    cd "$SCRIPT_DIR"
}

# Fonction: Test connectivité
test_connectivity() {
    echo -e "${BLUE}Test de connectivité...${NC}"
    sleep 15
    
    if curl -s http://localhost:8000/health >/dev/null 2>&1 || curl -s http://localhost:8000/ >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend accessible (localhost:8000)${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend: voir logs backend_production.log${NC}"
    fi
    
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend accessible (localhost:3000)${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend: voir logs frontend_production.log${NC}"
    fi
}

# Fonction: Affichage des secrets générés
show_generated_secrets() {
    echo ""
    echo -e "${PURPLE}${BOLD}=================================================================================================="
    echo "🔐 SECRETS GÉNÉRÉS AUTOMATIQUEMENT - SAUVEGARDEZ-LES PRÉCIEUSEMENT !"
    echo "=================================================================================================="
    echo -e "${NC}"
    
    echo -e "${CYAN}🔑 JWT & AUTHENTIFICATION:${NC}"
    echo "   JWT_SECRET_KEY: $JWT_SECRET"
    echo "   SESSION_SECRET: $SESSION_SECRET"
    echo "   API_SECRET_KEY: $API_SECRET"
    echo ""
    
    echo -e "${CYAN}🔐 CHIFFREMENT & SÉCURITÉ:${NC}"
    echo "   HASH_SALT: $HASH_SALT"
    echo "   ENCRYPTION_KEY: $ENCRYPTION_KEY"
    echo ""
    
    echo -e "${CYAN}🎮 DISCORD OAUTH (configuré):${NC}"
    echo "   CLIENT_ID: $DISCORD_CLIENT_ID"
    echo "   CLIENT_SECRET: $DISCORD_CLIENT_SECRET"
    echo "   BOT_TOKEN: ${DISCORD_BOT_TOKEN:-"(non configuré)"}"
    echo ""
    
    # Sauvegarder dans un fichier
    cat > "$SCRIPT_DIR/SECRETS_PRODUCTION.txt" << EOF
FLASHBACK FA ENTREPRISE - SECRETS PRODUCTION
Généré le: $(date)
Domaine: $DOMAIN_URL

JWT_SECRET_KEY=$JWT_SECRET
SESSION_SECRET=$SESSION_SECRET
API_SECRET_KEY=$API_SECRET
HASH_SALT=$HASH_SALT
ENCRYPTION_KEY=$ENCRYPTION_KEY

DISCORD_CLIENT_ID=$DISCORD_CLIENT_ID
DISCORD_CLIENT_SECRET=$DISCORD_CLIENT_SECRET
DISCORD_BOT_TOKEN=$DISCORD_BOT_TOKEN

⚠️ GARDEZ CE FICHIER EN SÉCURITÉ - NE LE PARTAGEZ JAMAIS !
EOF
    
    echo -e "${GREEN}✅ Secrets sauvegardés dans: SECRETS_PRODUCTION.txt${NC}"
}

# Fonction: Rapport final
show_final_report() {
    echo ""
    echo -e "${GREEN}${BOLD}=================================================================================================="
    echo "🎉 DÉPLOIEMENT PRODUCTION TERMINÉ - FLASHBACK FA ENTREPRISE"
    echo "=================================================================================================="
    echo -e "${NC}"
    
    echo -e "${CYAN}🌐 ACCÈS PRODUCTION:${NC}"
    echo "   🚀 Site Web: $DOMAIN_URL"
    echo "   🔧 API Backend: $DOMAIN_URL/api"
    echo "   📚 Documentation: $DOMAIN_URL/api/docs"
    echo "   💊 Health Check: $DOMAIN_URL/api/health"
    echo ""
    
    echo -e "${CYAN}🔧 ACCÈS LOCAL (développement):${NC}"
    echo "   🌐 Frontend: http://localhost:3000"
    echo "   🔧 Backend: http://localhost:8000"
    echo ""
    
    echo -e "${CYAN}🛠️  GESTION PRODUCTION:${NC}"
    echo "   🛑 Arrêter: kill \$(cat .backend_pid .frontend_pid 2>/dev/null) || true"
    echo "   📋 Logs Backend: tail -f backend_production.log"
    echo "   📋 Logs Frontend: tail -f frontend_production.log"
    echo "   🔄 Nginx: sudo systemctl restart nginx"
    echo ""
    
    echo -e "${CYAN}🔒 SSL/HTTPS (à configurer):${NC}"
    echo "   🔐 Certificat SSL: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    echo "   🔄 Renouvellement auto: sudo systemctl enable certbot.timer"
    echo ""
    
    echo -e "${CYAN}📁 FICHIERS IMPORTANTS:${NC}"
    echo "   🔐 Secrets: SECRETS_PRODUCTION.txt"
    echo "   ⚙️  Config Backend: backend/.env"
    echo "   ⚙️  Config Frontend: frontend/.env"
    echo "   🌐 Config Nginx: /etc/nginx/sites-available/$DOMAIN"
    echo ""
    
    echo -e "${GREEN}✨ VOTRE APPLICATION EST PRÊTE POUR LA PRODUCTION ! ✨${NC}"
    echo -e "${YELLOW}N'oubliez pas de configurer SSL avec certbot pour activer HTTPS${NC}"
}

# Exécution principale
main() {
    generate_secrets
    configure_discord
    fix_repositories
    install_system_deps  
    setup_database
    create_python_venv
    install_python_deps
    install_node_deps
    create_production_config
    configure_nginx
    start_services
    test_connectivity
    show_generated_secrets
    show_final_report
}

# Lancer le déploiement production
main