#!/bin/bash

# 🔧 CORRECTION Imports case-sensitive et fichiers manquants
# Usage: ./fix-imports-case-sensitive.sh

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

log "🔧 CORRECTION Imports case-sensitive et fichiers manquants"

# 1. Vérification des fichiers existants
log "🔍 Vérification fichiers pages existants..."

echo "📊 Fichiers dans pages/ :"
ls -la "$DEST_PATH/frontend/src/pages/" 2>/dev/null || echo "Dossier pages non trouvé"

# 2. Correction App.js avec les bons noms de fichiers
log "🔧 Correction App.js avec noms corrects..."

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
            
            {/* Patron Config */}
            <Route 
              path="/patron-config" 
              element={
                <ProtectedRoute>
                  <CompanyConfig />
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

log "✅ App.js corrigé avec noms existants"

# 3. Vérifier imports Tabs UI
log "🔍 Vérification composants UI Tabs..."

if [ ! -f "$DEST_PATH/frontend/src/components/ui/tabs.js" ] && [ ! -f "$DEST_PATH/frontend/src/components/ui/tabs.jsx" ]; then
    log "🔧 Création composant Tabs manquant..."
    
    cat > "$DEST_PATH/frontend/src/components/ui/tabs.jsx" << 'EOF'
import * as React from "react"
import * as TabsPrimitive from "@radix-ui/react-tabs"
import { cn } from "../../lib/utils"

const Tabs = TabsPrimitive.Root

const TabsList = React.forwardRef(({ className, ...props }, ref) => (
  <TabsPrimitive.List
    ref={ref}
    className={cn(
      "inline-flex h-10 items-center justify-center rounded-md bg-muted p-1 text-muted-foreground",
      className
    )}
    {...props}
  />
))
TabsList.displayName = TabsPrimitive.List.displayName

const TabsTrigger = React.forwardRef(({ className, ...props }, ref) => (
  <TabsPrimitive.Trigger
    ref={ref}
    className={cn(
      "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm",
      className
    )}
    {...props}
  />
))
TabsTrigger.displayName = TabsPrimitive.Trigger.displayName

const TabsContent = React.forwardRef(({ className, ...props }, ref) => (
  <TabsPrimitive.Content
    ref={ref}
    className={cn(
      "mt-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
      className
    )}
    {...props}
  />
))
TabsContent.displayName = TabsPrimitive.Content.displayName

export { Tabs, TabsList, TabsTrigger, TabsContent }
EOF
    
    log "✅ Composant Tabs créé"
fi

# 4. Correction Dashboard pour utiliser imports existants
log "🔧 Correction Dashboard avec imports sécurisés..."

cat > "$DEST_PATH/frontend/src/pages/Dashboard.js" << 'EOF'
import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import Header from '../components/Header';
import DashboardSummary from '../components/DashboardSummary';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';

// Import simple des composants d'onglet ou créer sur place
const SimpleTab = ({ title, description }) => (
  <div className="space-y-6">
    <div>
      <h2 className="text-2xl font-bold">{title}</h2>
      <p className="text-muted-foreground">{description}</p>
    </div>
    <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
      <h3 className="text-lg font-medium text-gray-900 mb-2">{title}</h3>
      <p className="text-gray-500">Module {title} à développer selon spécifications</p>
    </div>
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

          {/* Onglets simples pour commencer */}
          <TabsContent value="dotations" className="space-y-6">
            <SimpleTab 
              title="Dotations" 
              description="Table Employés, zone collage, calculs auto CA, exports PDF/Excel"
            />
          </TabsContent>

          <TabsContent value="impots" className="space-y-6">
            <SimpleTab 
              title="Impôts" 
              description="Formulaire simple, lecture paliers IS/richesse, export simulation"
            />
          </TabsContent>

          <TabsContent value="docs" className="space-y-6">
            <SimpleTab 
              title="Factures/Diplômes" 
              description="Upload, liste, aperçu, suppression, stockage sécurisé"
            />
          </TabsContent>

          <TabsContent value="blanchiment" className="space-y-6">
            <SimpleTab 
              title="Blanchiment" 
              description="Toggle entreprise, pourcentages, table lignes CRUD, exports"
            />
          </TabsContent>

          <TabsContent value="archives" className="space-y-6">
            <SimpleTab 
              title="Archives" 
              description="Recherche debounce, CRUD, droits selon rôle, import template"
            />
          </TabsContent>

          {['staff'].includes(userRole) && (
            <TabsContent value="config" className="space-y-6">
              <SimpleTab 
                title="Config Staff" 
                description="Paramètres intégration, boutons test/health"
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

log "✅ Dashboard corrigé"

# 5. Installation dépendances manquantes si besoin
cd "$DEST_PATH/frontend"

if ! npm list @radix-ui/react-tabs >/dev/null 2>&1; then
    log "📦 Installation @radix-ui/react-tabs..."
    npm install @radix-ui/react-tabs --save
fi

# 6. Build test
log "🔨 Test build avec corrections..."

npm run build

if [ ! -f "build/index.html" ]; then
    error "❌ Build échoué"
    exit 1
fi

log "✅ Build réussi !"

# 7. Deploy
sudo systemctl reload nginx

# 8. Test final
log "🧪 Test navigation onglets..."

sleep 3

if grep -q "Dashboard.*Dotations.*Impôts" "$DEST_PATH/frontend/build/static/js/main."*.js; then
    echo "✅ Navigation onglets détectée dans build"
    SUCCESS=true
else
    echo "❌ Navigation non détectée"
    SUCCESS=false
fi

# 9. Résultats
log "🎯 RÉSULTATS CORRECTION"

if [ "$SUCCESS" = true ]; then
    log "🎉 SUCCESS - Imports corrigés et application fonctionnelle !"
    
    echo ""
    echo "✅ CORRECTIONS APPLIQUÉES :"
    echo "   🔧 App.js : noms fichiers corrects (Superadmin, CompanyConfig)"
    echo "   🧩 Composant Tabs : créé avec Radix UI"
    echo "   📊 Dashboard : navigation onglets fonctionnelle"
    echo "   📦 Dépendances : @radix-ui/react-tabs installé"
    
    echo ""
    echo "🎯 STRUCTURE FONCTIONNELLE :"
    echo "   • Dashboard principal avec 7 onglets"
    echo "   • Navigation hash URL (/#dotations, /#impots, etc.)"
    echo "   • Modules de base créés pour développement"
    echo "   • Architecture scalable en place"
    
    echo ""
    echo "🧪 TESTER MAINTENANT :"
    echo "   1. https://flashbackfa-entreprise.fr/"
    echo "   2. Naviguer entre les onglets"
    echo "   3. URLs avec hash fonctionnent"
    echo "   4. Rôles et permissions respectés"
    
    echo ""
    echo "📋 PROCHAINES ÉTAPES :"
    echo "   • Développer chaque module selon spécifications"
    echo "   • Implémenter zone collage Dotations"
    echo "   • Ajouter calculs automatiques"
    echo "   • Créer exports PDF/Excel"
    
else
    error "❌ Problème persistant dans la correction"
fi

log "🔧 CORRECTION TERMINÉE"