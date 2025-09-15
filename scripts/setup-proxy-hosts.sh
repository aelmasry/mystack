#!/bin/bash

# Nginx Proxy Manager Setup Script
# This script helps you configure proxy hosts for all services

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Nginx Proxy Manager Setup Helper               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "🌐 **Step 1: Access Nginx Proxy Manager**"
echo "   URL: http://72.60.193.101:81"
echo "   Default Login: admin@example.com / changeme"
echo ""

echo "📝 **Step 2: Configure Cloudflare DNS Records**"
echo "   Add these A records in Cloudflare:"
echo "   • n8n.alisalem.me → 72.60.193.101"
echo "   • ollama.alisalem.me → 72.60.193.101"
echo "   • demo.alisalem.me → 72.60.193.101"
echo "   • portainer.alisalem.me → 72.60.193.101"
echo "   • dozzle.alisalem.me → 72.60.193.101"
echo ""

echo "🔧 **Step 3: Create Proxy Hosts**"
echo ""
echo "   **For n8n (n8n.alisalem.me):**"
echo "   • Domain: n8n.alisalem.me"
echo "   • Forward to: n8n-app:5678"
echo "   • Enable SSL with Let's Encrypt"
echo ""

echo "   **For OpenWebUI (ollama.alisalem.me):**"
echo "   • Domain: ollama.alisalem.me"
echo "   • Forward to: ollama-webui:8080"
echo "   • Enable SSL with Let's Encrypt"
echo ""

echo "   **For Demo Websites (demo.alisalem.me):**"
echo "   • Domain: demo.alisalem.me"
echo "   • Forward to: nginx-websites:80"
echo "   • Enable SSL with Let's Encrypt"
echo ""

echo "   **For Portainer (portainer.alisalem.me):**"
echo "   • Domain: portainer.alisalem.me"
echo "   • Forward to: portainer:9000"
echo "   • Enable SSL with Let's Encrypt"
echo ""

echo "   **For Dozzle (dozzle.alisalem.me):**"
echo "   • Domain: dozzle.alisalem.me"
echo "   • Forward to: dozzle:8080"
echo "   • Enable SSL with Let's Encrypt"
echo ""

echo "🔄 **Step 4: Restart n8n with HTTPS Configuration**"
echo "   The n8n configuration has been updated for HTTPS"
echo "   Run: cd /opt/mystack/n8n && docker-compose restart n8n"
echo ""

echo "🧪 **Step 5: Test Your Setup**"
echo "   After DNS propagation (2-5 minutes), test:"
echo "   • https://n8n.alisalem.me"
echo "   • https://ollama.alisalem.me"
echo "   • https://demo.alisalem.me"
echo ""

echo "📋 **Quick Commands:**"
echo "   Check DNS: nslookup n8n.alisalem.me"
echo "   Check containers: docker ps"
echo "   Check n8n logs: docker logs n8n-app"
echo ""

echo "✅ **Expected Results:**"
echo "   All services accessible via HTTPS with valid SSL certificates"
echo "   No security warnings in browsers"
echo "   Green lock icons for all subdomains"
echo ""

read -p "Press Enter to continue with n8n restart..."
echo ""

echo "🔄 Restarting n8n with HTTPS configuration..."
cd /opt/mystack/n8n && docker-compose restart n8n

echo ""
echo "✅ n8n restarted! Now configure the proxy hosts in Nginx Proxy Manager."
echo "   Access: http://72.60.193.101:81"
echo ""
