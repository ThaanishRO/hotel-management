export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'admin' | 'manager' | 'receptionist' | 'housekeeping';
  avatar?: string;
  createdAt: string;
  isActive: boolean;
}

export interface Room {
  id: string;
  roomNumber: string;
  type: 'single' | 'double' | 'suite' | 'deluxe' | 'presidential';
  status: 'available' | 'occupied' | 'maintenance' | 'cleaning';
  price: number;
  floor: number;
  amenities: string[];
  lastCleaned?: string;
  nextMaintenance?: string;
}

export interface Guest {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: string;
  idNumber: string;
  dateOfBirth: string;
  nationality: string;
  vipStatus: boolean;
  totalBookings: number;
  createdAt: string;
}

export interface Booking {
  id: string;
  guestId: string;
  roomId: string;
  checkInDate: string;
  checkOutDate: string;
  status: 'confirmed' | 'checked-in' | 'checked-out' | 'cancelled';
  totalAmount: number;
  paidAmount: number;
  guests: number;
  specialRequests?: string;
  createdAt: string;
  createdBy: string;
}

export interface Task {
  id: string;
  roomId: string;
  type: 'cleaning' | 'maintenance' | 'inspection';
  title: string;
  description: string;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'pending' | 'in-progress' | 'completed';
  assignedTo: string;
  createdAt: string;
  dueDate: string;
  completedAt?: string;
}

export interface Report {
  id: string;
  type: 'occupancy' | 'revenue' | 'maintenance' | 'guest-satisfaction';
  title: string;
  period: string;
  data: any;
  createdAt: string;
}

export interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  loading: boolean;
}