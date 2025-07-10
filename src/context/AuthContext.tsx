import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, AuthState } from '../types';

interface AuthContextType extends AuthState {
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  hasPermission: (permission: string) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Mock user data
const mockUsers: User[] = [
  {
    id: '1',
    email: 'admin@hotel.com',
    firstName: 'John',
    lastName: 'Admin',
    role: 'admin',
    createdAt: '2024-01-01',
    isActive: true
  },
  {
    id: '2',
    email: 'manager@hotel.com',
    firstName: 'Jane',
    lastName: 'Manager',
    role: 'manager',
    createdAt: '2024-01-01',
    isActive: true
  },
  {
    id: '3',
    email: 'receptionist@hotel.com',
    firstName: 'Mike',
    lastName: 'Reception',
    role: 'receptionist',
    createdAt: '2024-01-01',
    isActive: true
  }
];

const rolePermissions = {
  admin: ['*'],
  manager: ['dashboard', 'rooms', 'bookings', 'guests', 'staff', 'reports'],
  receptionist: ['dashboard', 'rooms', 'bookings', 'guests'],
  housekeeping: ['dashboard', 'rooms', 'tasks']
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [authState, setAuthState] = useState<AuthState>({
    user: null,
    token: null,
    isAuthenticated: false,
    loading: false
  });

  useEffect(() => {
    const token = localStorage.getItem('hotel_token');
    const userData = localStorage.getItem('hotel_user');
    
    if (token && userData) {
      setAuthState({
        user: JSON.parse(userData),
        token,
        isAuthenticated: true,
        loading: false
      });
    }
  }, []);

  const login = async (email: string, password: string) => {
    setAuthState(prev => ({ ...prev, loading: true }));
    
    // Mock authentication
    const user = mockUsers.find(u => u.email === email);
    
    if (user && password === 'password') {
      const token = `mock_token_${Date.now()}`;
      
      localStorage.setItem('hotel_token', token);
      localStorage.setItem('hotel_user', JSON.stringify(user));
      
      setAuthState({
        user,
        token,
        isAuthenticated: true,
        loading: false
      });
    } else {
      setAuthState(prev => ({ ...prev, loading: false }));
      throw new Error('Invalid credentials');
    }
  };

  const logout = () => {
    localStorage.removeItem('hotel_token');
    localStorage.removeItem('hotel_user');
    setAuthState({
      user: null,
      token: null,
      isAuthenticated: false,
      loading: false
    });
  };

  const hasPermission = (permission: string) => {
    if (!authState.user) return false;
    
    const userPermissions = rolePermissions[authState.user.role];
    return userPermissions.includes('*') || userPermissions.includes(permission);
  };

  return (
    <AuthContext.Provider value={{
      ...authState,
      login,
      logout,
      hasPermission
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};