# 🚀 Clone and Run MyStack Anywhere

This is a **completely portable** Docker-based stack that you can clone to any machine and run immediately.

## ✅ What's Included

### 🐳 **Services (All Self-Contained)**
- **Nginx Proxy Manager** - SSL/HTTPS management
- **n8n** - Workflow automation with PostgreSQL + Redis
- **Ollama + OpenWebUI** - Local AI models with web interface
- **Portainer + Dozzle** - Container management and log viewing
- **Static Websites** - Demo sites with nginx

### 📁 **Portable Structure**
```
mystack/
├── proxy/              # Nginx Proxy Manager + data
├── n8n/                # n8n + PostgreSQL + Redis + data
├── ollama/             # Ollama + OpenWebUI + data
├── websites/           # Static sites + nginx config
├── monitoring/         # Portainer + Dozzle + data
├── scripts/            # Management scripts
└── shared/             # Shared configurations
```

## 🎯 **Quick Start (3 Commands)**

```bash
# 1. Clone this folder
git clone <your-repo> mystack
cd mystack

# 2. Make scripts executable
chmod +x scripts/*.sh

# 3. Deploy everything
sudo bash scripts/setup-portable.sh
```

## 🌐 **Access Your Services**

After deployment, access your services at:

- **Nginx Proxy Manager**: http://localhost:81
- **n8n Workflows**: http://localhost:5678
- **OpenWebUI (AI)**: http://localhost:3000
- **Portainer**: http://localhost:9000
- **Dozzle (Logs)**: http://localhost:8080
- **Demo Websites**: http://localhost

## 🔧 **Management Commands**

```bash
# Check status of all services
bash scripts/status.sh

# Start all services
bash scripts/start-all.sh

# Stop all services
bash scripts/stop-all.sh

# Create backup
sudo bash scripts/backup.sh manual

# Restore backup
sudo bash scripts/restore.sh /path/to/backup.tar.gz
```

## 💾 **Data Persistence**

All data is stored locally within each service folder:

- **n8n data**: `n8n/data/` (workflows, credentials)
- **Database**: `n8n/database/` (PostgreSQL data)
- **Redis**: `n8n/redis-data/` (cache data)
- **AI Models**: `ollama/models/` (Ollama models)
- **WebUI Data**: `ollama/webui-data/` (user data)
- **Proxy Data**: `proxy/data/` (SSL certificates, configs)
- **Portainer**: `monitoring/portainer-data/` (container management)

## 🔒 **Security & Production**

### For Development:
- Default passwords are used
- Services accessible via localhost
- No SSL required

### For Production:
1. **Change passwords** in `.env` files
2. **Configure DNS** to point to your server
3. **Set up SSL** via Nginx Proxy Manager
4. **Configure firewall** (ports 80, 443, 81)

## 📦 **Individual Service Management**

```bash
# Start a single service
cd proxy
docker-compose up -d

# Stop a single service
cd proxy
docker-compose down

# View logs
cd proxy
docker-compose logs -f

# Update a service
cd proxy
docker-compose pull && docker-compose up -d
```

## 🐛 **Troubleshooting**

```bash
# Check what's running
docker ps

# Check service logs
cd [service-name]
docker-compose logs -f

# Restart everything
sudo bash scripts/deploy-all.sh

# Clean up Docker
docker system prune -f
```

## 📋 **Requirements**

- **Docker** 20.10+
- **Docker Compose** 2.0+
- **2GB RAM** minimum (4GB recommended)
- **10GB storage** minimum (50GB for AI models)
- **Linux/macOS/Windows** with WSL2

## 🎉 **That's It!**

This setup is designed to be **completely self-contained**. You can:

1. **Clone** this folder to any machine
2. **Run** the setup script
3. **Access** all services immediately
4. **Backup** the entire folder to preserve everything
5. **Move** to any other machine and run again

No external dependencies, no complex configuration - just clone and run! 🚀
