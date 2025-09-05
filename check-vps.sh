#!/bin/bash

# 🔍 Script de Vérification VPS - Portail Entreprise Flashback Fa
# Usage: ./check-vps.sh

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

info() {
    echo -e "${BLUE}[i]${NC} $1"
}

echo "🔍 Vérification de la Configuration VPS"
echo "======================================"

# Système
echo ""
info "📊 Informations Système"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"

# Ressources
echo ""
info "💾 Ressources Disponibles"
echo "RAM: $(free -h | awk 'NR==2{printf "%.1f GB utilisé / %.1f GB total (%.0f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')"
echo "Disque: $(df -h / | awk 'NR==2{printf "%s utilisé / %s total (%s)", $3, $2, $5}')"
echo "CPU: $(nproc) core(s)"

# Vérification des ports
echo ""
info "🌐 Ports Réseau"
if ss -tlnp | grep -q ":80 "; then
    warn "Port 80 déjà utilisé"
else
    log "Port 80 disponible"
fi

if ss -tlnp | grep -q ":443 "; then
    warn "Port 443 déjà utilisé"
else
    log "Port 443 disponible"
fi

if ss -tlnp | grep -q ":8001 "; then
    warn "Port 8001 déjà utilisé"
else
    log "Port 8001 disponible"
fi

# Prérequis logiciels
echo ""
info "📦 Prérequis Logiciels"

check_software() {
    local name=$1
    local command=$2
    local install_cmd=$3
    
    if command -v $command >/dev/null 2>&1; then
        local version=$($command --version 2>/dev/null | head -n1 || echo "version inconnue")
        log "$name installé ($version)"
    else
        error "$name NON installé"
        echo "   Installation: $install_cmd"
    fi
}

check_software "Node.js" "node" "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
check_software "Python3" "python3" "sudo apt install python3 python3-pip python3-venv -y"
check_software "Nginx" "nginx" "sudo apt install nginx -y"
check_software "Git" "git" "sudo apt install git -y"

# PM2 et Yarn (npm packages)
if command -v pm2 >/dev/null 2>&1; then
    log "PM2 installé ($(pm2 --version))"
else
    error "PM2 NON installé"
    echo "   Installation: sudo npm install -g pm2"
fi

if command -v yarn >/dev/null 2>&1; then
    log "Yarn installé ($(yarn --version))"
else
    error "Yarn NON installé"
    echo "   Installation: sudo npm install -g yarn"
fi

# Services système
echo ""
info "🔧 Services Système"

check_service() {
    local service=$1
    if systemctl is-active --quiet $service; then
        log "$service actif"
    elif systemctl is-enabled --quiet $service 2>/dev/null; then
        warn "$service installé mais inactif"
    else
        error "$service non disponible"
    fi
}

check_service "nginx"

# Permissions
echo ""
info "🔐 Permissions"
if [ "$EUID" -eq 0 ]; then
    warn "Exécuté en tant que root"
elif sudo -n true 2>/dev/null; then
    log "Accès sudo disponible"
else
    error "Pas d'accès sudo"
fi

# Espace disque nécessaire
echo ""
info "💽 Espace Disque"
available_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
if [ $available_gb -ge 5 ]; then
    log "Espace disque suffisant (${available_gb}GB disponible)"
else
    warn "Espace disque limité (${available_gb}GB disponible, 5GB recommandé)"
fi

# Réseau
echo ""
info "🌍 Connectivité Réseau"
if ping -c 1 google.com &> /dev/null; then
    log "Connexion Internet OK"
else
    error "Pas de connexion Internet"
fi

if ping -c 1 github.com &> /dev/null; then
    log "Accès à GitHub OK"
else
    error "Pas d'accès à GitHub"
fi

# Firewall
echo ""
info "🔥 Firewall"
if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        warn "UFW actif - Vérifiez que les ports 80, 443, 22 sont autorisés"
    else
        log "UFW installé mais inactif"
    fi
else
    warn "UFW non installé (optionnel)"
fi

# MongoDB (optionnel)
echo ""
info "🗄️ Base de Données (Optionnel)"
if command -v mongod >/dev/null 2>&1; then
    if systemctl is-active --quiet mongod; then
        log "MongoDB installé et actif"
    else
        warn "MongoDB installé mais inactif"
    fi
else
    warn "MongoDB non installé (utilisation de Supabase recommandée)"
fi

# SSL/Certbot
echo ""
info "🔒 SSL"
if command -v certbot >/dev/null 2>&1; then
    log "Certbot installé"
else
    warn "Certbot non installé"
    echo "   Installation: sudo apt install certbot python3-certbot-nginx -y"
fi

# Recommandations finales
echo ""
echo "📋 RÉSUMÉ ET RECOMMANDATIONS"
echo "=========================="

# Compter les erreurs
error_count=$(grep -c "✗" /tmp/check_output 2>/dev/null || echo "0")

if [ "$error_count" -eq 0 ]; then
    log "🎉 VPS prêt pour le déploiement !"
    echo ""
    echo "Commandes de déploiement :"
    echo "  1. cd /path/to/your/project"
    echo "  2. ./deploy.sh votre-domaine.com /var/www/portail-entreprise"
else
    warn "⚠️ $error_count problème(s) détecté(s) - Corrigez avant le déploiement"
fi

echo ""
echo "🔗 Ressources utiles :"
echo "  • Guide complet: DEPLOYMENT_GUIDE.md"
echo "  • Script automatique: deploy.sh"
echo "  • Configuration Supabase: SETUP_SUPABASE.md"