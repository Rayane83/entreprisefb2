#!/bin/bash

# 🔍 DIAGNOSTIC COMPLET - Identifier tous les problèmes

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}🔍 DIAGNOSTIC COMPLET - FLASHBACK FA ENTREPRISE${NC}"
echo "================================================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
VENV_DIR="$SCRIPT_DIR/venv"

# Fonction: Diagnostic système
diagnostic_system() {
    echo -e "${BLUE}📊 DIAGNOSTIC SYSTÈME${NC}"
    echo "Répertoire courant: $SCRIPT_DIR"
    echo "Utilisateur: $(whoami)"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Python: $(python3 --version)"
    echo "Node: $(node --version 2>/dev/null || echo 'Non installé')"
    echo "Yarn: $(yarn --version 2>/dev/null || echo 'Non installé')"
    echo "NPM: $(npm --version 2>/dev/null || echo 'Non installé')"
    echo ""
}

# Fonction: Diagnostic structure fichiers
diagnostic_structure() {
    echo -e "${BLUE}📁 DIAGNOSTIC STRUCTURE FICHIERS${NC}"
    
    echo "Structure du projet:"
    ls -la "$SCRIPT_DIR" | head -20
    echo ""
    
    echo "Backend directory:"
    if [[ -d "$BACKEND_DIR" ]]; then
        echo "✅ $BACKEND_DIR existe"
        echo "Contenu:"
        ls -la "$BACKEND_DIR" | head -10
        
        # Vérifier fichiers critiques
        [[ -f "$BACKEND_DIR/server.py" ]] && echo "✅ server.py présent" || echo "❌ server.py manquant"
        [[ -f "$BACKEND_DIR/.env" ]] && echo "✅ .env présent" || echo "❌ .env manquant"
        [[ -f "$BACKEND_DIR/requirements.txt" ]] && echo "✅ requirements.txt présent" || echo "❌ requirements.txt manquant"
    else
        echo "❌ $BACKEND_DIR n'existe pas"
    fi
    echo ""
    
    echo "Frontend directory:"
    if [[ -d "$FRONTEND_DIR" ]]; then
        echo "✅ $FRONTEND_DIR existe"
        echo "Contenu:"
        ls -la "$FRONTEND_DIR" | head -10
        
        [[ -f "$FRONTEND_DIR/package.json" ]] && echo "✅ package.json présent" || echo "❌ package.json manquant"
        [[ -f "$FRONTEND_DIR/.env" ]] && echo "✅ .env présent" || echo "❌ .env manquant"
        [[ -d "$FRONTEND_DIR/node_modules" ]] && echo "✅ node_modules présent" || echo "❌ node_modules manquant"
    else
        echo "❌ $FRONTEND_DIR n'existe pas"
    fi
    echo ""
    
    echo "Environnement virtuel:"
    if [[ -d "$VENV_DIR" ]]; then
        echo "✅ $VENV_DIR existe"
        [[ -f "$VENV_DIR/bin/activate" ]] && echo "✅ activate script présent" || echo "❌ activate script manquant"
        [[ -f "$VENV_DIR/bin/python" ]] && echo "✅ python venv présent" || echo "❌ python venv manquant"
    else
        echo "❌ $VENV_DIR n'existe pas"
    fi
    echo ""
}

# Fonction: Diagnostic environnement virtuel Python
diagnostic_python_venv() {
    echo -e "${BLUE}🐍 DIAGNOSTIC ENVIRONNEMENT VIRTUEL PYTHON${NC}"
    
    if [[ -d "$VENV_DIR" ]]; then
        echo "Activation de l'environnement virtuel..."
        if source "$VENV_DIR/bin/activate" 2>/dev/null; then
            echo "✅ Environnement virtuel activé"
            echo "Python venv: $(which python)"
            echo "Pip venv: $(which pip)"
            echo ""
            
            echo "Packages installés dans le venv:"
            pip list | head -20
            echo ""
            
            echo "Test des imports critiques:"
            python -c "
try:
    import fastapi
    print('✅ FastAPI:', fastapi.__version__)
except ImportError as e:
    print('❌ FastAPI:', e)

try:
    import uvicorn
    print('✅ Uvicorn:', uvicorn.__version__)
except ImportError as e:
    print('❌ Uvicorn:', e)

try:
    import sqlalchemy
    print('✅ SQLAlchemy:', sqlalchemy.__version__)
except ImportError as e:
    print('❌ SQLAlchemy:', e)

try:
    import pymysql
    print('✅ PyMySQL:', pymysql.__version__)
except ImportError as e:
    print('❌ PyMySQL:', e)
" 2>/dev/null || echo "❌ Erreur lors des tests d'import"
            
        else
            echo "❌ Impossible d'activer l'environnement virtuel"
        fi
    else
        echo "❌ Environnement virtuel non trouvé"
    fi
    echo ""
}

# Fonction: Diagnostic base de données
diagnostic_database() {
    echo -e "${BLUE}🗄️  DIAGNOSTIC BASE DE DONNÉES${NC}"
    
    # Test MySQL
    if command -v mysql >/dev/null 2>&1; then
        echo "✅ MySQL installé: $(mysql --version)"
        
        # Test connexion root
        if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
            echo "✅ Connexion MySQL root OK"
            
            # Test base de données
            if mysql -u root -e "USE flashback_fa_enterprise; SELECT 1;" >/dev/null 2>&1; then
                echo "✅ Base flashback_fa_enterprise existe"
            else
                echo "❌ Base flashback_fa_enterprise n'existe pas"
            fi
            
            # Test utilisateur flashback
            if mysql -u flashback_user -pFlashbackFA_2024! -e "SELECT 1;" >/dev/null 2>&1; then
                echo "✅ Utilisateur flashback_user OK"
            else
                echo "❌ Utilisateur flashback_user problème"
            fi
            
        else
            echo "❌ Connexion MySQL root échoue"
        fi
    else
        echo "❌ MySQL non installé"
    fi
    echo ""
}

# Fonction: Diagnostic fichiers de configuration
diagnostic_config() {
    echo -e "${BLUE}⚙️  DIAGNOSTIC CONFIGURATION${NC}"
    
    # Backend .env
    if [[ -f "$BACKEND_DIR/.env" ]]; then
        echo "✅ Backend .env existe"
        echo "Contenu (sans secrets):"
        grep -E "^(DATABASE_URL|API_HOST|API_PORT|CORS_ORIGINS)" "$BACKEND_DIR/.env" | head -5
    else
        echo "❌ Backend .env manquant"
    fi
    echo ""
    
    # Frontend .env
    if [[ -f "$FRONTEND_DIR/.env" ]]; then
        echo "✅ Frontend .env existe"
        echo "Contenu (sans secrets):"
        grep -E "^REACT_APP_" "$FRONTEND_DIR/.env" | head -5
    else
        echo "❌ Frontend .env manquant"
    fi
    echo ""
}

# Fonction: Test démarrage backend manuel
test_backend_manual() {
    echo -e "${BLUE}🔧 TEST DÉMARRAGE BACKEND MANUEL${NC}"
    
    cd "$BACKEND_DIR"
    
    if [[ -d "$VENV_DIR" ]] && source "$VENV_DIR/bin/activate" 2>/dev/null; then
        echo "✅ Environnement virtuel activé"
        
        if [[ -f "server.py" ]]; then
            echo "Test du démarrage backend (5 secondes)..."
            timeout 5s python server.py &
            SERVER_PID=$!
            sleep 2
            
            # Tester si le serveur répond
            if curl -s http://localhost:8000/ >/dev/null 2>&1; then
                echo "✅ Backend démarre et répond"
            elif curl -s http://localhost:8000/health >/dev/null 2>&1; then
                echo "✅ Backend démarre (health endpoint)"
            else
                echo "❌ Backend ne répond pas"
                echo "Erreurs possibles:"
                python server.py 2>&1 | head -10 &
                sleep 2
            fi
            
            # Nettoyer
            kill $SERVER_PID 2>/dev/null || true
            pkill -f "python.*server.py" 2>/dev/null || true
        else
            echo "❌ server.py non trouvé"
        fi
    else
        echo "❌ Impossible d'activer l'environnement virtuel"
    fi
    
    cd "$SCRIPT_DIR"
    echo ""
}

# Fonction: Diagnostic logs existants
diagnostic_logs() {
    echo -e "${BLUE}📋 DIAGNOSTIC LOGS${NC}"
    
    # Backend logs
    if [[ -f "$SCRIPT_DIR/backend_production.log" ]]; then
        echo "Backend logs (20 dernières lignes):"
        tail -n 20 "$SCRIPT_DIR/backend_production.log"
    else
        echo "❌ Pas de logs backend trouvés"
    fi
    echo ""
    
    # Frontend logs
    if [[ -f "$SCRIPT_DIR/frontend_production.log" ]]; then
        echo "Frontend logs (10 dernières lignes):"
        tail -n 10 "$SCRIPT_DIR/frontend_production.log"
    else
        echo "❌ Pas de logs frontend trouvés"
    fi
    echo ""
    
    # Nginx logs
    if [[ -f "/var/log/nginx/error.log" ]]; then
        echo "Nginx error logs (10 dernières lignes):"
        sudo tail -n 10 /var/log/nginx/error.log
    fi
    echo ""
}

# Fonction: Diagnostic processus actifs
diagnostic_processes() {
    echo -e "${BLUE}⚡ DIAGNOSTIC PROCESSUS${NC}"
    
    echo "Processus Python actifs:"
    ps aux | grep python | grep -v grep || echo "Aucun processus Python"
    echo ""
    
    echo "Processus Node actifs:"
    ps aux | grep node | grep -v grep || echo "Aucun processus Node"
    echo ""
    
    echo "Ports ouverts (3000, 8000, 80, 443):"
    sudo netstat -tlnp 2>/dev/null | grep -E ":(3000|8000|80|443)" || echo "Aucun port trouvé"
    echo ""
    
    # PIDs sauvegardés
    if [[ -f "$SCRIPT_DIR/.backend_pid" ]]; then
        SAVED_BACKEND_PID=$(cat "$SCRIPT_DIR/.backend_pid")
        if kill -0 "$SAVED_BACKEND_PID" 2>/dev/null; then
            echo "✅ Backend PID $SAVED_BACKEND_PID actif"
        else
            echo "❌ Backend PID $SAVED_BACKEND_PID mort"
        fi
    fi
    
    if [[ -f "$SCRIPT_DIR/.frontend_pid" ]]; then
        SAVED_FRONTEND_PID=$(cat "$SCRIPT_DIR/.frontend_pid")
        if kill -0 "$SAVED_FRONTEND_PID" 2>/dev/null; then
            echo "✅ Frontend PID $SAVED_FRONTEND_PID actif"
        else
            echo "❌ Frontend PID $SAVED_FRONTEND_PID mort"
        fi
    fi
    echo ""
}

# Fonction: Recommandations basées sur le diagnostic
generate_recommendations() {
    echo -e "${RED}🎯 RECOMMANDATIONS${NC}"
    echo "================================================================"
    
    # Analyser et recommander
    echo "Basé sur le diagnostic ci-dessus, voici les actions recommandées:"
    echo ""
    
    if [[ ! -f "$BACKEND_DIR/server.py" ]]; then
        echo "🔴 CRITIQUE: server.py manquant - Recréer le fichier backend"
    fi
    
    if [[ ! -d "$VENV_DIR" ]]; then
        echo "🔴 CRITIQUE: Environnement virtuel manquant - Recréer le venv"
    fi
    
    if [[ ! -f "$BACKEND_DIR/.env" ]]; then
        echo "🔴 CRITIQUE: Configuration backend manquante - Recréer .env"
    fi
    
    echo ""
    echo "🔧 Actions recommandées:"
    echo "1. Vérifier la structure de fichiers manquante"
    echo "2. Recréer l'environnement virtuel si corrompu"
    echo "3. Réinstaller les dépendances Python"
    echo "4. Tester le démarrage manuel du backend"
    echo "5. Analyser les logs d'erreur"
    echo ""
}

# Fonction principale
main() {
    diagnostic_system
    diagnostic_structure
    diagnostic_python_venv
    diagnostic_database
    diagnostic_config
    test_backend_manual
    diagnostic_logs
    diagnostic_processes
    generate_recommendations
    
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}DIAGNOSTIC TERMINÉ - Analysez les résultats ci-dessus${NC}"
    echo -e "${GREEN}================================================================${NC}"
}

# Lancer le diagnostic
main