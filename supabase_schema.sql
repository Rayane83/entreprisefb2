-- ===================================
-- SCHEMA SUPABASE - PORTAIL ENTREPRISE FLASHBACK FA
-- ===================================

-- Extension pour les UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table des entreprises
CREATE TABLE IF NOT EXISTS enterprises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    guild_id VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table de configuration Discord
CREATE TABLE IF NOT EXISTS discord_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enterprise_id UUID REFERENCES enterprises(id) ON DELETE CASCADE,
    guild_id VARCHAR(50) NOT NULL,
    roles JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des profils utilisateurs (liée aux utilisateurs auth de Supabase)
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    discord_id VARCHAR(50),
    discord_username VARCHAR(100),
    current_role VARCHAR(50),
    enterprise_id UUID REFERENCES enterprises(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des configurations d'entreprise
CREATE TABLE IF NOT EXISTS company_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enterprise_id UUID REFERENCES enterprises(id) ON DELETE CASCADE,
    config_key VARCHAR(100) NOT NULL,
    config_value JSONB,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(enterprise_id, config_key)
);

-- Table des tranches d'impôts
CREATE TABLE IF NOT EXISTS tax_brackets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enterprise_id UUID REFERENCES enterprises(id) ON DELETE CASCADE,
    min_income DECIMAL(15,2) NOT NULL,
    max_income DECIMAL(15,2),
    tax_rate DECIMAL(5,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des tranches de patrimoine
CREATE TABLE IF NOT EXISTS wealth_brackets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enterprise_id UUID REFERENCES enterprises(id) ON DELETE CASCADE,
    min_wealth DECIMAL(15,2) NOT NULL,
    max_wealth DECIMAL(15,2),
    tax_rate DECIMAL(5,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des règles de grades
CREATE TABLE IF NOT EXISTS grade_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enterprise_id UUID REFERENCES enterprises(id) ON DELETE CASCADE,
    grade_name VARCHAR(100) NOT NULL,
    base_salary DECIMAL(12,2) NOT NULL,
    multiplier DECIMAL(4,2) DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des rapports de dotations
CREATE TABLE IF NOT EXISTS dotation_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enterprise_id UUID REFERENCES enterprises(id) ON DELETE CASCADE,
    report_name VARCHAR(255) NOT NULL,
    report_date DATE NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'draft',
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des lignes de dotations
CREATE TABLE IF NOT EXISTS dotation_rows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES dotation_reports(id) ON DELETE CASCADE,
    employee_name VARCHAR(255) NOT NULL,
    grade VARCHAR(100),
    base_salary DECIMAL(12,2) NOT NULL,
    multiplier DECIMAL(4,2) DEFAULT 1.0,
    total_amount DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des primes tiers d'entreprise
CREATE TABLE IF NOT EXISTS company_prime_tiers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enterprise_id UUID REFERENCES enterprises(id) ON DELETE CASCADE,
    tier_name VARCHAR(100) NOT NULL,
    tier_value DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des paramètres de blanchiment
CREATE TABLE IF NOT EXISTS blanchiment_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enterprise_id UUID REFERENCES enterprises(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT false,
    threshold_amount DECIMAL(15,2) DEFAULT 10000.00,
    monitoring_period_days INTEGER DEFAULT 30,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table globale de blanchiment
CREATE TABLE IF NOT EXISTS blanchiment_global (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enterprise_id UUID REFERENCES enterprises(id) ON DELETE CASCADE,
    data_content TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des lignes de blanchiment
CREATE TABLE IF NOT EXISTS blanchiment_rows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    global_id UUID REFERENCES blanchiment_global(id) ON DELETE CASCADE,
    transaction_date DATE,
    amount DECIMAL(15,2),
    description TEXT,
    flagged BOOLEAN DEFAULT false,
    risk_level VARCHAR(20) DEFAULT 'low',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des archives
CREATE TABLE IF NOT EXISTS archives (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enterprise_id UUID REFERENCES enterprises(id) ON DELETE CASCADE,
    archive_type VARCHAR(50) NOT NULL, -- 'dotation', 'blanchiment', 'tax', etc.
    title VARCHAR(255) NOT NULL,
    description TEXT,
    data_content JSONB,
    file_url TEXT,
    archived_by UUID REFERENCES auth.users(id),
    archived_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===================================
-- INDEXES pour optimiser les performances
-- ===================================

CREATE INDEX IF NOT EXISTS idx_enterprises_guild_id ON enterprises(guild_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_discord_id ON user_profiles(discord_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_enterprise_id ON user_profiles(enterprise_id);
CREATE INDEX IF NOT EXISTS idx_dotation_reports_enterprise_id ON dotation_reports(enterprise_id);
CREATE INDEX IF NOT EXISTS idx_dotation_reports_date ON dotation_reports(report_date);
CREATE INDEX IF NOT EXISTS idx_dotation_rows_report_id ON dotation_rows(report_id);
CREATE INDEX IF NOT EXISTS idx_blanchiment_global_enterprise_id ON blanchiment_global(enterprise_id);
CREATE INDEX IF NOT EXISTS idx_blanchiment_rows_global_id ON blanchiment_rows(global_id);
CREATE INDEX IF NOT EXISTS idx_archives_enterprise_id ON archives(enterprise_id);
CREATE INDEX IF NOT EXISTS idx_archives_type ON archives(archive_type);

-- ===================================
-- TRIGGERS pour updated_at automatique
-- ===================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Application des triggers sur toutes les tables avec updated_at
CREATE TRIGGER update_enterprises_updated_at BEFORE UPDATE ON enterprises FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_discord_config_updated_at BEFORE UPDATE ON discord_config FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_company_configs_updated_at BEFORE UPDATE ON company_configs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tax_brackets_updated_at BEFORE UPDATE ON tax_brackets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_wealth_brackets_updated_at BEFORE UPDATE ON wealth_brackets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_grade_rules_updated_at BEFORE UPDATE ON grade_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dotation_reports_updated_at BEFORE UPDATE ON dotation_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_company_prime_tiers_updated_at BEFORE UPDATE ON company_prime_tiers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_blanchiment_settings_updated_at BEFORE UPDATE ON blanchiment_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_blanchiment_global_updated_at BEFORE UPDATE ON blanchiment_global FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===================================
-- INSERTION DE DONNÉES PAR DÉFAUT
-- ===================================

-- Entreprise par défaut (LSPD)
INSERT INTO enterprises (name, guild_id) 
VALUES ('LSPD', '1404608015230832742')
ON CONFLICT (guild_id) DO NOTHING;

-- Configuration Discord par défaut
INSERT INTO discord_config (enterprise_id, guild_id, roles)
SELECT id, guild_id, '{
  "staff": {"name": "Staff", "color": "#3b82f6"},
  "patron": {"name": "Patron", "color": "#16a34a"},
  "co-patron": {"name": "Co-Patron", "color": "#eab308"},
  "dot": {"name": "DOT", "color": "#a855f7"},
  "employe": {"name": "Employé", "color": "#64748b"}
}'::jsonb
FROM enterprises WHERE guild_id = '1404608015230832742'
ON CONFLICT DO NOTHING;

-- Tranches d'impôts par défaut
INSERT INTO tax_brackets (enterprise_id, min_income, max_income, tax_rate)
SELECT e.id, 0, 50000, 10
FROM enterprises e WHERE e.guild_id = '1404608015230832742'
ON CONFLICT DO NOTHING;

INSERT INTO tax_brackets (enterprise_id, min_income, max_income, tax_rate)
SELECT e.id, 50001, 100000, 20
FROM enterprises e WHERE e.guild_id = '1404608015230832742'
ON CONFLICT DO NOTHING;

-- Grades par défaut
INSERT INTO grade_rules (enterprise_id, grade_name, base_salary, multiplier)
SELECT e.id, 'Cadet', 25000, 1.0
FROM enterprises e WHERE e.guild_id = '1404608015230832742'
ON CONFLICT DO NOTHING;

INSERT INTO grade_rules (enterprise_id, grade_name, base_salary, multiplier)
SELECT e.id, 'Officer', 35000, 1.2
FROM enterprises e WHERE e.guild_id = '1404608015230832742'
ON CONFLICT DO NOTHING;