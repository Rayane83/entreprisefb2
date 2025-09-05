#!/bin/bash

echo "🔄 BASCULEMENT VERS MODE PRODUCTION - Discord Auth Réel"
echo "======================================================="

echo ""
echo "⚠️  ATTENTION: Ce script va:"
echo "   - Désactiver le mode mock"
echo "   - Activer l'authentification Discord réelle"
echo "   - Redémarrer les services"
echo ""

read -p "Voulez-vous continuer? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ Opération annulée"
    exit 0
fi

echo ""
echo "📝 Configuration du mode production..."

# Backup du .env actuel
cp /app/frontend/.env /app/frontend/.env.mock.backup

# Modification des variables pour production
sed -i 's/NODE_ENV=development/NODE_ENV=production/' /app/frontend/.env
sed -i 's/REACT_APP_PRODUCTION_MODE=false/REACT_APP_PRODUCTION_MODE=true/' /app/frontend/.env
sed -i 's/REACT_APP_USE_MOCK_AUTH=true/REACT_APP_USE_MOCK_AUTH=false/' /app/frontend/.env
sed -i 's/REACT_APP_FORCE_DISCORD_AUTH=false/REACT_APP_FORCE_DISCORD_AUTH=true/' /app/frontend/.env
sed -i 's|REACT_APP_BACKEND_URL=http://localhost:8001|REACT_APP_BACKEND_URL=https://enterprise-portal-2.preview.emergentagent.com|' /app/frontend/.env

echo "✅ Configuration production appliquée"

echo ""
echo "🔄 Redémarrage des services..."
sudo supervisorctl restart all

echo ""
echo "⏳ Attente du démarrage (15 secondes)..."
sleep 15

echo ""
echo "✅ Vérification de l'état..."
sudo supervisorctl status

echo ""
echo "🎉 MODE PRODUCTION ACTIVÉ !"
echo "======================================================="
echo ""
echo "📍 L'application utilise maintenant:"
echo "   🔐 Authentification Discord réelle"
echo "   🌐 URL backend production"
echo "   🚫 Mode mock désactivé"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Sauvegarde du mode mock: /app/frontend/.env.mock.backup"
echo "   - Pour revenir au mock: bash /app/restore-mock-mode.sh"
echo ""
echo "🔗 URL: http://localhost:3000"
echo "======================================================="