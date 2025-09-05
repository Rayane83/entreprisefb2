#!/bin/bash

# 🚀 LANCEUR AVEC ENVIRONNEMENT VIRTUEL - Portail Entreprise Flashback Fa
# Compatible Ubuntu 22.04+ avec gestion PEP 668

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
VENV_DIR="$SCRIPT_DIR/venv"

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

# Fonction: Création environnement virtuel Python
create_python_venv() {
    echo -e "${BLUE}Création environnement virtuel Python...${NC}"
    
    # Installer python3-venv si nécessaire
    if ! python3 -m venv --help >/dev/null 2>&1; then
        echo "Installation python3-venv..."
        sudo apt update -qq
        sudo apt install -y python3-venv python3-full
    fi
    
    # Créer l'environnement virtuel
    if [[ ! -d "$VENV_DIR" ]]; then
        python3 -m venv "$VENV_DIR"
        echo -e "${GREEN}✅ Environnement virtuel créé${NC}"
    else
        echo -e "${GREEN}✅ Environnement virtuel existant${NC}"
    fi
    
    # Activer l'environnement virtuel
    source "$VENV_DIR/bin/activate"
    
    # Mettre à jour pip
    pip install --upgrade pip --quiet
    echo -e "${GREEN}✅ Environnement virtuel activé${NC}"
}

# Fonction: Installation dépendances Python dans venv
install_python_deps() {
    if [[ -f "$BACKEND_DIR/requirements.txt" ]]; then
        echo -e "${BLUE}Installation dépendances Python (venv)...${NC}"
        cd "$BACKEND_DIR"
        
        # S'assurer que venv est activé
        if [[ "$VIRTUAL_ENV" != "$VENV_DIR" ]]; then
            source "$VENV_DIR/bin/activate"
        fi
        
        # Installer les dépendances
        pip install -r requirements.txt --quiet || pip install -r requirements.txt
        echo -e "${GREEN}✅ Dépendances Python installées (venv)${NC}"
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

# Fonction: Démarrage services
start_services() {
    echo -e "${BLUE}Démarrage des services...${NC}"
    
    # Arrêter processus existants
    pkill -f "python.*server.py" 2>/dev/null || true
    pkill -f "yarn start" 2>/dev/null || true
    pkill -f "npm start" 2>/dev/null || true
    
    # Démarrer backend avec venv
    cd "$BACKEND_DIR"
    echo "Démarrage backend (avec environnement virtuel)..."
    
    # S'assurer que venv est activé
    if [[ "$VIRTUAL_ENV" != "$VENV_DIR" ]]; then
        source "$VENV_DIR/bin/activate"
    fi
    
    python server.py &
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
    sleep 8  # Plus de temps pour que les services démarrent
    
    # Test backend avec plusieurs tentatives
    for i in {1..5}; do
        if curl -s -f http://localhost:8000/health/live >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Backend accessible (http://localhost:8000)${NC}"
            break
        elif [[ $i -eq 5 ]]; then
            echo -e "${YELLOW}⚠️  Backend non accessible après 5 tentatives${NC}"
            echo "Vérifiez les logs: tail -f $SCRIPT_DIR/backend.log"
        else
            echo "Tentative $i/5 - Backend en cours de démarrage..."
            sleep 2
        fi
    done
    
    # Test frontend
    for i in {1..3}; do
        if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Frontend accessible (http://localhost:3000)${NC}"
            break
        elif [[ $i -eq 3 ]]; then
            echo -e "${YELLOW}⚠️  Frontend non accessible${NC}"
        else
            echo "Frontend en cours de démarrage..."
            sleep 3
        fi
    done
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
    echo -e "${BLUE}🛠️  GESTION APPLICATION:${NC}"
    echo "   🛑 Arrêter: kill \$(cat .backend_pid .frontend_pid 2>/dev/null) 2>/dev/null || true"
    echo "   🔄 Redémarrer: $0"
    echo "   📋 Logs Backend: tail -f backend.log (si créé)"
    echo "   📋 PIDs: Backend=$(<.backend_pid 2>/dev/null), Frontend=$(<.frontend_pid 2>/dev/null)"
    echo ""
    echo -e "${BLUE}🐍 ENVIRONNEMENT PYTHON:${NC}"
    echo "   📁 Venv: $VENV_DIR"
    echo "   🔧 Activer: source $VENV_DIR/bin/activate"
    echo "   📦 Packages: pip list (après activation)"
    echo ""
    echo -e "${GREEN}✨ APPLICATION PRÊTE AVEC ENVIRONNEMENT VIRTUEL ! ✨${NC}"
}

# Fonction: Gestion des erreurs
cleanup_on_error() {
    echo -e "${RED}❌ Erreur détectée, nettoyage...${NC}"
    pkill -f "python.*server.py" 2>/dev/null || true
    pkill -f "yarn start" 2>/dev/null || true
    pkill -f "npm start" 2>/dev/null || true
    exit 1
}

trap cleanup_on_error ERR

# Exécution principale
main() {
    setup_database
    create_python_venv
    install_python_deps
    install_node_deps
    create_env_files
    start_services
    test_connectivity
    show_final_info
}

# Lancer
main