from fastapi import APIRouter, Depends, HTTPException, status, Response, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from datetime import datetime, timezone
import logging
from typing import Dict, Any

from database import get_db
from models import User, Enterprise
from schemas import (
    DiscordAuthCallback, AuthResponse, Token, TokenRefresh,
    UserResponse, BaseResponse, ApiResponse
)
from auth import (
    get_discord_user_from_code, get_or_create_user, find_user_enterprise,
    create_tokens_for_user, verify_token, generate_discord_oauth_url,
    get_current_active_user, get_discord_guild_member, determine_user_role,
    DiscordOAuthError, AuthenticationError
)

router = APIRouter(prefix="/auth", tags=["Authentication"])
logger = logging.getLogger(__name__)

@router.get("/discord", summary="Initier l'authentification Discord")
async def discord_auth(request: Request):
    """
    Rediriger vers Discord OAuth pour l'authentification.
    Génère l'URL Discord OAuth et redirige l'utilisateur.
    """
    try:
        # Générer un state pour sécuriser la requête (optionnel)
        state = f"auth_{datetime.now().timestamp()}"
        
        discord_url = generate_discord_oauth_url(state=state)
        
        logger.info(f"Redirection vers Discord OAuth: {discord_url}")
        
        return RedirectResponse(url=discord_url, status_code=302)
        
    except Exception as e:
        logger.error(f"Erreur lors de la génération de l'URL Discord: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'initialisation de l'authentification Discord"
        )

@router.post("/discord/callback", response_model=AuthResponse, summary="Callback Discord OAuth")
async def discord_callback(
    callback_data: DiscordAuthCallback,
    db: Session = Depends(get_db)
):
    """
    Traiter le callback Discord OAuth et authentifier l'utilisateur.
    
    - Échanger le code contre les données utilisateur Discord
    - Créer ou mettre à jour l'utilisateur en base
    - Déterminer l'entreprise et le rôle
    - Générer les tokens JWT
    """
    try:
        # 1. Récupérer les données utilisateur depuis Discord
        logger.info(f"Traitement du callback Discord avec code: {callback_data.code[:10]}...")
        
        discord_user_data = await get_discord_user_from_code(callback_data.code)
        
        if not discord_user_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Impossible de récupérer les données utilisateur Discord"
            )
        
        logger.info(f"Utilisateur Discord récupéré: {discord_user_data.get('username', 'Unknown')}")
        
        # 2. Trouver l'entreprise associée
        enterprise = find_user_enterprise(db, discord_user_data)
        
        if not enterprise:
            # Créer une entreprise par défaut ou refuser l'accès
            logger.warning(f"Aucune entreprise trouvée pour l'utilisateur {discord_user_data.get('username')}")
            # Pour l'instant, on continue sans entreprise
        
        # 3. Créer ou mettre à jour l'utilisateur
        user = get_or_create_user(db, discord_user_data, enterprise)
        
        # 4. Déterminer le rôle basé sur Discord
        if enterprise:
            member_data = await get_discord_guild_member(
                enterprise.discord_guild_id, 
                discord_user_data["id"]
            )
            user_role = determine_user_role(member_data, enterprise)
            
            # Mettre à jour le rôle si différent
            if user.role != user_role:
                user.role = user_role
                db.commit()
                db.refresh(user)
                logger.info(f"Rôle utilisateur mis à jour: {user_role}")
        
        # 5. Générer les tokens JWT
        tokens = create_tokens_for_user(user)
        
        # 6. Créer la réponse
        user_response = UserResponse.from_orm(user)
        auth_response = AuthResponse(
            tokens=Token(**tokens),
            user=user_response
        )
        
        logger.info(f"Authentification réussie pour {user.discord_username} (role: {user.role})")
        
        return auth_response
        
    except DiscordOAuthError as e:
        logger.error(f"Erreur Discord OAuth: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erreur d'authentification Discord: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Erreur inattendue lors du callback Discord: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur interne lors de l'authentification"
        )

@router.post("/refresh", response_model=Token, summary="Rafraîchir le token d'accès")
async def refresh_token(
    token_data: TokenRefresh,
    db: Session = Depends(get_db)
):
    """
    Rafraîchir le token d'accès à partir du refresh token.
    """
    try:
        # Vérifier le refresh token
        token_payload = verify_token(token_data.refresh_token)
        
        if token_payload.token_type != "refresh":
            raise AuthenticationError("Token de refresh invalide")
        
        # Récupérer l'utilisateur
        user = db.query(User).filter(User.id == token_payload.user_id).first()
        
        if not user or not user.is_active:
            raise AuthenticationError("Utilisateur introuvable ou inactif")
        
        # Générer de nouveaux tokens
        new_tokens = create_tokens_for_user(user)
        
        logger.info(f"Tokens rafraîchis pour l'utilisateur {user.discord_username}")
        
        return Token(**new_tokens)
        
    except AuthenticationError as e:
        logger.error(f"Erreur lors du refresh token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token invalide ou expiré"
        )
    except Exception as e:
        logger.error(f"Erreur inattendue lors du refresh: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur interne lors du rafraîchissement du token"
        )

@router.post("/logout", response_model=BaseResponse, summary="Déconnexion")
async def logout(
    current_user: User = Depends(get_current_active_user)
):
    """
    Déconnecter l'utilisateur.
    Note: Avec JWT, la déconnexion côté serveur est limitée.
    Le client doit supprimer les tokens.
    """
    try:
        logger.info(f"Déconnexion de l'utilisateur {current_user.discord_username}")
        
        # Optionnel: Mettre à jour la dernière activité
        # current_user.last_activity = datetime.now(timezone.utc)
        # db.commit()
        
        return BaseResponse(
            success=True,
            message="Déconnexion réussie"
        )
        
    except Exception as e:
        logger.error(f"Erreur lors de la déconnexion: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la déconnexion"
        )

@router.get("/me", response_model=UserResponse, summary="Profile utilisateur actuel")
async def get_current_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """
    Récupérer le profil de l'utilisateur actuellement connecté.
    """
    try:
        return UserResponse.from_orm(current_user)
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération du profil: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération du profil utilisateur"
        )

@router.get("/check", response_model=ApiResponse, summary="Vérifier le token")
async def check_token(
    current_user: User = Depends(get_current_active_user)
):
    """
    Vérifier si le token d'accès est valide.
    """
    try:
        return ApiResponse(
            success=True,
            message="Token valide",
            data={
                "user_id": current_user.id,
                "username": current_user.discord_username,
                "role": current_user.role,
                "enterprise_id": current_user.enterprise_id,
                "is_active": current_user.is_active
            }
        )
        
    except Exception as e:
        logger.error(f"Erreur lors de la vérification du token: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la vérification du token"
        )

@router.get("/discord-url", response_model=ApiResponse, summary="Obtenir l'URL Discord OAuth")
async def get_discord_oauth_url():
    """
    Obtenir l'URL Discord OAuth sans redirection automatique.
    Utile pour les applications frontend qui gèrent la redirection manuellement.
    """
    try:
        state = f"manual_{datetime.now().timestamp()}"
        discord_url = generate_discord_oauth_url(state=state)
        
        return ApiResponse(
            success=True,
            message="URL Discord OAuth générée",
            data={"url": discord_url, "state": state}
        )
        
    except Exception as e:
        logger.error(f"Erreur lors de la génération de l'URL Discord: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la génération de l'URL Discord OAuth"
        )