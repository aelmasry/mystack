# MyStack Complete Setup Guide

This guide will walk you through setting up your VPS with the MyStack Docker environment.

## Prerequisites

- Ubuntu 24.04 VPS with root access
- Domain name with DNS management access
- At least 2GB RAM and 20GB storage
- Basic knowledge of Linux commands

## Quick Start (Recommended)

### 1. Initial Server Setup

```bash
# Run the initialization script
sudo bash /opt/mystack/scripts/init-server.sh
```

This script will:
- Update system packages
- Install Docker and Docker Compose
- Configure firewall (UFW)
- Set up fail2ban for security
- Configure automatic security updates
- Create folder structure
- Set up backup automation

### 2. Quick Configuration

```bash
# Run the quick setup script
sudo bash /opt/mystack/scripts/quick-setup.sh
```

This script will:
- Prompt for your domain and email
- Generate secure passwords
- Create environment files
- Set up DNS configuration template
- Create initial backup

### 3. Deploy All Services

```bash
# Deploy all services
sudo bash /opt/mystack/scripts/deploy-all.sh
```

### 4. Configure DNS

1. Configure DNS records as shown in `/opt/mystack/DNS_SETUP.md`
2. Wait for DNS propagation (5-15 minutes)

### 5. Set Up Reverse Proxy

```bash
# Get proxy configuration instructions
bash /opt/mystack/scripts/configure-proxy-hosts.sh
```

1. Access Nginx Proxy Manager at `http://YOUR_SERVER_IP:81`
2. Login with `admin@example.com` / `changeme`
3. Create proxy hosts for each service
4. Enable SSL certificates

## Manual Setup (Alternative)

If you prefer to set up manually:

### 1. Initialize Server

```bash
sudo bash /opt/mystack/scripts/init-server.sh
```

### 2. Configure Environment Files

Copy and customize environment files in each service directory:

```bash
# Copy environment templates
cp /opt/mystack/shared/configs/global.env.example /opt/mystack/proxy/.env
cp /opt/mystack/shared/configs/global.env.example /opt/mystack/n8n/.env
cp /opt/mystack/shared/configs/global.env.example /opt/mystack/ollama/.env
```

Edit each `.env` file with your specific configuration.

### 3. Deploy Services

```bash
sudo bash /opt/mystack/scripts/deploy-all.sh
```

## Service Configuration

### Nginx Proxy Manager
- **Access**: `http://YOUR_SERVER_IP:81`
- **Default Login**: `admin@example.com` / `changeme`
- **Purpose**: SSL certificates and reverse proxy

### n8n Workflow Automation
- **Access**: `https://n8n.yourdomain.com`
- **Purpose**: Workflow automation and integrations
- **Database**: PostgreSQL with Redis caching

### Ollama + OpenWebUI
- **Access**: `https://ollama.yourdomain.com`
- **Purpose**: Local AI models with web interface
- **Models**: Stored outside `/opt/mystack` to avoid backup issues

### Portainer
- **Access**: `https://portainer.yourdomain.com`
- **Purpose**: Docker container management

### Dozzle
- **Access**: `https://dozzle.yourdomain.com`
- **Purpose**: Real-time container log viewing

### Demo Websites
- **Access**: `https://demo.yourdomain.com`
- **Purpose**: Static website hosting

## Management Commands

### Service Management
```bash
# Check status of all services
bash /opt/mystack/scripts/status.sh

# Start all services
bash /opt/mystack/scripts/start-all.sh

# Stop all services
bash /opt/mystack/scripts/stop-all.sh

# Deploy/update all services
sudo bash /opt/mystack/scripts/deploy-all.sh
```

### Backup Management
```bash
# Create manual backup
sudo bash /opt/mystack/scripts/backup.sh manual

# Create daily backup
sudo bash /opt/mystack/scripts/backup.sh daily

# Create weekly backup
sudo bash /opt/mystack/scripts/backup.sh weekly

# Restore from backup
sudo bash /opt/mystack/scripts/restore.sh /path/to/backup.tar.gz
```

### Individual Service Management
```bash
# Navigate to service directory
cd /opt/mystack/[service-name]

# Start service
docker-compose up -d

# Stop service
docker-compose down

# View logs
docker-compose logs -f

# Update service
docker-compose pull && docker-compose up -d
```

## Security Features

- **Firewall**: UFW configured with minimal open ports
- **Fail2ban**: Protection against brute force attacks
- **SSL/TLS**: Automatic Let's Encrypt certificates
- **Updates**: Automatic security updates enabled
- **Backups**: Automated daily and weekly backups
- **Isolation**: Services run in isolated Docker network

## Backup Strategy

### Included in Backups
- n8n workflow data and database
- Redis data
- Website content
- Proxy configurations
- Environment files

### Excluded from Backups
- Large LLM models (stored outside `/opt/mystack`)
- Docker images
- Log files
- Temporary files

### Backup Locations
- Daily backups: `/opt/mystack/backups/daily/`
- Weekly backups: `/opt/mystack/backups/weekly/`
- Manual backups: `/opt/mystack/backups/manual/`

## Troubleshooting

### Common Issues

1. **Services not starting**
   ```bash
   # Check Docker status
   systemctl status docker
   
   # Check service logs
   docker-compose logs -f [service-name]
   ```

2. **SSL certificates not working**
   - Verify DNS records are configured
   - Check Nginx Proxy Manager logs
   - Ensure ports 80 and 443 are open

3. **Backup failures**
   ```bash
   # Check backup logs
   tail -f /var/log/syslog | grep backup
   
   # Test backup manually
   sudo bash /opt/mystack/scripts/backup.sh manual
   ```

4. **High resource usage**
   ```bash
   # Check resource usage
   bash /opt/mystack/scripts/status.sh
   
   # Monitor containers
   docker stats
   ```

### Log Locations
- System logs: `/var/log/syslog`
- Docker logs: `docker-compose logs -f [service]`
- Nginx logs: `/opt/mystack/proxy/data/logs/`
- Application logs: `/opt/mystack/shared/logs/`

## Maintenance

### Regular Tasks
- Monitor service status weekly
- Check backup integrity monthly
- Update Docker images quarterly
- Review security logs monthly

### Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Update Docker images
cd /opt/mystack
for service in proxy n8n ollama websites monitoring; do
    cd $service
    docker-compose pull
    docker-compose up -d
    cd ..
done
```

## Support

For issues or questions:
1. Check service logs
2. Verify network connectivity
3. Ensure DNS is properly configured
4. Check firewall rules
5. Review this documentation

## File Structure

```
/opt/mystack/
├── proxy/              # Nginx Proxy Manager
│   ├── docker-compose.yml
│   ├── .env
│   └── data/
├── n8n/                # n8n + Postgres + Redis
│   ├── docker-compose.yml
│   ├── .env
│   ├── data/
│   ├── database/
│   └── redis-data/
├── ollama/             # Ollama + OpenWebUI
│   ├── docker-compose.yml
│   ├── .env
│   ├── models/
│   └── webui-data/
├── websites/           # Static websites
│   ├── docker-compose.yml
│   ├── nginx.conf/
│   ├── static-files/
│   └── demo-site/
├── monitoring/         # Portainer + Dozzle
│   ├── docker-compose.yml
│   └── portainer-data/
├── backups/            # Backup files
│   ├── daily/
│   ├── weekly/
│   └── manual/
├── shared/             # Shared configurations
│   ├── configs/
│   ├── certificates/
│   └── logs/
├── scripts/            # Automation scripts
│   ├── init-server.sh
│   ├── deploy-all.sh
│   ├── backup.sh
│   ├── restore.sh
│   ├── status.sh
│   └── quick-setup.sh
├── README.md
├── SETUP_GUIDE.md
└── DNS_SETUP.md
```

This completes your MyStack setup! Your VPS is now ready for testing, demos, and hosting personal sites with a secure, automated Docker environment.
