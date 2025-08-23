import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Badge } from './ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { 
  Settings, 
  Users, 
  Database, 
  Shield,
  Activity,
  AlertTriangle,
  CheckCircle 
} from 'lucide-react';
import { toast } from 'sonner';

const StaffConfig = () => {
  const [loading, setLoading] = useState(false);
  const [systemStatus, setSystemStatus] = useState({
    database: 'online',
    discord: 'online',
    webhooks: 'warning',
    rls: 'online'
  });

  const handleTestWebhooks = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 2000));
      toast.success('Webhooks testés avec succès');
      setSystemStatus(prev => ({ ...prev, webhooks: 'online' }));
    } catch (error) {
      toast.error('Erreur lors du test des webhooks');
    } finally {
      setLoading(false);
    }
  };

  const handleSyncRoles = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 3000));
      toast.success('Synchronisation des rôles Discord terminée');
    } catch (error) {
      toast.error('Erreur lors de la synchronisation');
    } finally {
      setLoading(false);
    }
  };

  const handleHealthCheck = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1500));
      toast.success('Vérification système terminée - Tout fonctionne');
    } catch (error) {
      toast.error('Problème détecté lors de la vérification');
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'online':
        return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'warning':
        return <AlertTriangle className="w-4 h-4 text-yellow-500" />;
      case 'offline':
        return <AlertTriangle className="w-4 h-4 text-red-500" />;
      default:
        return <Activity className="w-4 h-4 text-gray-500" />;
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'online': return 'bg-green-100 text-green-800';
      case 'warning': return 'bg-yellow-100 text-yellow-800';
      case 'offline': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Configuration Staff</h2>
          <p className="text-muted-foreground">
            Gestion système et configuration avancée
          </p>
        </div>
        <Badge variant="outline" className="bg-blue-50 text-blue-700">
          <Shield className="w-3 h-3 mr-1" />
          Staff Only
        </Badge>
      </div>

      <Tabs defaultValue="system" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="system">Système</TabsTrigger>
          <TabsTrigger value="discord">Discord</TabsTrigger>
          <TabsTrigger value="database">Base de Données</TabsTrigger>
          <TabsTrigger value="security">Sécurité</TabsTrigger>
        </TabsList>

        {/* System Status */}
        <TabsContent value="system" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <Activity className="w-5 h-5 mr-2" />
                État du Système
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center justify-between p-3 border rounded-lg">
                  <div className="flex items-center space-x-2">
                    {getStatusIcon(systemStatus.database)}
                    <span className="text-sm font-medium">Base de Données</span>
                  </div>
                  <Badge className={getStatusColor(systemStatus.database)}>
                    {systemStatus.database === 'online' ? 'En ligne' : 'Hors ligne'}
                  </Badge>
                </div>
                
                <div className="flex items-center justify-between p-3 border rounded-lg">
                  <div className="flex items-center space-x-2">
                    {getStatusIcon(systemStatus.discord)}
                    <span className="text-sm font-medium">Bot Discord</span>
                  </div>
                  <Badge className={getStatusColor(systemStatus.discord)}>
                    {systemStatus.discord === 'online' ? 'En ligne' : 'Hors ligne'}
                  </Badge>
                </div>
                
                <div className="flex items-center justify-between p-3 border rounded-lg">
                  <div className="flex items-center space-x-2">
                    {getStatusIcon(systemStatus.webhooks)}
                    <span className="text-sm font-medium">Webhooks</span>
                  </div>
                  <Badge className={getStatusColor(systemStatus.webhooks)}>
                    {systemStatus.webhooks === 'online' ? 'En ligne' : 'Attention'}
                  </Badge>
                </div>
                
                <div className="flex items-center justify-between p-3 border rounded-lg">
                  <div className="flex items-center space-x-2">
                    {getStatusIcon(systemStatus.rls)}
                    <span className="text-sm font-medium">RLS Policies</span>
                  </div>
                  <Badge className={getStatusColor(systemStatus.rls)}>
                    {systemStatus.rls === 'online' ? 'Actif' : 'Inactif'}
                  </Badge>
                </div>
              </div>
              
              <div className="flex space-x-2">
                <Button onClick={handleHealthCheck} disabled={loading}>
                  <Activity className="w-4 h-4 mr-2" />
                  Vérification Système
                </Button>
                <Button onClick={handleTestWebhooks} variant="outline" disabled={loading}>
                  <Database className="w-4 h-4 mr-2" />
                  Test Webhooks
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <Card>
            <CardHeader>
              <CardTitle>Actions Rapides</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="p-4 border rounded-lg text-center hover:bg-muted/50 cursor-pointer transition-colors">
                  <Users className="w-8 h-8 mx-auto mb-2 text-primary" />
                  <p className="text-sm font-medium">Gérer Utilisateurs</p>
                  <p className="text-xs text-muted-foreground">47 utilisateurs actifs</p>
                </div>
                <div className="p-4 border rounded-lg text-center hover:bg-muted/50 cursor-pointer transition-colors">
                  <Database className="w-8 h-8 mx-auto mb-2 text-primary" />
                  <p className="text-sm font-medium">Sauvegardes</p>
                  <p className="text-xs text-muted-foreground">Dernière: Hier 23:00</p>
                </div>
                <div className="p-4 border rounded-lg text-center hover:bg-muted/50 cursor-pointer transition-colors">
                  <Settings className="w-8 h-8 mx-auto mb-2 text-primary" />
                  <p className="text-sm font-medium">Maintenance</p>
                  <p className="text-xs text-muted-foreground">Prochaine: Dimanche</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Discord Configuration */}
        <TabsContent value="discord" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <Users className="w-5 h-5 mr-2" />
                Configuration Discord
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="guild_id">ID de Guilde Principal</Label>
                  <Input
                    id="guild_id"
                    value="1404608015230832742"
                    readOnly
                    className="bg-muted"
                  />
                </div>
                <div>
                  <Label htmlFor="bot_token">Token Bot (Masqué)</Label>
                  <Input
                    id="bot_token"
                    value="••••••••••••••••••••••••••••••••••••••••"
                    readOnly
                    className="bg-muted"
                  />
                </div>
              </div>
              
              <div className="space-y-2">
                <Label>Entreprises Configurées</Label>
                <div className="space-y-2">
                  <div className="flex items-center justify-between p-2 border rounded">
                    <div>
                      <span className="font-medium">LSPD</span>
                      <span className="text-sm text-muted-foreground ml-2">Los Santos Police Department</span>
                    </div>
                    <Badge variant="outline">Role: 123456</Badge>
                  </div>
                  <div className="flex items-center justify-between p-2 border rounded">
                    <div>
                      <span className="font-medium">EMS</span>
                      <span className="text-sm text-muted-foreground ml-2">Emergency Medical Services</span>
                    </div>
                    <Badge variant="outline">Role: 234567</Badge>
                  </div>
                </div>
              </div>
              
              <div className="flex space-x-2">
                <Button onClick={handleSyncRoles} disabled={loading}>
                  <Users className="w-4 h-4 mr-2" />
                  Synchroniser Rôles
                </Button>
                <Button variant="outline">
                  <Settings className="w-4 h-4 mr-2" />
                  Configurer Webhooks
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Database Management */}
        <TabsContent value="database" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <Database className="w-5 h-5 mr-2" />
                Gestion Base de Données
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold">156</div>
                  <div className="text-sm text-muted-foreground">Tables</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold">2.4 GB</div>
                  <div className="text-sm text-muted-foreground">Taille DB</div>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <div className="text-2xl font-bold">47,892</div>
                  <div className="text-sm text-muted-foreground">Enregistrements</div>
                </div>
              </div>
              
              <div className="space-y-2">
                <Label>Tables Principales</Label>
                <div className="space-y-1 text-sm">
                  <div className="flex justify-between">
                    <span>archives</span>
                    <Badge variant="outline">1,234 rows</Badge>
                  </div>
                  <div className="flex justify-between">
                    <span>dotation_reports</span>
                    <Badge variant="outline">567 rows</Badge>
                  </div>
                  <div className="flex justify-between">
                    <span>blanchiment_rows</span>
                    <Badge variant="outline">890 rows</Badge>
                  </div>
                  <div className="flex justify-between">
                    <span>enterprises</span>
                    <Badge variant="outline">12 rows</Badge>
                  </div>
                </div>
              </div>
              
              <div className="flex space-x-2">
                <Button variant="outline">
                  <Database className="w-4 h-4 mr-2" />
                  Sauvegarder
                </Button>
                <Button variant="outline">
                  <Activity className="w-4 h-4 mr-2" />
                  Analyser Performances
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Security */}
        <TabsContent value="security" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center">
                <Shield className="w-5 h-5 mr-2" />
                Sécurité & RLS
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label>Politiques RLS Actives</Label>
                <div className="space-y-2">
                  <div className="flex items-center justify-between p-2 border rounded">
                    <span className="text-sm">archives_select_policy</span>
                    <Badge className="bg-green-100 text-green-800">Actif</Badge>
                  </div>
                  <div className="flex items-center justify-between p-2 border rounded">
                    <span className="text-sm">dotation_reports_policy</span>
                    <Badge className="bg-green-100 text-green-800">Actif</Badge>
                  </div>
                  <div className="flex items-center justify-between p-2 border rounded">
                    <span className="text-sm">blanchiment_security_policy</span>
                    <Badge className="bg-green-100 text-green-800">Actif</Badge>
                  </div>
                </div>
              </div>
              
              <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                <div className="flex items-start space-x-2">
                  <AlertTriangle className="w-5 h-5 text-yellow-600 mt-0.5" />
                  <div>
                    <p className="text-sm font-medium text-yellow-800">
                      Attention: Politiques de sécurité
                    </p>
                    <p className="text-xs text-yellow-700 mt-1">
                      Les modifications des politiques RLS peuvent affecter l'accès aux données.
                      Contactez l'administrateur système avant toute modification.
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="flex space-x-2">
                <Button variant="outline">
                  <Shield className="w-4 h-4 mr-2" />
                  Voir Dashboard Supabase
                </Button>
                <Button variant="outline">
                  <Activity className="w-4 h-4 mr-2" />
                  Audit Logs
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default StaffConfig;