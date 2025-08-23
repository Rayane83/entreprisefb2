import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { 
  DollarSign, 
  Users, 
  TrendingUp, 
  Calendar,
  FileText,
  AlertCircle 
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

const DashboardSummary = () => {
  const { userEntreprise, userRole } = useAuth();

  const stats = [
    {
      title: 'CA Total Mensuel',
      value: '€ 245,000',
      change: '+12.5%',
      trend: 'up',
      icon: DollarSign,
      color: 'text-green-600'
    },
    {
      title: 'Employés Actifs',
      value: '47',
      change: '+3',
      trend: 'up',
      icon: Users,
      color: 'text-blue-600'
    },
    {
      title: 'Dotations en Attente',
      value: '3',
      change: 'À traiter',
      trend: 'neutral',
      icon: FileText,
      color: 'text-orange-600'
    },
    {
      title: 'Blanchiment Actif',
      value: '12',
      change: 'En cours',
      trend: 'neutral',
      icon: AlertCircle,
      color: 'text-purple-600'
    }
  ];

  const recentActivities = [
    {
      id: 1,
      type: 'Dotation',
      description: 'Nouvelle dotation LSPD - Janvier 2024',
      date: '2024-01-25',
      status: 'En attente',
      statusColor: 'bg-yellow-100 text-yellow-800'
    },
    {
      id: 2,
      type: 'Archive',
      description: 'Validation par Staff - Dotation Décembre',
      date: '2024-01-24',
      status: 'Validé',
      statusColor: 'bg-green-100 text-green-800'
    },
    {
      id: 3,
      type: 'Blanchiment',
      description: 'Nouveau cycle Groupe Alpha',
      date: '2024-01-23',
      status: 'En cours',
      statusColor: 'bg-blue-100 text-blue-800'
    },
    {
      id: 4,
      type: 'Impôt',
      description: 'Déclaration mensuelle soumise',
      date: '2024-01-22',
      status: 'Traité',
      statusColor: 'bg-gray-100 text-gray-800'
    }
  ];

  return (
    <div className="space-y-6">
      {/* Enterprise Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-foreground">
            Dashboard {userEntreprise && `- ${userEntreprise}`}
          </h2>
          <p className="text-muted-foreground">
            Vue d'ensemble de votre entreprise
          </p>
        </div>
        <Badge variant="outline" className="text-sm">
          <Calendar className="w-4 h-4 mr-1" />
          Janvier 2024
        </Badge>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => {
          const IconComponent = stat.icon;
          return (
            <Card key={index} className="hover:shadow-md transition-shadow">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  {stat.title}
                </CardTitle>
                <IconComponent className={`w-4 h-4 ${stat.color}`} />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stat.value}</div>
                <div className="flex items-center space-x-2 text-xs text-muted-foreground">
                  {stat.trend === 'up' && (
                    <TrendingUp className="w-3 h-3 text-green-500" />
                  )}
                  <span className={stat.trend === 'up' ? 'text-green-500' : ''}>
                    {stat.change}
                  </span>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Recent Activities */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Activités Récentes</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {recentActivities.map((activity) => (
              <div key={activity.id} className="flex items-center justify-between p-3 border rounded-lg">
                <div className="flex-1">
                  <div className="flex items-center space-x-2">
                    <Badge variant="outline" className="text-xs">
                      {activity.type}
                    </Badge>
                    <span className="text-sm font-medium">
                      {activity.description}
                    </span>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    {new Date(activity.date).toLocaleDateString('fr-FR')}
                  </p>
                </div>
                <Badge className={`text-xs ${activity.statusColor}`}>
                  {activity.status}
                </Badge>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Actions Rapides</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 border rounded-lg text-center hover:bg-muted/50 cursor-pointer transition-colors">
              <FileText className="w-8 h-8 mx-auto mb-2 text-primary" />
              <p className="text-sm font-medium">Nouvelle Dotation</p>
              <p className="text-xs text-muted-foreground">Créer une dotation</p>
            </div>
            <div className="p-4 border rounded-lg text-center hover:bg-muted/50 cursor-pointer transition-colors">
              <TrendingUp className="w-8 h-8 mx-auto mb-2 text-primary" />
              <p className="text-sm font-medium">Rapport Impôts</p>
              <p className="text-xs text-muted-foreground">Générer rapport</p>
            </div>
            <div className="p-4 border rounded-lg text-center hover:bg-muted/50 cursor-pointer transition-colors">
              <AlertCircle className="w-8 h-8 mx-auto mb-2 text-primary" />
              <p className="text-sm font-medium">Gérer Blanchiment</p>
              <p className="text-xs text-muted-foreground">Voir les cycles</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default DashboardSummary;