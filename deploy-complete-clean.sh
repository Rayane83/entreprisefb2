#!/bin/bash

# 🚀 Déploiement COMPLET - Portail Entreprise Flashback Fa v2.0.0
# Supprime TOUT et recrée l'application complète FastAPI + MySQL + React
# SANS aucun résidu, mock data ou référence Supabase

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${PURPLE}"
    echo "=================================================================================================="
    echo "🔥 DÉPLOIEMENT COMPLET CLEAN - PORTAIL ENTREPRISE FLASHBACK FA v2.0.0"
    echo "🗑️  SUPPRESSION TOTALE + RECRÉATION COMPLÈTE"
    echo "🚀 FASTAPI + MYSQL + REACT - SANS RÉSIDUS NI MOCK"
    echo "=================================================================================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[ÉTAPE $1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ÉTAPE 1: Nettoyage TOTAL
total_cleanup() {
    print_step "1" "NETTOYAGE TOTAL de tous les résidus"
    
    # Arrêter tous les services
    sudo supervisorctl stop all 2>/dev/null || true
    
    # Supprimer COMPLÈTEMENT backend et frontend
    rm -rf backend/ frontend/ 2>/dev/null || true
    rm -rf node_modules/ __pycache__/ *.pyc 2>/dev/null || true
    rm -f *.sh *.md *.sql *.js *.py 2>/dev/null || true
    
    print_success "Nettoyage total terminé"
}

# ÉTAPE 2: Installation système
install_system() {
    print_step "2" "Installation des dépendances système"
    
    sudo apt-get update -qq
    sudo apt-get install -y mariadb-server python3-pip python3-venv python3-dev default-libmysqlclient-dev build-essential pkg-config supervisor nginx curl wget unzip openssl nodejs npm 2>/dev/null || true
    
    # Installer yarn
    npm install -g yarn 2>/dev/null || true
    
    sudo systemctl start mariadb || service mariadb start
    sudo systemctl enable mariadb 2>/dev/null || true
    
    print_success "Système configuré"
}

# ÉTAPE 3: Base de données
setup_database() {
    print_step "3" "Configuration MySQL"
    
    mysql -u root <<EOF
DROP DATABASE IF EXISTS flashback_fa_enterprise;
CREATE DATABASE flashback_fa_enterprise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
DROP USER IF EXISTS 'flashback_user'@'localhost';
CREATE USER 'flashback_user'@'localhost' IDENTIFIED BY 'FlashbackFA_2024!';
GRANT ALL PRIVILEGES ON flashback_fa_enterprise.* TO 'flashback_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    print_success "MySQL configuré"
}

# ÉTAPE 4: Création COMPLÈTE du backend
create_backend() {
    print_step "4" "Création COMPLÈTE du backend FastAPI"
    
    mkdir -p backend/{routes,utils,alembic/versions,uploads}
    cd backend
    
    # requirements.txt
    cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn==0.24.0
python-dotenv==1.0.0
starlette==0.27.0
pydantic==2.5.0
sqlalchemy==2.0.23
alembic==1.13.1
pymysql==1.1.0
mysqlclient==2.2.0
httpx==0.25.2
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
aiofiles==23.2.1
openpyxl==3.1.2
reportlab==4.0.7
bcrypt==4.1.2
EOF
    
    # Installation
    python3 -m pip install -r requirements.txt
    
    # database.py
    cat > database.py << 'EOF'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "mysql+pymysql://flashback_user:FlashbackFA_2024!@localhost/flashback_fa_enterprise")

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF
    
    # models.py
    cat > models.py << 'EOF'
from sqlalchemy import Column, String, Integer, Float, DateTime, Boolean, Text, ForeignKey, Enum, BigInteger, Date
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
import uuid
import enum
from database import Base

class UserRole(enum.Enum):
    STAFF = "staff"
    PATRON = "patron"
    CO_PATRON = "co-patron"
    DOT = "dot"
    EMPLOYE = "employe"

class ArchiveStatus(enum.Enum):
    EN_ATTENTE = "En attente"
    VALIDE = "Validé"
    REFUSE = "Refusé"

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    discord_id = Column(String(20), unique=True, nullable=False, index=True)
    discord_username = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=True)
    avatar_url = Column(String(500), nullable=True)
    role = Column(Enum(UserRole), default=UserRole.EMPLOYE, nullable=False)
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"), nullable=True)
    is_active = Column(Boolean, default=True)
    last_login = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    enterprise = relationship("Enterprise", back_populates="users")

class Enterprise(Base):
    __tablename__ = "enterprises"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), nullable=False, unique=True)
    discord_guild_id = Column(String(20), unique=True, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    users = relationship("User", back_populates="enterprise")

class DotationReport(Base):
    __tablename__ = "dotation_reports"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"), nullable=False)
    created_by = Column(String(36), ForeignKey("users.id"), nullable=False)
    title = Column(String(200), nullable=False)
    period = Column(String(50), nullable=True)
    status = Column(Enum(ArchiveStatus), default=ArchiveStatus.EN_ATTENTE)
    total_ca = Column(Float, default=0.0)
    total_salaires = Column(Float, default=0.0)
    total_primes = Column(Float, default=0.0)
    total_employees = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

class DotationRow(Base):
    __tablename__ = "dotation_rows"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    report_id = Column(String(36), ForeignKey("dotation_reports.id"), nullable=False)
    employee_name = Column(String(100), nullable=False)
    grade = Column(String(50), nullable=True)
    run = Column(Float, default=0.0)
    facture = Column(Float, default=0.0)
    vente = Column(Float, default=0.0)
    ca_total = Column(Float, default=0.0)
    salaire = Column(Float, default=0.0)
    prime = Column(Float, default=0.0)
EOF
    
    # auth.py
    cat > auth.py << 'EOF'
from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from datetime import datetime, timedelta, timezone
import httpx
import os
from typing import Optional
import logging

from database import get_db
from models import User, Enterprise, UserRole

DISCORD_CLIENT_ID = os.getenv("DISCORD_CLIENT_ID")
DISCORD_CLIENT_SECRET = os.getenv("DISCORD_CLIENT_SECRET")
DISCORD_REDIRECT_URI = os.getenv("DISCORD_REDIRECT_URI")

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "fallback_secret")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRATION_HOURS = int(os.getenv("JWT_EXPIRATION_HOURS", "24"))

DISCORD_API_BASE = "https://discord.com/api/v10"
DISCORD_OAUTH_URL = f"{DISCORD_API_BASE}/oauth2/token"
DISCORD_USER_URL = f"{DISCORD_API_BASE}/users/@me"

security = HTTPBearer()
logger = logging.getLogger(__name__)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(hours=JWT_EXPIRATION_HOURS)
    
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=7)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    return encoded_jwt

def verify_token(token: str):
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return {"user_id": user_id}
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

async def get_discord_user_from_code(code: str):
    try:
        async with httpx.AsyncClient() as client:
            token_data = {
                "client_id": DISCORD_CLIENT_ID,
                "client_secret": DISCORD_CLIENT_SECRET,
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": DISCORD_REDIRECT_URI,
            }
            
            token_response = await client.post(DISCORD_OAUTH_URL, data=token_data)
            if token_response.status_code != 200:
                raise HTTPException(status_code=400, detail="Discord OAuth error")
            
            token_json = token_response.json()
            access_token = token_json.get("access_token")
            
            user_response = await client.get(
                DISCORD_USER_URL, 
                headers={"Authorization": f"Bearer {access_token}"}
            )
            
            if user_response.status_code != 200:
                raise HTTPException(status_code=400, detail="Failed to get Discord user")
            
            return user_response.json()
            
    except Exception as e:
        logger.error(f"Discord OAuth error: {e}")
        raise HTTPException(status_code=400, detail="Discord authentication failed")

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    token_data = verify_token(credentials.credentials)
    user = db.query(User).filter(User.id == token_data["user_id"]).first()
    if user is None or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found")
    return user

def create_tokens_for_user(user: User):
    token_data = {"sub": user.id}
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }
EOF
    
    # schemas.py
    cat > schemas.py << 'EOF'
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime
from enum import Enum

class UserRoleEnum(str, Enum):
    STAFF = "staff"
    PATRON = "patron"
    CO_PATRON = "co-patron"
    DOT = "dot"
    EMPLOYE = "employe"

class UserResponse(BaseModel):
    id: str
    discord_id: str
    discord_username: str
    email: Optional[str] = None
    avatar_url: Optional[str] = None
    role: UserRoleEnum
    enterprise_id: Optional[str] = None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class DiscordAuthCallback(BaseModel):
    code: str
    state: Optional[str] = None

class AuthResponse(BaseModel):
    tokens: Token
    user: UserResponse

class DotationRowCreate(BaseModel):
    employee_name: str
    grade: Optional[str] = None
    run: float = 0.0
    facture: float = 0.0
    vente: float = 0.0

class DotationReportCreate(BaseModel):
    title: str
    period: Optional[str] = None
    rows: List[DotationRowCreate] = []

class HealthResponse(BaseModel):
    status: str = "healthy"
    timestamp: datetime
    version: str = "2.0.0"
    database: str = "connected"
EOF
    
    # routes/__init__.py
    mkdir -p routes
    touch routes/__init__.py
    
    # routes/auth_routes.py
    cat > routes/auth_routes.py << 'EOF'
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timezone
import uuid

from database import get_db
from models import User, Enterprise
from schemas import DiscordAuthCallback, AuthResponse, Token, UserResponse
from auth import get_discord_user_from_code, create_tokens_for_user, get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/discord/callback", response_model=AuthResponse)
async def discord_callback(callback_data: DiscordAuthCallback, db: Session = Depends(get_db)):
    try:
        discord_user_data = await get_discord_user_from_code(callback_data.code)
        
        discord_id = str(discord_user_data["id"])
        user = db.query(User).filter(User.discord_id == discord_id).first()
        
        if not user:
            user = User(
                discord_id=discord_id,
                discord_username=discord_user_data.get("username", "Unknown"),
                email=discord_user_data.get("email"),
                avatar_url=f"https://cdn.discordapp.com/avatars/{discord_id}/{discord_user_data.get('avatar', '')}.png" if discord_user_data.get('avatar') else None,
                last_login=datetime.now(timezone.utc)
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        else:
            user.last_login = datetime.now(timezone.utc)
            db.commit()
            db.refresh(user)
        
        tokens = create_tokens_for_user(user)
        user_response = UserResponse.from_orm(user)
        
        return AuthResponse(tokens=Token(**tokens), user=user_response)
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: User = Depends(get_current_user)):
    return UserResponse.from_orm(current_user)

@router.get("/discord-url")
async def get_discord_oauth_url():
    from urllib.parse import urlencode
    import os
    
    params = {
        "client_id": os.getenv("DISCORD_CLIENT_ID"),
        "redirect_uri": os.getenv("DISCORD_REDIRECT_URI"),
        "response_type": "code",
        "scope": "identify email",
    }
    
    url = f"https://discord.com/api/oauth2/authorize?{urlencode(params)}"
    return {"success": True, "data": {"url": url}}
EOF
    
    # server.py
    cat > server.py << 'EOF'
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from contextlib import asynccontextmanager
import os
import logging
from datetime import datetime, timezone

from database import engine, get_db
from models import Base
from schemas import HealthResponse
from routes.auth_routes import router as auth_router

API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8001"))
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Créer les tables
    Base.metadata.create_all(bind=engine)
    yield

app = FastAPI(
    title="Portail Entreprise Flashback Fa - API",
    description="API FastAPI + MySQL pour gestion d'entreprise",
    version="2.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "Portail Entreprise Flashback Fa - API Backend v2.0.0",
        "status": "operational",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    try:
        from sqlalchemy import text
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        database_status = "connected"
    except:
        database_status = "error"
    
    return HealthResponse(
        status="healthy" if database_status == "connected" else "degraded",
        timestamp=datetime.now(timezone.utc),
        database=database_status
    )

app.include_router(auth_router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host=API_HOST, port=API_PORT, reload=False)
EOF
    
    # .env
    cat > .env << 'EOF'
DATABASE_URL=mysql+pymysql://flashback_user:FlashbackFA_2024!@localhost/flashback_fa_enterprise

DISCORD_CLIENT_ID=
DISCORD_CLIENT_SECRET=
DISCORD_BOT_TOKEN=
DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback

JWT_SECRET_KEY=super_secret_jwt_key_change_in_production_2024!
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

API_HOST=0.0.0.0
API_PORT=8001
CORS_ORIGINS=http://localhost:3000

UPLOAD_DIR=/home/ubuntu/entreprisefb2/backend/uploads
MAX_FILE_SIZE=10485760
EOF
    
    cd ..
    print_success "Backend FastAPI créé complètement"
}

# ÉTAPE 5: Création COMPLÈTE du frontend
create_frontend() {
    print_step "5" "Création COMPLÈTE du frontend React"
    
    # Créer la structure frontend
    mkdir -p frontend/{public,src/{components,pages,services,contexts,hooks,utils}}
    cd frontend
    
    # package.json
    cat > package.json << 'EOF'
{
  "name": "portail-entreprise-flashback",
  "version": "2.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.1",
    "react-scripts": "5.0.1",
    "@headlessui/react": "^1.7.17",
    "@heroicons/react": "^2.0.18",
    "clsx": "^2.0.0",
    "tailwindcss": "^3.3.0",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31",
    "sonner": "^1.2.4"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "proxy": "http://localhost:8001"
}
EOF
    
    # public/index.html
    mkdir -p public
    cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="fr">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%PUBLIC_URL%/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="Portail Entreprise Flashback Fa" />
    <title>Portail Entreprise Flashback Fa</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF
    
    # src/index.js
    cat > src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF
    
    # src/index.css
    cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOF
    
    # src/services/apiService.js
    cat > src/services/apiService.js << 'EOF'
const API_BASE_URL = process.env.REACT_APP_BACKEND_URL || 'http://localhost:8001';

let authToken = null;

export const setAuthToken = (token) => {
  authToken = token;
};

const apiRequest = async (endpoint, options = {}) => {
  const url = `${API_BASE_URL}${endpoint}`;
  
  const config = {
    headers: {
      'Content-Type': 'application/json',
      ...(authToken && { 'Authorization': `Bearer ${authToken}` }),
      ...(options.headers || {}),
    },
    ...options,
  };

  try {
    const response = await fetch(url, config);
    
    if (!response.ok) {
      if (response.status === 401) {
        localStorage.removeItem('auth_token');
        setAuthToken(null);
        window.location.href = '/';
        return null;
      }
      throw new Error(`HTTP ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.error(`API Error: ${endpoint}:`, error);
    throw error;
  }
};

export const authAPI = {
  getDiscordAuthUrl: async () => {
    return await apiRequest('/auth/discord-url');
  },

  handleDiscordCallback: async (code, state = null) => {
    const response = await apiRequest('/auth/discord/callback', {
      method: 'POST',
      body: JSON.stringify({ code, state }),
    });
    
    if (response && response.tokens) {
      localStorage.setItem('auth_token', response.tokens.access_token);
      setAuthToken(response.tokens.access_token);
      return response;
    }
    
    throw new Error('Authentification échouée');
  },

  getCurrentUser: async () => {
    return await apiRequest('/auth/me');
  },
};

// Récupérer le token du localStorage au démarrage
const savedToken = localStorage.getItem('auth_token');
if (savedToken) {
  setAuthToken(savedToken);
}
EOF
    
    # src/contexts/AuthContext.js
    cat > src/contexts/AuthContext.js << 'EOF'
import React, { createContext, useContext, useState, useEffect } from 'react';
import { authAPI } from '../services/apiService';

const AuthContext = createContext({});

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [session, setSession] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const token = localStorage.getItem('auth_token');
        if (token) {
          const userData = await authAPI.getCurrentUser();
          if (userData) {
            setUser(userData);
            setSession({ user: userData });
            setIsAuthenticated(true);
          }
        }
      } catch (error) {
        console.error('Auth check failed:', error);
        localStorage.removeItem('auth_token');
      } finally {
        setLoading(false);
      }
    };

    checkAuth();
  }, []);

  const loginWithDiscord = async () => {
    try {
      setLoading(true);
      const response = await authAPI.getDiscordAuthUrl();
      
      if (response.success && response.data.url) {
        window.location.href = response.data.url;
        return { error: null };
      } else {
        throw new Error('Impossible de générer l\'URL Discord OAuth');
      }
    } catch (error) {
      setLoading(false);
      return { error };
    }
  };

  const logout = async () => {
    try {
      localStorage.removeItem('auth_token');
      setUser(null);
      setSession(null);
      setIsAuthenticated(false);
    } catch (error) {
      console.error('Logout error:', error);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        session,
        isAuthenticated,
        loading,
        loginWithDiscord,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
EOF
    
    # src/components/LoginScreen.js
    cat > src/components/LoginScreen.js << 'EOF'
import React from 'react';
import { useAuth } from '../contexts/AuthContext';

const LoginScreen = () => {
  const { loginWithDiscord, loading } = useAuth();

  const handleDiscordLogin = async () => {
    await loginWithDiscord();
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Portail Entreprise Flashback Fa
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Connectez-vous avec Discord
          </p>
        </div>
        <div>
          <button
            onClick={handleDiscordLogin}
            disabled={loading}
            className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
          >
            {loading ? 'Connexion...' : 'Se connecter avec Discord'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default LoginScreen;
EOF
    
    # src/pages/Dashboard.js
    cat > src/pages/Dashboard.js << 'EOF'
import React from 'react';
import { useAuth } from '../contexts/AuthContext';

const Dashboard = () => {
  const { user, logout } = useAuth();

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-semibold">Portail Entreprise Flashback Fa</h1>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-700">
                Bienvenue, {user?.discord_username}
              </span>
              <button
                onClick={logout}
                className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm"
              >
                Déconnexion
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="border-4 border-dashed border-gray-200 rounded-lg h-96 flex items-center justify-center">
            <div className="text-center">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">
                🎉 Application FastAPI + MySQL Opérationnelle !
              </h2>
              <p className="text-gray-600">
                Backend: ✅ FastAPI + MySQL<br/>
                Frontend: ✅ React + Tailwind<br/>
                Auth: ✅ Discord OAuth<br/>
                Base: ✅ {user?.role} - {user?.enterprise_id || 'Pas d\'entreprise'}
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Dashboard;
EOF
    
    # src/pages/AuthCallback.js
    cat > src/pages/AuthCallback.js << 'EOF'
import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { authAPI } from '../services/apiService';

const AuthCallback = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [status, setStatus] = useState('Traitement...');

  useEffect(() => {
    const handleCallback = async () => {
      try {
        const code = searchParams.get('code');
        const state = searchParams.get('state');

        if (!code) {
          throw new Error('Code manquant');
        }

        setStatus('Authentification Discord...');
        await authAPI.handleDiscordCallback(code, state);
        
        setStatus('Succès ! Redirection...');
        setTimeout(() => {
          navigate('/', { replace: true });
        }, 1000);

      } catch (error) {
        setStatus('Erreur: ' + error.message);
        setTimeout(() => {
          navigate('/', { replace: true });
        }, 3000);
      }
    };

    handleCallback();
  }, [searchParams, navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <h2 className="text-2xl font-bold text-gray-900 mb-4">
          Authentification Discord
        </h2>
        <p className="text-gray-600">{status}</p>
      </div>
    </div>
  );
};

export default AuthCallback;
EOF
    
    # src/App.js
    cat > src/App.js << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import LoginScreen from './components/LoginScreen';
import Dashboard from './pages/Dashboard';
import AuthCallback from './pages/AuthCallback';

const AppContent = () => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-gray-900"></div>
          <p className="mt-4">Chargement...</p>
        </div>
      </div>
    );
  }

  return isAuthenticated ? <Dashboard /> : <LoginScreen />;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/" element={<AppContent />} />
          <Route path="/auth/callback" element={<AuthCallback />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
EOF
    
    # tailwind.config.js
    cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF
    
    # .env
    cat > .env << 'EOF'
REACT_APP_BACKEND_URL=http://localhost:8001
REACT_APP_DISCORD_CLIENT_ID=
REACT_APP_DISCORD_REDIRECT_URI=http://localhost:3000/auth/callback
REACT_APP_APP_NAME=Portail Entreprise Flashback Fa
REACT_APP_VERSION=2.0.0
EOF
    
    # Installation des dépendances
    yarn install
    
    cd ..
    print_success "Frontend React créé complètement"
}

# ÉTAPE 6: Configuration Supervisor
setup_supervisor() {
    print_step "6" "Configuration Supervisor"
    
    sudo tee /etc/supervisor/conf.d/backend.conf > /dev/null << EOF
[program:backend]
command=/usr/bin/python3 server.py
directory=$(pwd)/backend
user=ubuntu
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/backend.out.log
stderr_logfile=/var/log/supervisor/backend.err.log
environment=PATH="/usr/bin:/usr/local/bin"
EOF
    
    sudo tee /etc/supervisor/conf.d/frontend.conf > /dev/null << EOF
[program:frontend]
command=/usr/bin/yarn start
directory=$(pwd)/frontend
user=ubuntu
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/frontend.out.log
stderr_logfile=/var/log/supervisor/frontend.err.log
environment=PATH="/usr/bin:/usr/local/bin",NODE_ENV="development"
EOF
    
    sudo supervisorctl reread
    sudo supervisorctl update
    
    print_success "Supervisor configuré"
}

# ÉTAPE 7: Scripts de configuration
create_scripts() {
    print_step "7" "Création des scripts de configuration"
    
    # Script de configuration Discord sécurisé
    cat > configure-discord-tokens.sh << 'EOF'
#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 Configuration Discord OAuth${NC}"
echo ""

# Validation Client ID
while true; do
    echo -n "Discord Client ID (18-19 chiffres): "
    read -r DISCORD_CLIENT_ID
    
    if [[ $DISCORD_CLIENT_ID =~ ^[0-9]{18,19}$ ]]; then
        echo -e "${GREEN}✅ Client ID valide${NC}"
        break
    else
        echo -e "${RED}❌ Client ID invalide${NC}"
    fi
done

# Validation Client Secret
while true; do
    echo -n "Discord Client Secret (masqué): "
    read -rs DISCORD_CLIENT_SECRET
    echo
    
    if [[ ${#DISCORD_CLIENT_SECRET} -ge 20 ]]; then
        echo -e "${GREEN}✅ Client Secret valide${NC}"
        break
    else
        echo -e "${RED}❌ Client Secret trop court${NC}"
    fi
done

# Mise à jour des fichiers .env
sed -i "s/DISCORD_CLIENT_ID=.*/DISCORD_CLIENT_ID=$DISCORD_CLIENT_ID/" backend/.env
sed -i "s/DISCORD_CLIENT_SECRET=.*/DISCORD_CLIENT_SECRET=$DISCORD_CLIENT_SECRET/" backend/.env
sed -i "s/REACT_APP_DISCORD_CLIENT_ID=.*/REACT_APP_DISCORD_CLIENT_ID=$DISCORD_CLIENT_ID/" frontend/.env

# Générer JWT secret
JWT_SECRET=$(openssl rand -base64 32)
sed -i "s/JWT_SECRET_KEY=.*/JWT_SECRET_KEY=$JWT_SECRET/" backend/.env

echo ""
echo -e "${GREEN}🎉 Configuration terminée !${NC}"
echo "Redémarrez avec: sudo supervisorctl restart backend frontend"
EOF
    
    chmod +x configure-discord-tokens.sh
    
    # Script de lancement
    cat > run-app.sh << 'EOF'
#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Lancement Portail Entreprise Flashback Fa v2.0.0${NC}"

# Vérifier configuration Discord
if grep -q "DISCORD_CLIENT_ID=$" backend/.env; then
    echo -e "${YELLOW}⚠️  Configuration Discord manquante${NC}"
    echo "Exécutez: ./configure-discord-tokens.sh"
    exit 1
fi

# Démarrer services
sudo systemctl start mariadb || service mariadb start
sudo supervisorctl restart backend frontend

sleep 3

echo ""
echo -e "${GREEN}✅ Application démarrée !${NC}"
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend API: http://localhost:8001"
echo ""
EOF
    
    chmod +x run-app.sh
    
    print_success "Scripts de configuration créés"
}

# FONCTION PRINCIPALE
main() {
    print_header
    
    echo -e "${YELLOW}⚠️  ATTENTION: Ce script va SUPPRIMER COMPLÈTEMENT tout le contenu existant${NC}"
    echo -e "${YELLOW}et recréer une application FastAPI + MySQL + React SANS AUCUN RÉSIDU.${NC}"
    echo ""
    
    read -p "Voulez-vous continuer ? [y/N]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Déploiement annulé."
        exit 0
    fi
    
    total_cleanup
    install_system
    setup_database
    create_backend
    create_frontend
    setup_supervisor
    create_scripts
    
    echo ""
    echo -e "${GREEN}=================================================================================================="
    echo "🎉 DÉPLOIEMENT COMPLET TERMINÉ AVEC SUCCÈS !"
    echo "=================================================================================================="
    echo -e "${NC}"
    
    echo "📋 Application créée complètement :"
    echo ""
    echo "✅ Backend FastAPI + MySQL + SQLAlchemy"
    echo "✅ Frontend React + Tailwind + React Router"
    echo "✅ Authentification Discord OAuth"
    echo "✅ Base de données MySQL configurée"
    echo "✅ Supervisor configuré"
    echo "✅ Scripts de configuration sécurisés"
    echo ""
    echo -e "${BLUE}Prochaines étapes :${NC}"
    echo "1. Configurer Discord: ./configure-discord-tokens.sh"
    echo "2. Lancer l'application: ./run-app.sh"
    echo "3. Accéder à: http://localhost:3000"
    echo ""
    
    echo -n "Configurer Discord maintenant ? [y/N]: "
    read -r config_discord
    
    if [[ $config_discord =~ ^[Yy]$ ]]; then
        ./configure-discord-tokens.sh
        ./run-app.sh
    else
        echo -e "${GREEN}Déploiement terminé ! Configurez Discord puis lancez: ./run-app.sh${NC}"
    fi
}

main "$@"