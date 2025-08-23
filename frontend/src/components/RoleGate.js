import React from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Shield } from 'lucide-react';

const RoleGate = ({ children, requiredAccess }) => {
  const auth = useAuth();
  
  const hasAccess = () => {
    if (typeof requiredAccess === 'string') {
      return auth[requiredAccess] && auth[requiredAccess]();
    }
    return false;
  };

  if (!hasAccess()) {
    return (
      <Card className="max-w-md mx-auto">
        <CardHeader className="text-center">
          <Shield className="w-12 h-12 mx-auto text-muted-foreground mb-2" />
          <CardTitle className="text-lg">Accès refusé</CardTitle>
        </CardHeader>
        <CardContent className="text-center">
          <p className="text-muted-foreground">
            Vous n'avez pas les permissions nécessaires pour accéder à cette section.
          </p>
          <p className="text-sm text-muted-foreground mt-2">
            Rôle requis: {requiredAccess}
          </p>
        </CardContent>
      </Card>
    );
  }

  return <>{children}</>;
};

export default RoleGate;