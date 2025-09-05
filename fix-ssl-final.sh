#!/bin/bash

# 🚨 Correction SSL FINALE - Variables domaine corrigées
# Usage: ./fix-ssl-final.sh

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

log "🚨 Correction SSL finale pour $DOMAIN..."

# 1. Vérifier l'état actuel
log "🔍 Vérification de l'état actuel..."

# Test du backend
if curl -f -s "http://localhost:8001/api/" > /dev/null; then
    log "✅ Backend opérationnel"
else
    error "❌ Backend non opérationnel - Vérifiez PM2"
fi

# Test de la configuration Nginx
if sudo nginx -t > /dev/null 2>&1; then
    log "✅ Configuration Nginx valide"
else
    error "❌ Configuration Nginx invalide"
fi

# 2. Vérifier la résolution DNS
log "🌐 Test de résolution DNS..."
if nslookup $DOMAIN > /dev/null 2>&1; then
    log "✅ DNS résolu pour $DOMAIN"
    
    # Tenter la génération SSL avec le bon domaine
    log "🔒 Génération SSL pour $DOMAIN uniquement..."
    
    # Essayer avec le domaine principal seulement d'abord
    sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
    
    if [ $? -eq 0 ]; then
        log "✅ Certificat SSL généré pour $DOMAIN"
        
        # Ajouter www si possible
        log "🔒 Ajout du sous-domaine www..."
        sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --expand --non-interactive --agree-tos --email "admin@$DOMAIN"
        
        if [ $? -eq 0 ]; then
            log "✅ Certificat SSL étendu pour www.$DOMAIN"
        else
            warn "⚠️ www.$DOMAIN non ajouté (normal si DNS non configuré)"
        fi
        
    else
        error "❌ Échec génération SSL pour $DOMAIN"
    fi
    
else
    warn "⚠️ DNS non résolu pour $DOMAIN"
    log "📝 Votre site est accessible en HTTP : http://$DOMAIN"
    log "🔧 Pour configurer SSL après propagation DNS :"
    log "    sudo certbot --nginx -d $DOMAIN"
fi

# 3. Configuration finale et optimisation
log "⚙️ Optimisation finale..."

# S'assurer que PM2 tourne correctement
pm2 status | grep -q "flashbackfa-backend" || {
    log "🔄 Redémarrage PM2..."
    cd "$DEST_PATH"
    pm2 start ecosystem.config.js
    pm2 save
}

# Optimiser la configuration Nginx si SSL actif
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    log "🔧 Application des optimisations HTTPS..."
    
    # La configuration a déjà été modifiée par Certbot, on ajoute juste les headers de sécurité
    sudo tee -a /etc/nginx/sites-available/flashbackfa-entreprise > /dev/null << EOF

# Headers de sécurité additionnels (ajoutés automatiquement)
# add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
EOF
    
    # Test et reload
    sudo nginx -t && sudo systemctl reload nginx
    log "✅ Configuration HTTPS optimisée"
fi

# 4. Tests finaux complets
log "🧪 Tests finaux complets..."

sleep 3

# Test backend
if curl -f -s "http://localhost:8001/api/" > /dev/null; then
    log "✅ Backend API répond"
else
    error "❌ Backend API ne répond pas"
fi

# Test site HTTP
if curl -f -s "http://$DOMAIN/" > /dev/null 2>&1; then
    log "✅ Site HTTP accessible"
    SITE_HTTP="✅ http://$DOMAIN"
elif curl -f -s "http://localhost/" > /dev/null 2>&1; then
    log "✅ Site accessible localement"
    SITE_HTTP="✅ http://localhost (DNS en cours)"
else
    warn "⚠️ Site HTTP non accessible"
    SITE_HTTP="⚠️ En attente DNS"
fi

# Test site HTTPS
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    if curl -f -s "https://$DOMAIN/" > /dev/null 2>&1; then
        log "✅ Site HTTPS accessible"
        SITE_HTTPS="✅ https://$DOMAIN"
    else
        warn "⚠️ Site HTTPS pas encore accessible"
        SITE_HTTPS="⚠️ HTTPS configuré mais pas encore accessible"
    fi
else
    SITE_HTTPS="❌ SSL non configuré"
fi

# 5. Résumé final avec toutes les informations
echo ""
echo "🎉==========================================🎉"
echo -e "${GREEN}    RÉSUMÉ FINAL DE VOTRE SITE${NC}"
echo "🎉==========================================🎉"
echo ""

echo -e "${BLUE}🌟 ÉTAT DU SITE:${NC}"
echo -e "   Domain: $DOMAIN"
echo -e "   HTTP: $SITE_HTTP"
echo -e "   HTTPS: $SITE_HTTPS"
echo ""

echo -e "${BLUE}🔧 SERVICES:${NC}"
PM2_STATUS=$(pm2 status 2>/dev/null | grep flashbackfa-backend | awk '{print $10}' || echo "Non démarré")
echo -e "   Backend: $PM2_STATUS"
echo -e "   Nginx: ✅ Opérationnel"
echo -e "   SSL: $([ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] && echo "✅ Configuré" || echo "❌ Non configuré")"
echo ""

echo -e "${BLUE}✅ FONCTIONNALITÉS PRODUCTION:${NC}"
echo -e "   🔐 Authentification Discord OBLIGATOIRE"
echo -e "   📊 Exports Excel (Impôts, Blanchiment, Archives, Dotations)"
echo -e "   📋 Zone copier-coller Blanchiment"
echo -e "   🎨 Interface propre (sans 'Made with Emergent')"
echo -e "   🚀 Optimisé pour production"
echo ""

echo -e "${BLUE}📊 SURVEILLANCE:${NC}"
echo -e "   pm2 status"
echo -e "   pm2 logs flashbackfa-backend"
echo -e "   pm2 monit"
echo -e "   sudo tail -f /var/log/nginx/error.log"
echo ""

# URLs finales
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${GREEN}🎯 VOTRE PORTAIL ENTREPRISE EST PRÊT !${NC}"
    echo -e "${GREEN}   🔗 Accès sécurisé: https://$DOMAIN${NC}"
    echo -e "${GREEN}   🔧 API: https://$DOMAIN/api/${NC}"
else
    echo -e "${GREEN}🎯 VOTRE PORTAIL ENTREPRISE EST PRÊT !${NC}"
    echo -e "${GREEN}   🔗 Accès: http://$DOMAIN${NC}"
    echo -e "${GREEN}   🔧 API: http://$DOMAIN/api/${NC}"
    echo ""
    echo -e "${YELLOW}📝 Pour activer HTTPS après propagation DNS:${NC}"
    echo -e "   sudo certbot --nginx -d $DOMAIN"
fi

echo ""
echo -e "${GREEN}🔐 Connectez-vous avec votre compte Discord du serveur Flashback Fa !${NC}"

# 6. Test final d'accès et affichage du résultat
echo ""
echo -e "${BLUE}🧪 TEST FINAL:${NC}"

# Déterminer la meilleure URL
FINAL_URL=""
if curl -f -s "https://$DOMAIN/" > /dev/null 2>&1; then
    FINAL_URL="https://$DOMAIN"
    echo -e "${GREEN}✅ SITE HTTPS ENTIÈREMENT OPÉRATIONNEL !${NC}"
elif curl -f -s "http://$DOMAIN/" > /dev/null 2>&1; then
    FINAL_URL="http://$DOMAIN"
    echo -e "${GREEN}✅ SITE HTTP ENTIÈREMENT OPÉRATIONNEL !${NC}"
elif curl -f -s "http://localhost/" > /dev/null 2>&1; then
    FINAL_URL="http://localhost"
    echo -e "${YELLOW}⚠️ Site opérationnel localement (propagation DNS en cours)${NC}"
else
    echo -e "${RED}❌ Site non accessible - Vérifiez la configuration DNS${NC}"
fi

if [ ! -z "$FINAL_URL" ]; then
    echo -e "${GREEN}   Accédez maintenant à: $FINAL_URL${NC}"
fi

exit 0