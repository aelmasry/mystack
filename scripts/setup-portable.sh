#!/bin/bash

# MyStack Portable Setup Script
# This script sets up the portable MyStack environment
# Run with: bash /opt/mystack/scripts/setup-portable.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log "Starting MyStack Portable Setup..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    error "Docker is not running. Please start Docker first."
    exit 1
fi

log "Docker and Docker Compose are available"

# Create necessary directories
log "Creating necessary directories..."
mkdir -p proxy/data proxy/letsencrypt
mkdir -p n8n/data n8n/database n8n/redis-data
mkdir -p ollama/models ollama/webui-data ollama/config
mkdir -p monitoring/portainer-data
mkdir -p websites/static-files websites/demo
mkdir -p backups/daily backups/weekly backups/manual
mkdir -p shared/configs shared/certificates shared/logs

# Set proper permissions
log "Setting proper permissions..."
chmod +x scripts/*.sh
chmod 755 proxy/data n8n/data n8n/database n8n/redis-data
chmod 755 ollama/models ollama/webui-data ollama/config
chmod 755 monitoring/portainer-data

# Create .gitkeep files for empty directories
log "Creating .gitkeep files..."
find . -type d -name "data" -o -name "database" -o -name "models" -o -name "webui-data" -o -name "portainer-data" -o -name "redis-data" -o -name "letsencrypt" | while read dir; do
    touch "$dir/.gitkeep"
done

# Create environment files if they don't exist
log "Creating environment files..."
if [[ ! -f "proxy/.env" ]]; then
    cp shared/configs/global.env.example proxy/.env 2>/dev/null || echo "# Nginx Proxy Manager Environment" > proxy/.env
fi

if [[ ! -f "n8n/.env" ]]; then
    cp shared/configs/global.env.example n8n/.env 2>/dev/null || echo "# n8n Environment" > n8n/.env
fi

if [[ ! -f "ollama/.env" ]]; then
    cp shared/configs/global.env.example ollama/.env 2>/dev/null || echo "# Ollama Environment" > ollama/.env
fi

# Create Docker network
log "Creating Docker network..."
docker network create mystack-network 2>/dev/null || log "Network mystack-network already exists"

# Deploy services
log "Deploying services..."
bash scripts/deploy-all.sh

log "Portable setup completed successfully!"
echo ""
echo -e "${BLUE}=== Access Your Services ===${NC}"
echo "• Nginx Proxy Manager: http://localhost:81"
echo "• n8n: http://localhost:5678"
echo "• OpenWebUI: http://localhost:3000"
echo "• Portainer: http://localhost:9000"
echo "• Dozzle: http://localhost:8080"
echo "• Demo Websites: http://localhost"
echo ""
echo -e "${BLUE}=== Management Commands ===${NC}"
echo "• Check status: bash scripts/status.sh"
echo "• View logs: cd [service] && docker-compose logs -f"
echo "• Stop all: bash scripts/stop-all.sh"
echo "• Start all: bash scripts/start-all.sh"
echo ""
echo -e "${YELLOW}Note: Change default passwords in .env files for production use!${NC}"
