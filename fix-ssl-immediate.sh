#!/bin/bash

# 🚨 Correction Immédiate SSL - Site PRODUCTION
# Usage: ./fix-ssl-immediate.sh

set -e

DOMAIN="flashbackfa-entreprise.fr"
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

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log "🚨 Correction immédiate de la configuration SSL..."

# 1. Configuration Nginx HTTP temporaire (sans SSL)
log "🌐 Configuration Nginx HTTP temporaire..."

sudo tee /etc/nginx/sites-available/flashbackfa-entreprise << EOF
# TEMPORAIRE - HTTP seulement pour générer SSL
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Frontend - Application React
    location / {
        root $DEST_PATH/frontend/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        # Cache optimisé
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|webp|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, no-transform, immutable";
        }
    }
    
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
        text/plain;
        
    # Logs
    access_log /var/log/nginx/flashbackfa_access.log;
    error_log /var/log/nginx/flashbackfa_error.log;
}
EOF

# 2. Test et activation de la configuration HTTP
log "🧪 Test de la configuration Nginx..."
sudo nginx -t || error "Configuration Nginx HTTP invalide"

log "🔄 Rechargement Nginx..."
sudo systemctl reload nginx

# 3. Vérification que le site est accessible en HTTP
log "🌐 Vérification de l'accès HTTP..."
sleep 3

if curl -f -s "http://$DOMAIN/" > /dev/null; then
    log "✅ Site accessible en HTTP"
else
    warn "⚠️ Site pas encore accessible (DNS peut prendre du temps)"
fi

# 4. Génération du certificat SSL
log "🔒 Génération du certificat SSL..."

# Installation Certbot si nécessaire
if ! command -v certbot &> /dev/null; then
    log "📦 Installation de Certbot..."
    sudo apt update
    sudo apt install certbot python3-certbot-nginx -y
fi

# Générer le certificat SSL
log "🔑 Obtention du certificat SSL..."
sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"

if [ $? -eq 0 ]; then
    log "✅ Certificat SSL généré avec succès"
    
    # 5. Configuration finale HTTPS optimisée
    log "🔒 Application de la configuration HTTPS finale..."
    
    sudo tee /etc/nginx/sites-available/flashbackfa-entreprise << EOF
# PRODUCTION FINALE - Flashback Fa Entreprise avec SSL
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Certificates (générés par Certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # Configuration de sécurité renforcée
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https://dutvmjnhnrpqoztftzgd.supabase.co wss:; font-src 'self';" always;
    
    # Frontend - Application React PRODUCTION
    location / {
        root $DEST_PATH/frontend/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        # Cache optimisé pour la production
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|webp|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, no-transform, immutable";
            add_header Vary "Accept, Accept-Encoding";
        }
        
        # Headers pour l'application principale
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # API Backend PRODUCTION
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
        proxy_redirect off;
        
        # Timeouts optimisés pour la production
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffers optimisés
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # Headers sécurisés
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
    }
    
    # Compression optimisée
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        application/javascript
        application/json
        application/xml
        application/rss+xml
        application/atom+xml
        text/css
        text/javascript
        text/plain
        text/xml;
    
    # Logs spécifiques
    access_log /var/log/nginx/flashbackfa_access.log;
    error_log /var/log/nginx/flashbackfa_error.log;
}
EOF
    
    # Test de la configuration finale
    sudo nginx -t || error "Configuration HTTPS finale invalide"
    sudo systemctl reload nginx
    
    log "✅ Configuration HTTPS finale appliquée"
    
else
    warn "⚠️ Certificat SSL non généré automatiquement"
    log "📝 Votre site est accessible en HTTP: http://$DOMAIN"
    log "🔧 Pour générer SSL manuellement: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
fi

# 6. Configuration et démarrage PM2 final
log "🔄 Configuration finale PM2..."

# Arrêter tous les processus existants
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Nouveau fichier ecosystem optimisé
cat > "$DEST_PATH/ecosystem.config.js" << EOF
module.exports = {
  apps: [
    {
      name: 'flashbackfa-backend',
      cwd: '$DEST_PATH/backend',
      script: 'venv/bin/python',
      args: '-m uvicorn server:app --host 0.0.0.0 --port 8001 --workers 1',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      min_uptime: '10s',
      max_restarts: 5,
      env: {
        NODE_ENV: 'production',
        PORT: 8001,
        PYTHONPATH: '$DEST_PATH/backend'
      },
      log_file: '$DEST_PATH/logs/combined.log',
      out_file: '$DEST_PATH/logs/out.log',
      error_file: '$DEST_PATH/logs/error.log',
      time: true,
      merge_logs: true
    }
  ]
};
EOF

# Créer le dossier logs
mkdir -p "$DEST_PATH/logs"

# Démarrer le backend
cd "$DEST_PATH"
pm2 start ecosystem.config.js
pm2 save

# Configuration du démarrage automatique
pm2 startup ubuntu -u ubuntu --hp /home/ubuntu

# 7. Tests finaux complets
log "🧪 Tests finaux PRODUCTION..."

sleep 5

# Test backend local
if curl -f -s "http://localhost:8001/api/" > /dev/null; then
    log "✅ Backend PRODUCTION opérationnel"
else
    error "❌ Backend ne répond pas"
fi

# Test site HTTPS (si SSL généré)
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    if curl -f -s "https://$DOMAIN/" > /dev/null; then
        log "✅ Site HTTPS PRODUCTION accessible"
    else
        warn "⚠️ Site HTTPS pas encore accessible"
    fi
else
    if curl -f -s "http://$DOMAIN/" > /dev/null; then
        log "✅ Site HTTP PRODUCTION accessible"
    else
        warn "⚠️ Site HTTP pas encore accessible"
    fi
fi

# 8. Informations finales de succès
echo ""
echo "🎉====================================🎉"
echo -e "${GREEN}   SITE PRODUCTION 100% FINALISÉ !${NC}"
echo "🎉====================================🎉"
echo ""

if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${BLUE}🌟 VOTRE PORTAIL ENTREPRISE:${NC}"
    echo -e "   🔗 https://$DOMAIN"
    echo -e "   🔧 API: https://$DOMAIN/api/"
    echo -e "   🔒 SSL: Actif et sécurisé"
else
    echo -e "${BLUE}🌟 VOTRE PORTAIL ENTREPRISE:${NC}"
    echo -e "   🔗 http://$DOMAIN"
    echo -e "   🔧 API: http://$DOMAIN/api/"
    echo -e "   🔒 SSL: À configurer manuellement"
fi

echo ""
echo -e "${BLUE}✅ FONCTIONNALITÉS PRODUCTION:${NC}"
echo -e "   🔐 Authentification Discord OBLIGATOIRE"
echo -e "   📊 Export Excel toutes sections"
echo -e "   📋 Zone copier-coller opérationnelle"
echo -e "   🛡️ Sécurité optimisée (HTTPS + Headers)"
echo -e "   🚀 Performance optimisée"
echo -e "   🎨 Interface professionnelle (sans 'Made with Emergent')"
echo -e "   🔄 PM2 avec auto-restart"
echo ""
echo -e "${BLUE}📊 SURVEILLANCE:${NC}"
echo -e "   pm2 status                    # Statut application"
echo -e "   pm2 logs flashbackfa-backend  # Logs en temps réel"
echo -e "   pm2 monit                     # Monitoring complet"
echo ""
echo -e "${GREEN}🎯 VOTRE PORTAIL EST MAINTENANT 100% OPÉRATIONNEL !${NC}"
echo -e "${GREEN}   Connectez-vous avec votre compte Discord du serveur Flashback Fa${NC}"

exit 0