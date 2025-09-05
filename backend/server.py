from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from contextlib import asynccontextmanager
import os
import logging
import time
from datetime import datetime, timezone
from pathlib import Path

# Import de nos modules
from database import engine, get_db
from models import Base
from schemas import HealthResponse, ApiResponse
from routes.auth_routes import router as auth_router
from routes.dotation_routes import router as dotation_router

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration de l'application
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8001"))
API_DEBUG = os.getenv("API_DEBUG", "False").lower() == "true"
API_VERSION = os.getenv("API_VERSION", "2.0.0")

# Configuration CORS
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")

# Configuration des uploads
UPLOAD_DIR = os.getenv("UPLOAD_DIR", "/app/backend/uploads")
MAX_FILE_SIZE = int(os.getenv("MAX_FILE_SIZE", "10485760"))  # 10MB par défaut

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestionnaire de cycle de vie de l'application."""
    logger.info("🚀 Démarrage de l'API Portail Entreprise Flashback Fa v2.0.0")
    
    # Créer les répertoires nécessaires
    upload_dir = Path(UPLOAD_DIR)
    upload_dir.mkdir(parents=True, exist_ok=True)
    logger.info(f"📁 Répertoire d'upload créé: {UPLOAD_DIR}")
    
    # Vérifier la connexion à la base de données
    try:
        # Test de connexion
        from sqlalchemy import text
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("✅ Connexion à la base de données MySQL réussie")
    except Exception as e:
        logger.error(f"❌ Erreur de connexion à la base de données: {e}")
        raise
    
    yield
    
    logger.info("🛑 Arrêt de l'API Portail Entreprise Flashback Fa")

# Création de l'application FastAPI
app = FastAPI(
    title="Portail Entreprise Flashback Fa - API",
    description="""
    API complète pour la gestion d'entreprise Flashback Fa avec :
    
    - **Authentification Discord OAuth** : Connexion sécurisée via Discord
    - **Gestion des dotations** : Création, modification, export PDF/Excel
    - **Déclarations d'impôts** : Calculs automatiques, paliers fiscaux
    - **Documents** : Upload et gestion de factures/diplômes
    - **Blanchiment** : Suivi des opérations avec paramètres configurables
    - **Archives** : Centralisation de tous les documents et rapports
    - **Audit** : Traçabilité complète des actions utilisateurs
    
    **Version 2.0.0** - Migration complète de Supabase vers FastAPI + MySQL
    """,
    version=API_VERSION,
    docs_url="/docs" if API_DEBUG else None,
    redoc_url="/redoc" if API_DEBUG else None,
    lifespan=lifespan
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# Middleware pour le logging des requêtes
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # Exclure les routes de santé du logging détaillé
    if request.url.path not in ["/", "/health"]:
        logger.info(f"🔔 {request.method} {request.url.path} - Début")
    
    response = await call_next(request)
    
    process_time = time.time() - start_time
    
    if request.url.path not in ["/", "/health"]:
        logger.info(
            f"✅ {request.method} {request.url.path} - "
            f"{response.status_code} - {process_time:.3f}s"
        )
    
    response.headers["X-Process-Time"] = str(process_time)
    return response

# Middleware pour la gestion globale des erreurs
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"❌ Erreur non gérée sur {request.method} {request.url.path}: {exc}")
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "message": "Erreur interne du serveur",
            "detail": str(exc) if API_DEBUG else "Une erreur inattendue est survenue"
        }
    )

# ========== ROUTES PRINCIPALES ==========

@app.get("/", response_model=ApiResponse, summary="Route racine")
async def root():
    """
    Route racine de l'API - Informations de base sur le service.
    """
    return ApiResponse(
        success=True,
        message="Portail Entreprise Flashback Fa - API Backend v2.0.0",
        data={
            "version": API_VERSION,
            "status": "operational",
            "documentation": "/docs" if API_DEBUG else "disabled",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "features": [
                "Discord OAuth Authentication",
                "Dotations Management", 
                "Tax Declarations",
                "Document Management",
                "Blanchiment Tracking",
                "Archives System",
                "Audit Logging"
            ]
        }
    )

@app.get("/health", response_model=HealthResponse, summary="Vérification de santé")
async def health_check():
    """
    Endpoint de vérification de santé pour les systèmes de monitoring.
    
    Vérifie :
    - État de l'API
    - Connexion à la base de données
    - Accès aux répertoires de fichiers
    """
    services_status = {}
    overall_status = "healthy"
    
    # Test de la base de données
    try:
        from sqlalchemy import text
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            services_status["database"] = "connected"
    except Exception as e:
        services_status["database"] = f"error: {str(e)}"
        overall_status = "degraded"
        logger.warning(f"Base de données non accessible: {e}")
    
    # Test du répertoire d'upload
    try:
        upload_path = Path(UPLOAD_DIR)
        if upload_path.exists() and upload_path.is_dir():
            services_status["uploads"] = "accessible"
        else:
            services_status["uploads"] = "directory not found"
            overall_status = "degraded"
    except Exception as e:
        services_status["uploads"] = f"error: {str(e)}"
        overall_status = "degraded"
    
    # Test de l'espace disque (optionnel)
    try:
        import shutil
        total, used, free = shutil.disk_usage("/")
        free_gb = free // (1024**3)
        services_status["disk_space"] = f"{free_gb}GB free"
        
        if free_gb < 1:  # Moins de 1GB libre
            overall_status = "degraded"
    except Exception:
        services_status["disk_space"] = "unknown"
    
    return HealthResponse(
        status=overall_status,
        timestamp=datetime.now(timezone.utc),
        version=API_VERSION,
        database="connected" if services_status.get("database") == "connected" else "error",
        services=services_status
    )

# ========== INCLUSION DES ROUTES ==========

# Routes d'authentification
app.include_router(auth_router)

# Routes de dotations
app.include_router(dotation_router)

# TODO: Ajouter les autres routes
# app.include_router(tax_router)
# app.include_router(documents_router)
# app.include_router(blanchiment_router)
# app.include_router(archives_router)
# app.include_router(config_router)

# ========== ROUTES POUR FICHIERS STATIQUES ==========

# Servir les fichiers uploadés (avec authentification en production)
if os.path.exists(UPLOAD_DIR):
    app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# ========== ROUTES DE COMPATIBILITÉ (TEMPORAIRES) ==========

@app.get("/api/", summary="Route API racine (compatibilité)")
async def api_root():
    """Route de compatibilité pour les anciens appels API."""
    return {"message": "API Portail Entreprise Flashback Fa v2.0.0 - MySQL Backend"}

@app.get("/api/status", summary="Status check (compatibilité)")
async def api_status():
    """Route de compatibilité pour les anciens checks de statut."""
    return {
        "status": "ok",
        "version": API_VERSION,
        "database": "mysql",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

# ========== INFORMATIONS DE DÉMARRAGE ==========

if __name__ == "__main__":
    import uvicorn
    
    logger.info(f"🌟 Lancement de l'API sur {API_HOST}:{API_PORT}")
    logger.info(f"🔧 Mode debug: {API_DEBUG}")
    logger.info(f"🌐 CORS origins: {CORS_ORIGINS}")
    logger.info(f"📂 Répertoire uploads: {UPLOAD_DIR}")
    logger.info(f"💾 Taille max fichiers: {MAX_FILE_SIZE / 1024 / 1024:.1f}MB")
    
    uvicorn.run(
        "server:app",
        host=API_HOST,
        port=API_PORT,
        reload=API_DEBUG,
        log_level="info"
    )