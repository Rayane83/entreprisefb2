from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List, Optional
import logging
from datetime import datetime, timezone

from database import get_db
from models import User, TaxDeclaration, TaxBracket
from schemas import (
    TaxDeclarationCreate, TaxDeclarationUpdate, TaxDeclarationResponse,
    TaxCalculationRequest, TaxCalculationResponse,
    PaginationParams, PaginatedResponse, ApiResponse
)
from auth import get_current_active_user, require_patron_or_staff
from utils.tax_utils import calculate_taxes, get_tax_brackets
from utils.audit import log_action

router = APIRouter(prefix="/api/tax-declarations", tags=["Tax Declarations"])
logger = logging.getLogger(__name__)

@router.get("", response_model=PaginatedResponse, summary="Lister les déclarations d'impôts")
async def list_tax_declarations(
    pagination: PaginationParams = Depends(),
    period: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_patron_or_staff)
):
    """Lister les déclarations d'impôts avec pagination et filtres."""
    try:
        query = db.query(TaxDeclaration)
        
        # Filtrer par entreprise
        if current_user.enterprise_id:
            query = query.filter(TaxDeclaration.enterprise_id == current_user.enterprise_id)
        
        # Filtres
        if period:
            query = query.filter(TaxDeclaration.period.ilike(f"%{period}%"))
        if status:
            query = query.filter(TaxDeclaration.status == status)
        
        # Pagination
        total = query.count()
        declarations = query.order_by(desc(TaxDeclaration.created_at)).offset(
            (pagination.page - 1) * pagination.limit
        ).limit(pagination.limit).all()
        
        total_pages = (total + pagination.limit - 1) // pagination.limit
        
        return PaginatedResponse(
            items=[TaxDeclarationResponse.from_orm(d) for d in declarations],
            total=total,
            page=pagination.page,
            limit=pagination.limit,
            total_pages=total_pages
        )
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des déclarations: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des déclarations d'impôts"
        )

@router.post("", response_model=TaxDeclarationResponse, summary="Créer une déclaration d'impôts")
async def create_tax_declaration(
    declaration_data: TaxDeclarationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_patron_or_staff)
):
    """Créer une nouvelle déclaration d'impôts avec calculs automatiques."""
    try:
        if not current_user.enterprise_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Utilisateur non associé à une entreprise"
            )
        
        # Calculer les impôts
        tax_calculation = await calculate_taxes(
            db,
            declaration_data.revenus_imposables,
            declaration_data.abattements,
            declaration_data.patrimoine
        )
        
        # Créer la déclaration
        new_declaration = TaxDeclaration(
            enterprise_id=current_user.enterprise_id,
            user_id=current_user.id,
            period=declaration_data.period,
            revenus_totaux=declaration_data.revenus_totaux,
            revenus_imposables=declaration_data.revenus_imposables,
            abattements=declaration_data.abattements,
            patrimoine=declaration_data.patrimoine,
            impot_revenus=tax_calculation.impot_revenus,
            impot_patrimoine=tax_calculation.impot_patrimoine,
            impot_total=tax_calculation.impot_total,
            notes=declaration_data.notes
        )
        
        db.add(new_declaration)
        db.commit()
        db.refresh(new_declaration)
        
        # Log de l'action
        await log_action(
            db, current_user.id, "CREATE", "tax_declarations",
            new_declaration.id, None, new_declaration.__dict__
        )
        
        logger.info(f"Déclaration d'impôts créée: {new_declaration.id}")
        
        return TaxDeclarationResponse.from_orm(new_declaration)
        
    except Exception as e:
        logger.error(f"Erreur lors de la création de la déclaration: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la création de la déclaration d'impôts"
        )

@router.post("/calculate", response_model=TaxCalculationResponse, summary="Calculer les impôts")
async def calculate_tax_preview(
    calculation_request: TaxCalculationRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Calculer les impôts sans sauvegarder (prévisualisation)."""
    try:
        result = await calculate_taxes(
            db,
            calculation_request.revenus_imposables,
            calculation_request.abattements,
            calculation_request.patrimoine
        )
        
        return result
        
    except Exception as e:
        logger.error(f"Erreur lors du calcul des impôts: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors du calcul des impôts"
        )

@router.get("/brackets", response_model=List[dict], summary="Obtenir les paliers fiscaux")
async def get_tax_brackets_endpoint(
    bracket_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Récupérer les paliers fiscaux actuels."""
    try:
        brackets = await get_tax_brackets(db, bracket_type)
        return brackets
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des paliers: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des paliers fiscaux"
        )