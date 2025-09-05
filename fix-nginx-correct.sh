#!/bin/bash

# 🔧 Correction DÉFINITIVE Nginx - Configuration PROPRE
# Usage: ./fix-nginx-correct.sh

set -e

DOMAIN="flashbackfa-entreprise.fr"
DEST_PATH="/var/www/flashbackfa-entreprise.fr"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log "🔧 Correction DÉFINITIVE de la configuration Nginx..."

# 1. Configuration Nginx HTTP PROPRE (sans SSL, sans locations imbriquées)
log "🌐 Création configuration Nginx HTTP propre..."

sudo tee /etc/nginx/sites-available/flashbackfa-entreprise << EOF
# Configuration HTTP PROPRE - Flashback Fa Entreprise
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Logs
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
    
    # Assets statiques avec cache long
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|webp|svg|woff|woff2|ttf|eot)$ {
        root $DEST_PATH/frontend/build;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
        try_files \$uri =404;
    }
    
    # Frontend - Application React (catch-all)
    location / {
        root $DEST_PATH/frontend/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        # Headers pour HTML
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        application/javascript
        application/json
        application/xml
        text/css
        text/javascript
        text/plain
        text/xml;
    
    # Headers de sécurité basiques
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

# 2. Test de la configuration HTTP
log "🧪 Test de la configuration Nginx HTTP..."
sudo nginx -t

if [ $? -ne 0 ]; then
    error "❌ Configuration Nginx HTTP invalide"
fi

log "✅ Configuration Nginx HTTP valide"

# 3. Activation et redémarrage
log "🔄 Activation de la configuration..."
sudo systemctl reload nginx

# 4. Test d'accès
log "🌐 Test d'accès au site..."
sleep 3

# Test backend
if curl -f -s "http://localhost:8001/api/" > /dev/null; then
    log "✅ Backend accessible"
else
    error "❌ Backend non accessible"
fi

# Test site HTTP
if curl -f -s "http://$DOMAIN/" > /dev/null 2>&1; then
    log "✅ Site HTTP accessible"
elif curl -f -s "http://localhost/" > /dev/null 2>&1; then
    log "⚠️ Site accessible localement (DNS peut prendre du temps)"
else
    log "⚠️ Site pas encore accessible (normal si DNS pas propagé)"
fi

# 5. Installation Certbot
log "📦 Vérification Certbot..."
if ! command -v certbot &> /dev/null; then
    log "Installation de Certbot..."
    sudo apt update
    sudo apt install certbot python3-certbot-nginx -y
fi

# 6. Génération SSL avec Certbot (il modifiera automatiquement la config)
log "🔒 Génération du certificat SSL..."
sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"

if [ $? -eq 0 ]; then
    log "✅ Certificat SSL généré avec succès"
    log "✅ Certbot a automatiquement configuré HTTPS"
    
    # Tester HTTPS
    sleep 2
    if curl -f -s "https://$DOMAIN/" > /dev/null 2>&1; then
        log "✅ Site HTTPS accessible"
    else
        log "⚠️ Site HTTPS pas encore accessible (peut prendre quelques secondes)"
    fi
    
else
    log "⚠️ Certificat SSL non généré automatiquement"
    log "📝 Configuration manuelle SSL possible plus tard"
fi

# 7. Configuration finale PM2 (simple et propre)
log "🔄 Configuration PM2..."

# Arrêter les anciens processus
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Configuration PM2 simple
cat > "$DEST_PATH/ecosystem.config.js" << EOF
module.exports = {
  apps: [
    {
      name: 'flashbackfa-backend',
      cwd: '$DEST_PATH/backend',
      script: 'venv/bin/python',
      args: '-m uvicorn server:app --host 0.0.0.0 --port 8001',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 8001
      },
      log_file: '$DEST_PATH/logs/app.log',
      time: true
    }
  ]
};
EOF

# Créer dossier logs
mkdir -p "$DEST_PATH/logs"

# Démarrer PM2
cd "$DEST_PATH"
pm2 start ecosystem.config.js
pm2 save

# 8. Tests finaux
log "🧪 Tests finaux..."

sleep 5

# Test configuration Nginx
sudo nginx -t || error "Configuration Nginx finale invalide"

# Test PM2
if pm2 status | grep -q "online"; then
    log "✅ PM2 backend opérationnel"
else
    log "⚠️ PM2 backend peut avoir des problèmes"
fi

# Test backend
if curl -f -s "http://localhost:8001/api/" > /dev/null; then
    log "✅ Backend API répond"
else
    error "❌ Backend API ne répond pas"
fi

# 9. Informations finales
echo ""
echo "🎉========================================🎉"
echo -e "${GREEN}   CONFIGURATION NGINX CORRIGÉE !${NC}"
echo "🎉========================================🎉"
echo ""

# Déterminer l'URL finale
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    SITE_URL="https://$DOMAIN"
    API_URL="https://$DOMAIN/api/"
    SSL_STATUS="✅ SSL Actif"
else
    SITE_URL="http://$DOMAIN"
    API_URL="http://$DOMAIN/api/"
    SSL_STATUS="⚠️ SSL à configurer"
fi

echo -e "${BLUE}🌟 VOTRE SITE PRODUCTION:${NC}"
echo -e "   🔗 Site: $SITE_URL"
echo -e "   🔧 API: $API_URL"
echo -e "   🔒 $SSL_STATUS"
echo ""
echo -e "${BLUE}📊 STATUT SERVICES:${NC}"
echo -e "   Backend: \$(pm2 status | grep flashbackfa-backend | awk '{print \$10}')"
echo -e "   Nginx: ✅ Opérationnel"
echo ""
echo -e "${BLUE}📝 COMMANDES UTILES:${NC}"
echo -e "   pm2 status"
echo -e "   pm2 logs flashbackfa-backend"
echo -e "   sudo nginx -t"
echo -e "   sudo systemctl status nginx"
echo ""

# Test final d'accès
echo -e "${BLUE}🧪 TEST FINAL:${NC}"
if curl -f -s "$SITE_URL/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ SITE ENTIÈREMENT OPÉRATIONNEL !${NC}"
    echo -e "${GREEN}   Accédez à: $SITE_URL${NC}"
else
    echo -e "⚠️ Site pas encore accessible publiquement"
    echo -e "   Vérifiez que votre DNS pointe vers ce serveur"
    echo -e "   Test local: curl -I http://localhost/"
fi

echo ""
echo -e "${GREEN}🎯 CONFIGURATION NGINX PROPRE ET FONCTIONNELLE !${NC}"

exit 0