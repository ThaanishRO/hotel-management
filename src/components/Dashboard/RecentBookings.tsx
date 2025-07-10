import React from 'react';
import { Clock, User, Bed } from 'lucide-react';

const RecentBookings: React.FC = () => {
  const bookings = [
    {
      id: 'BK001',
      guest: 'John Smith',
      room: 'Suite 301',
      checkIn: '2024-01-15',
      checkOut: '2024-01-18',
      status: 'confirmed',
      amount: '$450'
    },
    {
      id: 'BK002',
      guest: 'Sarah Johnson',
      room: 'Deluxe 205',
      checkIn: '2024-01-16',
      checkOut: '2024-01-20',
      status: 'checked-in',
      amount: '$680'
    },
    {
      id: 'BK003',
      guest: 'Mike Wilson',
      room: 'Standard 102',
      checkIn: '2024-01-17',
      checkOut: '2024-01-19',
      status: 'confirmed',
      amount: '$280'
    }
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'confirmed': return 'bg-blue-100 text-blue-800';
      case 'checked-in': return 'bg-green-100 text-green-800';
      case 'checked-out': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-semibold text-gray-900">Recent Bookings</h2>
        <button className="text-blue-600 hover:text-blue-700 font-medium">View All</button>
      </div>

      <div className="space-y-4">
        {bookings.map((booking) => (
          <div key={booking.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
            <div className="flex items-center space-x-4">
              <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                <User className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900">{booking.guest}</h3>
                <p className="text-sm text-gray-600 flex items-center">
                  <Bed className="w-4 h-4 mr-1" />
                  {booking.room}
                </p>
              </div>
            </div>
            
            <div className="text-right">
              <div className="flex items-center space-x-2 mb-1">
                <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(booking.status)}`}>
                  {booking.status}
                </span>
                <span className="font-semibold text-gray-900">{booking.amount}</span>
              </div>
              <p className="text-sm text-gray-600 flex items-center">
                <Clock className="w-4 h-4 mr-1" />
                {booking.checkIn} - {booking.checkOut}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default RecentBookings;