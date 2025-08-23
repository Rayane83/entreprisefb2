import React from 'react';
import { Button } from '../components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Home, AlertCircle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const NotFound = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <Card className="w-full max-w-md text-center">
        <CardHeader className="space-y-4">
          <AlertCircle className="w-16 h-16 mx-auto text-destructive" />
          <CardTitle className="text-2xl">Page non trouvée</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            La page que vous recherchez n'existe pas ou a été déplacée.
          </p>
          <Button onClick={() => navigate('/')} className="w-full">
            <Home className="w-4 h-4 mr-2" />
            Retour à l'accueil
          </Button>
        </CardContent>
      </Card>
    </div>
  );
};

export default NotFound;