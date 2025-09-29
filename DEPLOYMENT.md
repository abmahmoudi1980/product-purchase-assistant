# Production Deployment Guide

This document provides comprehensive instructions for deploying the Product Purchase Assistant to the production server.

## Server Details

- **IP Address**: 95.182.101.204
- **Username**: root  
- **Deploy Path**: /root/app/ppa
- **Access Method**: SSH with password authentication

## Prerequisites

Before running the deployment, ensure you have the following tools installed on your local machine:

```bash
# Install required tools on Ubuntu/Debian
sudo apt-get update
sudo apt-get install sshpass rsync

# Install required tools on macOS (using Homebrew)
brew install sshpass rsync
```

## Quick Deployment

To deploy the application to production:

```bash
# Make the deployment script executable
chmod +x deploy.sh

# Deploy to production
./deploy.sh deploy
```

## Deployment Commands

The deployment script supports the following commands:

### Deploy Application
```bash
./deploy.sh deploy
```
This command will:
1. Create a backup of the existing deployment
2. Transfer project files to the server
3. Install Docker and Docker Compose if not present
4. Build Docker images
5. Start the production services
6. Verify health checks
7. Switch to the new deployment

### Check Status
```bash
./deploy.sh status
```
This command shows:
- Docker container status
- Recent logs from all services  
- Server resource usage

### Rollback Deployment
```bash
./deploy.sh rollback
```
This command will:
1. Stop the current deployment
2. Switch back to the previous deployment
3. Start the previous version

## Deployment Process Details

### 1. Pre-deployment Preparation

The deployment script automatically:
- Creates backup of existing deployment with timestamp
- Sets up directory structure on server
- Transfers files (excluding `.git`, `node_modules`, etc.)

### 2. Server Setup

If Docker is not installed, the script will:
- Update package repositories
- Install Docker CE and Docker Compose
- Start and enable Docker service
- Verify installation

### 3. Application Configuration

Creates production `.env` file with:
- Production Rails environment
- Rails master key for encrypted credentials
- Browser configuration for web scraping
- API endpoint configuration

### 4. Service Deployment

Using `docker-compose.prod.yml`:
- **Backend**: Rails app with Thruster server (port 3001 → 80)
- **Frontend**: Nuxt.js app (port 3000)
- **Reverse Proxy**: Nginx (port 80)

### 5. Health Monitoring

The deployment waits for services to become healthy:
- Backend health check: `/up` endpoint
- Frontend health check: root endpoint
- Timeout: 5 minutes

## Service Architecture

```
Internet → Nginx (Port 80) → Frontend (Port 3000) for /
                          → Backend (Port 80) for /api/*
```

### Service URLs

- **Main Application**: http://95.182.101.204
- **API Endpoints**: http://95.182.101.204/api/
- **Health Check**: http://95.182.101.204/up

## Directory Structure on Server

```
/root/app/ppa/
├── current/           # Current active deployment
├── current_old/       # Previous deployment (for rollback)
├── backups/           # Timestamped backups
│   ├── backup_20231201_143022/
│   └── backup_20231201_120156/
└── new_release/       # Temporary directory during deployment
```

## Backup and Rollback Strategy

### Automatic Backups
- Created before each deployment
- Stored in `/root/app/ppa/backups/`
- Named with timestamp: `backup_YYYYMMDD_HHMMSS`

### Manual Backup
```bash
# SSH to server
sshpass -p "dIZh8ffU6b4GBlHg#" ssh root@95.182.101.204

# Create manual backup
cd /root/app/ppa
cp -r current backups/manual_backup_$(date +%Y%m%d_%H%M%S)
```

### Rollback Process
1. Stops current deployment
2. Moves current to `current_failed`
3. Restores `current_old` to `current`
4. Starts the previous deployment

## Troubleshooting

### Common Issues

#### 1. Connection Issues
```bash
# Test SSH connection
sshpass -p "dIZh8ffU6b4GBlHg#" ssh root@95.182.101.204 'echo "Connection successful"'
```

#### 2. Docker Issues
```bash
# Check Docker status on server
./deploy.sh status

# Or manually SSH and check
sshpass -p "dIZh8ffU6b4GBlHg#" ssh root@95.182.101.204
docker ps
docker compose -f /root/app/ppa/current/docker-compose.prod.yml logs
```

#### 3. Service Health Issues
```bash
# Check individual service logs
docker compose -f docker-compose.prod.yml logs backend
docker compose -f docker-compose.prod.yml logs frontend
docker compose -f docker-compose.prod.yml logs reverse-proxy
```

#### 4. Port Conflicts
```bash
# Check what's using port 80
sudo netstat -tlnp | grep :80

# Stop conflicting services
sudo systemctl stop apache2  # If Apache is running
sudo systemctl stop nginx    # If system Nginx is running
```

### Recovery Procedures

#### Complete Recovery from Backup
```bash
# SSH to server
sshpass -p "dIZh8ffU6b4GBlHg#" ssh root@95.182.101.204

# Stop current deployment
cd /root/app/ppa/current
docker compose -f docker-compose.prod.yml down

# Restore from specific backup
cd /root/app/ppa
rm -rf current
cp -r backups/backup_YYYYMMDD_HHMMSS current

# Start restored deployment
cd current
docker compose -f docker-compose.prod.yml up -d
```

## Security Considerations

### Server Security
- Server uses password authentication (consider switching to SSH keys)
- Application runs in Docker containers with non-root users
- Nginx reverse proxy provides additional security layer

### Application Security
- Rails master key is secured in encrypted credentials
- SSL/TLS termination should be handled by external load balancer
- Browser automation runs in sandboxed containers

## Monitoring and Maintenance

### Health Monitoring
```bash
# Automated health check
curl -f http://95.182.101.204/up

# Check specific services
curl -f http://95.182.101.204/
curl -f http://95.182.101.204/api/v1/health
```

### Log Monitoring
```bash
# View recent logs
./deploy.sh status

# Follow logs in real-time
sshpass -p "dIZh8ffU6b4GBlHg#" ssh root@95.182.101.204
cd /root/app/ppa/current
docker compose -f docker-compose.prod.yml logs -f
```

### Resource Monitoring
```bash
# Check server resources
sshpass -p "dIZh8ffU6b4GBlHg#" ssh root@95.182.101.204 'df -h && free -h'

# Check Docker resource usage
sshpass -p "dIZh8ffU6b4GBlHg#" ssh root@95.182.101.204 'docker stats --no-stream'
```

## Environment Variables

Key environment variables used in production:

| Variable | Value | Purpose |
|----------|-------|---------|
| `RAILS_ENV` | production | Rails environment |
| `RAILS_MASTER_KEY` | bae6e853799d6c4a5abe1e209a474d2f | Rails encrypted credentials |
| `NODE_ENV` | production | Node.js environment |
| `BROWSER_TYPE` | firefox | Web scraping browser |
| `NUXT_PUBLIC_API_BASE` | http://backend/api/v1 | Frontend API endpoint |

## Performance Optimization

### Docker Optimizations
- Multi-stage builds reduce image sizes
- Volume caching for dependencies
- Non-root users for security
- Health checks for reliability

### Application Optimizations
- Rails asset pipeline with Thruster
- Nuxt.js production build optimization
- Nginx reverse proxy for static assets
- SQLite database for simplified deployment

## Backup Schedule Recommendation

Consider implementing automated backups:

```bash
# Add to server crontab
0 2 * * * cd /root/app/ppa && cp -r current backups/auto_backup_$(date +\%Y\%m\%d_\%H\%M\%S)

# Clean old backups (keep last 10)
0 3 * * * cd /root/app/ppa/backups && ls -t | tail -n +11 | xargs rm -rf
```

## Support and Maintenance

### Update Process
1. Test changes locally using `docker-compose.prod.yml`
2. Deploy using `./deploy.sh deploy`
3. Verify deployment with `./deploy.sh status`
4. Monitor logs for any issues
5. Rollback if needed with `./deploy.sh rollback`

### Emergency Contacts
- Keep server credentials secure
- Document any custom configurations
- Maintain backup of critical data

This deployment guide ensures reliable, repeatable deployments with proper backup and rollback capabilities.