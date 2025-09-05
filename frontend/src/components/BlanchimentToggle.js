import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Badge } from './ui/badge';
import { Switch } from './ui/switch';
import { Textarea } from './ui/textarea';
import { Plus, Trash2, Save, AlertTriangle, Upload, Download, FileSpreadsheet, Copy } from 'lucide-react';
import { toast } from 'sonner';
import { useAuth } from '../contexts/AuthContext';
import { mockBlanchimentRows } from '../data/mockData';
import { exportBlanchiment, parseExcelData, formatBlanchimentData } from '../utils/excelExport';

const BlanchimentToggle = () => {
  const { userEntreprise, isReadOnlyForStaff, canAccessStaffConfig } = useAuth();
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
  const [rows, setRows] = useState(mockBlanchimentRows);
  const [newRow, setNewRow] = useState({
    statut: 'En cours',
    date_recu: '',
    date_rendu: '',
    groupe: '',
    employe: '',
    donneur_id: '',
    recep_id: '',
    somme: ''
  });
  const [loading, setLoading] = useState(false);
  const [pasteData, setPasteData] = useState('');
  const [showPasteArea, setShowPasteArea] = useState(false);

  const readonly = isReadOnlyForStaff();
  const canManageBlanchiment = canAccessStaffConfig(); // Seul le staff peut activer/désactiver
  const currentSettings = useGlobal ? globalSettings : localSettings;

  const calculateDuration = (dateRecu, dateRendu) => {
    if (!dateRecu || !dateRendu) return null;
    const start = new Date(dateRecu);
    const end = new Date(dateRendu);
    const diffTime = Math.abs(end - start);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  };

  const handleRowChange = (id, field, value) => {
    setRows(prev => prev.map(row => {
      if (row.id === id) {
        const updated = { ...row, [field]: value };
        
        // Recalculate duration if dates changed
        if (field === 'date_recu' || field === 'date_rendu') {
          updated.duree = calculateDuration(updated.date_recu, updated.date_rendu);
        }
        
        // Update percentages from current settings
        updated.entreprise_perc = currentSettings.perc_entreprise;
        updated.groupe_perc = currentSettings.perc_groupe;
        
        return updated;
      }
      return row;
    }));
  };

  const addNewRow = () => {
    if (!newRow.groupe || !newRow.employe || !newRow.somme) {
      toast.error('Veuillez remplir tous les champs obligatoires');
      return;
    }

    const row = {
      id: `new-${Date.now()}`,
      ...newRow,
      somme: parseFloat(newRow.somme) || 0,
      duree: calculateDuration(newRow.date_recu, newRow.date_rendu),
      entreprise_perc: currentSettings.perc_entreprise,
      groupe_perc: currentSettings.perc_groupe
    };

    setRows(prev => [row, ...prev]);
    setNewRow({
      statut: 'En cours',
      date_recu: '',
      date_rendu: '',
      groupe: '',
      employe: '',
      donneur_id: '',
      recep_id: '',
      somme: ''
    });
    toast.success('Nouvelle ligne ajoutée');
  };

  const removeRow = (id) => {
    setRows(prev => prev.filter(row => row.id !== id));
    toast.success('Ligne supprimée');
  };

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
        comments: `Donneur: ${row.donneur_id}, Récepteur: ${row.recep_id}`
      }));

      exportBlanchiment(exportData, `blanchiment_${userEntreprise}_${new Date().toISOString().split('T')[0]}.xlsx`);
      toast.success('Export Excel réussi');
    } catch (error) {
      console.error('Erreur export:', error);
      toast.error('Erreur lors de l\'export Excel');
    }
  };

  const handlePasteData = () => {
    if (!pasteData.trim()) {
      toast.error('Aucune donnée à traiter');
      return;
    }

    try {
      const expectedColumns = ['Date Transaction', 'Montant', 'Groupe', 'Employé', 'Donneur ID', 'Récepteur ID'];
      const parsed = parseExcelData(pasteData, expectedColumns);

      if (!parsed.success) {
        toast.error(`Erreur de format: ${parsed.error}`);
        return;
      }

      const newRows = parsed.data.map((row, index) => ({
        id: `paste-${Date.now()}-${index}`,
        statut: 'En cours',
        date_recu: row['Date Transaction'] || row['Date'] || row['date'] || '',
        date_rendu: '',
        groupe: row['Groupe'] || row['groupe'] || '',
        employe: row['Employé'] || row['employe'] || row['Employe'] || '',
        donneur_id: row['Donneur ID'] || row['donneur'] || '',
        recep_id: row['Récepteur ID'] || row['recep'] || row['recepteur'] || '',
        somme: parseFloat(row['Montant'] || row['montant'] || row['Somme'] || 0),
        duree: null,
        entreprise_perc: currentSettings.perc_entreprise,
        groupe_perc: currentSettings.perc_groupe
      }));

      setRows(prev => [...newRows, ...prev]);
      setPasteData('');
      setShowPasteArea(false);
      toast.success(`${newRows.length} opération(s) ajoutée(s) depuis les données collées`);
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

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Gestion du Blanchiment</h2>
          <p className="text-muted-foreground">
            {userEntreprise && `Entreprise: ${userEntreprise}`}
            {readonly && " (Lecture seule - Staff)"}
          </p>
        </div>
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2">
            <Switch
              checked={blanchimentEnabled}
              onCheckedChange={setBlanchimentEnabled}
              disabled={!canManageBlanchiment} // Seul le staff peut activer/désactiver
            />
            <Label className="text-sm">
              {blanchimentEnabled ? 'Activé' : 'Désactivé'}
            </Label>
          </div>
          
          <div className="flex items-center space-x-2">
            {blanchimentEnabled && rows.length > 0 && (
              <Button variant="outline" onClick={handleExportExcel}>
                <Download className="w-4 h-4 mr-2" />
                Export Excel
              </Button>
            )}
            
            {!readonly && blanchimentEnabled && (
              <Button 
                variant="outline" 
                onClick={() => setShowPasteArea(!showPasteArea)}
              >
                <Copy className="w-4 h-4 mr-2" />
                Coller Données
              </Button>
            )}
            
            {!readonly && (
              <Button onClick={handleSave} disabled={loading}>
                <Save className="w-4 h-4 mr-2" />
                Sauvegarder
              </Button>
            )}
          </div>
        </div>
      </div>

      {!blanchimentEnabled && (
        <Card className="border-yellow-200 bg-yellow-50">
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <AlertTriangle className="w-5 h-5 text-yellow-600" />
              <span className="text-yellow-800">
                Le blanchiment est désactivé pour cette entreprise
              </span>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Settings */}
      <Card>
        <CardHeader>
          <CardTitle>Configuration des Pourcentages</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center space-x-4">
            <Switch
              checked={useGlobal}
              onCheckedChange={setUseGlobal}
              disabled={readonly}
            />
            <Label>Utiliser les paramètres globaux</Label>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <h4 className="font-medium">
                {useGlobal ? 'Paramètres Globaux' : 'Paramètres Locaux'}
              </h4>
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

      {/* Paste Data Area */}
      {!readonly && blanchimentEnabled && showPasteArea && (
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
                Format attendu: Date Transaction | Montant | Groupe | Employé | Donneur ID | Récepteur ID
              </p>
              <Textarea
                id="paste-area"
                placeholder="Collez vos données ici... (Ctrl+V)
Exemple:
2024-01-15	50000	Alpha	John Doe	123456	789012
2024-01-16	75000	Beta	Jane Smith	456789	012345"
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
            <div className="text-xs text-muted-foreground">
              <p><strong>Conseils:</strong></p>
              <ul className="list-disc list-inside space-y-1">
                <li>Copiez directement depuis Excel (Ctrl+C puis Ctrl+V)</li>
                <li>Les données peuvent être séparées par des tabulations, virgules ou points-virgules</li>
                <li>La première ligne peut contenir des en-têtes (optionnel)</li>
                <li>Les montants doivent être numériques</li>
              </ul>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Add New Row */}
      {!readonly && blanchimentEnabled && (
        <Card>
          <CardHeader>
            <CardTitle>Ajouter une Opération</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
              <div>
                <Label htmlFor="new_groupe">Groupe</Label>
                <Input
                  id="new_groupe"
                  value={newRow.groupe}
                  onChange={(e) => setNewRow(prev => ({ ...prev, groupe: e.target.value }))}
                  placeholder="Alpha, Beta, Gamma..."
                />
              </div>
              <div>
                <Label htmlFor="new_employe">Employé</Label>
                <Input
                  id="new_employe"
                  value={newRow.employe}
                  onChange={(e) => setNewRow(prev => ({ ...prev, employe: e.target.value }))}
                  placeholder="Nom de l'employé"
                />
              </div>
              <div>
                <Label htmlFor="new_somme">Somme (€)</Label>
                <Input
                  id="new_somme"
                  type="number"
                  value={newRow.somme}
                  onChange={(e) => setNewRow(prev => ({ ...prev, somme: e.target.value }))}
                  placeholder="50000"
                />
              </div>
              <div>
                <Label htmlFor="new_date_recu">Date Reçu</Label>
                <Input
                  id="new_date_recu"
                  type="date"
                  value={newRow.date_recu}
                  onChange={(e) => setNewRow(prev => ({ ...prev, date_recu: e.target.value }))}
                />
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div>
                <Label htmlFor="new_donneur_id">ID Donneur</Label>
                <Input
                  id="new_donneur_id"
                  value={newRow.donneur_id}
                  onChange={(e) => setNewRow(prev => ({ ...prev, donneur_id: e.target.value }))}
                  placeholder="123456"
                />
              </div>
              <div>
                <Label htmlFor="new_recep_id">ID Récepteur</Label>
                <Input
                  id="new_recep_id"
                  value={newRow.recep_id}
                  onChange={(e) => setNewRow(prev => ({ ...prev, recep_id: e.target.value }))}
                  placeholder="789012"
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
              <div className="flex items-end">
                <Button onClick={addNewRow} className="w-full">
                  <Plus className="w-4 h-4 mr-2" />
                  Ajouter
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Rows Table */}
      {blanchimentEnabled && (
        <Card>
          <CardHeader>
            <CardTitle>Opérations de Blanchiment ({rows.length})</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left p-2">Statut</th>
                    <th className="text-left p-2">Date Reçu</th>
                    <th className="text-left p-2">Date Rendu</th>
                    <th className="text-left p-2">Durée (j)</th>
                    <th className="text-left p-2">Groupe</th>
                    <th className="text-left p-2">Employé</th>
                    <th className="text-left p-2">Somme (€)</th>
                    <th className="text-left p-2">Ent. %</th>
                    <th className="text-left p-2">Grp. %</th>
                    {!readonly && <th className="text-left p-2">Actions</th>}
                  </tr>
                </thead>
                <tbody>
                  {rows.map((row) => (
                    <tr key={row.id} className="border-b">
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
                          className="w-auto"
                        />
                      </td>
                      <td className="p-2">
                        <Input
                          type="date"
                          value={row.date_rendu || ''}
                          onChange={(e) => handleRowChange(row.id, 'date_rendu', e.target.value)}
                          disabled={readonly}
                          className="w-auto"
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
                          className="w-24"
                        />
                      </td>
                      <td className="p-2">
                        <Input
                          value={row.employe}
                          onChange={(e) => handleRowChange(row.id, 'employe', e.target.value)}
                          disabled={readonly}
                          className="w-32"
                        />
                      </td>
                      <td className="p-2">
                        <Input
                          type="number"
                          value={row.somme}
                          onChange={(e) => handleRowChange(row.id, 'somme', parseFloat(e.target.value) || 0)}
                          disabled={readonly}
                          className="w-24"
                        />
                      </td>
                      <td className="p-2 text-sm text-muted-foreground">
                        {row.entreprise_perc}%
                      </td>
                      <td className="p-2 text-sm text-muted-foreground">
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
            
            {rows.length === 0 && (
              <div className="text-center py-8">
                <AlertTriangle className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                <p className="text-muted-foreground">Aucune opération de blanchiment</p>
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default BlanchimentToggle;