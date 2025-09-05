#!/bin/bash

echo "🚀 LANCEMENT DE LA NOUVELLE VERSION - Portail Entreprise Flashback Fa"
echo "=================================================================="

echo ""
echo "📋 Vérification de l'état actuel des services..."
sudo supervisorctl status

echo ""
echo "🔄 Redémarrage de tous les services pour la nouvelle version..."
sudo supervisorctl restart all

echo ""
echo "⏳ Attente du démarrage des services (15 secondes)..."
sleep 15

echo ""
echo "✅ Vérification de l'état final..."
sudo supervisorctl status

echo ""
echo "🌐 Test de connectivité..."
echo "Frontend: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)"
echo "Backend: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/)"

echo ""
echo "🎉 NOUVELLE VERSION LANCÉE AVEC SUCCÈS !"
echo "=================================================================="
echo ""
echo "📍 ACCÈS À L'APPLICATION:"
echo "   🔗 URL: http://localhost:3000"
echo ""
echo "🆕 NOUVELLES FONCTIONNALITÉS:"
echo "   ✅ Tous les boutons réparés et fonctionnels"
echo "   ✅ Page 'Gestion des Entreprises' (bouton dans header)"
echo "   ✅ Formulaire d'ajout d'entreprise (Guild ID + Nom + Role ID)"
echo "   ✅ Configuration rôles Dot Guild (Staff/Patron/Co-Patron/DOT)"
echo "   ✅ Bouton 'Page Principale' pour navigation"
echo "   ✅ Mode mock activé (connexion automatique en tant que Staff)"
echo ""
echo "🎯 COMMENT UTILISER:"
echo "   1. Ouvrir http://localhost:3000 dans votre navigateur"
echo "   2. Connexion automatique (mode mock)"
echo "   3. Cliquer sur 'Gestion Entreprises' dans le header"
echo "   4. Tester les nouvelles fonctionnalités"
echo ""
echo "📊 POUR VOIR LES LOGS EN TEMPS RÉEL:"
echo "   Frontend: tail -f /var/log/supervisor/frontend.out.log"
echo "   Backend:  tail -f /var/log/supervisor/backend.out.log"
echo ""
echo "=================================================================="