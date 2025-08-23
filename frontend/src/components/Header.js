import React from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Avatar, AvatarFallback, AvatarImage } from './ui/avatar';
import { LogOut, Settings, Shield, Building } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { mockUserRoles } from '../data/mockData';

const Header = () => {
  const { 
    user, 
    userRole, 
    userEntreprise, 
    logout, 
    canAccessStaffConfig, 
    canAccessCompanyConfig 
  } = useAuth();
  const navigate = useNavigate();

  const handleSuperStaffClick = () => {
    navigate('/superadmin');
  };

  const handlePatronConfigClick = () => {
    navigate('/patron-config');
  };

  const roleInfo = mockUserRoles[userRole] || mockUserRoles.employe;

  return (
    <header className="border-b bg-card shadow-sm">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo and Title */}
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center">
              <span className="text-sm font-bold text-primary-foreground">FB</span>
            </div>
            <span className="text-xl font-semibold text-foreground">
              Portail Entreprise Flashback Fa
            </span>
          </div>

          {/* User Info and Controls */}
          <div className="flex items-center space-x-4">
            {/* User Avatar and Name */}
            <div className="flex items-center space-x-2">
              <Avatar className="w-8 h-8">
                <AvatarImage src={user?.avatar} alt={user?.name} />
                <AvatarFallback>{user?.name?.charAt(0) || 'U'}</AvatarFallback>
              </Avatar>
              <span className="text-sm font-medium text-foreground">
                {user?.name}
              </span>
            </div>

            {/* Role Badge */}
            <Badge 
              variant="secondary" 
              className="text-xs font-medium"
              style={{ backgroundColor: roleInfo.color, color: 'white' }}
            >
              {roleInfo.name}
            </Badge>

            {/* Enterprise Badge */}
            {userEntreprise && (
              <Badge variant="outline" className="text-xs">
                <Building className="w-3 h-3 mr-1" />
                {userEntreprise}
              </Badge>
            )}

            {/* Staff SuperAdmin Button */}
            {canAccessStaffConfig() && (
              <Button
                variant="outline"
                size="sm"
                onClick={handleSuperStaffClick}
                className="text-xs"
              >
                <Shield className="w-3 h-3 mr-1" />
                SuperStaff
              </Button>
            )}

            {/* Patron Config Button */}
            {canAccessCompanyConfig() && (
              <Button
                variant="outline"
                size="sm"
                onClick={handlePatronConfigClick}
                className="text-xs"
              >
                <Settings className="w-3 h-3 mr-1" />
                Patron Config
              </Button>
            )}

            {/* Logout Button */}
            <Button
              variant="ghost"
              size="sm"
              onClick={logout}
              className="text-xs text-muted-foreground hover:text-foreground"
            >
              <LogOut className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;