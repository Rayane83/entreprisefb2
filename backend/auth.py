from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta, timezone
import httpx
import os
from typing import Optional, Dict, Any, List
import logging

from database import get_db
from models import User, Enterprise, UserRole
from schemas import TokenData, UserCreate, UserResponse

# Configuration
DISCORD_CLIENT_ID = os.getenv("DISCORD_CLIENT_ID")
DISCORD_CLIENT_SECRET = os.getenv("DISCORD_CLIENT_SECRET")
DISCORD_BOT_TOKEN = os.getenv("DISCORD_BOT_TOKEN")
DISCORD_REDIRECT_URI = os.getenv("DISCORD_REDIRECT_URI")

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "fallback_secret")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRATION_HOURS = int(os.getenv("JWT_EXPIRATION_HOURS", "24"))
JWT_REFRESH_EXPIRATION_DAYS = int(os.getenv("JWT_REFRESH_EXPIRATION_DAYS", "7"))

# URLs Discord API
DISCORD_API_BASE = "https://discord.com/api/v10"
DISCORD_OAUTH_URL = f"{DISCORD_API_BASE}/oauth2/token"
DISCORD_USER_URL = f"{DISCORD_API_BASE}/users/@me"
DISCORD_GUILDS_URL = f"{DISCORD_API_BASE}/users/@me/guilds"

# Security
security = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

logger = logging.getLogger(__name__)

class DiscordOAuthError(Exception):
    pass

class AuthenticationError(Exception):
    pass

# ========== JWT FUNCTIONS ==========

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Créer un token JWT d'accès."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(hours=JWT_EXPIRATION_HOURS)
    
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict):
    """Créer un token JWT de refresh."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=JWT_REFRESH_EXPIRATION_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> TokenData:
    """Vérifier et décoder un token JWT."""
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type", "access")
        
        if user_id is None:
            raise AuthenticationError("Token invalide")
        
        return TokenData(user_id=user_id, token_type=token_type)
    except JWTError as e:
        logger.error(f"Erreur JWT: {e}")
        raise AuthenticationError("Token invalide ou expiré")

# ========== DISCORD API FUNCTIONS ==========

async def get_discord_user_from_code(code: str) -> Dict[str, Any]:
    """Échanger le code Discord contre les données utilisateur."""
    try:
        async with httpx.AsyncClient() as client:
            # 1. Échanger le code contre un access token
            token_data = {
                "client_id": DISCORD_CLIENT_ID,
                "client_secret": DISCORD_CLIENT_SECRET,
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": DISCORD_REDIRECT_URI,
            }
            
            headers = {"Content-Type": "application/x-www-form-urlencoded"}
            
            token_response = await client.post(
                DISCORD_OAUTH_URL,
                data=token_data,
                headers=headers
            )
            
            if token_response.status_code != 200:
                logger.error(f"Erreur token Discord: {token_response.status_code} - {token_response.text}")
                raise DiscordOAuthError("Erreur lors de l'échange du code Discord")
            
            token_json = token_response.json()
            access_token = token_json.get("access_token")
            
            if not access_token:
                raise DiscordOAuthError("Access token Discord manquant")
            
            # 2. Récupérer les données utilisateur
            user_headers = {"Authorization": f"Bearer {access_token}"}
            
            user_response = await client.get(DISCORD_USER_URL, headers=user_headers)
            
            if user_response.status_code != 200:
                logger.error(f"Erreur utilisateur Discord: {user_response.status_code}")
                raise DiscordOAuthError("Erreur lors de la récupération des données utilisateur Discord")
            
            user_data = user_response.json()
            
            # 3. Récupérer les guilds/serveurs de l'utilisateur
            guilds_response = await client.get(DISCORD_GUILDS_URL, headers=user_headers)
            guilds_data = []
            
            if guilds_response.status_code == 200:
                guilds_data = guilds_response.json()
            
            user_data["guilds"] = guilds_data
            user_data["access_token"] = access_token
            
            return user_data
            
    except httpx.RequestError as e:
        logger.error(f"Erreur réseau Discord: {e}")
        raise DiscordOAuthError("Erreur de communication avec Discord")
    except Exception as e:
        logger.error(f"Erreur inattendue Discord OAuth: {e}")
        raise DiscordOAuthError("Erreur interne lors de l'authentification Discord")

async def get_discord_guild_member(guild_id: str, user_id: str) -> Optional[Dict[str, Any]]:
    """Récupérer les informations d'un membre dans une guild Discord."""
    if not DISCORD_BOT_TOKEN:
        logger.warning("DISCORD_BOT_TOKEN non configuré - impossible de récupérer les rôles")
        return None
    
    try:
        async with httpx.AsyncClient() as client:
            headers = {"Authorization": f"Bot {DISCORD_BOT_TOKEN}"}
            url = f"{DISCORD_API_BASE}/guilds/{guild_id}/members/{user_id}"
            
            response = await client.get(url, headers=headers)
            
            if response.status_code == 200:
                return response.json()
            elif response.status_code == 404:
                logger.info(f"Utilisateur {user_id} non trouvé dans la guild {guild_id}")
                return None
            else:
                logger.error(f"Erreur API Discord: {response.status_code} - {response.text}")
                return None
    except Exception as e:
        logger.error(f"Erreur lors de la récupération du membre Discord: {e}")
        return None

def determine_user_role(member_data: Optional[Dict], enterprise: Optional[Enterprise]) -> UserRole:
    """Déterminer le rôle d'un utilisateur basé sur ses rôles Discord."""
    if not member_data or not enterprise:
        return UserRole.EMPLOYE
    
    user_role_ids = member_data.get("roles", [])
    
    # Vérification des rôles par priorité (du plus élevé au plus bas)
    if enterprise.staff_role_id and enterprise.staff_role_id in user_role_ids:
        return UserRole.STAFF
    elif enterprise.patron_role_id and enterprise.patron_role_id in user_role_ids:
        return UserRole.PATRON
    elif enterprise.co_patron_role_id and enterprise.co_patron_role_id in user_role_ids:
        return UserRole.CO_PATRON
    elif enterprise.dot_role_id and enterprise.dot_role_id in user_role_ids:
        return UserRole.DOT
    else:
        return UserRole.EMPLOYE

# ========== DATABASE FUNCTIONS ==========

def get_or_create_user(db: Session, discord_user_data: Dict[str, Any], enterprise: Optional[Enterprise] = None) -> User:
    """Récupérer ou créer un utilisateur à partir des données Discord."""
    discord_id = str(discord_user_data["id"])
    
    # Chercher l'utilisateur existant
    user = db.query(User).filter(User.discord_id == discord_id).first()
    
    if user:
        # Mettre à jour les données existantes
        user.discord_username = discord_user_data.get("username", "Unknown")
        user.email = discord_user_data.get("email")
        user.avatar_url = f"https://cdn.discordapp.com/avatars/{discord_id}/{discord_user_data.get('avatar', '')}.png" if discord_user_data.get('avatar') else None
        user.last_login = datetime.now(timezone.utc)
        
        if enterprise:
            user.enterprise_id = enterprise.id
        
        db.commit()
        db.refresh(user)
        return user
    else:
        # Créer un nouvel utilisateur
        new_user = User(
            discord_id=discord_id,
            discord_username=discord_user_data.get("username", "Unknown"),
            email=discord_user_data.get("email"),
            avatar_url=f"https://cdn.discordapp.com/avatars/{discord_id}/{discord_user_data.get('avatar', '')}.png" if discord_user_data.get('avatar') else None,
            enterprise_id=enterprise.id if enterprise else None,
            role=UserRole.EMPLOYE,  # Rôle par défaut
            last_login=datetime.now(timezone.utc)
        )
        
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return new_user

def find_user_enterprise(db: Session, discord_user_data: Dict[str, Any]) -> Optional[Enterprise]:
    """Trouver l'entreprise d'un utilisateur basé sur ses guilds Discord."""
    user_guilds = discord_user_data.get("guilds", [])
    
    for guild in user_guilds:
        guild_id = str(guild["id"])
        enterprise = db.query(Enterprise).filter(Enterprise.discord_guild_id == guild_id).first()
        if enterprise:
            return enterprise
    
    return None

# ========== AUTHENTICATION DEPENDENCIES ==========

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """Dépendance pour récupérer l'utilisateur actuel à partir du token JWT."""
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        token_data = verify_token(credentials.credentials)
        
        if token_data.token_type != "access":
            raise credentials_exception
        
    except AuthenticationError:
        raise credentials_exception
    
    user = db.query(User).filter(User.id == token_data.user_id).first()
    if user is None or not user.is_active:
        raise credentials_exception
    
    return user

async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """Dépendance pour récupérer l'utilisateur actuel actif."""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

# ========== ROLE-BASED ACCESS CONTROL ==========

class RequireRole:
    """Décorateur de classe pour contrôler l'accès basé sur les rôles."""
    
    def __init__(self, allowed_roles: List[UserRole]):
        self.allowed_roles = allowed_roles
    
    def __call__(self, current_user: User = Depends(get_current_active_user)) -> User:
        if current_user.role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not enough permissions"
            )
        return current_user

# Dépendances pré-configurées pour les rôles
require_staff = RequireRole([UserRole.STAFF])
require_patron_or_staff = RequireRole([UserRole.PATRON, UserRole.CO_PATRON, UserRole.STAFF])
require_patron = RequireRole([UserRole.PATRON, UserRole.CO_PATRON])
require_dotation_access = RequireRole([UserRole.PATRON, UserRole.CO_PATRON, UserRole.STAFF, UserRole.DOT])

# ========== UTILITY FUNCTIONS ==========

def generate_discord_oauth_url(state: Optional[str] = None) -> str:
    """Générer l'URL d'authentification Discord OAuth."""
    base_url = "https://discord.com/api/oauth2/authorize"
    params = {
        "client_id": DISCORD_CLIENT_ID,
        "redirect_uri": DISCORD_REDIRECT_URI,
        "response_type": "code",
        "scope": "identify email guilds",
    }
    
    if state:
        params["state"] = state
    
    query_string = "&".join([f"{k}={v}" for k, v in params.items()])
    return f"{base_url}?{query_string}"

def create_tokens_for_user(user: User) -> Dict[str, str]:
    """Créer les tokens JWT pour un utilisateur."""
    token_data = {"sub": user.id}
    
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }