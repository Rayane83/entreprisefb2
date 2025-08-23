import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import LoginScreen from '../components/LoginScreen';
import Header from '../components/Header';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';
import DashboardSummary from '../components/DashboardSummary';
import DotationForm from '../components/DotationForm';
import ImpotForm from '../components/ImpotForm';
import DocsUpload from '../components/DocsUpload';
import BlanchimentToggle from '../components/BlanchimentToggle';
import ArchiveTable from '../components/ArchiveTable';
import StaffConfig from '../components/StaffConfig';
import RoleGate from '../components/RoleGate';

const Index = () => {
  const { user, loading } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="loading-dots">
          <span>•</span>
          <span>•</span>
          <span>•</span>
        </div>
      </div>
    );
  }

  if (!user) {
    return <LoginScreen />;
  }

  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="container mx-auto px-4 py-6">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-3xl font-bold mb-6">Portail Entreprise Flashback Fa</h1>
          
          <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
            <TabsList className="grid w-full grid-cols-7 mb-6">
              <TabsTrigger value="dashboard">Dashboard</TabsTrigger>
              <TabsTrigger value="dotations">Dotations</TabsTrigger>
              <TabsTrigger value="impots">Impôts</TabsTrigger>
              <TabsTrigger value="factures">Factures/Diplômes</TabsTrigger>
              <TabsTrigger value="blanchiment">Blanchiment</TabsTrigger>
              <TabsTrigger value="archives">Archives</TabsTrigger>
              <TabsTrigger value="config">Config</TabsTrigger>
            </TabsList>

            <TabsContent value="dashboard" className="space-y-6">
              <DashboardSummary />
            </TabsContent>

            <TabsContent value="dotations" className="space-y-6">
              <RoleGate requiredAccess="canAccessDotation">
                <DotationForm />
              </RoleGate>
            </TabsContent>

            <TabsContent value="impots" className="space-y-6">
              <RoleGate requiredAccess="canAccessImpot">
                <ImpotForm />
              </RoleGate>
            </TabsContent>

            <TabsContent value="factures" className="space-y-6">
              <DocsUpload />
            </TabsContent>

            <TabsContent value="blanchiment" className="space-y-6">
              <RoleGate requiredAccess="canAccessBlanchiment">
                <BlanchimentToggle />
              </RoleGate>
            </TabsContent>

            <TabsContent value="archives" className="space-y-6">
              <ArchiveTable />
            </TabsContent>

            <TabsContent value="config" className="space-y-6">
              <RoleGate requiredAccess="canAccessStaffConfig">
                <StaffConfig />
              </RoleGate>
            </TabsContent>
          </Tabs>
        </div>
      </main>
    </div>
  );
};

export default Index;