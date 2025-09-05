# 🚀 Guide de Déploiement VPS - Portail Entreprise Flashback Fa

## 📋 **Prérequis VPS**

### **Système recommandé**
- Ubuntu 20.04+ / Debian 11+
- RAM : 2GB minimum (4GB recommandé)
- CPU : 2 cores minimum
- Stockage : 20GB minimum
- Accès root ou sudo

### **Domaine et DNS**
- Nom de domaine pointant vers l'IP du VPS
- Certificat SSL (Let's Encrypt gratuit)

## 🛠️ **Étape 1 : Installation des Dépendances**

### **1.1 Mise à jour du système**
```bash
sudo apt update && sudo apt upgrade -y
```

### **1.2 Installation Node.js (v18+)**
```bash
# Via NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Vérifier
node --version
npm --version
```

### **1.3 Installation Python 3.9+**
```bash
sudo apt install python3 python3-pip python3-venv -y
```

### **1.4 Installation Nginx**
```bash
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

### **1.5 Installation PM2 (Process Manager)**
```bash
sudo npm install -g pm2
```

### **1.6 Installation Yarn**
```bash
sudo npm install -g yarn
```

## 📁 **Étape 2 : Configuration du Projet**

### **2.1 Navigation vers le projet**
```bash
cd /path/to/portail-entreprise-flashback-fa
```

### **2.2 Installation des dépendances Backend**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### **2.3 Installation des dépendances Frontend**
```bash
cd ../frontend
yarn install
```

## ⚙️ **Étape 3 : Configuration des Variables d'Environnement**

### **3.1 Backend (.env)**
```bash
cd backend
nano .env
```

Contenu :
```env
# Base de données
MONGO_URL=mongodb://localhost:27017
DB_NAME=portail_entreprise

# API
PORT=8001
HOST=0.0.0.0

# Environnement
ENV=production
DEBUG=false

# CORS
ALLOWED_ORIGINS=["https://votre-domaine.com"]
```

### **3.2 Frontend (.env)**
```bash
cd ../frontend
nano .env
```

Contenu :
```env
# Backend API
REACT_APP_BACKEND_URL=https://votre-domaine.com

# Supabase
REACT_APP_SUPABASE_URL=https://dutvmjnhnrpqoztftzgd.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dHZtam5obnJwcW96dGZ0emdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwMzI2NDksImV4cCI6MjA3MjYwODY0OX0.nYFZjQoC6-U2zdgaaYqj3GYWByqWvoa1RconWuOOuiw

# Discord (optionnel)
REACT_APP_DISCORD_GUILD_ID=1404608015230832742

# Production
NODE_ENV=production
```

## 🏗️ **Étape 4 : Build du Frontend**

```bash
cd frontend
yarn build
```

Le dossier `build` sera créé avec les fichiers statiques.

## 🌐 **Étape 5 : Configuration Nginx**

### **5.1 Créer la configuration du site**
```bash
sudo nano /etc/nginx/sites-available/portail-entreprise
```

Contenu :
```nginx
server {
    listen 80;
    server_name votre-domaine.com www.votre-domaine.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name votre-domaine.com www.votre-domaine.com;
    
    # SSL Configuration (sera ajouté par Certbot)
    # ssl_certificate /etc/letsencrypt/live/votre-domaine.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/votre-domaine.com/privkey.pem;
    
    # Frontend - Fichiers statiques React
    location / {
        root /path/to/portail-entreprise-flashback-fa/frontend/build;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
        
        # Cache pour les assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Backend API - Proxy vers FastAPI
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
```

### **5.2 Activer le site**
```bash
sudo ln -s /etc/nginx/sites-available/portail-entreprise /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🔒 **Étape 6 : SSL avec Let's Encrypt**

### **6.1 Installation Certbot**
```bash
sudo apt install certbot python3-certbot-nginx -y
```

### **6.2 Obtenir le certificat SSL**
```bash
sudo certbot --nginx -d votre-domaine.com -d www.votre-domaine.com
```

### **6.3 Auto-renouvellement**
```bash
sudo crontab -e
```

Ajouter :
```cron
0 12 * * * /usr/bin/certbot renew --quiet
```

## 🔄 **Étape 7 : Configuration PM2**

### **7.1 Créer le fichier de configuration PM2**
```bash
cd /path/to/portail-entreprise-flashback-fa
nano ecosystem.config.js
```

Contenu :
```javascript
module.exports = {
  apps: [
    {
      name: 'portail-backend',
      cwd: './backend',
      script: 'venv/bin/python',
      args: '-m uvicorn server:app --host 0.0.0.0 --port 8001',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 8001
      },
      log_file: './logs/backend.log',
      out_file: './logs/backend-out.log',
      error_file: './logs/backend-error.log',
      time: true
    }
  ]
};
```

### **7.2 Créer le dossier logs**
```bash
mkdir logs
```

### **7.3 Démarrer l'application**
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

Suivre les instructions affichées pour le démarrage automatique.

## 🗄️ **Étape 8 : Configuration MongoDB (Optionnel)**

Si vous utilisez MongoDB localement :

### **8.1 Installation MongoDB**
```bash
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
```

### **8.2 Démarrage MongoDB**
```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

## 🔥 **Étape 9 : Configuration du Firewall**

```bash
# UFW
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# Ou iptables
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

## 📊 **Étape 10 : Monitoring et Maintenance**

### **10.1 Commandes PM2 utiles**
```bash
pm2 status                    # Statut des processus
pm2 logs portail-backend     # Logs en temps réel
pm2 restart portail-backend  # Redémarrer
pm2 stop portail-backend     # Arrêter
pm2 monit                    # Monitoring
```

### **10.2 Logs Nginx**
```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### **10.3 Script de mise à jour**
```bash
nano update.sh
```

Contenu :
```bash
#!/bin/bash
echo "🔄 Mise à jour du Portail Entreprise..."

# Git pull
git pull origin main

# Backend
cd backend
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Frontend
cd frontend
yarn install
yarn build
cd ..

# Redémarrage
pm2 restart portail-backend
sudo systemctl reload nginx

echo "✅ Mise à jour terminée !"
```

```bash
chmod +x update.sh
```

## 🧪 **Étape 11 : Tests de Déploiement**

### **11.1 Test Backend**
```bash
curl https://votre-domaine.com/api/
```

### **11.2 Test Frontend**
Ouvrir https://votre-domaine.com dans le navigateur

### **11.3 Test SSL**
```bash
curl -I https://votre-domaine.com
```

## 🆘 **Dépannage Courant**

### **Problème : Backend ne démarre pas**
```bash
cd backend
source venv/bin/activate
python -m uvicorn server:app --host 0.0.0.0 --port 8001
```

### **Problème : Frontend ne se charge pas**
```bash
sudo nginx -t
sudo systemctl status nginx
```

### **Problème : Certificat SSL**
```bash
sudo certbot certificates
sudo certbot renew --dry-run
```

## 🎉 **Votre application est maintenant déployée !**

- **Frontend** : https://votre-domaine.com
- **API** : https://votre-domaine.com/api/
- **Monitoring** : `pm2 monit`

---

**Note** : Remplacez `votre-domaine.com` par votre vrai domaine et `/path/to/portail-entreprise-flashback-fa` par le chemin réel de votre projet.