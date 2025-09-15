#!/bin/bash

echo "🤖 Automated Proxy Host Configuration"
echo "===================================="

PUBLIC_IP="72.60.193.101"
PROXY_API="http://localhost:81/api"

# Function to create proxy host via API (requires authentication)
create_proxy_host() {
    local domain_names="$1"
    local forward_host="$2"
    local forward_port="$3"
    local description="$4"
    
    echo "Creating proxy host for: $domain_names"
    
    # Note: This requires API authentication which is complex to automate
    # Manual setup through UI is recommended for now
}

echo "ℹ️  Automated API configuration is complex due to authentication."
echo "Please follow the manual setup guide above."
echo ""
echo "🔧 Quick verification commands:"
echo ""
echo "# Check if services are running"
echo "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
echo ""
echo "# Test internal connectivity"
echo "docker exec reverse-proxy-manager ping n8n-app -c 1"
echo "docker exec reverse-proxy-manager ping ollama-webui -c 1"
echo "docker exec reverse-proxy-manager ping websites-nginx -c 1"
echo ""
echo "# Check service health"
echo "curl http://localhost:5678/healthz  # n8n"
echo "curl http://localhost:3000/health   # Ollama WebUI"
echo "curl http://localhost:11434/api/version  # Ollama API"
