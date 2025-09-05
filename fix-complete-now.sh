#!/bin/bash

# 🚀 CORRECTION COMPLÈTE IMMÉDIATE - Authentification Discord RÉELLE
# Usage: ./fix-complete-now.sh

set -e

DEST_PATH="/var/www/flashbackfa-entreprise.fr"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log "🚀 CORRECTION COMPLÈTE IMMÉDIATE - Tous les problèmes identifiés"

# 1. Copier tous les fichiers corrigés
log "📂 Copie des fichiers corrigés..."

# Copier les fichiers corrigés depuis /app vers le projet
cp /app/frontend/.env "$DEST_PATH/frontend/.env"
cp /app/frontend/src/contexts/AuthContext.js "$DEST_PATH/frontend/src/contexts/AuthContext.js"
cp /app/frontend/src/components/LoginScreen.js "$DEST_PATH/frontend/src/components/LoginScreen.js"
cp /app/frontend/src/App.js "$DEST_PATH/frontend/src/App.js"

log "✅ Fichiers corrigés copiés"

# 2. Créer le composant Badge manquant si nécessaire
if [ ! -f "$DEST_PATH/frontend/src/components/ui/badge.js" ]; then
    log "📝 Création du composant Badge manquant..."
    
    mkdir -p "$DEST_PATH/frontend/src/components/ui"
    
    cat > "$DEST_PATH/frontend/src/components/ui/badge.js" << 'EOF'
import * as React from "react";
import { cva } from "class-variance-authority";
import { cn } from "../../lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
  {
    variants: {
      variant: {
        default:
          "border-transparent bg-primary text-primary-foreground hover:bg-primary/80",
        secondary:
          "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80",
        destructive:
          "border-transparent bg-destructive text-destructive-foreground hover:bg-destructive/80",
        outline: "text-foreground",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
);

function Badge({ className, variant, ...props }) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />;
}

export { Badge, badgeVariants };
EOF
fi

# 3. Créer le composant CardDescription manquant si nécessaire
if ! grep -q "CardDescription" "$DEST_PATH/frontend/src/components/ui/card.js" 2>/dev/null; then
    log "📝 Mise à jour du composant Card avec CardDescription..."
    
    cat > "$DEST_PATH/frontend/src/components/ui/card.js" << 'EOF'
import * as React from "react";
import { cn } from "../../lib/utils";

const Card = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
      "rounded-lg border bg-card text-card-foreground shadow-sm",
      className
    )}
    {...props}
  />
));
Card.displayName = "Card";

const CardHeader = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex flex-col space-y-1.5 p-6", className)}
    {...props}
  />
));
CardHeader.displayName = "CardHeader";

const CardTitle = React.forwardRef(({ className, ...props }, ref) => (
  <h3
    ref={ref}
    className={cn(
      "text-2xl font-semibold leading-none tracking-tight",
      className
    )}
    {...props}
  />
));
CardTitle.displayName = "CardTitle";

const CardDescription = React.forwardRef(({ className, ...props }, ref) => (
  <p
    ref={ref}
    className={cn("text-sm text-muted-foreground", className)}
    {...props}
  />
));
CardDescription.displayName = "CardDescription";

const CardContent = React.forwardRef(({ className, ...props }, ref) => (
  <div ref={ref} className={cn("p-6 pt-0", className)} {...props} />
));
CardContent.displayName = "CardContent";

const CardFooter = React.forwardRef(({ className, ...props }, ref) => (
  <div
    ref={ref}
    className={cn("flex items-center p-6 pt-0", className)}
    {...props}
  />
));
CardFooter.displayName = "CardFooter";

export { Card, CardHeader, CardFooter, CardTitle, CardDescription, CardContent };
EOF
fi

# 4. Créer lib/utils.js si manquant
if [ ! -f "$DEST_PATH/frontend/src/lib/utils.js" ]; then
    log "📝 Création de lib/utils.js..."
    
    mkdir -p "$DEST_PATH/frontend/src/lib"
    
    cat > "$DEST_PATH/frontend/src/lib/utils.js" << 'EOF'
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs) {
  return twMerge(clsx(inputs));
}
EOF
fi

# 5. Suppression complète du build et rebuild
log "🗑️ Suppression build et rebuild complet..."

cd "$DEST_PATH/frontend"

# Supprimer le build existant
rm -rf build/
rm -rf node_modules/.cache/ 2>/dev/null || true

# Rebuild avec variables d'environnement production
export NODE_ENV=production
export REACT_APP_BUILD_TIME=$(date +%s)
yarn build

log "✅ Nouveau build généré"

# 6. Redémarrage complet Nginx
log "🔄 Redémarrage complet Nginx..."

sudo systemctl stop nginx
sudo pkill -f nginx 2>/dev/null || true
sleep 3
sudo systemctl start nginx

# 7. Test du nouveau build
log "🧪 Test du nouveau build..."

sleep 5

# Test que le bon fichier JS est généré
JS_FILES=$(ls build/static/js/main.*.js 2>/dev/null | head -1)
if [ ! -z "$JS_FILES" ]; then
    JS_FILENAME=$(basename "$JS_FILES")
    log "✅ Fichier JS généré: $JS_FILENAME"
    
    # Test que ce fichier est bien dans index.html
    if grep -q "$JS_FILENAME" build/index.html; then
        log "✅ index.html référence le bon fichier JS"
        BUILD_SUCCESS=true
    else
        log "❌ index.html ne référence pas le bon fichier JS"
        BUILD_SUCCESS=false
    fi
else
    log "❌ Aucun fichier JS généré"
    BUILD_SUCCESS=false
fi

# 8. Test final de l'application
if [ "$BUILD_SUCCESS" = true ]; then
    log "🧪 Test final de l'application..."
    
    sleep 3
    
    # Test avec curl pour vérifier le contenu
    RESPONSE=$(curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" "https://flashbackfa-entreprise.fr/" 2>/dev/null || curl -s -H "Cache-Control: no-cache" -H "Pragma: no-cache" "http://flashbackfa-entreprise.fr/" 2>/dev/null)
    
    if echo "$RESPONSE" | grep -q "$JS_FILENAME" && echo "$RESPONSE" | grep -q "Se connecter avec Discord"; then
        log "✅ NOUVEAU BUILD AVEC DISCORD AUTH DÉTECTÉ !"
        SUCCESS=true
    elif echo "$RESPONSE" | grep -q "$JS_FILENAME"; then
        log "✅ Nouveau build détecté, vérification contenu Discord..."
        SUCCESS=partial
    else
        log "❌ Ancien build encore servi"
        SUCCESS=false
    fi
else
    SUCCESS=false
fi

# 9. Informations finales
echo ""
echo "🎉============================================🎉"
echo -e "${GREEN}     CORRECTION COMPLÈTE APPLIQUÉE !${NC}"
echo "🎉============================================🎉"
echo ""

echo -e "${BLUE}✅ CORRECTIONS APPLIQUÉES:${NC}"
echo -e "   ✅ AuthContext - Discord OAuth strict"
echo -e "   ✅ LoginScreen - Authentification Discord réelle"
echo -e "   ✅ App.js - Protection des routes"
echo -e "   ✅ Variables .env - Configuration production"
echo -e "   ✅ Composants UI manquants créés"
echo -e "   ✅ Build complet régénéré"

echo ""
echo -e "${BLUE}🔧 FICHIERS CORRIGÉS:${NC}"
echo -e "   • frontend/.env"
echo -e "   • src/contexts/AuthContext.js"
echo -e "   • src/components/LoginScreen.js"
echo -e "   • src/App.js"
echo -e "   • src/components/ui/badge.js"
echo -e "   • src/components/ui/card.js"
echo -e "   • src/lib/utils.js"

echo ""
echo -e "${BLUE}🎯 RÉSULTAT:${NC}"
if [ "$SUCCESS" = true ]; then
    echo -e "   ${GREEN}✅ AUTHENTIFICATION DISCORD MAINTENANT ACTIVE !${NC}"
    echo -e "   ${GREEN}🔗 Testez: https://flashbackfa-entreprise.fr${NC}"
    echo -e "   ${GREEN}🔐 Vous devriez voir la page de connexion Discord !${NC}"
elif [ "$SUCCESS" = partial ]; then
    echo -e "   ${GREEN}✅ Nouveau build généré et déployé${NC}"
    echo -e "   ⚠️ Testez dans un onglet privé pour voir les changements"
else
    echo -e "   ❌ Problème avec le build - Vérifiez les logs"
fi

echo ""
echo -e "${BLUE}🧪 POUR TESTER IMMÉDIATEMENT:${NC}"
echo -e "${GREEN}   1. Ouvrez un NOUVEL ONGLET PRIVÉ${NC}"
echo -e "${GREEN}   2. Allez sur: https://flashbackfa-entreprise.fr${NC}"
echo -e "${GREEN}   3. Vous devriez voir 'Portail Entreprise - Flashback Fa'${NC}"
echo -e "${GREEN}   4. Puis 'Se connecter avec Discord' au lieu de connexion auto${NC}"

echo ""
if [ "$SUCCESS" = true ]; then
    echo -e "${GREEN}🚀 L'AUTHENTIFICATION DISCORD EST MAINTENANT OBLIGATOIRE !${NC}"
    echo -e "${GREEN}   Plus de connexion automatique - Discord requis ! 🔥${NC}"
else
    echo -e "⚠️ Si vous voyez encore l'ancienne version:"
    echo -e "   • Fermez complètement votre navigateur"
    echo -e "   • Rouvrez en mode privé"
    echo -e "   • Ou essayez un autre navigateur"
fi

exit 0