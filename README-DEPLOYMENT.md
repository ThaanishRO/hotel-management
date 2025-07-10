# Hotel Management System - Rocky Linux 10 Deployment Guide

## Prerequisites

- Rocky Linux 10 server with root access
- MySQL database server at 192.168.1.2 with credentials:
  - User: hotel_user
  - Password: 25846936
  - Database: hotel_db
- Minimum 2GB RAM, 2 CPU cores, 20GB disk space

## Quick Deployment Steps

### 1. Initial System Setup

```bash
# Download and run the setup script
curl -O https://your-repo/deploy/rocky-linux-10-deployment.sh
chmod +x rocky-linux-10-deployment.sh
sudo ./rocky-linux-10-deployment.sh
```

### 2. Copy Application Files

```bash
# Copy your application files to the server
scp -r hotel-management-system/* user@your-server:/opt/hotel-management/
```

### 3. Configure Environment

```bash
# Edit the environment files
sudo nano /opt/hotel-management/backend/.env
sudo nano /opt/hotel-management/.env

# Update the following in backend/.env:
# - SECRET_KEY (generate a new one)
# - DATABASE_URL (verify connection details)
# - ALLOWED_ORIGINS (add your domain)
```

### 4. Deploy Application

```bash
# Run the quick deployment script
cd /opt/hotel-management
sudo ./deploy/quick-deploy.sh
```

### 5. Verify Deployment

```bash
# Check system status
./monitor.sh

# Check service logs
journalctl -u hotel-backend -f
journalctl -u hotel-frontend -f
```

## Access URLs

- **Frontend**: http://your-server-ip
- **Backend API**: http://your-server-ip:8000
- **API Documentation**: http://your-server-ip:8000/docs

## Default Login Credentials

- **Admin**: admin@hotel.com / password
- **Manager**: manager@hotel.com / password
- **Receptionist**: receptionist@hotel.com / password
- **Housekeeping**: housekeeping@hotel.com / password

## Management Commands

### Service Management
```bash
# Start services
sudo systemctl start hotel-backend hotel-frontend

# Stop services
sudo systemctl stop hotel-backend hotel-frontend

# Restart services
sudo systemctl restart hotel-backend hotel-frontend

# Check status
sudo systemctl status hotel-backend hotel-frontend
```

### Monitoring
```bash
# System status
/opt/hotel-management/monitor.sh

# View logs
journalctl -u hotel-backend -f
journalctl -u hotel-frontend -f

# Check ports
netstat -tuln | grep -E ':(80|3000|8000)'
```

### Backup & Restore
```bash
# Create backup
/opt/hotel-management/backup.sh

# Restore from backup
mysql -h 192.168.1.2 -u hotel_user -p25846936 hotel_db < /opt/hotel-management/backups/hotel_db_YYYYMMDD_HHMMSS.sql
```

### Updates & Deployment
```bash
# Deploy new version
cd /opt/hotel-management
git pull origin main  # if using git
./deploy.sh
```

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   ```bash
   # Test database connection
   mysql -h 192.168.1.2 -u hotel_user -p25846936 hotel_db
   
   # Check firewall on database server
   # Ensure MySQL is configured to accept remote connections
   ```

2. **Service Won't Start**
   ```bash
   # Check logs
   journalctl -u hotel-backend -n 50
   journalctl -u hotel-frontend -n 50
   
   # Check file permissions
   sudo chown -R hotelapp:hotelapp /opt/hotel-management
   ```

3. **Port Already in Use**
   ```bash
   # Find process using port
   sudo netstat -tulpn | grep :8000
   sudo netstat -tulpn | grep :3000
   
   # Kill process if needed
   sudo kill -9 <PID>
   ```

4. **Frontend Build Fails**
   ```bash
   # Clear npm cache
   npm cache clean --force
   
   # Reinstall dependencies
   rm -rf node_modules package-lock.json
   npm install
   ```

### Performance Optimization

1. **Enable Gzip Compression**
   ```bash
   # Already configured in nginx.conf
   # Verify with: curl -H "Accept-Encoding: gzip" -I http://your-server
   ```

2. **Database Optimization**
   ```sql
   -- Add indexes for better performance
   CREATE INDEX idx_bookings_dates ON bookings(check_in_date, check_out_date);
   CREATE INDEX idx_rooms_status ON rooms(status);
   CREATE INDEX idx_guests_email ON guests(email);
   ```

3. **Monitor Resources**
   ```bash
   # CPU and memory usage
   htop
   
   # Disk usage
   df -h
   
   # Service resource usage
   systemctl status hotel-backend hotel-frontend
   ```

## Security Considerations

1. **Change Default Passwords**
   - Update all default user passwords
   - Generate new SECRET_KEY
   - Use strong database passwords

2. **Firewall Configuration**
   ```bash
   # Only allow necessary ports
   sudo firewall-cmd --permanent --remove-port=8000/tcp  # Remove direct backend access
   sudo firewall-cmd --permanent --remove-port=3000/tcp  # Remove direct frontend access
   sudo firewall-cmd --reload
   ```

3. **SSL/HTTPS Setup**
   ```bash
   # Install certbot for Let's Encrypt
   sudo dnf install certbot python3-certbot-nginx
   
   # Get SSL certificate
   sudo certbot --nginx -d your-domain.com
   ```

4. **Regular Updates**
   ```bash
   # System updates
   sudo dnf update -y
   
   # Application updates
   cd /opt/hotel-management
   ./deploy.sh
   ```

## Support

For issues and support:
1. Check logs: `/opt/hotel-management/logs/`
2. Run monitor script: `/opt/hotel-management/monitor.sh`
3. Review systemd logs: `journalctl -u hotel-backend -u hotel-frontend`