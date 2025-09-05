import { supabase } from '../lib/supabase';

/**
 * Service pour gérer les opérations Supabase
 */

// ===================================
// SERVICES D'ENTREPRISE
// ===================================

export const enterpriseService = {
  // Récupérer l'entreprise par Guild ID
  async getEnterpriseByGuildId(guildId) {
    try {
      const { data, error } = await supabase
        .from('enterprises')
        .select('*')
        .eq('guild_id', guildId)
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur récupération entreprise:', error);
      return { data: null, error };
    }
  },

  // Créer une nouvelle entreprise
  async createEnterprise(enterpriseData) {
    try {
      const { data, error } = await supabase
        .from('enterprises')
        .insert([enterpriseData])
        .select()
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur création entreprise:', error);
      return { data: null, error };
    }
  }
};

// ===================================
// SERVICES UTILISATEUR
// ===================================

export const userService = {
  // Créer ou mettre à jour le profil utilisateur
  async upsertUserProfile(userId, profileData) {
    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .upsert({
          id: userId,
          ...profileData
        })
        .select()
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur profil utilisateur:', error);
      return { data: null, error };
    }
  },

  // Récupérer le profil utilisateur
  async getUserProfile(userId) {
    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .select(`
          *,
          enterprises (
            id,
            name,
            guild_id
          )
        `)
        .eq('id', userId)
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur récupération profil:', error);
      return { data: null, error };
    }
  }
};

// ===================================
// SERVICES DOTATIONS
// ===================================

export const dotationService = {
  // Créer un rapport de dotation
  async createDotationReport(reportData) {
    try {
      const { data, error } = await supabase
        .from('dotation_reports')
        .insert([reportData])
        .select()
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur création rapport dotation:', error);
      return { data: null, error };
    }
  },

  // Récupérer les rapports de dotation
  async getDotationReports(enterpriseId, limit = 10) {
    try {
      const { data, error } = await supabase
        .from('dotation_reports')
        .select(`
          *,
          dotation_rows (*)
        `)
        .eq('enterprise_id', enterpriseId)
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur récupération rapports dotation:', error);
      return { data: null, error };
    }
  },

  // Ajouter des lignes de dotation
  async addDotationRows(reportId, rows) {
    try {
      const rowsWithReportId = rows.map(row => ({
        ...row,
        report_id: reportId
      }));

      const { data, error } = await supabase
        .from('dotation_rows')
        .insert(rowsWithReportId)
        .select();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur ajout lignes dotation:', error);
      return { data: null, error };
    }
  }
};

// ===================================
// SERVICES BLANCHIMENT
// ===================================

export const blanchimentService = {
  // Récupérer les paramètres de blanchiment
  async getBlanchimentSettings(enterpriseId) {
    try {
      const { data, error } = await supabase
        .from('blanchiment_settings')
        .select('*')
        .eq('enterprise_id', enterpriseId)
        .single();

      if (error && error.code !== 'PGRST116') throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur récupération paramètres blanchiment:', error);
      return { data: null, error };
    }
  },

  // Mettre à jour les paramètres de blanchiment
  async updateBlanchimentSettings(enterpriseId, settings) {
    try {
      const { data, error } = await supabase
        .from('blanchiment_settings')
        .upsert({
          enterprise_id: enterpriseId,
          ...settings
        })
        .select()
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur mise à jour paramètres blanchiment:', error);
      return { data: null, error };
    }
  },

  // Créer des données de blanchiment globales
  async createBlanchimentGlobal(enterpriseId, dataContent, createdBy) {
    try {
      const { data, error } = await supabase
        .from('blanchiment_global')
        .insert([{
          enterprise_id: enterpriseId,
          data_content: dataContent,
          created_by: createdBy
        }])
        .select()
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur création blanchiment global:', error);
      return { data: null, error };
    }
  },

  // Ajouter des lignes de blanchiment
  async addBlanchimentRows(globalId, rows) {
    try {
      const rowsWithGlobalId = rows.map(row => ({
        ...row,
        global_id: globalId
      }));

      const { data, error } = await supabase
        .from('blanchiment_rows')
        .insert(rowsWithGlobalId)
        .select();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur ajout lignes blanchiment:', error);
      return { data: null, error };
    }
  },

  // Récupérer les données de blanchiment
  async getBlanchimentData(enterpriseId) {
    try {
      const { data, error } = await supabase
        .from('blanchiment_global')
        .select(`
          *,
          blanchiment_rows (*)
        `)
        .eq('enterprise_id', enterpriseId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur récupération données blanchiment:', error);
      return { data: null, error };
    }
  }
};

// ===================================
// SERVICES ARCHIVES
// ===================================

export const archiveService = {
  // Créer une archive
  async createArchive(archiveData) {
    try {
      const { data, error } = await supabase
        .from('archives')
        .insert([archiveData])
        .select()
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur création archive:', error);
      return { data: null, error };
    }
  },

  // Récupérer les archives
  async getArchives(enterpriseId, archiveType = null) {
    try {
      let query = supabase
        .from('archives')
        .select('*')
        .eq('enterprise_id', enterpriseId)
        .order('archived_at', { ascending: false });

      if (archiveType) {
        query = query.eq('archive_type', archiveType);
      }

      const { data, error } = await query;

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur récupération archives:', error);
      return { data: null, error };
    }
  },

  // Mettre à jour une archive
  async updateArchive(archiveId, updates) {
    try {
      const { data, error } = await supabase
        .from('archives')
        .update(updates)
        .eq('id', archiveId)
        .select()
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur mise à jour archive:', error);
      return { data: null, error };
    }
  },

  // Supprimer une archive
  async deleteArchive(archiveId) {
    try {
      const { error } = await supabase
        .from('archives')
        .delete()
        .eq('id', archiveId);

      if (error) throw error;
      return { error: null };
    } catch (error) {
      console.error('Erreur suppression archive:', error);
      return { error };
    }
  }
};

// ===================================
// SERVICES CONFIGURATION
// ===================================

export const configService = {
  // Récupérer les configurations d'entreprise
  async getCompanyConfigs(enterpriseId) {
    try {
      const { data, error } = await supabase
        .from('company_configs')
        .select('*')
        .eq('enterprise_id', enterpriseId);

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur récupération configurations:', error);
      return { data: null, error };
    }
  },

  // Mettre à jour une configuration
  async updateConfig(enterpriseId, configKey, configValue, createdBy) {
    try {
      const { data, error } = await supabase
        .from('company_configs')
        .upsert({
          enterprise_id: enterpriseId,
          config_key: configKey,
          config_value: configValue,
          created_by: createdBy
        })
        .select()
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur mise à jour configuration:', error);
      return { data: null, error };
    }
  },

  // Récupérer les règles de grades
  async getGradeRules(enterpriseId) {
    try {
      const { data, error } = await supabase
        .from('grade_rules')
        .select('*')
        .eq('enterprise_id', enterpriseId)
        .order('grade_name');

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur récupération règles grades:', error);
      return { data: null, error };
    }
  },

  // Mettre à jour les règles de grades
  async updateGradeRules(enterpriseId, gradeRules) {
    try {
      // Supprimer les anciennes règles
      await supabase
        .from('grade_rules')
        .delete()
        .eq('enterprise_id', enterpriseId);

      // Ajouter les nouvelles règles
      const rulesWithEnterpriseId = gradeRules.map(rule => ({
        ...rule,
        enterprise_id: enterpriseId
      }));

      const { data, error } = await supabase
        .from('grade_rules')
        .insert(rulesWithEnterpriseId)
        .select();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur mise à jour règles grades:', error);
      return { data: null, error };
    }
  }
};

// Export par défaut
export default {
  enterpriseService,
  userService,
  dotationService,
  blanchimentService,
  archiveService,
  configService
};