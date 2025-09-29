# Docker Setup Guide

This project includes comprehensive Docker support for both development and production environments.

## Quick Start with Docker

### Development Environment

For local development with hot reloading and volume mounting:

```bash
# Start both backend and frontend services
docker-compose -f docker-compose.dev.yml up

# Or start individually:
docker-compose -f docker-compose.dev.yml up backend
docker-compose -f docker-compose.dev.yml up frontend
```

The services will be available at:
- Frontend: http://localhost:3000
- Backend API: http://localhost:3001

### Production Environment (using built images)

For production deployment with optimized builds:

```bash
# Build and start all services
docker-compose -f docker-compose.prod.yml up --build

# Or using the main docker-compose file (development friendly)
docker-compose up --build
```

## Docker Files Overview

### Backend Docker Support

1. **Dockerfile** (Production): Multi-stage build with Rails 8.0, optimized for production with Thruster and browser automation support
2. **Dockerfile.dev** (Development): Development-friendly build with Firefox browser for web scraping
3. **.dockerignore**: Excludes unnecessary files from Docker build context

### Frontend Docker Support

1. **Dockerfile**: Multi-stage build for Nuxt.js with production optimization
2. **.dockerignore**: Excludes node_modules and build artifacts

### Docker Compose Configurations

1. **docker-compose.yml**: Development setup with volume mounting for hot reloading
2. **docker-compose.dev.yml**: Simplified development setup using base images
3. **docker-compose.prod.yml**: Production setup with reverse proxy (Nginx)
4. **nginx.conf**: Nginx configuration for production reverse proxy

## Environment Configuration

### Environment Variables

Create a `.env` file in the root directory:

```bash
# Backend Configuration
RAILS_MASTER_KEY=your_rails_master_key_here
OPENROUTER_API_KEY=your_openrouter_api_key_here
BROWSER_TYPE=firefox

# Frontend Configuration
NUXT_PUBLIC_API_BASE=http://localhost:3001/api/v1
```

For Docker environments, the API base URL will be automatically configured to use the backend container.

### Database

The application uses SQLite3 for both development and production. The database files are stored in the backend container and persist through volume mounting.

## Building Individual Images

### Backend
```bash
# Development image
cd backend
docker build -f Dockerfile.dev -t product-assistant-backend-dev .

# Production image
cd backend  
docker build -t product-assistant-backend .
```

### Frontend
```bash
cd frontend
docker build -t product-assistant-frontend .
```

## Network Architecture

The Docker setup creates an isolated network (`app-network`) where:
- Frontend communicates with backend using service names
- Backend runs on port 3001 internally
- Frontend runs on port 3000 internally
- Both services expose their ports to the host

## Health Checks

Both services include health checks:
- Backend: Checks `/up` endpoint
- Frontend: Checks root endpoint availability

## Volume Persistence

- **backend_bundle**: Persists Ruby gems
- **frontend_node_modules**: Persists Node.js modules
- **Backend app files**: Mounted for development hot reloading
- **Frontend app files**: Mounted for development hot reloading

## Production Considerations

### Security Features
- Non-root users in all containers
- Minimal base images (Alpine Linux for frontend)
- Multi-stage builds to reduce image size
- Proper secrets management via environment variables

### Performance Optimizations
- Bundle caching for faster rebuilds  
- Nginx reverse proxy for production load balancing
- Thruster optimization for Rails assets
- Health checks for container orchestration

### Browser Automation Support
- Firefox browser pre-installed for Digikala scraping
- Headless browser configuration ready for production
- Browser type configurable via environment variables

## Troubleshooting

### Common Issues

1. **Port conflicts**: Make sure ports 3000 and 3001 are not in use
2. **Volume permissions**: On some systems, you may need to adjust file permissions
3. **Memory issues**: Ensure Docker has sufficient memory allocated (4GB recommended)
4. **Network issues**: Check firewall settings if containers can't communicate

### Debugging

```bash
# View logs for all services
docker-compose -f docker-compose.dev.yml logs

# View logs for specific service
docker-compose -f docker-compose.dev.yml logs backend

# Execute commands in running containers
docker-compose -f docker-compose.dev.yml exec backend bash
docker-compose -f docker-compose.dev.yml exec frontend sh

# Rebuild services after changes
docker-compose -f docker-compose.dev.yml up --build
```

### Development Tips

1. Use `docker-compose.dev.yml` for active development
2. Backend changes will reload automatically with volume mounting
3. Frontend changes will hot-reload with Nuxt.js dev server
4. Database changes persist in Docker volumes
5. Use `docker-compose down -v` to reset all data

## Integration with Kamal (Production Deployment)

The backend Dockerfile is compatible with Kamal deployment. For cloud deployment:

```bash
# Configure Kamal (separate setup required)
kamal setup
kamal deploy
```

This Docker setup provides a complete development and production environment for the Product Purchase Assistant application with proper service isolation, networking, and deployment readiness.