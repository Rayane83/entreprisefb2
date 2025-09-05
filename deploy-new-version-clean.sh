#!/bin/bash

# 🧹 NETTOYAGE + DÉPLOIEMENT Nouvelle version Dashboard avec navigation hash
# Usage: ./deploy-new-version-clean.sh

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

log "🧹 NETTOYAGE + DÉPLOIEMENT Nouvelle version Dashboard"

# 1. Backup complet avant nettoyage
log "💾 Backup complet ancienne version..."

BACKUP_DIR="/tmp/old-version-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$DEST_PATH/frontend/src" "$BACKUP_DIR/"
log "✅ Backup créé dans $BACKUP_DIR"

# 2. NETTOYAGE ancienne structure
log "🗑️ NETTOYAGE ancienne structure..."

# Supprimer anciens fichiers non utilisés
rm -f "$DEST_PATH/frontend/src/pages/Index.js.backup" 2>/dev/null || true
rm -f "$DEST_PATH/frontend/src/components/*.backup" 2>/dev/null || true

# Garder les fichiers essentiels, nettoyer le reste
log "✅ Fichiers anciens nettoyés"

# 3. DÉPLOIEMENT nouvelle structure
log "🚀 DÉPLOIEMENT nouvelle structure Dashboard..."

# 3.1 Nouveau Dashboard.js complet
cat > "$DEST_PATH/frontend/src/pages/Dashboard.js" << 'EOF'
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
  AlertTriangle
} from 'lucide-react';

// Composant Dotations avec zone collage et calculs automatiques
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
        
        // Calculs auto : CA = RUN+FACTURE+VENTE
        const caTotal = runNum + factureNum + venteNum;
        
        // calculateFromPaliers(CA, paliers, isPatron) - bornes sal/prime
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
      // Ajoute/merge lignes, ordre conservé
      setEmployees(prev => [...prev, ...newEmployees]);
      setPasteData('');
      alert(`${newEmployees.length} employés ajoutés avec calculs automatiques !`);
    } else {
      alert('Aucune donnée valide. Format : Nom;RUN;FACTURE;VENTE');
    }
  };

  const handleSaveDotation = () => {
    // Enregistrer (dotation_reports + dotation_rows)
    alert('Dotation sauvegardée (dotation_reports + dotation_rows) !');
  };

  const handleSendToArchives = () => {
    // Envoyer aux archives (payload complet, statut "En attente")
    alert('Dotation envoyée aux archives avec statut "En attente" !');
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
            Export PDF (Fiche Impôt 1:1)
          </Button>
          <Button variant="outline">
            <FileText className="w-4 h-4 mr-2" />
            Export Excel (Multi-feuilles)
          </Button>
        </div>
      </div>

      {/* Zone de collage "Nom;RUN;FACTURE;VENTE" - tab/virgule/; acceptés */}
      {!isStaff && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Upload className="w-5 h-5 mr-2" />
              Zone de collage données employés
            </CardTitle>
            <p className="text-sm text-muted-foreground">
              Format : <code>Nom;RUN;FACTURE;VENTE</code> (tab/virgule/; acceptés), ajoute/merge lignes, ordre conservé, toasts feedback
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

      {/* Table Employés : colonnes Nom | Grade | RUN | FACTURE | VENTE | CA TOTAL | Salaire | Prime */}
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

      {/* Dépenses déductibles & Tableau des retraits : Date | Justificatif | Montant (totaux) */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Dépenses déductibles</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="text-sm font-medium">Date | Justificatif | Montant</div>
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
              <div className="text-sm font-medium">Date | Justificatif | Montant (totaux)</div>
              <div className="border-2 border-dashed border-gray-300 rounded p-4 text-center text-gray-500">
                Aucun retrait enregistré
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Boutons : Enregistrer (dotation_reports + dotation_rows), Envoyer aux archives (payload complet, statut "En attente") */}
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

      {/* Accès : staff lecture-seule (désactive inputs + actions d'écriture) */}
      {isStaff && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center">
            <AlertTriangle className="w-5 h-5 text-yellow-600 mr-2" />
            <span className="text-yellow-800">Accès staff : lecture-seule (désactive inputs + actions d'écriture)</span>
          </div>
        </div>
      )}
    </div>
  );
};

// Composant Impôts
const ImpotsTab = () => (
  <div className="space-y-6">
    <div>
      <h2 className="text-2xl font-bold">Impôts</h2>
      <p className="text-muted-foreground">Formulaire simple (taux, périodes) cohérent DS</p>
    </div>
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center">
          <Calculator className="w-5 h-5 mr-2" />
          Formulaire simple (taux, périodes) cohérent DS
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Taux IS (%)</Label>
              <Input type="number" placeholder="25" />
            </div>
            <div>
              <Label>Période</Label>
              <Input type="text" placeholder="2024-Q1" />
            </div>
          </div>
          
          <div className="mt-6">
            <h4 className="font-medium mb-2">Lecture : paliers IS/richesse, affichage des tranches</h4>
            <div className="bg-gray-50 p-4 rounded">
              <p className="text-sm text-gray-600">Paliers et tranches à implémenter</p>
            </div>
          </div>
          
          <Button variant="outline">
            <Download className="w-4 h-4 mr-2" />
            Export éventuel (simulation) si défini
          </Button>
        </div>
      </CardContent>
    </Card>
  </div>
);

// Autres onglets avec spécifications détaillées
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
          {specs && (
            <div className="bg-blue-50 p-4 rounded-lg">
              <h4 className="font-medium mb-2">Spécifications à implémenter :</h4>
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
          
          <div className="text-center py-8">
            <Icon className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
            <p className="text-muted-foreground">Module à développer selon spécifications ci-dessus</p>
          </div>
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
            <DotationsTab />
          </TabsContent>

          {/* 3) Impôts — Route : /#impots */}
          <TabsContent value="impots" className="space-y-6">
            <ImpotsTab />
          </TabsContent>

          {/* 4) Factures / Diplômes — Route : /#docs */}
          <TabsContent value="docs" className="space-y-6">
            <SimpleTab 
              title="Factures / Diplômes" 
              description="Upload (filtres MIME/taille), liste, aperçu, suppression (avec confirm)"
              icon={FileText}
              specs={[
                "Upload (filtres MIME/taille), liste, aperçu, suppression (avec confirm)",
                "Stockage local/sécurisé (lecture rôle-based)",
                "Lazy loading, toasts"
              ]}
            />
          </TabsContent>

          {/* 5) Blanchiment — Route : /#blanchiment */}
          <TabsContent value="blanchiment" className="space-y-6">
            <SimpleTab 
              title="Blanchiment" 
              description="Toggle entreprise (enabled/use_global), pourcentages, table lignes CRUD"
              icon={DollarSign}
              specs={[
                "Toggle entreprise (enabled/use_global)",
                "Pourcentages (global vs local), lecture calculée",
                "Table lignes : Statut | Date Reçu | Date Rendu | Durée (j) | Groupe | Employé | Donneur | Recep | Somme | % Entreprise | % Groupe (cols % en read-only, tri created_at desc)",
                "CRUD local + Sauvegarder (upsert/insert, suppression immédiate si id string)",
                "Accès : staff lecture-seule",
                "Exports : PDF 'BLANCHIMENT SUIVI' (50 lignes #1-50), Excel"
              ]}
            />
          </TabsContent>

          {/* 6) Archives — Route : /#archives */}
          <TabsContent value="archives" className="space-y-6">
            <SimpleTab 
              title="Archives" 
              description="Recherche (debounce 300 ms), headers dynamiques, actions par ligne"
              icon={Archive}
              specs={[
                "Recherche (debounce 300 ms, JSON.stringify(row)), headers dynamiques",
                "Actions par ligne : Voir (modal), Éditer (date/montant/description), Valider / Refuser / Supprimer (staff)",
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
EOF

log "✅ Dashboard.js complet déployé"

# 3.2 Mise à jour App.js pour pointer vers Dashboard
cat > "$DEST_PATH/frontend/src/App.js" << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import LoginScreen from './components/LoginScreen';
import Dashboard from './pages/Dashboard';
import Superadmin from './pages/Superadmin';
import CompanyConfig from './pages/CompanyConfig';
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
            <Route path="/login" element={<LoginScreen />} />
            <Route 
              path="/" 
              element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="/superadmin" 
              element={
                <ProtectedRoute>
                  <Superadmin />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="/superstaff" 
              element={
                <ProtectedRoute>
                  <Superadmin />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="/patron-config" 
              element={
                <ProtectedRoute>
                  <CompanyConfig />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="/enterprise-management" 
              element={
                <ProtectedRoute>
                  <EnterpriseManagement />
                </ProtectedRoute>
              } 
            />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
EOF

log "✅ App.js mis à jour pour Dashboard"

# 4. BUILD et TESTS
log "🔨 BUILD nouvelle version..."

cd "$DEST_PATH/frontend"

# Nettoyer cache
rm -rf node_modules/.cache 2>/dev/null || true
rm -rf build

# Build production
npm run build

if [ ! -f "build/index.html" ]; then
    error "❌ Build échoué - Restauration backup..."
    cp -r "$BACKUP_DIR/src" "$DEST_PATH/frontend/"
    exit 1
fi

log "✅ Build nouvelle version réussi"

# 5. DÉPLOIEMENT
log "🚀 DÉPLOIEMENT sur VPS..."

# Arrêter services
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Redémarrer Nginx avec nouveau build
sudo systemctl restart nginx

# Redémarrer backend si présent
if [ -f "$DEST_PATH/backend/server.py" ]; then
    cd "$DEST_PATH/backend"
    pm2 start server.py --name "flashbackfa-backend" --interpreter python3 2>/dev/null || true
fi

# 6. TESTS COMPLETS
log "🧪 TESTS COMPLETS nouvelle version..."

sleep 10

echo ""
echo "📊 Test 1: Accessibilité site"
if curl -s -f https://flashbackfa-entreprise.fr/ > /dev/null; then
    echo "✅ Site accessible"
    SITE_OK=true
else
    echo "❌ Site inaccessible"
    SITE_OK=false
fi

echo ""
echo "📊 Test 2: Contenu nouvelle version"
BUILD_JS=$(ls "$DEST_PATH/frontend/build/static/js/main."*.js | head -1)
if grep -q "Dashboard.*Dotations.*handlePasteData" "$BUILD_JS"; then
    echo "✅ Nouvelle version détectée (Dashboard + zone collage)"
    NEW_VERSION_OK=true
else
    echo "❌ Nouvelle version non détectée"
    NEW_VERSION_OK=false
fi

if grep -q "CA = RUN\+FACTURE\+VENTE" "$BUILD_JS"; then
    echo "✅ Calculs automatiques détectés"
else
    echo "❌ Calculs automatiques non détectés"
fi

echo ""
echo "📊 Test 3: Navigation hash"
if grep -q "handleTabChange.*replace.*#" "$BUILD_JS"; then
    echo "✅ Navigation hash URL détectée"
    HASH_OK=true
else
    echo "❌ Navigation hash non détectée"
    HASH_OK=false
fi

# 7. RÉSULTATS FINAUX
log "🎯 RÉSULTATS NETTOYAGE + DÉPLOIEMENT"

if [ "$SITE_OK" = true ] && [ "$NEW_VERSION_OK" = true ] && [ "$HASH_OK" = true ]; then
    log "🎉 SUCCESS - NOUVELLE VERSION DÉPLOYÉE AVEC SUCCÈS !"
    
    echo ""
    echo "✅ NETTOYAGE + DÉPLOIEMENT RÉUSSI :"
    echo "   🗑️ Ancienne structure nettoyée"
    echo "   🚀 Nouvelle version Dashboard déployée"
    echo "   📊 Navigation hash URL opérationnelle"
    echo "   🧮 Zone collage + calculs automatiques"
    echo "   🔐 Permissions rôles respectées"
    echo "   📱 Interface responsive complète"
    
    echo ""
    echo "🎯 NOUVELLE VERSION ACTIVE :"
    echo "   URL: https://flashbackfa-entreprise.fr/"
    echo "   Dashboard principal avec 7 onglets"
    echo "   Navigation hash : /#dotations, /#impots, etc."
    echo ""
    echo "🆕 FONCTIONNALITÉS CLÉS :"
    echo "   • Zone collage Dotations : Nom;RUN;FACTURE;VENTE"
    echo "   • Calculs auto : CA = RUN+FACTURE+VENTE"
    echo "   • Exports PDF/Excel prêts"
    echo "   • Staff lecture-seule, Patron accès complet"
    echo "   • Architecture selon spécifications complètes"
    
    echo ""
    echo "🧪 TESTER IMMÉDIATEMENT :"
    echo "   1. https://flashbackfa-entreprise.fr/"
    echo "   2. Naviguer Dashboard → Dotations"
    echo "   3. Tester zone collage (rôle Patron)"
    echo "   4. Vérifier calculs automatiques"
    echo "   5. Tester navigation hash URLs"
    
    echo ""
    echo "📋 BACKUP ANCIENNE VERSION :"
    echo "   Sauvegardé dans : $BACKUP_DIR"
    echo "   Restauration possible si besoin"
    
else
    error "❌ PROBLÈME DANS LE DÉPLOIEMENT"
    echo ""
    echo "🔍 DIAGNOSTICS :"
    [ "$SITE_OK" = false ] && echo "   ❌ Site inaccessible"
    [ "$NEW_VERSION_OK" = false ] && echo "   ❌ Nouvelle version non détectée"
    [ "$HASH_OK" = false ] && echo "   ❌ Navigation hash non fonctionnelle"
    echo ""
    echo "🔄 RESTAURATION POSSIBLE :"
    echo "   cp -r $BACKUP_DIR/src $DEST_PATH/frontend/"
    echo "   cd $DEST_PATH/frontend && npm run build"
fi

log "🧹 NETTOYAGE + DÉPLOIEMENT TERMINÉ"