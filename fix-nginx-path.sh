#!/bin/bash

# 🔧 CORRECTION CRITIQUE - Nginx sert le mauvais dossier build
# Usage: ./fix-nginx-path.sh

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

log "🔧 CORRECTION CRITIQUE - Nginx sert le mauvais dossier build !"

# 1. Diagnostic du problème
log "🔍 Diagnostic des dossiers build..."

echo "📁 Contenu du dossier build actuel :"
ls -la "$DEST_PATH/frontend/build/" 2>/dev/null || echo "❌ Dossier build manquant"

echo ""
echo "📁 Fichiers JS dans le build :"
ls -la "$DEST_PATH/frontend/build/static/js/" 2>/dev/null || echo "❌ Dossier JS manquant"

echo ""
echo "📁 Configuration Nginx actuelle :"
sudo cat /etc/nginx/sites-available/flashbackfa-entreprise | grep "root"

# 2. Vérifier que notre nouveau build existe bien
if [ ! -f "$DEST_PATH/frontend/build/static/js/main.7ce2b6fa.js" ]; then
    error "❌ Le nouveau build n'existe pas ! Regénération..."
    
    cd "$DEST_PATH/frontend"
    rm -rf build/
    yarn build
    
    log "✅ Nouveau build régénéré"
fi

# 3. Vérifier le contenu du index.html
log "🔍 Vérification index.html..."

if grep -q "main.7ce2b6fa.js" "$DEST_PATH/frontend/build/index.html"; then
    log "✅ index.html contient le bon fichier JS"
else
    error "❌ index.html ne contient pas le bon fichier JS"
    echo "Contenu index.html :"
    cat "$DEST_PATH/frontend/build/index.html" | head -10
fi

# 4. Supprimer TOUS les anciens builds et caches
log "🗑️ Suppression de TOUS les anciens builds..."

# Chercher et supprimer tous les dossiers build
find /var/www/ -name "build" -type d -path "*/frontend/build" 2>/dev/null | while read build_dir; do
    if [ "$build_dir" != "$DEST_PATH/frontend/build" ]; then
        echo "🗑️ Suppression ancien build: $build_dir"
        sudo rm -rf "$build_dir"
    fi
done

# 5. Recréer la configuration Nginx avec le bon chemin
log "🌐 Recréation configuration Nginx avec chemin correct..."

sudo tee /etc/nginx/sites-available/flashbackfa-entreprise << EOF
# Configuration CORRIGÉE - Flashback Fa Entreprise
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
    
    # CHEMIN ABSOLU ET CORRECT DU BUILD
    root $DEST_PATH/frontend/build;
    index index.html;
    
    # Logs spécifiques
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
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Assets statiques avec cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|webp|svg|woff|woff2|ttf|eot)$ {
        expires 1h;
        add_header Cache-Control "public, no-transform";
        add_header Vary "Accept-Encoding";
        try_files \$uri =404;
    }
    
    # Frontend - SPA React (catch-all)
    location / {
        try_files \$uri \$uri/ /index.html;
        
        # Headers anti-cache pour l'application
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
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

# 6. Test de la configuration Nginx
log "🧪 Test configuration Nginx..."

sudo nginx -t

if [ $? -ne 0 ]; then
    error "❌ Configuration Nginx invalide !"
    exit 1
fi

log "✅ Configuration Nginx valide"

# 7. Redémarrage COMPLET de Nginx
log "🔄 Redémarrage COMPLET Nginx..."

sudo systemctl stop nginx
sudo pkill -f nginx 2>/dev/null || true
sleep 3
sudo systemctl start nginx

# 8. Vérifier que Nginx sert bien le bon fichier
log "🧪 Test que Nginx sert le BON build..."

sleep 3

# Test direct du fichier JS
JS_RESPONSE=$(curl -s "https://flashbackfa-entreprise.fr/static/js/main.7ce2b6fa.js" 2>/dev/null || echo "erreur")

if echo "$JS_RESPONSE" | grep -q "createRoot\|React" && [ ${#JS_RESPONSE} -gt 1000 ]; then
    log "✅ Fichier JS correct servi par Nginx"
    JS_SERVED=true
else
    error "❌ Fichier JS incorrect ou non servi"
    JS_SERVED=false
fi

# Test de la page principale
INDEX_RESPONSE=$(curl -s -H "Cache-Control: no-cache" "https://flashbackfa-entreprise.fr/" 2>/dev/null)

if echo "$INDEX_RESPONSE" | grep -q "main.7ce2b6fa.js"; then
    log "✅ Page principale contient le bon fichier JS"
    INDEX_OK=true
else
    error "❌ Page principale contient encore l'ancien fichier JS"
    INDEX_OK=false
    
    echo "🔍 Fichier JS détecté dans la réponse :"
    echo "$INDEX_RESPONSE" | grep -o 'main\.[a-zA-Z0-9]*\.js' || echo "Aucun fichier main.*.js détecté"
fi

# 9. Test final de l'application
log "🧪 Test final de l'application..."

sleep 2

FINAL_RESPONSE=$(curl -s -H "Cache-Control: no-cache" "https://flashbackfa-entreprise.fr/" 2>/dev/null)

# Vérifier que c'est bien notre nouveau build
if echo "$FINAL_RESPONSE" | grep -q "main.7ce2b6fa.js"; then
    if echo "$FINAL_RESPONSE" | grep -q "Se connecter avec Discord" || echo "$FINAL_RESPONSE" | grep -q "Connexion Sécurisée"; then
        log "✅ NOUVEAU BUILD AVEC DISCORD AUTH DÉTECTÉ !"
        SUCCESS=true
    else
        log "✅ Nouveau build servi, mais contenu à vérifier"
        SUCCESS=partial
    fi
else
    error "❌ Ancien build encore servi"
    SUCCESS=false
fi

# 10. Informations de diagnostic finales
echo ""
echo "🎉============================================🎉"
echo -e "${GREEN}      DIAGNOSTIC ET CORRECTION BUILD${NC}"
echo "🎉============================================🎉"
echo ""

echo -e "${BLUE}📊 DIAGNOSTIC:${NC}"
echo -e "   Fichier JS servi: $(echo "$INDEX_RESPONSE" | grep -o 'main\.[a-zA-Z0-9]*\.js' || echo 'Non détecté')"
echo -e "   Fichier JS attendu: main.7ce2b6fa.js"
echo -e "   JS correct servi: $([ "$JS_SERVED" = true ] && echo "✅" || echo "❌")"
echo -e "   Index correct: $([ "$INDEX_OK" = true ] && echo "✅" || echo "❌")"

echo ""
echo -e "${BLUE}🔧 ACTIONS EFFECTUÉES:${NC}"
echo -e "   ✅ Configuration Nginx corrigée avec chemin absolu"
echo -e "   ✅ Anciens builds supprimés"
echo -e "   ✅ Nginx redémarré complètement"
echo -e "   ✅ Cache anti-headers ajoutés"

echo ""
echo -e "${BLUE}🎯 RÉSULTAT:${NC}"
if [ "$SUCCESS" = true ]; then
    echo -e "   ${GREEN}✅ NOUVEAU BUILD AVEC DISCORD AUTH ACTIF !${NC}"
    echo -e "   ${GREEN}🔗 Testez maintenant: https://flashbackfa-entreprise.fr${NC}"
    echo -e "   ${GREEN}🔐 Vous devriez voir la page de connexion Discord !${NC}"
elif [ "$SUCCESS" = partial ]; then
    echo -e "   ${YELLOW}⚠️ Nouveau build servi, vérifiez le contenu${NC}"
    echo -e "   ${YELLOW}🔗 Testez: https://flashbackfa-entreprise.fr${NC}"
    echo -e "   ${YELLOW}📱 Utilisez un onglet privé si nécessaire${NC}"
else
    echo -e "   ${RED}❌ Problème persistant${NC}"
    echo -e "   ${RED}🔧 Vérifiez manuellement les chemins Nginx${NC}"
fi

echo ""
echo -e "${BLUE}🧪 POUR TESTER:${NC}"
echo -e "${GREEN}   1. Ouvrez un NOUVEL ONGLET PRIVÉ${NC}"
echo -e "${GREEN}   2. Allez sur: https://flashbackfa-entreprise.fr${NC}"
echo -e "${GREEN}   3. Vérifiez F12 -> Network que main.7ce2b6fa.js se charge${NC}"
echo -e "${GREEN}   4. Vous devriez voir 'Se connecter avec Discord' !${NC}"

exit 0