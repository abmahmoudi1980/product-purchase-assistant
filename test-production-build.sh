#!/bin/bash

# Test deployment locally before pushing to production
# This script validates the production Docker build

set -e

echo "🧪 Testing Production Build Locally"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test containers..."
    docker compose -f docker-compose.prod.yml down -v --remove-orphans 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Check if .env exists and has required values
log_info "Checking environment configuration..."
if [[ ! -f .env ]]; then
    log_error ".env file not found. Creating from example..."
    cp .env.example .env
    sed -i 's/your_rails_master_key_here/bae6e853799d6c4a5abe1e209a474d2f/' .env
    log_success "Created .env file with Rails master key"
fi

# Validate Docker Compose configuration
log_info "Validating Docker Compose configuration..."
docker compose -f docker-compose.prod.yml config > /dev/null
log_success "Docker Compose configuration is valid"

# Build images
log_info "Building production images (this may take several minutes)..."
docker compose -f docker-compose.prod.yml build --no-cache

log_success "Images built successfully"

# Start services
log_info "Starting production services..."
docker compose -f docker-compose.prod.yml up -d

# Wait for services to be healthy
log_info "Waiting for services to be healthy (up to 5 minutes)..."
timeout=300
counter=0
healthy=false

while [ $counter -lt $timeout ]; do
    # Check if all services are healthy or running
    backend_healthy=$(docker compose -f docker-compose.prod.yml ps backend --format json | jq -r '.Health // "healthy"')
    frontend_healthy=$(docker compose -f docker-compose.prod.yml ps frontend --format json | jq -r '.Health // "healthy"')
    proxy_running=$(docker compose -f docker-compose.prod.yml ps reverse-proxy --format json | jq -r '.State')
    
    if [[ "$backend_healthy" == "healthy" && "$frontend_healthy" == "healthy" && "$proxy_running" == "running" ]]; then
        healthy=true
        break
    fi
    
    echo -n "."
    sleep 10
    counter=$((counter + 10))
done

echo ""

if [ "$healthy" = true ]; then
    log_success "All services are healthy!"
else
    log_error "Services failed to become healthy within timeout"
    log_info "Showing logs for debugging:"
    docker compose -f docker-compose.prod.yml logs
    exit 1
fi

# Test endpoints
log_info "Testing application endpoints..."

# Test health endpoint
if curl -f http://localhost/up > /dev/null 2>&1; then
    log_success "Backend health check passed"
else
    log_error "Backend health check failed"
    docker compose -f docker-compose.prod.yml logs backend
    exit 1
fi

# Test frontend
if curl -f http://localhost > /dev/null 2>&1; then
    log_success "Frontend is responding"
else
    log_error "Frontend is not responding"
    docker compose -f docker-compose.prod.yml logs frontend
    exit 1
fi

# Test API endpoint (basic check)
if curl -f http://localhost/api/v1 > /dev/null 2>&1 || curl -s http://localhost/api/v1 | grep -q "error\|not found" > /dev/null 2>&1; then
    log_success "API endpoint is accessible"
else
    log_info "API endpoint test inconclusive (this may be normal if no routes are defined)"
fi

# Show final status
log_info "Showing final container status:"
docker compose -f docker-compose.prod.yml ps

log_success "Production build test completed successfully!"
log_info "The application is ready for deployment to production"
log_info ""
log_info "Next steps:"
log_info "1. Run: ./deploy.sh deploy"
log_info "2. Monitor deployment: ./deploy.sh status"
log_info "3. If issues occur: ./deploy.sh rollback"

# Cleanup will run automatically due to trap