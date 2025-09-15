#!/bin/bash
echo "🚀 Starting All Services..."

# Create network if doesn't exist
docker network create mystack-network 2>/dev/null || true

# Start services in order
echo "📡 Starting Reverse Proxy..."
cd /opt/mystack/reverse-proxy && docker compose up -d

echo "🤖 Starting n8n Stack..."
cd /opt/mystack/n8n && docker compose up -d

echo "🧠 Starting Ollama Stack..."
cd /opt/mystack/ollama && docker compose up -d

echo "🌐 Starting Websites..."
cd /opt/mystack/websites && docker compose up -d

echo "✅ All services started!"
/opt/mystack/scripts/monitoring/status-all.sh
