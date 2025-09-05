from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc
from typing import List, Optional
import logging
import tempfile
import os
from datetime import datetime, timezone

from database import get_db
from models import User, DotationReport, DotationRow
from schemas import (
    DotationReportCreate, DotationReportUpdate, DotationReportResponse,
    DotationRowCreate, DotationRowUpdate, DotationRowResponse,
    DotationBulkImport, PaginationParams, PaginatedResponse,
    ExportRequest, ApiResponse
)
from auth import get_current_active_user, require_dotation_access
from utils.dotation_utils import (
    calculate_dotation_totals, parse_bulk_dotation_data,
    export_dotation_pdf, export_dotation_excel
)
from utils.audit import log_action

router = APIRouter(prefix="/api/dotations", tags=["Dotations"])
logger = logging.getLogger(__name__)

@router.get("", response_model=PaginatedResponse, summary="Lister les rapports de dotation")
async def list_dotation_reports(
    pagination: PaginationParams = Depends(),
    status: Optional[str] = None,
    period: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_dotation_access)
):
    """
    Lister les rapports de dotation avec pagination et filtres.
    
    - **status**: Filtrer par statut (En attente, Validé, Refusé)
    - **period**: Filtrer par période
    - **page**: Numéro de page (défaut: 1)
    - **limit**: Nombre d'éléments par page (défaut: 20, max: 100)
    """
    try:
        query = db.query(DotationReport)
        
        # Filtrer par entreprise de l'utilisateur
        if current_user.enterprise_id:
            query = query.filter(DotationReport.enterprise_id == current_user.enterprise_id)
        
        # Filtres optionnels
        if status:
            query = query.filter(DotationReport.status == status)
        
        if period:
            query = query.filter(DotationReport.period.ilike(f"%{period}%"))
        
        # Pagination
        total = query.count()
        reports = query.order_by(desc(DotationReport.created_at)).offset(
            (pagination.page - 1) * pagination.limit
        ).limit(pagination.limit).all()
        
        # Calculer le nombre total de pages
        total_pages = (total + pagination.limit - 1) // pagination.limit
        
        # Convertir en réponse
        report_responses = [DotationReportResponse.from_orm(report) for report in reports]
        
        logger.info(f"Récupération de {len(reports)} rapports de dotation pour {current_user.discord_username}")
        
        return PaginatedResponse(
            items=report_responses,
            total=total,
            page=pagination.page,
            limit=pagination.limit,
            total_pages=total_pages
        )
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des rapports de dotation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des rapports de dotation"
        )

@router.post("", response_model=DotationReportResponse, summary="Créer un rapport de dotation")
async def create_dotation_report(
    report_data: DotationReportCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_dotation_access)
):
    """
    Créer un nouveau rapport de dotation avec ses lignes d'employés.
    
    Les calculs (CA total, salaires, primes) sont automatiquement effectués.
    """
    try:
        if not current_user.enterprise_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Utilisateur non associé à une entreprise"
            )
        
        # Créer le rapport principal
        new_report = DotationReport(
            enterprise_id=current_user.enterprise_id,
            created_by=current_user.id,
            title=report_data.title,
            period=report_data.period,
            notes=report_data.notes
        )
        
        db.add(new_report)
        db.commit()
        db.refresh(new_report)
        
        # Ajouter les lignes d'employés
        for row_data in report_data.rows:
            # Calcul automatique du CA total
            ca_total = row_data.run + row_data.facture + row_data.vente
            
            # Calculs des salaires et primes (logique métier à adapter)
            salaire = ca_total * 0.35  # 35% du CA
            prime = ca_total * 0.08    # 8% du CA
            
            dotation_row = DotationRow(
                report_id=new_report.id,
                employee_name=row_data.employee_name,
                grade=row_data.grade,
                run=row_data.run,
                facture=row_data.facture,
                vente=row_data.vente,
                ca_total=ca_total,
                salaire=salaire,
                prime=prime
            )
            
            db.add(dotation_row)
        
        # Calculer les totaux du rapport
        calculate_dotation_totals(db, new_report.id)
        
        db.commit()
        db.refresh(new_report)
        
        # Log de l'action
        await log_action(
            db, current_user.id, "CREATE", "dotation_reports", 
            new_report.id, None, new_report.__dict__
        )
        
        logger.info(f"Rapport de dotation créé: {new_report.id} par {current_user.discord_username}")
        
        return DotationReportResponse.from_orm(new_report)
        
    except Exception as e:
        logger.error(f"Erreur lors de la création du rapport de dotation: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la création du rapport de dotation"
        )

@router.get("/{report_id}", response_model=DotationReportResponse, summary="Récupérer un rapport de dotation")
async def get_dotation_report(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_dotation_access)
):
    """
    Récupérer un rapport de dotation spécifique avec toutes ses lignes.
    """
    try:
        report = db.query(DotationReport).filter(
            DotationReport.id == report_id
        ).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rapport de dotation introuvable"
            )
        
        # Vérifier les permissions (même entreprise)
        if current_user.enterprise_id and report.enterprise_id != current_user.enterprise_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès non autorisé à ce rapport"
            )
        
        return DotationReportResponse.from_orm(report)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la récupération du rapport de dotation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération du rapport de dotation"
        )

@router.put("/{report_id}", response_model=DotationReportResponse, summary="Mettre à jour un rapport de dotation")
async def update_dotation_report(
    report_id: str,
    report_data: DotationReportUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_dotation_access)
):
    """
    Mettre à jour un rapport de dotation existant.
    """
    try:
        report = db.query(DotationReport).filter(
            DotationReport.id == report_id
        ).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rapport de dotation introuvable"
            )
        
        # Vérifier les permissions
        if current_user.enterprise_id and report.enterprise_id != current_user.enterprise_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès non autorisé à ce rapport"
            )
        
        # Sauvegarder les anciennes valeurs pour l'audit
        old_values = report.__dict__.copy()
        
        # Mettre à jour les champs
        update_data = report_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(report, field, value)
        
        report.updated_at = datetime.now(timezone.utc)
        
        db.commit()
        db.refresh(report)
        
        # Log de l'action
        await log_action(
            db, current_user.id, "UPDATE", "dotation_reports",
            report.id, old_values, report.__dict__
        )
        
        logger.info(f"Rapport de dotation mis à jour: {report_id} par {current_user.discord_username}")
        
        return DotationReportResponse.from_orm(report)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la mise à jour du rapport de dotation: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la mise à jour du rapport de dotation"
        )

@router.delete("/{report_id}", response_model=ApiResponse, summary="Supprimer un rapport de dotation")
async def delete_dotation_report(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_dotation_access)
):
    """
    Supprimer un rapport de dotation et toutes ses lignes associées.
    """
    try:
        report = db.query(DotationReport).filter(
            DotationReport.id == report_id
        ).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rapport de dotation introuvable"
            )
        
        # Vérifier les permissions
        if current_user.enterprise_id and report.enterprise_id != current_user.enterprise_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès non autorisé à ce rapport"
            )
        
        # Sauvegarder pour l'audit
        old_values = report.__dict__.copy()
        
        # Supprimer (cascade supprime automatiquement les lignes)
        db.delete(report)
        db.commit()
        
        # Log de l'action
        await log_action(
            db, current_user.id, "DELETE", "dotation_reports",
            report_id, old_values, None
        )
        
        logger.info(f"Rapport de dotation supprimé: {report_id} par {current_user.discord_username}")
        
        return ApiResponse(
            success=True,
            message="Rapport de dotation supprimé avec succès"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la suppression du rapport de dotation: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la suppression du rapport de dotation"
        )

@router.post("/bulk-import", response_model=ApiResponse, summary="Import en lot des données de dotation")
async def bulk_import_dotation_data(
    import_data: DotationBulkImport,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_dotation_access)
):
    """
    Importer des données de dotation en lot depuis du texte CSV/Excel collé.
    
    Format attendu: Nom;RUN;FACTURE;VENTE (séparateurs: ; , tab)
    """
    try:
        if not current_user.enterprise_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Utilisateur non associé à une entreprise"
            )
        
        # Parser les données
        parsed_rows = parse_bulk_dotation_data(import_data.data, import_data.format)
        
        if not parsed_rows:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Aucune donnée valide trouvée. Vérifiez le format: Nom;RUN;FACTURE;VENTE"
            )
        
        # Créer un rapport de dotation pour l'import
        import_report = DotationReport(
            enterprise_id=current_user.enterprise_id,
            created_by=current_user.id,
            title=f"Import en lot {datetime.now().strftime('%Y-%m-%d %H:%M')}",
            period=datetime.now().strftime('%Y-%m')
        )
        
        db.add(import_report)
        db.commit()
        db.refresh(import_report)
        
        # Ajouter les lignes parsées
        for row_data in parsed_rows:
            dotation_row = DotationRow(
                report_id=import_report.id,
                employee_name=row_data["nom"],
                grade=row_data.get("grade", "À définir"),
                run=row_data["run"],
                facture=row_data["facture"],
                vente=row_data["vente"],
                ca_total=row_data["ca_total"],
                salaire=row_data["salaire"],
                prime=row_data["prime"]
            )
            db.add(dotation_row)
        
        # Calculer les totaux
        calculate_dotation_totals(db, import_report.id)
        
        db.commit()
        
        # Log de l'action
        await log_action(
            db, current_user.id, "BULK_IMPORT", "dotation_reports",
            import_report.id, None, {"rows_count": len(parsed_rows)}
        )
        
        logger.info(f"Import en lot réussi: {len(parsed_rows)} lignes importées par {current_user.discord_username}")
        
        return ApiResponse(
            success=True,
            message=f"{len(parsed_rows)} employés importés avec succès",
            data={"report_id": import_report.id, "rows_imported": len(parsed_rows)}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de l'import en lot: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'import des données"
        )

@router.post("/{report_id}/export-pdf", summary="Exporter un rapport en PDF")
async def export_dotation_pdf_report(
    report_id: str,
    export_request: ExportRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_dotation_access)
):
    """
    Exporter un rapport de dotation en PDF (fiche impôt).
    """
    try:
        report = db.query(DotationReport).filter(
            DotationReport.id == report_id
        ).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rapport de dotation introuvable"
            )
        
        # Vérifier les permissions
        if current_user.enterprise_id and report.enterprise_id != current_user.enterprise_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès non autorisé à ce rapport"
            )
        
        # Générer le PDF
        pdf_path = await export_dotation_pdf(report, export_request.filters)
        
        # Log de l'action
        await log_action(
            db, current_user.id, "EXPORT_PDF", "dotation_reports",
            report_id, None, {"format": "pdf"}
        )
        
        logger.info(f"Export PDF généré pour le rapport {report_id} par {current_user.discord_username}")
        
        return FileResponse(
            path=pdf_path,
            filename=f"dotation_{report.title}_{report.period}.pdf",
            media_type="application/pdf"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de l'export PDF: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la génération du PDF"
        )

@router.post("/{report_id}/export-excel", summary="Exporter un rapport en Excel")
async def export_dotation_excel_report(
    report_id: str,
    export_request: ExportRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_dotation_access)
):
    """
    Exporter un rapport de dotation en Excel (multi-feuilles).
    """
    try:
        report = db.query(DotationReport).filter(
            DotationReport.id == report_id
        ).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rapport de dotation introuvable"
            )
        
        # Vérifier les permissions
        if current_user.enterprise_id and report.enterprise_id != current_user.enterprise_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès non autorisé à ce rapport"
            )
        
        # Générer l'Excel
        excel_path = await export_dotation_excel(report, export_request.filters)
        
        # Log de l'action
        await log_action(
            db, current_user.id, "EXPORT_EXCEL", "dotation_reports",
            report_id, None, {"format": "excel"}
        )
        
        logger.info(f"Export Excel généré pour le rapport {report_id} par {current_user.discord_username}")
        
        return FileResponse(
            path=excel_path,
            filename=f"dotation_{report.title}_{report.period}.xlsx",
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de l'export Excel: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la génération du fichier Excel"
        )

# ========== ROUTES POUR LES LIGNES DE DOTATION ==========

@router.get("/{report_id}/rows", response_model=List[DotationRowResponse], summary="Lister les lignes d'un rapport")
async def list_dotation_rows(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_dotation_access)
):
    """
    Lister toutes les lignes d'employés d'un rapport de dotation.
    """
    try:
        # Vérifier que le rapport existe et que l'utilisateur y a accès
        report = db.query(DotationReport).filter(DotationReport.id == report_id).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rapport de dotation introuvable"
            )
        
        if current_user.enterprise_id and report.enterprise_id != current_user.enterprise_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès non autorisé à ce rapport"
            )
        
        # Récupérer les lignes
        rows = db.query(DotationRow).filter(DotationRow.report_id == report_id).all()
        
        return [DotationRowResponse.from_orm(row) for row in rows]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des lignes de dotation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des lignes de dotation"
        )

@router.post("/{report_id}/rows", response_model=DotationRowResponse, summary="Ajouter une ligne de dotation")
async def add_dotation_row(
    report_id: str,
    row_data: DotationRowCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_dotation_access)
):
    """
    Ajouter une nouvelle ligne d'employé à un rapport de dotation.
    """
    try:
        # Vérifier que le rapport existe et que l'utilisateur y a accès
        report = db.query(DotationReport).filter(DotationReport.id == report_id).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rapport de dotation introuvable"
            )
        
        if current_user.enterprise_id and report.enterprise_id != current_user.enterprise_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès non autorisé à ce rapport"
            )
        
        # Créer la nouvelle ligne avec calculs automatiques
        ca_total = row_data.run + row_data.facture + row_data.vente
        salaire = ca_total * 0.35  # 35% du CA
        prime = ca_total * 0.08    # 8% du CA
        
        new_row = DotationRow(
            report_id=report_id,
            employee_name=row_data.employee_name,
            grade=row_data.grade,
            run=row_data.run,
            facture=row_data.facture,
            vente=row_data.vente,
            ca_total=ca_total,
            salaire=salaire,
            prime=prime
        )
        
        db.add(new_row)
        
        # Recalculer les totaux du rapport
        calculate_dotation_totals(db, report_id)
        
        db.commit()
        db.refresh(new_row)
        
        logger.info(f"Ligne de dotation ajoutée au rapport {report_id} par {current_user.discord_username}")
        
        return DotationRowResponse.from_orm(new_row)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de l'ajout de la ligne de dotation: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'ajout de la ligne de dotation"
        )