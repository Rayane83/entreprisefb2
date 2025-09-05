from pydantic import BaseModel, Field, EmailStr, validator
from typing import Optional, List, Dict, Any, Union
from datetime import datetime, date
from enum import Enum
import uuid

# ========== ENUMS ==========

class UserRoleEnum(str, Enum):
    STAFF = "staff"
    PATRON = "patron"
    CO_PATRON = "co-patron"
    DOT = "dot"
    EMPLOYE = "employe"

class ArchiveStatusEnum(str, Enum):
    EN_ATTENTE = "En attente"
    VALIDE = "Validé"
    REFUSE = "Refusé"

class BlanchimentStatusEnum(str, Enum):
    EN_COURS = "En cours"
    TERMINE = "Terminé"
    SUSPENDU = "Suspendu"
    ANNULE = "Annulé"

class DocumentTypeEnum(str, Enum):
    FACTURE = "Facture"
    DIPLOME = "Diplôme"
    CONTRAT = "Contrat"
    RAPPORT = "Rapport"
    DOCUMENT = "Document"

# ========== BASE SCHEMAS ==========

class BaseResponse(BaseModel):
    success: bool = True
    message: Optional[str] = None

class PaginationParams(BaseModel):
    page: int = Field(1, ge=1)
    limit: int = Field(20, ge=1, le=100)

class PaginatedResponse(BaseModel):
    items: List[Any]
    total: int
    page: int
    limit: int
    total_pages: int

# ========== AUTHENTICATION ==========

class TokenData(BaseModel):
    user_id: str
    token_type: str = "access"

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenRefresh(BaseModel):
    refresh_token: str

class DiscordAuthCallback(BaseModel):
    code: str
    state: Optional[str] = None

class AuthResponse(BaseModel):
    tokens: Token
    user: "UserResponse"

# ========== USER & ENTERPRISE ==========

class UserBase(BaseModel):
    discord_username: str
    email: Optional[EmailStr] = None
    role: UserRoleEnum = UserRoleEnum.EMPLOYE

class UserCreate(UserBase):
    discord_id: str
    avatar_url: Optional[str] = None

class UserUpdate(BaseModel):
    discord_username: Optional[str] = None
    email: Optional[EmailStr] = None
    role: Optional[UserRoleEnum] = None
    is_active: Optional[bool] = None

class UserResponse(BaseModel):
    id: str
    discord_id: str
    discord_username: str
    email: Optional[str] = None
    avatar_url: Optional[str] = None
    role: UserRoleEnum
    enterprise_id: Optional[str] = None
    is_active: bool
    last_login: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True

class EnterpriseBase(BaseModel):
    name: str
    discord_guild_id: str
    main_guild_role_id: Optional[str] = None
    staff_role_id: Optional[str] = None
    patron_role_id: Optional[str] = None
    co_patron_role_id: Optional[str] = None
    dot_role_id: Optional[str] = None
    member_role_id: Optional[str] = None

class EnterpriseCreate(EnterpriseBase):
    pass

class EnterpriseUpdate(BaseModel):
    name: Optional[str] = None
    main_guild_role_id: Optional[str] = None
    staff_role_id: Optional[str] = None
    patron_role_id: Optional[str] = None
    co_patron_role_id: Optional[str] = None
    dot_role_id: Optional[str] = None
    member_role_id: Optional[str] = None
    is_active: Optional[bool] = None

class EnterpriseResponse(BaseModel):
    id: str
    name: str
    discord_guild_id: str
    main_guild_role_id: Optional[str] = None
    staff_role_id: Optional[str] = None
    patron_role_id: Optional[str] = None
    co_patron_role_id: Optional[str] = None
    dot_role_id: Optional[str] = None
    member_role_id: Optional[str] = None
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# ========== DOTATIONS ==========

class DotationRowBase(BaseModel):
    employee_name: str
    grade: Optional[str] = None
    run: float = 0.0
    facture: float = 0.0
    vente: float = 0.0
    ca_total: float = 0.0
    salaire: float = 0.0
    prime: float = 0.0

class DotationRowCreate(DotationRowBase):
    pass

class DotationRowUpdate(BaseModel):
    employee_name: Optional[str] = None
    grade: Optional[str] = None
    run: Optional[float] = None
    facture: Optional[float] = None
    vente: Optional[float] = None
    ca_total: Optional[float] = None
    salaire: Optional[float] = None
    prime: Optional[float] = None

class DotationRowResponse(BaseModel):
    id: str
    employee_name: str
    grade: Optional[str] = None
    run: float
    facture: float
    vente: float
    ca_total: float
    salaire: float
    prime: float
    created_at: datetime
    
    class Config:
        from_attributes = True

class DotationReportBase(BaseModel):
    title: str
    period: Optional[str] = None
    notes: Optional[str] = None

class DotationReportCreate(DotationReportBase):
    rows: List[DotationRowCreate] = []

class DotationReportUpdate(BaseModel):
    title: Optional[str] = None
    period: Optional[str] = None
    status: Optional[ArchiveStatusEnum] = None
    notes: Optional[str] = None

class DotationReportResponse(BaseModel):
    id: str
    title: str
    period: Optional[str] = None
    status: ArchiveStatusEnum
    total_ca: float
    total_salaires: float
    total_primes: float
    total_employees: int
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    enterprise_id: str
    created_by: str
    rows: List[DotationRowResponse] = []
    
    class Config:
        from_attributes = True

class DotationBulkImport(BaseModel):
    data: str  # Données CSV/Excel collées
    format: str = "auto"  # "csv", "excel", "auto"

# ========== TAX DECLARATIONS ==========

class TaxDeclarationBase(BaseModel):
    period: str
    revenus_totaux: float = 0.0
    revenus_imposables: float = 0.0
    abattements: float = 0.0
    patrimoine: float = 0.0
    notes: Optional[str] = None

class TaxDeclarationCreate(TaxDeclarationBase):
    pass

class TaxDeclarationUpdate(BaseModel):
    period: Optional[str] = None
    revenus_totaux: Optional[float] = None
    revenus_imposables: Optional[float] = None
    abattements: Optional[float] = None
    patrimoine: Optional[float] = None
    status: Optional[ArchiveStatusEnum] = None
    notes: Optional[str] = None

class TaxDeclarationResponse(BaseModel):
    id: str
    period: str
    revenus_totaux: float
    revenus_imposables: float
    abattements: float
    patrimoine: float
    impot_revenus: float
    impot_patrimoine: float
    impot_total: float
    status: ArchiveStatusEnum
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    enterprise_id: str
    user_id: str
    
    class Config:
        from_attributes = True

class TaxCalculationRequest(BaseModel):
    revenus_imposables: float
    abattements: float = 0.0
    patrimoine: float = 0.0

class TaxCalculationResponse(BaseModel):
    impot_revenus: float
    impot_patrimoine: float
    impot_total: float
    income_tax_bracket: str
    income_tax_rate: float
    wealth_tax_bracket: str
    wealth_tax_rate: float

# ========== DOCUMENTS ==========

class DocumentResponse(BaseModel):
    id: str
    filename: str
    original_filename: str
    file_size: int
    mime_type: str
    document_type: DocumentTypeEnum
    is_active: bool
    created_at: datetime
    enterprise_id: str
    uploaded_by: str
    
    class Config:
        from_attributes = True

class DocumentStats(BaseModel):
    total: int
    factures: int
    diplomes: int
    contrats: int
    rapports: int
    autres: int
    total_size: int

# ========== BLANCHIMENT ==========

class BlanchimentSettingBase(BaseModel):
    is_enabled: bool = True
    use_global_settings: bool = True
    perc_entreprise: float = 15.0
    perc_groupe: float = 5.0

class BlanchimentSettingUpdate(BlanchimentSettingBase):
    pass

class BlanchimentSettingResponse(BaseModel):
    id: str
    is_enabled: bool
    use_global_settings: bool
    perc_entreprise: float
    perc_groupe: float
    updated_at: datetime
    enterprise_id: str
    
    class Config:
        from_attributes = True

class BlanchimentOperationBase(BaseModel):
    status: BlanchimentStatusEnum = BlanchimentStatusEnum.EN_COURS
    date_recu: Optional[date] = None
    date_rendu: Optional[date] = None
    groupe: str
    employe: str
    donneur_id: Optional[str] = None
    recepteur_id: Optional[str] = None
    somme: float
    entreprise_perc: float
    groupe_perc: float

class BlanchimentOperationCreate(BlanchimentOperationBase):
    pass

class BlanchimentOperationUpdate(BaseModel):
    status: Optional[BlanchimentStatusEnum] = None
    date_recu: Optional[date] = None
    date_rendu: Optional[date] = None
    groupe: Optional[str] = None
    employe: Optional[str] = None
    donneur_id: Optional[str] = None
    recepteur_id: Optional[str] = None
    somme: Optional[float] = None
    entreprise_perc: Optional[float] = None
    groupe_perc: Optional[float] = None

class BlanchimentOperationResponse(BaseModel):
    id: str
    status: BlanchimentStatusEnum
    date_recu: Optional[date] = None
    date_rendu: Optional[date] = None
    duree_jours: Optional[int] = None
    groupe: str
    employe: str
    donneur_id: Optional[str] = None
    recepteur_id: Optional[str] = None
    somme: float
    entreprise_perc: float
    groupe_perc: float
    created_at: datetime
    updated_at: datetime
    enterprise_id: str
    created_by: str
    
    class Config:
        from_attributes = True

class BlanchimentBulkImport(BaseModel):
    data: str  # Données CSV/Excel collées
    format: str = "auto"

class BlanchimentStats(BaseModel):
    total: int
    en_cours: int
    termine: int
    suspendu: int
    annule: int
    somme_totale: float

# ========== ARCHIVES ==========

class ArchiveBase(BaseModel):
    title: str
    description: Optional[str] = None
    archive_type: str
    montant: Optional[float] = None
    period: Optional[str] = None
    reference_id: Optional[str] = None
    archive_metadata: Optional[Dict[str, Any]] = None

class ArchiveCreate(ArchiveBase):
    pass

class ArchiveUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[ArchiveStatusEnum] = None
    montant: Optional[float] = None
    period: Optional[str] = None
    archive_metadata: Optional[Dict[str, Any]] = None

class ArchiveResponse(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    archive_type: str
    status: ArchiveStatusEnum
    montant: Optional[float] = None
    period: Optional[str] = None
    reference_id: Optional[str] = None
    archive_metadata: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime
    enterprise_id: str
    created_by: str
    
    class Config:
        from_attributes = True

class ArchiveSearch(BaseModel):
    query: Optional[str] = None
    archive_type: Optional[str] = None
    status: Optional[ArchiveStatusEnum] = None
    date_from: Optional[date] = None
    date_to: Optional[date] = None
    montant_min: Optional[float] = None
    montant_max: Optional[float] = None

# ========== EXPORT REQUESTS ==========

class ExportRequest(BaseModel):
    format: str = "excel"  # "excel", "pdf", "csv"
    filters: Optional[Dict[str, Any]] = None
    date_range: Optional[Dict[str, str]] = None

# ========== API RESPONSES ==========

class ApiResponse(BaseModel):
    success: bool = True
    message: Optional[str] = None
    data: Optional[Any] = None
    errors: Optional[List[str]] = None

class HealthResponse(BaseModel):
    status: str = "healthy"
    timestamp: datetime
    version: str = "2.0.0"
    database: str = "connected"
    services: Dict[str, str] = {}

# Forward references
UserResponse.model_rebuild()
AuthResponse.model_rebuild()