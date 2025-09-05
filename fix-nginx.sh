#!/bin/bash

# 🔧 Script de correction Nginx - Configuration temporaire sans SSL
# Usage: ./fix-nginx.sh flashbackfa-entreprise.fr /var/www/flashbackfa-entreprise.fr

DOMAIN=$1
DEST_PATH=$2

echo "🔧 Correction de la configuration Nginx..."

# Configuration Nginx temporaire (HTTP seulement pour commencer)
sudo tee /etc/nginx/sites-available/flashbackfa-entreprise > /dev/null << EOF
# Configuration temporaire HTTP pour flashbackfa-entreprise.fr
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Frontend
    location / {
        root $DEST_PATH/frontend/build;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
        
        # Cache pour les assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Backend API
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
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF

echo "✅ Configuration Nginx HTTP créée"

# Test de la configuration
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration Nginx valide"
    
    # Redémarrage de Nginx
    sudo systemctl reload nginx
    echo "✅ Nginx redémarré"
    
    # Vérification que le site est accessible
    sleep 2
    if curl -f -s "http://$DOMAIN/" > /dev/null 2>&1; then
        echo "✅ Site accessible en HTTP"
    else
        echo "⚠️  Site pas encore accessible (DNS peut prendre du temps)"
    fi
    
    # Maintenant configurer SSL
    echo ""
    echo "🔒 Configuration SSL avec Certbot..."
    
    # Installation Certbot si nécessaire
    if ! command -v certbot &> /dev/null; then
        echo "📦 Installation de Certbot..."
        sudo apt update
        sudo apt install certbot python3-certbot-nginx -y
    fi
    
    # Obtention du certificat SSL
    echo "🔑 Génération du certificat SSL..."
    sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    
    if [ $? -eq 0 ]; then
        echo "✅ SSL configuré avec succès"
        echo ""
        echo "🎉 Déploiement terminé !"
        echo "   🌐 Site: https://$DOMAIN"
        echo "   🔧 API: https://$DOMAIN/api/"
    else
        echo "⚠️  SSL pas configuré automatiquement"
        echo "   🌐 Site accessible en HTTP: http://$DOMAIN"
        echo "   🔧 API: http://$DOMAIN/api/"
        echo ""
        echo "📝 Pour configurer SSL manuellement plus tard:"
        echo "   sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    fi
    
else
    echo "❌ Configuration Nginx invalide"
    exit 1
fi

# Informations finales
echo ""
echo "📊 Statut des services:"
echo "   Backend: \$(pm2 status | grep flashbackfa-backend)"
echo "   Nginx: \$(sudo systemctl status nginx --no-pager -l)"
echo ""
echo "📝 Commandes utiles:"
echo "   pm2 logs flashbackfa-backend    # Logs backend"
echo "   sudo tail -f /var/log/nginx/error.log  # Logs Nginx"
echo "   pm2 restart flashbackfa-backend # Redémarrer backend"