#!/bin/bash

# Product Purchase Assistant Production Deployment Script
# Deploy to production server: 95.182.101.204
# Target path: /root/app/ppa

set -e  # Exit on any error

# Configuration
SERVER_IP="95.182.101.204"
SERVER_USER="root"
SERVER_PASSWORD="dIZh8ffU6b4GBlHg#"
DEPLOY_PATH="/root/app/ppa"
PROJECT_NAME="product-purchase-assistant"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if sshpass is available for password authentication
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v sshpass &> /dev/null; then
        log_error "sshpass is required for password authentication"
        log_info "Install it with: sudo apt-get install sshpass"
        exit 1
    fi
    
    if ! command -v rsync &> /dev/null; then
        log_error "rsync is required for file transfer"
        log_info "Install it with: sudo apt-get install rsync"
        exit 1
    fi
    
    log_success "All dependencies are available"
}

# Function to execute commands on remote server
execute_remote() {
    local command="$1"
    log_info "Executing on server: $command"
    
    sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" "$command"
}

# Function to copy files to remote server
copy_to_remote() {
    local source="$1"
    local destination="$2"
    log_info "Copying $source to server:$destination"
    
    sshpass -p "$SERVER_PASSWORD" rsync -avz -e "ssh -o StrictHostKeyChecking=no" \
        --exclude '.git' \
        --exclude 'node_modules' \
        --exclude '.env' \
        --exclude 'tmp' \
        --exclude 'log' \
        "$source" "$SERVER_USER@$SERVER_IP:$destination"
}

# Main deployment function
deploy() {
    log_info "Starting deployment to $SERVER_IP:$DEPLOY_PATH"
    
    # Create deployment directory structure
    log_info "Setting up deployment directory structure..."
    execute_remote "mkdir -p $DEPLOY_PATH"
    execute_remote "mkdir -p $DEPLOY_PATH/backups"
    
    # Backup existing deployment if it exists
    log_info "Creating backup of existing deployment..."
    execute_remote "if [ -d '$DEPLOY_PATH/current' ]; then 
        BACKUP_NAME=backup_\$(date +%Y%m%d_%H%M%S)
        cp -r $DEPLOY_PATH/current $DEPLOY_PATH/backups/\$BACKUP_NAME
        echo 'Backup created: \$BACKUP_NAME'
    fi"
    
    # Copy project files to server
    log_info "Transferring project files..."
    copy_to_remote "./" "$DEPLOY_PATH/new_release/"
    
    # Install Docker and Docker Compose on server if not present
    log_info "Ensuring Docker is installed on server..."
    execute_remote "
        # Update package index
        apt-get update
        
        # Install Docker if not present
        if ! command -v docker &> /dev/null; then
            echo 'Installing Docker...'
            apt-get install -y ca-certificates curl gnupg lsb-release
            mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            systemctl start docker
            systemctl enable docker
        else
            echo 'Docker is already installed'
        fi
        
        # Verify Docker installation
        docker --version
        docker compose version
    "
    
    # Setup production environment file
    log_info "Setting up production environment..."
    execute_remote "cd $DEPLOY_PATH/new_release && cat > .env << 'EOF'
# Production Environment Configuration
RAILS_ENV=production
NODE_ENV=production

# Backend Configuration
RAILS_MASTER_KEY=bae6e853799d6c4a5abe1e209a474d2f
OPENROUTER_API_KEY=your_openrouter_api_key_here
BROWSER_TYPE=firefox

# Frontend Configuration
NUXT_PUBLIC_API_BASE=http://backend/api/v1

# Production specific settings
RAILS_LOG_LEVEL=info
RAILS_SERVE_STATIC_FILES=true
EOF"
    
    # Stop existing containers if running
    log_info "Stopping existing containers..."
    execute_remote "cd $DEPLOY_PATH && if [ -d 'current' ]; then 
        cd current && docker compose -f docker-compose.prod.yml down || true
    fi"
    
    # Build and start new deployment
    log_info "Building and starting new deployment..."
    execute_remote "cd $DEPLOY_PATH/new_release && 
        docker compose -f docker-compose.prod.yml build --no-cache
        docker compose -f docker-compose.prod.yml up -d
    "
    
    # Wait for services to be healthy
    log_info "Waiting for services to be healthy..."
    execute_remote "cd $DEPLOY_PATH/new_release && 
        timeout=300
        counter=0
        while [ \$counter -lt \$timeout ]; do
            if docker compose -f docker-compose.prod.yml ps --format json | grep -q '\"Health\":\"healthy\"'; then
                echo 'Services are healthy!'
                break
            fi
            echo 'Waiting for services to be healthy...'
            sleep 10
            counter=\$((counter + 10))
        done
        
        if [ \$counter -ge \$timeout ]; then
            echo 'Services failed to become healthy within timeout'
            docker compose -f docker-compose.prod.yml logs
            exit 1
        fi
    "
    
    # Switch to new deployment
    log_info "Switching to new deployment..."
    execute_remote "cd $DEPLOY_PATH && 
        rm -rf current_old
        if [ -d 'current' ]; then mv current current_old; fi
        mv new_release current
    "
    
    # Cleanup old containers and images
    log_info "Cleaning up old Docker resources..."
    execute_remote "docker system prune -f"
    
    log_success "Deployment completed successfully!"
    log_info "Application should be available at: http://$SERVER_IP"
    log_info "Backend API: http://$SERVER_IP/api/"
    log_info "Health check: http://$SERVER_IP/up"
}

# Rollback function
rollback() {
    log_warning "Initiating rollback to previous deployment..."
    
    execute_remote "cd $DEPLOY_PATH && 
        if [ -d 'current_old' ]; then
            # Stop current deployment
            cd current && docker compose -f docker-compose.prod.yml down || true
            
            # Switch back to old deployment
            cd $DEPLOY_PATH
            mv current current_failed
            mv current_old current
            
            # Start old deployment
            cd current && docker compose -f docker-compose.prod.yml up -d
            
            echo 'Rollback completed successfully'
        else
            echo 'No previous deployment found for rollback'
            exit 1
        fi
    "
    
    log_success "Rollback completed successfully!"
}

# Show deployment status
status() {
    log_info "Checking deployment status on $SERVER_IP..."
    
    execute_remote "cd $DEPLOY_PATH/current 2>/dev/null && 
        echo '=== Docker Compose Status ==='
        docker compose -f docker-compose.prod.yml ps
        
        echo -e '\n=== Container Logs (last 20 lines) ==='
        docker compose -f docker-compose.prod.yml logs --tail=20
        
        echo -e '\n=== System Resources ==='
        df -h
        free -h
    " || {
        log_error "Failed to get status. Deployment might not exist."
        exit 1
    }
}

# Usage information
usage() {
    echo "Usage: $0 [deploy|rollback|status]"
    echo ""
    echo "Commands:"
    echo "  deploy    - Deploy the application to production server"
    echo "  rollback  - Rollback to the previous deployment"
    echo "  status    - Check the status of the current deployment"
    echo ""
    echo "Server: $SERVER_IP"
    echo "Path: $DEPLOY_PATH"
}

# Main script logic
case "$1" in
    deploy)
        check_dependencies
        deploy
        ;;
    rollback)
        check_dependencies
        rollback
        ;;
    status)
        check_dependencies
        status
        ;;
    *)
        usage
        exit 1
        ;;
esac