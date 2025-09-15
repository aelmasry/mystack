# MyStack - Complete VPS Docker Environment

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Docker](https://img.shields.io/badge/docker-compose-blue.svg)
![Platform](https://img.shields.io/badge/platform-linux-green.svg)

A comprehensive, production-ready Docker-based environment for Ubuntu 24 VPS, featuring workflow automation, AI services, reverse proxy, and monitoring.

## 🚀 Features

- **🔄 Workflow Automation**: n8n with PostgreSQL and Redis
- **🤖 AI/LLM Services**: Ollama + OpenWebUI for local AI hosting
- **🌐 Reverse Proxy**: Nginx Proxy Manager with automatic HTTPS/SSL
- **📊 Monitoring**: Portainer CE and Dozzle for container management
- **🗂️ Website Hosting**: Static website and demo environments
- **🔐 Security**: UFW firewall, HTTPS everywhere, automated updates
- **💾 Backup System**: Automated backups with configurable retention

## 📋 Prerequisites

- Ubuntu 24.04 VPS with root access
- Domain name with DNS control (Cloudflare, Hostinger, etc.)
- Minimum 4GB RAM, 20GB storage
- Docker and Docker Compose (auto-installed)

## ⚡ Quick Start

### 1. Clone and Setup
```bash
# Clone to /opt/mystack
sudo git clone https://github.com/aelmasry/mystack.git /opt/mystack
cd /opt/mystack

# Make scripts executable
sudo chmod +x scripts/*.sh

# Initialize server (installs Docker, configures firewall)
sudo bash scripts/init-server.sh
```

### 2. Configure Domains
Update your DNS provider with these A records pointing to your VPS IP:
```
proxy.yourdomain.com    → Your VPS IP
n8n.yourdomain.com      → Your VPS IP  
ollama.yourdomain.com   → Your VPS IP
portainer.yourdomain.com → Your VPS IP
dozzle.yourdomain.com   → Your VPS IP
```

### 3. Deploy Services
```bash
# Deploy all services in correct order
sudo bash scripts/deploy-all.sh

# Check status
sudo bash scripts/status.sh
```

### 4. Access Services
- **Nginx Proxy Manager**: `http://your-vps-ip:81` (admin@example.com / changeme)
- **n8n**: `https://n8n.yourdomain.com`
- **OpenWebUI**: `https://ollama.yourdomain.com` 
- **Portainer**: `https://portainer.yourdomain.com`
- **Dozzle**: `https://dozzle.yourdomain.com`

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Cloudflare    │────│  Nginx Proxy     │────│   Docker Apps   │
│  (DNS + CDN)    │    │    Manager       │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                          │
                              ├── n8n Stack ────────────┤
                              ├── Ollama + WebUI ───────┤  
                              ├── Static Websites ──────┤
                              └── Monitoring ───────────┘
```

### Network Architecture
- All services run on `mystack-network` Docker network
- Nginx Proxy Manager handles SSL termination and routing
- Internal communication via container names
- External access via configured domains

## 📁 Project Structure

```
/opt/mystack/
├── 🔧 proxy/              # Nginx Proxy Manager + SSL
├── ⚡ n8n/                # Workflow automation stack
├── 🤖 ollama/             # AI/LLM services  
├── 🌐 websites/           # Static website hosting
├── 📊 monitoring/         # Container management tools
├── 💾 backups/            # Automated backup storage
├── 🔧 scripts/            # Management automation
├── 📝 shared/             # Shared configurations
└── 📚 docs/               # Documentation
```

## 🔧 Services Overview

### Core Services

| Service | Port | Purpose | Dependencies |
|---------|------|---------|--------------|
| **Nginx Proxy Manager** | 80, 443, 81 | Reverse proxy + SSL | None |
| **n8n** | 5678 | Workflow automation | PostgreSQL, Redis |
| **PostgreSQL** | 5432 | n8n database | None |
| **Redis** | 6379 | n8n cache/queue | None |
| **Ollama** | 11434 | LLM inference | None |
| **OpenWebUI** | 8080 | AI web interface | Ollama |
| **Portainer** | 9000 | Docker management | None |
| **Dozzle** | 8888 | Log viewer | None |

### Optional Services
- **Static Websites**: Demo and portfolio sites
- **Monitoring**: Grafana + Prometheus (disabled by default)

## 🛠️ Management Scripts

```bash
# Core Operations
scripts/init-server.sh          # Initial VPS setup
scripts/deploy-all.sh           # Deploy all services
scripts/status.sh               # Check all services status

# Service Management  
scripts/management/start-all.sh # Start all services
scripts/management/stop-all.sh  # Stop all services

# Backup & Maintenance
scripts/backup.sh               # Create backup
scripts/restore.sh              # Restore from backup
scripts/cleanup.sh              # Clean old data

# Monitoring
scripts/health-check.sh         # Health check all services
scripts/monitor.sh              # Resource monitoring
```

## 🔐 Security Features

- **Firewall**: UFW configured (ports 22, 80, 443, 81)
- **HTTPS**: Automatic SSL certificates via Let's Encrypt
- **Updates**: Unattended security updates enabled
- **Network**: Isolated Docker networks
- **Access**: Service-specific authentication
- **Backups**: Encrypted backup storage

## 💾 Backup Strategy

### What's Backed Up
- ✅ PostgreSQL databases (n8n workflows)
- ✅ Redis data (sessions, cache)
- ✅ n8n configuration and workflows
- ✅ Website content and configurations
- ✅ Proxy configurations and certificates

### What's Excluded
- ❌ Large LLM models (Ollama)
- ❌ Docker images and containers
- ❌ System logs
- ❌ Temporary files

### Backup Management
```bash
# Manual backup
sudo bash scripts/backup.sh

# Restore from backup
sudo bash scripts/restore.sh backup_YYYY-MM-DD_HH-MM-SS.tar.gz

# Automated daily backups (via cron)
# Retention: 30 days (configurable)
```

## 🔧 Configuration

### Environment Variables
Each service uses environment variables for configuration:

```bash
# n8n Configuration
N8N_HOST=n8n.yourdomain.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.yourdomain.com
GENERIC_TIMEZONE=Asia/Dubai

# Database Configuration  
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_DATABASE=n8n

# Authentication
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=changeme
```

### SSL/HTTPS Setup
1. **Automatic**: Let's Encrypt via Nginx Proxy Manager UI
2. **Manual**: Upload custom certificates
3. **Cloudflare**: Origin certificates for Cloudflare users

## 📊 Monitoring & Maintenance

### Health Monitoring
```bash
# Check all services
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Service-specific logs
docker-compose -f n8n/docker-compose.yml logs -f

# Resource usage
docker stats
```

### Regular Maintenance
- **Daily**: Automated backups
- **Weekly**: Security updates
- **Monthly**: Log cleanup and optimization
- **Quarterly**: Full system review

## 🚨 Troubleshooting

### Common Issues

#### Services Not Starting
```bash
# Check Docker daemon
sudo systemctl status docker

# Check network
docker network ls | grep mystack

# Recreate network
docker network create mystack-network
```

#### SSL/HTTPS Issues
```bash
# Check Nginx Proxy Manager logs
docker logs nginx-proxy-manager

# Test certificate
openssl s_client -connect yourdomain.com:443

# Renew certificates manually
# Via Nginx Proxy Manager UI: SSL Certificates > Renew
```

#### Database Connection Issues
```bash
# Check PostgreSQL health
docker exec n8n-postgres pg_isready -U postgres

# Check Redis connection
docker exec n8n-redis redis-cli ping
```

### Log Locations
- **Application Logs**: Available via Dozzle UI
- **Nginx Logs**: `/opt/mystack/proxy/data/logs/`
- **Backup Logs**: `/opt/mystack/backups/logs/`

## 🔄 Updates

### Application Updates
```bash
# Update all Docker images
cd /opt/mystack
docker-compose -f proxy/docker-compose.yml pull
docker-compose -f n8n/docker-compose.yml pull
docker-compose -f ollama/docker-compose.yml pull
docker-compose -f monitoring/docker-compose.yml pull

# Restart with new images
bash scripts/deploy-all.sh
```

### System Updates
```bash
# Update Ubuntu packages
sudo apt update && sudo apt upgrade -y

# Update Docker
sudo apt install docker-ce docker-ce-cli containerd.io
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:

1. **Check Logs**: Use Dozzle or `docker logs [container-name]`
2. **Verify DNS**: Ensure domains point to your VPS
3. **Check Firewall**: Verify UFW rules with `sudo ufw status`
4. **GitHub Issues**: Open an issue for bugs or feature requests

## 🙏 Acknowledgments

- [n8n](https://n8n.io/) - Workflow automation platform
- [Ollama](https://ollama.ai/) - Local LLM hosting
- [OpenWebUI](https://openwebui.com/) - AI web interface
- [Nginx Proxy Manager](https://nginxproxymanager.com/) - Reverse proxy management
- [Portainer](https://www.portainer.io/) - Docker management
- [Dozzle](https://dozzle.dev/) - Docker log viewer

---

**⭐ If this project helps you, please consider giving it a star!**