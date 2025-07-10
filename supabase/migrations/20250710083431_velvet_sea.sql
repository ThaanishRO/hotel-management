-- Hotel Management System Database Schema
-- Create database and user
CREATE DATABASE IF NOT EXISTS hotel_db;
CREATE USER IF NOT EXISTS 'hotel_user'@'%' IDENTIFIED BY '25846936';
GRANT ALL PRIVILEGES ON hotel_db.* TO 'hotel_user'@'%';
FLUSH PRIVILEGES;

USE hotel_db;

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role ENUM('admin', 'manager', 'receptionist', 'housekeeping') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
);

-- Rooms table
CREATE TABLE rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(10) UNIQUE NOT NULL,
    room_type ENUM('standard', 'deluxe', 'suite', 'presidential') NOT NULL,
    status ENUM('available', 'occupied', 'cleaning', 'maintenance') DEFAULT 'available',
    price_per_night DECIMAL(10, 2) NOT NULL,
    floor INT NOT NULL,
    amenities TEXT,
    last_cleaned TIMESTAMP NULL,
    next_maintenance TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_room_number (room_number),
    INDEX idx_status (status),
    INDEX idx_type (room_type)
);

-- Guests table
CREATE TABLE guests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT,
    id_number VARCHAR(50) UNIQUE NOT NULL,
    date_of_birth DATE,
    nationality VARCHAR(50),
    vip_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_id_number (id_number),
    INDEX idx_vip_status (vip_status)
);

-- Bookings table
CREATE TABLE bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    guest_id INT NOT NULL,
    room_id INT NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    status ENUM('confirmed', 'checked_in', 'checked_out', 'cancelled') DEFAULT 'confirmed',
    total_amount DECIMAL(10, 2) NOT NULL,
    paid_amount DECIMAL(10, 2) DEFAULT 0.00,
    number_of_guests INT DEFAULT 1,
    special_requests TEXT,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_guest_id (guest_id),
    INDEX idx_room_id (room_id),
    INDEX idx_dates (check_in_date, check_out_date),
    INDEX idx_status (status)
);

-- Tasks table
CREATE TABLE tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    task_type ENUM('cleaning', 'maintenance', 'inspection') NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    status ENUM('pending', 'in_progress', 'completed') DEFAULT 'pending',
    assigned_to INT,
    due_date TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_room_id (room_id),
    INDEX idx_status (status),
    INDEX idx_type (task_type),
    INDEX idx_priority (priority),
    INDEX idx_assigned_to (assigned_to)
);

-- Reports table
CREATE TABLE reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    report_type VARCHAR(50) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type (report_type),
    INDEX idx_period (period_start, period_end)
);

-- Insert sample data
INSERT INTO users (email, hashed_password, first_name, last_name, role) VALUES
('admin@hotel.com', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'John', 'Admin', 'admin'),
('manager@hotel.com', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'Jane', 'Manager', 'manager'),
('receptionist@hotel.com', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'Mike', 'Reception', 'receptionist'),
('housekeeping@hotel.com', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 'Maria', 'Housekeeping', 'housekeeping');

INSERT INTO rooms (room_number, room_type, price_per_night, floor, amenities) VALUES
('101', 'standard', 120.00, 1, '["WiFi", "TV", "AC"]'),
('102', 'standard', 120.00, 1, '["WiFi", "TV", "AC"]'),
('201', 'deluxe', 180.00, 2, '["WiFi", "TV", "AC", "Minibar"]'),
('202', 'deluxe', 180.00, 2, '["WiFi", "TV", "AC", "Minibar"]'),
('301', 'suite', 350.00, 3, '["WiFi", "TV", "AC", "Minibar", "Balcony", "Kitchenette"]'),
('401', 'presidential', 500.00, 4, '["WiFi", "TV", "AC", "Minibar", "Balcony", "Kitchenette", "Jacuzzi"]');

INSERT INTO guests (first_name, last_name, email, phone, address, id_number, nationality) VALUES
('John', 'Smith', 'john.smith@email.com', '+1-555-0123', '123 Main St, New York, NY', 'ID123456789', 'USA'),
('Sarah', 'Johnson', 'sarah.johnson@email.com', '+1-555-0124', '456 Oak Ave, Los Angeles, CA', 'ID987654321', 'USA'),
('Michael', 'Brown', 'michael.brown@email.com', '+1-555-0125', '789 Pine Rd, Chicago, IL', 'ID456789123', 'Canada');