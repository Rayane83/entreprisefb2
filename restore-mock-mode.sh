#!/bin/bash

echo "🎭 RESTAURATION DU MODE MOCK - Développement"
echo "============================================="

echo ""
echo "📝 Restauration de la configuration mock..."

if [ -f "/app/frontend/.env.mock.backup" ]; then
    cp /app/frontend/.env.mock.backup /app/frontend/.env
    echo "✅ Configuration mock restaurée depuis la sauvegarde"
else
    # Configuration mock par défaut
    cat > /app/frontend/.env << 'EOF'
# MODE DÉVELOPPEMENT TEMPORAIRE POUR TESTS
NODE_ENV=development
REACT_APP_PRODUCTION_MODE=false
REACT_APP_USE_MOCK_AUTH=true
REACT_APP_FORCE_DISCORD_AUTH=false

# Backend API - Local pour développement
REACT_APP_BACKEND_URL=http://localhost:8001

# Supabase PRODUCTION
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwMzI2NDksImV4cCI6MjA3MjYwODY0OX0.nYFZjQoC6-U2zdgaaYqj3GYWByqWvoa1RconWuOOuiw

# Discord PRODUCTION - Serveur Flashback Fa
REACT_APP_DISCORD_GUILD_ID=1404608015230832742

# Désactiver développement
REACT_APP_DISABLE_DEVTOOLS=true
GENERATE_SOURCEMAP=false
WDS_SOCKET_PORT=443
EOF
    echo "✅ Configuration mock par défaut créée"
fi

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
echo "🎉 MODE MOCK RESTAURÉ !"
echo "============================================="
echo ""
echo "📍 L'application utilise maintenant:"
echo "   🎭 Mode mock (connexion automatique)"
echo "   👤 Utilisateur: Staff (accès complet)"
echo "   🌐 Backend local"
echo ""
echo "🔗 URL: http://localhost:3000"
echo "============================================="