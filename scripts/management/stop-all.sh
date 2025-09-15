#!/bin/bash
echo "⏹️ Stopping All Services..."

cd /opt/mystack/reverse-proxy && docker compose down
cd /opt/mystack/n8n && docker compose down
cd /opt/mystack/ollama && docker compose down
cd /opt/mystack/websites && docker compose down

echo "✅ All services stopped!"
