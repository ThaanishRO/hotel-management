#!/bin/bash

# Hotel Management System Deployment Script for Rocky Linux
# This script sets up the complete hotel management system on Rocky Linux

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Hotel Management System deployment on Rocky Linux${NC}"

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
sudo dnf update -y

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
sudo dnf install -y epel-release
sudo dnf install -y git curl wget nano vim firewalld

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install Docker Compose
echo -e "${YELLOW}Installing Docker Compose...${NC}"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Node.js (for frontend development)
echo -e "${YELLOW}Installing Node.js...${NC}"
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs

# Install Python and pip
echo -e "${YELLOW}Installing Python and pip...${NC}"
sudo dnf install -y python3 python3-pip python3-devel

# Install MySQL client
echo -e "${YELLOW}Installing MySQL client...${NC}"
sudo dnf install -y mysql

# Configure firewall
echo -e "${YELLOW}Configuring firewall...${NC}"
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload

# Create application directory
echo -e "${YELLOW}Creating application directory...${NC}"
sudo mkdir -p /opt/hotel-management
sudo chown $USER:$USER /opt/hotel-management
cd /opt/hotel-management

# Clone repository (if using git)
echo -e "${YELLOW}Setting up project structure...${NC}"
# Note: You would typically clone from a git repository here
# git clone https://github.com/your-username/hotel-management-system.git .

# Create directory structure
mkdir -p {backend,frontend,nginx,database,deploy,logs}

# Create environment file
echo -e "${YELLOW}Creating environment configuration...${NC}"
cat > .env << EOF
# Database Configuration
DATABASE_URL=mysql+pymysql://hotel_user:25846936@192.168.1.2:3306/hotel_db

# Security
SECRET_KEY=$(openssl rand -hex 32)
DEBUG=False

# Redis Configuration
REDIS_URL=redis://localhost:6379

# Celery Configuration
CELERY_BROKER_URL=redis://localhost:6379
CELERY_RESULT_BACKEND=redis://localhost:6379

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000

# Frontend Configuration
VITE_API_URL=http://localhost:8000
EOF

# Create systemd service files
echo -e "${YELLOW}Creating systemd service files...${NC}"

# Backend service
sudo tee /etc/systemd/system/hotel-backend.service > /dev/null << EOF
[Unit]
Description=Hotel Management System Backend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/hotel-management/backend
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=/opt/hotel-management/backend
EnvironmentFile=/opt/hotel-management/.env
ExecStart=/usr/local/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Frontend service
sudo tee /etc/systemd/system/hotel-frontend.service > /dev/null << EOF
[Unit]
Description=Hotel Management System Frontend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/hotel-management
Environment=PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/bin/node
Environment=NODE_ENV=production
EnvironmentFile=/opt/hotel-management/.env
ExecStart=/usr/bin/npm run preview -- --host 0.0.0.0 --port 3000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create deployment script
cat > deploy/deploy.sh << 'EOF'
#!/bin/bash

# Deployment script for Hotel Management System

set -e

cd /opt/hotel-management

echo "Pulling latest changes..."
# git pull origin main

echo "Installing backend dependencies..."
cd backend
pip3 install -r requirements.txt --user
cd ..

echo "Installing frontend dependencies..."
npm install

echo "Building frontend..."
npm run build

echo "Restarting services..."
sudo systemctl restart hotel-backend
sudo systemctl restart hotel-frontend
sudo systemctl restart nginx

echo "Deployment completed successfully!"
EOF

chmod +x deploy/deploy.sh

# Create backup script
cat > deploy/backup.sh << 'EOF'
#!/bin/bash

# Backup script for Hotel Management System

BACKUP_DIR="/opt/hotel-management/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Creating database backup..."
mysqldump -h 192.168.1.2 -u hotel_user -p25846936 hotel_db > $BACKUP_DIR/hotel_db_$DATE.sql

echo "Creating application backup..."
tar -czf $BACKUP_DIR/app_backup_$DATE.tar.gz -C /opt/hotel-management --exclude=node_modules --exclude=.git --exclude=backups .

echo "Backup completed: $BACKUP_DIR/hotel_db_$DATE.sql and $BACKUP_DIR/app_backup_$DATE.tar.gz"

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x deploy/backup.sh

# Create monitoring script
cat > deploy/monitor.sh << 'EOF'
#!/bin/bash

# Monitoring script for Hotel Management System

check_service() {
    SERVICE=$1
    if systemctl is-active --quiet $SERVICE; then
        echo "$SERVICE is running"
    else
        echo "$SERVICE is not running - attempting restart"
        sudo systemctl restart $SERVICE
    fi
}

check_port() {
    PORT=$1
    SERVICE=$2
    if netstat -tuln | grep -q ":$PORT "; then
        echo "$SERVICE is listening on port $PORT"
    else
        echo "$SERVICE is not listening on port $PORT"
    fi
}

echo "=== Hotel Management System Status ==="
echo "Date: $(date)"
echo

echo "--- Services Status ---"
check_service hotel-backend
check_service hotel-frontend
check_service nginx
check_service redis

echo

echo "--- Port Status ---"
check_port 8000 "Backend API"
check_port 3000 "Frontend"
check_port 80 "Nginx"

echo

echo "--- Database Connection ---"
if mysql -h 192.168.1.2 -u hotel_user -p25846936 -e "SELECT 1" hotel_db > /dev/null 2>&1; then
    echo "Database connection successful"
else
    echo "Database connection failed"
fi

echo

echo "--- Disk Usage ---"
df -h /opt/hotel-management

echo

echo "--- System Load ---"
uptime
EOF

chmod +x deploy/monitor.sh

# Create cron job for monitoring
echo -e "${YELLOW}Setting up monitoring cron job...${NC}"
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/hotel-management/deploy/monitor.sh >> /opt/hotel-management/logs/monitor.log 2>&1") | crontab -

# Create log rotation
sudo tee /etc/logrotate.d/hotel-management > /dev/null << EOF
/opt/hotel-management/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 $USER $USER
}
EOF

# Enable and start services
echo -e "${YELLOW}Enabling and starting services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable hotel-backend
sudo systemctl enable hotel-frontend

echo -e "${GREEN}Rocky Linux setup completed successfully!${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy your application files to /opt/hotel-management/"
echo "2. Update the .env file with your specific configuration"
echo "3. Run the deployment script: ./deploy/deploy.sh"
echo "4. Start the services: sudo systemctl start hotel-backend hotel-frontend"
echo "5. Monitor the system: ./deploy/monitor.sh"
echo
echo -e "${GREEN}Your hotel management system will be available at:${NC}"
echo "- Frontend: http://$(hostname -I | awk '{print $1}'):3000"
echo "- Backend API: http://$(hostname -I | awk '{print $1}'):8000"
echo "- Nginx (when configured): http://$(hostname -I | awk '{print $1}')"
EOF

chmod +x deploy/rocky-linux-setup.sh

# Create quick start script
cat > deploy/quick-start.sh << 'EOF'
#!/bin/bash

# Quick start script for Hotel Management System

echo "Starting Hotel Management System..."

# Start backend
echo "Starting backend..."
cd /opt/hotel-management/backend
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

# Start frontend
echo "Starting frontend..."
cd /opt/hotel-management
npm run preview -- --host 0.0.0.0 --port 3000 &
FRONTEND_PID=$!

echo "Backend started with PID: $BACKEND_PID"
echo "Frontend started with PID: $FRONTEND_PID"
echo
echo "System is starting up..."
echo "Frontend will be available at: http://localhost:3000"
echo "Backend API will be available at: http://localhost:8000"
echo
echo "Press Ctrl+C to stop all services"

# Wait for interrupt
trap 'kill $BACKEND_PID $FRONTEND_PID; exit' INT
wait
EOF

chmod +x deploy/quick-start.sh

# Create README
cat > README.md << 'EOF'
# Hotel Management System

A comprehensive full-stack hotel management system with role-based access control.

## Features

- Role-based authentication (Admin, Manager, Receptionist, Housekeeping)
- Room management with real-time availability
- Booking and reservation system
- Guest management and check-in/check-out
- Staff management and task assignment
- Financial reporting and analytics
- Housekeeping task management
- Interactive dashboard with charts and metrics

## Technology Stack

- **Frontend**: React 18 + TypeScript + Tailwind CSS
- **Backend**: Python FastAPI + SQLAlchemy + MySQL
- **Database**: MySQL
- **Caching**: Redis
- **Task Queue**: Celery
- **Web Server**: Nginx
- **Containerization**: Docker & Docker Compose

## Quick Start

1. **Setup Rocky Linux environment:**
   ```bash
   chmod +x deploy/rocky-linux-setup.sh
   ./deploy/rocky-linux-setup.sh
   ```

2. **Configure environment:**
   ```bash
   cp backend/.env.example backend/.env
   # Edit backend/.env with your database credentials
   ```

3. **Initialize database:**
   ```bash
   mysql -h 192.168.1.2 -u hotel_user -p25846936 < database/init.sql
   ```

4. **Start services:**
   ```bash
   # Using Docker Compose
   docker-compose up -d

   # Or using the quick start script
   ./deploy/quick-start.sh
   ```

## Default Login Credentials

- **Admin**: admin@hotel.com / password
- **Manager**: manager@hotel.com / password
- **Receptionist**: receptionist@hotel.com / password
- **Housekeeping**: housekeeping@hotel.com / password

## API Documentation

Once the backend is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Deployment

For production deployment on Rocky Linux:

1. Run the setup script: `./deploy/rocky-linux-setup.sh`
2. Copy your application files to `/opt/hotel-management/`
3. Update configuration in `.env`
4. Run deployment: `./deploy/deploy.sh`

## Monitoring

- Check system status: `./deploy/monitor.sh`
- View logs: `tail -f /opt/hotel-management/logs/monitor.log`
- Create backups: `./deploy/backup.sh`

## Support

For issues and support, please check the logs in `/opt/hotel-management/logs/`
EOF