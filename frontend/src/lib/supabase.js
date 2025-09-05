import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL || 'https://pmhktnxqponixycsjcwr.supabase.co';
const supabaseKey = process.env.REACT_APP_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBtaGt0bnhxcG9uaXh5Y3NqY3dyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ5Njg0MzcsImV4cCI6MjA1MDU0NDQzN30.2nq0zxe9f4vWXNXv0pnUL9tkEJU-DKWrNIE8Vc7J4gQ';

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