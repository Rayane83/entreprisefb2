# ⚡ Démarrage Rapide - Déploiement VPS

## 🎯 **Vous êtes ici** : Projet cloné ✅

Maintenant, suivez ces 4 étapes simples pour déployer votre application :

## 📋 **Étape 1 : Vérification VPS**

```bash
# Dans le dossier de votre projet
./check-vps.sh
```

Ce script vérifie que votre VPS a tout ce qu'il faut. Installez ce qui manque.

## 🚀 **Étape 2 : Déploiement Automatique**

```bash
# Remplacez par votre domaine et le chemin désiré
./deploy.sh votre-domaine.com /var/www/portail-entreprise
```

**Exemple concret :**
```bash
./deploy.sh portail.monentreprise.com /var/www/portail-entreprise
```

## 🔧 **Étape 3 : Configuration DNS**

Pointez votre domaine vers l'IP de votre VPS :
- **Type A** : `votre-domaine.com` → `IP_DE_VOTRE_VPS`
- **Type A** : `www.votre-domaine.com` → `IP_DE_VOTRE_VPS`

## 🎉 **Étape 4 : Vérification**

1. **Frontend** : https://votre-domaine.com
2. **API** : https://votre-domaine.com/api/
3. **Statut** : `pm2 status`

---

## 🛠️ **Installation des Prérequis (si nécessaire)**

Si `check-vps.sh` indique des manques :

### **Node.js 18+**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2 yarn
```

### **Python 3 + Nginx**
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

### **Certbot (SSL)**
```bash
sudo apt install certbot python3-certbot-nginx -y
```

---

## ⚙️ **Variables d'Environnement**

Le script `deploy.sh` crée automatiquement les fichiers `.env`, mais vous pouvez les personnaliser :

### **Backend** (`backend/.env`)
```env
MONGO_URL=mongodb://localhost:27017
DB_NAME=portail_entreprise
ALLOWED_ORIGINS=["https://votre-domaine.com"]
```

### **Frontend** (`frontend/.env`)
```env
REACT_APP_BACKEND_URL=https://votre-domaine.com
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=votre_cle_supabase
```

---

## 🔄 **Commandes de Maintenance**

### **Statut de l'application**
```bash
pm2 status
pm2 logs portail-backend
```

### **Mise à jour du code**
```bash
cd /var/www/portail-entreprise
./update.sh
```

### **Redémarrage des services**
```bash
pm2 restart portail-backend
sudo systemctl reload nginx
```

### **Logs**
```bash
# Logs application
pm2 logs portail-backend

# Logs Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## 🐛 **Dépannage Rapide**

### **L'application ne se charge pas**
```bash
# Vérifier le statut
pm2 status
sudo systemctl status nginx

# Redémarrer si nécessaire
pm2 restart portail-backend
sudo systemctl restart nginx
```

### **Erreur 502 Bad Gateway**
```bash
# Vérifier que le backend tourne sur le port 8001
curl http://localhost:8001/api/

# Si pas de réponse, redémarrer
pm2 restart portail-backend
```

### **Certificat SSL non généré**
```bash
sudo certbot --nginx -d votre-domaine.com -d www.votre-domaine.com
```

---

## 📚 **Documentation Complète**

- **Guide détaillé** : `DEPLOYMENT_GUIDE.md`
- **Configuration Supabase** : `SETUP_SUPABASE.md`
- **Intégration complète** : `INTEGRATION_COMPLETE.md`

---

## 🎯 **Résumé des 4 Étapes**

1. `./check-vps.sh` ← Vérification
2. `./deploy.sh votre-domaine.com /path` ← Déploiement  
3. Configuration DNS ← Pointage domaine
4. Test https://votre-domaine.com ← Vérification

**C'est tout ! Votre application est en ligne ! 🚀**