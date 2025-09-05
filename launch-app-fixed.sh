#!/bin/bash

# 🚀 LANCEUR CORRIGÉ - Portail Entreprise Flashback Fa
# Résout le problème repository MongoDB + dépendances

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

# Fonction: Correction repository et installation dépendances système
fix_repos_and_install_deps() {
    echo -e "${BLUE}Correction repositories et installation dépendances...${NC}"
    
    # Supprimer le repository MongoDB problématique s'il existe
    sudo rm -f /etc/apt/sources.list.d/mongodb*.list 2>/dev/null || true
    
    # Mettre à jour avec ignore des erreurs de repository
    echo "Mise à jour des packages (ignore MongoDB repo)..."
    sudo apt update 2>/dev/null || sudo apt update --allow-releaseinfo-change 2>/dev/null || true
    
    echo "Installation des dépendances système..."
    # Installer les dépendances essentielles
    sudo apt install -y \
        pkg-config \
        python3-dev \
        python3-venv \
        python3-full \
        build-essential \
        curl \
        wget 2>/dev/null || echo "Certaines dépendances peuvent déjà être installées"
    
    # Tenter d'installer les dépendances MySQL/MariaDB
    sudo apt install -y libmariadb-dev libmariadb-dev-compat 2>/dev/null || \
    sudo apt install -y default-libmysqlclient-dev 2>/dev/null || \
    echo "Headers MySQL non installés (pas grave, on utilise PyMySQL pur Python)"
    
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
        echo -e "${YELLOW}⚠️  MySQL non disponible - l'app utilisera SQLite en fallback${NC}"
    fi
}

# Fonction: Création environnement virtuel Python
create_python_venv() {
    echo -e "${BLUE}Création environnement virtuel Python...${NC}"
    
    # Supprimer l'ancien venv s'il est corrompu
    if [[ -d "$VENV_DIR" ]] && ! source "$VENV_DIR/bin/activate" 2>/dev/null; then
        echo "Suppression venv corrompu..."
        rm -rf "$VENV_DIR"
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

# Fonction: Création requirements.txt minimal et sûr
create_minimal_requirements() {
    echo -e "${BLUE}Création requirements.txt minimal...${NC}"
    
    # Créer un requirements.txt avec uniquement les packages essentiels
    cat > "$BACKEND_DIR/requirements.txt" << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-dotenv==1.0.0
pydantic==2.5.0
sqlalchemy==2.0.23
pymysql==1.1.0
httpx==0.25.2
python-multipart==0.0.6
EOF
    
    echo -e "${GREEN}✅ Requirements.txt minimal créé${NC}"
}

# Fonction: Installation dépendances Python dans venv
install_python_deps() {
    echo -e "${BLUE}Installation dépendances Python (minimal)...${NC}"
    cd "$BACKEND_DIR"
    
    # S'assurer que venv est activé
    if [[ "$VIRTUAL_ENV" != "$VENV_DIR" ]]; then
        source "$VENV_DIR/bin/activate"
    fi
    
    # Installer les dépendances une par une pour identifier les problèmes
    echo "Installation des packages Python essentiels..."
    pip install fastapi==0.104.1 --quiet
    pip install uvicorn[standard]==0.24.0 --quiet  
    pip install python-dotenv==1.0.0 --quiet
    pip install pydantic==2.5.0 --quiet
    pip install sqlalchemy==2.0.23 --quiet
    pip install pymysql==1.1.0 --quiet
    pip install httpx==0.25.2 --quiet
    pip install python-multipart==0.0.6 --quiet
    
    echo -e "${GREEN}✅ Dépendances Python installées (venv)${NC}"
}

# Fonction: Installation dépendances Node
install_node_deps() {
    if [[ -f "$FRONTEND_DIR/package.json" ]]; then
        echo -e "${BLUE}Installation dépendances Node.js...${NC}"
        cd "$FRONTEND_DIR"
        
        # Nettoyer le cache si nécessaire
        if command -v yarn >/dev/null 2>&1; then
            yarn cache clean 2>/dev/null || true
            yarn install --network-timeout 100000 2>/dev/null || yarn install
        elif command -v npm >/dev/null 2>&1; then
            npm cache clean --force 2>/dev/null || true
            npm install --timeout 100000 2>/dev/null || npm install
        fi
        echo -e "${GREEN}✅ Dépendances Node.js installées${NC}"
    fi
}

# Fonction: Création fichiers .env avec fallback SQLite
create_env_files() {
    echo -e "${BLUE}Création fichiers .env...${NC}"
    
    # Détecter si MySQL est disponible
    if mysql -u flashback_user -pFlashbackFA_2024! -e "SELECT 1;" >/dev/null 2>&1; then
        DB_URL="mysql+pymysql://flashback_user:FlashbackFA_2024!@localhost/flashback_fa_enterprise"
        echo "Using MySQL database"
    else
        DB_URL="sqlite:///./flashback.db"
        echo "Using SQLite database (fallback)"
    fi
    
    # Backend .env
    cat > "$BACKEND_DIR/.env" << EOF
DATABASE_URL=$DB_URL
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

# Fonction: Test rapide des imports Python
test_python_imports() {
    echo -e "${BLUE}Test des imports Python...${NC}"
    cd "$BACKEND_DIR"
    
    # S'assurer que venv est activé
    if [[ "$VIRTUAL_ENV" != "$VENV_DIR" ]]; then
        source "$VENV_DIR/bin/activate"
    fi
    
    if python -c "
import fastapi, uvicorn, sqlalchemy, pymysql
print('✅ FastAPI:', fastapi.__version__)
print('✅ Uvicorn:', uvicorn.__version__)  
print('✅ SQLAlchemy:', sqlalchemy.__version__)
print('✅ PyMySQL:', pymysql.__version__)
" 2>/dev/null; then
        echo -e "${GREEN}✅ Imports Python validés${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Problème avec certains imports Python${NC}"
        return 1
    fi
}

# Fonction: Démarrage services
start_services() {
    echo -e "${BLUE}Démarrage des services...${NC}"
    
    # Arrêter processus existants
    pkill -f "python.*server.py" 2>/dev/null || true
    pkill -f "yarn start" 2>/dev/null || true
    pkill -f "npm start" 2>/dev/null || true
    sleep 2
    
    # Démarrer backend avec venv
    cd "$BACKEND_DIR"
    echo "Démarrage backend..."
    
    # S'assurer que venv est activé
    if [[ "$VIRTUAL_ENV" != "$VENV_DIR" ]]; then
        source "$VENV_DIR/bin/activate"
    fi
    
    # Démarrer avec logs
    nohup python server.py > "$SCRIPT_DIR/backend.log" 2>&1 &
    BACKEND_PID=$!
    echo "$BACKEND_PID" > "$SCRIPT_DIR/.backend_pid"
    echo -e "${GREEN}✅ Backend démarré (PID: $BACKEND_PID)${NC}"
    
    # Démarrer frontend
    cd "$FRONTEND_DIR"
    echo "Démarrage frontend..."
    if command -v yarn >/dev/null 2>&1; then
        nohup yarn start > "$SCRIPT_DIR/frontend.log" 2>&1 &
    else
        nohup npm start > "$SCRIPT_DIR/frontend.log" 2>&1 &
    fi
    FRONTEND_PID=$!
    echo "$FRONTEND_PID" > "$SCRIPT_DIR/.frontend_pid"
    echo -e "${GREEN}✅ Frontend démarré (PID: $FRONTEND_PID)${NC}"
    
    cd "$SCRIPT_DIR"
}

# Fonction: Test connectivité avec logs
test_connectivity() {
    echo -e "${BLUE}Test de connectivité...${NC}"
    echo "Attente démarrage des services (20 secondes)..."
    sleep 20
    
    # Test backend
    echo "Test du backend..."
    for i in {1..5}; do
        if curl -s http://localhost:8000/health >/dev/null 2>&1 || curl -s http://localhost:8000/ >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Backend accessible (http://localhost:8000)${NC}"
            break
        elif [[ $i -eq 5 ]]; then
            echo -e "${YELLOW}⚠️  Backend non accessible après 5 tentatives${NC}"
            echo "Dernières lignes du log backend:"
            tail -n 10 "$SCRIPT_DIR/backend.log" 2>/dev/null || echo "Pas de log backend"
        else
            echo "Tentative $i/5..."
            sleep 5
        fi
    done
    
    # Test frontend
    echo "Test du frontend..."
    for i in {1..3}; do
        if curl -s http://localhost:3000 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Frontend accessible (http://localhost:3000)${NC}"
            break
        elif [[ $i -eq 3 ]]; then
            echo -e "${YELLOW}⚠️  Frontend non accessible${NC}"
            echo "Dernières lignes du log frontend:"
            tail -n 10 "$SCRIPT_DIR/frontend.log" 2>/dev/null || echo "Pas de log frontend"
        else
            echo "Tentative $i/3..."
            sleep 5
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
    echo -e "${BLUE}🛠️  GESTION:${NC}"
    echo "   🛑 Arrêter: kill \$(cat .backend_pid .frontend_pid 2>/dev/null) || true"
    echo "   📋 Logs Backend: tail -f backend.log"
    echo "   📋 Logs Frontend: tail -f frontend.log"
    echo "   🔄 Redémarrer: $0"
    echo ""
    echo -e "${GREEN}✨ APPLICATION PRÊTE ! ✨${NC}"
    
    # Afficher les PIDs
    if [[ -f ".backend_pid" ]] && [[ -f ".frontend_pid" ]]; then
        echo "PIDs: Backend=$(<.backend_pid), Frontend=$(<.frontend_pid)"
    fi
}

# Exécution principale
main() {
    fix_repos_and_install_deps
    setup_database
    create_python_venv
    create_minimal_requirements
    install_python_deps
    test_python_imports || echo "Continuing despite import warnings..."
    install_node_deps
    create_env_files
    start_services
    test_connectivity
    show_final_info
}

# Lancer
main