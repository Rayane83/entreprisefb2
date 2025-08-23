import React from 'react';
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'sonner';
import "./App.css";
import "./index.css";
import Index from './pages/Index';
import Superadmin from './pages/Superadmin';
import CompanyConfig from './pages/CompanyConfig';
import NotFound from './pages/NotFound';
import { AuthProvider } from './contexts/AuthContext';

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <div className="App">
          <BrowserRouter>
            <Routes>
              <Route path="/" element={<Index />} />
              <Route path="/superadmin" element={<Superadmin />} />
              <Route path="/superstaff" element={<Superadmin />} />
              <Route path="/patron-config" element={<CompanyConfig />} />
              <Route path="*" element={<NotFound />} />
            </Routes>
            <Toaster richColors position="top-right" />
          </BrowserRouter>
        </div>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;