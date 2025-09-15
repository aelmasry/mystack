#!/bin/bash

# MyStack VPS Initialization Script
# This script sets up a fresh Ubuntu 24 VPS for Docker-based services
# Run with: sudo bash /opt/mystack/scripts/init-server.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

log "Starting MyStack VPS initialization..."

# Update system packages
log "Updating system packages..."
apt update && apt upgrade -y

# Install essential packages
log "Installing essential packages..."
apt install -y \
    curl \
    wget \
    git \
    unzip \
    htop \
    nano \
    vim \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

# Install Docker
log "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Remove old Docker installations
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    log "Docker installed successfully"
else
    log "Docker is already installed"
fi

# Install Docker Compose (standalone)
log "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log "Docker Compose installed successfully"
else
    log "Docker Compose is already installed"
fi

# Create mystack user and add to docker group
log "Setting up mystack user..."
if ! id "mystack" &>/dev/null; then
    useradd -m -s /bin/bash mystack
    usermod -aG docker mystack
    log "Created mystack user and added to docker group"
else
    usermod -aG docker mystack
    log "Added mystack user to docker group"
fi

# Configure firewall (UFW)
log "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (be careful with this!)
ufw allow ssh

# Allow HTTP and HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow Nginx Proxy Manager admin interface
ufw allow 81/tcp

# Allow specific ports for services (if needed)
ufw allow 9000/tcp  # Portainer (will be proxied later)

# Enable firewall
ufw --force enable

log "Firewall configured successfully"

# Configure fail2ban
log "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

systemctl enable fail2ban
systemctl start fail2ban

log "Fail2ban configured successfully"

# Configure unattended upgrades
log "Configuring automatic security updates..."
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

log "Automatic security updates configured"

# Create folder structure
log "Creating folder structure..."
mkdir -p /opt/mystack/{proxy,n8n,ollama,websites,monitoring,backups/{daily,weekly,manual},shared/{configs,certificates,logs},scripts}

# Set proper permissions
chown -R mystack:mystack /opt/mystack
chmod -R 755 /opt/mystack

log "Folder structure created successfully"

# Create Docker network
log "Creating Docker network..."
docker network create mystack-network 2>/dev/null || log "Network mystack-network already exists"

# Configure system limits for Docker
log "Configuring system limits..."
cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# Configure Docker daemon
log "Configuring Docker daemon..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "metrics-addr": "127.0.0.1:9323",
  "default-address-pools": [
    {
      "base": "172.17.0.0/12",
      "size": 24
    }
  ]
}
EOF

systemctl restart docker

log "Docker daemon configured successfully"

# Create systemd service for automatic startup
log "Creating systemd service for MyStack..."
cat > /etc/systemd/system/mystack.service << EOF
[Unit]
Description=MyStack Docker Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/mystack
ExecStart=/opt/mystack/scripts/deploy-all.sh
ExecStop=/usr/local/bin/docker-compose -f /opt/mystack/proxy/docker-compose.yml down
ExecStop=/usr/local/bin/docker-compose -f /opt/mystack/n8n/docker-compose.yml down
ExecStop=/usr/local/bin/docker-compose -f /opt/mystack/ollama/docker-compose.yml down
ExecStop=/usr/local/bin/docker-compose -f /opt/mystack/websites/docker-compose.yml down
ExecStop=/usr/local/bin/docker-compose -f /opt/mystack/monitoring/docker-compose.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mystack.service

log "Systemd service created and enabled"

# Create backup cron job
log "Setting up automated backups..."
cat > /etc/cron.d/mystack-backup << EOF
# MyStack automated backups
# Daily backup at 2 AM
0 2 * * * root /opt/mystack/scripts/backup.sh daily
# Weekly backup on Sunday at 3 AM
0 3 * * 0 root /opt/mystack/scripts/backup.sh weekly
EOF

log "Automated backups configured"

# Create cleanup script for old backups
cat > /opt/mystack/scripts/cleanup-backups.sh << 'EOF'
#!/bin/bash
# Cleanup old backup files

BACKUP_DIR="/opt/mystack/backups"
DAILY_RETENTION=7    # Keep daily backups for 7 days
WEEKLY_RETENTION=30  # Keep weekly backups for 30 days

# Clean daily backups
find "$BACKUP_DIR/daily" -name "*.tar.gz" -mtime +$DAILY_RETENTION -delete 2>/dev/null || true

# Clean weekly backups
find "$BACKUP_DIR/weekly" -name "*.tar.gz" -mtime +$WEEKLY_RETENTION -delete 2>/dev/null || true

echo "$(date): Backup cleanup completed"
EOF

chmod +x /opt/mystack/scripts/cleanup-backups.sh

# Add cleanup to cron (run daily at 4 AM)
echo "0 4 * * * root /opt/mystack/scripts/cleanup-backups.sh" >> /etc/cron.d/mystack-backup

# Set up log rotation
log "Configuring log rotation..."
cat > /etc/logrotate.d/mystack << EOF
/opt/mystack/shared/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 mystack mystack
}
EOF

# Create environment file template
log "Creating environment configuration template..."
cat > /opt/mystack/shared/configs/.env.template << EOF
# MyStack Environment Configuration Template
# Copy this file to each service directory and customize as needed

# Domain configuration
DOMAIN=yourdomain.com
EMAIL=admin@yourdomain.com

# Database passwords (generate strong passwords)
POSTGRES_PASSWORD=your_secure_postgres_password
REDIS_PASSWORD=your_secure_redis_password

# n8n configuration
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_n8n_password

# Ollama configuration
OLLAMA_MODELS_PATH=/opt/ollama-models

# Backup configuration
BACKUP_RETENTION_DAYS=30
EOF

# Make scripts executable
chmod +x /opt/mystack/scripts/*.sh

log "Initialization completed successfully!"
log ""
log "Next steps:"
log "1. Configure your domain DNS to point to this server"
log "2. Copy and customize environment files in each service directory"
log "3. Run: sudo bash /opt/mystack/scripts/deploy-all.sh"
log ""
log "Default service URLs (after deployment):"
log "- Nginx Proxy Manager: http://your-server-ip:81"
log "- n8n: https://n8n.yourdomain.com"
log "- OpenWebUI: https://ollama.yourdomain.com"
log "- Portainer: https://portainer.yourdomain.com"
log "- Dozzle: https://dozzle.yourdomain.com"
log ""
warn "Remember to:"
warn "- Update firewall rules if needed"
warn "- Configure SSL certificates in Nginx Proxy Manager"
warn "- Set strong passwords in environment files"
warn "- Test all services after deployment"
