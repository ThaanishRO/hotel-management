#!/bin/bash

# Hotel Management System Deployment Script for Rocky Linux 10
# Run this script as root or with sudo privileges

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/opt/hotel-management"
DB_HOST="192.168.1.2"
DB_USER="hotel_user"
DB_PASS="25846936"
DB_NAME="hotel_db"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Hotel Management System Deployment${NC}"
echo -e "${GREEN}Rocky Linux 10 Setup${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${YELLOW}Running as root. Creating deployment user...${NC}"
   useradd -m -s /bin/bash hotelapp || true
   usermod -aG wheel hotelapp
   DEPLOY_USER="hotelapp"
else
   DEPLOY_USER=$(whoami)
   echo -e "${YELLOW}Running as user: $DEPLOY_USER${NC}"
fi

# Update system
echo -e "${BLUE}Step 1: Updating system packages...${NC}"
dnf update -y
dnf install -y epel-release

# Install required packages
echo -e "${BLUE}Step 2: Installing required packages...${NC}"
dnf groupinstall -y "Development Tools"
dnf install -y \
    git \
    curl \
    wget \
    nano \
    vim \
    firewalld \
    nginx \
    redis \
    python3 \
    python3-pip \
    python3-devel \
    mysql \
    mysql-devel \
    gcc \
    gcc-c++ \
    make \
    openssl-devel \
    libffi-devel \
    zlib-devel \
    bzip2-devel \
    readline-devel \
    sqlite-devel \
    pkg-config

# Install Node.js 18
echo -e "${BLUE}Step 3: Installing Node.js 18...${NC}"
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs

# Install PM2 for process management
echo -e "${BLUE}Step 4: Installing PM2...${NC}"
npm install -g pm2

# Create project directory
echo -e "${BLUE}Step 5: Setting up project directory...${NC}"
mkdir -p $PROJECT_DIR
mkdir -p $PROJECT_DIR/{logs,uploads,backups}
chown -R $DEPLOY_USER:$DEPLOY_USER $PROJECT_DIR

# Install Python dependencies
echo -e "${BLUE}Step 6: Installing Python dependencies...${NC}"
pip3 install --upgrade pip
pip3 install virtualenv

# Create Python virtual environment
cd $PROJECT_DIR
sudo -u $DEPLOY_USER python3 -m venv venv
sudo -u $DEPLOY_USER $PROJECT_DIR/venv/bin/pip install --upgrade pip

# Configure firewall
echo -e "${BLUE}Step 7: Configuring firewall...${NC}"
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --permanent --add-port=3000/tcp
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Start and enable services
echo -e "${BLUE}Step 8: Starting services...${NC}"
systemctl start redis
systemctl enable redis
systemctl start nginx
systemctl enable nginx

# Create systemd service for backend
echo -e "${BLUE}Step 9: Creating systemd services...${NC}"
cat > /etc/systemd/system/hotel-backend.service << EOF
[Unit]
Description=Hotel Management System Backend
After=network.target redis.service

[Service]
Type=simple
User=$DEPLOY_USER
Group=$DEPLOY_USER
WorkingDirectory=$PROJECT_DIR/backend
Environment=PATH=$PROJECT_DIR/venv/bin
EnvironmentFile=$PROJECT_DIR/backend/.env
ExecStart=$PROJECT_DIR/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for frontend
cat > /etc/systemd/system/hotel-frontend.service << EOF
[Unit]
Description=Hotel Management System Frontend
After=network.target

[Service]
Type=simple
User=$DEPLOY_USER
Group=$DEPLOY_USER
WorkingDirectory=$PROJECT_DIR
Environment=PATH=/usr/bin:/bin:/usr/local/bin
Environment=NODE_ENV=production
EnvironmentFile=$PROJECT_DIR/.env
ExecStart=/usr/bin/npm run preview -- --host 0.0.0.0 --port 3000
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create deployment script
echo -e "${BLUE}Step 10: Creating deployment scripts...${NC}"
cat > $PROJECT_DIR/deploy.sh << 'EOF'
#!/bin/bash

set -e

PROJECT_DIR="/opt/hotel-management"
cd $PROJECT_DIR

echo "=== Hotel Management System Deployment ==="

# Backup current deployment
if [ -d "backend" ]; then
    echo "Creating backup..."
    tar -czf backups/backup-$(date +%Y%m%d-%H%M%S).tar.gz backend frontend --exclude=node_modules --exclude=__pycache__ --exclude=.git
fi

echo "Installing backend dependencies..."
cd backend
../venv/bin/pip install -r requirements.txt
cd ..

echo "Installing frontend dependencies..."
npm install

echo "Building frontend..."
npm run build

echo "Running database migrations..."
cd backend
../venv/bin/python -c "
from app.database import engine
from app.models import Base
Base.metadata.create_all(bind=engine)
print('Database tables created successfully')
"
cd ..

echo "Restarting services..."
sudo systemctl restart hotel-backend
sudo systemctl restart hotel-frontend
sudo systemctl restart nginx

echo "Checking service status..."
sudo systemctl status hotel-backend --no-pager
sudo systemctl status hotel-frontend --no-pager

echo "Deployment completed successfully!"
echo "Frontend: http://$(hostname -I | awk '{print $1}'):3000"
echo "Backend API: http://$(hostname -I | awk '{print $1}'):8000"
EOF

chmod +x $PROJECT_DIR/deploy.sh
chown $DEPLOY_USER:$DEPLOY_USER $PROJECT_DIR/deploy.sh

# Create monitoring script
cat > $PROJECT_DIR/monitor.sh << 'EOF'
#!/bin/bash

echo "=== Hotel Management System Status ==="
echo "Date: $(date)"
echo

echo "--- Service Status ---"
systemctl is-active hotel-backend && echo "✓ Backend: Running" || echo "✗ Backend: Stopped"
systemctl is-active hotel-frontend && echo "✓ Frontend: Running" || echo "✗ Frontend: Stopped"
systemctl is-active nginx && echo "✓ Nginx: Running" || echo "✗ Nginx: Stopped"
systemctl is-active redis && echo "✓ Redis: Running" || echo "✗ Redis: Stopped"

echo
echo "--- Port Status ---"
netstat -tuln | grep -q ":8000 " && echo "✓ Backend API: Port 8000 open" || echo "✗ Backend API: Port 8000 closed"
netstat -tuln | grep -q ":3000 " && echo "✓ Frontend: Port 3000 open" || echo "✗ Frontend: Port 3000 closed"
netstat -tuln | grep -q ":80 " && echo "✓ Nginx: Port 80 open" || echo "✗ Nginx: Port 80 closed"

echo
echo "--- Database Connection ---"
mysql -h 192.168.1.2 -u hotel_user -p25846936 -e "SELECT 1" hotel_db > /dev/null 2>&1 && echo "✓ Database: Connected" || echo "✗ Database: Connection failed"

echo
echo "--- System Resources ---"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')"
echo "Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
echo "Disk Usage: $(df -h $PROJECT_DIR | awk 'NR==2{printf "%s", $5}')"

echo
echo "--- Recent Logs ---"
echo "Backend logs (last 5 lines):"
journalctl -u hotel-backend --no-pager -n 5

echo
echo "Frontend logs (last 5 lines):"
journalctl -u hotel-frontend --no-pager -n 5
EOF

chmod +x $PROJECT_DIR/monitor.sh
chown $DEPLOY_USER:$DEPLOY_USER $PROJECT_DIR/monitor.sh

# Create backup script
cat > $PROJECT_DIR/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/hotel-management/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Creating database backup..."
mysqldump -h 192.168.1.2 -u hotel_user -p25846936 hotel_db > $BACKUP_DIR/hotel_db_$DATE.sql

echo "Creating application backup..."
tar -czf $BACKUP_DIR/app_backup_$DATE.tar.gz -C /opt/hotel-management \
    --exclude=node_modules \
    --exclude=__pycache__ \
    --exclude=.git \
    --exclude=backups \
    --exclude=logs \
    --exclude=venv \
    backend frontend .env

echo "Backup completed:"
echo "- Database: $BACKUP_DIR/hotel_db_$DATE.sql"
echo "- Application: $BACKUP_DIR/app_backup_$DATE.tar.gz"

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Old backups cleaned up (kept last 7 days)"
EOF

chmod +x $PROJECT_DIR/backup.sh
chown $DEPLOY_USER:$DEPLOY_USER $PROJECT_DIR/backup.sh

# Setup log rotation
echo -e "${BLUE}Step 11: Setting up log rotation...${NC}"
cat > /etc/logrotate.d/hotel-management << EOF
$PROJECT_DIR/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 $DEPLOY_USER $DEPLOY_USER
    postrotate
        systemctl reload hotel-backend hotel-frontend
    endscript
}
EOF

# Setup cron jobs
echo -e "${BLUE}Step 12: Setting up cron jobs...${NC}"
(crontab -u $DEPLOY_USER -l 2>/dev/null; echo "*/5 * * * * $PROJECT_DIR/monitor.sh >> $PROJECT_DIR/logs/monitor.log 2>&1") | crontab -u $DEPLOY_USER -
(crontab -u $DEPLOY_USER -l 2>/dev/null; echo "0 2 * * * $PROJECT_DIR/backup.sh >> $PROJECT_DIR/logs/backup.log 2>&1") | crontab -u $DEPLOY_USER -

# Create nginx configuration
echo -e "${BLUE}Step 13: Configuring Nginx...${NC}"
cat > /etc/nginx/conf.d/hotel-management.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Frontend
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # API routes
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files
    location /static/ {
        alias /opt/hotel-management/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Test nginx configuration
nginx -t

# Reload systemd and nginx
systemctl daemon-reload
systemctl reload nginx

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy your application files to $PROJECT_DIR/"
echo "2. Update the .env files with your configuration"
echo "3. Run the deployment script: $PROJECT_DIR/deploy.sh"
echo "4. Monitor the system: $PROJECT_DIR/monitor.sh"
echo
echo -e "${YELLOW}Default access URLs:${NC}"
echo "- Frontend: http://$(hostname -I | awk '{print $1}')"
echo "- Backend API: http://$(hostname -I | awk '{print $1}')/api"
echo "- Direct Frontend: http://$(hostname -I | awk '{print $1}'):3000"
echo "- Direct Backend: http://$(hostname -I | awk '{print $1}'):8000"
echo
echo -e "${YELLOW}Useful commands:${NC}"
echo "- Check status: $PROJECT_DIR/monitor.sh"
echo "- Create backup: $PROJECT_DIR/backup.sh"
echo "- Deploy updates: $PROJECT_DIR/deploy.sh"
echo "- View logs: journalctl -u hotel-backend -f"
echo "- Restart services: systemctl restart hotel-backend hotel-frontend"
EOF