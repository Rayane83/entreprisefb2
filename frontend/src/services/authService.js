import { supabase } from '../lib/supabase';

export const authService = {
  // Connexion Discord OAuth
  async signInWithDiscord() {
    try {
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'discord',
        options: {
          redirectTo: `${window.location.origin}`
        }
      });
      
      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur connexion Discord:', error);
      return { data: null, error };
    }
  },

  // Déconnexion
  async signOut() {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      return { error: null };
    } catch (error) {
      console.error('Erreur déconnexion:', error);
      return { error };
    }
  },

  // Récupérer session actuelle
  async getSession() {
    try {
      const { data: { session }, error } = await supabase.auth.getSession();
      if (error) throw error;
      return { session, error: null };
    } catch (error) {
      console.error('Erreur récupération session:', error);
      return { session: null, error };
    }
  },

  // Écouter changements d'auth
  onAuthStateChange(callback) {
    return supabase.auth.onAuthStateChange(callback);
  },

  // Récupérer les rôles Discord de l'utilisateur
  async getUserGuildRoles(guildId = '1404608015230832742') {
    try {
      const { data: session } = await this.getSession();
      if (!session.session?.user) {
        return { roles: [], userRole: null, entreprise: null, error: null };
      }

      const user = session.session.user;

      // Vérifier si l'utilisateur a des métadonnées Discord
      if (user.app_metadata?.provider === 'discord') {
        // Récupérer les rôles depuis les métadonnées Discord
        const discordData = user.user_metadata;
        const userId = user.id;

        try {
          // Appeler l'edge function pour récupérer les rôles Discord
          const { data: rolesData, error: rolesError } = await supabase.functions.invoke('get-discord-roles', {
            body: { 
              guildId, 
              discordUserId: discordData.provider_id || discordData.sub 
            }
          });

          if (rolesError) {
            console.warn('Edge function non disponible, utilisation des rôles par défaut:', rolesError);
            return this.getFallbackRoles(user);
          }

          // Analyser les rôles retournés
          const userRoles = rolesData.roles || [];
          const roleHierarchy = ['staff', 'patron', 'co-patron', 'dot', 'employe'];
          
          // Déterminer le rôle le plus élevé
          let userRole = 'employe';
          for (const role of roleHierarchy) {
            if (userRoles.some(r => r.name.toLowerCase().includes(role) || r.id === this.getRoleId(role))) {
              userRole = role;
              break;
            }
          }

          // Mettre à jour le profil utilisateur dans Supabase
          await this.updateUserProfile(userId, {
            discord_id: discordData.provider_id || discordData.sub,
            discord_username: discordData.full_name || discordData.name,
            current_role: userRole,
            enterprise_id: rolesData.enterpriseId
          });

          return {
            roles: userRoles,
            userRole,
            entreprise: rolesData.enterpriseName || 'LSPD',
            error: null
          };

        } catch (edgeFunctionError) {
          console.warn('Erreur edge function, utilisation des rôles par défaut:', edgeFunctionError);
          return this.getFallbackRoles(user);
        }
      } else {
        // Utilisateur non Discord, utiliser les rôles par défaut
        return this.getFallbackRoles(user);
      }

    } catch (error) {
      console.error('Erreur récupération rôles:', error);
      return { roles: [], userRole: null, entreprise: null, error };
    }
  },

  // Rôles de secours basés sur l'email (pour les tests)
  getFallbackRoles(user) {
    const mockRoles = {
      'staff': { name: 'Staff', color: '#3b82f6' },
      'patron': { name: 'Patron', color: '#16a34a' },
      'co-patron': { name: 'Co-Patron', color: '#eab308' },
      'dot': { name: 'DOT', color: '#a855f7' },
      'employe': { name: 'Employé', color: '#64748b' }
    };

    // Déterminer le rôle basé sur l'email
    let userRole = 'employe';
    const email = user.email?.toLowerCase() || '';
    
    if (email.includes('admin') || email.includes('staff')) userRole = 'staff';
    else if (email.includes('patron') && email.includes('co')) userRole = 'co-patron';
    else if (email.includes('patron')) userRole = 'patron';
    else if (email.includes('dot')) userRole = 'dot';

    return { 
      roles: [mockRoles[userRole]], 
      userRole,
      entreprise: 'LSPD',
      error: null 
    };
  },

  // Récupérer l'ID de rôle Discord par nom
  getRoleId(roleName) {
    const roleIds = {
      'staff': process.env.REACT_APP_DISCORD_STAFF_ROLE_ID || '',
      'patron': process.env.REACT_APP_DISCORD_PATRON_ROLE_ID || '',
      'co-patron': process.env.REACT_APP_DISCORD_CO_PATRON_ROLE_ID || '',
      'dot': process.env.REACT_APP_DISCORD_DOT_ROLE_ID || '',
      'employe': process.env.REACT_APP_DISCORD_EMPLOYE_ROLE_ID || ''
    };
    return roleIds[roleName];
  },

  // Mettre à jour le profil utilisateur
  async updateUserProfile(userId, profileData) {
    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .upsert({
          id: userId,
          ...profileData,
          updated_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Erreur mise à jour profil:', error);
      return { data: null, error };
    }
  }
};