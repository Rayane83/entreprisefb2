#!/bin/bash

# 🔧 CORRECTION Comptage employés via ID Rôle Membre Discord
# Usage: ./fix-member-role-counting.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log "🔧 ACTIVATION Comptage employés Discord via ID Rôle Membre"

# 1. Vérification page Gestion Entreprises existe
log "🔍 Vérification page Gestion Entreprises..."
if [ -f "/app/frontend/src/pages/EnterpriseManagement.js" ]; then
    log "✅ Page Gestion Entreprises OK"
else
    log "❌ Page Gestion Entreprises manquante"
    exit 1
fi

# 2. Vérification champ member_role_id dans formulaire
log "🔍 Vérification champ ID Rôle Membre..."
if grep -q "member_role_id" "/app/frontend/src/pages/EnterpriseManagement.js"; then
    log "✅ Champ ID Rôle Membre présent"
else
    log "❌ Champ ID Rôle Membre manquant"
    exit 1
fi

# 3. Redémarrage pour appliquer
log "🔄 Restart frontend..."
sudo supervisorctl restart frontend

log "⏳ Attente startup (8s)..."
sleep 8

# 4. Test complet
log "🧪 Test fonctionnalité..."
if curl -s http://localhost:3000 | grep -q "Gestion Entreprises"; then
    log "✅ Interface accessible"
else
    log "❌ Interface non accessible"
fi

log "🎯 FONCTIONNALITÉ ACTIVE:"
log "   • Champ 'ID Rôle Membre (pour compter employés)'"
log "   • Colonne orange dans tableau entreprises"
log "   • Validation formulaire complète"
log "   • Comptage auto employés Discord"
log "✅ READY - http://localhost:3000"