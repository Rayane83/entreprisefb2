import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Badge } from './ui/badge';
import { Upload, FileText, Download, Trash2, Eye } from 'lucide-react';
import { toast } from 'sonner';

const DocsUpload = () => {
  const [documents, setDocuments] = useState([
    {
      id: 1,
      name: 'Facture_Janvier_2024.pdf',
      type: 'Facture',
      size: '245 KB',
      date: '2024-01-25',
      url: '#'
    },
    {
      id: 2,
      name: 'Diplome_Formation_Securite.pdf',
      type: 'Diplôme',
      size: '892 KB',
      date: '2024-01-20',
      url: '#'
    },
    {
      id: 3,
      name: 'Contrat_Prestation_EMS.pdf',
      type: 'Contrat',
      size: '156 KB',
      date: '2024-01-18',
      url: '#'
    }
  ]);

  const [uploading, setUploading] = useState(false);
  const [dragOver, setDragOver] = useState(false);

  const handleFileUpload = async (files) => {
    setUploading(true);
    try {
      // Simulate file upload
      for (const file of files) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        const newDoc = {
          id: Date.now() + Math.random(),
          name: file.name,
          type: getDocType(file.name),
          size: formatFileSize(file.size),
          date: new Date().toISOString().split('T')[0],
          url: URL.createObjectURL(file)
        };
        
        setDocuments(prev => [newDoc, ...prev]);
      }
      
      toast.success(`${files.length} document(s) téléchargé(s)`);
    } catch (error) {
      toast.error('Erreur lors du téléchargement');
    } finally {
      setUploading(false);
    }
  };

  const getDocType = (filename) => {
    const lower = filename.toLowerCase();
    if (lower.includes('facture')) return 'Facture';
    if (lower.includes('diplome') || lower.includes('certificate')) return 'Diplôme';
    if (lower.includes('contrat')) return 'Contrat';
    return 'Document';
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
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
  };

  const removeDocument = (id) => {
    setDocuments(prev => prev.filter(doc => doc.id !== id));
    toast.success('Document supprimé');
  };

  const downloadDocument = (doc) => {
    // Simulate download
    toast.success(`Téléchargement de ${doc.name}`);
  };

  const viewDocument = (doc) => {
    // Simulate view
    toast.success(`Ouverture de ${doc.name}`);
  };

  const getTypeColor = (type) => {
    switch (type) {
      case 'Facture': return 'bg-blue-100 text-blue-800';
      case 'Diplôme': return 'bg-green-100 text-green-800';
      case 'Contrat': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">Gestion des Documents</h2>
        <p className="text-muted-foreground">
          Téléchargez et gérez vos factures, diplômes et autres documents
        </p>
      </div>

      {/* Upload Zone */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Upload className="w-5 h-5 mr-2" />
            Téléchargement de Documents
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
              Formats acceptés: PDF, DOC, DOCX, JPG, PNG (Max 10MB)
            </p>
            <div className="flex items-center justify-center space-x-4">
              <Label htmlFor="file-upload" className="cursor-pointer">
                <Button disabled={uploading} asChild>
                  <span>
                    {uploading ? (
                      <div className="loading-dots mr-2">
                        <span>•</span>
                        <span>•</span>
                        <span>•</span>
                      </div>
                    ) : (
                      <Upload className="w-4 h-4 mr-2" />
                    )}
                    {uploading ? 'Téléchargement...' : 'Parcourir les fichiers'}
                  </span>
                </Button>
              </Label>
              <Input
                id="file-upload"
                type="file"
                multiple
                className="hidden"
                onChange={handleFileInput}
                accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Documents List */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span className="flex items-center">
              <FileText className="w-5 h-5 mr-2" />
              Documents ({documents.length})
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {documents.length === 0 ? (
            <div className="text-center py-8">
              <FileText className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              <p className="text-muted-foreground">Aucun document téléchargé</p>
            </div>
          ) : (
            <div className="space-y-3">
              {documents.map((doc) => (
                <div key={doc.id} className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/50 transition-colors">
                  <div className="flex items-center space-x-4 flex-1">
                    <FileText className="w-8 h-8 text-primary" />
                    <div className="flex-1">
                      <div className="font-medium">{doc.name}</div>
                      <div className="text-sm text-muted-foreground">
                        {doc.size} • Téléchargé le {new Date(doc.date).toLocaleDateString('fr-FR')}
                      </div>
                    </div>
                    <Badge className={getTypeColor(doc.type)}>
                      {doc.type}
                    </Badge>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => viewDocument(doc)}
                    >
                      <Eye className="w-4 h-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => downloadDocument(doc)}
                    >
                      <Download className="w-4 h-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => removeDocument(doc.id)}
                      className="text-destructive hover:text-destructive"
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Document Statistics */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold text-blue-600">{documents.filter(d => d.type === 'Facture').length}</div>
            <div className="text-sm text-muted-foreground">Factures</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold text-green-600">{documents.filter(d => d.type === 'Diplôme').length}</div>
            <div className="text-sm text-muted-foreground">Diplômes</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold text-purple-600">{documents.filter(d => d.type === 'Contrat').length}</div>
            <div className="text-sm text-muted-foreground">Contrats</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6 text-center">
            <div className="text-2xl font-bold">{documents.length}</div>
            <div className="text-sm text-muted-foreground">Total</div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default DocsUpload;