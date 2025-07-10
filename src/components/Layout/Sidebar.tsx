import React from 'react';
import { 
  Home, 
  Bed, 
  Users, 
  Calendar, 
  UserCheck, 
  ClipboardList, 
  BarChart3, 
  Settings,
  LogOut
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

interface SidebarProps {
  currentView: string;
  setCurrentView: (view: string) => void;
}

const Sidebar: React.FC<SidebarProps> = ({ currentView, setCurrentView }) => {
  const { user, logout, hasPermission } = useAuth();

  const menuItems = [
    { id: 'dashboard', icon: Home, label: 'Dashboard', permission: 'dashboard' },
    { id: 'rooms', icon: Bed, label: 'Rooms', permission: 'rooms' },
    { id: 'bookings', icon: Calendar, label: 'Bookings', permission: 'bookings' },
    { id: 'guests', icon: Users, label: 'Guests', permission: 'guests' },
    { id: 'staff', icon: UserCheck, label: 'Staff', permission: 'staff' },
    { id: 'tasks', icon: ClipboardList, label: 'Tasks', permission: 'tasks' },
    { id: 'reports', icon: BarChart3, label: 'Reports', permission: 'reports' },
    { id: 'settings', icon: Settings, label: 'Settings', permission: 'settings' }
  ];

  const filteredMenuItems = menuItems.filter(item => hasPermission(item.permission));

  return (
    <div className="w-64 bg-white shadow-lg min-h-screen">
      <div className="p-6 border-b border-gray-200">
        <h1 className="text-2xl font-bold text-blue-800">Hotel Manager</h1>
        <div className="mt-4 flex items-center space-x-3">
          <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
            <span className="text-blue-600 font-semibold">
              {user?.firstName?.[0]}{user?.lastName?.[0]}
            </span>
          </div>
          <div>
            <p className="font-medium text-gray-900">{user?.firstName} {user?.lastName}</p>
            <p className="text-sm text-gray-500 capitalize">{user?.role}</p>
          </div>
        </div>
      </div>
      
      <nav className="mt-6">
        <div className="px-3 space-y-1">
          {filteredMenuItems.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                onClick={() => setCurrentView(item.id)}
                className={`w-full flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-colors ${
                  currentView === item.id
                    ? 'bg-blue-50 text-blue-700 border-r-2 border-blue-600'
                    : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                }`}
              >
                <Icon className="w-5 h-5 mr-3" />
                {item.label}
              </button>
            );
          })}
        </div>
      </nav>
      
      <div className="absolute bottom-0 w-64 p-4 border-t border-gray-200">
        <button
          onClick={logout}
          className="w-full flex items-center px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-50 rounded-lg transition-colors"
        >
          <LogOut className="w-5 h-5 mr-3" />
          Logout
        </button>
      </div>
    </div>
  );
};

export default Sidebar;