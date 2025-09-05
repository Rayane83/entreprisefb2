#!/bin/bash

# 🚀 LANCEUR SIMPLE - Portail Entreprise Flashback Fa
# Script de déploiement sans erreurs de syntaxe

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 LANCEMENT PORTAIL ENTREPRISE FLASHBACK FA${NC}"

# Auto-détection répertoire
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Répertoire: $SCRIPT_DIR"

# Variables
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

# Fonction: Installation dépendances Python
install_python_deps() {
    if [[ -f "$BACKEND_DIR/requirements.txt" ]]; then
        echo -e "${BLUE}Installation dépendances Python...${NC}"
        cd "$BACKEND_DIR"
        pip3 install --user -r requirements.txt --quiet || pip3 install --user -r requirements.txt
        echo -e "${GREEN}✅ Dépendances Python installées${NC}"
    fi
}

# Fonction: Installation dépendances Node
install_node_deps() {
    if [[ -f "$FRONTEND_DIR/package.json" ]]; then
        echo -e "${BLUE}Installation dépendances Node.js...${NC}"
        cd "$FRONTEND_DIR"
        if command -v yarn >/dev/null 2>&1; then
            yarn install --silent || yarn install
        elif command -v npm >/dev/null 2>&1; then
            npm install --silent || npm install
        fi
        echo -e "${GREEN}✅ Dépendances Node.js installées${NC}"
    fi
}

# Fonction: Création fichiers .env
create_env_files() {
    echo -e "${BLUE}Création fichiers .env...${NC}"
    
    # Backend .env
    cat > "$BACKEND_DIR/.env" << 'EOF'
DATABASE_URL=mysql+pymysql://flashback_user:FlashbackFA_2024!@localhost/flashback_fa_enterprise
DISCORD_CLIENT_ID=
DISCORD_CLIENT_SECRET=
DISCORD_BOT_TOKEN=
DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback
JWT_SECRET_KEY=super_secret_jwt_key_change_in_production_2024!
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=http://localhost:3000
ENABLE_METRICS=true
LOG_LEVEL=INFO
EOF

    # Frontend .env
    cat > "$FRONTEND_DIR/.env" << 'EOF'
REACT_APP_BACKEND_URL=http://localhost:8000
REACT_APP_DISCORD_CLIENT_ID=
REACT_APP_DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback
REACT_APP_APP_NAME=Portail Entreprise Flashback Fa
REACT_APP_VERSION=2.0.0
REACT_APP_USE_MOCK_AUTH=true
REACT_APP_FORCE_DISCORD_AUTH=false
EOF

    echo -e "${GREEN}✅ Fichiers .env créés${NC}"
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
        echo -e "${GREEN}✅ Base de données configurée${NC}"
    else
        echo -e "${YELLOW}⚠️  MySQL non disponible${NC}"
    fi
}

# Fonction: Démarrage services
start_services() {
    echo -e "${BLUE}Démarrage des services...${NC}"
    
    # Arrêter processus existants
    pkill -f "python3 server.py" 2>/dev/null || true
    pkill -f "yarn start" 2>/dev/null || true
    pkill -f "npm start" 2>/dev/null || true
    
    # Démarrer backend
    cd "$BACKEND_DIR"
    echo "Démarrage backend..."
    python3 server.py &
    BACKEND_PID=$!
    echo "$BACKEND_PID" > "$SCRIPT_DIR/.backend_pid"
    echo -e "${GREEN}✅ Backend démarré (PID: $BACKEND_PID)${NC}"
    
    # Démarrer frontend
    cd "$FRONTEND_DIR"
    echo "Démarrage frontend..."
    if command -v yarn >/dev/null 2>&1; then
        yarn start &
    else
        npm start &
    fi
    FRONTEND_PID=$!
    echo "$FRONTEND_PID" > "$SCRIPT_DIR/.frontend_pid"
    echo -e "${GREEN}✅ Frontend démarré (PID: $FRONTEND_PID)${NC}"
    
    cd "$SCRIPT_DIR"
}

# Fonction: Test connectivité
test_connectivity() {
    echo -e "${BLUE}Test de connectivité...${NC}"
    sleep 5
    
    if curl -s -f http://localhost:8000/health/live >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend accessible (http://localhost:8000)${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend non accessible${NC}"
    fi
    
    if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend accessible (http://localhost:3000)${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend non accessible${NC}"
    fi
}

# Fonction: Affichage infos finales
show_final_info() {
    echo ""
    echo -e "${GREEN}🎉 DÉPLOIEMENT TERMINÉ !${NC}"
    echo ""
    echo -e "${BLUE}📱 ACCÈS APPLICATION:${NC}"
    echo "   🌐 Interface: http://localhost:3000"
    echo "   🔧 API: http://localhost:8000"
    echo "   📚 Documentation: http://localhost:8000/docs"
    echo "   💊 Health: http://localhost:8000/health/live"
    echo ""
    echo -e "${BLUE}🛠️  ARRÊTER L'APPLICATION:${NC}"
    echo "   kill \$(cat .backend_pid .frontend_pid 2>/dev/null) 2>/dev/null || true"
    echo ""
    echo -e "${GREEN}✨ APPLICATION PRÊTE ! ✨${NC}"
}

# Exécution principale
main() {
    setup_database
    install_python_deps
    install_node_deps
    create_env_files
    start_services
    test_connectivity
    show_final_info
}

# Lancer
main