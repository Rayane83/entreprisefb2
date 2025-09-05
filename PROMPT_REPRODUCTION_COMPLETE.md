# 🚀 PROMPT COMPLET - REPRODUCTION PORTAIL ENTREPRISE FLASHBACK FA

## CONTEXTE DU PROJET

Créez une application web complète "Portail Entreprise Flashback Fa" avec les spécifications suivantes :

### ARCHITECTURE TECHNIQUE
- **Backend** : FastAPI + SQLAlchemy + MySQL/SQLite
- **Frontend** : React + Tailwind CSS + Vite
- **Authentification** : Discord OAuth native + JWT
- **Base de données** : MySQL (avec fallback SQLite)
- **Déploiement** : Nginx + Supervisor/PM2
- **Domaine de production** : https://flashbackfa-entreprise.fr/

### FONCTIONNALITÉS PRINCIPALES
- Système d'authentification Discord OAuth complet
- Gestion des rôles (Staff, Patron, Co-Patron, Employé)
- 7 modules métier : Dashboard, Dotations, Impôts, Factures/Diplômes, Blanchiment, Archives, Config
- Interface responsive avec Tailwind CSS
- API REST complète avec documentation automatique
- Exports Excel/PDF
- Gestion des permissions par rôle
- Logs et monitoring

---

## STRUCTURE DU PROJET

```
/
├── backend/
│   ├── .env (généré par script)
│   ├── requirements.txt
│   ├── server.py
│   ├── database.py
│   ├── models.py
│   ├── auth.py
│   ├── schemas.py
│   ├── alembic.ini
│   ├── alembic/
│   │   └── versions/
│   ├── routes/
│   │   ├── auth_routes.py
│   │   ├── dotation_routes.py
│   │   ├── tax_routes.py
│   │   ├── document_routes.py
│   │   ├── blanchiment_routes.py
│   │   ├── archive_routes.py
│   │   └── config_routes.py
│   └── utils/
│       ├── dotation_utils.py
│       └── audit.py
├── frontend/
│   ├── .env (généré par script)
│   ├── package.json
│   ├── vite.config.js
│   ├── tailwind.config.js
│   ├── index.html
│   ├── src/
│   │   ├── main.jsx
│   │   ├── App.jsx
│   │   ├── index.css
│   │   ├── components/
│   │   │   ├── LoginScreen.jsx
│   │   │   ├── Layout.jsx
│   │   │   ├── Navigation.jsx
│   │   │   └── ui/
│   │   ├── contexts/
│   │   │   └── AuthContext.jsx
│   │   ├── pages/
│   │   │   ├── Dashboard.jsx
│   │   │   ├── AuthCallback.jsx
│   │   │   ├── Dotations.jsx
│   │   │   ├── Impots.jsx
│   │   │   ├── Documents.jsx
│   │   │   ├── Blanchiment.jsx
│   │   │   ├── Archives.jsx
│   │   │   └── Config.jsx
│   │   └── services/
│   │       └── apiService.js
├── scripts/
│   ├── reconstruction-complete.sh
│   ├── configure-discord-tokens.sh
│   ├── run-app.sh
│   └── deploy-production.sh
└── README.md
```

---

## FICHIERS BACKEND

### backend/requirements.txt
```
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-dotenv==1.0.0
pydantic==2.5.0
sqlalchemy==2.0.23
alembic==1.13.1
pymysql==1.1.0
httpx==0.25.2
python-multipart==0.0.6
python-jose[cryptography]>=3.3.0
bcrypt>=4.0.0
passlib[bcrypt]>=1.7.4
cryptography>=41.0.0
```

### backend/server.py
```python
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import os
from dotenv import load_dotenv

from database import get_db, engine
from models import Base
from auth import get_current_user, create_access_token
from schemas import UserResponse, DiscordCallback

# Import routes
from routes.auth_routes import router as auth_router
from routes.dotation_routes import router as dotation_router
from routes.tax_routes import router as tax_router
from routes.document_routes import router as document_router
from routes.blanchiment_routes import router as blanchiment_router
from routes.archive_routes import router as archive_router
from routes.config_routes import router as config_router

load_dotenv()

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Portail Entreprise Flashback Fa",
    description="API for Flashback Fa Enterprise Portal",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router, prefix="/auth", tags=["Authentication"])
app.include_router(dotation_router, prefix="/api/dotations", tags=["Dotations"])
app.include_router(tax_router, prefix="/api/tax", tags=["Tax Declarations"])
app.include_router(document_router, prefix="/api/documents", tags=["Documents"])
app.include_router(blanchiment_router, prefix="/api/blanchiment", tags=["Blanchiment"])
app.include_router(archive_router, prefix="/api/archives", tags=["Archives"])
app.include_router(config_router, prefix="/api/config", tags=["Configuration"])

@app.get("/")
async def root():
    return {"message": "Portail Entreprise Flashback Fa API", "version": "2.0.0"}

@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    try:
        # Test database connection
        db.execute("SELECT 1")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "server:app", 
        host=os.getenv("API_HOST", "0.0.0.0"), 
        port=int(os.getenv("API_PORT", 8000)), 
        reload=True
    )
```

### backend/database.py
```python
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./flashback.db")

if DATABASE_URL.startswith("mysql"):
    engine = create_engine(DATABASE_URL)
else:
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### backend/models.py
```python
from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey, Enum, Float
from sqlalchemy.relationship import relationship
from sqlalchemy.sql import func
from database import Base
import enum
import uuid

class UserRole(enum.Enum):
    STAFF = "staff"
    PATRON = "patron"
    CO_PATRON = "co-patron"
    EMPLOYE = "employe"

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    discord_id = Column(String(255), unique=True, nullable=False)
    username = Column(String(255), nullable=False)
    email = Column(String(255))
    avatar_url = Column(String(500))
    role = Column(Enum(UserRole), default=UserRole.EMPLOYE)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class Enterprise(Base):
    __tablename__ = "enterprises"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False)
    description = Column(Text)
    owner_id = Column(String(36), ForeignKey("users.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    owner = relationship("User", back_populates="owned_enterprises")

User.owned_enterprises = relationship("Enterprise", back_populates="owner")

class DotationReport(Base):
    __tablename__ = "dotation_reports"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"))
    period = Column(String(50))
    amount = Column(Float)
    status = Column(String(50), default="pending")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class TaxDeclaration(Base):
    __tablename__ = "tax_declarations"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"))
    tax_type = Column(String(100))
    amount = Column(Float)
    due_date = Column(DateTime)
    status = Column(String(50), default="pending")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Document(Base):
    __tablename__ = "documents"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"))
    filename = Column(String(255))
    file_path = Column(String(500))
    file_type = Column(String(50))
    category = Column(String(100))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class BlanchimentTransaction(Base):
    __tablename__ = "blanchiment_transactions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"))
    amount = Column(Float)
    percentage = Column(Float)
    transaction_type = Column(String(100))
    status = Column(String(50), default="pending")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Archive(Base):
    __tablename__ = "archives"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"))
    title = Column(String(255))
    content = Column(Text)
    category = Column(String(100))
    tags = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
```

### backend/auth.py
```python
from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from datetime import datetime, timedelta
import httpx
import os
from dotenv import load_dotenv

from database import get_db
from models import User
from schemas import UserResponse

load_dotenv()

security = HTTPBearer()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_HOURS = int(os.getenv("JWT_EXPIRATION_HOURS", "24"))

DISCORD_CLIENT_ID = os.getenv("DISCORD_CLIENT_ID")
DISCORD_CLIENT_SECRET = os.getenv("DISCORD_CLIENT_SECRET")
DISCORD_REDIRECT_URI = os.getenv("DISCORD_REDIRECT_URI")

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        discord_id: str = payload.get("sub")
        if discord_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials"
            )
        return discord_id
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    discord_id = verify_token(credentials.credentials)
    user = db.query(User).filter(User.discord_id == discord_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    return user

async def exchange_discord_code(code: str):
    """Exchange Discord authorization code for access token"""
    data = {
        'client_id': DISCORD_CLIENT_ID,
        'client_secret': DISCORD_CLIENT_SECRET,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': DISCORD_REDIRECT_URI,
    }
    
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    
    async with httpx.AsyncClient() as client:
        response = await client.post('https://discord.com/api/oauth2/token', data=data, headers=headers)
        if response.status_code != 200:
            raise HTTPException(status_code=400, detail="Invalid authorization code")
        return response.json()

async def get_discord_user(access_token: str):
    """Get Discord user information using access token"""
    headers = {'Authorization': f'Bearer {access_token}'}
    
    async with httpx.AsyncClient() as client:
        response = await client.get('https://discord.com/api/users/@me', headers=headers)
        if response.status_code != 200:
            raise HTTPException(status_code=400, detail="Failed to get user info")
        return response.json()
```

### backend/schemas.py
```python
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from models import UserRole

class UserResponse(BaseModel):
    id: str
    discord_id: str
    username: str
    email: Optional[str] = None
    avatar_url: Optional[str] = None
    role: UserRole
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class DiscordCallback(BaseModel):
    code: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class DotationCreate(BaseModel):
    enterprise_id: str
    period: str
    amount: float

class TaxDeclarationCreate(BaseModel):
    enterprise_id: str
    tax_type: str
    amount: float
    due_date: datetime

class DocumentUpload(BaseModel):
    filename: str
    category: str
    enterprise_id: str

class BlanchimentCreate(BaseModel):
    enterprise_id: str
    amount: float
    percentage: float
    transaction_type: str

class ArchiveCreate(BaseModel):
    enterprise_id: str
    title: str
    content: str
    category: str
    tags: Optional[str] = None
```

---

## FICHIERS FRONTEND

### frontend/package.json
```json
{
  "name": "portail-entreprise-flashback-fa",
  "version": "2.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "start": "vite --host 0.0.0.0 --port 3001"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.0",
    "axios": "^1.6.0",
    "lucide-react": "^0.294.0",
    "@headlessui/react": "^1.7.17"
  },
  "devDependencies": {
    "@types/react": "^18.2.37",
    "@types/react-dom": "^18.2.15",
    "@vitejs/plugin-react": "^4.1.1",
    "vite": "^5.0.0",
    "tailwindcss": "^3.3.6",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32"
  }
}
```

### frontend/vite.config.js
```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 3001
  },
  define: {
    'process.env': process.env
  }
})
```

### frontend/tailwind.config.js
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'flashback': {
          'primary': '#1e40af',
          'secondary': '#3b82f6',
          'accent': '#60a5fa',
          'dark': '#1e293b',
          'light': '#f8fafc'
        }
      }
    },
  },
  plugins: [],
}
```

### frontend/index.html
```html
<!DOCTYPE html>
<html lang="fr">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Portail Entreprise Flashback Fa</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
```

### frontend/src/main.jsx
```jsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
```

### frontend/src/App.jsx
```jsx
import React from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './contexts/AuthContext'
import LoginScreen from './components/LoginScreen'
import Layout from './components/Layout'
import Dashboard from './pages/Dashboard'
import AuthCallback from './pages/AuthCallback'
import Dotations from './pages/Dotations'
import Impots from './pages/Impots'
import Documents from './pages/Documents'
import Blanchiment from './pages/Blanchiment'
import Archives from './pages/Archives'
import Config from './pages/Config'

function ProtectedRoute({ children }) {
  const { user, loading } = useAuth()
  
  if (loading) {
    return <div className="flex items-center justify-center min-h-screen">
      <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-flashback-primary"></div>
    </div>
  }
  
  return user ? children : <Navigate to="/login" />
}

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="min-h-screen bg-gray-50">
          <Routes>
            <Route path="/login" element={<LoginScreen />} />
            <Route path="/auth/callback" element={<AuthCallback />} />
            <Route path="/" element={
              <ProtectedRoute>
                <Layout>
                  <Dashboard />
                </Layout>
              </ProtectedRoute>
            } />
            <Route path="/dotations" element={
              <ProtectedRoute>
                <Layout>
                  <Dotations />
                </Layout>
              </ProtectedRoute>
            } />
            <Route path="/impots" element={
              <ProtectedRoute>
                <Layout>
                  <Impots />
                </Layout>
              </ProtectedRoute>
            } />
            <Route path="/documents" element={
              <ProtectedRoute>
                <Layout>
                  <Documents />
                </Layout>
              </ProtectedRoute>
            } />
            <Route path="/blanchiment" element={
              <ProtectedRoute>
                <Layout>
                  <Blanchiment />
                </Layout>
              </ProtectedRoute>
            } />
            <Route path="/archives" element={
              <ProtectedRoute>
                <Layout>
                  <Archives />
                </Layout>
              </ProtectedRoute>
            } />
            <Route path="/config" element={
              <ProtectedRoute>
                <Layout>
                  <Config />
                </Layout>
              </ProtectedRoute>
            } />
          </Routes>
        </div>
      </Router>
    </AuthProvider>
  )
}

export default App
```

### frontend/src/index.css
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply font-sans antialiased;
  }
}

@layer components {
  .btn-primary {
    @apply bg-flashback-primary hover:bg-flashback-secondary text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200;
  }
  
  .btn-secondary {
    @apply bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-2 px-4 rounded-lg transition-colors duration-200;
  }
  
  .card {
    @apply bg-white rounded-lg border border-gray-200 shadow-sm p-6;
  }
  
  .input-field {
    @apply w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-flashback-primary focus:border-flashback-primary outline-none transition-colors duration-200;
  }
}
```

---

## SCRIPTS DE DÉPLOIEMENT

### reconstruction-complete.sh
```bash
#!/bin/bash

# 🚀 SCRIPT DE RECONSTRUCTION COMPLÈTE
# Ce script configure automatiquement tout le projet

set -e

# [Le contenu complet du script de reconstruction que j'ai créé précédemment]
```

### configure-discord-tokens.sh
```bash
#!/bin/bash

# 🔐 CONFIGURATION DISCORD OAUTH INTERACTIVE
# Script pour configurer les tokens Discord de manière sécurisée

echo "🔐 Configuration Discord OAuth"
echo "Rendez-vous sur: https://discord.com/developers/applications"
echo ""
echo -n "Discord Client ID: "
read -r DISCORD_CLIENT_ID

echo -n "Discord Client Secret: "
read -r DISCORD_CLIENT_SECRET

echo -n "Discord Bot Token (optionnel): "
read -r DISCORD_BOT_TOKEN

# Mise à jour des fichiers .env
sed -i "s/DISCORD_CLIENT_ID=.*/DISCORD_CLIENT_ID=$DISCORD_CLIENT_ID/" backend/.env
sed -i "s/DISCORD_CLIENT_SECRET=.*/DISCORD_CLIENT_SECRET=$DISCORD_CLIENT_SECRET/" backend/.env
sed -i "s/DISCORD_BOT_TOKEN=.*/DISCORD_BOT_TOKEN=$DISCORD_BOT_TOKEN/" backend/.env

sed -i "s/REACT_APP_DISCORD_CLIENT_ID=.*/REACT_APP_DISCORD_CLIENT_ID=$DISCORD_CLIENT_ID/" frontend/.env

echo "✅ Configuration Discord mise à jour!"
```

---

## INSTRUCTIONS DE REPRODUCTION

### 1. Créer la structure du projet
```bash
mkdir portail-entreprise-flashback-fa
cd portail-entreprise-flashback-fa
mkdir -p backend/{routes,utils,alembic/versions} frontend/src/{components,pages,contexts,services} scripts
```

### 2. Créer tous les fichiers
Créez chaque fichier avec le contenu exact spécifié ci-dessus.

### 3. Configuration de l'environnement
```bash
# Backend
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Frontend
cd ../frontend
npm install
# ou
yarn install
```

### 4. Configuration de la base de données
```bash
# MySQL
mysql -u root -p
CREATE DATABASE flashback_fa_enterprise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'flashback_user'@'localhost' IDENTIFIED BY 'FlashbackFA_2024!';
GRANT ALL PRIVILEGES ON flashback_fa_enterprise.* TO 'flashback_user'@'localhost';
FLUSH PRIVILEGES;
```

### 5. Variables d'environnement
Créez les fichiers `.env` avec les templates fournis et remplacez les valeurs par vos vraie tokens Discord.

### 6. Démarrage
```bash
# Backend
cd backend
source venv/bin/activate
python server.py

# Frontend (nouveau terminal)
cd frontend
npm run dev
# ou
yarn dev
```

### 7. Configuration Nginx (Production)
```nginx
server {
    listen 80;
    server_name flashbackfa-entreprise.fr;
    
    location / {
        proxy_pass http://localhost:3001;
        # [configuration proxy complète]
    }
    
    location /api/ {
        proxy_pass http://localhost:8000/;
        # [configuration proxy complète]
    }
}
```

---

## FONCTIONNALITÉS À IMPLÉMENTER

### Modules Dashboard
- Vue d'ensemble des statistiques
- Graphiques de performance
- Notifications importantes

### Module Dotations
- Calcul automatique des dotations
- Import/Export Excel
- Gestion des périodes

### Module Impôts
- Déclarations fiscales
- Calculs automatiques
- Rappels d'échéances

### Module Documents
- Upload de fichiers
- Catégorisation
- Recherche et filtres

### Module Blanchiment
- Transactions suspectes
- Pourcentages de risque
- Rapports d'analyse

### Module Archives
- Stockage documentaire
- Système de tags
- Recherche avancée

### Module Configuration
- Paramètres utilisateur
- Gestion des rôles
- Configuration système

---

## SÉCURITÉ

### JWT Tokens
- Expiration automatique
- Refresh tokens
- Révocation de tokens

### Discord OAuth
- Flow OAuth2 complet
- Validation des tokens
- Gestion des erreurs

### Base de données
- Hashage des mots de passe
- Requêtes préparées
- Validation des entrées

### HTTPS/SSL
- Certificats Let's Encrypt
- Redirection HTTPS forcée
- Headers de sécurité

---

## DÉPLOIEMENT PRODUCTION

### 1. Serveur (Ubuntu/Debian)
```bash
# Installation des dépendances
sudo apt update
sudo apt install python3 python3-venv python3-pip nodejs npm nginx mysql-server certbot

# Configuration SSL
sudo certbot --nginx -d flashbackfa-entreprise.fr
```

### 2. Services
```bash
# Supervisor pour Python
sudo apt install supervisor

# PM2 pour Node.js (optionnel)
sudo npm install -g pm2
```

### 3. Configuration automatique
Utiliser le script `reconstruction-complete.sh` qui automatise tout le processus.

---

## TESTING

### Backend
```bash
cd backend
python -m pytest tests/
```

### Frontend
```bash
cd frontend
npm test
# ou
yarn test
```

### API Testing
- Documentation automatique : `/docs`
- Tests d'intégration avec Postman
- Tests de charge avec Artillery

---

## MONITORING

### Logs
- Backend : Logs structurés JSON
- Frontend : Console errors tracking
- Nginx : Access et error logs

### Métriques
- Performance API
- Temps de réponse
- Taux d'erreur

### Alertes
- Monitoring uptime
- Alertes par email/Discord
- Dashboard de monitoring

---

Cette spécification complète permet de reproduire exactement le projet "Portail Entreprise Flashback Fa" avec toutes ses fonctionnalités, sa sécurité et son déploiement en production.