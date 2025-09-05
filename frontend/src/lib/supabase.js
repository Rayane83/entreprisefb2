import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Variables d\'environnement Supabase manquantes. Vérifiez REACT_APP_SUPABASE_URL et REACT_APP_SUPABASE_ANON_KEY');
}

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    storage: localStorage,
  },
});

// Configuration des tables
export const TABLES = {
  ARCHIVES: 'archives',
  BLANCHIMENT_GLOBAL: 'blanchiment_global', 
  BLANCHIMENT_ROWS: 'blanchiment_rows',
  BLANCHIMENT_SETTINGS: 'blanchiment_settings',
  COMPANY_CONFIGS: 'company_configs',
  COMPANY_PRIME_TIERS: 'company_prime_tiers',
  DISCORD_CONFIG: 'discord_config',
  DOTATION_REPORTS: 'dotation_reports',
  DOTATION_ROWS: 'dotation_rows',
  ENTERPRISES: 'enterprises',
  GRADE_RULES: 'grade_rules',
  TAX_BRACKETS: 'tax_brackets',
  WEALTH_BRACKETS: 'wealth_brackets'
};