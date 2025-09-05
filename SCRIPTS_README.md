# 🔧 Scripts de Configuration - Portail Entreprise Flashback Fa

## 🚀 Lancement Rapide

```bash
# Démarrer l'application (recommandé)
./run-app.sh
```

## 📋 Scripts Disponibles

### 🎯 **./run-app.sh** - Lancement Intelligent
**Usage principal** pour démarrer l'application

**Fonctionnalités :**
- ✅ Détection automatique de la configuration Discord
- ✅ Proposition de configuration si manquante
- ✅ Démarrage automatique de tous les services
- ✅ Mode développement avec authentification mock
- ✅ Vérification de santé des services
- ✅ Ouverture automatique du navigateur

```bash
./run-app.sh
# Suit le guide interactif
```

---

### 🔐 **./configure-discord-tokens.sh** - Configuration Sécurisée
**Configuration production** des tokens Discord OAuth

**Fonctionnalités :**
- 🔑 Saisie sécurisée des tokens Discord
- 🛡️ Validation automatique des formats
- 💾 Sauvegarde automatique des fichiers .env
- 🔒 Génération de clés JWT sécurisées
- 📋 Guide intégré Discord Developer Portal

```bash
./configure-discord-tokens.sh
# Suit le guide de configuration Discord
```

**Ce qui est demandé :**
- **Discord Client ID** (18-19 chiffres)
- **Discord Client Secret** (saisie masquée)
- **Discord Bot Token** (optionnel pour rôles)

---

### 🎬 **./demo-configuration.sh** - Démonstration
**Présentation** des fonctionnalités de sécurité

**Fonctionnalités :**
- 📖 Explication des nouvelles fonctionnalités
- 🎭 Simulations des scripts
- 🛡️ Présentation des mesures de sécurité
- 🚀 Lancement optionnel de la configuration réelle

```bash
./demo-configuration.sh
# Découvrir les fonctionnalités
```

---

## 🔐 Sécurité Implémentée

### ✅ **Tokens Protégés**
- ❌ **Aucun token en dur** dans le code source
- 🔒 **Saisie masquée** pour les secrets Discord
- 💾 **Sauvegarde automatique** des configurations
- 🔑 **Génération automatique** des clés JWT

### ✅ **Validation Automatique**
- 🔢 **Client ID Discord** : Format 18-19 chiffres
- 🔐 **Client Secret** : Minimum 20 caractères
- 🤖 **Bot Token** : Validation optionnelle
- ⚡ **Validation temps réel** lors de la saisie

### ✅ **Protection des Fichiers**
- 📁 **Sauvegardes horodatées** des fichiers .env
- 🚫 **Exclusion .gitignore** des fichiers sensibles
- 🛡️ **Échappement automatique** des caractères spéciaux
- 🔄 **Restauration possible** via sauvegardes

---

## 🏗️ Architecture de Configuration

```
/app/
├── configure-discord-tokens.sh  # Configuration sécurisée Discord
├── run-app.sh                  # Lancement intelligent
├── demo-configuration.sh       # Démonstration
├── backend/.env                # Configuration backend (avec backups)
├── frontend/.env               # Configuration frontend (avec backups)
└── README_MIGRATION_V2.md      # Documentation complète
```

---

## 🎯 Flux d'Utilisation

### 📋 **Première Installation**
```bash
1. ./demo-configuration.sh      # (Optionnel) Découvrir les fonctionnalités
2. ./run-app.sh                 # Lancement avec configuration automatique
3. Choisir : Configuration Discord OU Mode développement
4. L'application se lance automatiquement
```

### 🔧 **Configuration Production**
```bash
1. ./configure-discord-tokens.sh # Configuration des tokens Discord
2. ./run-app.sh                 # Lancement en mode production
3. Accès : http://localhost:3000
```

### 🎭 **Mode Développement**
```bash
1. ./run-app.sh                 # Lancement
2. Choisir "Mode développement" 
3. Authentification mock activée
4. Accès : http://localhost:3000
```

---

## 🚨 Dépannage

### ❌ **Services non démarrés**
```bash
# Vérifier les services
sudo supervisorctl status

# Redémarrer si besoin
sudo supervisorctl restart all

# Vérifier les logs
tail -f /var/log/supervisor/*.log
```

### ❌ **Configuration Discord incorrecte**
```bash
# Reconfigurer les tokens
./configure-discord-tokens.sh

# Les anciennes configurations sont sauvegardées automatiquement
ls backend/.env.backup.*
```

### ❌ **Base de données inaccessible**
```bash
# Redémarrer MariaDB
service mariadb restart

# Vérifier la connexion
mysql -u flashback_user -p flashback_fa_enterprise
```

---

## 📞 Support

### 🔗 **URLs Importantes**
- **Application** : http://localhost:3000
- **API Backend** : http://localhost:8001
- **Documentation API** : http://localhost:8001/docs
- **Health Check** : http://localhost:8001/health

### 📋 **Commandes Utiles**
```bash
# Status des services
sudo supervisorctl status

# Logs en temps réel
tail -f /var/log/supervisor/backend.*.log
tail -f /var/log/supervisor/frontend.*.log

# Redémarrage complet
sudo supervisorctl restart all

# Vérification de santé
curl http://localhost:8001/health
```

### 🔧 **Configuration Discord Developer Portal**
1. **Créer application** : https://discord.com/developers/applications
2. **OAuth2 Settings** :
   - Redirect URI : `http://localhost:3000/auth/callback`
   - Scopes : `identify`, `email`, `guilds`
3. **Copier** : Client ID, Client Secret
4. **Bot optionnel** : Pour récupération des rôles

---

**🎉 Configuration terminée ! L'application est prête pour la production avec authentification Discord OAuth sécurisée.**