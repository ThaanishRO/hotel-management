#!/bin/bash

# Quick deployment script after initial setup
# Run this after copying your application files

set -e

PROJECT_DIR="/opt/hotel-management"
cd $PROJECT_DIR

echo "=== Quick Hotel Management System Deployment ==="

# Install backend dependencies
echo "Installing backend Python dependencies..."
cd backend
../venv/bin/pip install -r requirements.txt
cd ..

# Install frontend dependencies
echo "Installing frontend Node.js dependencies..."
npm install

# Build frontend
echo "Building frontend for production..."
npm run build

# Initialize database
echo "Initializing database..."
mysql -h 192.168.1.2 -u hotel_user -p25846936 hotel_db < database/init.sql || echo "Database already initialized"

# Create database tables
cd backend
../venv/bin/python -c "
from app.database import engine
from app.models import Base
Base.metadata.create_all(bind=engine)
print('Database tables created/updated successfully')
"
cd ..

# Enable and start services
echo "Starting services..."
sudo systemctl enable hotel-backend hotel-frontend
sudo systemctl start hotel-backend
sudo systemctl start hotel-frontend

# Wait for services to start
sleep 5

# Check service status
echo "Checking service status..."
sudo systemctl status hotel-backend --no-pager
sudo systemctl status hotel-frontend --no-pager

echo
echo "=== Deployment Complete ==="
echo "Frontend: http://$(hostname -I | awk '{print $1}')"
echo "Backend API: http://$(hostname -I | awk '{print $1}'):8000"
echo
echo "Default login credentials:"
echo "- Admin: admin@hotel.com / password"
echo "- Manager: manager@hotel.com / password"
echo "- Receptionist: receptionist@hotel.com / password"
echo
echo "Monitor system: $PROJECT_DIR/monitor.sh"