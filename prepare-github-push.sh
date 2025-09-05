#!/bin/bash

#################################################################
# Script de Préparation pour Push GitHub
# 
# SUPPRIME LES SECRETS AVANT GITHUB PUSH :
# - Tokens Discord
# - Clés API Supabase
# - Autres credentials sensibles
#################################################################

APP_DIR="$HOME/entreprisefb"
FRONTEND_DIR="$APP_DIR/frontend"
BACKEND_DIR="$APP_DIR/backend"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
important() { echo -e "${PURPLE}[IMPORTANT]${NC} $1"; }

important "🔐 PRÉPARATION POUR GITHUB - Suppression des secrets"

#################################################################
# 1. SAUVEGARDE DES FICHIERS AVEC SECRETS
#################################################################

log "💾 Sauvegarde des fichiers avec secrets..."

# Créer répertoire de sauvegarde
BACKUP_DIR="/tmp/secrets-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Sauvegarder les .env avec secrets
if [ -f "$FRONTEND_DIR/.env" ]; then
    cp "$FRONTEND_DIR/.env" "$BACKUP_DIR/frontend.env"
    log "Frontend .env sauvegardé"
fi

if [ -f "$BACKEND_DIR/.env" ]; then
    cp "$BACKEND_DIR/.env" "$BACKUP_DIR/backend.env"
    log "Backend .env sauvegardé"
fi

success "Secrets sauvegardés dans: $BACKUP_DIR"

#################################################################
# 2. CRÉATION DE FICHIERS .ENV SANS SECRETS
#################################################################

log "🧹 Création de fichiers .env sans secrets..."

# Frontend .env sans secrets
cd "$FRONTEND_DIR"
cat > .env << 'FRONTEND_CLEAN_EOF'
# CONFIGURATION FRONTEND - VERSION GITHUB (SANS SECRETS)
REACT_APP_BACKEND_URL=https://flashbackfa-entreprise.fr
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=VOTRE_SUPABASE_ANON_KEY_ICI

# DISCORD CONFIGURATION (À CONFIGURER EN PRODUCTION)
REACT_APP_USE_MOCK_AUTH=true
REACT_APP_DISCORD_CLIENT_ID=VOTRE_DISCORD_CLIENT_ID_ICI
REACT_APP_DISCORD_REDIRECT_URI=https://dutvmjnhnrpqoztftzgd.supabase.co/auth/v1/callback

# PRODUCTION
NODE_ENV=production
GENERATE_SOURCEMAP=false
REACT_APP_ENV=production
FRONTEND_CLEAN_EOF

# Backend .env sans secrets
cd "$BACKEND_DIR"
cat > .env << 'BACKEND_CLEAN_EOF'
# BACKEND PRODUCTION - VERSION GITHUB (SANS SECRETS)
SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
SUPABASE_SERVICE_KEY=VOTRE_SUPABASE_SERVICE_KEY_ICI

# DISCORD TOKENS (À CONFIGURER EN PRODUCTION)
DISCORD_BOT_TOKEN=VOTRE_DISCORD_BOT_TOKEN_ICI
DISCORD_CLIENT_ID=VOTRE_DISCORD_CLIENT_ID_ICI
DISCORD_CLIENT_SECRET=VOTRE_DISCORD_CLIENT_SECRET_ICI

# CORS et production
CORS_ORIGINS=https://flashbackfa-entreprise.fr,https://www.flashbackfa-entreprise.fr
ENVIRONMENT=production
DEBUG=false
BACKEND_CLEAN_EOF

success "Fichiers .env nettoyés (secrets supprimés)"

#################################################################
# 3. CRÉATION/MISE À JOUR .GITIGNORE
#################################################################

log "📝 Mise à jour .gitignore..."

cd "$APP_DIR"

# Créer/mettre à jour .gitignore
cat > .gitignore << 'GITIGNORE_EOF'
# Secrets et configuration locale
.env
.env.local
.env.production
.env.development
*.env
secrets-backup-*

# Dependencies
node_modules/
__pycache__/
*.pyc
venv/
env/

# Build outputs
build/
dist/
*.egg-info/

# Logs
*.log
logs/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# PM2
.pm2/

# Temporary folders
tmp/
temp/

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Local database
*.sqlite
*.sqlite3
*.db

# Backup files
*.backup
*.bak
*.tmp

# Cache
.cache/
.parcel-cache/
GITIGNORE_EOF

success ".gitignore mis à jour pour protéger les secrets"

#################################################################
# 4. CRÉATION FICHIER README AVEC INSTRUCTIONS
#################################################################

log "📖 Création README avec instructions de déploiement..."

cat > README.md << 'README_EOF'
# Portail Entreprise Flashback Fa

Application de gestion d'entreprise avec authentification Discord OAuth et backend FastAPI.

## 🚀 Architecture

- **Frontend**: React avec Tailwind CSS et shadcn/ui
- **Backend**: FastAPI avec Pydantic
- **Base de données**: Supabase (PostgreSQL)
- **Authentification**: Discord OAuth via Supabase
- **Déploiement**: PM2 + Nginx

## 📦 Fonctionnalités

- 💰 **Dotations**: Gestion des dotations mensuelles avec calculs automatiques
- 📊 **Impôts**: Déclarations fiscales IS et patrimoine
- 📄 **Factures/Diplômes**: Upload et gestion des documents
- 🔄 **Blanchiment**: Suivi des opérations de blanchiment
- 📦 **Archives**: Historique avec recherche avancée
- ⚙️ **Configuration**: Paramètres système et rôles

## 🔧 Installation

### Prérequis
- Node.js 18+ et Yarn
- Python 3.9+ avec pip
- Nginx (pour production)
- PM2 (pour production)

### Configuration des Variables d'Environnement

#### Frontend (.env)
```env
REACT_APP_BACKEND_URL=https://votre-domaine.com
REACT_APP_SUPABASE_URL=votre_url_supabase
REACT_APP_SUPABASE_ANON_KEY=votre_cle_supabase
REACT_APP_DISCORD_CLIENT_ID=votre_client_id_discord
REACT_APP_DISCORD_REDIRECT_URI=url_de_redirection
```

#### Backend (.env)
```env
SUPABASE_URL=votre_url_supabase
SUPABASE_SERVICE_KEY=votre_service_key_supabase
DISCORD_BOT_TOKEN=votre_token_bot_discord
DISCORD_CLIENT_ID=votre_client_id_discord
DISCORD_CLIENT_SECRET=votre_client_secret_discord
CORS_ORIGINS=https://votre-domaine.com
```

### Installation Locale

```bash
# Frontend
cd frontend
yarn install
yarn start

# Backend
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python server.py
```

### Déploiement Production

Utilisez les scripts de déploiement fournis :

```bash
# Déploiement interactif avec configuration Discord
./deploy-interactive-discord.sh

# Ou déploiement complet automatique
./deploy-production-complete-fixed.sh
```

## 🔐 Configuration Discord OAuth

1. Créez une application sur [Discord Developer Portal](https://discord.com/developers/applications)
2. Notez votre Client ID et Client Secret
3. Configurez les URLs de redirection dans Supabase
4. Ajoutez vos tokens dans les fichiers .env

## 📁 Structure du Projet

```
├── frontend/                # Application React
│   ├── src/
│   │   ├── components/      # Composants UI
│   │   ├── pages/          # Pages principales
│   │   ├── contexts/       # Contextes React (Auth, etc.)
│   │   ├── services/       # Services Supabase
│   │   └── utils/          # Utilitaires
│   └── public/
├── backend/                 # API FastAPI
│   ├── server.py           # Serveur principal
│   └── requirements.txt    # Dépendances Python
└── scripts/                # Scripts de déploiement
```

## 🛠️ Scripts de Déploiement

- `deploy-interactive-discord.sh`: Déploiement avec saisie interactive des tokens
- `deploy-production-complete-fixed.sh`: Déploiement automatique complet
- `fix-discord-auth-supabase.sh`: Correction des problèmes d'authentification
- `prepare-github-push.sh`: Préparation pour push GitHub (supprime les secrets)

## 🔒 Sécurité

- Les tokens et clés API ne sont jamais commitées sur GitHub
- Utilisation de variables d'environnement pour tous les secrets
- Configuration HTTPS avec SSL en production
- Validation côté serveur avec Pydantic

## 📞 Support

Pour les problèmes techniques ou questions :
- Consultez les logs PM2: `pm2 logs`
- Vérifiez les services: `pm2 status`
- Redémarrez si nécessaire: `pm2 restart all`

## 📄 Licence

Projet privé - Tous droits réservés
README_EOF

success "README créé avec instructions complètes"

#################################################################
# 5. SUPPRESSION FICHIERS SENSIBLES ADDITIONNELS
#################################################################

log "🗑️ Suppression fichiers sensibles additionnels..."

# Supprimer fichiers de backup potentiels
find "$APP_DIR" -name "*.backup" -delete 2>/dev/null || true
find "$APP_DIR" -name "*.bak" -delete 2>/dev/null || true
find "$APP_DIR" -name "*secret*" -type f -delete 2>/dev/null || true

# Nettoyer logs PM2 s'ils contiennent des secrets
rm -rf ~/.pm2/logs/*.log 2>/dev/null || true

success "Fichiers sensibles supprimés"

#################################################################
# 6. INSTRUCTIONS FINALES
#################################################################

echo ""
important "🎉 PRÉPARATION GITHUB TERMINÉE !"
echo ""
echo "✅ ACTIONS EFFECTUÉES :"
echo "   • Secrets sauvegardés dans: $BACKUP_DIR"
echo "   • Fichiers .env nettoyés (placeholders au lieu des vraies valeurs)"
echo "   • .gitignore mis à jour pour bloquer les secrets"
echo "   • README créé avec instructions de déploiement"
echo "   • Fichiers sensibles supprimés"
echo ""
echo "🚀 MAINTENANT VOUS POUVEZ :"
echo "   1. Utiliser 'Save to GitHub' sans problème de sécurité"
echo "   2. Les vrais secrets restent sur votre serveur"
echo "   3. Les collaborateurs devront configurer leurs propres .env"
echo ""
echo "⚠️ IMPORTANT :"
echo "   • Vos vrais secrets sont dans: $BACKUP_DIR"
echo "   • Pour restaurer après le push: ./restore-secrets.sh"
echo "   • Ne jamais commiter les fichiers de backup"
echo ""

# Créer script de restauration
cat > restore-secrets.sh << EOF
#!/bin/bash
# Script de restauration des secrets
BACKUP_DIR="$BACKUP_DIR"

if [ -f "\$BACKUP_DIR/frontend.env" ]; then
    cp "\$BACKUP_DIR/frontend.env" "$FRONTEND_DIR/.env"
    echo "✅ Secrets frontend restaurés"
fi

if [ -f "\$BACKUP_DIR/backend.env" ]; then
    cp "\$BACKUP_DIR/backend.env" "$BACKEND_DIR/.env"
    echo "✅ Secrets backend restaurés"
fi

echo "🔐 Tous les secrets ont été restaurés"
EOF

chmod +x restore-secrets.sh

success "🔐 Script de restauration créé: ./restore-secrets.sh"

echo ""
important "📤 VOUS POUVEZ MAINTENANT UTILISER 'Save to GitHub' SANS ERREUR !"