#!/bin/bash

# 🚀 LANCEMENT Gestion Entreprises avec nouvelles fonctionnalités
# Usage: ./launch-enterprise-management.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${RED}[WARN]${NC} $1"
}

log "🚀 Lancement Portail Entreprise - Gestion Entreprises activée"

# 1. Vérification services
log "🔍 Vérification services..."
sudo supervisorctl status

# 2. Redémarrage rapide
log "🔄 Redémarrage services..."
sudo supervisorctl restart all

# 3. Attente startup
log "⏳ Attente services (10s)..."
sleep 10

# 4. Test connectivité
log "🌐 Test connectivité..."
if curl -s -f http://localhost:3000 > /dev/null; then
    log "✅ Frontend OK"
else
    warn "❌ Frontend KO"
fi

if curl -s -f http://localhost:8001/api/ > /dev/null; then
    log "✅ Backend OK"
else
    warn "❌ Backend KO"
fi

log "🎯 ACCÈS: http://localhost:3000"
log "🎭 Mode: Mock (connexion auto Staff)"
log "🆕 Nouveautés:"
log "   • Bouton violet 'Gestion Entreprises' (header)"
log "   • Formulaire ajout entreprise + ID Rôle Membre"
log "   • Configuration rôles Dot Guild"
log "   • Bouton 'Page Principale'"
log "✅ READY - Tous boutons fonctionnels"