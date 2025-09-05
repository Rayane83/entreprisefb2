from sqlalchemy import (
    Column, String, Integer, Float, DateTime, Boolean, Text, 
    ForeignKey, JSON, Enum, BigInteger, Date, Time
)
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime, timezone
import uuid
import enum

Base = declarative_base()

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

class BlanchimentStatus(enum.Enum):
    EN_COURS = "En cours"
    TERMINE = "Terminé"
    SUSPENDU = "Suspendu"
    ANNULE = "Annulé"

class DocumentType(enum.Enum):
    FACTURE = "Facture"
    DIPLOME = "Diplôme"
    CONTRAT = "Contrat"
    RAPPORT = "Rapport"
    DOCUMENT = "Document"

# ========== AUTHENTIFICATION & UTILISATEURS ==========

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
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relations
    enterprise = relationship("Enterprise", back_populates="users")
    dotation_reports = relationship("DotationReport", back_populates="created_by_user")
    tax_declarations = relationship("TaxDeclaration", back_populates="user")
    documents = relationship("Document", back_populates="uploaded_by_user")
    blanchiment_operations = relationship("BlanchimentOperation", back_populates="created_by_user")
    archives = relationship("Archive", back_populates="created_by_user")
    audit_logs = relationship("AuditLog", back_populates="user")

class Enterprise(Base):
    __tablename__ = "enterprises"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), nullable=False, unique=True)
    discord_guild_id = Column(String(20), unique=True, nullable=False)
    main_guild_role_id = Column(String(20), nullable=True)
    staff_role_id = Column(String(20), nullable=True)
    patron_role_id = Column(String(20), nullable=True)
    co_patron_role_id = Column(String(20), nullable=True)
    dot_role_id = Column(String(20), nullable=True)
    member_role_id = Column(String(20), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relations
    users = relationship("User", back_populates="enterprise")
    dotation_reports = relationship("DotationReport", back_populates="enterprise")
    tax_declarations = relationship("TaxDeclaration", back_populates="enterprise")
    documents = relationship("Document", back_populates="enterprise")
    blanchiment_settings = relationship("BlanchimentSetting", back_populates="enterprise")
    blanchiment_operations = relationship("BlanchimentOperation", back_populates="enterprise")
    archives = relationship("Archive", back_populates="enterprise")

# ========== DOTATIONS ==========

class DotationReport(Base):
    __tablename__ = "dotation_reports"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"), nullable=False)
    created_by = Column(String(36), ForeignKey("users.id"), nullable=False)
    title = Column(String(200), nullable=False)
    period = Column(String(50), nullable=True)  # "2024-Q1", "Janvier 2024", etc.
    status = Column(Enum(ArchiveStatus), default=ArchiveStatus.EN_ATTENTE)
    total_ca = Column(Float, default=0.0)
    total_salaires = Column(Float, default=0.0)
    total_primes = Column(Float, default=0.0)
    total_employees = Column(Integer, default=0)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relations
    enterprise = relationship("Enterprise", back_populates="dotation_reports")
    created_by_user = relationship("User", back_populates="dotation_reports")
    rows = relationship("DotationRow", back_populates="report", cascade="all, delete-orphan")

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
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    # Relations
    report = relationship("DotationReport", back_populates="rows")

# ========== IMPÔTS ==========

class TaxBracket(Base):
    __tablename__ = "tax_brackets"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    bracket_type = Column(String(20), nullable=False)  # "revenus" ou "patrimoine"
    min_amount = Column(Float, nullable=False)
    max_amount = Column(Float, nullable=True)  # NULL pour la dernière tranche
    tax_rate = Column(Float, nullable=False)  # Taux en décimal (0.10 pour 10%)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
class TaxDeclaration(Base):
    __tablename__ = "tax_declarations"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"), nullable=False)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    period = Column(String(50), nullable=False)  # "2024-Q1"
    revenus_totaux = Column(Float, default=0.0)
    revenus_imposables = Column(Float, default=0.0)
    abattements = Column(Float, default=0.0)
    patrimoine = Column(Float, default=0.0)
    impot_revenus = Column(Float, default=0.0)
    impot_patrimoine = Column(Float, default=0.0)
    impot_total = Column(Float, default=0.0)
    status = Column(Enum(ArchiveStatus), default=ArchiveStatus.EN_ATTENTE)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relations
    enterprise = relationship("Enterprise", back_populates="tax_declarations")
    user = relationship("User", back_populates="tax_declarations")

# ========== DOCUMENTS (FACTURES/DIPLÔMES) ==========

class Document(Base):
    __tablename__ = "documents"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"), nullable=False)
    uploaded_by = Column(String(36), ForeignKey("users.id"), nullable=False)
    filename = Column(String(255), nullable=False)
    original_filename = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    file_size = Column(BigInteger, nullable=False)
    mime_type = Column(String(100), nullable=False)
    document_type = Column(Enum(DocumentType), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    # Relations
    enterprise = relationship("Enterprise", back_populates="documents")
    uploaded_by_user = relationship("User", back_populates="documents")

# ========== BLANCHIMENT ==========

class BlanchimentSetting(Base):
    __tablename__ = "blanchiment_settings"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"), nullable=False)
    is_enabled = Column(Boolean, default=True)
    use_global_settings = Column(Boolean, default=True)
    perc_entreprise = Column(Float, default=15.0)
    perc_groupe = Column(Float, default=5.0)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relations
    enterprise = relationship("Enterprise", back_populates="blanchiment_settings")

class BlanchimentOperation(Base):
    __tablename__ = "blanchiment_operations"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"), nullable=False)
    created_by = Column(String(36), ForeignKey("users.id"), nullable=False)
    status = Column(Enum(BlanchimentStatus), default=BlanchimentStatus.EN_COURS)
    date_recu = Column(Date, nullable=True)
    date_rendu = Column(Date, nullable=True)
    duree_jours = Column(Integer, nullable=True)
    groupe = Column(String(50), nullable=False)
    employe = Column(String(100), nullable=False)
    donneur_id = Column(String(50), nullable=True)
    recepteur_id = Column(String(50), nullable=True)
    somme = Column(Float, nullable=False)
    entreprise_perc = Column(Float, nullable=False)
    groupe_perc = Column(Float, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relations
    enterprise = relationship("Enterprise", back_populates="blanchiment_operations")
    created_by_user = relationship("User", back_populates="blanchiment_operations")

# ========== ARCHIVES ==========

class Archive(Base):
    __tablename__ = "archives"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    enterprise_id = Column(String(36), ForeignKey("enterprises.id"), nullable=False)
    created_by = Column(String(36), ForeignKey("users.id"), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    archive_type = Column(String(50), nullable=False)  # "Dotation", "Impot", "Blanchiment", etc.
    status = Column(Enum(ArchiveStatus), default=ArchiveStatus.EN_ATTENTE)
    montant = Column(Float, nullable=True)
    period = Column(String(50), nullable=True)
    reference_id = Column(String(36), nullable=True)  # ID de l'objet source
    metadata = Column(JSON, nullable=True)  # Données additionnelles JSON
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relations
    enterprise = relationship("Enterprise", back_populates="archives")
    created_by_user = relationship("User", back_populates="archives")

# ========== CONFIGURATION ==========

class GradeRule(Base):
    __tablename__ = "grade_rules"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    grade_name = Column(String(50), nullable=False, unique=True)
    salaire_base = Column(Float, default=0.0)
    prime_base = Column(Float, default=0.0)
    ca_multiplier = Column(Float, default=0.35)  # 35% du CA par défaut
    prime_multiplier = Column(Float, default=0.08)  # 8% du CA par défaut
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

# ========== AUDIT & LOGS ==========

class AuditLog(Base):
    __tablename__ = "audit_logs"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    action = Column(String(100), nullable=False)  # "CREATE", "UPDATE", "DELETE", "LOGIN", etc.
    table_name = Column(String(50), nullable=True)
    record_id = Column(String(36), nullable=True)
    old_values = Column(JSON, nullable=True)
    new_values = Column(JSON, nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    # Relations
    user = relationship("User", back_populates="audit_logs")

# ========== CONFIGURATION DISCORD ==========

class DiscordConfig(Base):
    __tablename__ = "discord_configs"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    guild_id = Column(String(20), unique=True, nullable=False)
    guild_name = Column(String(100), nullable=False)
    client_id = Column(String(50), nullable=True)
    webhook_url = Column(String(500), nullable=True)
    sync_enabled = Column(Boolean, default=True)
    last_sync = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))