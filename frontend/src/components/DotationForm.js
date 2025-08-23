import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Separator } from './ui/separator';
import { Badge } from './ui/badge';
import { Textarea } from './ui/textarea';
import { Plus, Trash2, Copy, Save, Archive, Calculator } from 'lucide-react';
import { toast } from 'sonner';
import { useAuth } from '../contexts/AuthContext';
import { mockDotationData, mockTaxBrackets } from '../data/mockData';

const DotationForm = () => {
  const { isReadOnlyForStaff, userEntreprise } = useAuth();
  const [soldeActuel, setSoldeActuel] = useState(mockDotationData.solde_actuel);
  const [employees, setEmployees] = useState(mockDotationData.employees);
  const [depenses, setDepenses] = useState(mockDotationData.depenses);
  const [retraits, setRetraits] = useState(mockDotationData.retraits);
  const [pasteEmployeeData, setPasteEmployeeData] = useState('');
  const [pasteDepenseData, setPasteDepenseData] = useState('');
  const [pasteRetraitData, setPasteRetraitData] = useState('');
  const [loading, setLoading] = useState(false);

  const readonly = isReadOnlyForStaff();

  // Calculate salary and prime based on tax brackets
  const calculateFromPaliers = (ca, isPatron = false) => {
    let salaire = 0;
    let prime = 0;
    
    for (const bracket of mockTaxBrackets) {
      if (ca >= bracket.min && (bracket.max === null || ca <= bracket.max)) {
        const salaireMin = isPatron ? bracket.sal_min_pat : bracket.sal_min_emp;
        const salaireMax = isPatron ? bracket.sal_max_pat : bracket.sal_max_emp;
        const primeMin = isPatron ? bracket.pr_min_pat : bracket.pr_min_emp;
        const primeMax = isPatron ? bracket.pr_max_pat : bracket.pr_max_emp;
        
        // Simple calculation - could be more complex
        salaire = salaireMin + (ca - bracket.min) * bracket.taux * 0.5;
        prime = primeMin + (ca - bracket.min) * bracket.taux * 0.3;
        
        salaire = Math.min(Math.max(salaire, salaireMin), salaireMax);
        prime = Math.min(Math.max(prime, primeMin), primeMax);
        break;
      }
    }
    
    return { salaire: Math.round(salaire), prime: Math.round(prime) };
  };

  // Recalculate employee totals
  const recalculateEmployee = (employee, index) => {
    const ca_total = employee.run + employee.facture + employee.vente;
    const { salaire, prime } = calculateFromPaliers(ca_total, false);
    
    const updatedEmployee = {
      ...employee,
      ca_total,
      salaire,
      prime
    };
    
    const newEmployees = [...employees];
    newEmployees[index] = updatedEmployee;
    setEmployees(newEmployees);
  };

  // Handle employee field changes
  const handleEmployeeChange = (index, field, value) => {
    const numValue = field === 'name' ? value : parseFloat(value) || 0;
    const newEmployees = [...employees];
    newEmployees[index] = { ...newEmployees[index], [field]: numValue };
    
    if (['run', 'facture', 'vente'].includes(field)) {
      recalculateEmployee(newEmployees[index], index);
    } else {
      setEmployees(newEmployees);
    }
  };

  // Parse and add employee data from paste
  const handleEmployeePaste = () => {
    if (!pasteEmployeeData.trim()) return;
    
    try {
      const lines = pasteEmployeeData.trim().split('\n');
      const newEmployees = [];
      
      lines.forEach(line => {
        const parts = line.split(/[;\t,]/).map(p => p.trim());
        if (parts.length >= 4) {
          const [name, run, facture, vente] = parts;
          const runVal = parseFloat(run) || 0;
          const factureVal = parseFloat(facture) || 0;
          const venteVal = parseFloat(vente) || 0;
          const ca_total = runVal + factureVal + venteVal;
          const { salaire, prime } = calculateFromPaliers(ca_total, false);
          
          newEmployees.push({
            id: Date.now() + Math.random(),
            name,
            run: runVal,
            facture: factureVal,
            vente: venteVal,
            ca_total,
            salaire,
            prime
          });
        }
      });
      
      if (newEmployees.length > 0) {
        setEmployees([...employees, ...newEmployees]);
        setPasteEmployeeData('');
        toast.success(`${newEmployees.length} employé(s) ajouté(s)`);
      } else {
        toast.error('Format invalide. Utilisez: Nom; RUN; FACTURE; VENTE');
      }
    } catch (error) {
      toast.error('Erreur lors du traitement des données');
    }
  };

  // Add new employee
  const addEmployee = () => {
    const newEmployee = {
      id: Date.now(),
      name: '',
      run: 0,
      facture: 0,
      vente: 0,
      ca_total: 0,
      salaire: 0,
      prime: 0
    };
    setEmployees([...employees, newEmployee]);
  };

  // Remove employee
  const removeEmployee = (index) => {
    const newEmployees = employees.filter((_, i) => i !== index);
    setEmployees(newEmployees);
  };

  // Parse and add expense data
  const handleDepensePaste = () => {
    if (!pasteDepenseData.trim()) return;
    
    try {
      const lines = pasteDepenseData.trim().split('\n');
      const newDepenses = [];
      
      lines.forEach(line => {
        const parts = line.split(/[;\t,]/).map(p => p.trim());
        if (parts.length >= 3) {
          const [date, justificatif, montant] = parts;
          newDepenses.push({
            id: Date.now() + Math.random(),
            date,
            justificatif,
            montant: parseFloat(montant) || 0
          });
        }
      });
      
      if (newDepenses.length > 0) {
        setDepenses([...depenses, ...newDepenses]);
        setPasteDepenseData('');
        toast.success(`${newDepenses.length} dépense(s) ajoutée(s)`);
      }
    } catch (error) {
      toast.error('Erreur lors du traitement des dépenses');
    }
  };

  // Parse and add withdrawal data
  const handleRetraitPaste = () => {
    if (!pasteRetraitData.trim()) return;
    
    try {
      const lines = pasteRetraitData.trim().split('\n');
      const newRetraits = [];
      
      lines.forEach(line => {
        const parts = line.split(/[;\t,]/).map(p => p.trim());
        if (parts.length >= 3) {
          const [date, justificatif, montant] = parts;
          newRetraits.push({
            id: Date.now() + Math.random(),
            date,
            justificatif,
            montant: parseFloat(montant) || 0
          });
        }
      });
      
      if (newRetraits.length > 0) {
        setRetraits([...retraits, ...newRetraits]);
        setPasteRetraitData('');
        toast.success(`${newRetraits.length} retrait(s) ajouté(s)`);
      }
    } catch (error) {
      toast.error('Erreur lors du traitement des retraits');
    }
  };

  // Calculate totals
  const totals = {
    ca: employees.reduce((sum, emp) => sum + emp.ca_total, 0),
    salaires: employees.reduce((sum, emp) => sum + emp.salaire, 0),
    primes: employees.reduce((sum, emp) => sum + emp.prime, 0),
    depenses: depenses.reduce((sum, dep) => sum + dep.montant, 0),
    retraits: retraits.reduce((sum, ret) => sum + ret.montant, 0)
  };

  // Save dotation
  const handleSave = async () => {
    setLoading(true);
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      toast.success('Dotation sauvegardée avec succès');
    } catch (error) {
      toast.error('Erreur lors de la sauvegarde');
    } finally {
      setLoading(false);
    }
  };

  // Send to archives
  const handleSendToArchives = async () => {
    setLoading(true);
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      toast.success('Dotation envoyée aux archives');
    } catch (error) {
      toast.error('Erreur lors de l\'envoi');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Gestion des Dotations</h2>
          <p className="text-muted-foreground">
            {userEntreprise && `Entreprise: ${userEntreprise}`}
            {readonly && " (Lecture seule - Staff)"}
          </p>
        </div>
        <div className="flex space-x-2">
          {!readonly && (
            <>
              <Button onClick={handleSave} disabled={loading}>
                <Save className="w-4 h-4 mr-2" />
                Enregistrer
              </Button>
              <Button onClick={handleSendToArchives} variant="outline" disabled={loading}>
                <Archive className="w-4 h-4 mr-2" />
                Envoyer aux archives
              </Button>
            </>
          )}
        </div>
      </div>

      {/* Current Balance */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Calculator className="w-5 h-5 mr-2" />
            Solde Actuel et Limites
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <Label htmlFor="solde">Solde Actuel (€)</Label>
              <Input
                id="solde"
                type="number"
                value={soldeActuel}
                onChange={(e) => setSoldeActuel(parseFloat(e.target.value) || 0)}
                disabled={readonly}
              />
            </div>
            <div>
              <Label>Limites Employé</Label>
              <div className="text-sm text-muted-foreground">
                Salaire: €5,000 - €25,000<br />
                Prime: €0 - €12,000
              </div>
            </div>
            <div>
              <Label>Limites Patron</Label>
              <div className="text-sm text-muted-foreground">
                Salaire: €8,000 - €40,000<br />
                Prime: €0 - €20,000
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Employees Section */}
      <Card>
        <CardHeader>
          <CardTitle>Tableau des Employés</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Paste Zone */}
          {!readonly && (
            <div className="space-y-2">
              <Label htmlFor="paste-employees">Zone de collage (Nom; RUN; FACTURE; VENTE)</Label>
              <Textarea
                id="paste-employees"
                placeholder="Pierre Martin; 15000; 8000; 12000&#10;Marie Dubois; 20000; 10000; 15000"
                value={pasteEmployeeData}
                onChange={(e) => setPasteEmployeeData(e.target.value)}
                rows={3}
              />
              <div className="flex space-x-2">
                <Button onClick={handleEmployeePaste} variant="outline" size="sm">
                  <Copy className="w-4 h-4 mr-2" />
                  Coller les données
                </Button>
                <Button onClick={addEmployee} variant="outline" size="sm">
                  <Plus className="w-4 h-4 mr-2" />
                  Ajouter un employé
                </Button>
              </div>
            </div>
          )}

          {/* Employees Table */}
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead>
                <tr className="border-b">
                  <th className="text-left p-2">Nom</th>
                  <th className="text-left p-2">RUN (€)</th>
                  <th className="text-left p-2">FACTURE (€)</th>
                  <th className="text-left p-2">VENTE (€)</th>
                  <th className="text-left p-2">CA Total (€)</th>
                  <th className="text-left p-2">Salaire (€)</th>
                  <th className="text-left p-2">Prime (€)</th>
                  {!readonly && <th className="text-left p-2">Actions</th>}
                </tr>
              </thead>
              <tbody>
                {employees.map((employee, index) => (
                  <tr key={employee.id} className="border-b">
                    <td className="p-2">
                      <Input
                        value={employee.name}
                        onChange={(e) => handleEmployeeChange(index, 'name', e.target.value)}
                        disabled={readonly}
                        className="min-w-0"
                      />
                    </td>
                    <td className="p-2">
                      <Input
                        type="number"
                        value={employee.run}
                        onChange={(e) => handleEmployeeChange(index, 'run', e.target.value)}
                        disabled={readonly}
                        className="min-w-0"
                      />
                    </td>
                    <td className="p-2">
                      <Input
                        type="number"
                        value={employee.facture}
                        onChange={(e) => handleEmployeeChange(index, 'facture', e.target.value)}
                        disabled={readonly}
                        className="min-w-0"
                      />
                    </td>
                    <td className="p-2">
                      <Input
                        type="number"
                        value={employee.vente}
                        onChange={(e) => handleEmployeeChange(index, 'vente', e.target.value)}
                        disabled={readonly}
                        className="min-w-0"
                      />
                    </td>
                    <td className="p-2">
                      <Badge variant="outline">{employee.ca_total.toLocaleString()}</Badge>
                    </td>
                    <td className="p-2">
                      <Badge variant="secondary">{employee.salaire.toLocaleString()}</Badge>
                    </td>
                    <td className="p-2">
                      <Badge variant="secondary">{employee.prime.toLocaleString()}</Badge>
                    </td>
                    {!readonly && (
                      <td className="p-2">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => removeEmployee(index)}
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

          {/* Totals */}
          <div className="flex justify-end space-x-4 p-4 bg-muted rounded-lg">
            <div className="text-right">
              <div className="text-sm text-muted-foreground">CA Total</div>
              <div className="font-bold">€{totals.ca.toLocaleString()}</div>
            </div>
            <div className="text-right">
              <div className="text-sm text-muted-foreground">Salaires Total</div>
              <div className="font-bold">€{totals.salaires.toLocaleString()}</div>
            </div>
            <div className="text-right">
              <div className="text-sm text-muted-foreground">Primes Total</div>
              <div className="font-bold">€{totals.primes.toLocaleString()}</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Expenses and Withdrawals */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Deductible Expenses */}
        <Card>
          <CardHeader>
            <CardTitle>Dépenses Déductibles</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {!readonly && (
              <div className="space-y-2">
                <Label htmlFor="paste-depenses">Zone de collage (Date; Justificatif; Montant)</Label>
                <Textarea
                  id="paste-depenses"
                  placeholder="2024-01-15; Fournitures bureau; 2500"
                  value={pasteDepenseData}
                  onChange={(e) => setPasteDepenseData(e.target.value)}
                  rows={2}
                />
                <Button onClick={handleDepensePaste} variant="outline" size="sm">
                  <Copy className="w-4 h-4 mr-2" />
                  Coller les dépenses
                </Button>
              </div>
            )}
            
            <div className="space-y-2 max-h-60 overflow-y-auto">
              {depenses.map((depense, index) => (
                <div key={depense.id} className="flex items-center justify-between p-2 border rounded">
                  <div className="flex-1">
                    <div className="text-sm font-medium">{depense.justificatif}</div>
                    <div className="text-xs text-muted-foreground">{depense.date}</div>
                  </div>
                  <Badge variant="outline">€{depense.montant.toLocaleString()}</Badge>
                  {!readonly && (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setDepenses(depenses.filter(d => d.id !== depense.id))}
                    >
                      <Trash2 className="w-3 h-3" />
                    </Button>
                  )}
                </div>
              ))}
            </div>
            
            <Separator />
            <div className="flex justify-between items-center font-bold">
              <span>Total Dépenses:</span>
              <span>€{totals.depenses.toLocaleString()}</span>
            </div>
          </CardContent>
        </Card>

        {/* Withdrawals */}
        <Card>
          <CardHeader>
            <CardTitle>Tableau des Retraits</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {!readonly && (
              <div className="space-y-2">
                <Label htmlFor="paste-retraits">Zone de collage (Date; Justificatif; Montant)</Label>
                <Textarea
                  id="paste-retraits"
                  placeholder="2024-01-10; Avance salaire Pierre; 5000"
                  value={pasteRetraitData}
                  onChange={(e) => setPasteRetraitData(e.target.value)}
                  rows={2}
                />
                <Button onClick={handleRetraitPaste} variant="outline" size="sm">
                  <Copy className="w-4 h-4 mr-2" />
                  Coller les retraits
                </Button>
              </div>
            )}
            
            <div className="space-y-2 max-h-60 overflow-y-auto">
              {retraits.map((retrait, index) => (
                <div key={retrait.id} className="flex items-center justify-between p-2 border rounded">
                  <div className="flex-1">
                    <div className="text-sm font-medium">{retrait.justificatif}</div>
                    <div className="text-xs text-muted-foreground">{retrait.date}</div>
                  </div>
                  <Badge variant="outline">€{retrait.montant.toLocaleString()}</Badge>
                  {!readonly && (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setRetraits(retraits.filter(r => r.id !== retrait.id))}
                    >
                      <Trash2 className="w-3 h-3" />
                    </Button>
                  )}
                </div>
              ))}
            </div>
            
            <Separator />
            <div className="flex justify-between items-center font-bold">
              <span>Total Retraits:</span>
              <span>€{totals.retraits.toLocaleString()}</span>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default DotationForm;