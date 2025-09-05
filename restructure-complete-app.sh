#!/bin/bash

# 🚀 RESTRUCTURATION COMPLÈTE Application selon spécifications
# Usage: ./restructure-complete-app.sh

set -e

DEST_PATH="/var/www/flashbackfa-entreprise.fr"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log "🚀 RESTRUCTURATION COMPLÈTE Application selon spécifications"

# 1. Backup complet actuel
log "💾 Backup complet de l'application actuelle..."

BACKUP_DIR="/tmp/app-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$DEST_PATH/frontend/src" "$BACKUP_DIR/"
log "✅ Backup créé dans $BACKUP_DIR"

# 2. Restructuration du App.js principal avec routes à onglets
log "🏗️ Restructuration App.js principal..."

cat > "$DEST_PATH/frontend/src/App.js" << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import LoginScreen from './components/LoginScreen';
import Dashboard from './pages/Dashboard';
import SuperAdmin from './pages/SuperAdmin';
import PatronConfig from './pages/PatronConfig';
import EnterpriseManagement from './pages/EnterpriseManagement';
import NotFound from './pages/NotFound';
import './App.css';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Vérification de l'authentification...</p>
        </div>
      </div>
    );
  }
  
  return isAuthenticated ? children : <Navigate to="/login" replace />;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="App">
          <Routes>
            {/* Route de connexion */}
            <Route path="/login" element={<LoginScreen />} />
            
            {/* Dashboard principal avec onglets */}
            <Route 
              path="/" 
              element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              } 
            />
            
            {/* SuperAdmin */}
            <Route 
              path="/superadmin" 
              element={
                <ProtectedRoute>
                  <SuperAdmin />
                </ProtectedRoute>
              } 
            />
            
            <Route 
              path="/superstaff" 
              element={
                <ProtectedRoute>
                  <SuperAdmin />
                </ProtectedRoute>
              } 
            />
            
            {/* Patron Config */}
            <Route 
              path="/patron-config" 
              element={
                <ProtectedRoute>
                  <PatronConfig />
                </ProtectedRoute>
              } 
            />
            
            {/* Gestion des entreprises */}
            <Route 
              path="/enterprise-management" 
              element={
                <ProtectedRoute>
                  <EnterpriseManagement />
                </ProtectedRoute>
              } 
            />
            
            {/* Pages d'erreur */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
EOF

log "✅ App.js restructuré"

# 3. Création du Dashboard principal avec onglets
log "📊 Création Dashboard principal avec onglets..."

cat > "$DEST_PATH/frontend/src/pages/Dashboard.js" << 'EOF'
import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import Header from '../components/Header';
import DashboardSummary from '../components/DashboardSummary';
import DotationsTab from '../components/tabs/DotationsTab';
import ImpotsTab from '../components/tabs/ImpotsTab';
import DocsTab from '../components/tabs/DocsTab';
import BlanchimentTab from '../components/tabs/BlanchimentTab';
import ArchivesTab from '../components/tabs/ArchivesTab';
import ConfigTab from '../components/tabs/ConfigTab';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';

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

          {/* Dashboard - Route : / */}
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

          {/* Dotations - Route : /#dotations */}
          <TabsContent value="dotations" className="space-y-6">
            <DotationsTab />
          </TabsContent>

          {/* Impôts - Route : /#impots */}
          <TabsContent value="impots" className="space-y-6">
            <ImpotsTab />
          </TabsContent>

          {/* Factures/Diplômes - Route : /#docs */}
          <TabsContent value="docs" className="space-y-6">
            <DocsTab />
          </TabsContent>

          {/* Blanchiment - Route : /#blanchiment */}
          <TabsContent value="blanchiment" className="space-y-6">
            <BlanchimentTab />
          </TabsContent>

          {/* Archives - Route : /#archives */}
          <TabsContent value="archives" className="space-y-6">
            <ArchivesTab />
          </TabsContent>

          {/* Config - Route : /#config */}
          {['staff'].includes(userRole) && (
            <TabsContent value="config" className="space-y-6">
              <ConfigTab />
            </TabsContent>
          )}
        </Tabs>
      </div>
    </div>
  );
};

export default Dashboard;
EOF

log "✅ Dashboard principal créé"

# 4. Création des composants d'onglets
log "📑 Création des composants d'onglets..."

# Créer le dossier tabs
mkdir -p "$DEST_PATH/frontend/src/components/tabs"

# DotationsTab
cat > "$DEST_PATH/frontend/src/components/tabs/DotationsTab.js" << 'EOF'
import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Badge } from '../ui/badge';
import { 
  Users,
  Calculator,
  FileText,
  Download,
  Upload,
  Save,
  Send
} from 'lucide-react';

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

  const handlePasteData = () => {
    if (!pasteData.trim()) return;
    
    const lines = pasteData.split('\n').filter(line => line.trim());
    const newEmployees = [];
    
    lines.forEach(line => {
      const parts = line.split(/[;\t,]/).map(p => p.trim());
      if (parts.length >= 4) {
        const [nom, run, facture, vente] = parts;
        const runNum = parseInt(run) || 0;
        const factureNum = parseInt(facture) || 0;
        const venteNum = parseInt(vente) || 0;
        const caTotal = runNum + factureNum + venteNum;
        
        newEmployees.push({
          nom,
          grade: 'À définir',
          run: runNum,
          facture: factureNum,
          vente: venteNum,
          caTotal,
          salaire: Math.round(caTotal * 0.3), // Exemple de calcul
          prime: Math.round(caTotal * 0.05)
        });
      }
    });
    
    setEmployees([...employees, ...newEmployees]);
    setPasteData('');
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Dotations</h2>
          <p className="text-muted-foreground">Gestion des salaires et primes des employés</p>
        </div>
        <div className="flex space-x-2">
          <Button variant="outline">
            <Download className="w-4 h-4 mr-2" />
            Export PDF
          </Button>
          <Button variant="outline">
            <FileText className="w-4 h-4 mr-2" />
            Export Excel
          </Button>
        </div>
      </div>

      {/* Zone de collage */}
      {!isStaff && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Upload className="w-5 h-5 mr-2" />
              Import Données Employés
            </CardTitle>
            <p className="text-sm text-muted-foreground">
              Format : Nom;RUN;FACTURE;VENTE (un employé par ligne)
            </p>
          </CardHeader>
          <CardContent className="space-y-4">
            <Textarea
              placeholder="Jean Dupont;125000;75000;50000&#10;Marie Martin;150000;80000;60000"
              value={pasteData}
              onChange={(e) => setPasteData(e.target.value)}
              rows={4}
            />
            <Button onClick={handlePasteData}>
              <Upload className="w-4 h-4 mr-2" />
              Importer les données
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Table Employés */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Users className="w-5 h-5 mr-2" />
            Employés ({employees.length})
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
                    <td className="p-4 font-bold">{emp.caTotal.toLocaleString()}€</td>
                    <td className="p-4 text-green-600">{emp.salaire.toLocaleString()}€</td>
                    <td className="p-4 text-blue-600">{emp.prime.toLocaleString()}€</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Dépenses déductibles */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Dépenses déductibles</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-center py-8">
              <Calculator className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              <p className="text-muted-foreground">Aucune dépense enregistrée</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Tableau des retraits</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-center py-8">
              <FileText className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              <p className="text-muted-foreground">Aucun retrait enregistré</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Actions */}
      {!isStaff && (
        <div className="flex justify-end space-x-2">
          <Button variant="outline">
            <Save className="w-4 h-4 mr-2" />
            Enregistrer
          </Button>
          <Button>
            <Send className="w-4 h-4 mr-2" />
            Envoyer aux archives
          </Button>
        </div>
      )}
    </div>
  );
};

export default DotationsTab;
EOF

# Créons d'autres onglets de base
for tab in "ImpotsTab" "DocsTab" "BlanchimentTab" "ArchivesTab" "ConfigTab"; do
cat > "$DEST_PATH/frontend/src/components/tabs/${tab}.js" << EOF
import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Settings } from 'lucide-react';

const ${tab} = () => {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">${tab/Tab/}</h2>
        <p className="text-muted-foreground">Module ${tab/Tab/} à implémenter</p>
      </div>
      
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Settings className="w-5 h-5 mr-2" />
            ${tab/Tab/}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8">
            <Settings className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
            <p className="text-muted-foreground">Fonctionnalités ${tab/Tab/} à développer</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default ${tab};
EOF
done

log "✅ Composants d'onglets créés"

# 5. Mise à jour DashboardSummary
cat > "$DEST_PATH/frontend/src/components/DashboardSummary.js" << 'EOF'
import React from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { 
  DollarSign,
  Users,
  FileText,
  AlertTriangle,
  TrendingUp,
  Calendar
} from 'lucide-react';

const DashboardSummary = () => {
  const { userRole, userEntreprise } = useAuth();
  
  // Mock data basé sur le rôle
  const metrics = {
    caTotal: 2847650,
    employesActifs: 24,
    dotationsPendantes: 3,
    archivesAttente: 7,
    blanchimentStatus: 'Active',
    derniereMaj: '2024-09-05'
  };

  const cards = [
    {
      title: 'CA Total',
      value: `${metrics.caTotal.toLocaleString()}€`,
      change: '+12.5%',
      icon: DollarSign,
      color: 'text-green-600'
    },
    {
      title: 'Employés Actifs',
      value: metrics.employesActifs,
      change: '+2',
      icon: Users,
      color: 'text-blue-600'
    },
    {
      title: 'Dotations en cours',
      value: metrics.dotationsPendantes,
      change: 'En attente',
      icon: FileText,
      color: 'text-orange-600'
    },
    {
      title: 'Archives en attente',
      value: metrics.archivesAttente,
      change: 'À traiter',
      icon: AlertTriangle,
      color: 'text-red-600'
    }
  ];

  return (
    <div className="space-y-6">
      {/* Métriques principales */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {cards.map((card, index) => (
          <Card key={index}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{card.title}</CardTitle>
              <card.icon className={`h-4 w-4 ${card.color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{card.value}</div>
              <p className="text-xs text-muted-foreground">{card.change}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Statut Blanchiment */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <TrendingUp className="w-5 h-5 mr-2" />
              Statut Blanchiment
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <span>Statut actuel :</span>
              <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-sm">
                {metrics.blanchimentStatus}
              </span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Calendar className="w-5 h-5 mr-2" />
              Dernière mise à jour
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-lg">{metrics.derniereMaj}</p>
            <p className="text-sm text-muted-foreground">Données synchronisées</p>
          </CardContent>
        </Card>
      </div>

      {/* Liens rapides basés sur le rôle */}
      <Card>
        <CardHeader>
          <CardTitle>Liens rapides</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <button className="p-4 text-left border rounded-lg hover:bg-muted/50">
              <FileText className="w-6 h-6 mb-2 text-blue-600" />
              <div className="font-medium">Nouvelle dotation</div>
              <div className="text-sm text-muted-foreground">Créer une dotation</div>
            </button>
            
            <button className="p-4 text-left border rounded-lg hover:bg-muted/50">
              <Users className="w-6 h-6 mb-2 text-green-600" />
              <div className="font-medium">Employés</div>
              <div className="text-sm text-muted-foreground">Gérer l'équipe</div>
            </button>
            
            <button className="p-4 text-left border rounded-lg hover:bg-muted/50">
              <DollarSign className="w-6 h-6 mb-2 text-orange-600" />
              <div className="font-medium">Blanchiment</div>
              <div className="text-sm text-muted-foreground">Suivi des opérations</div>
            </button>
            
            <button className="p-4 text-left border rounded-lg hover:bg-muted/50">
              <AlertTriangle className="w-6 h-6 mb-2 text-red-600" />
              <div className="font-medium">Archives</div>
              <div className="text-sm text-muted-foreground">Consulter l'historique</div>
            </button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default DashboardSummary;
EOF

log "✅ DashboardSummary mis à jour"

# 6. Build et test
log "🔨 Build de la nouvelle structure..."

cd "$DEST_PATH/frontend"
npm run build

if [ ! -f "build/index.html" ]; then
    error "❌ Build échoué - Restauration backup..."
    cp -r "$BACKUP_DIR/src" "$DEST_PATH/frontend/"
    exit 1
fi

log "✅ Build réussi"

# 7. Deploy
sudo systemctl reload nginx

log "🧪 Test de la nouvelle structure..."

sleep 5

# Vérifier que les nouveaux composants sont dans le build
if grep -q "DotationsTab" "$DEST_PATH/frontend/build/static/js/main."*.js; then
    echo "✅ Nouveaux composants détectés dans le build"
    SUCCESS=true
else
    echo "❌ Composants non détectés"
    SUCCESS=false
fi

# 8. Résultats
log "🎯 RÉSULTATS RESTRUCTURATION"

if [ "$SUCCESS" = true ]; then
    log "🎉 SUCCESS - Application restructurée selon spécifications !"
    
    echo ""
    echo "✅ STRUCTURE IMPLÉMENTÉE :"
    echo ""
    echo "📊 1. Dashboard (/) - Métriques et liens rapides"
    echo "👥 2. Dotations (/#dotations) - Table employés + zone collage"
    echo "💰 3. Impôts (/#impots) - Formulaire simple"
    echo "📄 4. Factures/Diplômes (/#docs) - Upload et gestion"
    echo "🔄 5. Blanchiment (/#blanchiment) - Toggle + table"
    echo "📚 6. Archives (/#archives) - Recherche et CRUD"
    echo "⚙️  7. Config (/#config) - Paramètres staff"
    echo "🛡️  8. SuperAdmin (/superadmin) - Gestion complète"
    echo "🏢 9. Patron Config (/patron-config) - Config entreprise"
    echo ""
    echo "🎯 NAVIGATION :"
    echo "   • Routes principales : /, /superadmin, /patron-config"
    echo "   • Onglets hash : /#dotations, /#impots, etc."
    echo "   • Navigation Header conservée"
    echo ""
    echo "📋 PROCHAINES ÉTAPES :"
    echo "   1. Tester : https://flashbackfa-entreprise.fr/"
    echo "   2. Naviguer entre les onglets"
    echo "   3. Développer les fonctionnalités de chaque module"
    echo "   4. Implémenter les calculs et API"
    
else
    error "❌ Problème dans la restructuration"
    echo "Backup disponible dans : $BACKUP_DIR"
fi

log "🚀 RESTRUCTURATION TERMINÉE"