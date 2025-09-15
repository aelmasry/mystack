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
