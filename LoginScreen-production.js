import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { LogIn, Shield, Users, Building } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { toast } from 'sonner';

const LoginScreen = () => {
  const { loginWithDiscord, loading } = useAuth();
  const [isConnecting, setIsConnecting] = useState(false);

  const handleDiscordLogin = async () => {
    setIsConnecting(true);
    try {
      const { error } = await loginWithDiscord();
      
      if (error) {
        console.error('Erreur connexion:', error);
        toast.error('Erreur lors de la connexion Discord. Veuillez réessayer.');
      } else {
        toast.success('Redirection vers Discord...');
      }
    } catch (error) {
      console.error('Erreur connexion Discord:', error);
      toast.error('Erreur de connexion. Vérifiez votre connexion internet.');
    } finally {
      setIsConnecting(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        
        {/* Logo et titre */}
        <div className="text-center space-y-4">
          <div className="flex items-center justify-center w-16 h-16 mx-auto bg-blue-600 rounded-full">
            <Building className="w-8 h-8 text-white" />
          </div>
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              Portail Entreprise
            </h1>
            <p className="text-lg text-blue-600 font-semibold">
              Flashback Fa
            </p>
            <p className="text-sm text-gray-600 mt-2">
              Gestion des dotations, impôts et archives
            </p>
          </div>
        </div>

        {/* Carte de connexion */}
        <Card className="shadow-xl border-0">
          <CardHeader className="text-center pb-2">
            <CardTitle className="flex items-center justify-center space-x-2">
              <Shield className="w-5 h-5 text-blue-600" />
              <span>Connexion Sécurisée</span>
            </CardTitle>
            <p className="text-sm text-gray-600">
              Connectez-vous avec votre compte Discord
            </p>
          </CardHeader>
          
          <CardContent className="space-y-6">
            
            {/* Informations sur les rôles */}
            <div className="space-y-3">
              <div className="flex items-center space-x-2 text-sm text-gray-600">
                <Users className="w-4 h-4" />
                <span className="font-medium">Rôles autorisés :</span>
              </div>
              <div className="flex flex-wrap gap-2">
                <Badge variant="outline" className="bg-blue-50 text-blue-700">
                  Staff
                </Badge>
                <Badge variant="outline" className="bg-green-50 text-green-700">
                  Patron
                </Badge>
                <Badge variant="outline" className="bg-yellow-50 text-yellow-700">
                  Co-Patron
                </Badge>
                <Badge variant="outline" className="bg-purple-50 text-purple-700">
                  DOT
                </Badge>
                <Badge variant="outline" className="bg-gray-50 text-gray-700">
                  Employé
                </Badge>
              </div>
            </div>

            {/* Bouton de connexion Discord */}
            <Button 
              onClick={handleDiscordLogin}
              disabled={loading || isConnecting}
              className="w-full bg-[#5865F2] hover:bg-[#4752C4] text-white h-12"
              size="lg"
            >
              {isConnecting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                  Connexion en cours...
                </>
              ) : (
                <>
                  <LogIn className="w-5 h-5 mr-2" />
                  Se connecter avec Discord
                </>
              )}
            </Button>

            {/* Informations de sécurité */}
            <div className="text-xs text-gray-500 text-center space-y-2">
              <p>
                🔒 Connexion sécurisée via Discord OAuth
              </p>
              <p>
                Vos permissions sont automatiquement synchronisées avec vos rôles Discord sur le serveur Flashback Fa
              </p>
            </div>

          </CardContent>
        </Card>

        {/* Informations supplémentaires */}
        <div className="text-center space-y-2">
          <p className="text-sm text-gray-600">
            Problème de connexion ?
          </p>
          <p className="text-xs text-gray-500">
            Contactez un administrateur sur Discord ou vérifiez que vous êtes membre du serveur Flashback Fa
          </p>
        </div>

      </div>
    </div>
  );
};

export default LoginScreen;