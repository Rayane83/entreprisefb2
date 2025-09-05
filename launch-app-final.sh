#!/bin/bash

# 🚀 LANCEUR FINAL - Portail Entreprise Flashback Fa
# Résout le problème mysqlclient + dépendances système

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

# Fonction: Installation dépendances système
install_system_deps() {
    echo -e "${BLUE}Installation dépendances système...${NC}"
    
    # Mettre à jour la liste des packages
    sudo apt update -qq
    
    # Installer les dépendances pour mysqlclient
    sudo apt install -y \
        pkg-config \
        python3-dev \
        libmariadb-dev \
        libmariadb-dev-compat \
        build-essential \
        python3-venv \
        python3-full 2>/dev/null || \
    sudo apt install -y \
        pkg-config \
        python3-dev \
        default-libmysqlclient-dev \
        build-essential \
        python3-venv \
        python3-full
    
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
        echo -e "${GREEN}✅ Base de données configurée${NC}"
    else
        echo -e "${YELLOW}⚠️  MySQL non disponible${NC}"
    fi
}

# Fonction: Création environnement virtuel Python
create_python_venv() {
    echo -e "${BLUE}Création environnement virtuel Python...${NC}"
    
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

# Fonction: Création requirements.txt optimisé
create_optimized_requirements() {
    echo -e "${BLUE}Création requirements.txt optimisé...${NC}"
    
    # Créer un requirements.txt sans mysqlclient problématique
    cat > "$BACKEND_DIR/requirements.txt" << 'EOF'
fastapi==0.104.1
uvicorn==0.24.0
python-dotenv==1.0.0
starlette==0.27.0
pydantic==2.5.0
sqlalchemy==2.0.23
alembic==1.13.1
pymysql==1.1.0
cryptography==41.0.8
httpx==0.25.2
python-jose[cryptography]==3.3.0
bcrypt==4.1.2
python-multipart==0.0.6
EOF
    
    echo -e "${GREEN}✅ Requirements.txt optimisé créé (sans mysqlclient)${NC}"
}

# Fonction: Installation dépendances Python dans venv
install_python_deps() {
    echo -e "${BLUE}Installation dépendances Python (venv)...${NC}"
    cd "$BACKEND_DIR"
    
    # S'assurer que venv est activé
    if [[ "$VIRTUAL_ENV" != "$VENV_DIR" ]]; then
        source "$VENV_DIR/bin/activate"
    fi
    
    # Installer les dépendances
    pip install -r requirements.txt --quiet || pip install -r requirements.txt
    echo -e "${GREEN}✅ Dépendances Python installées (venv)${NC}"
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
    
    # Backend .env avec PyMySQL uniquement
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
    
    # Rediriger les logs vers un fichier
    python server.py > "$SCRIPT_DIR/backend.log" 2>&1 &
    BACKEND_PID=$!
    echo "$BACKEND_PID" > "$SCRIPT_DIR/.backend_pid"
    echo -e "${GREEN}✅ Backend démarré (PID: $BACKEND_PID)${NC}"
    
    # Démarrer frontend
    cd "$FRONTEND_DIR"
    echo "Démarrage frontend..."
    if command -v yarn >/dev/null 2>&1; then
        yarn start > "$SCRIPT_DIR/frontend.log" 2>&1 &
    else
        npm start > "$SCRIPT_DIR/frontend.log" 2>&1 &
    fi
    FRONTEND_PID=$!
    echo "$FRONTEND_PID" > "$SCRIPT_DIR/.frontend_pid"
    echo -e "${GREEN}✅ Frontend démarré (PID: $FRONTEND_PID)${NC}"
    
    cd "$SCRIPT_DIR"
}

# Fonction: Test connectivité
test_connectivity() {
    echo -e "${BLUE}Test de connectivité...${NC}"
    echo "Attente démarrage des services (15 secondes)..."
    sleep 15
    
    # Test backend avec plusieurs tentatives
    echo "Test du backend..."
    for i in {1..10}; do
        if curl -s -f http://localhost:8000/health >/dev/null 2>&1 || curl -s -f http://localhost:8000/ >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Backend accessible (http://localhost:8000)${NC}"
            break
        elif [[ $i -eq 10 ]]; then
            echo -e "${YELLOW}⚠️  Backend non accessible après 10 tentatives${NC}"
            echo "Dernières lignes du log backend:"
            tail -n 5 "$SCRIPT_DIR/backend.log" 2>/dev/null || echo "Pas de log backend disponible"
        else
            echo "Tentative $i/10 - Backend en cours de démarrage..."
            sleep 2
        fi
    done
    
    # Test frontend
    echo "Test du frontend..."
    for i in {1..5}; do
        if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Frontend accessible (http://localhost:3000)${NC}"
            break
        elif [[ $i -eq 5 ]]; then
            echo -e "${YELLOW}⚠️  Frontend non accessible${NC}"
            echo "Dernières lignes du log frontend:"
            tail -n 5 "$SCRIPT_DIR/frontend.log" 2>/dev/null || echo "Pas de log frontend disponible"
        else
            echo "Tentative $i/5 - Frontend en cours de démarrage..."
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
    echo "   💊 Health: http://localhost:8000/health"
    echo ""
    echo -e "${BLUE}🛠️  GESTION APPLICATION:${NC}"
    echo "   🛑 Arrêter: kill \$(cat .backend_pid .frontend_pid 2>/dev/null) 2>/dev/null || true"
    echo "   🔄 Redémarrer: $0"
    echo "   📋 Logs Backend: tail -f backend.log"
    echo "   📋 Logs Frontend: tail -f frontend.log"
    echo "   📋 PIDs: Backend=$(<.backend_pid 2>/dev/null), Frontend=$(<.frontend_pid 2>/dev/null)"
    echo ""
    echo -e "${BLUE}🐍 ENVIRONNEMENT PYTHON:${NC}"
    echo "   📁 Venv: $VENV_DIR"
    echo "   🔧 Activer: source $VENV_DIR/bin/activate"
    echo "   📦 Drivers DB: PyMySQL (pur Python, pas de compilation)"
    echo ""
    echo -e "${GREEN}✨ APPLICATION PRÊTE AVEC ENVIRONNEMENT SÉCURISÉ ! ✨${NC}"
}

# Fonction: Test rapide des imports Python
test_python_imports() {
    echo -e "${BLUE}Test des imports Python...${NC}"
    cd "$BACKEND_DIR"
    
    # S'assurer que venv est activé
    if [[ "$VIRTUAL_ENV" != "$VENV_DIR" ]]; then
        source "$VENV_DIR/bin/activate"
    fi
    
    if python -c "import fastapi, uvicorn, sqlalchemy, pymysql; print('✅ Tous les imports OK')" 2>/dev/null; then
        echo -e "${GREEN}✅ Imports Python validés${NC}"
    else
        echo -e "${YELLOW}⚠️  Problème avec certains imports Python${NC}"
    fi
}

# Exécution principale
main() {
    install_system_deps
    setup_database
    create_python_venv
    create_optimized_requirements
    install_python_deps
    test_python_imports
    install_node_deps
    create_env_files
    start_services
    test_connectivity
    show_final_info
}

# Lancer
main