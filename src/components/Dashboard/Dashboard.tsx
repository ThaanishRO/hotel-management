import React from 'react';
import DashboardStats from './DashboardStats';
import RecentBookings from './RecentBookings';
import RoomStatus from './RoomStatus';

const Dashboard: React.FC = () => {
  return (
    <div className="p-6 space-y-6">
      <DashboardStats />
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <RecentBookings />
        <RoomStatus />
      </div>
    </div>
  );
};

export default Dashboard;