#!/bin/bash

# MyStack Status Check Script
# This script provides a comprehensive status overview of all services
# Run with: bash /opt/mystack/scripts/status.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Header
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    MyStack Status Dashboard                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# System Information
echo -e "${BLUE}=== System Information ===${NC}"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory Usage: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}')"
echo ""

# Docker Status
echo -e "${BLUE}=== Docker Status ===${NC}"
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✓ Docker is running${NC}"
    echo "Docker Version: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
    echo "Docker Compose Version: $(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)"
else
    echo -e "${RED}✗ Docker is not running${NC}"
fi
echo ""

# Network Status
echo -e "${BLUE}=== Network Status ===${NC}"
if docker network ls | grep -q mystack-network; then
    echo -e "${GREEN}✓ mystack-network exists${NC}"
    echo "Network Details:"
    docker network inspect mystack-network --format '{{.IPAM.Config}}' 2>/dev/null || echo "  Unable to get network details"
else
    echo -e "${RED}✗ mystack-network missing${NC}"
fi
echo ""

# Service Status
echo -e "${BLUE}=== Service Status ===${NC}"
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
        echo -e "${CYAN}$service_name:${NC}"
        
        # Check if any containers are running
        if docker-compose ps | grep -q "Up"; then
            echo -e "  ${GREEN}Status: Running${NC}"
            
            # Show container details
            docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | while read -r line; do
                echo "  $line"
            done
        else
            echo -e "  ${RED}Status: Not Running${NC}"
        fi
        echo ""
    else
        echo -e "${YELLOW}$service_name: Compose file not found${NC}"
    fi
done

# Container Overview
echo -e "${BLUE}=== All Containers Overview ===${NC}"
if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "NAMES"; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "No containers are currently running"
fi
echo ""

# Resource Usage
echo -e "${BLUE}=== Resource Usage ===${NC}"
if command -v docker stats &> /dev/null; then
    echo "Container Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null || echo "Unable to get resource usage"
fi
echo ""

# Backup Status
echo -e "${BLUE}=== Backup Status ===${NC}"
backup_dirs=("/opt/mystack/backups/daily" "/opt/mystack/backups/weekly" "/opt/mystack/backups/manual")
for backup_dir in "${backup_dirs[@]}"; do
    if [[ -d "$backup_dir" ]]; then
        backup_count=$(find "$backup_dir" -name "*.tar.gz" 2>/dev/null | wc -l)
        if [[ $backup_count -gt 0 ]]; then
            latest_backup=$(find "$backup_dir" -name "*.tar.gz" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
            if [[ -n "$latest_backup" ]]; then
                backup_size=$(du -h "$latest_backup" | cut -f1)
                backup_date=$(stat -c %y "$latest_backup" | cut -d' ' -f1)
                echo -e "${GREEN}✓ $(basename "$backup_dir"): $backup_count backups (latest: $backup_date, $backup_size)${NC}"
            fi
        else
            echo -e "${YELLOW}? $(basename "$backup_dir"): No backups found${NC}"
        fi
    else
        echo -e "${RED}✗ $(basename "$backup_dir"): Directory not found${NC}"
    fi
done
echo ""

# SSL Certificate Status
echo -e "${BLUE}=== SSL Certificate Status ===${NC}"
if [[ -d "/opt/mystack/proxy/data/letsencrypt" ]]; then
    cert_count=$(find "/opt/mystack/proxy/data/letsencrypt" -name "*.pem" 2>/dev/null | wc -l)
    if [[ $cert_count -gt 0 ]]; then
        echo -e "${GREEN}✓ $cert_count SSL certificates found${NC}"
        
        # Check certificate expiry (if openssl is available)
        if command -v openssl &> /dev/null; then
            find "/opt/mystack/proxy/data/letsencrypt" -name "*.pem" 2>/dev/null | head -3 | while read -r cert_file; do
                if [[ -f "$cert_file" ]]; then
                    expiry=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
                    if [[ -n "$expiry" ]]; then
                        echo "  $(basename "$cert_file"): Expires $expiry"
                    fi
                fi
            done
        fi
    else
        echo -e "${YELLOW}? No SSL certificates found${NC}"
    fi
else
    echo -e "${RED}✗ SSL certificate directory not found${NC}"
fi
echo ""

# Service URLs
echo -e "${BLUE}=== Service URLs ===${NC}"
echo "Management Interfaces:"
echo "  • Nginx Proxy Manager: http://$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP"):81"
echo "  • Portainer: https://portainer.yourdomain.com"
echo "  • Dozzle: https://dozzle.yourdomain.com"
echo ""
echo "Application Services:"
echo "  • n8n: https://n8n.yourdomain.com"
echo "  • OpenWebUI: https://ollama.yourdomain.com"
echo "  • Demo Websites: https://demo.yourdomain.com"
echo ""

# Recommendations
echo -e "${BLUE}=== Recommendations ===${NC}"
if ! systemctl is-active --quiet docker; then
    echo -e "${RED}• Start Docker service${NC}"
fi

if ! docker network ls | grep -q mystack-network; then
    echo -e "${RED}• Create mystack-network${NC}"
fi

# Check for services not running
for service_info in "${services[@]}"; do
    IFS=':' read -r service_dir service_name <<< "$service_info"
    compose_file="/opt/mystack/$service_dir/docker-compose.yml"
    
    if [[ -f "$compose_file" ]]; then
        cd "$(dirname "$compose_file")"
        if ! docker-compose ps | grep -q "Up"; then
            echo -e "${YELLOW}• Start $service_name service${NC}"
        fi
    fi
done

# Check for recent backups
recent_backup_found=false
for backup_dir in "${backup_dirs[@]}"; do
    if [[ -d "$backup_dir" ]]; then
        if find "$backup_dir" -name "*.tar.gz" -mtime -1 2>/dev/null | grep -q .; then
            recent_backup_found=true
            break
        fi
    fi
done

if [[ "$recent_backup_found" == false ]]; then
    echo -e "${YELLOW}• Run a backup (no recent backups found)${NC}"
fi

echo ""
echo -e "${CYAN}Status check completed at $(date)${NC}"