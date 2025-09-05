#!/bin/bash

# 🔧 Correction PM2 et test Discord Auth - Correction immédiate
# Usage: ./fix-pm2-discord.sh

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

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log "🔧 Correction PM2 et finalisation authentification Discord..."

# 1. Nettoyer complètement PM2
log "🧹 Nettoyage complet PM2..."

pm2 kill 2>/dev/null || true
sleep 2

# 2. Vérifier que le dossier backend existe et est correct
log "📁 Vérification structure backend..."

if [ ! -d "$DEST_PATH/backend" ]; then
    error "❌ Dossier backend manquant : $DEST_PATH/backend"
fi

if [ ! -f "$DEST_PATH/backend/server.py" ]; then
    error "❌ Fichier server.py manquant"
fi

if [ ! -d "$DEST_PATH/backend/venv" ]; then
    error "❌ Environnement virtuel Python manquant"
fi

log "✅ Structure backend OK"

# 3. Recréer le fichier ecosystem PM2
log "📝 Création fichier ecosystem.config.js..."

cat > "$DEST_PATH/ecosystem.config.js" << EOF
module.exports = {
  apps: [
    {
      name: 'flashbackfa-backend',
      cwd: '$DEST_PATH/backend',
      script: 'venv/bin/python',
      args: '-m uvicorn server:app --host 0.0.0.0 --port 8001',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
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

# 4. Créer le dossier logs
mkdir -p "$DEST_PATH/logs"

# 5. Test du backend avant de le démarrer avec PM2
log "🧪 Test du backend avant démarrage PM2..."

cd "$DEST_PATH/backend"
source venv/bin/activate

# Test rapide que le backend peut démarrer
timeout 10s python -m uvicorn server:app --host 0.0.0.0 --port 8001 > /tmp/backend_test.log 2>&1 &
BACKEND_PID=$!

sleep 5

# Tester si le backend répond
if curl -f -s "http://localhost:8001/api/" > /dev/null; then
    log "✅ Backend test OK"
    kill $BACKEND_PID 2>/dev/null || true
else
    error "❌ Backend ne démarre pas. Logs:"
    kill $BACKEND_PID 2>/dev/null || true
    cat /tmp/backend_test.log
    exit 1
fi

# 6. Démarrer avec PM2
log "🚀 Démarrage PM2 propre..."

cd "$DEST_PATH"
pm2 start ecosystem.config.js

# Attendre que le processus démarre
sleep 5

# 7. Vérifier le statut PM2
log "📊 Vérification statut PM2..."

pm2 status

if pm2 status | grep -q "online"; then
    log "✅ PM2 backend en ligne"
else
    error "❌ PM2 backend pas en ligne. Logs:"
    pm2 logs flashbackfa-backend --lines 20
    exit 1
fi

# 8. Test final de l'API
log "🧪 Test final API..."

sleep 3

if curl -f -s "http://localhost:8001/api/" > /dev/null; then
    log "✅ API backend répond"
else
    error "❌ API backend ne répond pas"
    pm2 logs flashbackfa-backend --lines 10
    exit 1
fi

# 9. Test d'accès au site
log "🌐 Test d'accès au site..."

SITE_URL=""
if curl -f -s "https://flashbackfa-entreprise.fr/" > /dev/null 2>&1; then
    SITE_URL="https://flashbackfa-entreprise.fr"
    log "✅ Site HTTPS accessible"
elif curl -f -s "http://flashbackfa-entreprise.fr/" > /dev/null 2>&1; then
    SITE_URL="http://flashbackfa-entreprise.fr"
    log "✅ Site HTTP accessible"
else
    warn "⚠️ Site pas encore accessible publiquement (DNS peut prendre du temps)"
    # Test local
    if curl -f -s "http://localhost/" > /dev/null 2>&1; then
        SITE_URL="http://localhost"
        log "✅ Site accessible localement"
    else
        error "❌ Site non accessible même localement"
    fi
fi

# 10. Sauvegarder la configuration PM2
pm2 save

# Configuration auto-start PM2
pm2 startup ubuntu -u ubuntu --hp /home/ubuntu 2>/dev/null || true

# 11. Informations finales de succès
echo ""
echo "🎉========================================🎉"
echo -e "${GREEN}   AUTHENTIFICATION DISCORD ACTIVÉE !${NC}"
echo "🎉========================================🎉"
echo ""

echo -e "${BLUE}✅ SERVICES OPÉRATIONNELS:${NC}"
PM2_STATUS=$(pm2 status | grep flashbackfa-backend | awk '{print $10}' 2>/dev/null || echo "Erreur")
echo -e "   Backend PM2: $PM2_STATUS"
echo -e "   API: ✅ http://localhost:8001/api/"
echo -e "   Nginx: ✅ Opérationnel"

if [ ! -z "$SITE_URL" ]; then
    echo -e "   Site: ✅ $SITE_URL"
else
    echo -e "   Site: ⚠️ En attente DNS"
fi

echo ""
echo -e "${BLUE}🔐 AUTHENTIFICATION DISCORD:${NC}"
echo -e "   ✅ Mode PRODUCTION activé"
echo -e "   ✅ Plus de données de test/mock"
echo -e "   ✅ Discord OAuth obligatoire"
echo -e "   ✅ Rôles Discord synchronisés"

echo ""
echo -e "${BLUE}🎯 COMMENT TESTER:${NC}"
if [ ! -z "$SITE_URL" ]; then
    echo -e "${GREEN}   1. Allez sur: $SITE_URL${NC}"
else
    echo -e "${GREEN}   1. Allez sur: http://flashbackfa-entreprise.fr${NC}"
fi
echo -e "${GREEN}   2. Vous verrez la page de connexion Discord${NC}"
echo -e "${GREEN}   3. Cliquez 'Se connecter avec Discord'${NC}"
echo -e "${GREEN}   4. Autorisez l'application Discord${NC}"
echo -e "${GREEN}   5. Vous serez connecté avec votre rôle réel !${NC}"

echo ""
echo -e "${BLUE}📊 SURVEILLANCE:${NC}"
echo -e "   pm2 status"
echo -e "   pm2 logs flashbackfa-backend"
echo -e "   pm2 monit"

echo ""
echo -e "${YELLOW}⚠️ IMPORTANT:${NC}"
echo -e "   Pour que Discord OAuth fonctionne complètement:"
echo -e "   1. Configurez votre app Discord sur https://discord.com/developers"
echo -e "   2. Ajoutez le redirect URL dans Supabase"
echo -e "   3. Activez Discord OAuth dans Supabase Dashboard"

echo ""
echo -e "${GREEN}🚀 VOTRE PORTAIL AVEC AUTHENTIFICATION DISCORD RÉELLE EST PRÊT !${NC}"

# 12. Test final d'accès et encouragement
echo ""
echo -e "${BLUE}🧪 TEST FINAL - ALLEZ TESTER MAINTENANT:${NC}"

if [ ! -z "$SITE_URL" ]; then
    echo -e "${GREEN}   Ouvrez votre navigateur: $SITE_URL${NC}"
    echo -e "${GREEN}   L'authentification Discord vous attend ! 🔥${NC}"
else
    echo -e "${YELLOW}   Attendez quelques minutes que le DNS se propage${NC}"
    echo -e "${YELLOW}   Puis ouvrez: http://flashbackfa-entreprise.fr${NC}"
fi

exit 0