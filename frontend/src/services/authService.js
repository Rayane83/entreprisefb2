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
        return { roles: [], error: null };
      }

      // Simuler les rôles pour le moment (à remplacer par l'edge function)
      const mockRoles = {
        'staff': { name: 'Staff', color: '#3b82f6' },
        'patron': { name: 'Patron', color: '#16a34a' },
        'co-patron': { name: 'Co-Patron', color: '#eab308' },
        'dot': { name: 'DOT', color: '#a855f7' },
        'employe': { name: 'Employé', color: '#64748b' }
      };

      // Pour la démo, retourner un rôle basé sur l'email
      const user = session.session.user;
      let userRole = 'employe';
      
      if (user.email?.includes('admin')) userRole = 'staff';
      else if (user.email?.includes('patron')) userRole = 'patron';
      else if (user.email?.includes('co-patron')) userRole = 'co-patron';
      else if (user.email?.includes('dot')) userRole = 'dot';

      return { 
        roles: [mockRoles[userRole]], 
        userRole,
        entreprise: 'LSPD',
        error: null 
      };
    } catch (error) {
      console.error('Erreur récupération rôles:', error);
      return { roles: [], error };
    }
  }
};