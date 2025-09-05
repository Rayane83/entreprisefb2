#!/bin/bash

# 🔍 DIAGNOSTIC COMPLET et CORRECTION VPS
# Usage: ./diagnose-and-fix-vps.sh

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

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log "🔍 DIAGNOSTIC COMPLET VPS"

# 1. Vérification structure et build
log "📁 Vérification structure complète..."

echo "📊 Structure dossiers :"
[ -d "$DEST_PATH" ] && echo "✅ $DEST_PATH" || echo "❌ $DEST_PATH"
[ -d "$DEST_PATH/frontend" ] && echo "✅ $DEST_PATH/frontend" || echo "❌ $DEST_PATH/frontend"
[ -d "$DEST_PATH/frontend/build" ] && echo "✅ Build folder" || echo "❌ Build folder"

echo ""
echo "📊 Fichiers build JS :"
if [ -d "$DEST_PATH/frontend/build/static/js" ]; then
    BUILD_FILES=$(ls -la "$DEST_PATH/frontend/build/static/js/" | grep "main\." || echo "Aucun")
    echo "Build JS: $BUILD_FILES"
else
    echo "❌ Dossier JS build manquant"
fi

echo ""
echo "📊 Contenu index.html build :"
if [ -f "$DEST_PATH/frontend/build/index.html" ]; then
    MAIN_JS_REF=$(grep -o 'main\.[a-zA-Z0-9]*\.js' "$DEST_PATH/frontend/build/index.html" || echo "Non trouvé")
    echo "JS référencé: $MAIN_JS_REF"
else
    echo "❌ index.html build manquant"
fi

# 2. Vérification configuration Nginx
log "🌐 Vérification configuration Nginx..."

echo "📊 Configuration Nginx active :"
if [ -f "/etc/nginx/sites-enabled/flashbackfa-entreprise" ]; then
    NGINX_ROOT=$(grep "root " /etc/nginx/sites-enabled/flashbackfa-entreprise | head -1 || echo "Non trouvé")
    echo "Root Nginx: $NGINX_ROOT"
else
    echo "❌ Configuration Nginx manquante"
fi

echo ""
echo "📊 Status Nginx :"
sudo systemctl status nginx --no-pager -l | head -5

# 3. Test contenu actuel servi
log "🔍 Test contenu actuel servi par Nginx..."

echo "📊 Contenu HTML actuel :"
CURRENT_HTML=$(curl -s https://flashbackfa-entreprise.fr/ 2>/dev/null | head -20 || echo "Erreur curl")
if echo "$CURRENT_HTML" | grep -q "Gestion Entreprises"; then
    echo "✅ Bouton Gestion Entreprises trouvé dans HTML"
else
    echo "❌ Bouton Gestion Entreprises non trouvé"
    echo "Extrait HTML reçu :"
    echo "$CURRENT_HTML" | head -10
fi

# 4. Vérification fichiers source
log "📄 Vérification fichiers source..."

echo "📊 Header.js source :"
if grep -q "Gestion Entreprises" "$DEST_PATH/frontend/src/components/Header.js"; then
    echo "✅ Bouton présent dans source Header.js"
else
    echo "❌ Bouton manquant dans source Header.js"
fi

echo ""
echo "📊 App.js source :"
if grep -q "enterprise-management" "$DEST_PATH/frontend/src/App.js"; then
    echo "✅ Route présente dans source App.js"
else
    echo "❌ Route manquante dans source App.js"
fi

echo ""
echo "📊 EnterpriseManagement.js :"
if [ -f "$DEST_PATH/frontend/src/pages/EnterpriseManagement.js" ]; then
    echo "✅ Fichier EnterpriseManagement.js présent"
else
    echo "❌ Fichier EnterpriseManagement.js manquant"
fi

# 5. CORRECTION si problèmes détectés
log "🔧 CORRECTION des problèmes détectés..."

NEEDS_REBUILD=false

# Vérifier si Nginx pointe au bon endroit
if ! grep -q "$DEST_PATH/frontend/build" /etc/nginx/sites-enabled/flashbackfa-entreprise 2>/dev/null; then
    warn "Configuration Nginx à corriger..."
    
    # Corriger la config Nginx
    sudo tee /etc/nginx/sites-enabled/flashbackfa-entreprise > /dev/null << EOF
# Configuration CORRIGÉE - Nouvelles fonctionnalités
server {
    listen 80;
    server_name flashbackfa-entreprise.fr www.flashbackfa-entreprise.fr;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name flashbackfa-entreprise.fr www.flashbackfa-entreprise.fr;
    
    # SSL (géré par Certbot)
    ssl_certificate /etc/letsencrypt/live/flashbackfa-entreprise.fr/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/flashbackfa-entreprise.fr/privkey.pem;
    
    # Racine vers le build React
    root $DEST_PATH/frontend/build;
    index index.html;
    
    # Gestion des routes React
    location / {
        try_files \$uri \$uri/ /index.html;
        
        # Headers cache pour performance
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # Assets statiques avec cache
    location /static/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gestion erreurs
    error_page 404 /index.html;
}
EOF
    
    log "✅ Configuration Nginx corrigée"
    sudo nginx -t
    sudo systemctl reload nginx
fi

# Vérifier si le build existe et est récent
if [ ! -f "$DEST_PATH/frontend/build/index.html" ]; then
    warn "Build manquant, rebuild nécessaire..."
    NEEDS_REBUILD=true
else
    # Vérifier si le build contient les nouvelles fonctionnalités
    if ! grep -q "enterprise-management" "$DEST_PATH/frontend/build/index.html" 2>/dev/null; then
        warn "Build ne contient pas les nouvelles fonctionnalités, rebuild nécessaire..."
        NEEDS_REBUILD=true
    fi
fi

# Rebuild si nécessaire
if [ "$NEEDS_REBUILD" = true ]; then
    log "🔨 REBUILD FORCÉ..."
    
    cd "$DEST_PATH/frontend"
    
    # Nettoyage complet
    rm -rf build
    rm -rf node_modules/.cache 2>/dev/null || true
    
    # Rebuild
    npm run build
    
    if [ -f "build/index.html" ]; then
        log "✅ Rebuild réussi"
    else
        error "❌ Rebuild échoué"
        exit 1
    fi
fi

# 6. Force clear cache Nginx
log "🗑️ Nettoyage cache Nginx..."

sudo systemctl stop nginx
sudo rm -rf /var/cache/nginx/* 2>/dev/null || true
sudo systemctl start nginx

# 7. Tests finaux
log "🧪 TESTS FINAUX APRÈS CORRECTION..."

sleep 10

echo ""
echo "📊 Test final accessibilité :"
if curl -s -f https://flashbackfa-entreprise.fr/ > /dev/null; then
    echo "✅ Site accessible"
else
    echo "❌ Site inaccessible"
fi

echo ""
echo "📊 Test final contenu (avec cache bypass) :"
FINAL_CONTENT=$(curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" https://flashbackfa-entreprise.fr/ 2>/dev/null || echo "")
if echo "$FINAL_CONTENT" | grep -q "Gestion Entreprises"; then
    echo "✅ Bouton Gestion Entreprises détecté !"
    FINAL_SUCCESS=true
else
    echo "❌ Bouton toujours non détecté"
    FINAL_SUCCESS=false
    echo ""
    echo "Contenu reçu (premiers 500 caractères) :"
    echo "$FINAL_CONTENT" | head -c 500
fi

# 8. Instructions manuelles si problème persiste
if [ "$FINAL_SUCCESS" != true ]; then
    warn "INSTRUCTIONS MANUELLES"
    echo ""
    echo "Si le problème persiste, vérifiez manuellement :"
    echo ""
    echo "1. 🔍 Vérifier build :"
    echo "   cd $DEST_PATH/frontend"
    echo "   ls -la build/static/js/"
    echo "   grep -i 'gestion entreprises' build/index.html"
    echo ""
    echo "2. 🌐 Vérifier Nginx :"
    echo "   sudo nginx -t"
    echo "   sudo systemctl status nginx"
    echo "   curl -I https://flashbackfa-entreprise.fr/"
    echo ""
    echo "3. 🧹 Clear cache navigateur :"
    echo "   - Ouvrir https://flashbackfa-entreprise.fr/"
    echo "   - Ctrl+Shift+R (force refresh)"
    echo "   - Ou F12 > Network > Disable cache"
    echo ""
    echo "4. 🔐 Vérifier authentification :"
    echo "   - Le bouton nécessite d'être connecté avec rôle Staff"
    echo "   - Connectez-vous avec Discord"
    echo "   - Vérifiez votre rôle dans l'interface"
fi

# 9. RÉSULTATS FINAUX
log "🎯 DIAGNOSTIC ET CORRECTION TERMINÉS"

if [ "$FINAL_SUCCESS" = true ]; then
    log "🎉 SUCCESS - NOUVELLES FONCTIONNALITÉS DÉTECTÉES !"
    
    echo ""
    echo "✅ RÉSOLUTION COMPLÈTE :"
    echo "   🌐 Site accessible"
    echo "   🆕 Bouton 'Gestion Entreprises' détecté"
    echo "   🔨 Build déployé correctement"
    echo "   ⚙️  Configuration Nginx OK"
    
    echo ""
    echo "🎯 PROCHAINES ÉTAPES :"
    echo "   1. Ouvrir https://flashbackfa-entreprise.fr/"
    echo "   2. Se connecter avec Discord"
    echo "   3. Chercher bouton violet 'Gestion Entreprises' (rôle Staff requis)"
    echo "   4. Tester les nouvelles fonctionnalités"
    
else
    error "❌ PROBLÈME PERSISTANT"
    echo ""
    echo "Le diagnostic a identifié et tenté de corriger les problèmes,"
    echo "mais le bouton n'est toujours pas détecté."
    echo ""
    echo "Causes possibles restantes :"
    echo "   - Cache navigateur très persistant"
    echo "   - Problème d'authentification (rôle Staff requis)"
    echo "   - Build non déployé correctement malgré les corrections"
fi

log "🔍 DIAGNOSTIC TERMINÉ"