#!/bin/bash

# 🔧 AJOUT Bouton retour page principale dans SuperAdmin
# Usage: ./add-superadmin-home-button.sh

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

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log "🔧 AJOUT Bouton retour page principale dans SuperAdmin"

# 1. Vérification fichier SuperAdmin existe
if [ ! -f "$DEST_PATH/frontend/src/pages/Superadmin.js" ]; then
    error "❌ Fichier Superadmin.js non trouvé"
    exit 1
fi

log "✅ Fichier Superadmin.js trouvé"

# 2. Backup du fichier actuel
cp "$DEST_PATH/frontend/src/pages/Superadmin.js" "$DEST_PATH/frontend/src/pages/Superadmin.js.backup"
log "✅ Backup créé"

# 3. Vérifier si bouton existe déjà
if grep -q "Page Principale" "$DEST_PATH/frontend/src/pages/Superadmin.js"; then
    log "✅ Bouton 'Page Principale' déjà présent"
else
    log "🔧 Ajout du bouton 'Page Principale'..."
    
    # Vérifier les imports
    if ! grep -q "Home" "$DEST_PATH/frontend/src/pages/Superadmin.js"; then
        # Ajouter import Home si pas présent
        sed -i '/from ['\''"]lucide-react['\''"];/s/} from/Home, &/' "$DEST_PATH/frontend/src/pages/Superadmin.js"
        log "✅ Import Home ajouté"
    fi
    
    # Ajouter le bouton dans le header de la page
    # Chercher la première div avec classe container et ajouter le bouton
    sed -i '/<div className="container mx-auto/,/<\/div>/s|</div>|          <Button onClick={() => navigate("/")} className="bg-green-600 hover:bg-green-700">\
            <Home className="w-4 h-4 mr-2" />\
            Page Principale\
          </Button>\
        </div>|' "$DEST_PATH/frontend/src/pages/Superadmin.js"
    
    log "✅ Bouton ajouté dans Superadmin.js"
fi

# 4. Vérifier que useNavigate est importé
if ! grep -q "useNavigate" "$DEST_PATH/frontend/src/pages/Superadmin.js"; then
    # Ajouter useNavigate si pas présent
    sed -i "s/import React/import React, { useNavigate }/" "$DEST_PATH/frontend/src/pages/Superadmin.js"
    sed -i "/from 'react-router-dom'/s/}/useNavigate, &/" "$DEST_PATH/frontend/src/pages/Superadmin.js"
    
    # Ajouter la déclaration dans le composant
    sed -i '/const.*= () => {/a\  const navigate = useNavigate();' "$DEST_PATH/frontend/src/pages/Superadmin.js"
    
    log "✅ useNavigate ajouté"
fi

# 5. Build et déploiement
log "🔨 Build avec nouveau bouton..."

cd "$DEST_PATH/frontend"
npm run build

if [ ! -f "build/index.html" ]; then
    error "❌ Build échoué"
    # Restaurer backup
    cp "$DEST_PATH/frontend/src/pages/Superadmin.js.backup" "$DEST_PATH/frontend/src/pages/Superadmin.js"
    exit 1
fi

log "✅ Build réussi"

# 6. Restart Nginx pour nouveau build
sudo systemctl reload nginx

# 7. Test final
log "🧪 Test modification..."

sleep 5

if grep -q "Page Principale" "$DEST_PATH/frontend/build/static/js/main."*.js; then
    echo "✅ Bouton 'Page Principale' détecté dans le build"
    SUCCESS=true
else
    echo "❌ Bouton non détecté dans le build"
    SUCCESS=false
fi

# 8. Résultats
log "🎯 RÉSULTATS"

if [ "$SUCCESS" = true ]; then
    log "🎉 SUCCESS - Bouton retour ajouté dans SuperAdmin !"
    
    echo ""
    echo "✅ MODIFICATION APPLIQUÉE :"
    echo "   🆕 Bouton vert 'Page Principale' ajouté"
    echo "   🏠 Navigation vers / (page d'accueil)"
    echo "   🎯 Visible dans /superadmin"
    
    echo ""
    echo "🧪 POUR TESTER :"
    echo "   1. Aller sur https://flashbackfa-entreprise.fr/"
    echo "   2. Se connecter avec Discord (rôle Staff)"
    echo "   3. Cliquer sur 'SuperStaff' dans header"
    echo "   4. Voir le bouton vert 'Page Principale'"
    echo "   5. Cliquer dessus pour retourner à l'accueil"
    
else
    error "❌ ÉCHEC - Restauration backup..."
    cp "$DEST_PATH/frontend/src/pages/Superadmin.js.backup" "$DEST_PATH/frontend/src/pages/Superadmin.js"
    cd "$DEST_PATH/frontend"
    npm run build
    sudo systemctl reload nginx
fi

log "🔧 AJOUT BOUTON SUPERADMIN TERMINÉ"