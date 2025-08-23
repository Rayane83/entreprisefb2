import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Badge } from './ui/badge';
import { Calculator, Save, FileText } from 'lucide-react';
import { toast } from 'sonner';
import { useAuth } from '../contexts/AuthContext';

const ImpotForm = () => {
  const { userEntreprise, isReadOnlyForStaff } = useAuth();
  const [formData, setFormData] = useState({
    revenus_totaux: 250000,
    revenus_imposables: 200000,
    abattements: 50000,
    taux_impot: 0.15,
    impot_calcule: 30000,
    avantages_nature: 15000,
    frais_professionnels: 8000
  });
  const [loading, setLoading] = useState(false);

  const readonly = isReadOnlyForStaff();

  const handleInputChange = (field, value) => {
    const numValue = parseFloat(value) || 0;
    setFormData(prev => ({
      ...prev,
      [field]: numValue
    }));
    
    // Auto-calculate tax when relevant fields change
    if (['revenus_imposables', 'taux_impot', 'abattements'].includes(field)) {
      calculateTax();
    }
  };

  const calculateTax = () => {
    const base = formData.revenus_imposables - formData.abattements;
    const impot = Math.max(0, base * formData.taux_impot);
    
    setFormData(prev => ({
      ...prev,
      impot_calcule: Math.round(impot)
    }));
  };

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

  const handleSubmit = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1500));
      toast.success('Déclaration soumise aux autorités fiscales');
    } catch (error) {
      toast.error('Erreur lors de la soumission');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Déclaration d'Impôts</h2>
          <p className="text-muted-foreground">
            {userEntreprise && `Entreprise: ${userEntreprise}`}
            {readonly && " (Lecture seule - Staff)"}
          </p>
        </div>
        <div className="flex space-x-2">
          {!readonly && (
            <>
              <Button onClick={handleSave} variant="outline" disabled={loading}>
                <Save className="w-4 h-4 mr-2" />
                Sauvegarder
              </Button>
              <Button onClick={handleSubmit} disabled={loading}>
                <FileText className="w-4 h-4 mr-2" />
                Soumettre
              </Button>
            </>
          )}
        </div>
      </div>

      {/* Tax Calculation Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Calculator className="w-5 h-5 mr-2" />
            Calcul de l'Impôt
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div>
                <Label htmlFor="revenus_totaux">Revenus Totaux (€)</Label>
                <Input
                  id="revenus_totaux"
                  type="number"
                  value={formData.revenus_totaux}
                  onChange={(e) => handleInputChange('revenus_totaux', e.target.value)}
                  disabled={readonly}
                />
              </div>
              
              <div>
                <Label htmlFor="revenus_imposables">Revenus Imposables (€)</Label>
                <Input
                  id="revenus_imposables"
                  type="number"
                  value={formData.revenus_imposables}
                  onChange={(e) => handleInputChange('revenus_imposables', e.target.value)}
                  disabled={readonly}
                />
              </div>
              
              <div>
                <Label htmlFor="abattements">Abattements (€)</Label>
                <Input
                  id="abattements"
                  type="number"
                  value={formData.abattements}
                  onChange={(e) => handleInputChange('abattements', e.target.value)}
                  disabled={readonly}
                />
              </div>
              
              <div>
                <Label htmlFor="taux_impot">Taux d'Impôt (%)</Label>
                <Input
                  id="taux_impot"
                  type="number"
                  step="0.01"
                  value={formData.taux_impot * 100}
                  onChange={(e) => handleInputChange('taux_impot', parseFloat(e.target.value) / 100)}
                  disabled={readonly}
                />
              </div>
            </div>
            
            <div className="space-y-4">
              <div>
                <Label htmlFor="avantages_nature">Avantages en Nature (€)</Label>
                <Input
                  id="avantages_nature"
                  type="number"
                  value={formData.avantages_nature}
                  onChange={(e) => handleInputChange('avantages_nature', e.target.value)}
                  disabled={readonly}
                />
              </div>
              
              <div>
                <Label htmlFor="frais_professionnels">Frais Professionnels (€)</Label>
                <Input
                  id="frais_professionnels"
                  type="number"
                  value={formData.frais_professionnels}
                  onChange={(e) => handleInputChange('frais_professionnels', e.target.value)}
                  disabled={readonly}
                />
              </div>
              
              <div className="p-4 bg-primary/10 rounded-lg">
                <Label className="text-sm text-muted-foreground">Impôt Calculé</Label>
                <div className="text-3xl font-bold text-primary">
                  €{formData.impot_calcule.toLocaleString()}
                </div>
              </div>
              
              <Button
                onClick={calculateTax}
                variant="outline"
                className="w-full"
                disabled={readonly}
              >
                <Calculator className="w-4 h-4 mr-2" />
                Recalculer
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Summary Card */}
      <Card>
        <CardHeader>
          <CardTitle>Résumé de la Déclaration</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center p-4 border rounded-lg">
              <div className="text-sm text-muted-foreground">Base Imposable</div>
              <div className="text-xl font-bold">
                €{(formData.revenus_imposables - formData.abattements).toLocaleString()}
              </div>
            </div>
            <div className="text-center p-4 border rounded-lg">
              <div className="text-sm text-muted-foreground">Taux Appliqué</div>
              <div className="text-xl font-bold">
                {(formData.taux_impot * 100).toFixed(1)}%
              </div>
            </div>
            <div className="text-center p-4 border rounded-lg bg-destructive/10">
              <div className="text-sm text-muted-foreground">Impôt à Payer</div>
              <div className="text-xl font-bold text-destructive">
                €{formData.impot_calcule.toLocaleString()}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tax Brackets Information */}
      <Card>
        <CardHeader>
          <CardTitle>Barème de l'Impôt sur la Fortune</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left p-2">Tranche</th>
                  <th className="text-left p-2">De (€)</th>
                  <th className="text-left p-2">À (€)</th>
                  <th className="text-left p-2">Taux (%)</th>
                </tr>
              </thead>
              <tbody>
                <tr className="border-b">
                  <td className="p-2">Tranche 1</td>
                  <td className="p-2">0</td>
                  <td className="p-2">100,000</td>
                  <td className="p-2">10%</td>
                </tr>
                <tr className="border-b">
                  <td className="p-2">Tranche 2</td>
                  <td className="p-2">100,001</td>
                  <td className="p-2">500,000</td>
                  <td className="p-2">15%</td>
                </tr>
                <tr className="border-b">
                  <td className="p-2">Tranche 3</td>
                  <td className="p-2">500,001</td>
                  <td className="p-2">∞</td>
                  <td className="p-2">20%</td>
                </tr>
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default ImpotForm;