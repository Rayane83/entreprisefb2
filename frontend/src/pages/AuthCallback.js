import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import newAuthService from '../services/newAuthService';

const AuthCallback = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { setLoading } = useAuth();
  const [status, setStatus] = useState('Traitement de l\'authentification...');
  const [error, setError] = useState(null);

  useEffect(() => {
    const handleCallback = async () => {
      try {
        setLoading(true);
        setStatus('Traitement du callback Discord...');

        // Récupérer le code et l'état depuis l'URL
        const code = searchParams.get('code');
        const state = searchParams.get('state');
        const error = searchParams.get('error');

        if (error) {
          throw new Error(`Erreur Discord OAuth: ${error}`);
        }

        if (!code) {
          throw new Error('Code d\'autorisation manquant');
        }

        console.log('🔐 Traitement du callback Discord avec code:', code.substring(0, 10) + '...');

        // Traiter le callback avec le nouveau service
        const result = await newAuthService.handleDiscordCallback(code, state);

        if (result.error) {
          throw result.error;
        }

        console.log('✅ Authentification réussie, redirection...');
        setStatus('Authentification réussie ! Redirection...');

        // Attendre un peu puis rediriger
        setTimeout(() => {
          navigate('/', { replace: true });
        }, 1000);

      } catch (error) {
        console.error('❌ Erreur lors du callback d\'authentification:', error);
        setError(error.message || 'Erreur lors de l\'authentification');
        setStatus('Erreur d\'authentification');

        // Rediriger vers la page d'accueil après erreur
        setTimeout(() => {
          navigate('/', { replace: true });
        }, 3000);
      } finally {
        setLoading(false);
      }
    };

    handleCallback();
  }, [searchParams, navigate, setLoading]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <div className="mx-auto h-12 w-12 flex items-center justify-center">
            {error ? (
              <div className="text-red-500">
                <svg className="w-12 h-12" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
            ) : (
              <div className="text-blue-500">
                <svg className="animate-spin w-12 h-12" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              </div>
            )}
          </div>
          
          <h2 className="mt-6 text-3xl font-extrabold text-gray-900">
            {error ? 'Erreur d\'authentification' : 'Authentification'}
          </h2>
          
          <p className="mt-2 text-sm text-gray-600">
            {status}
          </p>
          
          {error && (
            <div className="mt-4 p-4 border border-red-300 rounded-md bg-red-50">
              <div className="text-sm text-red-700">
                {error}
              </div>
              <div className="text-xs text-red-500 mt-2">
                Redirection automatique vers la page d'accueil...
              </div>
            </div>
          )}
          
          {!error && (
            <div className="mt-4 p-4 border border-blue-300 rounded-md bg-blue-50">
              <div className="text-sm text-blue-700">
                Finalisation de la connexion avec Discord...
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AuthCallback;