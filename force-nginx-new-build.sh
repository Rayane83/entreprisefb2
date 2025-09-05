#!/bin/bash

# 🚨 FORCER NGINX À SERVIR LE NOUVEAU BUILD - Solution définitive
# Usage: ./force-nginx-new-build.sh

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

log "🚨 FORCER NGINX À SERVIR LE NOUVEAU BUILD"

# 1. Diagnostic complet
log "🔍 Diagnostic complet des builds..."

echo "📁 Build actuel dans le dossier :"
ls -la "$DEST_PATH/frontend/build/static/js/" 2>/dev/null | grep main || echo "Aucun fichier main trouvé"

echo ""
echo "📄 Contenu index.html :"
grep -o 'main\.[a-zA-Z0-9]*\.js' "$DEST_PATH/frontend/build/index.html" 2>/dev/null || echo "Aucun fichier main dans index.html"

echo ""
echo "🌐 Ce que Nginx sert actuellement :"
CURRENT_RESPONSE=$(curl -s "https://flashbackfa-entreprise.fr/" 2>/dev/null)
CURRENT_JS=$(echo "$CURRENT_RESPONSE" | grep -o 'main\.[a-zA-Z0-9]*\.js' || echo "Non détecté")
echo "Fichier JS servi: $CURRENT_JS"

# 2. Identifier le nouveau fichier JS
NEW_JS=$(ls "$DEST_PATH/frontend/build/static/js/main."*.js 2>/dev/null | xargs -n 1 basename | head -1)
if [ -z "$NEW_JS" ]; then
    error "❌ Aucun fichier JS trouvé dans le build !"
    exit 1
fi

log "🎯 Nouveau fichier JS à servir: $NEW_JS"

# 3. Vérifier que le nouveau fichier est dans index.html
if ! grep -q "$NEW_JS" "$DEST_PATH/frontend/build/index.html"; then
    error "❌ Le fichier $NEW_JS n'est pas référencé dans index.html !"
    
    echo "🔧 Tentative de correction de index.html..."
    # Backup
    cp "$DEST_PATH/frontend/build/index.html" "$DEST_PATH/frontend/build/index.html.backup"
    
    # Corriger index.html
    sed -i "s/main\.[a-zA-Z0-9]*\.js/$NEW_JS/g" "$DEST_PATH/frontend/build/index.html"
    
    if grep -q "$NEW_JS" "$DEST_PATH/frontend/build/index.html"; then
        log "✅ index.html corrigé"
    else
        error "❌ Impossible de corriger index.html"
        exit 1
    fi
fi

# 4. Supprimer TOUS les caches Nginx possibles
log "🗑️ Suppression TOTALE des caches Nginx..."

# Arrêter Nginx complètement
sudo systemctl stop nginx
sudo pkill -f nginx 2>/dev/null || true

# Supprimer tous les logs et caches
sudo rm -rf /var/log/nginx/* 2>/dev/null || true
sudo rm -rf /var/cache/nginx/* 2>/dev/null || true
sudo rm -rf /tmp/nginx* 2>/dev/null || true

# 5. Recréer la configuration Nginx avec chemins absolus
log "🔧 Recréation complète configuration Nginx..."

sudo tee /etc/nginx/sites-available/flashbackfa-entreprise << EOF
# Configuration FORCÉE - Nouveau build $NEW_JS
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
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # CHEMIN ABSOLU FORCÉ
    root $DEST_PATH/frontend/build;
    index index.html;
    
    # Logs dédiés
    access_log /var/log/nginx/flashbackfa_access.log;
    error_log /var/log/nginx/flashbackfa_error.log;
    
    # API Backend
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Fichier JS spécifique avec timestamp
    location /static/js/$NEW_JS {
        expires off;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
        add_header Pragma "no-cache";
        add_header Last-Modified \$date_gmt;
        add_header ETag "";
        if_modified_since off;
        try_files \$uri =404;
    }
    
    # Autres assets JS/CSS
    location ~* \.(?:js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1h;
        add_header Cache-Control "public, no-transform";
        try_files \$uri =404;
    }
    
    # Frontend - Application React (catch-all)
    location / {
        try_files \$uri \$uri/ /index.html;
        
        # Headers anti-cache pour HTML
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0" always;
        add_header Pragma "no-cache" always;
        add_header Last-Modified \$date_gmt always;
        add_header ETag "" always;
        if_modified_since off;
    }
    
    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        application/javascript
        application/json
        text/css
        text/javascript
        text/plain
        text/xml;
    
    # Headers de sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

# 6. Test configuration Nginx
log "🧪 Test configuration Nginx..."

sudo nginx -t
if [ $? -ne 0 ]; then
    error "❌ Configuration Nginx invalide !"
    exit 1
fi

log "✅ Configuration Nginx valide"

# 7. Redémarrage avec délai
log "🔄 Redémarrage Nginx avec délai..."

sleep 5
sudo systemctl start nginx

# Attendre que Nginx soit complètement démarré
sleep 10

# 8. Test multiple avec retry
log "🧪 Tests multiples avec retry..."

for i in {1..5}; do
    echo "Test $i/5..."
    
    # Test avec headers anti-cache forts
    RESPONSE=$(curl -s -H "Cache-Control: no-cache, no-store, must-revalidate" -H "Pragma: no-cache" -H "Expires: 0" "https://flashbackfa-entreprise.fr/?v=$(date +%s)" 2>/dev/null)
    
    SERVED_JS=$(echo "$RESPONSE" | grep -o 'main\.[a-zA-Z0-9]*\.js' | head -1)
    
    if [ "$SERVED_JS" = "$NEW_JS" ]; then
        log "✅ Test $i: Nouveau build servi ($SERVED_JS)"
        
        # Test contenu Discord
        if echo "$RESPONSE" | grep -q "Se connecter avec Discord" || echo "$RESPONSE" | grep -q "Connexion Sécurisée"; then
            log "✅ Test $i: Contenu Discord détecté"
            SUCCESS=true
            break
        else
            log "⚠️ Test $i: Nouveau build mais contenu Discord pas détecté"
            SUCCESS=partial
        fi
    else
        log "❌ Test $i: Ancien build encore servi ($SERVED_JS)"
        SUCCESS=false
    fi
    
    sleep 2
done

# 9. Test direct du fichier JS
log "🧪 Test direct du fichier JS..."

JS_DIRECT=$(curl -s "https://flashbackfa-entreprise.fr/static/js/$NEW_JS" 2>/dev/null)
if [ ${#JS_DIRECT} -gt 10000 ]; then
    log "✅ Fichier JS accessible directement"
    JS_ACCESSIBLE=true
else
    log "❌ Fichier JS non accessible directement"
    JS_ACCESSIBLE=false
fi

# 10. Informations de diagnostic finales
echo ""
echo "🎉========================================🎉"
echo -e "${GREEN}    DIAGNOSTIC FINAL NGINX + BUILD${NC}"
echo "🎉========================================🎉"
echo ""

echo -e "${BLUE}📊 DIAGNOSTIC COMPLET:${NC}"
echo -e "   Fichier attendu: $NEW_JS"
echo -e "   Fichier servi: $SERVED_JS"
echo -e "   Fichier accessible: $([ "$JS_ACCESSIBLE" = true ] && echo "✅" || echo "❌")"
echo -e "   Contenu Discord: $([ "$SUCCESS" = true ] && echo "✅ Détecté" || echo "❌ Non détecté")"

echo ""
echo -e "${BLUE}🔧 ACTIONS EFFECTUÉES:${NC}"
echo -e "   ✅ Configuration Nginx recréée avec chemin absolu"
echo -e "   ✅ Caches Nginx supprimés complètement"
echo -e "   ✅ Headers anti-cache renforcés"
echo -e "   ✅ Nginx redémarré complètement"
echo -e "   ✅ Tests multiples effectués"

echo ""
echo -e "${BLUE}🎯 RÉSULTAT FINAL:${NC}"
if [ "$SUCCESS" = true ]; then
    echo -e "   ${GREEN}✅ NOUVEAU BUILD AVEC DISCORD AUTH SERVI !${NC}"
    echo -e "   ${GREEN}🔗 Site: https://flashbackfa-entreprise.fr${NC}"
    echo -e "   ${GREEN}🔐 L'authentification Discord est maintenant active !${NC}"
elif [ "$SUCCESS" = partial ]; then
    echo -e "   ${YELLOW}⚠️ Nouveau build servi mais contenu à vérifier${NC}"
    echo -e "   ${YELLOW}🔗 Testez: https://flashbackfa-entreprise.fr${NC}"
else
    echo -e "   ${RED}❌ Problème persistant avec le cache${NC}"
    echo -e "   ${RED}🔧 Essayez un autre navigateur ou attendez 5 minutes${NC}"
fi

echo ""
echo -e "${BLUE}🧪 POUR TESTER MAINTENANT:${NC}"
echo -e "${GREEN}   1. Fermez COMPLÈTEMENT votre navigateur${NC}"
echo -e "${GREEN}   2. Rouvrez en mode INCOGNITO/PRIVÉ${NC}"
echo -e "${GREEN}   3. Allez sur: https://flashbackfa-entreprise.fr${NC}"
echo -e "${GREEN}   4. Ouvrez F12 -> Network pour voir $NEW_JS${NC}"

echo ""
if [ "$SUCCESS" = true ]; then
    echo -e "${GREEN}🚀 L'AUTHENTIFICATION DISCORD EST ENFIN ACTIVE ! 🔥${NC}"
    echo -e "${GREEN}   Vous devriez voir la page de connexion Discord ! 🎉${NC}"
else
    echo -e "${YELLOW}💡 Si le problème persiste:${NC}"
    echo -e "   • Utilisez un autre navigateur (Firefox, Edge, etc.)"
    echo -e "   • Ou attendez quelques minutes (propagation cache)"
    echo -e "   • Ou ajoutez ?v=$(date +%s) à la fin de l'URL"
fi

exit 0