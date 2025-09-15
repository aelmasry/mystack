#!/bin/bash
echo "📊 MyStack Status Overview"
echo "=========================="

echo ""
echo "🔄 Service Status:"
services=("reverse-proxy-manager" "n8n-postgres" "n8n-redis" "n8n-app" "ollama-server" "ollama-webui" "websites-nginx")

for service in "${services[@]}"; do
    if docker ps --filter "name=$service" --format "{{.Names}}" | grep -q "$service"; then
        status="✅ Running"
        uptime=$(docker ps --filter "name=$service" --format "{{.Status}}")
        echo "  $service: $status ($uptime)"
    else
        echo "  $service: ❌ Stopped"
    fi
done

echo ""
echo "📈 Resource Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -10

echo ""
echo "🌐 Access URLs:"
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
echo "  Proxy Manager: http://$PUBLIC_IP:81"
echo "  n8n: http://$PUBLIC_IP:5678"  
echo "  Ollama WebUI: http://$PUBLIC_IP:3000"
echo "  Demo Website: http://$PUBLIC_IP:8080"

echo ""
echo "📁 Data Usage:"
du -sh /opt/mystack/*/data 2>/dev/null | head -5
