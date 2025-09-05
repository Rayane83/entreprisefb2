import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Badge } from '../components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';
import { 
  Building, 
  Users, 
  Plus,
  Trash2,
  Save,
  ArrowLeft,
  Server,
  Shield,
  Home
} from 'lucide-react';
import { toast } from 'sonner';

const EnterpriseManagement = () => {
  const navigate = useNavigate();
  const { userRole } = useAuth();
  const [loading, setLoading] = useState(false);

  // État pour les entreprises
  const [enterprises, setEnterprises] = useState([
    {
      id: 1,
      nom: 'LSPD',
      discord_guild_id: '1404608015230832742',
      main_role_id: '1404608015230832745'
    },
    {
      id: 2,
      nom: 'EMS',
      discord_guild_id: '1404608015230832742',
      main_role_id: '1404608015230832746'
    }
  ]);

  // État pour nouvelle entreprise
  const [newEnterprise, setNewEnterprise] = useState({
    nom: '',
    discord_guild_id: '',
    main_role_id: ''
  });

  // État pour configuration des rôles Dot Guild
  const [dotGuildConfig, setDotGuildConfig] = useState({
    dot_guild_id: '1234567890123456789',
    staff_role_id: '1234567890123456780',
    patron_role_id: '1234567890123456781',
    co_patron_role_id: '1234567890123456782',
    dot_role_id: '1234567890123456783'
  });

  const handleAddEnterprise = async () => {
    if (!newEnterprise.nom || !newEnterprise.discord_guild_id || !newEnterprise.main_role_id) {
      toast.error('Veuillez remplir tous les champs obligatoires');
      return;
    }

    setLoading(true);
    try {
      // Simulation d'appel API
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const enterprise = {
        id: Date.now(),
        ...newEnterprise
      };
      
      setEnterprises([...enterprises, enterprise]);
      setNewEnterprise({
        nom: '',
        discord_guild_id: '',
        main_role_id: ''
      });
      
      toast.success('Entreprise ajoutée avec succès');
    } catch (error) {
      toast.error('Erreur lors de l\'ajout de l\'entreprise');
    } finally {
      setLoading(false);
    }
  };

  const handleRemoveEnterprise = async (id) => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 500));
      setEnterprises(enterprises.filter(e => e.id !== id));
      toast.success('Entreprise supprimée');
    } catch (error) {
      toast.error('Erreur lors de la suppression');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveDotGuildConfig = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      toast.success('Configuration Dot Guild sauvegardée');
    } catch (error) {
      toast.error('Erreur lors de la sauvegarde');
    } finally {
      setLoading(false);
    }
  };

  const handleGoToMainPage = () => {
    navigate('/');
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
                <h1 className="text-3xl font-bold">Gestion des Entreprises</h1>
                <p className="text-muted-foreground mt-1">
                  Configuration des entreprises et des rôles Discord
                </p>
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <Badge variant="outline" className="bg-purple-50 text-purple-700">
                <Shield className="w-3 h-3 mr-1" />
                {userRole === 'staff' ? 'Staff' : 'Admin'}
              </Badge>
              <Button onClick={handleGoToMainPage} className="bg-green-600 hover:bg-green-700">
                <Home className="w-4 h-4 mr-2" />
                Page Principale
              </Button>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-6">
        <Tabs defaultValue="enterprises" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="enterprises">Entreprises</TabsTrigger>
            <TabsTrigger value="roles">Configuration Rôles</TabsTrigger>
          </TabsList>

          {/* Gestion des Entreprises */}
          <TabsContent value="enterprises" className="space-y-6">
            {/* Formulaire d'ajout */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Plus className="w-5 h-5 mr-2" />
                  Ajouter une Nouvelle Entreprise
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <Label htmlFor="nom">Nom de l'Entreprise *</Label>
                    <Input
                      id="nom"
                      value={newEnterprise.nom}
                      onChange={(e) => setNewEnterprise(prev => ({ ...prev, nom: e.target.value }))}
                      placeholder="LSPD, EMS, FBI..."
                    />
                  </div>
                  <div>
                    <Label htmlFor="guild_id">ID Guild Discord *</Label>
                    <Input
                      id="guild_id"
                      value={newEnterprise.discord_guild_id}
                      onChange={(e) => setNewEnterprise(prev => ({ ...prev, discord_guild_id: e.target.value }))}
                      placeholder="1404608015230832742"
                    />
                  </div>
                  <div>
                    <Label htmlFor="main_role_id">ID Rôle Principal *</Label>
                    <Input
                      id="main_role_id"
                      value={newEnterprise.main_role_id}
                      onChange={(e) => setNewEnterprise(prev => ({ ...prev, main_role_id: e.target.value }))}
                      placeholder="1404608015230832745"
                    />
                  </div>
                </div>
                <div className="flex justify-end">
                  <Button onClick={handleAddEnterprise} disabled={loading}>
                    <Plus className="w-4 h-4 mr-2" />
                    Ajouter l'Entreprise
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Liste des entreprises */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Building className="w-5 h-5 mr-2" />
                  Entreprises Configurées ({enterprises.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left p-4">Nom</th>
                        <th className="text-left p-4">ID Guild Discord</th>
                        <th className="text-left p-4">ID Rôle Principal</th>
                        <th className="text-left p-4">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {enterprises.map((enterprise) => (
                        <tr key={enterprise.id} className="border-b hover:bg-muted/50">
                          <td className="p-4">
                            <div className="flex items-center space-x-2">
                              <Building className="w-4 h-4 text-primary" />
                              <span className="font-medium">{enterprise.nom}</span>
                            </div>
                          </td>
                          <td className="p-4">
                            <Badge variant="outline" className="font-mono text-xs">
                              {enterprise.discord_guild_id}
                            </Badge>
                          </td>
                          <td className="p-4">
                            <Badge variant="outline" className="font-mono text-xs">
                              {enterprise.main_role_id}
                            </Badge>
                          </td>
                          <td className="p-4">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleRemoveEnterprise(enterprise.id)}
                              className="text-red-600 hover:text-red-700 hover:bg-red-50"
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                
                {enterprises.length === 0 && (
                  <div className="text-center py-8">
                    <Building className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                    <p className="text-muted-foreground">Aucune entreprise configurée</p>
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          {/* Configuration des Rôles */}
          <TabsContent value="roles" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Server className="w-5 h-5 mr-2" />
                  Configuration Rôles Dot Guild
                </CardTitle>
                <p className="text-sm text-muted-foreground mt-1">
                  Configurez les ID des rôles Staff, Patron, Co-Patron et DOT depuis la guild Dot
                </p>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <div>
                      <Label htmlFor="dot_guild_id">ID de la Guild Dot *</Label>
                      <Input
                        id="dot_guild_id"
                        value={dotGuildConfig.dot_guild_id}
                        onChange={(e) => setDotGuildConfig(prev => ({ ...prev, dot_guild_id: e.target.value }))}
                        placeholder="1234567890123456789"
                      />
                    </div>
                    
                    <div>
                      <Label htmlFor="staff_role_id">ID Rôle Staff</Label>
                      <Input
                        id="staff_role_id"
                        value={dotGuildConfig.staff_role_id}
                        onChange={(e) => setDotGuildConfig(prev => ({ ...prev, staff_role_id: e.target.value }))}
                        placeholder="1234567890123456780"
                      />
                    </div>
                    
                    <div>
                      <Label htmlFor="patron_role_id">ID Rôle Patron</Label>
                      <Input
                        id="patron_role_id"
                        value={dotGuildConfig.patron_role_id}
                        onChange={(e) => setDotGuildConfig(prev => ({ ...prev, patron_role_id: e.target.value }))}
                        placeholder="1234567890123456781"
                      />
                    </div>
                  </div>
                  
                  <div className="space-y-4">
                    <div>
                      <Label htmlFor="co_patron_role_id">ID Rôle Co-Patron</Label>
                      <Input
                        id="co_patron_role_id"
                        value={dotGuildConfig.co_patron_role_id}
                        onChange={(e) => setDotGuildConfig(prev => ({ ...prev, co_patron_role_id: e.target.value }))}
                        placeholder="1234567890123456782"
                      />
                    </div>
                    
                    <div>
                      <Label htmlFor="dot_role_id">ID Rôle DOT</Label>
                      <Input
                        id="dot_role_id"
                        value={dotGuildConfig.dot_role_id}
                        onChange={(e) => setDotGuildConfig(prev => ({ ...prev, dot_role_id: e.target.value }))}
                        placeholder="1234567890123456783"
                      />
                    </div>
                    
                    <div className="pt-4">
                      <Button onClick={handleSaveDotGuildConfig} disabled={loading} className="w-full">
                        <Save className="w-4 h-4 mr-2" />
                        Sauvegarder Configuration
                      </Button>
                    </div>
                  </div>
                </div>

                {/* Aperçu de la configuration */}
                <div className="p-4 bg-muted rounded-lg">
                  <h4 className="font-medium mb-3">Aperçu de la Configuration :</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div className="space-y-2">
                      <div className="flex justify-between">
                        <span>Guild Dot:</span>
                        <Badge variant="outline" className="font-mono text-xs">
                          {dotGuildConfig.dot_guild_id}
                        </Badge>
                      </div>
                      <div className="flex justify-between">
                        <span>Staff:</span>
                        <Badge variant="outline" className="bg-blue-50 text-blue-700 font-mono text-xs">
                          {dotGuildConfig.staff_role_id}
                        </Badge>
                      </div>
                    </div>
                    <div className="space-y-2">
                      <div className="flex justify-between">
                        <span>Patron:</span>
                        <Badge variant="outline" className="bg-green-50 text-green-700 font-mono text-xs">
                          {dotGuildConfig.patron_role_id}
                        </Badge>
                      </div>
                      <div className="flex justify-between">
                        <span>Co-Patron:</span>
                        <Badge variant="outline" className="bg-yellow-50 text-yellow-700 font-mono text-xs">
                          {dotGuildConfig.co_patron_role_id}
                        </Badge>
                      </div>
                      <div className="flex justify-between">
                        <span>DOT:</span>
                        <Badge variant="outline" className="bg-purple-50 text-purple-700 font-mono text-xs">
                          {dotGuildConfig.dot_role_id}
                        </Badge>
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default EnterpriseManagement;