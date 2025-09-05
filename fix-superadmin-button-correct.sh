#!/bin/bash

# 🔧 CORRECTION Bouton SuperAdmin - Fix syntaxe
# Usage: ./fix-superadmin-button-correct.sh

set -e

DEST_PATH="/var/www/flashbackfa-entreprise.fr"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log "🔧 CORRECTION Bouton SuperAdmin - Fix syntaxe"

# 1. Restaurer backup propre
if [ -f "$DEST_PATH/frontend/src/pages/Superadmin.js.backup" ]; then
    log "🔄 Restauration backup propre..."
    cp "$DEST_PATH/frontend/src/pages/Superadmin.js.backup" "$DEST_PATH/frontend/src/pages/Superadmin.js"
    log "✅ Backup restauré"
else
    error "❌ Backup non trouvé"
    exit 1
fi

# 2. Créer le Superadmin.js CORRECT complet
log "🔧 Création Superadmin.js correct avec bouton..."

cat > "$DEST_PATH/frontend/src/pages/Superadmin.js" << 'EOF'
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';
import { Badge } from '../components/ui/badge';
import { 
  Shield, 
  Users, 
  Settings, 
  Database,
  Activity,
  AlertTriangle,
  CheckCircle,
  Home,
  ArrowLeft
} from 'lucide-react';

const Superadmin = () => {
  const navigate = useNavigate();
  const { user, userRole, userEntreprise } = useAuth();
  const [activeTab, setActiveTab] = useState('overview');

  // Mock data pour la démonstration
  const [systemStats] = useState({
    totalUsers: 156,
    activeUsers: 89,
    totalEnterprises: 12,
    totalTransactions: 2847
  });

  const [recentActivity] = useState([
    { id: 1, user: 'Jean Dupont', action: 'Connexion', time: '2 minutes ago', type: 'success' },
    { id: 2, user: 'Marie Martin', action: 'Export Excel', time: '15 minutes ago', type: 'info' },
    { id: 3, user: 'Pierre Durand', action: 'Ajout dotation', time: '1 heure ago', type: 'success' },
    { id: 4, user: 'System', action: 'Erreur base de données', time: '2 heures ago', type: 'error' }
  ]);

  const getActivityIcon = (type) => {
    switch (type) {
      case 'success': return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'error': return <AlertTriangle className="w-4 h-4 text-red-500" />;
      default: return <Activity className="w-4 h-4 text-blue-500" />;
    }
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="border-b bg-card">
        <div className="container mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => navigate('/')}
                className="flex items-center"
              >
                <ArrowLeft className="w-4 h-4 mr-2" />
                Retour
              </Button>
              <div>
                <h1 className="text-3xl font-bold flex items-center">
                  <Shield className="w-8 h-8 mr-3 text-red-600" />
                  SuperAdmin Panel
                </h1>
                <p className="text-muted-foreground mt-1">
                  Administration système et surveillance
                </p>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <Badge variant="outline" className="bg-red-50 text-red-700">
                <Shield className="w-3 h-3 mr-1" />
                {userRole === 'staff' ? 'Staff' : 'SuperAdmin'}
              </Badge>
              <Button onClick={() => navigate('/')} className="bg-green-600 hover:bg-green-700">
                <Home className="w-4 h-4 mr-2" />
                Page Principale
              </Button>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-6">
        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="overview">Vue d'ensemble</TabsTrigger>
            <TabsTrigger value="users">Utilisateurs</TabsTrigger>
            <TabsTrigger value="system">Système</TabsTrigger>
            <TabsTrigger value="logs">Logs</TabsTrigger>
          </TabsList>

          {/* Vue d'ensemble */}
          <TabsContent value="overview" className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Utilisateurs Total</CardTitle>
                  <Users className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{systemStats.totalUsers}</div>
                  <p className="text-xs text-muted-foreground">+12% depuis le mois dernier</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Utilisateurs Actifs</CardTitle>
                  <Activity className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{systemStats.activeUsers}</div>
                  <p className="text-xs text-muted-foreground">Connectés aujourd'hui</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Entreprises</CardTitle>
                  <Database className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{systemStats.totalEnterprises}</div>
                  <p className="text-xs text-muted-foreground">Organisations enregistrées</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Transactions</CardTitle>
                  <Settings className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{systemStats.totalTransactions}</div>
                  <p className="text-xs text-muted-foreground">Ce mois-ci</p>
                </CardContent>
              </Card>
            </div>

            {/* Activité récente */}
            <Card>
              <CardHeader>
                <CardTitle>Activité Récente</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {recentActivity.map((activity) => (
                    <div key={activity.id} className="flex items-center space-x-4">
                      <div className="flex-shrink-0">
                        {getActivityIcon(activity.type)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900">
                          {activity.user}
                        </p>
                        <p className="text-sm text-gray-500">
                          {activity.action}
                        </p>
                      </div>
                      <div className="flex-shrink-0 text-sm text-gray-500">
                        {activity.time}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Gestion Utilisateurs */}
          <TabsContent value="users" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Gestion des Utilisateurs</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Administration des comptes utilisateurs et des permissions
                </p>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8">
                  <Users className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground">Module de gestion des utilisateurs</p>
                  <p className="text-sm text-muted-foreground mt-2">
                    Fonctionnalités à implémenter
                  </p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Système */}
          <TabsContent value="system" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Configuration Système</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Paramètres avancés et configuration du système
                </p>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8">
                  <Settings className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground">Configuration système</p>
                  <p className="text-sm text-muted-foreground mt-2">
                    Paramètres avancés disponibles ici
                  </p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Logs */}
          <TabsContent value="logs" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Logs Système</CardTitle>
                <p className="text-sm text-muted-foreground">
                  Surveillance et logs d'activité du système
                </p>
              </CardHeader>
              <CardContent>
                <div className="text-center py-8">
                  <Activity className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground">Logs et monitoring</p>
                  <p className="text-sm text-muted-foreground mt-2">
                    Surveillance en temps réel du système
                  </p>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default Superadmin;
EOF

log "✅ Superadmin.js correct créé"

# 3. Build test
log "🔨 Test build avec syntaxe correcte..."

cd "$DEST_PATH/frontend"
npm run build

if [ ! -f "build/index.html" ]; then
    error "❌ Build échoué même avec syntaxe correcte"
    exit 1
fi

log "✅ Build réussi !"

# 4. Deploy
sudo systemctl reload nginx

# 5. Test final
log "🧪 Test bouton dans build..."

sleep 3

if grep -q "Page Principale" "$DEST_PATH/frontend/build/static/js/main."*.js; then
    echo "✅ Bouton 'Page Principale' détecté dans build"
    SUCCESS=true
else
    echo "❌ Bouton non détecté"
    SUCCESS=false
fi

# 6. Résultats
log "🎯 RÉSULTATS CORRECTION"

if [ "$SUCCESS" = true ]; then
    log "🎉 SUCCESS - Bouton SuperAdmin corrigé et déployé !"
    
    echo ""
    echo "✅ CORRECTION APPLIQUÉE :"
    echo "   🔧 Syntaxe corrigée (imports fixes)"
    echo "   🆕 Bouton vert 'Page Principale' ajouté"
    echo "   🏠 Navigation vers page d'accueil"
    echo "   🎯 SuperAdmin page complète"
    
    echo ""
    echo "🧪 BOUTONS DISPONIBLES DANS SUPERADMIN :"
    echo "   • Bouton 'Retour' (gris, en haut à gauche)"
    echo "   • Bouton 'Page Principale' (vert, en haut à droite)"
    echo ""
    echo "🎯 POUR TESTER :"
    echo "   1. https://flashbackfa-entreprise.fr/"
    echo "   2. Connexion Discord (rôle Staff)"
    echo "   3. Clic 'SuperStaff' → page SuperAdmin ouverte"
    echo "   4. Voir les 2 boutons de navigation"
    
else
    error "❌ Problème persistant"
fi

log "🔧 CORRECTION SUPERADMIN TERMINÉE"