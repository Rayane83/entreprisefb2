# 🚀 DÉMARRAGE RAPIDE - Portail Entreprise Flashback Fa v2.0.0

## ⚡ Lancement en 30 secondes

```bash
cd /app
./run-app.sh
```

**C'est tout !** Le script détecte automatiquement votre configuration et vous guide.

---

## 🎯 Deux Modes Disponibles

### 🔐 **Mode Production** (Discord OAuth)
✅ Authentification Discord réelle  
✅ Utilisateurs réels de votre serveur Discord  
✅ Gestion des rôles automatique  

**Prérequis :** Application Discord créée sur https://discord.com/developers/applications

### 🎭 **Mode Développement** (Mock)
✅ Connexion automatique  
✅ Utilisateur de test prédéfini  
✅ Tous les modules accessibles  

**Aucun prérequis** - Fonctionne immédiatement

---

## 📋 Guide Express Discord

**Si vous choisissez le mode production :**

1. **Créer l'application Discord :**
   - Allez sur https://discord.com/developers/applications
   - Cliquez "New Application"
   - Nom : "Portail Flashback Fa"

2. **Configuration OAuth2 :**
   - Onglet "OAuth2" → "General"
   - Ajoutez redirect : `http://localhost:3000/auth/callback`
   - Copiez Client ID et Client Secret

3. **Le script fait le reste !**

---

## 🌟 Fonctionnalités Disponibles

### 💰 **Dotations**
- Zone de collage Excel/CSV
- Calculs automatiques (CA, salaires, primes)
- Export PDF et Excel

### 🧾 **Impôts** 
- Déclarations avec calculs temps réel
- Paliers fiscaux automatiques
- Prévisualisation des calculs

### 📄 **Documents**
- Upload factures/diplômes
- Gestion par type de document
- Stockage sécurisé

### 💸 **Blanchiment**
- Suivi des opérations
- Paramètres configurables
- Statistiques complètes

### 📚 **Archives**
- Centralisation de tous les documents
- Recherche avancée
- Export groupé

### ⚙️ **Configuration**
- Gestion des entreprises
- Paramètres Discord
- Administration

---

## 🔧 Commandes Rapides

```bash
# Lancer l'application
./run-app.sh

# Configurer Discord (production)
./configure-discord-tokens.sh

# Voir la démonstration
./demo-configuration.sh

# Redémarrer les services
sudo supervisorctl restart all

# Voir les logs
tail -f /var/log/supervisor/backend.*.log
```

---

## 📱 Accès Rapide

Une fois démarrée :

- **🌐 Application** : http://localhost:3000
- **🔧 API** : http://localhost:8001  
- **📚 Documentation** : http://localhost:8001/docs

---

## 🆘 Besoin d'Aide ?

- **📖 Documentation complète** : `README_MIGRATION_V2.md`
- **🔧 Guide des scripts** : `SCRIPTS_README.md`
- **🎬 Démonstration** : `./demo-configuration.sh`

---

**🎉 Votre application d'entreprise est prête ! Bon développement !**