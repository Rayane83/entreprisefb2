import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Badge } from '../components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';
import { Textarea } from '../components/ui/textarea';
import { 
  Shield, 
  Database, 
  Settings, 
  Users, 
  Building, 
  DollarSign,
  Percent,
  FileText,
  Plus,
  Trash2,
  Edit
} from 'lucide-react';
import { toast } from 'sonner';
import RoleGate from '../components/RoleGate';
import { mockDiscordConfig, mockEnterprises } from '../data/mockData';

const Superadmin = () => {
  const { userRole } = useAuth();
  const [loading, setLoading] = useState(false);
  
  // State for different configurations
  const [discordConfig, setDiscordConfig] = useState(mockDiscordConfig);
  const [enterprises, setEnterprises] = useState(mockEnterprises);
  const [taxBrackets, setTaxBrackets] = useState([
    { id: 1, min: 0, max: 50000, taux: 0.1, entreprise_key: 'LSPD' },
    { id: 2, min: 50001, max: 100000, taux: 0.15, entreprise_key: 'LSPD' }
  ]);
  const [wealthBrackets, setWealthBrackets] = useState([
    { id: 1, min: 0, max: 100000, taux: 0.1, entreprise_key: 'LSPD' },
    { id: 2, min: 100001, max: 500000, taux: 0.15, entreprise_key: 'LSPD' }
  ]);
  const [gradeRules, setGradeRules] = useState([
    { id: 1, grade: 'Officier', role_discord_id: '123456', taux_horaire: 50, pourcentage_ca: 0.1, entreprise_key: 'LSPD' }
  ]);
  const [primeTiers, setPrimeTiers] = useState([
    { id: 1, seuil: 50000, prime: 5000, entreprise_key: 'LSPD' }
  ]);
  const [blanchimentGlobal, setBlanchimentGlobal] = useState({
    perc_entreprise: 15,
    perc_groupe: 5
  });
  const [companyConfig, setCompanyConfig] = useState({
    config: JSON.stringify({
      salaire_base: 8000,
      prime_base: 2000,
      coefficients: {
        run: 1.2,
        facture: 1.0,
        vente: 0.8
      }
    }, null, 2)
  });

  const handleSave = async (section) => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      toast.success(`Configuration ${section} sauvegardée`);
    } catch (error) {
      toast.error(`Erreur lors de la sauvegarde ${section}`);
    } finally {
      setLoading(false);
    }
  };

  const addNewItem = (setter, template) => {
    setter(prev => [...prev, { ...template, id: Date.now() }]);
  };

  const removeItem = (setter, id) => {
    setter(prev => prev.filter(item => item.id !== id));
  };

  const updateItem = (setter, id, field, value) => {
    setter(prev => prev.map(item => 
      item.id === id ? { ...item, [field]: value } : item
    ));
  };

  return (
    <RoleGate requiredAccess="canAccessStaffConfig">
      <div className="min-h-screen bg-background">
        {/* Header */}
        <div className="border-b bg-card">
          <div className="container mx-auto px-4 py-6">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-3xl font-bold">SuperStaff Configuration</h1>
                <p className="text-muted-foreground mt-1">
                  Panneau de configuration central pour la gestion système
                </p>
              </div>
              <Badge variant="outline" className="bg-red-50 text-red-700">
                <Shield className="w-3 h-3 mr-1" />
                SuperStaff Access
              </Badge>
            </div>
          </div>
        </div>

        <div className="container mx-auto px-4 py-6">
          <Tabs defaultValue="discord" className="w-full">
            <TabsList className="grid w-full grid-cols-7">
              <TabsTrigger value="discord">Discord</TabsTrigger>
              <TabsTrigger value="enterprises">Entreprises</TabsTrigger>
              <TabsTrigger value="tax">Paliers Dotations</TabsTrigger>
              <TabsTrigger value="wealth">Impôt Fortune</TabsTrigger>
              <TabsTrigger value="grades">Grades</TabsTrigger>
              <TabsTrigger value="blanchiment">Blanchiment</TabsTrigger>
              <TabsTrigger value="config">Config JSON</TabsTrigger>
            </TabsList>

            {/* Discord Configuration */}
            <TabsContent value="discord" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <Users className="w-5 h-5 mr-2" />
                    Configuration Discord & Guildes
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="principal_guild">ID Guilde Principal</Label>
                      <Input
                        id="principal_guild"
                        value={discordConfig.principalGuildId}
                        onChange={(e) => setDiscordConfig(prev => ({ 
                          ...prev, 
                          principalGuildId: e.target.value 
                        }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="dot_guild">ID Guilde DOT</Label>
                      <Input
                        id="dot_guild"
                        value={discordConfig.dot.guildId}
                        onChange={(e) => setDiscordConfig(prev => ({ 
                          ...prev, 
                          dot: { ...prev.dot, guildId: e.target.value }
                        }))}
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label>Entreprises Mappées</Label>
                    <div className="space-y-2">
                      {discordConfig.enterprises.map((enterprise, index) => (
                        <div key={index} className="flex items-center space-x-2 p-2 border rounded">
                          <Input
                            placeholder="Clé"
                            value={enterprise.key}
                            onChange={(e) => {
                              const newEnterprises = [...discordConfig.enterprises];
                              newEnterprises[index] = { ...enterprise, key: e.target.value };
                              setDiscordConfig(prev => ({ ...prev, enterprises: newEnterprises }));
                            }}
                            className="w-20"
                          />
                          <Input
                            placeholder="Nom"
                            value={enterprise.name}
                            onChange={(e) => {
                              const newEnterprises = [...discordConfig.enterprises];
                              newEnterprises[index] = { ...enterprise, name: e.target.value };
                              setDiscordConfig(prev => ({ ...prev, enterprises: newEnterprises }));
                            }}
                            className="flex-1"
                          />
                          <Input
                            placeholder="Role ID"
                            value={enterprise.role_id}
                            onChange={(e) => {
                              const newEnterprises = [...discordConfig.enterprises];
                              newEnterprises[index] = { ...enterprise, role_id: e.target.value };
                              setDiscordConfig(prev => ({ ...prev, enterprises: newEnterprises }));
                            }}
                            className="w-32"
                          />
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              const newEnterprises = discordConfig.enterprises.filter((_, i) => i !== index);
                              setDiscordConfig(prev => ({ ...prev, enterprises: newEnterprises }));
                            }}
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                      ))}
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => {
                        const newEnterprise = { key: '', name: '', guildId: discordConfig.principalGuildId, role_id: '', employee_role_id: '' };
                        setDiscordConfig(prev => ({ 
                          ...prev, 
                          enterprises: [...prev.enterprises, newEnterprise]
                        }));
                      }}
                    >
                      <Plus className="w-4 h-4 mr-2" />
                      Ajouter Entreprise
                    </Button>
                  </div>

                  <div className="flex space-x-2">
                    <Button onClick={() => handleSave('Discord')} disabled={loading}>
                      <Database className="w-4 h-4 mr-2" />
                      Sauvegarder
                    </Button>
                    <Button variant="outline">
                      <Users className="w-4 h-4 mr-2" />
                      Tester Webhooks
                    </Button>
                    <Button variant="outline">
                      <Shield className="w-4 h-4 mr-2" />
                      Sync Rôles Discord
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Enterprises Management */}
            <TabsContent value="enterprises" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center">
                      <Building className="w-5 h-5 mr-2" />
                      Gestion des Entreprises
                    </span>
                    <Button
                      onClick={() => addNewItem(setEnterprises, {
                        guild_id: discordConfig.principalGuildId,
                        key: '',
                        name: '',
                        role_id: '',
                        employee_role_id: ''
                      })}
                    >
                      <Plus className="w-4 h-4 mr-2" />
                      Nouvelle Entreprise
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead>
                        <tr className="border-b">
                          <th className="text-left p-2">Guild ID</th>
                          <th className="text-left p-2">Clé</th>
                          <th className="text-left p-2">Nom</th>
                          <th className="text-left p-2">Role ID</th>
                          <th className="text-left p-2">Employee Role ID</th>
                          <th className="text-left p-2">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {enterprises.map((enterprise) => (
                          <tr key={enterprise.id} className="border-b">
                            <td className="p-2">
                              <Input
                                value={enterprise.guild_id}
                                onChange={(e) => updateItem(setEnterprises, enterprise.id, 'guild_id', e.target.value)}
                                className="w-40"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                value={enterprise.key}
                                onChange={(e) => updateItem(setEnterprises, enterprise.id, 'key', e.target.value)}
                                className="w-20"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                value={enterprise.name}
                                onChange={(e) => updateItem(setEnterprises, enterprise.id, 'name', e.target.value)}
                                className="min-w-0"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                value={enterprise.role_id}
                                onChange={(e) => updateItem(setEnterprises, enterprise.id, 'role_id', e.target.value)}
                                className="w-32"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                value={enterprise.employee_role_id}
                                onChange={(e) => updateItem(setEnterprises, enterprise.id, 'employee_role_id', e.target.value)}
                                className="w-32"
                              />
                            </td>
                            <td className="p-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => removeItem(setEnterprises, enterprise.id)}
                              >
                                <Trash2 className="w-4 h-4" />
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                  <div className="mt-4">
                    <Button onClick={() => handleSave('Entreprises')} disabled={loading}>
                      <Database className="w-4 h-4 mr-2" />
                      Sauvegarder Entreprises
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Tax Brackets */}
            <TabsContent value="tax" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center">
                      <DollarSign className="w-5 h-5 mr-2" />
                      Paliers Dotations (tax_brackets)
                    </span>
                    <Button
                      onClick={() => addNewItem(setTaxBrackets, {
                        min: 0,
                        max: null,
                        taux: 0.1,
                        entreprise_key: 'LSPD',
                        sal_min_emp: 5000,
                        sal_max_emp: 15000,
                        sal_min_pat: 8000,
                        sal_max_pat: 25000,
                        pr_min_emp: 0,
                        pr_max_emp: 5000,
                        pr_min_pat: 0,
                        pr_max_pat: 10000
                      })}
                    >
                      <Plus className="w-4 h-4 mr-2" />
                      Nouveau Palier
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b">
                          <th className="text-left p-2">Entreprise</th>
                          <th className="text-left p-2">Min (€)</th>
                          <th className="text-left p-2">Max (€)</th>
                          <th className="text-left p-2">Taux</th>
                          <th className="text-left p-2">Sal Min Emp</th>
                          <th className="text-left p-2">Sal Max Emp</th>
                          <th className="text-left p-2">Sal Min Pat</th>
                          <th className="text-left p-2">Sal Max Pat</th>
                          <th className="text-left p-2">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {taxBrackets.map((bracket) => (
                          <tr key={bracket.id} className="border-b">
                            <td className="p-2">
                              <Input
                                value={bracket.entreprise_key}
                                onChange={(e) => updateItem(setTaxBrackets, bracket.id, 'entreprise_key', e.target.value)}
                                className="w-16"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={bracket.min}
                                onChange={(e) => updateItem(setTaxBrackets, bracket.id, 'min', parseFloat(e.target.value) || 0)}
                                className="w-20"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={bracket.max || ''}
                                onChange={(e) => updateItem(setTaxBrackets, bracket.id, 'max', e.target.value ? parseFloat(e.target.value) : null)}
                                className="w-20"
                                placeholder="∞"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                step="0.01"
                                value={bracket.taux}
                                onChange={(e) => updateItem(setTaxBrackets, bracket.id, 'taux', parseFloat(e.target.value) || 0)}
                                className="w-16"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={bracket.sal_min_emp || ''}
                                onChange={(e) => updateItem(setTaxBrackets, bracket.id, 'sal_min_emp', parseFloat(e.target.value) || 0)}
                                className="w-20"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={bracket.sal_max_emp || ''}
                                onChange={(e) => updateItem(setTaxBrackets, bracket.id, 'sal_max_emp', parseFloat(e.target.value) || 0)}
                                className="w-20"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={bracket.sal_min_pat || ''}
                                onChange={(e) => updateItem(setTaxBrackets, bracket.id, 'sal_min_pat', parseFloat(e.target.value) || 0)}
                                className="w-20"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={bracket.sal_max_pat || ''}
                                onChange={(e) => updateItem(setTaxBrackets, bracket.id, 'sal_max_pat', parseFloat(e.target.value) || 0)}
                                className="w-20"
                              />
                            </td>
                            <td className="p-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => removeItem(setTaxBrackets, bracket.id)}
                              >
                                <Trash2 className="w-4 h-4" />
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                  <div className="mt-4">
                    <Button onClick={() => handleSave('Paliers Dotations')} disabled={loading}>
                      <Database className="w-4 h-4 mr-2" />
                      Sauvegarder Paliers
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Wealth Brackets */}
            <TabsContent value="wealth" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center">
                      <Percent className="w-5 h-5 mr-2" />
                      Impôt sur la Fortune (wealth_brackets)
                    </span>
                    <Button
                      onClick={() => addNewItem(setWealthBrackets, {
                        min: 0,
                        max: null,
                        taux: 0.1,
                        entreprise_key: 'LSPD'
                      })}
                    >
                      <Plus className="w-4 h-4 mr-2" />
                      Nouveau Palier
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead>
                        <tr className="border-b">
                          <th className="text-left p-2">Entreprise</th>
                          <th className="text-left p-2">Min (€)</th>
                          <th className="text-left p-2">Max (€)</th>
                          <th className="text-left p-2">Taux (%)</th>
                          <th className="text-left p-2">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {wealthBrackets.map((bracket) => (
                          <tr key={bracket.id} className="border-b">
                            <td className="p-2">
                              <Input
                                value={bracket.entreprise_key}
                                onChange={(e) => updateItem(setWealthBrackets, bracket.id, 'entreprise_key', e.target.value)}
                                className="w-20"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={bracket.min}
                                onChange={(e) => updateItem(setWealthBrackets, bracket.id, 'min', parseFloat(e.target.value) || 0)}
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={bracket.max || ''}
                                onChange={(e) => updateItem(setWealthBrackets, bracket.id, 'max', e.target.value ? parseFloat(e.target.value) : null)}
                                placeholder="∞"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                step="0.01"
                                value={bracket.taux * 100}
                                onChange={(e) => updateItem(setWealthBrackets, bracket.id, 'taux', (parseFloat(e.target.value) || 0) / 100)}
                              />
                            </td>
                            <td className="p-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => removeItem(setWealthBrackets, bracket.id)}
                              >
                                <Trash2 className="w-4 h-4" />
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                  <div className="mt-4">
                    <Button onClick={() => handleSave('Impôt Fortune')} disabled={loading}>
                      <Database className="w-4 h-4 mr-2" />
                      Sauvegarder Paliers
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Grades */}
            <TabsContent value="grades" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center">
                      <Users className="w-5 h-5 mr-2" />
                      Règles de Grade (grade_rules)
                    </span>
                    <Button
                      onClick={() => addNewItem(setGradeRules, {
                        grade: '',
                        role_discord_id: '',
                        taux_horaire: 0,
                        pourcentage_ca: 0,
                        entreprise_key: 'LSPD'
                      })}
                    >
                      <Plus className="w-4 h-4 mr-2" />
                      Nouveau Grade
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead>
                        <tr className="border-b">
                          <th className="text-left p-2">Entreprise</th>
                          <th className="text-left p-2">Grade</th>
                          <th className="text-left p-2">Role Discord ID</th>
                          <th className="text-left p-2">Taux Horaire (€)</th>
                          <th className="text-left p-2">Pourcentage CA (%)</th>
                          <th className="text-left p-2">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {gradeRules.map((grade) => (
                          <tr key={grade.id} className="border-b">
                            <td className="p-2">
                              <Input
                                value={grade.entreprise_key}
                                onChange={(e) => updateItem(setGradeRules, grade.id, 'entreprise_key', e.target.value)}
                                className="w-20"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                value={grade.grade}
                                onChange={(e) => updateItem(setGradeRules, grade.id, 'grade', e.target.value)}
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                value={grade.role_discord_id}
                                onChange={(e) => updateItem(setGradeRules, grade.id, 'role_discord_id', e.target.value)}
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={grade.taux_horaire}
                                onChange={(e) => updateItem(setGradeRules, grade.id, 'taux_horaire', parseFloat(e.target.value) || 0)}
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                step="0.01"
                                value={grade.pourcentage_ca * 100}
                                onChange={(e) => updateItem(setGradeRules, grade.id, 'pourcentage_ca', (parseFloat(e.target.value) || 0) / 100)}
                              />
                            </td>
                            <td className="p-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => removeItem(setGradeRules, grade.id)}
                              >
                                <Trash2 className="w-4 h-4" />
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                  <div className="mt-4">
                    <Button onClick={() => handleSave('Grades')} disabled={loading}>
                      <Database className="w-4 h-4 mr-2" />
                      Sauvegarder Grades
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Blanchiment */}
            <TabsContent value="blanchiment" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <Shield className="w-5 h-5 mr-2" />
                    Configuration Blanchiment
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <h4 className="font-medium mb-2">Paramètres Globaux</h4>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <Label htmlFor="global_perc_entreprise">Pourcentage Entreprise (%)</Label>
                        <Input
                          id="global_perc_entreprise"
                          type="number"
                          value={blanchimentGlobal.perc_entreprise}
                          onChange={(e) => setBlanchimentGlobal(prev => ({ 
                            ...prev, 
                            perc_entreprise: parseFloat(e.target.value) || 0 
                          }))}
                        />
                      </div>
                      <div>
                        <Label htmlFor="global_perc_groupe">Pourcentage Groupe (%)</Label>
                        <Input
                          id="global_perc_groupe"
                          type="number"
                          value={blanchimentGlobal.perc_groupe}
                          onChange={(e) => setBlanchimentGlobal(prev => ({ 
                            ...prev, 
                            perc_groupe: parseFloat(e.target.value) || 0 
                          }))}
                        />
                      </div>
                    </div>
                  </div>
                  
                  <div className="mt-4">
                    <Button onClick={() => handleSave('Blanchiment')} disabled={loading}>
                      <Database className="w-4 h-4 mr-2" />
                      Sauvegarder Configuration
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Company Config JSON */}
            <TabsContent value="config" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <FileText className="w-5 h-5 mr-2" />
                    Configuration JSON Entreprise
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <Label htmlFor="config_json">Configuration JSON</Label>
                    <Textarea
                      id="config_json"
                      value={companyConfig.config}
                      onChange={(e) => setCompanyConfig(prev => ({ 
                        ...prev, 
                        config: e.target.value 
                      }))}
                      rows={15}
                      className="font-mono text-sm"
                      placeholder="Configuration JSON..."
                    />
                  </div>
                  
                  <div className="flex space-x-2">
                    <Button onClick={() => handleSave('Config JSON')} disabled={loading}>
                      <Database className="w-4 h-4 mr-2" />
                      Sauvegarder JSON
                    </Button>
                    <Button 
                      variant="outline"
                      onClick={() => {
                        try {
                          JSON.parse(companyConfig.config);
                          toast.success('JSON valide');
                        } catch (error) {
                          toast.error('JSON invalide: ' + error.message);
                        }
                      }}
                    >
                      <Settings className="w-4 h-4 mr-2" />
                      Valider JSON
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </RoleGate>
  );
};

export default Superadmin;