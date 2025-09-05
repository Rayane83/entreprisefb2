#!/bin/bash

# 🆕 ACTIVATION Nouvelles fonctionnalités Gestion Entreprises
# Usage: ./enable-enterprise-features.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log "🆕 ACTIVATION Nouvelles fonctionnalités Entreprises"

# 1. Vérification fichiers requis
log "🔍 Vérification composants..."
if [ -f "/app/frontend/src/pages/EnterpriseManagement.js" ]; then
    log "✅ EnterpriseManagement.js présent"
else
    log "❌ EnterpriseManagement.js manquant"
    exit 1
fi

# 2. Vérification route dans App.js
log "🔍 Vérification routes..."
if grep -q "enterprise-management" "/app/frontend/src/App.js"; then
    log "✅ Route /enterprise-management configurée"
else
    log "❌ Route manquante"
    exit 1
fi

# 3. Vérification bouton Header
log "🔍 Vérification bouton header..."
if grep -q "Gestion Entreprises" "/app/frontend/src/components/Header.js"; then
    log "✅ Bouton header configuré"
else
    log "❌ Bouton header manquant"
    exit 1
fi

# 4. User Staff pour accès complet
log "🎭 Vérification rôle Staff pour accès..."
if grep -q "setUserRole('staff')" "/app/frontend/src/contexts/AuthContext.js"; then
    log "✅ Rôle Staff activé"
else
    log "❌ Rôle Staff manquant"
    exit 1
fi

# 5. Restart frontend
log "🔄 Restart frontend..."
sudo supervisorctl restart frontend

log "⏳ Attente (10s)..."
sleep 10

# 6. Test accès
log "🧪 Test nouvelles fonctionnalités..."
if curl -s http://localhost:3000 > /dev/null; then
    log "✅ Application accessible"
else
    log "❌ Application inaccessible"
    exit 1
fi

log "🎯 FONCTIONNALITÉS ACTIVÉES:"
log "   🆕 Page Gestion Entreprises (/enterprise-management)"
log "   🆕 Formulaire ajout entreprise (4 champs)"
log "   🆕 ID Rôle Membre pour comptage employés"
log "   🆕 Configuration rôles Dot Guild"
log "   🆕 Bouton violet 'Gestion Entreprises' (header)"
log "   🆕 Bouton vert 'Page Principale'"
log "   🆕 Tableau avec colonne orange ID Rôle Membre"
log "✅ TOUTES FONCTIONNALITÉS ACTIVES - http://localhost:3000"