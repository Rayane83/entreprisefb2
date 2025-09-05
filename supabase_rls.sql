-- ===================================
-- POLITIQUES RLS - PORTAIL ENTREPRISE FLASHBACK FA
-- ===================================

-- Activer RLS sur toutes les tables
ALTER TABLE enterprises ENABLE row level security;
ALTER TABLE discord_config ENABLE row level security;
ALTER TABLE user_profiles ENABLE row level security;
ALTER TABLE company_configs ENABLE row level security;
ALTER TABLE tax_brackets ENABLE row level security;
ALTER TABLE wealth_brackets ENABLE row level security;
ALTER TABLE grade_rules ENABLE row level security;
ALTER TABLE dotation_reports ENABLE row level security;
ALTER TABLE dotation_rows ENABLE row level security;
ALTER TABLE company_prime_tiers ENABLE row level security;
ALTER TABLE blanchiment_settings ENABLE row level security;
ALTER TABLE blanchiment_global ENABLE row level security;
ALTER TABLE blanchiment_rows ENABLE row level security;
ALTER TABLE archives ENABLE row level security;

-- ===================================
-- FONCTIONS HELPER POUR LES RÔLES
-- ===================================

-- Fonction pour récupérer l'enterprise_id de l'utilisateur connecté
CREATE OR REPLACE FUNCTION get_user_enterprise_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT enterprise_id 
        FROM user_profiles 
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier le rôle de l'utilisateur connecté
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS VARCHAR AS $$
BEGIN
    RETURN (
        SELECT current_role 
        FROM user_profiles 
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier si l'utilisateur est staff
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN get_user_role() = 'staff';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier si l'utilisateur est patron ou co-patron
CREATE OR REPLACE FUNCTION is_patron_level()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN get_user_role() IN ('patron', 'co-patron');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================
-- POLITIQUES ENTERPRISES
-- ===================================

-- Lecture pour tous les utilisateurs authentifiés de la même entreprise
CREATE POLICY "enterprises_select_policy" ON enterprises
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    id = get_user_enterprise_id()
);

-- Mise à jour uniquement pour staff
CREATE POLICY "enterprises_update_policy" ON enterprises
FOR UPDATE USING (
    is_staff() AND 
    id = get_user_enterprise_id()
);

-- ===================================
-- POLITIQUES USER_PROFILES
-- ===================================

-- Lecture de son propre profil ou tous les profils pour staff
CREATE POLICY "user_profiles_select_policy" ON user_profiles
FOR SELECT USING (
    auth.role() = 'authenticated' AND (
        id = auth.uid() OR 
        is_staff()
    )
);

-- Mise à jour de son propre profil ou tous pour staff
CREATE POLICY "user_profiles_update_policy" ON user_profiles
FOR UPDATE USING (
    auth.role() = 'authenticated' AND (
        id = auth.uid() OR 
        is_staff()
    )
);

-- Insertion pour nouveaux utilisateurs
CREATE POLICY "user_profiles_insert_policy" ON user_profiles
FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND 
    id = auth.uid()
);

-- ===================================
-- POLITIQUES COMPANY_CONFIGS
-- ===================================

-- Lecture pour tous de la même entreprise
CREATE POLICY "company_configs_select_policy" ON company_configs
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id()
);

-- Modification uniquement pour patron niveau et plus
CREATE POLICY "company_configs_modify_policy" ON company_configs
FOR ALL USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id() AND
    (is_staff() OR is_patron_level())
);

-- ===================================
-- POLITIQUES TAX_BRACKETS & WEALTH_BRACKETS
-- ===================================

-- Lecture pour tous de la même entreprise
CREATE POLICY "tax_brackets_select_policy" ON tax_brackets
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id()
);

CREATE POLICY "wealth_brackets_select_policy" ON wealth_brackets
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id()
);

-- Modification uniquement pour staff
CREATE POLICY "tax_brackets_modify_policy" ON tax_brackets
FOR ALL USING (
    is_staff() AND 
    enterprise_id = get_user_enterprise_id()
);

CREATE POLICY "wealth_brackets_modify_policy" ON wealth_brackets
FOR ALL USING (
    is_staff() AND 
    enterprise_id = get_user_enterprise_id()
);

-- ===================================
-- POLITIQUES GRADE_RULES
-- ===================================

-- Lecture pour tous de la même entreprise
CREATE POLICY "grade_rules_select_policy" ON grade_rules
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id()
);

-- Modification uniquement pour staff et patrons
CREATE POLICY "grade_rules_modify_policy" ON grade_rules
FOR ALL USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id() AND
    (is_staff() OR is_patron_level())
);

-- ===================================
-- POLITIQUES DOTATION_REPORTS & DOTATION_ROWS
-- ===================================

-- Lecture pour tous de la même entreprise
CREATE POLICY "dotation_reports_select_policy" ON dotation_reports
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id()
);

CREATE POLICY "dotation_rows_select_policy" ON dotation_rows
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    EXISTS (
        SELECT 1 FROM dotation_reports dr 
        WHERE dr.id = report_id 
        AND dr.enterprise_id = get_user_enterprise_id()
    )
);

-- Modification pour staff, patrons et DOT
CREATE POLICY "dotation_reports_modify_policy" ON dotation_reports
FOR ALL USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id() AND
    get_user_role() IN ('staff', 'patron', 'co-patron', 'dot')
);

CREATE POLICY "dotation_rows_modify_policy" ON dotation_rows
FOR ALL USING (
    auth.role() = 'authenticated' AND 
    EXISTS (
        SELECT 1 FROM dotation_reports dr 
        WHERE dr.id = report_id 
        AND dr.enterprise_id = get_user_enterprise_id()
        AND get_user_role() IN ('staff', 'patron', 'co-patron', 'dot')
    )
);

-- ===================================
-- POLITIQUES BLANCHIMENT
-- ===================================

-- Settings: lecture pour tous, modification pour staff seulement
CREATE POLICY "blanchiment_settings_select_policy" ON blanchiment_settings
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id()
);

CREATE POLICY "blanchiment_settings_modify_policy" ON blanchiment_settings
FOR ALL USING (
    is_staff() AND 
    enterprise_id = get_user_enterprise_id()
);

-- Global: lecture pour tous, modification pour staff
CREATE POLICY "blanchiment_global_select_policy" ON blanchiment_global
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id()
);

CREATE POLICY "blanchiment_global_modify_policy" ON blanchiment_global
FOR ALL USING (
    is_staff() AND 
    enterprise_id = get_user_enterprise_id()
);

-- Rows: lecture pour tous de la même entreprise
CREATE POLICY "blanchiment_rows_select_policy" ON blanchiment_rows
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    EXISTS (
        SELECT 1 FROM blanchiment_global bg 
        WHERE bg.id = global_id 
        AND bg.enterprise_id = get_user_enterprise_id()
    )
);

CREATE POLICY "blanchiment_rows_modify_policy" ON blanchiment_rows
FOR ALL USING (
    is_staff() AND 
    EXISTS (
        SELECT 1 FROM blanchiment_global bg 
        WHERE bg.id = global_id 
        AND bg.enterprise_id = get_user_enterprise_id()
    )
);

-- ===================================
-- POLITIQUES ARCHIVES
-- ===================================

-- Lecture pour tous de la même entreprise
CREATE POLICY "archives_select_policy" ON archives
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id()
);

-- Création d'archives pour staff et patrons
CREATE POLICY "archives_insert_policy" ON archives
FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id() AND
    (is_staff() OR is_patron_level())
);

-- Suppression uniquement pour staff
CREATE POLICY "archives_delete_policy" ON archives
FOR DELETE USING (
    is_staff() AND 
    enterprise_id = get_user_enterprise_id()
);

-- ===================================
-- POLITIQUES COMPANY_PRIME_TIERS
-- ===================================

-- Lecture pour tous de la même entreprise
CREATE POLICY "company_prime_tiers_select_policy" ON company_prime_tiers
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id()
);

-- Modification pour staff et patrons
CREATE POLICY "company_prime_tiers_modify_policy" ON company_prime_tiers
FOR ALL USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id() AND
    (is_staff() OR is_patron_level())
);

-- ===================================
-- POLITIQUES DISCORD_CONFIG
-- ===================================

-- Lecture pour tous de la même entreprise
CREATE POLICY "discord_config_select_policy" ON discord_config
FOR SELECT USING (
    auth.role() = 'authenticated' AND 
    enterprise_id = get_user_enterprise_id()
);

-- Modification uniquement pour staff
CREATE POLICY "discord_config_modify_policy" ON discord_config
FOR ALL USING (
    is_staff() AND 
    enterprise_id = get_user_enterprise_id()
);