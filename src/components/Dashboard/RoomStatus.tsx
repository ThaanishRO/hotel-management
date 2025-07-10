import React from 'react';
import { Bed, Wrench, Sparkles, CheckCircle } from 'lucide-react';

const RoomStatus: React.FC = () => {
  const roomStats = [
    { status: 'Available', count: 45, color: 'green', icon: CheckCircle },
    { status: 'Occupied', count: 38, color: 'blue', icon: Bed },
    { status: 'Cleaning', count: 12, color: 'yellow', icon: Sparkles },
    { status: 'Maintenance', count: 5, color: 'red', icon: Wrench }
  ];

  const rooms = [
    { number: '101', type: 'Standard', status: 'available', floor: 1 },
    { number: '102', type: 'Standard', status: 'occupied', floor: 1 },
    { number: '201', type: 'Deluxe', status: 'cleaning', floor: 2 },
    { number: '301', type: 'Suite', status: 'maintenance', floor: 3 },
    { number: '302', type: 'Suite', status: 'available', floor: 3 },
    { number: '401', type: 'Presidential', status: 'occupied', floor: 4 }
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'available': return 'bg-green-100 text-green-800 border-green-200';
      case 'occupied': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'cleaning': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'maintenance': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <h2 className="text-xl font-semibold text-gray-900 mb-6">Room Status</h2>
      
      <div className="grid grid-cols-2 gap-4 mb-6">
        {roomStats.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <div key={index} className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
              <div className={`p-2 rounded-full ${
                stat.color === 'green' ? 'bg-green-100' :
                stat.color === 'blue' ? 'bg-blue-100' :
                stat.color === 'yellow' ? 'bg-yellow-100' :
                'bg-red-100'
              }`}>
                <Icon className={`w-4 h-4 ${
                  stat.color === 'green' ? 'text-green-600' :
                  stat.color === 'blue' ? 'text-blue-600' :
                  stat.color === 'yellow' ? 'text-yellow-600' :
                  'text-red-600'
                }`} />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stat.count}</p>
                <p className="text-sm text-gray-600">{stat.status}</p>
              </div>
            </div>
          );
        })}
      </div>

      <div className="space-y-2 max-h-64 overflow-y-auto">
        {rooms.map((room, index) => (
          <div key={index} className="flex items-center justify-between p-3 border rounded-lg hover:bg-gray-50 transition-colors">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center">
                <span className="text-xs font-medium text-gray-700">{room.number}</span>
              </div>
              <div>
                <p className="font-medium text-gray-900">Room {room.number}</p>
                <p className="text-sm text-gray-600">{room.type} • Floor {room.floor}</p>
              </div>
            </div>
            <span className={`px-3 py-1 text-xs font-medium rounded-full border ${getStatusColor(room.status)}`}>
              {room.status}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default RoomStatus;