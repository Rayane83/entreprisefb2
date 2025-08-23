import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Badge } from './ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from './ui/dialog';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { 
  Search, 
  Download, 
  Eye, 
  Edit, 
  Check, 
  X, 
  Trash2,
  Upload,
  FileSpreadsheet 
} from 'lucide-react';
import { toast } from 'sonner';
import { useAuth } from '../contexts/AuthContext';
import { mockArchives } from '../data/mockData';
import * as XLSX from 'xlsx';

const ArchiveTable = () => {
  const { userRole, canAccessStaffConfig } = useAuth();
  const [archives, setArchives] = useState(mockArchives);
  const [filteredArchives, setFilteredArchives] = useState(mockArchives);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedArchive, setSelectedArchive] = useState(null);
  const [editingArchive, setEditingArchive] = useState(null);
  const [loading, setLoading] = useState(false);

  const isStaff = canAccessStaffConfig();
  const isPatronCoPatron = ['patron', 'co-patron'].includes(userRole);

  // Debounced search
  React.useEffect(() => {
    const timer = setTimeout(() => {
      if (searchTerm.trim() === '') {
        setFilteredArchives(archives);
      } else {
        const filtered = archives.filter(archive => {
          const searchStr = JSON.stringify(archive).toLowerCase();
          return searchStr.includes(searchTerm.toLowerCase());
        });
        setFilteredArchives(filtered);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [searchTerm, archives]);

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

    if (!confirm('Êtes-vous sûr de vouloir supprimer cette archive ?')) {
      return;
    }

    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setArchives(prev => prev.filter(archive => archive.id !== id));
      toast.success('Archive supprimée');
    } catch (error) {
      toast.error('Erreur lors de la suppression');
    } finally {
      setLoading(false);
    }
  };

  const exportToExcel = () => {
    const exportData = filteredArchives.map(archive => ({
      'ID': archive.id,
      'Type': archive.type,
      'Date': new Date(archive.date).toLocaleDateString('fr-FR'),
      'Montant': archive.montant,
      'Statut': archive.statut,
      'Entreprise': archive.entreprise_key,
      'Payload': JSON.stringify(archive.payload, null, 2)
    }));

    const worksheet = XLSX.utils.json_to_sheet(exportData);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Archives');

    const fileName = `archives_${new Date().toISOString().split('T')[0]}.xlsx`;
    XLSX.writeFile(workbook, fileName);
    toast.success(`Fichier ${fileName} exporté`);
  };

  const handleTemplateImport = (event) => {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const workbook = XLSX.read(e.target.result, { type: 'binary' });
        const sheetName = workbook.SheetNames[0];
        const sheet = workbook.Sheets[sheetName];
        
        toast.success('Template importé avec succès');
      } catch (error) {
        toast.error('Erreur lors de l\'import du template');
      }
    };
    reader.readAsBinaryString(file);
  };

  const getStatutColor = (statut) => {
    switch (statut.toLowerCase()) {
      case 'en attente': return 'bg-yellow-100 text-yellow-800';
      case 'validé': return 'bg-green-100 text-green-800';
      case 'refusé': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Gestion des Archives</h2>
          <p className="text-muted-foreground">
            Consultez et gérez les archives des dotations et documents
          </p>
        </div>
        <div className="flex items-center space-x-2">
          {isStaff && (
            <>
              <Label htmlFor="template-upload" className="cursor-pointer">
                <Button variant="outline" asChild>
                  <span>
                    <Upload className="w-4 h-4 mr-2" />
                    Template
                  </span>
                </Button>
              </Label>
              <Input
                id="template-upload"
                type="file"
                accept=".xlsx"
                className="hidden"
                onChange={handleTemplateImport}
              />
            </>
          )}
          <Button onClick={exportToExcel} variant="outline">
            <FileSpreadsheet className="w-4 h-4 mr-2" />
            Export Excel
          </Button>
        </div>
      </div>

      {/* Search Bar */}
      <Card>
        <CardContent className="p-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Rechercher dans les archives..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>
        </CardContent>
      </Card>

      {/* Archives Table */}
      <Card>
        <CardHeader>
          <CardTitle>
            Archives ({filteredArchives.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
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
                      <Badge variant="outline">{archive.type}</Badge>
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
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                        
                        {canEdit(archive) && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleEdit(archive)}
                          >
                            <Edit className="w-4 h-4" />
                          </Button>
                        )}
                        
                        {isStaff && archive.statut !== 'Validé' && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleValidate(archive.id)}
                            className="text-green-600 hover:text-green-700"
                          >
                            <Check className="w-4 h-4" />
                          </Button>
                        )}
                        
                        {isStaff && archive.statut !== 'Refusé' && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleReject(archive.id)}
                            className="text-red-600 hover:text-red-700"
                          >
                            <X className="w-4 h-4" />
                          </Button>
                        )}
                        
                        {isStaff && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleDelete(archive.id)}
                            className="text-red-600 hover:text-red-700"
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
          
          {filteredArchives.length === 0 && (
            <div className="text-center py-8">
              <FileSpreadsheet className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              <p className="text-muted-foreground">
                {searchTerm ? 'Aucune archive trouvée' : 'Aucune archive disponible'}
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* View Archive Modal */}
      <Dialog open={!!selectedArchive} onOpenChange={() => setSelectedArchive(null)}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Détails de l'Archive</DialogTitle>
          </DialogHeader>
          {selectedArchive && (
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
                <Label className="text-sm font-medium">Payload</Label>
                <pre className="mt-2 p-4 bg-muted rounded-lg text-sm overflow-auto max-h-60">
                  {JSON.stringify(selectedArchive.payload, null, 2)}
                </pre>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Edit Archive Modal */}
      <Dialog open={!!editingArchive} onOpenChange={() => setEditingArchive(null)}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Modifier l'Archive</DialogTitle>
          </DialogHeader>
          {editingArchive && (
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
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default ArchiveTable;