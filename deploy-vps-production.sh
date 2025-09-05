#!/bin/bash

#################################################################
# Script de Déploiement VPS Production - Portail Entreprise Flashback Fa
# 
# Domaine: flashbackfa-entreprise.fr
# Ce script :
# 1. Détecte l'environnement (local /app ou VPS ~/entreprisefb)
# 2. Supprime l'ancienne version (cache, build, node_modules)
# 3. Installe les dépendances fraîches
# 4. Configure pour la production
# 5. Redémarre tous les services (PM2 + Nginx)
# 6. Vérifie que tout fonctionne
#
# Usage: ./deploy-vps-production.sh
#################################################################

# Configuration
if [ -d "/app/frontend" ] && [ -d "/app/backend" ]; then
    # Environnement local emergent
    APP_DIR="/app"
    USE_SUPERVISOR=true
    DOMAIN="localhost"
elif [ -d "$HOME/entreprisefb/frontend" ] && [ -d "$HOME/entreprisefb/backend" ]; then
    # Environnement VPS
    APP_DIR="$HOME/entreprisefb"
    USE_SUPERVISOR=false
    DOMAIN="flashbackfa-entreprise.fr"
else
    echo "❌ Structure de répertoire non reconnue. Recherche de répertoires frontend et backend..."
    # Recherche automatique
    CURRENT_DIR=$(pwd)
    if [ -d "$CURRENT_DIR/frontend" ] && [ -d "$CURRENT_DIR/backend" ]; then
        APP_DIR="$CURRENT_DIR"
        USE_SUPERVISOR=false
        DOMAIN="flashbackfa-entreprise.fr"
        echo "✅ Structure trouvée dans: $APP_DIR"
    else
        echo "❌ Impossible de trouver les répertoires frontend et backend"
        echo "Veuillez exécuter ce script depuis le répertoire racine de l'application"
        exit 1
    fi
fi

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
# ÉTAPE 1: DÉTECTION ET VÉRIFICATIONS PRÉLIMINAIRES
#################################################################

log "🔍 Vérification de l'environnement..."
log "Répertoire détecté: $APP_DIR"
log "Domaine: $DOMAIN"
log "Type de service: $([ "$USE_SUPERVISOR" = true ] && echo "Supervisor (local)" || echo "PM2 (VPS)")"

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "$FRONTEND_DIR" ] || [ ! -d "$BACKEND_DIR" ]; then
    error "Structure de répertoire invalide pour $APP_DIR"
    error "Frontend: $FRONTEND_DIR $([ -d "$FRONTEND_DIR" ] && echo "✅" || echo "❌")"
    error "Backend: $BACKEND_DIR $([ -d "$BACKEND_DIR" ] && echo "✅" || echo "❌")"
    exit 1
fi

# Vérifier que les outils nécessaires sont installés
if ! command_exists yarn; then
    error "Yarn n'est pas installé. Installation requise."
    if command_exists npm; then
        warning "NPM détecté. Installation de yarn..."
        npm install -g yarn
    else
        exit 1
    fi
fi

if ! command_exists python3; then
    error "Python3 n'est pas installé. Installation requise."
    exit 1
fi

# Vérifier le gestionnaire de services
if [ "$USE_SUPERVISOR" = true ]; then
    if ! command_exists supervisorctl; then
        error "Supervisor n'est pas installé. Installation requise."
        exit 1
    fi
else
    if ! command_exists pm2; then
        warning "PM2 n'est pas installé. Installation..."
        npm install -g pm2
    fi
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
    cp "$BACKEND_DIR/.env" "$BACKUP_DIR/backend.env"
fi

# Sauvegarder package.json et requirements.txt
cp "$FRONTEND_DIR/package.json" "$BACKUP_DIR/" 2>/dev/null || true
cp "$BACKEND_DIR/requirements.txt" "$BACKUP_DIR/" 2>/dev/null || true

success "Sauvegarde créée dans $BACKUP_DIR"

#################################################################
# ÉTAPE 3: ARRÊT DES SERVICES
#################################################################

log "🛑 Arrêt des services..."

if [ "$USE_SUPERVISOR" = true ]; then
    sudo supervisorctl stop all
    sleep 2
else
    # Arrêt PM2
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    sleep 2
fi

success "Services arrêtés"

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

# Installation avec yarn
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
# ÉTAPE 7: CONFIGURATION POUR LA PRODUCTION
#################################################################

log "🔧 Configuration pour la production..."

# Configuration frontend
cd "$FRONTEND_DIR"

# Vérifier les variables d'environnement frontend
if [ -f ".env" ]; then
    if [ "$DOMAIN" != "localhost" ]; then
        # Mise à jour pour production si nécessaire
        if ! grep -q "REACT_APP_BACKEND_URL.*$DOMAIN" .env; then
            warning "Configuration domaine de production"
            # Backup avant modification
            cp .env .env.backup
            # Mise à jour du backend URL pour production
            sed -i "s|REACT_APP_BACKEND_URL=.*|REACT_APP_BACKEND_URL=https://$DOMAIN/api|g" .env || true
        fi
    fi
    success "Configuration frontend OK"
else
    warning "Fichier .env frontend manquant"
fi

# Configuration backend
cd "$BACKEND_DIR"
if [ -f ".env" ]; then
    success "Configuration backend OK"
else
    warning "Fichier .env backend manquant"
fi

#################################################################
# ÉTAPE 8: BUILD DE L'APPLICATION FRONTEND (si production)
#################################################################

cd "$FRONTEND_DIR"

if [ "$DOMAIN" != "localhost" ]; then
    log "🏗️ Build de l'application pour la production..."
    yarn build
    success "Build production créé"
else
    log "Mode développement - pas de build nécessaire"
fi

#################################################################
# ÉTAPE 9: REDÉMARRAGE DES SERVICES
#################################################################

log "🚀 Redémarrage des services..."

if [ "$USE_SUPERVISOR" = true ]; then
    # Redémarrer avec supervisor
    sudo supervisorctl start all
    sleep 3
    sudo supervisorctl status
else
    # Redémarrer avec PM2
    cd "$BACKEND_DIR"
    pm2 start --name "backend" "python3 server.py"
    
    cd "$FRONTEND_DIR"
    if [ "$DOMAIN" != "localhost" ]; then
        # Production: servir les fichiers statiques
        pm2 serve build 3000 --name "frontend"
    else
        # Développement: serveur de développement
        pm2 start --name "frontend" "yarn start"
    fi
    
    # Sauvegarder la configuration PM2
    pm2 save
    pm2 startup
fi

# Attendre que les services soient complètement démarrés
log "Attente du démarrage complet des services..."
sleep 5

#################################################################
# ÉTAPE 10: VÉRIFICATIONS POST-DÉPLOIEMENT
#################################################################

log "✅ Vérifications post-déploiement..."

# Vérifier que le backend répond
if [ "$DOMAIN" = "localhost" ]; then
    BACKEND_URL="http://localhost:8001"
    FRONTEND_URL="http://localhost:3000"
else
    BACKEND_URL="https://$DOMAIN/api"
    FRONTEND_URL="https://$DOMAIN"
fi

# Test backend
if curl -f -s "$BACKEND_URL/health" >/dev/null 2>&1; then
    success "Backend opérationnel sur $BACKEND_URL"
elif curl -f -s "$BACKEND_URL/" >/dev/null 2>&1; then
    success "Backend opérationnel sur $BACKEND_URL"
else
    warning "Backend ne répond pas sur $BACKEND_URL"
fi

# Test frontend
if curl -f -s "$FRONTEND_URL" >/dev/null 2>&1; then
    success "Frontend opérationnel sur $FRONTEND_URL"
else
    warning "Frontend ne répond pas sur $FRONTEND_URL"
fi

# Redémarrer nginx si VPS
if [ "$USE_SUPERVISOR" = false ] && command_exists nginx; then
    log "Redémarrage de Nginx..."
    sudo systemctl reload nginx
    success "Nginx redémarré"
fi

#################################################################
# ÉTAPE 11: RÉSUMÉ ET CONSEILS
#################################################################

log "📋 Résumé du déploiement..."

success "✅ Déploiement terminé avec succès !"

echo
echo "🌐 URLs d'accès:"
echo "   Frontend: $FRONTEND_URL"
echo "   Backend:  $BACKEND_URL"
echo
echo "📁 Sauvegarde créée dans: $BACKUP_DIR"
echo
echo "🔧 Commandes utiles:"
if [ "$USE_SUPERVISOR" = true ]; then
    echo "   Statut services:     sudo supervisorctl status"
    echo "   Redémarrer tout:     sudo supervisorctl restart all"
    echo "   Logs frontend:       sudo supervisorctl tail -f frontend"
    echo "   Logs backend:        sudo supervisorctl tail -f backend"
else
    echo "   Statut services:     pm2 status"
    echo "   Redémarrer tout:     pm2 restart all"
    echo "   Logs frontend:       pm2 logs frontend"
    echo "   Logs backend:        pm2 logs backend"
    echo "   Reload Nginx:        sudo systemctl reload nginx"
fi
echo
echo "📝 Notes importantes:"
echo "   • Application déployée pour: $DOMAIN"
echo "   • Type d'environnement: $([ "$USE_SUPERVISOR" = true ] && echo "Développement (supervisor)" || echo "Production (PM2)")"
echo "   • Build: $([ "$DOMAIN" != "localhost" ] && echo "Production (optimisé)" || echo "Développement (hot reload)")"
echo "   • Les variables d'environnement sont préservées"
echo

success "Déploiement complet terminé ! 🎉"

# Afficher l'état final des services
if [ "$USE_SUPERVISOR" = true ]; then
    echo "État des services:"
    sudo supervisorctl status
else
    echo "État des services PM2:"
    pm2 status
fi