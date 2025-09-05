/**
 * Nouveau service d'authentification pour remplacer Supabase
 * Utilise le backend FastAPI + MySQL + Discord OAuth
 */

import { authAPI } from './apiService';

class NewAuthService {
  constructor() {
    this.user = null;
    this.session = null;
    this.isAuthenticated = false;
    this.listeners = [];
  }

  // ========== AUTHENTIFICATION ==========

  async signInWithDiscord() {
    try {
      console.log('🚀 Lancement authentification Discord...');
      
      // Récupérer l'URL Discord OAuth
      const response = await authAPI.getDiscordAuthUrl();
      
      if (response.success && response.data.url) {
        console.log('🔄 Redirection vers Discord OAuth...');
        
        // Rediriger vers Discord
        window.location.href = response.data.url;
        
        return { error: null };
      } else {
        throw new Error('Impossible de générer l\'URL Discord OAuth');
      }
      
    } catch (error) {
      console.error('❌ Erreur lors de la connexion Discord:', error);
      return { error };
    }
  }

  async handleDiscordCallback(code, state = null) {
    try {
      console.log('🔐 Traitement du callback Discord...');
      
      const response = await authAPI.handleDiscordCallback(code, state);
      
      if (response && response.tokens && response.user) {
        console.log('✅ Authentification Discord réussie');
        
        // Mettre à jour l'état local
        this.user = response.user;
        this.session = { user: response.user };
        this.isAuthenticated = true;
        
        // Notifier les listeners
        this.notifyListeners('SIGNED_IN', this.session);
        
        return { user: response.user, session: this.session, error: null };
      } else {
        throw new Error('Réponse d\'authentification invalide');
      }
      
    } catch (error) {
      console.error('❌ Erreur lors du traitement du callback Discord:', error);
      return { error };
    }
  }

  async signOut() {
    try {
      console.log('🚪 Déconnexion...');
      
      // Déconnexion côté serveur
      await authAPI.logout();
      
      // Nettoyer l'état local
      this.user = null;
      this.session = null;
      this.isAuthenticated = false;
      
      // Notifier les listeners
      this.notifyListeners('SIGNED_OUT', null);
      
      console.log('✅ Déconnexion réussie');
      
    } catch (error) {
      console.error('❌ Erreur lors de la déconnexion:', error);
      
      // Nettoyer quand même côté client
      this.user = null;
      this.session = null;
      this.isAuthenticated = false;
      
      this.notifyListeners('SIGNED_OUT', null);
    }
  }

  async getSession() {
    try {
      // Vérifier si on a un token valide
      const tokenCheck = await authAPI.checkToken();
      
      if (tokenCheck && tokenCheck.success) {
        // Récupérer les données utilisateur
        const userData = await authAPI.getCurrentUser();
        
        if (userData) {
          this.user = userData;
          this.session = { user: userData };
          this.isAuthenticated = true;
          
          return { session: this.session, error: null };
        }
      }
      
      // Pas de session valide
      this.user = null;
      this.session = null;
      this.isAuthenticated = false;
      
      return { session: null, error: null };
      
    } catch (error) {
      console.error('❌ Erreur lors de la récupération de la session:', error);
      
      // En cas d'erreur, considérer comme non authentifié
      this.user = null;
      this.session = null;
      this.isAuthenticated = false;
      
      return { session: null, error };
    }
  }

  async refreshSession() {
    try {
      console.log('🔄 Rafraîchissement de la session...');
      
      await authAPI.refreshToken();
      
      // Récupérer les nouvelles données utilisateur
      const userData = await authAPI.getCurrentUser();
      
      if (userData) {
        this.user = userData;
        this.session = { user: userData };
        this.isAuthenticated = true;
        
        this.notifyListeners('TOKEN_REFRESHED', this.session);
        
        return { session: this.session, error: null };
      }
      
      throw new Error('Impossible de récupérer les données utilisateur après refresh');
      
    } catch (error) {
      console.error('❌ Erreur lors du rafraîchissement:', error);
      
      // En cas d'échec, déconnecter l'utilisateur
      await this.signOut();
      
      return { session: null, error };
    }
  }

  // ========== GESTION DES RÔLES DISCORD ==========

  async getUserGuildRoles() {
    try {
      // Cette logique sera implémentée côté backend
      // Pour l'instant, on retourne les données du profil utilisateur
      if (this.user) {
        return {
          userRole: this.user.role || 'employe',
          entreprise: this.user.enterprise_id || 'Flashback Fa',
          error: null
        };
      }
      
      return {
        userRole: 'employe',
        entreprise: 'Flashback Fa',
        error: 'Utilisateur non connecté'
      };
      
    } catch (error) {
      console.error('❌ Erreur lors de la récupération des rôles:', error);
      return {
        userRole: 'employe',
        entreprise: 'Flashback Fa',
        error
      };
    }
  }

  // ========== LISTENERS ==========

  onAuthStateChange(callback) {
    const listener = { callback };
    this.listeners.push(listener);
    
    // Retourner un objet avec unsubscribe pour compatibilité
    return {
      data: {
        subscription: {
          unsubscribe: () => {
            const index = this.listeners.indexOf(listener);
            if (index > -1) {
              this.listeners.splice(index, 1);
            }
          }
        }
      }
    };
  }

  notifyListeners(event, session) {
    this.listeners.forEach(listener => {
      try {
        listener.callback(event, session);
      } catch (error) {
        console.error('❌ Erreur dans listener auth:', error);
      }
    });
  }

  // ========== UTILITAIRES ==========

  getCurrentUser() {
    return this.user;
  }

  isUserAuthenticated() {
    return this.isAuthenticated && this.user && localStorage.getItem('auth_token');
  }

  // Méthode pour vérifier si on est en mode mock (compatibilité)
  isMockMode() {
    return process.env.REACT_APP_USE_MOCK_AUTH === 'true' && 
           process.env.REACT_APP_FORCE_DISCORD_AUTH !== 'true';
  }
}

// Instance singleton
const newAuthService = new NewAuthService();

export default newAuthService;