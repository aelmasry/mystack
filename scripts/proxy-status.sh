#!/bin/bash
echo "🌐 Nginx Proxy Manager Status"
echo "=============================="

# Check if container is running
if docker ps | grep -q nginx-proxy-manager; then
    echo "✅ Nginx Proxy Manager: Running"
    
    # Get container stats
    echo ""
    echo "📊 Container Stats:"
    docker stats nginx-proxy-manager --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    
    echo ""
    echo "🔗 Access URLs:"
    echo "   Admin Panel: http://$(curl -s ifconfig.me):81"
    echo "   HTTP: http://$(curl -s ifconfig.me):80"
    echo "   HTTPS: https://$(curl -s ifconfig.me):443"
    echo "   Default Login: admin@example.com / changeme"
    
    echo ""
    echo "📋 Active Proxy Hosts:"
    docker exec nginx-proxy-manager ls -la /data/nginx/proxy_host/ 2>/dev/null | wc -l | xargs echo "Total configurations:"
    
else
    echo "❌ Nginx Proxy Manager: Not Running"
    echo ""
    echo "🔧 To start: docker compose -f /opt/mystack/nginx-proxy/docker-compose.yml up -d"
fi

echo ""
echo "🔍 Open Ports:"
netstat -tlnp | grep -E ':80|:443|:81'

echo ""
echo "📝 Recent Logs:"
docker logs nginx-proxy-manager --tail 10 2>/dev/null || echo "No logs available"
