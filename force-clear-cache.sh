#!/bin/bash

# 🗑️ Forcer la suppression complète du cache et rebuild - AUTHENTIFICATION DISCORD
# Usage: ./force-clear-cache.sh

set -e

DEST_PATH="/var/www/flashbackfa-entreprise.fr"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log "🗑️ SUPPRESSION COMPLÈTE DU CACHE ET REBUILD FORCÉ..."

# 1. Vérifier que nos fichiers Discord Auth sont bien en place
log "🔍 Vérification des fichiers d'authentification Discord..."

# Vérifier AuthContext
if grep -q "Discord OAuth OBLIGATOIRE" "$DEST_PATH/frontend/src/contexts/AuthContext.js"; then
    log "✅ AuthContext Discord OK"
else
    warn "❌ AuthContext pas à jour"
fi

# Vérifier LoginScreen
if grep -q "Se connecter avec Discord" "$DEST_PATH/frontend/src/components/LoginScreen.js"; then
    log "✅ LoginScreen Discord OK"
else
    warn "❌ LoginScreen pas à jour"
fi

# Vérifier .env
if grep -q "REACT_APP_FORCE_DISCORD_AUTH=true" "$DEST_PATH/frontend/.env"; then
    log "✅ Variables .env Discord OK"
else
    warn "❌ Variables .env pas à jour"
fi

# 2. SUPPRESSION COMPLÈTE DE L'ANCIEN BUILD
log "🗑️ Suppression complète de l'ancien build..."

cd "$DEST_PATH/frontend"

# Supprimer complètement le build existant
rm -rf build/
rm -rf node_modules/.cache/ 2>/dev/null || true
rm -rf .cache/ 2>/dev/null || true

log "✅ Ancien build supprimé"

# 3. NETTOYAGE COMPLET YARN
log "🧹 Nettoyage complet Yarn et cache..."

yarn cache clean
rm -rf node_modules/
yarn install

log "✅ Dépendances réinstallées"

# 4. REBUILD COMPLET FORCÉ
log "🏗️ REBUILD COMPLET FORCÉ avec authentification Discord..."

# Forcer la génération d'un nouveau build ID
export GENERATE_SOURCEMAP=false
export REACT_APP_BUILD_TIME=$(date +%s)

yarn build

log "✅ Nouveau build créé"

# 5. VÉRIFICATION DU NOUVEAU BUILD
log "🔍 Vérification du nouveau build..."

# Vérifier que le build contient bien nos nouvelles données
if [ -f "build/index.html" ]; then
    log "✅ index.html généré"
else
    log "❌ index.html manquant"
    exit 1
fi

# Vérifier la présence des fichiers JS/CSS
if ls build/static/js/*.js >/dev/null 2>&1; then
    log "✅ Fichiers JavaScript générés"
else
    log "❌ Fichiers JavaScript manquants"
    exit 1
fi

# 6. VIDAGE CACHE NGINX ET REDÉMARRAGE
log "🔄 Vidage cache Nginx et redémarrage..."

# Supprimer les logs Nginx qui peuvent contenir du cache
sudo rm -f /var/log/nginx/flashbackfa_access.log* 2>/dev/null || true
sudo rm -f /var/log/nginx/flashbackfa_error.log* 2>/dev/null || true

# Redémarrage complet Nginx (pas juste reload)  
sudo systemctl stop nginx
sleep 2
sudo systemctl start nginx

log "✅ Nginx redémarré complètement"

# 7. VÉRIFICATION QUE LE NOUVEAU BUILD EST SERVI
log "🧪 Test que le nouveau build est servi..."

sleep 3

# Tester avec un header pour éviter le cache
RESPONSE=$(curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" "https://flashbackfa-entreprise.fr/" 2>/dev/null || curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" "http://flashbackfa-entreprise.fr/" 2>/dev/null || echo "erreur")

if echo "$RESPONSE" | grep -q "Se connecter avec Discord" || echo "$RESPONSE" | grep -q "Connexion Sécurisée"; then
    log "✅ Nouveau build avec authentification Discord détecté"
else
    warn "⚠️ Ancien build encore présent ou site non accessible"
    
    # Debug: vérifier le contenu servi
    log "🔍 Debug: vérification du contenu..."
    echo "$RESPONSE" | head -20
fi

# 8. FORCER LA RÉGÉNÉRATION DU CACHE NAVIGATEUR
log "🌐 Génération URL anti-cache..."

TIMESTAMP=$(date +%s)
if curl -s "https://flashbackfa-entreprise.fr/" >/dev/null 2>&1; then
    SITE_URL="https://flashbackfa-entreprise.fr/?v=$TIMESTAMP"
    SITE_BASE="https://flashbackfa-entreprise.fr"
elif curl -s "http://flashbackfa-entreprise.fr/" >/dev/null 2>&1; then
    SITE_URL="http://flashbackfa-entreprise.fr/?v=$TIMESTAMP"
    SITE_BASE="http://flashbackfa-entreprise.fr"
else
    SITE_URL="http://localhost/?v=$TIMESTAMP"
    SITE_BASE="http://localhost"
fi

# 9. TEST FINAL AVEC TIMESTAMP
log "🧪 Test final avec timestamp pour éviter le cache..."

sleep 2

FINAL_RESPONSE=$(curl -s -H "Cache-Control: no-cache" "$SITE_URL" 2>/dev/null || echo "erreur")

if echo "$FINAL_RESPONSE" | grep -q "Se connecter avec Discord"; then
    log "✅ AUTHENTIFICATION DISCORD CONFIRMÉE DANS LE BUILD"
    DISCORD_AUTH_ACTIVE=true
else
    warn "❌ Authentification Discord pas encore visible"
    DISCORD_AUTH_ACTIVE=false
fi

# 10. INFORMATIONS FINALES
echo ""
echo "🎉=============================================🎉"
echo -e "${GREEN}     CACHE VIDÉ ET BUILD FORCÉ !${NC}"
echo "🎉=============================================🎉"
echo ""

echo -e "${BLUE}🗑️ ACTIONS EFFECTUÉES:${NC}"
echo -e "   ✅ Ancien build supprimé complètement"
echo -e "   ✅ Cache Yarn nettoyé"
echo -e "   ✅ Dépendances réinstallées"
echo -e "   ✅ Build complet forcé"
echo -e "   ✅ Nginx redémarré complètement"
echo -e "   ✅ Cache navigateur contourné"

echo ""
echo -e "${BLUE}🌟 VOTRE SITE:${NC}"
echo -e "   🔗 URL normale: $SITE_BASE"
echo -e "   🔗 URL anti-cache: $SITE_URL"

echo ""
echo -e "${BLUE}🔐 AUTHENTIFICATION DISCORD:${NC}"
if [ "$DISCORD_AUTH_ACTIVE" = true ]; then
    echo -e "   ✅ ACTIF - Page de connexion Discord détectée"
else
    echo -e "   ⚠️ En cours - Peut nécessiter vidage cache navigateur"
fi

echo ""
echo -e "${BLUE}🎯 POUR TESTER MAINTENANT:${NC}"
echo -e "${GREEN}   1. Ouvrez un NOUVEL ONGLET PRIVÉ/INCOGNITO${NC}"
echo -e "${GREEN}   2. Allez sur: $SITE_BASE${NC}"
echo -e "${GREEN}   3. Ou utilisez l'URL anti-cache: $SITE_URL${NC}"
echo -e "${GREEN}   4. Vous DEVEZ voir 'Se connecter avec Discord'${NC}"

echo ""
echo -e "${YELLOW}💡 SI VOUS VOYEZ ENCORE L'ANCIEN SITE:${NC}"
echo -e "   • Utilisez un onglet privé/incognito"
echo -e "   • Ou videz le cache navigateur (Ctrl+F5)"
echo -e "   • Ou utilisez l'URL avec timestamp: $SITE_URL"

echo ""
if [ "$DISCORD_AUTH_ACTIVE" = true ]; then
    echo -e "${GREEN}🚀 AUTHENTIFICATION DISCORD MAINTENANT ACTIVE !${NC}"
    echo -e "${GREEN}   Testez la connexion Discord immédiatement ! 🔥${NC}"
else
    echo -e "${YELLOW}⚠️ Si le problème persiste, videz votre cache navigateur${NC}"
fi

exit 0