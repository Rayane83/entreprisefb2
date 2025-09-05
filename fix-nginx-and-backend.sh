#!/bin/bash

# 🔧 CORRECTION NGINX + BACKEND - flashbackfa-entreprise.fr

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 CORRECTION NGINX + BACKEND${NC}"

DOMAIN="flashbackfa-entreprise.fr"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fonction: Correction configuration Nginx (HTTP d'abord, SSL plus tard)
fix_nginx_config() {
    echo -e "${BLUE}Correction configuration Nginx...${NC}"
    
    # Configuration Nginx HTTP seulement (SSL ajouté après certbot)
    sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << 'EOF'
server {
    listen 80;
    server_name flashbackfa-entreprise.fr www.flashbackfa-entreprise.fr;
    
    # Frontend (React)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
    
    # Security headers (basic)
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF

    # Tester et recharger Nginx
    if sudo nginx -t; then
        sudo systemctl reload nginx
        echo -e "${GREEN}✅ Configuration Nginx corrigée et rechargée${NC}"
    else
        echo -e "${RED}❌ Erreur configuration Nginx${NC}"
        return 1
    fi
}

# Fonction: Diagnostic et correction backend
fix_backend_issues() {
    echo -e "${BLUE}Diagnostic backend...${NC}"
    
    # Vérifier si le processus backend fonctionne
    if [[ -f "$SCRIPT_DIR/.backend_pid" ]]; then
        BACKEND_PID=$(cat "$SCRIPT_DIR/.backend_pid")
        if kill -0 "$BACKEND_PID" 2>/dev/null; then
            echo -e "${GREEN}✅ Processus backend actif (PID: $BACKEND_PID)${NC}"
        else
            echo -e "${YELLOW}⚠️  Processus backend mort, redémarrage...${NC}"
            start_backend
        fi
    else
        echo -e "${YELLOW}⚠️  PID backend non trouvé, démarrage...${NC}"
        start_backend
    fi
    
    # Vérifier les logs backend
    if [[ -f "$SCRIPT_DIR/backend_production.log" ]]; then
        echo -e "${BLUE}Dernières lignes des logs backend:${NC}"
        tail -n 10 "$SCRIPT_DIR/backend_production.log"
    fi
}

# Fonction: Démarrage/redémarrage backend
start_backend() {
    echo -e "${BLUE}Démarrage backend...${NC}"
    
    cd "$SCRIPT_DIR/backend"
    
    # Activer l'environnement virtuel
    if [[ -d "$SCRIPT_DIR/venv" ]]; then
        source "$SCRIPT_DIR/venv/bin/activate"
        echo "Environnement virtuel activé"
    fi
    
    # Arrêter l'ancien processus
    pkill -f "python.*server.py" 2>/dev/null || true
    sleep 2
    
    # Démarrer le nouveau processus
    nohup python server.py > "$SCRIPT_DIR/backend_production.log" 2>&1 &
    BACKEND_PID=$!
    echo "$BACKEND_PID" > "$SCRIPT_DIR/.backend_pid"
    
    echo -e "${GREEN}✅ Backend redémarré (PID: $BACKEND_PID)${NC}"
    cd "$SCRIPT_DIR"
}

# Fonction: Test connectivité amélioré
test_connectivity_detailed() {
    echo -e "${BLUE}Test de connectivité détaillé...${NC}"
    sleep 5
    
    # Test backend direct
    echo "Test backend localhost:8000..."
    for i in {1..5}; do
        if curl -s -f http://localhost:8000/health >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Backend accessible directement${NC}"
            break
        elif curl -s http://localhost:8000/ >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Backend répond (pas de /health)${NC}"
            break
        elif [[ $i -eq 5 ]]; then
            echo -e "${YELLOW}⚠️  Backend non accessible après 5 tentatives${NC}"
            echo "Tentative de connexion simple:"
            curl -v http://localhost:8000/ 2>&1 | head -10
        else
            echo "Tentative $i/5..."
            sleep 2
        fi
    done
    
    # Test frontend
    echo "Test frontend localhost:3000..."
    if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend non accessible${NC}"
    fi
    
    # Test via Nginx
    echo "Test via Nginx..."
    if curl -s -f http://localhost/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend accessible via Nginx${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend non accessible via Nginx${NC}"
    fi
}

# Fonction: Configuration SSL automatique (optionnel)
setup_ssl_optional() {
    echo -e "${BLUE}Configuration SSL (optionnel)...${NC}"
    echo ""
    echo -e "${YELLOW}Voulez-vous configurer SSL/HTTPS maintenant ? (y/N)${NC}"
    read -r -n 1 SSL_CHOICE
    echo ""
    
    if [[ $SSL_CHOICE =~ ^[Yy]$ ]]; then
        echo "Configuration SSL avec certbot..."
        if sudo certbot --nginx -d flashbackfa-entreprise.fr -d www.flashbackfa-entreprise.fr --non-interactive --agree-tos --email admin@flashbackfa-entreprise.fr; then
            echo -e "${GREEN}✅ SSL configuré avec succès${NC}"
            sudo systemctl enable certbot.timer
        else
            echo -e "${YELLOW}⚠️  SSL non configuré - configurez plus tard avec:${NC}"
            echo "sudo certbot --nginx -d flashbackfa-entreprise.fr -d www.flashbackfa-entreprise.fr"
        fi
    else
        echo -e "${YELLOW}SSL non configuré - configurez plus tard si nécessaire${NC}"
    fi
}

# Fonction: Rapport final
show_status_report() {
    echo ""
    echo -e "${GREEN}🎉 CORRECTIONS APPLIQUÉES${NC}"
    echo ""
    echo -e "${BLUE}📊 STATUT SERVICES:${NC}"
    
    # Statut Nginx
    if systemctl is-active --quiet nginx; then
        echo "   ✅ Nginx: ACTIF"
    else
        echo "   ❌ Nginx: INACTIF"
    fi
    
    # Statut Backend
    if [[ -f "$SCRIPT_DIR/.backend_pid" ]] && kill -0 "$(cat "$SCRIPT_DIR/.backend_pid")" 2>/dev/null; then
        echo "   ✅ Backend: ACTIF (PID: $(cat "$SCRIPT_DIR/.backend_pid"))"
    else
        echo "   ❌ Backend: INACTIF"
    fi
    
    # Statut Frontend
    if [[ -f "$SCRIPT_DIR/.frontend_pid" ]] && kill -0 "$(cat "$SCRIPT_DIR/.frontend_pid")" 2>/dev/null; then
        echo "   ✅ Frontend: ACTIF (PID: $(cat "$SCRIPT_DIR/.frontend_pid"))"
    else
        echo "   ❌ Frontend: INACTIF"
    fi
    
    echo ""
    echo -e "${BLUE}🌐 ACCÈS:${NC}"
    echo "   🌐 Site Web: http://flashbackfa-entreprise.fr/"
    echo "   🔧 API: http://flashbackfa-entreprise.fr/api/"
    echo "   💊 Health: http://flashbackfa-entreprise.fr/health"
    echo ""
    echo "   🏠 Local Frontend: http://localhost:3000"
    echo "   🔧 Local Backend: http://localhost:8000"
    echo ""
    echo -e "${BLUE}📋 LOGS:${NC}"
    echo "   📋 Backend: tail -f backend_production.log"
    echo "   📋 Frontend: tail -f frontend_production.log"
    echo "   📋 Nginx: sudo tail -f /var/log/nginx/access.log"
}

# Exécution principale
main() {
    fix_nginx_config
    fix_backend_issues
    test_connectivity_detailed
    setup_ssl_optional
    show_status_report
}

# Lancer les corrections
main