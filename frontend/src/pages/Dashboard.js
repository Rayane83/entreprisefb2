import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import Header from '../components/Header';
import DashboardSummary from '../components/DashboardSummary';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Badge } from '../components/ui/badge';
import { Textarea } from '../components/ui/textarea';
import RoleGate from '../components/RoleGate';
import { toast } from 'sonner';
import { 
  Users,
  Calculator,
  FileText,
  Download,
  Upload,
  Save,
  Send,
  Settings,
  Database,
  Archive,
  DollarSign,
  Building,
  AlertTriangle,
  Eye,
  Trash2,
  Copy,
  Plus
} from 'lucide-react';

// Composant Dotations avec zone collage et calculs
const DotationsTab = () => {
  const { userRole } = useAuth();
  const isStaff = userRole === 'staff';
  
  const [employees, setEmployees] = useState([
    {
      nom: 'Jean Dupont',
      grade: 'Sergent',
      run: 125000,
      facture: 75000,
      vente: 50000,
      caTotal: 250000,
      salaire: 85000,
      prime: 15000
    }
  ]);
  
  const [pasteData, setPasteData] = useState('');
  const [expenses, setExpenses] = useState([]);
  const [withdrawals, setWithdrawals] = useState([]);

  // Zone de collage : Format "Nom;RUN;FACTURE;VENTE"
  const handlePasteData = () => {
    if (!pasteData.trim()) {
      alert('Veuillez coller des données au format Nom;RUN;FACTURE;VENTE');
      return;
    }
    
    const lines = pasteData.split('\n').filter(line => line.trim());
    const newEmployees = [];
    
    lines.forEach(line => {
      const parts = line.split(/[;\t,]/).map(p => p.trim());
      if (parts.length >= 4) {
        const [nom, run, facture, vente] = parts;
        const runNum = parseInt(run) || 0;
        const factureNum = parseInt(facture) || 0;
        const venteNum = parseInt(vente) || 0;
        
        // Calcul auto : CA = RUN+FACTURE+VENTE
        const caTotal = runNum + factureNum + venteNum;
        
        // calculateFromPaliers(CA, paliers, isPatron) - simulation
        const salaire = Math.round(caTotal * 0.35); // 35% du CA
        const prime = Math.round(caTotal * 0.08);   // 8% du CA
        
        newEmployees.push({
          nom,
          grade: 'À définir',
          run: runNum,
          facture: factureNum,
          vente: venteNum,
          caTotal,
          salaire,
          prime
        });
      }
    });
    
    if (newEmployees.length > 0) {
      // Merge avec conservation de l'ordre
      setEmployees(prev => [...prev, ...newEmployees]);
      setPasteData('');
      alert(`${newEmployees.length} employés ajoutés avec succès !`);
    } else {
      alert('Aucune donnée valide trouvée. Format attendu : Nom;RUN;FACTURE;VENTE');
    }
  };

  const handleSaveDotation = () => {
    // Enregistrer (dotation_reports + dotation_rows)
    alert('Dotation sauvegardée !');
  };

  const handleSendToArchives = () => {
    // Envoyer aux archives (payload complet, statut "En attente")
    alert('Dotation envoyée aux archives avec statut "En attente"');
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Dotations</h2>
          <p className="text-muted-foreground">Table Employés, zone collage, calculs auto CA, exports PDF/Excel</p>
        </div>
        <div className="flex space-x-2">
          <Button variant="outline">
            <Download className="w-4 h-4 mr-2" />
            Export PDF (Fiche Impôt)
          </Button>
          <Button variant="outline">
            <FileText className="w-4 h-4 mr-2" />
            Export Excel (Multi-feuilles)
          </Button>
        </div>
      </div>

      {/* Zone de collage "Nom;RUN;FACTURE;VENTE" */}
      {!isStaff && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Upload className="w-5 h-5 mr-2" />
              Zone de collage données employés
            </CardTitle>
            <p className="text-sm text-muted-foreground">
              Format : <code>Nom;RUN;FACTURE;VENTE</code> (tab/virgule/; acceptés), ajoute/merge lignes, ordre conservé
            </p>
          </CardHeader>
          <CardContent className="space-y-4">
            <Textarea
              placeholder="Jean Dupont;125000;75000;50000&#10;Marie Martin;150000;80000;60000&#10;Pierre Moreau;200000;100000;75000"
              value={pasteData}
              onChange={(e) => setPasteData(e.target.value)}
              rows={4}
              className="font-mono text-sm"
            />
            <Button onClick={handlePasteData} disabled={!pasteData.trim()}>
              <Upload className="w-4 h-4 mr-2" />
              Importer et calculer automatiquement
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Table Employés avec colonnes : Nom | Grade | RUN | FACTURE | VENTE | CA TOTAL | Salaire | Prime */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Users className="w-5 h-5 mr-2" />
            Table Employés ({employees.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left p-4">Nom</th>
                  <th className="text-left p-4">Grade</th>
                  <th className="text-left p-4">RUN</th>
                  <th className="text-left p-4">FACTURE</th>
                  <th className="text-left p-4">VENTE</th>
                  <th className="text-left p-4">CA TOTAL</th>
                  <th className="text-left p-4">Salaire</th>
                  <th className="text-left p-4">Prime</th>
                </tr>
              </thead>
              <tbody>
                {employees.map((emp, index) => (
                  <tr key={index} className="border-b hover:bg-muted/50">
                    <td className="p-4 font-medium">{emp.nom}</td>
                    <td className="p-4">
                      <Badge variant="outline">{emp.grade}</Badge>
                    </td>
                    <td className="p-4">{emp.run.toLocaleString()}€</td>
                    <td className="p-4">{emp.facture.toLocaleString()}€</td>
                    <td className="p-4">{emp.vente.toLocaleString()}€</td>
                    <td className="p-4 font-bold text-blue-600">{emp.caTotal.toLocaleString()}€</td>
                    <td className="p-4 text-green-600">{emp.salaire.toLocaleString()}€</td>
                    <td className="p-4 text-purple-600">{emp.prime.toLocaleString()}€</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          
          {employees.length === 0 && (
            <div className="text-center py-8">
              <Users className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              <p className="text-muted-foreground">Aucun employé. Utilisez la zone de collage pour importer.</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Dépenses déductibles & Tableau des retraits */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Dépenses déductibles</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="text-sm">Date | Justificatif | Montant</div>
              <div className="border-2 border-dashed border-gray-300 rounded p-4 text-center text-gray-500">
                Aucune dépense enregistrée
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Tableau des retraits</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="text-sm">Date | Justificatif | Montant (totaux)</div>
              <div className="border-2 border-dashed border-gray-300 rounded p-4 text-center text-gray-500">
                Aucun retrait enregistré
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Boutons : Enregistrer / Envoyer aux archives */}
      {!isStaff && (
        <div className="flex justify-end space-x-2">
          <Button variant="outline" onClick={handleSaveDotation}>
            <Save className="w-4 h-4 mr-2" />
            Enregistrer (dotation_reports + dotation_rows)
          </Button>
          <Button onClick={handleSendToArchives}>
            <Send className="w-4 h-4 mr-2" />
            Envoyer aux archives (payload complet, statut "En attente")
          </Button>
        </div>
      )}

      {/* Staff : lecture seule */}
      {isStaff && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center">
            <AlertTriangle className="w-5 h-5 text-yellow-600 mr-2" />
            <span className="text-yellow-800">Accès staff : lecture seule (inputs + actions d'écriture désactivés)</span>
          </div>
        </div>
      )}
    </div>
  );
};

// Composant Impôts avec calculs réels
const ImpotsTab = () => {
  const { userRole, userEntreprise, isReadOnlyForStaff } = useAuth();
  const readonly = isReadOnlyForStaff();
  
  const [impotData, setImpotData] = useState({
    revenus_totaux: 250000,
    revenus_imposables: 200000,
    abattements: 50000,
    patrimoine: 150000,
    periode: '2024-Q1'
  });
  
  const [taxBrackets] = useState([
    { min: 0, max: 100000, taux: 0.10, type: 'revenus' },
    { min: 100001, max: 500000, taux: 0.15, type: 'revenus' },
    { min: 500001, max: null, taux: 0.20, type: 'revenus' }
  ]);
  
  const [wealthBrackets] = useState([
    { min: 0, max: 100000, taux: 0.05, type: 'patrimoine' },
    { min: 100001, max: 500000, taux: 0.10, type: 'patrimoine' },
    { min: 500001, max: null, taux: 0.15, type: 'patrimoine' }
  ]);
  
  const [loading, setLoading] = useState(false);
  
  // Calcul de l'impôt sur les revenus
  const calculateIncomeTax = () => {
    const baseImposable = Math.max(0, impotData.revenus_imposables - impotData.abattements);
    let impot = 0;
    let tranche = '';
    
    for (const bracket of taxBrackets) {
      if (baseImposable >= bracket.min && (bracket.max === null || baseImposable <= bracket.max)) {
        const montantTrancheMin = bracket.min;
        const montantTranche = baseImposable - montantTrancheMin;
        impot = montantTranche * bracket.taux;
        tranche = `${bracket.min.toLocaleString()}€ - ${bracket.max ? bracket.max.toLocaleString() + '€' : '∞'}`;
        break;
      }
    }
    
    return { impot: Math.round(impot), tranche, taux: taxBrackets.find(b => baseImposable >= b.min && (b.max === null || baseImposable <= b.max))?.taux * 100 || 0 };
  };
  
  // Calcul de l'impôt sur le patrimoine
  const calculateWealthTax = () => {
    let impot = 0;
    let tranche = '';
    
    for (const bracket of wealthBrackets) {
      if (impotData.patrimoine >= bracket.min && (bracket.max === null || impotData.patrimoine <= bracket.max)) {
        const montantTrancheMin = bracket.min;
        const montantTranche = impotData.patrimoine - montantTrancheMin;
        impot = montantTranche * bracket.taux;
        tranche = `${bracket.min.toLocaleString()}€ - ${bracket.max ? bracket.max.toLocaleString() + '€' : '∞'}`;
        break;
      }
    }
    
    return { impot: Math.round(impot), tranche, taux: wealthBrackets.find(b => impotData.patrimoine >= b.min && (b.max === null || impotData.patrimoine <= b.max))?.taux * 100 || 0 };
  };
  
  const incomeTax = calculateIncomeTax();
  const wealthTax = calculateWealthTax();
  const totalTax = incomeTax.impot + wealthTax.impot;
  
  const handleSave = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      toast.success('Déclaration d\'impôts sauvegardée');
    } catch (error) {
      toast.error('Erreur lors de la sauvegarde');
    } finally {
      setLoading(false);
    }
  };
  
  const handleExport = () => {
    try {
      const exportData = [{
        name: `Déclaration ${userEntreprise}`,
        income: impotData.revenus_imposables,
        wealth: impotData.patrimoine, 
        incomeTaxBracket: incomeTax.tranche,
        incomeTaxRate: incomeTax.taux,
        incomeTaxAmount: incomeTax.impot,
        wealthTaxBracket: wealthTax.tranche,
        wealthTaxRate: wealthTax.taux,
        wealthTaxAmount: wealthTax.impot,
        totalTax: totalTax,
        calculationDate: new Date().toLocaleDateString('fr-FR')
      }];
      
      // Utilisation de l'utilitaire d'export
      const { exportImpots } = require('../utils/excelExport');
      exportImpots(exportData, `impots_${userEntreprise}_${new Date().toISOString().split('T')[0]}.xlsx`);
      toast.success('Export Excel réussi');
    } catch (error) {
      console.error('Erreur export:', error);
      toast.error('Erreur lors de l\'export Excel');
    }
  };
  
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Déclaration d'Impôts</h2>
          <p className="text-muted-foreground">
            {userEntreprise && `Entreprise: ${userEntreprise}`} - Période: {impotData.periode}
            {readonly && " (Lecture seule - Staff)"}
          </p>
        </div>
        <div className="flex space-x-2">
          <Button onClick={handleExport} variant="outline">
            <Download className="w-4 h-4 mr-2" />
            Export Excel
          </Button>
          {!readonly && (
            <Button onClick={handleSave} disabled={loading}>
              <Save className="w-4 h-4 mr-2" />
              Sauvegarder
            </Button>
          )}
        </div>
      </div>

      {/* Formulaire de saisie */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Calculator className="w-5 h-5 mr-2" />
            Données Fiscales
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div>
                <Label htmlFor="revenus_totaux">Revenus Totaux (€)</Label>
                <Input
                  id="revenus_totaux"
                  type="number"
                  value={impotData.revenus_totaux}
                  onChange={(e) => setImpotData(prev => ({ ...prev, revenus_totaux: parseFloat(e.target.value) || 0 }))}
                  disabled={readonly}
                />
              </div>
              <div>
                <Label htmlFor="revenus_imposables">Revenus Imposables (€)</Label>
                <Input
                  id="revenus_imposables"
                  type="number"
                  value={impotData.revenus_imposables}
                  onChange={(e) => setImpotData(prev => ({ ...prev, revenus_imposables: parseFloat(e.target.value) || 0 }))}
                  disabled={readonly}
                />
              </div>
              <div>
                <Label htmlFor="abattements">Abattements (€)</Label>
                <Input
                  id="abattements"
                  type="number"
                  value={impotData.abattements}
                  onChange={(e) => setImpotData(prev => ({ ...prev, abattements: parseFloat(e.target.value) || 0 }))}
                  disabled={readonly}
                />
              </div>
            </div>
            <div className="space-y-4">
              <div>
                <Label htmlFor="patrimoine">Patrimoine Total (€)</Label>
                <Input
                  id="patrimoine"
                  type="number"
                  value={impotData.patrimoine}
                  onChange={(e) => setImpotData(prev => ({ ...prev, patrimoine: parseFloat(e.target.value) || 0 }))}
                  disabled={readonly}
                />
              </div>
              <div>
                <Label htmlFor="periode">Période</Label>
                <Input
                  id="periode"
                  value={impotData.periode}
                  onChange={(e) => setImpotData(prev => ({ ...prev, periode: e.target.value }))}
                  disabled={readonly}
                />
              </div>
              
              {/* Calculs en temps réel */}
              <div className="p-4 bg-primary/10 rounded-lg">
                <Label className="text-sm text-muted-foreground">Total Impôts à Payer</Label>
                <div className="text-3xl font-bold text-primary">
                  €{totalTax.toLocaleString()}
                </div>
                <div className="text-sm text-muted-foreground mt-1">
                  Revenus: €{incomeTax.impot.toLocaleString()} + Patrimoine: €{wealthTax.impot.toLocaleString()}
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Détail des calculs */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Impôt sur les Revenus</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <div className="flex justify-between">
                <span>Base imposable:</span>
                <span>€{Math.max(0, impotData.revenus_imposables - impotData.abattements).toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span>Tranche:</span>
                <span className="text-sm">{incomeTax.tranche}</span>
              </div>
              <div className="flex justify-between">
                <span>Taux appliqué:</span>
                <span>{incomeTax.taux}%</span>
              </div>
              <div className="flex justify-between font-bold border-t pt-2">
                <span>Impôt revenus:</span>
                <span>€{incomeTax.impot.toLocaleString()}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Impôt sur le Patrimoine</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <div className="flex justify-between">
                <span>Patrimoine total:</span>
                <span>€{impotData.patrimoine.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span>Tranche:</span>
                <span className="text-sm">{wealthTax.tranche}</span>
              </div>
              <div className="flex justify-between">
                <span>Taux appliqué:</span>
                <span>{wealthTax.taux}%</span>
              </div>
              <div className="flex justify-between font-bold border-t pt-2">
                <span>Impôt patrimoine:</span>
                <span>€{wealthTax.impot.toLocaleString()}</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Barèmes fiscaux */}
      <Card>
        <CardHeader>
          <CardTitle>Barèmes Fiscaux</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h4 className="font-medium mb-3">Impôt sur les Revenus</h4>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left p-2">Tranche (€)</th>
                      <th className="text-left p-2">Taux</th>
                    </tr>
                  </thead>
                  <tbody>
                    {taxBrackets.map((bracket, index) => (
                      <tr key={index} className="border-b">
                        <td className="p-2">
                          {bracket.min.toLocaleString()} - {bracket.max ? bracket.max.toLocaleString() : '∞'}
                        </td>
                        <td className="p-2">{(bracket.taux * 100).toFixed(1)}%</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
            
            <div>
              <h4 className="font-medium mb-3">Impôt sur le Patrimoine</h4>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left p-2">Tranche (€)</th>
                      <th className="text-left p-2">Taux</th>
                    </tr>
                  </thead>
                  <tbody>
                    {wealthBrackets.map((bracket, index) => (
                      <tr key={index} className="border-b">
                        <td className="p-2">
                          {bracket.min.toLocaleString()} - {bracket.max ? bracket.max.toLocaleString() : '∞'}
                        </td>
                        <td className="p-2">{(bracket.taux * 100).toFixed(1)}%</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Staff : lecture seule */}
      {readonly && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center">
            <AlertTriangle className="w-5 h-5 text-yellow-600 mr-2" />
            <span className="text-yellow-800">Accès staff : lecture seule (calculs et sauvegarde désactivés)</span>
          </div>
        </div>
      )}
    </div>
  );
};

// Autres onglets simples avec specs
const SimpleTab = ({ title, description, icon: Icon, specs }) => (
  <div className="space-y-6">
    <div>
      <h2 className="text-2xl font-bold">{title}</h2>
      <p className="text-muted-foreground">{description}</p>
    </div>
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center">
          <Icon className="w-5 h-5 mr-2" />
          {title}
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          <div className="text-center py-8">
            <Icon className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">{title}</h3>
            <p className="text-gray-500 mb-4">Module à développer selon spécifications</p>
          </div>
          
          {specs && (
            <div className="bg-blue-50 p-4 rounded-lg">
              <h4 className="font-medium mb-2">Spécifications :</h4>
              <ul className="text-sm space-y-1">
                {specs.map((spec, index) => (
                  <li key={index} className="flex items-start">
                    <span className="w-2 h-2 bg-blue-400 rounded-full mt-2 mr-2 flex-shrink-0"></span>
                    {spec}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  </div>
);

const Dashboard = () => {
  const { userRole } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  
  // Gestion des onglets basée sur le hash de l'URL
  const getActiveTab = () => {
    const hash = location.hash.replace('#', '');
    return hash || 'dashboard';
  };
  
  const [activeTab, setActiveTab] = useState(getActiveTab());
  
  useEffect(() => {
    setActiveTab(getActiveTab());
  }, [location.hash]);
  
  const handleTabChange = (value) => {
    setActiveTab(value);
    navigate(value === 'dashboard' ? '/' : `/#${value}`, { replace: true });
  };

  return (
    <div className="min-h-screen bg-background">
      <Header />
      
      <div className="container mx-auto px-4 py-6">
        <Tabs value={activeTab} onValueChange={handleTabChange} className="w-full">
          <TabsList className="grid w-full grid-cols-7">
            <TabsTrigger value="dashboard">Dashboard</TabsTrigger>
            <TabsTrigger value="dotations">Dotations</TabsTrigger>
            <TabsTrigger value="impots">Impôts</TabsTrigger>
            <TabsTrigger value="docs">Factures/Diplômes</TabsTrigger>
            <TabsTrigger value="blanchiment">Blanchiment</TabsTrigger>
            <TabsTrigger value="archives">Archives</TabsTrigger>
            {['staff'].includes(userRole) && (
              <TabsTrigger value="config">Config</TabsTrigger>
            )}
          </TabsList>

          {/* 1) Dashboard — Route : / */}
          <TabsContent value="dashboard" className="space-y-6">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-3xl font-bold">Dashboard</h1>
                <p className="text-muted-foreground">
                  Portail Entreprise Flashback Fa – Tableau de bord
                </p>
              </div>
            </div>
            <DashboardSummary />
          </TabsContent>

          {/* 2) Dotations — Route : /#dotations */}
          <TabsContent value="dotations" className="space-y-6">
            <RoleGate requiredAccess="canAccessDotation">
              <DotationsTab />
            </RoleGate>
          </TabsContent>

          {/* 3) Impôts — Route : /#impots */}
          <TabsContent value="impots" className="space-y-6">
            <RoleGate requiredAccess="canAccessImpot">
              <ImpotsTab />
            </RoleGate>
          </TabsContent>

          {/* 4) Factures / Diplômes — Route : /#docs */}
          <TabsContent value="docs" className="space-y-6">
            <SimpleTab 
              title="Factures / Diplômes" 
              description="Upload (filtres MIME/taille), liste, aperçu, suppression (avec confirm)"
              icon={FileText}
              specs={[
                "Upload avec filtres MIME/taille",
                "Liste des documents",
                "Aperçu des fichiers",
                "Suppression avec confirmation",
                "Stockage local/sécurisé (lecture rôle-based)",
                "Lazy loading, toasts"
              ]}
            />
          </TabsContent>

          {/* 5) Blanchiment — Route : /#blanchiment */}
          <TabsContent value="blanchiment" className="space-y-6">
            <RoleGate requiredAccess="canAccessBlanchiment">
              <SimpleTab 
                title="Blanchiment" 
                description="Toggle entreprise (enabled/use_global), pourcentages, table lignes CRUD"
                icon={DollarSign}
                specs={[
                  "Toggle entreprise (enabled/use_global)",
                  "Pourcentages (global vs local), lecture calculée",
                  "Table lignes : Statut | Date Reçu | Date Rendu | Durée (j) | Groupe | Employé | Donneur | Recep | Somme | % Entreprise | % Groupe",
                  "Cols % en read-only, tri created_at desc",
                  "CRUD local + Sauvegarder (upsert/insert)",
                  "Accès : staff lecture-seule",
                  "Exports : PDF 'BLANCHIMENT SUIVI' (50 lignes #1-50), Excel"
                ]}
              />
            </RoleGate>
          </TabsContent>

          {/* 6) Archives — Route : /#archives */}
          <TabsContent value="archives" className="space-y-6">
            <SimpleTab 
              title="Archives" 
              description="Recherche (debounce 300 ms), headers dynamiques, actions par ligne"
              icon={Archive}
              specs={[
                "Recherche (debounce 300 ms, JSON.stringify(row))",
                "Headers dynamiques",
                "Actions par ligne : Voir (modal), Éditer (date/montant/description)",
                "Valider / Refuser / Supprimer (staff)",
                "Droits d'édition : staff toujours ; patron/co-patron si statut contient 'refus'",
                "Export Excel : nommage archives_{entreprise|toutes}_{guild}_{YYYY-MM-DD}.xlsx",
                "Import template (staff) : mapping colonnes selon la 1ère ligne"
              ]}
            />
          </TabsContent>

          {/* 7) Config (Staff) — Route : /#config */}
          {['staff'].includes(userRole) && (
            <TabsContent value="config" className="space-y-6">
              <SimpleTab 
                title="Config Staff" 
                description="Paramètres intégration actuels (lecture/écriture réservée staff)"
                icon={Settings}
                specs={[
                  "Paramètres intégration actuels (lecture/écriture réservée staff)",
                  "Boutons de test/health si présent"
                ]}
              />
            </TabsContent>
          )}
        </Tabs>
      </div>
    </div>
  );
};

export default Dashboard;