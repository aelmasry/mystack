#!/bin/bash
echo "🧠 Installing Ollama Models..."

# Check if Ollama is running
if ! docker ps | grep -q ollama-server; then
    echo "❌ Ollama server is not running!"
    echo "Start it with: cd /opt/mystack/ollama && docker compose up -d"
    exit 1
fi

echo "📥 Available models to install:"
echo "1. llama3.2:1b (Smallest - ~1GB)"
echo "2. llama3.2:3b (Small - ~2GB)" 
echo "3. llama3.1:8b (Medium - ~4.7GB)"
echo "4. codellama:7b (Code - ~3.8GB)"

read -p "Choose model number (1-4): " choice

case $choice in
    1)
        echo "Installing Llama 3.2 1B..."
        docker exec ollama-server ollama pull llama3.2:1b
        ;;
    2)
        echo "Installing Llama 3.2 3B..."
        docker exec ollama-server ollama pull llama3.2:3b
        ;;
    3)
        echo "Installing Llama 3.1 8B..."
        docker exec ollama-server ollama pull llama3.1:8b
        ;;
    4)
        echo "Installing Code Llama 7B..."
        docker exec ollama-server ollama pull codellama:7b
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo "✅ Model installation completed!"
echo "📋 Installed models:"
docker exec ollama-server ollama list
