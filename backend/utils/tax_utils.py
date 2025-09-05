from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
import logging

from models import TaxBracket
from schemas import TaxCalculationResponse

logger = logging.getLogger(__name__)

async def calculate_taxes(
    db: Session,
    revenus_imposables: float,
    abattements: float = 0.0,
    patrimoine: float = 0.0
) -> TaxCalculationResponse:
    """Calculer les impôts sur les revenus et le patrimoine."""
    try:
        # Base imposable pour les revenus
        base_imposable = max(0, revenus_imposables - abattements)
        
        # Calculer l'impôt sur les revenus
        income_brackets = await get_tax_brackets(db, "revenus")
        income_tax_result = calculate_tax_for_amount(base_imposable, income_brackets)
        
        # Calculer l'impôt sur le patrimoine
        wealth_brackets = await get_tax_brackets(db, "patrimoine")
        wealth_tax_result = calculate_tax_for_amount(patrimoine, wealth_brackets)
        
        total_tax = income_tax_result["tax"] + wealth_tax_result["tax"]
        
        return TaxCalculationResponse(
            impot_revenus=income_tax_result["tax"],
            impot_patrimoine=wealth_tax_result["tax"],
            impot_total=total_tax,
            income_tax_bracket=income_tax_result["bracket"],
            income_tax_rate=income_tax_result["rate"],
            wealth_tax_bracket=wealth_tax_result["bracket"],
            wealth_tax_rate=wealth_tax_result["rate"]
        )
        
    except Exception as e:
        logger.error(f"Erreur lors du calcul des impôts: {e}")
        raise

def calculate_tax_for_amount(amount: float, brackets: List[Dict]) -> Dict[str, Any]:
    """Calculer l'impôt pour un montant donné selon les paliers."""
    if not brackets or amount <= 0:
        return {
            "tax": 0.0,
            "bracket": "0€ - 0€",
            "rate": 0.0
        }
    
    for bracket in brackets:
        min_amount = bracket["min_amount"]
        max_amount = bracket["max_amount"]
        tax_rate = bracket["tax_rate"]
        
        if amount >= min_amount and (max_amount is None or amount <= max_amount):
            # Calcul de l'impôt
            taxable_amount = amount - min_amount
            tax = taxable_amount * tax_rate
            
            # Format du palier
            bracket_str = f"{min_amount:,.0f}€ - {max_amount:,.0f}€" if max_amount else f"{min_amount:,.0f}€ - ∞"
            
            return {
                "tax": round(tax, 2),
                "bracket": bracket_str,
                "rate": tax_rate * 100  # Convertir en pourcentage
            }
    
    # Si aucun palier trouvé, utiliser le dernier
    last_bracket = brackets[-1]
    return {
        "tax": 0.0,
        "bracket": f"{last_bracket['min_amount']:,.0f}€ - ∞",
        "rate": last_bracket["tax_rate"] * 100
    }

async def get_tax_brackets(db: Session, bracket_type: Optional[str] = None) -> List[Dict[str, Any]]:
    """Récupérer les paliers fiscaux depuis la base de données."""
    try:
        query = db.query(TaxBracket).filter(TaxBracket.is_active == True)
        
        if bracket_type:
            query = query.filter(TaxBracket.bracket_type == bracket_type)
        
        brackets = query.order_by(TaxBracket.min_amount).all()
        
        result = []
        for bracket in brackets:
            result.append({
                "id": bracket.id,
                "bracket_type": bracket.bracket_type,
                "min_amount": bracket.min_amount,
                "max_amount": bracket.max_amount,
                "tax_rate": bracket.tax_rate
            })
        
        return result
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des paliers: {e}")
        return []

async def initialize_default_tax_brackets(db: Session):
    """Initialiser les paliers fiscaux par défaut si ils n'existent pas."""
    try:
        # Vérifier si des paliers existent déjà
        existing_brackets = db.query(TaxBracket).count()
        
        if existing_brackets > 0:
            logger.info("Les paliers fiscaux existent déjà")
            return
        
        # Paliers pour les revenus
        income_brackets = [
            {"bracket_type": "revenus", "min_amount": 0, "max_amount": 100000, "tax_rate": 0.10},
            {"bracket_type": "revenus", "min_amount": 100001, "max_amount": 500000, "tax_rate": 0.15},
            {"bracket_type": "revenus", "min_amount": 500001, "max_amount": None, "tax_rate": 0.20},
        ]
        
        # Paliers pour le patrimoine
        wealth_brackets = [
            {"bracket_type": "patrimoine", "min_amount": 0, "max_amount": 100000, "tax_rate": 0.05},
            {"bracket_type": "patrimoine", "min_amount": 100001, "max_amount": 500000, "tax_rate": 0.10},
            {"bracket_type": "patrimoine", "min_amount": 500001, "max_amount": None, "tax_rate": 0.15},
        ]
        
        # Créer tous les paliers
        all_brackets = income_brackets + wealth_brackets
        
        for bracket_data in all_brackets:
            bracket = TaxBracket(**bracket_data)
            db.add(bracket)
        
        db.commit()
        logger.info(f"Paliers fiscaux initialisés: {len(all_brackets)} paliers créés")
        
    except Exception as e:
        logger.error(f"Erreur lors de l'initialisation des paliers fiscaux: {e}")
        db.rollback()
        raise