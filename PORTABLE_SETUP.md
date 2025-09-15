# MyStack Portable Setup

This setup is designed to be completely portable - you can clone this entire folder to any machine and run it with minimal configuration.

## 🚀 Quick Start (Portable)

### Prerequisites
- Docker and Docker Compose installed
- Ports 80, 81, 443 available (or modify docker-compose.yml files)

### 1. Clone and Run
```bash
# Clone this folder to your machine
git clone <your-repo> mystack
cd mystack

# Make scripts executable
chmod +x scripts/*.sh

# Deploy all services
sudo bash scripts/deploy-all.sh
```

### 2. Configure Environment (Optional)
```bash
# Copy and customize environment files
cp shared/configs/global.env.example proxy/.env
cp shared/configs/global.env.example n8n/.env
cp shared/configs/global.env.example ollama/.env

# Edit the .env files with your settings
nano proxy/.env
nano n8n/.env
nano ollama/.env
```

### 3. Access Services
- **Nginx Proxy Manager**: http://localhost:81
- **n8n**: http://localhost:5678 (or via proxy)
- **OpenWebUI**: http://localhost:3000 (or via proxy)
- **Portainer**: http://localhost:9000 (or via proxy)
- **Dozzle**: http://localhost:8080 (or via proxy)
- **Demo Websites**: http://localhost (or via proxy)

## 📁 Project Structure

Each service is completely self-contained:

```
mystack/
├── proxy/                    # Nginx Proxy Manager
│   ├── docker-compose.yml   # Service definition
│   ├── .env                 # Environment variables
│   ├── data/                # Proxy data (SQLite, configs)
│   └── letsencrypt/         # SSL certificates
│
├── n8n/                     # n8n Workflow Automation
│   ├── docker-compose.yml   # Service definition
│   ├── .env                 # Environment variables
│   ├── data/                # n8n workflows and configs
│   ├── database/            # PostgreSQL data
│   └── redis-data/          # Redis data
│
├── ollama/                  # Ollama + OpenWebUI
│   ├── docker-compose.yml   # Service definition
│   ├── .env                 # Environment variables
│   ├── models/              # AI models (excluded from git)
│   ├── webui-data/          # OpenWebUI data
│   └── config/              # Ollama configuration
│
├── websites/                # Static Websites
│   ├── docker-compose.yml   # Service definition
│   ├── static-files/        # Main website files
│   ├── demo/                # Demo website
│   └── nginx.conf/          # Nginx configuration
│
├── monitoring/              # Portainer + Dozzle
│   ├── docker-compose.yml   # Service definition
│   └── portainer-data/      # Portainer data
│
└── scripts/                 # Management scripts
    ├── deploy-all.sh        # Deploy all services
    ├── status.sh            # Check service status
    ├── backup.sh            # Backup data
    └── restore.sh           # Restore data
```

## 🔧 Individual Service Management

### Start a single service:
```bash
cd proxy
docker-compose up -d
```

### Stop a single service:
```bash
cd proxy
docker-compose down
```

### View logs:
```bash
cd proxy
docker-compose logs -f
```

### Update a service:
```bash
cd proxy
docker-compose pull
docker-compose up -d
```

## 💾 Data Persistence

All data is stored locally within each service directory:

- **n8n**: Workflows, credentials, and settings in `n8n/data/`
- **PostgreSQL**: Database files in `n8n/database/`
- **Redis**: Cache data in `n8n/redis-data/`
- **Ollama**: AI models in `ollama/models/`
- **OpenWebUI**: User data in `ollama/webui-data/`
- **Proxy**: SSL certificates and configs in `proxy/data/` and `proxy/letsencrypt/`
- **Portainer**: Container management data in `monitoring/portainer-data/`

## 🌐 Network Configuration

All services use the `mystack-network` Docker network for internal communication. External access is handled by:

1. **Direct port access** (for development)
2. **Nginx Proxy Manager** (for production with SSL)

## 🔒 Security Notes

- Environment files (`.env`) contain sensitive data and are excluded from git
- SSL certificates are generated automatically and stored locally
- All services run in isolated Docker networks
- Default passwords should be changed in production

## 📦 Backup and Restore

### Create backup:
```bash
sudo bash scripts/backup.sh manual
```

### Restore backup:
```bash
sudo bash scripts/restore.sh /path/to/backup.tar.gz
```

## 🚀 Production Deployment

For production use:

1. **Configure DNS**: Point your domain to the server
2. **Set up SSL**: Use Nginx Proxy Manager to get Let's Encrypt certificates
3. **Change passwords**: Update all default passwords in `.env` files
4. **Configure firewall**: Only open necessary ports (80, 443, 81)
5. **Set up monitoring**: Use Portainer and Dozzle for container management

## 🔄 Updates

To update the entire stack:

```bash
# Pull latest images
for service in proxy n8n ollama websites monitoring; do
    cd $service
    docker-compose pull
    docker-compose up -d
    cd ..
done
```

## 🐛 Troubleshooting

### Check service status:
```bash
bash scripts/status.sh
```

### View service logs:
```bash
cd [service-name]
docker-compose logs -f
```

### Restart all services:
```bash
sudo bash scripts/deploy-all.sh
```

### Clean up Docker:
```bash
docker system prune -f
docker volume prune -f
```

## 📋 Requirements

- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 10GB minimum, 50GB recommended for models
- **OS**: Linux (Ubuntu 20.04+ recommended), macOS, or Windows with WSL2

This setup is designed to be completely self-contained and portable. You can clone it to any machine and have a fully functional stack running in minutes!
