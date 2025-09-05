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
import ConfigStaffTab from '../components/StaffConfig';
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

// Composant Factures/Diplômes complet avec upload
const FacturesDiplomesTab = () => {
  const { userRole, userEntreprise, isReadOnlyForStaff } = useAuth();
  const readonly = isReadOnlyForStaff();
  
  const [documents, setDocuments] = useState([
    {
      id: 1,
      name: 'Facture_Janvier_2024.pdf',
      type: 'Facture',
      size: 245000,
      date: '2024-01-25',
      url: '#',
      mimeType: 'application/pdf'
    },
    {
      id: 2,
      name: 'Diplome_Formation_Securite.pdf',
      type: 'Diplôme',
      size: 892000,
      date: '2024-01-20',
      url: '#',
      mimeType: 'application/pdf'
    }
  ]);
  
  const [uploading, setUploading] = useState(false);
  const [dragOver, setDragOver] = useState(false);
  const [previewDoc, setPreviewDoc] = useState(null);
  const [loading, setLoading] = useState(false);
  
  // Types de fichiers acceptés
  const acceptedTypes = {
    'application/pdf': '.pdf',
    'application/msword': '.doc',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '.docx', 
    'image/jpeg': '.jpg,.jpeg',
    'image/png': '.png',
    'image/gif': '.gif'
  };
  
  const maxFileSize = 10 * 1024 * 1024; // 10MB
  
  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };
  
  const getDocType = (filename) => {
    const lower = filename.toLowerCase();
    if (lower.includes('facture') || lower.includes('invoice')) return 'Facture';
    if (lower.includes('diplome') || lower.includes('certificate') || lower.includes('cert')) return 'Diplôme';
    if (lower.includes('contrat') || lower.includes('contract')) return 'Contrat';
    if (lower.includes('rapport') || lower.includes('report')) return 'Rapport';
    return 'Document';
  };
  
  const validateFile = (file) => {
    if (!Object.keys(acceptedTypes).includes(file.type)) {
      return { valid: false, error: `Type de fichier non autorisé: ${file.type}` };
    }
    
    if (file.size > maxFileSize) {
      return { valid: false, error: `Fichier trop volumineux: ${formatFileSize(file.size)}. Maximum: ${formatFileSize(maxFileSize)}` };
    }
    
    return { valid: true };
  };
  
  const handleFileUpload = async (files) => {
    if (readonly) {
      toast.error('Action non autorisée en mode lecture seule');
      return;
    }
    
    setUploading(true);
    const validFiles = [];
    const errors = [];
    
    // Validation des fichiers
    for (const file of files) {
      const validation = validateFile(file);
      if (validation.valid) {
        validFiles.push(file);
      } else {
        errors.push(`${file.name}: ${validation.error}`);
      }
    }
    
    if (errors.length > 0) {
      toast.error(`Erreurs: ${errors.join(', ')}`);
    }
    
    if (validFiles.length === 0) {
      setUploading(false);
      return;
    }
    
    try {
      // Simulation upload avec progress
      for (let i = 0; i < validFiles.length; i++) {
        const file = validFiles[i];
        
        // Simulation délai upload
        await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));
        
        const newDoc = {
          id: Date.now() + Math.random(),
          name: file.name,
          type: getDocType(file.name),
          size: file.size,
          date: new Date().toISOString().split('T')[0],
          url: URL.createObjectURL(file),
          mimeType: file.type
        };
        
        setDocuments(prev => [newDoc, ...prev]);
        toast.success(`${file.name} téléchargé avec succès`);
      }
      
      if (validFiles.length > 1) {
        toast.success(`${validFiles.length} documents téléchargés au total`);
      }
    } catch (error) {
      toast.error('Erreur lors du téléchargement');
    } finally {
      setUploading(false);
    }
  };
  
  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    const files = Array.from(e.dataTransfer.files);
    handleFileUpload(files);
  };
  
  const handleFileInput = (e) => {
    const files = Array.from(e.target.files);
    handleFileUpload(files);
    e.target.value = ''; // Reset input
  };
  
  const handleDelete = async (id) => {
    if (readonly) {
      toast.error('Action non autorisée en mode lecture seule');
      return;
    }
    
    const doc = documents.find(d => d.id === id);
    if (!doc) return;
    
    if (!window.confirm(`Êtes-vous sûr de vouloir supprimer "${doc.name}" ?`)) {
      return;
    }
    
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 500));
      setDocuments(prev => prev.filter(d => d.id !== id));
      toast.success(`${doc.name} supprimé`);
    } catch (error) {
      toast.error('Erreur lors de la suppression');
    } finally {
      setLoading(false);
    }
  };
  
  const handlePreview = (doc) => {
    setPreviewDoc(doc);
    toast.info(`Aperçu de ${doc.name}`);
  };
  
  const handleDownload = (doc) => {
    const link = document.createElement('a');
    link.href = doc.url;
    link.download = doc.name;
    link.click();
    toast.success(`Téléchargement de ${doc.name}`);
  };
  
  const getTypeColor = (type) => {
    switch (type) {
      case 'Facture': return 'bg-blue-100 text-blue-800';
      case 'Diplôme': return 'bg-green-100 text-green-800';
      case 'Contrat': return 'bg-purple-100 text-purple-800';
      case 'Rapport': return 'bg-orange-100 text-orange-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };
  
  const stats = {
    factures: documents.filter(d => d.type === 'Facture').length,
    diplomes: documents.filter(d => d.type === 'Diplôme').length,
    contrats: documents.filter(d => d.type === 'Contrat').length,
    total: documents.length
  };
  
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Factures / Diplômes</h2>
          <p className="text-muted-foreground">
            {userEntreprise && `Entreprise: ${userEntreprise}`} - Gestion des documents
            {readonly && " (Lecture seule - Staff)"}
          </p>
        </div>
        <div className="flex space-x-2">
          <Badge variant="outline" className="text-sm">
            {documents.length} document{documents.length !== 1 ? 's' : ''}
          </Badge>
        </div>
      </div>

      {/* Zone d'upload */}
      {!readonly && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Upload className="w-5 h-5 mr-2" />
              Zone de Téléchargement
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div
              className={`border-2 border-dashed rounded-lg p-8 text-center transition-colors ${
                dragOver 
                  ? 'border-primary bg-primary/5' 
                  : 'border-muted-foreground/25 hover:border-primary/50'
              }`}
              onDrop={handleDrop}
              onDragOver={(e) => {
                e.preventDefault();
                setDragOver(true);
              }}
              onDragLeave={() => setDragOver(false)}
            >
              <Upload className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              <h3 className="text-lg font-medium mb-2">
                Glissez vos fichiers ici ou cliquez pour parcourir
              </h3>
              <p className="text-muted-foreground mb-4">
                Formats acceptés: PDF, DOC, DOCX, JPG, PNG, GIF (Max {formatFileSize(maxFileSize)})
              </p>
              <div className="flex items-center justify-center space-x-4">
                <Label htmlFor="file-upload" className="cursor-pointer">
                  <Button disabled={uploading} asChild>
                    <span>
                      {uploading ? (
                        <>
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                          Téléchargement...
                        </>
                      ) : (
                        <>
                          <Upload className="w-4 h-4 mr-2" />
                          Parcourir les fichiers
                        </>
                      )}
                    </span>
                  </Button>
                </Label>
                <Input
                  id="file-upload"
                  type="file"
                  multiple
                  className="hidden"
                  onChange={handleFileInput}
                  accept={Object.values(acceptedTypes).join(',')}
                />
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Statistiques */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold text-blue-600">{stats.factures}</div>
            <div className="text-sm text-muted-foreground">Factures</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold text-green-600">{stats.diplomes}</div>
            <div className="text-sm text-muted-foreground">Diplômes</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold text-purple-600">{stats.contrats}</div>
            <div className="text-sm text-muted-foreground">Contrats</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold">{stats.total}</div>
            <div className="text-sm text-muted-foreground">Total</div>
          </CardContent>
        </Card>
      </div>

      {/* Liste des documents */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <FileText className="w-5 h-5 mr-2" />
            Documents ({documents.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {documents.length === 0 ? (
            <div className="text-center py-8">
              <FileText className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              <p className="text-muted-foreground">Aucun document téléchargé</p>
              {readonly && (
                <p className="text-sm text-yellow-600 mt-2">Mode lecture seule - Téléchargement désactivé</p>
              )}
            </div>
          ) : (
            <div className="space-y-3">
              {documents.map((doc) => (
                <div key={doc.id} className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/50 transition-colors">
                  <div className="flex items-center space-x-4 flex-1">
                    <FileText className="w-8 h-8 text-primary" />
                    <div className="flex-1">
                      <div className="flex items-center space-x-2">
                        <span className="font-medium">{doc.name}</span>
                        <Badge className={getTypeColor(doc.type)}>
                          {doc.type}
                        </Badge>
                      </div>
                      <div className="text-sm text-muted-foreground">
                        {formatFileSize(doc.size)} • Téléchargé le {new Date(doc.date).toLocaleDateString('fr-FR')}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handlePreview(doc)}
                      title="Aperçu"
                    >
                      <Eye className="w-4 h-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleDownload(doc)}
                      title="Télécharger"
                    >
                      <Download className="w-4 h-4" />
                    </Button>
                    {!readonly && (
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDelete(doc.id)}
                        className="text-destructive hover:text-destructive"
                        title="Supprimer"
                        disabled={loading}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Staff : lecture seule */}
      {readonly && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center">
            <AlertTriangle className="w-5 h-5 text-yellow-600 mr-2" />
            <span className="text-yellow-800">Accès staff : lecture seule (téléchargement et suppression désactivés)</span>
          </div>
        </div>
      )}
    </div>
  );
};

// Composant Blanchiment complet avec toggle et CRUD 
const BlanchimentTab = () => {
  const { userRole, userEntreprise, isReadOnlyForStaff, canAccessStaffConfig } = useAuth();
  const readonly = isReadOnlyForStaff();
  const canManageSettings = canAccessStaffConfig(); // Seul le staff peut activer/désactiver
  
  const [blanchimentEnabled, setBlanchimentEnabled] = useState(true);
  const [useGlobal, setUseGlobal] = useState(true);
  const [globalSettings, setGlobalSettings] = useState({
    perc_entreprise: 15,
    perc_groupe: 5
  });
  const [localSettings, setLocalSettings] = useState({
    perc_entreprise: 12,
    perc_groupe: 8
  });
  
  const [rows, setRows] = useState([
    {
      id: '1',
      statut: 'En cours',
      date_recu: '2024-01-15',
      date_rendu: '',
      duree: null,
      groupe: 'Alpha',
      employe: 'Jean Dupont',
      donneur: 'ID123456',
      recep: 'ID789012',
      somme: 50000,
      entreprise_perc: 15,
      groupe_perc: 5,
      created_at: '2024-01-15T10:00:00Z'
    },
    {
      id: '2',
      statut: 'Terminé',
      date_recu: '2024-01-10',
      date_rendu: '2024-01-20',
      duree: 10,
      groupe: 'Beta',
      employe: 'Marie Martin',
      donneur: 'ID345678',
      recep: 'ID901234',
      somme: 75000,
      entreprise_perc: 15,
      groupe_perc: 5,
      created_at: '2024-01-10T14:30:00Z'
    }
  ]);
  
  const [newRow, setNewRow] = useState({
    statut: 'En cours',
    date_recu: '',
    date_rendu: '',
    groupe: '',
    employe: '',
    donneur: '',
    recep: '',
    somme: 0
  });
  
  const [loading, setLoading] = useState(false);
  const [pasteData, setPasteData] = useState('');
  const [showPasteArea, setShowPasteArea] = useState(false);
  
  const currentSettings = useGlobal ? globalSettings : localSettings;
  
  // Calcul de la durée entre deux dates
  const calculateDuration = (dateRecu, dateRendu) => {
    if (!dateRecu || !dateRendu) return null;
    const start = new Date(dateRecu);
    const end = new Date(dateRendu);
    const diffTime = Math.abs(end - start);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  };
  
  // Gestion des changements sur une ligne
  const handleRowChange = (id, field, value) => {
    setRows(prev => prev.map(row => {
      if (row.id === id) {
        const updated = { ...row, [field]: value };
        
        // Recalculer la durée si les dates changent
        if (field === 'date_recu' || field === 'date_rendu') {
          updated.duree = calculateDuration(updated.date_recu, updated.date_rendu);
        }
        
        // Mettre à jour les pourcentages depuis les paramètres actuels
        updated.entreprise_perc = currentSettings.perc_entreprise;
        updated.groupe_perc = currentSettings.perc_groupe;
        
        return updated;
      }
      return row;
    }));
  };
  
  // Ajout d'une nouvelle ligne
  const addNewRow = () => {
    if (!newRow.groupe || !newRow.employe || !newRow.somme) {
      toast.error('Veuillez remplir les champs obligatoires (Groupe, Employé, Somme)');
      return;
    }
    
    const row = {
      id: `new-${Date.now()}`,
      ...newRow,
      somme: parseFloat(newRow.somme) || 0,
      duree: calculateDuration(newRow.date_recu, newRow.date_rendu),
      entreprise_perc: currentSettings.perc_entreprise,
      groupe_perc: currentSettings.perc_groupe,
      created_at: new Date().toISOString()
    };
    
    setRows(prev => [row, ...prev]); // Ajout en début (tri desc)
    setNewRow({
      statut: 'En cours',
      date_recu: '',
      date_rendu: '',
      groupe: '',
      employe: '',
      donneur: '',
      recep: '',
      somme: 0
    });
    toast.success('Nouvelle opération ajoutée');
  };
  
  // Suppression d'une ligne
  const removeRow = (id) => {
    if (!window.confirm('Êtes-vous sûr de vouloir supprimer cette opération ?')) {
      return;
    }
    setRows(prev => prev.filter(row => row.id !== id));
    toast.success('Opération supprimée');
  };
  
  // Sauvegarde
  const handleSave = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      toast.success('Configuration blanchiment sauvegardée');
    } catch (error) {
      toast.error('Erreur lors de la sauvegarde');
    } finally {
      setLoading(false);
    }
  };
  
  // Export Excel
  const handleExportExcel = () => {
    try {
      const exportData = rows.map(row => ({
        transactionDate: row.date_recu || '',
        amount: row.somme || 0,
        description: `${row.groupe} - ${row.employe}`,
        flagged: row.statut === 'Suspendu',
        riskLevel: row.statut === 'Suspendu' ? 'high' : 'low',
        thresholdExceeded: (row.somme || 0) > 50000,
        analysisDate: new Date().toLocaleDateString('fr-FR'),
        comments: `Donneur: ${row.donneur}, Récepteur: ${row.recep}, Durée: ${row.duree || 'N/A'}j`
      }));
      
      const { exportBlanchiment } = require('../utils/excelExport');
      exportBlanchiment(exportData, `blanchiment_${userEntreprise}_${new Date().toISOString().split('T')[0]}.xlsx`);
      toast.success('Export Excel réussi');
    } catch (error) {
      console.error('Erreur export:', error);
      toast.error('Erreur lors de l\'export Excel');
    }
  };
  
  // Traitement données collées
  const handlePasteData = () => {
    if (!pasteData.trim()) {
      toast.error('Aucune donnée à traiter');
      return;
    }
    
    try {
      const lines = pasteData.trim().split('\n');
      const newRows = [];
      
      lines.forEach(line => {
        const parts = line.split(/[;\t,]/).map(p => p.trim());
        if (parts.length >= 6) {
          const [date, groupe, employe, donneur, recep, somme] = parts;
          newRows.push({
            id: `paste-${Date.now()}-${Math.random()}`,
            statut: 'En cours',
            date_recu: date || '',
            date_rendu: '',
            duree: null,
            groupe: groupe || '',
            employe: employe || '',
            donneur: donneur || '',
            recep: recep || '', 
            somme: parseFloat(somme) || 0,
            entreprise_perc: currentSettings.perc_entreprise,
            groupe_perc: currentSettings.perc_groupe,
            created_at: new Date().toISOString()
          });
        }
      });
      
      if (newRows.length > 0) {
        setRows(prev => [...newRows, ...prev]);
        setPasteData('');
        setShowPasteArea(false);
        toast.success(`${newRows.length} opération(s) ajoutée(s) depuis les données collées`);
      } else {
        toast.error('Format invalide. Utilisez: Date;Groupe;Employé;Donneur;Recep;Somme');
      }
    } catch (error) {
      console.error('Erreur traitement données:', error);
      toast.error('Erreur lors du traitement des données');
    }
  };
  
  const getStatutColor = (statut) => {
    switch (statut) {
      case 'En cours': return 'bg-blue-100 text-blue-800';
      case 'Terminé': return 'bg-green-100 text-green-800';
      case 'Suspendu': return 'bg-yellow-100 text-yellow-800';
      case 'Annulé': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };
  
  // Statistiques
  const stats = {
    total: rows.length,
    enCours: rows.filter(r => r.statut === 'En cours').length,
    termine: rows.filter(r => r.statut === 'Terminé').length,
    suspendu: rows.filter(r => r.statut === 'Suspendu').length,
    sommeTotal: rows.reduce((sum, r) => sum + (r.somme || 0), 0)
  };
  
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Gestion du Blanchiment</h2>
          <p className="text-muted-foreground">
            {userEntreprise && `Entreprise: ${userEntreprise}`} - Suivi des opérations
            {readonly && " (Lecture seule - Staff)"}
          </p>
        </div>
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2">
            <Label className="text-sm">Blanchiment:</Label>
            <Button
              variant={blanchimentEnabled ? "default" : "outline"}
              size="sm"
              onClick={() => setBlanchimentEnabled(!blanchimentEnabled)}
              disabled={!canManageSettings}
            >
              {blanchimentEnabled ? 'Activé' : 'Désactivé'}
            </Button>
          </div>
          
          {blanchimentEnabled && (
            <>
              {rows.length > 0 && (
                <Button variant="outline" onClick={handleExportExcel}>
                  <Download className="w-4 h-4 mr-2" />
                  Export Excel
                </Button>
              )}
              
              {!readonly && (
                <>
                  <Button 
                    variant="outline" 
                    onClick={() => setShowPasteArea(!showPasteArea)}
                  >
                    <Copy className="w-4 h-4 mr-2" />
                    Coller Données
                  </Button>
                  
                  <Button onClick={handleSave} disabled={loading}>
                    <Save className="w-4 h-4 mr-2" />
                    Sauvegarder
                  </Button>
                </>
              )}
            </>
          )}
        </div>
      </div>

      {/* Alerte blanchiment désactivé */}
      {!blanchimentEnabled && (
        <Card className="border-yellow-200 bg-yellow-50">
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <AlertTriangle className="w-5 h-5 text-yellow-600" />
              <span className="text-yellow-800">
                Le blanchiment est désactivé pour cette entreprise.
                {!canManageSettings && " Seul le staff peut l'activer."}
              </span>
            </div>
          </CardContent>
        </Card>
      )}

      {blanchimentEnabled && (
        <>
          {/* Configuration des pourcentages */}
          <Card>
            <CardHeader>
              <CardTitle>Configuration des Pourcentages</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center space-x-4">
                <Button
                  variant={useGlobal ? "default" : "outline"}
                  size="sm"
                  onClick={() => setUseGlobal(!useGlobal)}
                  disabled={readonly}
                >
                  {useGlobal ? 'Paramètres Globaux' : 'Paramètres Locaux'}
                </Button>
                <span className="text-sm text-muted-foreground">
                  {useGlobal ? 'Utilise les paramètres définis globalement' : 'Paramètres spécifiques à cette entreprise'}
                </span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="perc_entreprise">Pourcentage Entreprise (%)</Label>
                    <Input
                      id="perc_entreprise"
                      type="number"
                      value={currentSettings.perc_entreprise}
                      onChange={(e) => {
                        const value = parseFloat(e.target.value) || 0;
                        if (useGlobal) {
                          setGlobalSettings(prev => ({ ...prev, perc_entreprise: value }));
                        } else {
                          setLocalSettings(prev => ({ ...prev, perc_entreprise: value }));
                        }
                      }}
                      disabled={readonly}
                    />
                  </div>
                  <div>
                    <Label htmlFor="perc_groupe">Pourcentage Groupe (%)</Label>
                    <Input
                      id="perc_groupe"
                      type="number"
                      value={currentSettings.perc_groupe}
                      onChange={(e) => {
                        const value = parseFloat(e.target.value) || 0;
                        if (useGlobal) {
                          setGlobalSettings(prev => ({ ...prev, perc_groupe: value }));
                        } else {
                          setLocalSettings(prev => ({ ...prev, perc_groupe: value }));
                        }
                      }}
                      disabled={readonly}
                    />
                  </div>
                </div>
                
                <div className="space-y-4">
                  <h4 className="font-medium">Exemple de Calcul</h4>
                  <div className="p-4 bg-muted rounded-lg text-sm">
                    <div className="space-y-2">
                      <div className="flex justify-between">
                        <span>Somme de base:</span>
                        <span className="font-medium">€100,000</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Part entreprise ({currentSettings.perc_entreprise}%):</span>
                        <span className="font-medium">€{(100000 * currentSettings.perc_entreprise / 100).toLocaleString()}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Part groupe ({currentSettings.perc_groupe}%):</span>
                        <span className="font-medium">€{(100000 * currentSettings.perc_groupe / 100).toLocaleString()}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Statistiques */}
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            <Card>
              <CardContent className="p-6 text-center">
                <div className="text-2xl font-bold">{stats.total}</div>
                <div className="text-sm text-muted-foreground">Total</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-6 text-center">
                <div className="text-2xl font-bold text-blue-600">{stats.enCours}</div>
                <div className="text-sm text-muted-foreground">En cours</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-6 text-center">
                <div className="text-2xl font-bold text-green-600">{stats.termine}</div>
                <div className="text-sm text-muted-foreground">Terminé</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-6 text-center">
                <div className="text-2xl font-bold text-yellow-600">{stats.suspendu}</div>
                <div className="text-sm text-muted-foreground">Suspendu</div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-6 text-center">
                <div className="text-2xl font-bold">€{stats.sommeTotal.toLocaleString()}</div>
                <div className="text-sm text-muted-foreground">Somme totale</div>
              </CardContent>
            </Card>
          </div>

          {/* Zone de collage */}
          {!readonly && showPasteArea && (
            <Card className="border-blue-200 bg-blue-50">
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Copy className="w-5 h-5 mr-2" />
                  Coller des Données depuis Excel/CSV
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <Label htmlFor="paste-area">
                    Collez vos données ici (depuis Excel, CSV ou autre tableur)
                  </Label>
                  <p className="text-sm text-muted-foreground mb-2">
                    Format attendu: Date | Groupe | Employé | Donneur | Récepteur | Somme
                  </p>
                  <Textarea
                    id="paste-area"
                    placeholder="Collez vos données ici... (Ctrl+V)
Exemple:
2024-01-15	Alpha	John Doe	ID123456	ID789012	50000
2024-01-16	Beta	Jane Smith	ID456789	ID012345	75000"
                    value={pasteData}
                    onChange={(e) => setPasteData(e.target.value)}
                    rows={6}
                    className="font-mono text-sm"
                  />
                </div>
                <div className="flex items-center space-x-4">
                  <Button onClick={handlePasteData} disabled={!pasteData.trim()}>
                    <Upload className="w-4 h-4 mr-2" />
                    Traiter les Données
                  </Button>
                  <Button 
                    variant="outline" 
                    onClick={() => {
                      setPasteData('');
                      setShowPasteArea(false);
                    }}
                  >
                    Annuler
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Formulaire nouvelle opération */}
          {!readonly && (
            <Card>
              <CardHeader>
                <CardTitle>Ajouter une Opération</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                  <div>
                    <Label>Statut</Label>
                    <select
                      value={newRow.statut}
                      onChange={(e) => setNewRow(prev => ({ ...prev, statut: e.target.value }))}
                      className="w-full p-2 border rounded"
                    >
                      <option value="En cours">En cours</option>
                      <option value="Terminé">Terminé</option>
                      <option value="Suspendu">Suspendu</option>
                      <option value="Annulé">Annulé</option>
                    </select>
                  </div>
                  <div>
                    <Label htmlFor="new_groupe">Groupe *</Label>
                    <Input
                      id="new_groupe"
                      value={newRow.groupe}
                      onChange={(e) => setNewRow(prev => ({ ...prev, groupe: e.target.value }))}
                      placeholder="Alpha, Beta..."
                    />
                  </div>
                  <div>
                    <Label htmlFor="new_employe">Employé *</Label>
                    <Input
                      id="new_employe"
                      value={newRow.employe}
                      onChange={(e) => setNewRow(prev => ({ ...prev, employe: e.target.value }))}
                      placeholder="Nom de l'employé"
                    />
                  </div>
                  <div>
                    <Label htmlFor="new_somme">Somme (€) *</Label>
                    <Input
                      id="new_somme"
                      type="number"
                      value={newRow.somme}
                      onChange={(e) => setNewRow(prev => ({ ...prev, somme: parseFloat(e.target.value) || 0 }))}
                      placeholder="50000"
                    />
                  </div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                  <div>
                    <Label htmlFor="new_date_recu">Date Reçu</Label>
                    <Input
                      id="new_date_recu"
                      type="date"
                      value={newRow.date_recu}
                      onChange={(e) => setNewRow(prev => ({ ...prev, date_recu: e.target.value }))}
                    />
                  </div>
                  <div>
                    <Label htmlFor="new_date_rendu">Date Rendu</Label>
                    <Input
                      id="new_date_rendu"
                      type="date"
                      value={newRow.date_rendu}
                      onChange={(e) => setNewRow(prev => ({ ...prev, date_rendu: e.target.value }))}
                    />
                  </div>
                  <div>
                    <Label htmlFor="new_donneur">ID Donneur</Label>
                    <Input
                      id="new_donneur"
                      value={newRow.donneur}
                      onChange={(e) => setNewRow(prev => ({ ...prev, donneur: e.target.value }))}
                      placeholder="ID123456"
                    />
                  </div>
                  <div>
                    <Label htmlFor="new_recep">ID Récepteur</Label>
                    <Input
                      id="new_recep"
                      value={newRow.recep}
                      onChange={(e) => setNewRow(prev => ({ ...prev, recep: e.target.value }))}
                      placeholder="ID789012"
                    />
                  </div>
                </div>
                <div className="flex justify-end">
                  <Button onClick={addNewRow}>
                    <Plus className="w-4 h-4 mr-2" />
                    Ajouter Opération
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Table des opérations */}
          <Card>
            <CardHeader>
              <CardTitle>Opérations de Blanchiment ({rows.length})</CardTitle>
            </CardHeader>
            <CardContent>
              {rows.length === 0 ? (
                <div className="text-center py-8">
                  <AlertTriangle className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground">Aucune opération de blanchiment</p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left p-2">Statut</th>
                        <th className="text-left p-2">Date Reçu</th>
                        <th className="text-left p-2">Date Rendu</th>
                        <th className="text-left p-2">Durée (j)</th>
                        <th className="text-left p-2">Groupe</th>
                        <th className="text-left p-2">Employé</th>
                        <th className="text-left p-2">Donneur</th>
                        <th className="text-left p-2">Récepteur</th>
                        <th className="text-left p-2">Somme (€)</th>
                        <th className="text-left p-2">% Ent.</th>
                        <th className="text-left p-2">% Grp.</th>
                        {!readonly && <th className="text-left p-2">Actions</th>}
                      </tr>
                    </thead>
                    <tbody>
                      {rows.map((row) => (
                        <tr key={row.id} className="border-b hover:bg-muted/50">
                          <td className="p-2">
                            <Badge className={getStatutColor(row.statut)}>
                              {row.statut}
                            </Badge>
                          </td>
                          <td className="p-2">
                            <Input
                              type="date"
                              value={row.date_recu}
                              onChange={(e) => handleRowChange(row.id, 'date_recu', e.target.value)}
                              disabled={readonly}
                              className="w-auto text-xs"
                            />
                          </td>
                          <td className="p-2">
                            <Input
                              type="date"
                              value={row.date_rendu || ''}
                              onChange={(e) => handleRowChange(row.id, 'date_rendu', e.target.value)}
                              disabled={readonly}
                              className="w-auto text-xs"
                            />
                          </td>
                          <td className="p-2">
                            <Badge variant="outline">
                              {row.duree ? `${row.duree}j` : '-'}
                            </Badge>
                          </td>
                          <td className="p-2">
                            <Input
                              value={row.groupe}
                              onChange={(e) => handleRowChange(row.id, 'groupe', e.target.value)}
                              disabled={readonly}
                              className="w-20 text-xs"
                            />
                          </td>
                          <td className="p-2">
                            <Input
                              value={row.employe}
                              onChange={(e) => handleRowChange(row.id, 'employe', e.target.value)}
                              disabled={readonly}
                              className="w-24 text-xs"
                            />
                          </td>
                          <td className="p-2">
                            <Input
                              value={row.donneur}
                              onChange={(e) => handleRowChange(row.id, 'donneur', e.target.value)}
                              disabled={readonly}
                              className="w-20 text-xs"
                            />
                          </td>
                          <td className="p-2">
                            <Input
                              value={row.recep}
                              onChange={(e) => handleRowChange(row.id, 'recep', e.target.value)}
                              disabled={readonly}
                              className="w-20 text-xs"
                            />
                          </td>
                          <td className="p-2">
                            <Input
                              type="number"
                              value={row.somme}
                              onChange={(e) => handleRowChange(row.id, 'somme', parseFloat(e.target.value) || 0)}
                              disabled={readonly}
                              className="w-24 text-xs"
                            />
                          </td>
                          <td className="p-2 text-xs text-muted-foreground">
                            {row.entreprise_perc}%
                          </td>
                          <td className="p-2 text-xs text-muted-foreground">
                            {row.groupe_perc}%
                          </td>
                          {!readonly && (
                            <td className="p-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => removeRow(row.id)}
                              >
                                <Trash2 className="w-4 h-4" />
                              </Button>
                            </td>
                          )}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        </>
      )}

      {/* Staff : lecture seule */}
      {readonly && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center">
            <AlertTriangle className="w-5 h-5 text-yellow-600 mr-2" />
            <span className="text-yellow-800">Accès staff : lecture seule (modification et création désactivées)</span>
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

// Composant Archives complet avec recherche et CRUD
const ArchivesTab = () => {
  const { userRole, userEntreprise, canAccessStaffConfig } = useAuth();
  const isStaff = canAccessStaffConfig();
  const isPatronCoPatron = ['patron', 'co-patron'].includes(userRole);
  
  const [archives, setArchives] = useState([
    {
      id: '1',
      type: 'Dotation',
      date: '2024-01-25',
      montant: 125000,
      statut: 'En attente',
      entreprise_key: 'LSPD',
      created_at: '2024-01-25T10:00:00Z',
      payload: {
        employees: [
          { name: 'Pierre Martin', ca_total: 35000, salaire: 8500, prime: 2000 },
          { name: 'Marie Dubois', ca_total: 45000, salaire: 12000, prime: 3500 }
        ],
        totals: { ca: 80000, salaires: 20500, primes: 5500 },
        solde_actuel: 150000,
        description: 'Dotation mensuelle janvier 2024'
      }
    },
    {
      id: '2',
      type: 'Impôt',
      date: '2024-01-20',
      montant: 25000,
      statut: 'Validé',
      entreprise_key: 'LSPD',
      created_at: '2024-01-20T14:30:00Z',
      payload: {
        revenus_imposables: 200000,
        patrimoine: 150000,
        impot_revenus: 20000,
        impot_patrimoine: 5000,
        description: 'Déclaration impôts Q4 2023'
      }
    },
    {
      id: '3',
      type: 'Blanchiment',
      date: '2024-01-18',
      montant: 50000,
      statut: 'Refusé',
      entreprise_key: 'EMS',
      created_at: '2024-01-18T09:15:00Z',
      payload: {
        operations: 3,
        somme_totale: 175000,
        entreprise_perc: 15,
        groupe_perc: 5,
        description: 'Cycle blanchiment semaine 3 - Non conforme'
      }
    }
  ]);
  
  const [filteredArchives, setFilteredArchives] = useState(archives);
  const [searchTerm, setSearchTerm] = useState('');
  const [filters, setFilters] = useState({
    type: '',
    statut: '',
    entreprise: '',
    dateDebut: '',
    dateFin: ''
  });
  const [selectedArchive, setSelectedArchive] = useState(null);
  const [editingArchive, setEditingArchive] = useState(null);
  const [loading, setLoading] = useState(false);
  
  // Recherche avec debounce
  useEffect(() => {
    const timer = setTimeout(() => {
      let filtered = archives;
      
      // Recherche globale
      if (searchTerm.trim()) {
        filtered = filtered.filter(archive => {
          const searchStr = JSON.stringify(archive).toLowerCase();
          return searchStr.includes(searchTerm.toLowerCase());
        });
      }
      
      // Filtres spécifiques
      if (filters.type) {
        filtered = filtered.filter(archive => archive.type === filters.type);
      }
      if (filters.statut) {
        filtered = filtered.filter(archive => archive.statut === filters.statut);
      }
      if (filters.entreprise) {
        filtered = filtered.filter(archive => archive.entreprise_key === filters.entreprise);
      }
      if (filters.dateDebut) {
        filtered = filtered.filter(archive => archive.date >= filters.dateDebut);
      }
      if (filters.dateFin) {
        filtered = filtered.filter(archive => archive.date <= filters.dateFin);
      }
      
      // Tri par date de création desc
      filtered.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
      
      setFilteredArchives(filtered);
    }, 300);
    
    return () => clearTimeout(timer);
  }, [searchTerm, filters, archives]);
  
  // Vérification des droits d'édition
  const canEdit = (archive) => {
    if (isStaff) return true;
    if (isPatronCoPatron && archive.statut.toLowerCase().includes('refus')) return true;
    return false;
  };
  
  const handleView = (archive) => {
    setSelectedArchive(archive);
  };
  
  const handleEdit = (archive) => {
    if (!canEdit(archive)) {
      toast.error('Vous n\'avez pas les permissions pour éditer cette archive');
      return;
    }
    setEditingArchive({ ...archive });
  };
  
  const handleSaveEdit = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setArchives(prev => prev.map(archive => 
        archive.id === editingArchive.id ? editingArchive : archive
      ));
      
      setEditingArchive(null);
      toast.success('Archive modifiée avec succès');
    } catch (error) {
      toast.error('Erreur lors de la modification');
    } finally {
      setLoading(false);
    }
  };
  
  const handleValidate = async (id) => {
    if (!isStaff) {
      toast.error('Seul le staff peut valider les archives');
      return;
    }
    
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setArchives(prev => prev.map(archive => 
        archive.id === id ? { ...archive, statut: 'Validé' } : archive
      ));
      
      toast.success('Archive validée');
    } catch (error) {
      toast.error('Erreur lors de la validation');
    } finally {
      setLoading(false);
    }
  };
  
  const handleReject = async (id) => {
    if (!isStaff) {
      toast.error('Seul le staff peut refuser les archives');
      return;
    }
    
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setArchives(prev => prev.map(archive => 
        archive.id === id ? { ...archive, statut: 'Refusé' } : archive
      ));
      
      toast.success('Archive refusée');
    } catch (error) {
      toast.error('Erreur lors du refus');
    } finally {
      setLoading(false);
    }
  };
  
  const handleDelete = async (id) => {
    if (!isStaff) {
      toast.error('Seul le staff peut supprimer les archives');
      return;
    }
    
    const archive = archives.find(a => a.id === id);
    if (!window.confirm(`Êtes-vous sûr de vouloir supprimer l'archive "${archive?.type} - ${archive?.date}" ?`)) {
      return;
    }
    
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 500));
      
      setArchives(prev => prev.filter(archive => archive.id !== id));
      toast.success('Archive supprimée');
    } catch (error) {
      toast.error('Erreur lors de la suppression');
    } finally {
      setLoading(false);
    }
  };
  
  const handleExportExcel = () => {
    try {
      const exportData = filteredArchives.map(archive => ({
        'ID': archive.id,
        'Type': archive.type,
        'Date': new Date(archive.date).toLocaleDateString('fr-FR'), 
        'Montant (€)': archive.montant,
        'Statut': archive.statut,
        'Entreprise': archive.entreprise_key,
        'Créé le': new Date(archive.created_at).toLocaleDateString('fr-FR'),
        'Description': archive.payload?.description || '',
        'Détails': JSON.stringify(archive.payload, null, 2)
      }));
      
      // Utilisation d'XLSX directement pour plus de contrôle
      const XLSX = require('xlsx');
      const worksheet = XLSX.utils.json_to_sheet(exportData);
      const workbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(workbook, worksheet, 'Archives');
      
      const fileName = userEntreprise 
        ? `archives_${userEntreprise}_${new Date().toISOString().split('T')[0]}.xlsx`
        : `archives_toutes_${new Date().toISOString().split('T')[0]}.xlsx`;
        
      XLSX.writeFile(workbook, fileName);
      toast.success(`Export Excel réussi : ${fileName}`);
    } catch (error) {
      console.error('Erreur export:', error);
      toast.error('Erreur lors de l\'export Excel');
    }
  };
  
  const handleTemplateImport = (event) => {
    const file = event.target.files[0];
    if (!file) return;
    
    if (!isStaff) {
      toast.error('Seul le staff peut importer des templates');
      return;
    }
    
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const XLSX = require('xlsx');
        const workbook = XLSX.read(e.target.result, { type: 'binary' });
        const sheetName = workbook.SheetNames[0];
        const sheet = workbook.Sheets[sheetName];
        
        // Récupération des données
        const data = XLSX.utils.sheet_to_json(sheet);
        
        if (data.length > 0) {
          // Exemple de mapping basé sur la première ligne
          const headers = Object.keys(data[0]);
          console.log('Headers détectés:', headers);
          
          toast.success(`Template importé avec succès. ${data.length} ligne(s) détectée(s).`);
          
          // Ici on pourrait traiter et ajouter les données aux archives
          // Pour l'instant, on affiche juste un succès
        } else {
          toast.error('Fichier vide ou format non reconnu');
        }
      } catch (error) {
        console.error('Erreur import:', error);
        toast.error('Erreur lors de l\'import du template');
      }
    };
    reader.readAsBinaryString(file);
    event.target.value = ''; // Reset input
  };
  
  const getStatutColor = (statut) => {
    switch (statut.toLowerCase()) {
      case 'en attente': return 'bg-yellow-100 text-yellow-800';
      case 'validé': return 'bg-green-100 text-green-800';
      case 'refusé': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };
  
  const getTypeColor = (type) => {
    switch (type) {
      case 'Dotation': return 'bg-blue-100 text-blue-800';
      case 'Impôt': return 'bg-purple-100 text-purple-800';
      case 'Blanchiment': return 'bg-orange-100 text-orange-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };
  
  // Statistiques
  const stats = {
    total: filteredArchives.length,
    enAttente: filteredArchives.filter(a => a.statut === 'En attente').length,
    valide: filteredArchives.filter(a => a.statut === 'Validé').length,
    refuse: filteredArchives.filter(a => a.statut === 'Refusé').length,
    montantTotal: filteredArchives.reduce((sum, a) => sum + a.montant, 0)
  };
  
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Gestion des Archives</h2>
          <p className="text-muted-foreground">
            Consultez et gérez les archives des dotations, impôts et blanchiment
            {userEntreprise && ` - Entreprise: ${userEntreprise}`}
          </p>
        </div>
        <div className="flex items-center space-x-2">
          {isStaff && (
            <>
              <Label htmlFor="template-upload" className="cursor-pointer">
                <Button variant="outline" size="sm" asChild>
                  <span>
                    <Upload className="w-4 h-4 mr-2" />
                    Import Template
                  </span>
                </Button>
              </Label>
              <Input
                id="template-upload"
                type="file"
                accept=".xlsx,.xls"
                className="hidden"
                onChange={handleTemplateImport}
              />
            </>
          )}
          <Button onClick={handleExportExcel} variant="outline" size="sm">
            <Download className="w-4 h-4 mr-2" />
            Export Excel
          </Button>
        </div>
      </div>

      {/* Statistiques */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold">{stats.total}</div>
            <div className="text-sm text-muted-foreground">Total</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold text-yellow-600">{stats.enAttente}</div>
            <div className="text-sm text-muted-foreground">En attente</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold text-green-600">{stats.valide}</div>
            <div className="text-sm text-muted-foreground">Validé</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold text-red-600">{stats.refuse}</div>
            <div className="text-sm text-muted-foreground">Refusé</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold">€{stats.montantTotal.toLocaleString()}</div>
            <div className="text-sm text-muted-foreground">Montant total</div>
          </CardContent>
        </Card>
      </div>

      {/* Recherche et filtres avancés */}
      <Card>
        <CardHeader>
          <CardTitle>Recherche Avancée</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Recherche globale */}
          <div>
            <Label htmlFor="search">Recherche globale</Label>
            <div className="relative">
              <Eye className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                id="search"
                placeholder="Rechercher dans toutes les archives..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>
          
          {/* Filtres spécifiques */}
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
            <div>
              <Label>Type</Label>
              <select
                value={filters.type}
                onChange={(e) => setFilters(prev => ({ ...prev, type: e.target.value }))}
                className="w-full p-2 border rounded"
              >
                <option value="">Tous les types</option>
                <option value="Dotation">Dotation</option>
                <option value="Impôt">Impôt</option>
                <option value="Blanchiment">Blanchiment</option>
              </select>
            </div>
            <div>
              <Label>Statut</Label>
              <select
                value={filters.statut}
                onChange={(e) => setFilters(prev => ({ ...prev, statut: e.target.value }))}
                className="w-full p-2 border rounded"
              >
                <option value="">Tous les statuts</option>
                <option value="En attente">En attente</option>
                <option value="Validé">Validé</option>
                <option value="Refusé">Refusé</option>
              </select>
            </div>
            <div>
              <Label>Entreprise</Label>
              <select
                value={filters.entreprise}
                onChange={(e) => setFilters(prev => ({ ...prev, entreprise: e.target.value }))}
                className="w-full p-2 border rounded"
              >
                <option value="">Toutes les entreprises</option>
                <option value="LSPD">LSPD</option>
                <option value="EMS">EMS</option>
                <option value="FBI">FBI</option>
              </select>
            </div>
            <div>
              <Label>Date début</Label>
              <Input
                type="date"
                value={filters.dateDebut}
                onChange={(e) => setFilters(prev => ({ ...prev, dateDebut: e.target.value }))}
              />
            </div>
            <div>
              <Label>Date fin</Label>
              <Input
                type="date"
                value={filters.dateFin}
                onChange={(e) => setFilters(prev => ({ ...prev, dateFin: e.target.value }))}
              />
            </div>
          </div>
          
          {/* Bouton reset filtres */}
          <div className="flex justify-end">
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => {
                setSearchTerm('');
                setFilters({
                  type: '',
                  statut: '',
                  entreprise: '',
                  dateDebut: '',
                  dateFin: ''
                });
              }}
            >
              Réinitialiser les filtres
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Table des archives */}
      <Card>
        <CardHeader>
          <CardTitle>
            Archives ({filteredArchives.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {filteredArchives.length === 0 ? (
            <div className="text-center py-8">
              <Archive className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              <p className="text-muted-foreground">
                {searchTerm || Object.values(filters).some(f => f) ? 'Aucune archive trouvée' : 'Aucune archive disponible'}
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left p-3">Type</th>
                    <th className="text-left p-3">Date</th>
                    <th className="text-left p-3">Montant</th>
                    <th className="text-left p-3">Statut</th>
                    <th className="text-left p-3">Entreprise</th>
                    <th className="text-left p-3">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredArchives.map((archive) => (
                    <tr key={archive.id} className="border-b hover:bg-muted/50">
                      <td className="p-3">
                        <Badge className={getTypeColor(archive.type)}>
                          {archive.type}
                        </Badge>
                      </td>
                      <td className="p-3">
                        {new Date(archive.date).toLocaleDateString('fr-FR')}
                      </td>
                      <td className="p-3 font-medium">
                        €{archive.montant.toLocaleString()}
                      </td>
                      <td className="p-3">
                        <Badge className={getStatutColor(archive.statut)}>
                          {archive.statut}
                        </Badge>
                      </td>
                      <td className="p-3">
                        <Badge variant="secondary">{archive.entreprise_key}</Badge>
                      </td>
                      <td className="p-3">
                        <div className="flex items-center space-x-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleView(archive)}
                            title="Voir les détails"
                          >
                            <Eye className="w-4 h-4" />
                          </Button>
                          
                          {canEdit(archive) && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleEdit(archive)}
                              title="Éditer"
                            >
                              <Settings className="w-4 h-4" />
                            </Button>
                          )}
                          
                          {isStaff && archive.statut !== 'Validé' && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleValidate(archive.id)}
                              className="text-green-600 hover:text-green-700"
                              title="Valider"
                              disabled={loading}
                            >
                              ✓
                            </Button>
                          )}
                          
                          {isStaff && archive.statut !== 'Refusé' && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleReject(archive.id)}
                              className="text-red-600 hover:text-red-700"
                              title="Refuser"
                              disabled={loading}
                            >
                              ✗
                            </Button>
                          )}
                          
                          {isStaff && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleDelete(archive.id)}
                              className="text-red-600 hover:text-red-700"
                              title="Supprimer"
                              disabled={loading}
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Modal visualisation */}
      {selectedArchive && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" onClick={() => setSelectedArchive(null)}>
          <div className="bg-white rounded-lg p-6 max-w-2xl max-h-[80vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold">Détails de l'Archive</h3>
              <Button variant="ghost" size="sm" onClick={() => setSelectedArchive(null)}>
                ✗
              </Button>
            </div>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label className="text-sm font-medium">Type</Label>
                  <p>{selectedArchive.type}</p>
                </div>
                <div>
                  <Label className="text-sm font-medium">Date</Label>
                  <p>{new Date(selectedArchive.date).toLocaleDateString('fr-FR')}</p>
                </div>
                <div>
                  <Label className="text-sm font-medium">Montant</Label>
                  <p>€{selectedArchive.montant.toLocaleString()}</p>
                </div>
                <div>
                  <Label className="text-sm font-medium">Statut</Label>
                  <Badge className={getStatutColor(selectedArchive.statut)}>
                    {selectedArchive.statut}
                  </Badge>
                </div>
              </div>
              <div>
                <Label className="text-sm font-medium">Description</Label>
                <p>{selectedArchive.payload?.description || 'Aucune description'}</p>
              </div>
              <div>
                <Label className="text-sm font-medium">Détails (Payload)</Label>
                <pre className="mt-2 p-4 bg-muted rounded-lg text-sm overflow-auto max-h-60 whitespace-pre-wrap">
                  {JSON.stringify(selectedArchive.payload, null, 2)}
                </pre>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Modal édition */}
      {editingArchive && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" onClick={() => setEditingArchive(null)}>
          <div className="bg-white rounded-lg p-6 max-w-lg w-full" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold">Modifier l'Archive</h3>
              <Button variant="ghost" size="sm" onClick={() => setEditingArchive(null)}>
                ✗
              </Button>
            </div>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="edit_date">Date</Label>
                  <Input
                    id="edit_date"
                    type="date"
                    value={editingArchive.date}
                    onChange={(e) => setEditingArchive(prev => ({ ...prev, date: e.target.value }))}
                  />
                </div>
                <div>
                  <Label htmlFor="edit_montant">Montant (€)</Label>
                  <Input
                    id="edit_montant"
                    type="number"
                    value={editingArchive.montant}
                    onChange={(e) => setEditingArchive(prev => ({ ...prev, montant: parseFloat(e.target.value) || 0 }))}
                  />
                </div>
              </div>
              <div>
                <Label htmlFor="edit_description">Description</Label>
                <Textarea
                  id="edit_description"
                  value={editingArchive.payload?.description || ''}
                  onChange={(e) => setEditingArchive(prev => ({ 
                    ...prev, 
                    payload: { ...prev.payload, description: e.target.value }
                  }))}
                  rows={3}
                />
              </div>
              <div className="flex justify-end space-x-2">
                <Button variant="outline" onClick={() => setEditingArchive(null)}>
                  Annuler
                </Button>
                <Button onClick={handleSaveEdit} disabled={loading}>
                  {loading ? 'Sauvegarde...' : 'Sauvegarder'}
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

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
            <FacturesDiplomesTab />
          </TabsContent>

          {/* 5) Blanchiment — Route : /#blanchiment */}
          <TabsContent value="blanchiment" className="space-y-6">
            <RoleGate requiredAccess="canAccessBlanchiment">
              <BlanchimentTab />
            </RoleGate>
          </TabsContent>

          {/* 6) Archives — Route : /#archives */}
          <TabsContent value="archives" className="space-y-6">
            <ArchivesTab />
          </TabsContent>

          {/* 7) Config (Staff) — Route : /#config */}
          <TabsContent value="config" className="space-y-6">
            <RoleGate requiredAccess="canAccessStaffConfig">
              <ConfigStaffTab />
            </RoleGate>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default Dashboard;