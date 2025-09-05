from sqlalchemy.orm import Session
from typing import Optional, Dict, Any
import json
import logging
from datetime import datetime, timezone

from models import AuditLog

logger = logging.getLogger(__name__)

async def log_action(
    db: Session,
    user_id: Optional[str],
    action: str,
    table_name: Optional[str] = None,
    record_id: Optional[str] = None,
    old_values: Optional[Dict[str, Any]] = None,
    new_values: Optional[Dict[str, Any]] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None
):
    """
    Enregistrer une action d'audit dans la base de données.
    
    Args:
        db: Session de base de données
        user_id: ID de l'utilisateur qui effectue l'action
        action: Type d'action (CREATE, UPDATE, DELETE, LOGIN, etc.)
        table_name: Nom de la table concernée
        record_id: ID de l'enregistrement concerné
        old_values: Anciennes valeurs (pour UPDATE/DELETE)
        new_values: Nouvelles valeurs (pour CREATE/UPDATE)
        ip_address: Adresse IP de l'utilisateur
        user_agent: User-Agent du navigateur
    """
    try:
        # Nettoyer les valeurs pour la sérialisation JSON
        clean_old_values = None
        clean_new_values = None
        
        if old_values:
            clean_old_values = clean_values_for_json(old_values)
        
        if new_values:
            clean_new_values = clean_values_for_json(new_values)
        
        # Créer l'entrée d'audit
        audit_log = AuditLog(
            user_id=user_id,
            action=action,
            table_name=table_name,
            record_id=record_id,
            old_values=clean_old_values,
            new_values=clean_new_values,
            ip_address=ip_address,
            user_agent=user_agent
        )
        
        db.add(audit_log)
        db.commit()
        
        logger.info(f"Action d'audit enregistrée: {action} sur {table_name}:{record_id} par user:{user_id}")
        
    except Exception as e:
        logger.error(f"Erreur lors de l'enregistrement de l'audit: {e}")
        # Ne pas faire échouer l'opération principale à cause de l'audit
        db.rollback()

def clean_values_for_json(values: Dict[str, Any]) -> Dict[str, Any]:
    """
    Nettoyer les valeurs pour qu'elles soient sérialisables en JSON.
    """
    cleaned = {}
    
    for key, value in values.items():
        # Ignorer les clés privées et les relations SQLAlchemy
        if key.startswith('_'):
            continue
        
        try:
            # Convertir les datetime en chaînes ISO
            if hasattr(value, 'isoformat'):
                cleaned[key] = value.isoformat()
            # Convertir les enums en valeurs string
            elif hasattr(value, 'value'):
                cleaned[key] = value.value
            # Garder les types JSON-sérialisables
            elif isinstance(value, (str, int, float, bool, type(None))):
                cleaned[key] = value
            # Convertir le reste en string
            else:
                cleaned[key] = str(value)
                
        except Exception as e:
            logger.warning(f"Impossible de sérialiser la valeur {key}: {e}")
            cleaned[key] = f"<non-serializable: {type(value).__name__}>"
    
    return cleaned

def get_client_ip(request) -> Optional[str]:
    """
    Extraire l'adresse IP du client à partir de la requête FastAPI.
    """
    try:
        # Vérifier les headers de proxy
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        # IP directe du client
        if hasattr(request, "client") and request.client:
            return request.client.host
        
        return None
        
    except Exception as e:
        logger.warning(f"Impossible d'extraire l'IP du client: {e}")
        return None

def get_user_agent(request) -> Optional[str]:
    """
    Extraire le User-Agent à partir de la requête FastAPI.
    """
    try:
        return request.headers.get("User-Agent")
    except Exception as e:
        logger.warning(f"Impossible d'extraire le User-Agent: {e}")
        return None

# Décorateur pour l'audit automatique
def audit_action(action: str, table_name: Optional[str] = None):
    """
    Décorateur pour l'audit automatique des actions.
    """
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # Extraire les paramètres communs
            db = None
            current_user = None
            request = None
            
            # Chercher les paramètres dans les arguments
            for arg in args:
                if hasattr(arg, 'query'):  # Session SQLAlchemy
                    db = arg
                elif hasattr(arg, 'discord_id'):  # User model
                    current_user = arg
                elif hasattr(arg, 'headers'):  # FastAPI Request
                    request = arg
            
            # Chercher dans les kwargs
            db = db or kwargs.get('db')
            current_user = current_user or kwargs.get('current_user')
            request = request or kwargs.get('request')
            
            # Exécuter la fonction originale
            result = await func(*args, **kwargs)
            
            # Enregistrer l'audit si possible
            if db and current_user:
                try:
                    ip_address = get_client_ip(request) if request else None
                    user_agent = get_user_agent(request) if request else None
                    
                    await log_action(
                        db=db,
                        user_id=current_user.id,
                        action=action,
                        table_name=table_name,
                        ip_address=ip_address,
                        user_agent=user_agent
                    )
                except Exception as e:
                    logger.warning(f"Audit automatique échoué: {e}")
            
            return result
        
        return wrapper
    return decorator