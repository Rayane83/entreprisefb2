/**
 * Service API pour remplacer Supabase
 * Gère toutes les communications avec le backend FastAPI + MySQL
 */

const API_BASE_URL = process.env.REACT_APP_BACKEND_URL || 'http://localhost:8001';

// Configuration de base pour les requêtes
const API_CONFIG = {
  headers: {
    'Content-Type': 'application/json',
  },
};

// Gestion du token d'authentification
let authToken = null;

export const setAuthToken = (token) => {
  authToken = token;
  if (token) {
    API_CONFIG.headers['Authorization'] = `Bearer ${token}`;
  } else {
    delete API_CONFIG.headers['Authorization'];
  }
};

// Récupérer le token du localStorage au démarrage
const savedToken = localStorage.getItem('auth_token');
if (savedToken) {
  setAuthToken(savedToken);
}

// Fonction générique pour les requêtes API
const apiRequest = async (endpoint, options = {}) => {
  const url = `${API_BASE_URL}${endpoint}`;
  
  const config = {
    ...API_CONFIG,
    ...options,
    headers: {
      ...API_CONFIG.headers,
      ...(options.headers || {}),
    },
  };

  try {
    console.log(`🔔 API Request: ${options.method || 'GET'} ${url}`);
    
    const response = await fetch(url, config);
    
    // Gestion des erreurs HTTP
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      
      // Token expiré ou invalide
      if (response.status === 401) {
        console.warn('🔐 Token expiré, déconnexion automatique');
        localStorage.removeItem('auth_token');
        localStorage.removeItem('refresh_token');
        setAuthToken(null);
        // Rediriger vers la page de connexion si nécessaire
        window.location.href = '/';
        return null;
      }
      
      throw new Error(errorData.detail || errorData.message || `HTTP ${response.status}`);
    }

    const data = await response.json();
    console.log(`✅ API Response: ${options.method || 'GET'} ${url} - Success`);
    
    return data;
    
  } catch (error) {
    console.error(`❌ API Error: ${options.method || 'GET'} ${url}:`, error);
    throw error;
  }
};

// ========== AUTHENTIFICATION ==========

export const authAPI = {
  // Obtenir l'URL de connexion Discord
  getDiscordAuthUrl: async () => {
    return await apiRequest('/auth/discord-url');
  },

  // Traiter le callback Discord
  handleDiscordCallback: async (code, state = null) => {
    const response = await apiRequest('/auth/discord/callback', {
      method: 'POST',
      body: JSON.stringify({ code, state }),
    });
    
    if (response && response.tokens) {
      // Sauvegarder les tokens
      localStorage.setItem('auth_token', response.tokens.access_token);
      localStorage.setItem('refresh_token', response.tokens.refresh_token);
      setAuthToken(response.tokens.access_token);
      
      return response;
    }
    
    throw new Error('Authentification échouée');
  },

  // Rafraîchir le token
  refreshToken: async () => {
    const refreshToken = localStorage.getItem('refresh_token');
    if (!refreshToken) {
      throw new Error('Aucun refresh token disponible');
    }

    const response = await apiRequest('/auth/refresh', {
      method: 'POST',
      body: JSON.stringify({ refresh_token: refreshToken }),
    });

    if (response) {
      localStorage.setItem('auth_token', response.access_token);
      localStorage.setItem('refresh_token', response.refresh_token);
      setAuthToken(response.access_token);
      return response;
    }

    throw new Error('Rafraîchissement du token échoué');
  },

  // Déconnexion
  logout: async () => {
    try {
      await apiRequest('/auth/logout', { method: 'POST' });
    } catch (error) {
      console.warn('Erreur lors de la déconnexion côté serveur:', error);
    } finally {
      // Nettoyer côté client
      localStorage.removeItem('auth_token');
      localStorage.removeItem('refresh_token');
      setAuthToken(null);
    }
  },

  // Récupérer le profil utilisateur actuel
  getCurrentUser: async () => {
    return await apiRequest('/auth/me');
  },

  // Vérifier si le token est valide
  checkToken: async () => {
    return await apiRequest('/auth/check');
  },
};

// ========== DOTATIONS ==========

export const dotationsAPI = {
  // Lister les rapports de dotation
  list: async (params = {}) => {
    const queryParams = new URLSearchParams(params).toString();
    const endpoint = `/api/dotations${queryParams ? `?${queryParams}` : ''}`;
    return await apiRequest(endpoint);
  },

  // Créer un rapport de dotation
  create: async (reportData) => {
    return await apiRequest('/api/dotations', {
      method: 'POST',
      body: JSON.stringify(reportData),
    });
  },

  // Récupérer un rapport spécifique
  get: async (reportId) => {
    return await apiRequest(`/api/dotations/${reportId}`);
  },

  // Mettre à jour un rapport
  update: async (reportId, updateData) => {
    return await apiRequest(`/api/dotations/${reportId}`, {
      method: 'PUT',
      body: JSON.stringify(updateData),
    });
  },

  // Supprimer un rapport
  delete: async (reportId) => {
    return await apiRequest(`/api/dotations/${reportId}`, {
      method: 'DELETE',
    });
  },

  // Import en lot
  bulkImport: async (data, format = 'auto') => {
    return await apiRequest('/api/dotations/bulk-import', {
      method: 'POST',
      body: JSON.stringify({ data, format }),
    });
  },

  // Export PDF
  exportPdf: async (reportId, filters = {}) => {
    const response = await fetch(`${API_BASE_URL}/api/dotations/${reportId}/export-pdf`, {
      method: 'POST',
      headers: API_CONFIG.headers,
      body: JSON.stringify({ format: 'pdf', filters }),
    });

    if (!response.ok) {
      throw new Error('Erreur lors de l\'export PDF');
    }

    // Retourner le blob pour téléchargement
    return await response.blob();
  },

  // Export Excel
  exportExcel: async (reportId, filters = {}) => {
    const response = await fetch(`${API_BASE_URL}/api/dotations/${reportId}/export-excel`, {
      method: 'POST',
      headers: API_CONFIG.headers,
      body: JSON.stringify({ format: 'excel', filters }),
    });

    if (!response.ok) {
      throw new Error('Erreur lors de l\'export Excel');
    }

    return await response.blob();
  },

  // Gestion des lignes d'employés
  rows: {
    list: async (reportId) => {
      return await apiRequest(`/api/dotations/${reportId}/rows`);
    },

    add: async (reportId, rowData) => {
      return await apiRequest(`/api/dotations/${reportId}/rows`, {
        method: 'POST',
        body: JSON.stringify(rowData),
      });
    },
  },
};

// ========== IMPÔTS / TAX DECLARATIONS ==========

export const taxAPI = {
  // Lister les déclarations
  list: async (params = {}) => {
    const queryParams = new URLSearchParams(params).toString();
    const endpoint = `/api/tax-declarations${queryParams ? `?${queryParams}` : ''}`;
    return await apiRequest(endpoint);
  },

  // Créer une déclaration
  create: async (declarationData) => {
    return await apiRequest('/api/tax-declarations', {
      method: 'POST',
      body: JSON.stringify(declarationData),
    });
  },

  // Calculer les impôts (prévisualisation)
  calculate: async (calculationData) => {
    return await apiRequest('/api/tax-declarations/calculate', {
      method: 'POST',
      body: JSON.stringify(calculationData),
    });
  },

  // Récupérer les paliers fiscaux
  getBrackets: async (bracketType = null) => {
    const endpoint = `/api/tax-declarations/brackets${bracketType ? `?bracket_type=${bracketType}` : ''}`;
    return await apiRequest(endpoint);
  },
};

// ========== HEALTH CHECK ==========

export const healthAPI = {
  check: async () => {
    return await apiRequest('/health');
  },

  status: async () => {
    return await apiRequest('/');
  },
};

// ========== UTILITAIRES ==========

// Fonction pour télécharger un blob (exports)
export const downloadBlob = (blob, filename) => {
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);
};

// Fonction pour formatter les erreurs API
export const formatAPIError = (error) => {
  if (typeof error === 'string') {
    return error;
  }
  
  if (error.message) {
    return error.message;
  }
  
  return 'Une erreur inattendue est survenue';
};

// Intercepteur pour les requêtes automatiques de refresh token
const originalRequest = apiRequest;
const apiRequestWithRetry = async (endpoint, options = {}) => {
  try {
    return await originalRequest(endpoint, options);
  } catch (error) {
    // Si l'erreur est 401 et qu'on a un refresh token, essayer de rafraîchir
    if (error.message.includes('401') && localStorage.getItem('refresh_token')) {
      try {
        await authAPI.refreshToken();
        // Réessayer la requête originale avec le nouveau token
        return await originalRequest(endpoint, options);
      } catch (refreshError) {
        console.error('Impossible de rafraîchir le token:', refreshError);
        throw error; // Relancer l'erreur originale
      }
    }
    throw error;
  }
};

// Exporter la version avec retry
export { apiRequestWithRetry as apiRequest };

console.log('🔧 Service API initialisé avec backend:', API_BASE_URL);