import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from './ui/card';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { LogIn, Shield, Users, Building, AlertCircle } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { toast } from 'sonner';

const LoginScreen = () => {
  const { loginWithDiscord, loading } = useAuth();
  const [isConnecting, setIsConnecting] = useState(false);

  const handleDiscordLogin = async () => {
    setIsConnecting(true);
    
    try {
      console.log('🚀 Démarrage connexion Discord...');
      toast.info('Redirection vers Discord...');
      
      const { error } = await loginWithDiscord();
      
      if (error) {
        console.error('Erreur connexion:', error);
        toast.error('Erreur lors de la connexion Discord. Vérifiez que vous êtes membre du serveur Flashback Fa.');
        setIsConnecting(false);
      }
      // Si pas d'erreur, la redirection Discord est en cours
      
    } catch (error) {
      console.error('Erreur connexion Discord:', error);
      toast.error('Erreur de connexion. Vérifiez votre connexion internet.');
      setIsConnecting(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        
        {/* Logo et Titre */}
        <div className="text-center space-y-4">
          <div className="flex items-center justify-center w-20 h-20 mx-auto bg-gradient-to-br from-blue-600 to-purple-600 rounded-full shadow-lg">
            <Building className="w-10 h-10 text-white" />
          </div>
          <div>
            <h1 className="text-4xl font-bold text-gray-900 mb-2">
              Portail Entreprise
            </h1>
            <p className="text-xl text-blue-600 font-semibold">
              Flashback Fa
            </p>
            <p className="text-sm text-gray-600 mt-3">
              Gestion des dotations, impôts et archives d'entreprise
            </p>
          </div>
        </div>

        {/* Carte de Connexion */}
        <Card className="shadow-2xl border-0 bg-white/90 backdrop-blur">
          <CardHeader className="text-center pb-4">
            <CardTitle className="flex items-center justify-center space-x-2 text-lg">
              <Shield className="w-6 h-6 text-blue-600" />
              <span>Connexion Sécurisée</span>
            </CardTitle>
            <CardDescription className="text-sm text-gray-600">
              Authentification via Discord obligatoire
            </CardDescription>
          </CardHeader>
          
          <CardContent className="space-y-6">
            
            {/* Avertissement sécurité */}
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <div className="flex items-start space-x-3">
                <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
                <div className="text-sm text-blue-800">
                  <p className="font-semibold mb-1">Accès Restreint</p>
                  <p>Vous devez être membre du serveur Discord <strong>Flashback Fa</strong> avec un rôle autorisé.</p>
                </div>
              </div>
            </div>

            {/* Rôles autorisés */}
            <div className="space-y-3">
              <div className="flex items-center space-x-2 text-sm text-gray-700">
                <Users className="w-4 h-4" />
                <span className="font-medium">Rôles autorisés :</span>
              </div>
              <div className="grid grid-cols-2 gap-2">
                <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200 justify-center py-2">
                  Staff
                </Badge>
                <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200 justify-center py-2">
                  Patron
                </Badge>
                <Badge variant="outline" className="bg-yellow-50 text-yellow-700 border-yellow-200 justify-center py-2">
                  Co-Patron
                </Badge>
                <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200 justify-center py-2">
                  DOT
                </Badge>
                <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-200 justify-center py-2 col-span-2">
                  Employé
                </Badge>
              </div>
            </div>

            {/* Bouton Discord */}
            <Button 
              onClick={handleDiscordLogin}
              disabled={loading || isConnecting}
              className="w-full bg-[#5865F2] hover:bg-[#4752C4] text-white h-14 text-lg font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
            >
              {isConnecting ? (
                <>
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-3"></div>
                  Connexion en cours...
                </>
              ) : (
                <>
                  <LogIn className="w-6 h-6 mr-3" />
                  Se connecter avec Discord
                </>
              )}
            </Button>

            {/* Informations sécurité */}
            <div className="text-xs text-gray-500 text-center space-y-2 pt-2">
              <p className="flex items-center justify-center space-x-1">
                <Shield className="w-3 h-3" />
                <span>Connexion sécurisée OAuth 2.0</span>
              </p>
              <p>
                Vos permissions sont synchronisées automatiquement avec vos rôles Discord sur le serveur Flashback Fa
              </p>
            </div>

          </CardContent>
        </Card>

        {/* Support */}
        <div className="text-center space-y-3">
          <p className="text-sm text-gray-600">
            Problème de connexion ?
          </p>
          <div className="text-xs text-gray-500 space-y-1">
            <p>• Vérifiez que vous êtes membre du serveur Discord Flashback Fa</p>
            <p>• Contactez un administrateur si vous ne pouvez pas vous connecter</p>
            <p>• Assurez-vous d'avoir un des rôles autorisés</p>
          </div>
        </div>

      </div>
    </div>
  );
};

export default LoginScreen;