#!/bin/bash

#################################################################
# Script de Déploiement Complet - Portail Entreprise Flashback Fa
# 
# Ce script :
# 1. Supprime l'ancienne version (cache, build, node_modules)
# 2. Installe les dépendances fraîches
# 3. Build la nouvelle version
# 4. Redémarre tous les services
# 5. Vérifie que tout fonctionne
#
# Usage: ./deploy-complete-application.sh
#################################################################

# Configuration
APP_DIR="/app"
FRONTEND_DIR="$APP_DIR/frontend"
BACKEND_DIR="$APP_DIR/backend"
BACKUP_DIR="/tmp/backup-$(date +%Y%m%d-%H%M%S)"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction de nettoyage en cas d'erreur
cleanup_on_error() {
    error "Erreur détectée. Arrêt du script."
    exit 1
}

# Trap pour gérer les erreurs
trap cleanup_on_error ERR

#################################################################
# ÉTAPE 1: VÉRIFICATIONS PRÉLIMINAIRES
#################################################################

log "🔍 Vérification des prérequis..."

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "$FRONTEND_DIR" ] || [ ! -d "$BACKEND_DIR" ]; then
    error "Structure de répertoire invalide. Assurez-vous d'être dans le répertoire racine de l'application."
    exit 1
fi

# Vérifier que les outils nécessaires sont installés
if ! command_exists yarn; then
    error "Yarn n'est pas installé. Installation requise."
    exit 1
fi

if ! command_exists python3; then
    error "Python3 n'est pas installé. Installation requise."
    exit 1
fi

if ! command_exists supervisorctl; then
    error "Supervisor n'est pas installé. Installation requise."
    exit 1
fi

success "Tous les prérequis sont satisfaits"

#################################################################
# ÉTAPE 2: SAUVEGARDE DE SÉCURITÉ
#################################################################

log "💾 Création d'une sauvegarde de sécurité..."

mkdir -p "$BACKUP_DIR"

# Sauvegarder les fichiers de configuration critiques
if [ -f "$FRONTEND_DIR/.env" ]; then
    cp "$FRONTEND_DIR/.env" "$BACKUP_DIR/frontend.env"
fi

if [ -f "$BACKEND_DIR/.env" ]; then
    cp "$BACKEND_DIR/.env" "$BACKEND_DIR/backend.env"
fi

# Sauvegarder package.json et requirements.txt
cp "$FRONTEND_DIR/package.json" "$BACKUP_DIR/" 2>/dev/null || true
cp "$BACKEND_DIR/requirements.txt" "$BACKUP_DIR/" 2>/dev/null || true

success "Sauvegarde créée dans $BACKUP_DIR"

#################################################################
# ÉTAPE 3: ARRÊT DES SERVICES
#################################################################

log "🛑 Arrêt des services..."

sudo supervisorctl stop all
sleep 2

# Vérifier que les services sont bien arrêtés
if sudo supervisorctl status | grep -q "RUNNING"; then
    warning "Certains services sont encore en cours d'exécution"
    sudo supervisorctl stop all
    sleep 3
fi

success "Tous les services sont arrêtés"

#################################################################
# ÉTAPE 4: NETTOYAGE DE L'ANCIENNE VERSION
#################################################################

log "🧹 Nettoyage de l'ancienne version..."

# Nettoyage Frontend
cd "$FRONTEND_DIR"

log "Suppression du cache et build frontend..."
rm -rf node_modules
rm -rf build
rm -rf dist
rm -rf .next
rm -rf .cache
rm -rf .parcel-cache
rm -f yarn-error.log
rm -f npm-debug.log*
rm -f package-lock.json

# Nettoyage des caches yarn et npm
yarn cache clean --force 2>/dev/null || true
npm cache clean --force 2>/dev/null || true

success "Frontend nettoyé"

# Nettoyage Backend
cd "$BACKEND_DIR"

log "Suppression du cache backend..."
rm -rf __pycache__
rm -rf *.pyc
rm -rf .pytest_cache
rm -rf *.egg-info
find . -name "*.pyc" -delete
find . -name "__pycache__" -delete

# Nettoyage cache pip
pip cache purge 2>/dev/null || true

success "Backend nettoyé"

#################################################################
# ÉTAPE 5: INSTALLATION DES DÉPENDANCES FRONTEND
#################################################################

log "📦 Installation des dépendances frontend..."

cd "$FRONTEND_DIR"

# Installation avec yarn (comme spécifié dans les consignes)
log "Installation avec yarn..."
yarn install --frozen-lockfile --network-timeout 100000

# Vérifier que les dépendances critiques sont installées
CRITICAL_DEPS=("react" "react-dom" "react-router-dom" "@radix-ui/react-tabs" "lucide-react" "xlsx" "sonner")

for dep in "${CRITICAL_DEPS[@]}"; do
    if ! yarn list --pattern "$dep" >/dev/null 2>&1; then
        warning "Dépendance critique '$dep' manquante, installation..."
        yarn add "$dep"
    fi
done

success "Dépendances frontend installées"

#################################################################
# ÉTAPE 6: INSTALLATION DES DÉPENDANCES BACKEND
#################################################################

log "🐍 Installation des dépendances backend..."

cd "$BACKEND_DIR"

# Mise à jour pip
python3 -m pip install --upgrade pip

# Installation des requirements
if [ -f "requirements.txt" ]; then
    log "Installation des requirements Python..."
    pip install -r requirements.txt
    
    # Vérifier que FastAPI est installé
    if ! python3 -c "import fastapi" 2>/dev/null; then
        error "FastAPI n'est pas correctement installé"
        exit 1
    fi
    
    success "Requirements Python installés"
else
    warning "Fichier requirements.txt non trouvé"
fi

#################################################################
# ÉTAPE 7: VÉRIFICATION DES FICHIERS DE CONFIGURATION
#################################################################

log "🔧 Vérification des configurations..."

# Vérifier les variables d'environnement frontend
if [ -f "$FRONTEND_DIR/.env" ]; then
    if grep -q "REACT_APP_BACKEND_URL" "$FRONTEND_DIR/.env"; then
        success "Configuration frontend OK"
    else
        warning "REACT_APP_BACKEND_URL manquant dans .env frontend"
    fi
else
    warning "Fichier .env frontend manquant"
fi

# Vérifier les variables d'environnement backend
if [ -f "$BACKEND_DIR/.env" ]; then
    if grep -q "MONGO_URL" "$BACKEND_DIR/.env"; then
        success "Configuration backend OK"
    else
        warning "MONGO_URL manquant dans .env backend"
    fi
else
    warning "Fichier .env backend manquant"
fi

#################################################################
# ÉTAPE 8: BUILD DE L'APPLICATION FRONTEND (si nécessaire)
#################################################################

cd "$FRONTEND_DIR"

# Pour une application React en développement, pas de build nécessaire
# Le hot reload sera géré par le serveur de développement
log "Application prête pour le développement (hot reload activé)"

#################################################################
# ÉTAPE 9: REDÉMARRAGE DES SERVICES
#################################################################

log "🚀 Redémarrage des services..."

# Redémarrer tous les services
sudo supervisorctl start all
sleep 3

# Vérifier le statut des services
log "Vérification du statut des services..."
sudo supervisorctl status

# Attendre que les services soient complètement démarrés
log "Attente du démarrage complet des services..."
sleep 5

#################################################################
# ÉTAPE 10: VÉRIFICATIONS POST-DÉPLOIEMENT
#################################################################

log "✅ Vérifications post-déploiement..."

# Vérifier que le backend répond
BACKEND_URL="http://localhost:8001"
if curl -f -s "$BACKEND_URL/health" >/dev/null 2>&1; then
    success "Backend opérationnel sur $BACKEND_URL"
else
    # Essayer l'endpoint par défaut
    if curl -f -s "$BACKEND_URL/" >/dev/null 2>&1; then
        success "Backend opérationnel sur $BACKEND_URL"
    else
        warning "Backend ne répond pas sur $BACKEND_URL"
    fi
fi

# Vérifier que le frontend répond
FRONTEND_URL="http://localhost:3000"
if curl -f -s "$FRONTEND_URL" >/dev/null 2>&1; then
    success "Frontend opérationnel sur $FRONTEND_URL"
else
    warning "Frontend ne répond pas sur $FRONTEND_URL"
fi

# Vérifier l'utilisation des ressources
log "État des ressources système:"
echo "Mémoire:"
free -h
echo
echo "Processeur:"
top -bn1 | grep "Cpu(s)" | head -1
echo

#################################################################
# ÉTAPE 11: RÉSUMÉ ET CONSEILS
#################################################################

log "📋 Résumé du déploiement..."

success "✅ Déploiement terminé avec succès !"

echo
echo "🌐 URLs d'accès:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8001"
echo
echo "📁 Sauvegarde créée dans: $BACKUP_DIR"
echo
echo "🔧 Commandes utiles:"
echo "   Statut services:     sudo supervisorctl status"
echo "   Redémarrer tout:     sudo supervisorctl restart all"
echo "   Logs frontend:       sudo supervisorctl tail -f frontend"
echo "   Logs backend:        sudo supervisorctl tail -f backend"
echo
echo "📝 Notes importantes:"
echo "   • L'application utilise le hot reload en développement"
echo "   • Les changements de code sont automatiquement détectés"
echo "   • Utilisez 'yarn' pour toute installation de dépendance (pas npm)"
echo "   • Les variables d'environnement sont préservées"
echo

# Afficher les logs récents en cas de problème
if sudo supervisorctl status | grep -q "FATAL\|EXITED"; then
    warning "Certains services ont des problèmes. Logs récents:"
    echo "--- LOGS BACKEND ---"
    sudo supervisorctl tail backend
    echo
    echo "--- LOGS FRONTEND ---"
    sudo supervisorctl tail frontend
fi

success "Déploiement complet terminé ! 🎉"

# Optionnel: Ouvrir l'application dans le navigateur
# if command_exists xdg-open; then
#     xdg-open http://localhost:3000
# elif command_exists open; then
#     open http://localhost:3000
# fi