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
  Building, 
  Download, 
  Upload, 
  Settings, 
  Users, 
  DollarSign,
  FileText,
  Plus,
  Trash2,
  Save,
  ArrowLeft
} from 'lucide-react';
import { toast } from 'sonner';
import RoleGate from '../components/RoleGate';

const CompanyConfig = () => {
  const { userEntreprise, userRole } = useAuth();
  const [loading, setLoading] = useState(false);
  
  // Company configuration state
  const [companyConfig, setCompanyConfig] = useState({
    entreprise_key: userEntreprise || 'LSPD',
    salaire_base: 8000,
    prime_base: 2000,
    coefficients: {
      run: 1.2,
      facture: 1.0,
      vente: 0.8
    },
    bonus_paliers: [
      { seuil: 50000, bonus: 0.1 },
      { seuil: 100000, bonus: 0.15 }
    ],
    heures_travail: {
      min_hebdo: 35,
      max_hebdo: 50,
      taux_heures_sup: 1.5
    }
  });

  const [grades, setGrades] = useState([
    { 
      id: 1, 
      nom: 'Officier', 
      niveau: 1, 
      salaire_min: 5000, 
      salaire_max: 12000,
      taux_horaire: 45,
      role_discord_id: '123456789'
    },
    { 
      id: 2, 
      nom: 'Sergent', 
      niveau: 2, 
      salaire_min: 8000, 
      salaire_max: 18000,
      taux_horaire: 65,
      role_discord_id: '234567890'
    },
    { 
      id: 3, 
      nom: 'Lieutenant', 
      niveau: 3, 
      salaire_min: 12000, 
      salaire_max: 25000,
      taux_horaire: 85,
      role_discord_id: '345678901'
    }
  ]);

  const [employees, setEmployees] = useState([
    {
      id: 1,
      nom: 'Jean Dupont',
      discord_id: '123456789012345678',
      grade_id: 1,
      date_embauche: '2023-01-15',
      salaire_actuel: 8500,
      statut: 'Actif'
    },
    {
      id: 2,
      nom: 'Marie Martin',
      discord_id: '234567890123456789',
      grade_id: 2,
      date_embauche: '2023-03-20',
      salaire_actuel: 12000,
      statut: 'Actif'
    }
  ]);

  const [primeTiers, setPrimeTiers] = useState([
    { id: 1, seuil: 30000, prime: 2000, description: 'Prime performance mensuelle' },
    { id: 2, seuil: 60000, prime: 5000, description: 'Prime excellence trimestrielle' },
    { id: 3, seuil: 100000, prime: 10000, description: 'Prime leadership annuelle' }
  ]);

  const handleSaveConfig = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      toast.success('Configuration entreprise sauvegardée');
    } catch (error) {
      toast.error('Erreur lors de la sauvegarde');
    } finally {
      setLoading(false);
    }
  };

  const exportConfig = () => {
    const config = {
      companyConfig,
      grades,
      employees,
      primeTiers
    };
    
    const dataStr = JSON.stringify(config, null, 2);
    const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
    
    const exportFileDefaultName = `config_${userEntreprise}_${new Date().toISOString().split('T')[0]}.json`;
    
    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', dataUri);
    linkElement.setAttribute('download', exportFileDefaultName);
    linkElement.click();
    
    toast.success('Configuration exportée');
  };

  const importConfig = (event) => {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const config = JSON.parse(e.target.result);
        
        if (config.companyConfig) setCompanyConfig(config.companyConfig);
        if (config.grades) setGrades(config.grades);
        if (config.employees) setEmployees(config.employees);
        if (config.primeTiers) setPrimeTiers(config.primeTiers);
        
        toast.success('Configuration importée avec succès');
      } catch (error) {
        toast.error('Erreur lors de l\'import: fichier JSON invalide');
      }
    };
    reader.readAsText(file);
  };

  const addGrade = () => {
    const newGrade = {
      id: Date.now(),
      nom: '',
      niveau: grades.length + 1,
      salaire_min: 5000,
      salaire_max: 15000,
      taux_horaire: 50,
      role_discord_id: ''
    };
    setGrades([...grades, newGrade]);
  };

  const removeGrade = (id) => {
    setGrades(grades.filter(grade => grade.id !== id));
  };

  const updateGrade = (id, field, value) => {
    setGrades(grades.map(grade => 
      grade.id === id ? { ...grade, [field]: value } : grade
    ));
  };

  const addEmployee = () => {
    const newEmployee = {
      id: Date.now(),
      nom: '',
      discord_id: '',
      grade_id: grades[0]?.id || 1,
      date_embauche: new Date().toISOString().split('T')[0],
      salaire_actuel: 0,
      statut: 'Actif'
    };
    setEmployees([...employees, newEmployee]);
  };

  const removeEmployee = (id) => {
    setEmployees(employees.filter(emp => emp.id !== id));
  };

  const updateEmployee = (id, field, value) => {
    setEmployees(employees.map(emp => 
      emp.id === id ? { ...emp, [field]: value } : emp
    ));
  };

  const addPrimeTier = () => {
    const newTier = {
      id: Date.now(),
      seuil: 0,
      prime: 0,
      description: ''
    };
    setPrimeTiers([...primeTiers, newTier]);
  };

  const removePrimeTier = (id) => {
    setPrimeTiers(primeTiers.filter(tier => tier.id !== id));
  };

  const updatePrimeTier = (id, field, value) => {
    setPrimeTiers(primeTiers.map(tier => 
      tier.id === id ? { ...tier, [field]: value } : tier
    ));
  };

  return (
    <RoleGate requiredAccess="canAccessCompanyConfig">
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
                  <h1 className="text-3xl font-bold">Configuration Patron</h1>
                  <p className="text-muted-foreground mt-1">
                    Paramètres d'entreprise, grades et gestion des employés - {userEntreprise}
                  </p>
                </div>
              </div>
              <div className="flex items-center space-x-2">
                <Badge variant="outline" className="bg-green-50 text-green-700">
                  <Building className="w-3 h-3 mr-1" />
                  {userRole === 'patron' ? 'Patron' : 'Co-Patron'}
                </Badge>
                <Button onClick={exportConfig} variant="outline" size="sm">
                  <Download className="w-4 h-4 mr-2" />
                  Export
                </Button>
                <Label htmlFor="import-config" className="cursor-pointer">
                  <Button variant="outline" size="sm" asChild>
                    <span>
                      <Upload className="w-4 h-4 mr-2" />
                      Import
                    </span>
                  </Button>
                </Label>
                <Input
                  id="import-config"
                  type="file"
                  accept=".json"
                  className="hidden"
                  onChange={importConfig}
                />
                <Button onClick={handleSaveConfig} disabled={loading}>
                  <Save className="w-4 h-4 mr-2" />
                  Sauvegarder
                </Button>
              </div>
            </div>
          </div>
        </div>

        <div className="container mx-auto px-4 py-6">
          <Tabs defaultValue="config" className="w-full">
            <TabsList className="grid w-full grid-cols-4">
              <TabsTrigger value="config">Configuration</TabsTrigger>
              <TabsTrigger value="grades">Grades</TabsTrigger>
              <TabsTrigger value="employees">Employés</TabsTrigger>
              <TabsTrigger value="primes">Primes Tiers</TabsTrigger>
            </TabsList>

            {/* Company Configuration */}
            <TabsContent value="config" className="space-y-4">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Basic Settings */}
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center">
                      <Settings className="w-5 h-5 mr-2" />
                      Paramètres de Base
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div>
                      <Label htmlFor="salaire_base">Salaire de Base (€)</Label>
                      <Input
                        id="salaire_base"
                        type="number"
                        value={companyConfig.salaire_base}
                        onChange={(e) => setCompanyConfig(prev => ({ 
                          ...prev, 
                          salaire_base: parseFloat(e.target.value) || 0 
                        }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="prime_base">Prime de Base (€)</Label>
                      <Input
                        id="prime_base"
                        type="number"
                        value={companyConfig.prime_base}
                        onChange={(e) => setCompanyConfig(prev => ({ 
                          ...prev, 
                          prime_base: parseFloat(e.target.value) || 0 
                        }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="min_hebdo">Heures Min/Semaine</Label>
                      <Input
                        id="min_hebdo"
                        type="number"
                        value={companyConfig.heures_travail.min_hebdo}
                        onChange={(e) => setCompanyConfig(prev => ({ 
                          ...prev, 
                          heures_travail: { 
                            ...prev.heures_travail, 
                            min_hebdo: parseFloat(e.target.value) || 0 
                          }
                        }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="max_hebdo">Heures Max/Semaine</Label>
                      <Input
                        id="max_hebdo"
                        type="number"
                        value={companyConfig.heures_travail.max_hebdo}
                        onChange={(e) => setCompanyConfig(prev => ({ 
                          ...prev, 
                          heures_travail: { 
                            ...prev.heures_travail, 
                            max_hebdo: parseFloat(e.target.value) || 0 
                          }
                        }))}
                      />
                    </div>
                  </CardContent>
                </Card>

                {/* Coefficients */}
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center">
                      <DollarSign className="w-5 h-5 mr-2" />
                      Coefficients de Calcul
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div>
                      <Label htmlFor="coeff_run">Coefficient RUN</Label>
                      <Input
                        id="coeff_run"
                        type="number"
                        step="0.1"
                        value={companyConfig.coefficients.run}
                        onChange={(e) => setCompanyConfig(prev => ({ 
                          ...prev, 
                          coefficients: { 
                            ...prev.coefficients, 
                            run: parseFloat(e.target.value) || 0 
                          }
                        }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="coeff_facture">Coefficient FACTURE</Label>
                      <Input
                        id="coeff_facture"
                        type="number"
                        step="0.1"
                        value={companyConfig.coefficients.facture}
                        onChange={(e) => setCompanyConfig(prev => ({ 
                          ...prev, 
                          coefficients: { 
                            ...prev.coefficients, 
                            facture: parseFloat(e.target.value) || 0 
                          }
                        }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="coeff_vente">Coefficient VENTE</Label>
                      <Input
                        id="coeff_vente"
                        type="number"
                        step="0.1"
                        value={companyConfig.coefficients.vente}
                        onChange={(e) => setCompanyConfig(prev => ({ 
                          ...prev, 
                          coefficients: { 
                            ...prev.coefficients, 
                            vente: parseFloat(e.target.value) || 0 
                          }
                        }))}
                      />
                    </div>
                    <div>
                      <Label htmlFor="taux_heures_sup">Taux Heures Sup</Label>
                      <Input
                        id="taux_heures_sup"
                        type="number"
                        step="0.1"
                        value={companyConfig.heures_travail.taux_heures_sup}
                        onChange={(e) => setCompanyConfig(prev => ({ 
                          ...prev, 
                          heures_travail: { 
                            ...prev.heures_travail, 
                            taux_heures_sup: parseFloat(e.target.value) || 0 
                          }
                        }))}
                      />
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* Bonus Paliers */}
              <Card>
                <CardHeader>
                  <CardTitle>Paliers de Bonus</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2">
                    {companyConfig.bonus_paliers.map((palier, index) => (
                      <div key={index} className="flex items-center space-x-2">
                        <Label className="w-20">Seuil:</Label>
                        <Input
                          type="number"
                          value={palier.seuil}
                          onChange={(e) => {
                            const newPaliers = [...companyConfig.bonus_paliers];
                            newPaliers[index] = { ...palier, seuil: parseFloat(e.target.value) || 0 };
                            setCompanyConfig(prev => ({ ...prev, bonus_paliers: newPaliers }));
                          }}
                          className="w-32"
                        />
                        <Label className="w-20">Bonus:</Label>
                        <Input
                          type="number"
                          step="0.01"
                          value={palier.bonus}
                          onChange={(e) => {
                            const newPaliers = [...companyConfig.bonus_paliers];
                            newPaliers[index] = { ...palier, bonus: parseFloat(e.target.value) || 0 };
                            setCompanyConfig(prev => ({ ...prev, bonus_paliers: newPaliers }));
                          }}
                          className="w-32"
                        />
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => {
                            const newPaliers = companyConfig.bonus_paliers.filter((_, i) => i !== index);
                            setCompanyConfig(prev => ({ ...prev, bonus_paliers: newPaliers }));
                          }}
                        >
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    ))}
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => {
                        const newPaliers = [...companyConfig.bonus_paliers, { seuil: 0, bonus: 0 }];
                        setCompanyConfig(prev => ({ ...prev, bonus_paliers: newPaliers }));
                      }}
                    >
                      <Plus className="w-4 h-4 mr-2" />
                      Ajouter Palier
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Grades Management */}
            <TabsContent value="grades" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center">
                      <Users className="w-5 h-5 mr-2" />
                      Gestion des Grades
                    </span>
                    <Button onClick={addGrade}>
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
                          <th className="text-left p-2">Nom</th>
                          <th className="text-left p-2">Niveau</th>
                          <th className="text-left p-2">Salaire Min (€)</th>
                          <th className="text-left p-2">Salaire Max (€)</th>
                          <th className="text-left p-2">Taux/H (€)</th>
                          <th className="text-left p-2">Role Discord ID</th>
                          <th className="text-left p-2">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {grades.map((grade) => (
                          <tr key={grade.id} className="border-b">
                            <td className="p-2">
                              <Input
                                value={grade.nom}
                                onChange={(e) => updateGrade(grade.id, 'nom', e.target.value)}
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={grade.niveau}
                                onChange={(e) => updateGrade(grade.id, 'niveau', parseInt(e.target.value) || 0)}
                                className="w-20"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={grade.salaire_min}
                                onChange={(e) => updateGrade(grade.id, 'salaire_min', parseFloat(e.target.value) || 0)}
                                className="w-28"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={grade.salaire_max}
                                onChange={(e) => updateGrade(grade.id, 'salaire_max', parseFloat(e.target.value) || 0)}
                                className="w-28"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={grade.taux_horaire}
                                onChange={(e) => updateGrade(grade.id, 'taux_horaire', parseFloat(e.target.value) || 0)}
                                className="w-20"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                value={grade.role_discord_id}
                                onChange={(e) => updateGrade(grade.id, 'role_discord_id', e.target.value)}
                                className="w-36"
                              />
                            </td>
                            <td className="p-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => removeGrade(grade.id)}
                              >
                                <Trash2 className="w-4 h-4" />
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Employees Management */}
            <TabsContent value="employees" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center">
                      <Users className="w-5 h-5 mr-2" />
                      Gestion des Employés ({employees.length})
                    </span>
                    <Button onClick={addEmployee}>
                      <Plus className="w-4 h-4 mr-2" />
                      Nouvel Employé
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead>
                        <tr className="border-b">
                          <th className="text-left p-2">Nom</th>
                          <th className="text-left p-2">Discord ID</th>
                          <th className="text-left p-2">Grade</th>
                          <th className="text-left p-2">Date Embauche</th>
                          <th className="text-left p-2">Salaire (€)</th>
                          <th className="text-left p-2">Statut</th>
                          <th className="text-left p-2">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {employees.map((employee) => (
                          <tr key={employee.id} className="border-b">
                            <td className="p-2">
                              <Input
                                value={employee.nom}
                                onChange={(e) => updateEmployee(employee.id, 'nom', e.target.value)}
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                value={employee.discord_id}
                                onChange={(e) => updateEmployee(employee.id, 'discord_id', e.target.value)}
                                className="w-40"
                              />
                            </td>
                            <td className="p-2">
                              <select
                                value={employee.grade_id}
                                onChange={(e) => updateEmployee(employee.id, 'grade_id', parseInt(e.target.value))}
                                className="w-full p-2 border rounded"
                              >
                                {grades.map(grade => (
                                  <option key={grade.id} value={grade.id}>
                                    {grade.nom}
                                  </option>
                                ))}
                              </select>
                            </td>
                            <td className="p-2">
                              <Input
                                type="date"
                                value={employee.date_embauche}
                                onChange={(e) => updateEmployee(employee.id, 'date_embauche', e.target.value)}
                                className="w-36"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={employee.salaire_actuel}
                                onChange={(e) => updateEmployee(employee.id, 'salaire_actuel', parseFloat(e.target.value) || 0)}
                                className="w-24"
                              />
                            </td>
                            <td className="p-2">
                              <select
                                value={employee.statut}
                                onChange={(e) => updateEmployee(employee.id, 'statut', e.target.value)}
                                className="w-24 p-2 border rounded"
                              >
                                <option value="Actif">Actif</option>
                                <option value="Inactif">Inactif</option>
                                <option value="Congé">Congé</option>
                              </select>
                            </td>
                            <td className="p-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => removeEmployee(employee.id)}
                              >
                                <Trash2 className="w-4 h-4" />
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            {/* Prime Tiers */}
            <TabsContent value="primes" className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center">
                      <DollarSign className="w-5 h-5 mr-2" />
                      Primes par Tiers
                    </span>
                    <Button onClick={addPrimeTier}>
                      <Plus className="w-4 h-4 mr-2" />
                      Nouveau Tiers
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead>
                        <tr className="border-b">
                          <th className="text-left p-2">Seuil (€)</th>
                          <th className="text-left p-2">Prime (€)</th>
                          <th className="text-left p-2">Description</th>
                          <th className="text-left p-2">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {primeTiers.map((tier) => (
                          <tr key={tier.id} className="border-b">
                            <td className="p-2">
                              <Input
                                type="number"
                                value={tier.seuil}
                                onChange={(e) => updatePrimeTier(tier.id, 'seuil', parseFloat(e.target.value) || 0)}
                                className="w-28"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                type="number"
                                value={tier.prime}
                                onChange={(e) => updatePrimeTier(tier.id, 'prime', parseFloat(e.target.value) || 0)}
                                className="w-28"
                              />
                            </td>
                            <td className="p-2">
                              <Input
                                value={tier.description}
                                onChange={(e) => updatePrimeTier(tier.id, 'description', e.target.value)}
                                placeholder="Description de la prime..."
                              />
                            </td>
                            <td className="p-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => removePrimeTier(tier.id)}
                              >
                                <Trash2 className="w-4 h-4" />
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
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

export default CompanyConfig;