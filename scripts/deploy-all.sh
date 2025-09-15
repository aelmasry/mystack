#!/bin/bash

# MyStack Deploy All Services Script
# This script deploys all services in the correct order
# Run with: sudo bash /opt/mystack/scripts/deploy-all.sh

set -e  # Exit on any error

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

# Check if Docker is running
if ! systemctl is-active --quiet docker; then
    error "Docker is not running. Please start Docker first."
    exit 1
fi

log "Starting MyStack deployment..."

# Create Docker network if it doesn't exist
log "Creating Docker network..."
docker network create mystack-network 2>/dev/null || log "Network mystack-network already exists"

# Function to deploy a service
deploy_service() {
    local service_name=$1
    local compose_file=$2
    
    if [[ -f "$compose_file" ]]; then
        log "Deploying $service_name..."
        cd "$(dirname "$compose_file")"
        docker-compose down 2>/dev/null || true
        docker-compose pull
        docker-compose up -d
        log "$service_name deployed successfully"
    else
        warn "$service_name compose file not found: $compose_file"
    fi
}

# Function to wait for service to be healthy
wait_for_service() {
    local service_name=$1
    local max_attempts=30
    local attempt=1
    
    log "Waiting for $service_name to be ready..."
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker-compose ps | grep -q "Up (healthy)"; then
            log "$service_name is ready"
            return 0
        elif docker-compose ps | grep -q "Up"; then
            log "$service_name is running"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    warn "$service_name may not be fully ready yet"
    return 1
}

# Deploy services in correct order
log "Deploying services in order..."

# 1. Deploy reverse proxy first (Nginx Proxy Manager)
deploy_service "Nginx Proxy Manager" "/opt/mystack/proxy/docker-compose.yml"
wait_for_service "Nginx Proxy Manager"

# 2. Deploy monitoring services (Portainer, Dozzle)
deploy_service "Monitoring (Portainer + Dozzle)" "/opt/mystack/monitoring/docker-compose.yml"
wait_for_service "Monitoring"

# 3. Deploy n8n stack (Postgres, Redis, n8n)
deploy_service "n8n Stack" "/opt/mystack/n8n/docker-compose.yml"
wait_for_service "n8n Stack"

# 4. Deploy Ollama + OpenWebUI
deploy_service "Ollama + OpenWebUI" "/opt/mystack/ollama/docker-compose.yml"
wait_for_service "Ollama + OpenWebUI"

# 5. Deploy websites
deploy_service "Websites" "/opt/mystack/websites/docker-compose.yml"
wait_for_service "Websites"

# Check all services status
log "Checking all services status..."
echo ""
echo "=== Service Status ==="

services=(
    "proxy:Nginx Proxy Manager"
    "monitoring:Portainer + Dozzle"
    "n8n:n8n Stack"
    "ollama:Ollama + OpenWebUI"
    "websites:Websites"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r service_dir service_name <<< "$service_info"
    compose_file="/opt/mystack/$service_dir/docker-compose.yml"
    
    if [[ -f "$compose_file" ]]; then
        cd "$(dirname "$compose_file")"
        echo -e "${BLUE}$service_name:${NC}"
        docker-compose ps
        echo ""
    fi
done

# Show network information
log "Docker network information:"
docker network ls | grep mystack
echo ""

# Show running containers
log "All running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Show service URLs
log "Service URLs (configure DNS to point to this server):"
echo ""
echo -e "${BLUE}Management Interfaces:${NC}"
echo "- Nginx Proxy Manager: http://$(curl -s ifconfig.me):81"
echo "- Portainer: https://portainer.yourdomain.com"
echo "- Dozzle: https://dozzle.yourdomain.com"
echo ""
echo -e "${BLUE}Application Services:${NC}"
echo "- n8n: https://n8n.yourdomain.com"
echo "- OpenWebUI: https://ollama.yourdomain.com"
echo "- Demo Websites: https://demo.yourdomain.com"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Configure your DNS provider with the following subdomains:"
echo "   - proxy.yourdomain.com → Nginx Proxy Manager"
echo "   - n8n.yourdomain.com → n8n workflow automation"
echo "   - ollama.yourdomain.com → OpenWebUI"
echo "   - portainer.yourdomain.com → Portainer"
echo "   - dozzle.yourdomain.com → Dozzle logs"
echo "   - demo.yourdomain.com → Demo websites"
echo ""
echo "2. Access Nginx Proxy Manager and configure SSL certificates"
echo "3. Set up proxy hosts for each service"
echo "4. Test all services"
echo ""

# Create a simple health check script
cat > /opt/mystack/scripts/health-check.sh << 'EOF'
#!/bin/bash
# Simple health check for all services

echo "=== MyStack Health Check ==="
echo "Date: $(date)"
echo ""

# Check Docker
if systemctl is-active --quiet docker; then
    echo "✓ Docker is running"
else
    echo "✗ Docker is not running"
fi

# Check network
if docker network ls | grep -q mystack-network; then
    echo "✓ mystack-network exists"
else
    echo "✗ mystack-network missing"
fi

# Check services
services=("proxy" "monitoring" "n8n" "ollama" "websites")
for service in "${services[@]}"; do
    if [[ -f "/opt/mystack/$service/docker-compose.yml" ]]; then
        cd "/opt/mystack/$service"
        if docker-compose ps | grep -q "Up"; then
            echo "✓ $service is running"
        else
            echo "✗ $service is not running"
        fi
    else
        echo "? $service compose file not found"
    fi
done

echo ""
echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
EOF

chmod +x /opt/mystack/scripts/health-check.sh

log "Deployment completed successfully!"
log "Run '/opt/mystack/scripts/health-check.sh' to verify all services"
