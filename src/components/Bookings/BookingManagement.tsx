import React, { useState } from 'react';
import { Plus, Calendar, User, DollarSign, Filter } from 'lucide-react';
import { Booking, Guest } from '../../types';

const BookingManagement: React.FC = () => {
  const [bookings] = useState<Booking[]>([
    {
      id: '1',
      guestId: '1',
      roomId: '1',
      checkInDate: '2024-01-15',
      checkOutDate: '2024-01-18',
      status: 'confirmed',
      totalAmount: 450,
      paidAmount: 450,
      guests: 2,
      createdAt: '2024-01-10T10:00:00Z',
      createdBy: 'admin'
    },
    {
      id: '2',
      guestId: '2',
      roomId: '2',
      checkInDate: '2024-01-16',
      checkOutDate: '2024-01-20',
      status: 'checked-in',
      totalAmount: 720,
      paidAmount: 360,
      guests: 1,
      createdAt: '2024-01-12T14:30:00Z',
      createdBy: 'receptionist'
    }
  ]);

  const [guests] = useState<Guest[]>([
    {
      id: '1',
      firstName: 'John',
      lastName: 'Smith',
      email: 'john.smith@email.com',
      phone: '+1-555-0123',
      address: '123 Main St, New York, NY',
      idNumber: 'ID123456789',
      dateOfBirth: '1985-03-15',
      nationality: 'USA',
      vipStatus: false,
      totalBookings: 3,
      createdAt: '2024-01-01T00:00:00Z'
    },
    {
      id: '2',
      firstName: 'Sarah',
      lastName: 'Johnson',
      email: 'sarah.johnson@email.com',
      phone: '+1-555-0124',
      address: '456 Oak Ave, Los Angeles, CA',
      idNumber: 'ID987654321',
      dateOfBirth: '1990-07-22',
      nationality: 'USA',
      vipStatus: true,
      totalBookings: 8,
      createdAt: '2023-12-15T00:00:00Z'
    }
  ]);

  const [statusFilter, setStatusFilter] = useState('all');

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'confirmed': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'checked-in': return 'bg-green-100 text-green-800 border-green-200';
      case 'checked-out': return 'bg-gray-100 text-gray-800 border-gray-200';
      case 'cancelled': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getGuestName = (guestId: string) => {
    const guest = guests.find(g => g.id === guestId);
    return guest ? `${guest.firstName} ${guest.lastName}` : 'Unknown Guest';
  };

  const filteredBookings = statusFilter === 'all' ? bookings : bookings.filter(booking => booking.status === statusFilter);

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Booking Management</h1>
          <p className="text-gray-600 mt-1">Manage reservations, check-ins, and check-outs</p>
        </div>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center space-x-2">
          <Plus className="w-4 h-4" />
          <span>New Booking</span>
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center space-x-4">
            <Filter className="w-5 h-5 text-gray-400" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="all">All Bookings</option>
              <option value="confirmed">Confirmed</option>
              <option value="checked-in">Checked In</option>
              <option value="checked-out">Checked Out</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Booking ID
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Guest
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Room
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Dates
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Amount
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredBookings.map((booking) => (
                <tr key={booking.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">#{booking.id}</div>
                    <div className="text-sm text-gray-500">{booking.guests} guests</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                        <User className="w-5 h-5 text-blue-600" />
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900">{getGuestName(booking.guestId)}</div>
                        <div className="text-sm text-gray-500">Guest ID: {booking.guestId}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">Room {booking.roomId}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center text-sm text-gray-900">
                      <Calendar className="w-4 h-4 mr-2 text-gray-400" />
                      <div>
                        <div>{new Date(booking.checkInDate).toLocaleDateString()}</div>
                        <div className="text-gray-500">to {new Date(booking.checkOutDate).toLocaleDateString()}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full border ${getStatusColor(booking.status)}`}>
                      {booking.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center text-sm">
                      <DollarSign className="w-4 h-4 mr-1 text-gray-400" />
                      <div>
                        <div className="font-medium text-gray-900">${booking.totalAmount}</div>
                        <div className="text-gray-500">Paid: ${booking.paidAmount}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <div className="flex items-center space-x-2">
                      {booking.status === 'confirmed' && (
                        <button className="bg-green-600 text-white px-3 py-1 rounded text-xs hover:bg-green-700">
                          Check In
                        </button>
                      )}
                      {booking.status === 'checked-in' && (
                        <button className="bg-blue-600 text-white px-3 py-1 rounded text-xs hover:bg-blue-700">
                          Check Out
                        </button>
                      )}
                      <button className="text-gray-600 hover:text-gray-900 px-3 py-1 border border-gray-300 rounded text-xs">
                        Edit
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default BookingManagement;