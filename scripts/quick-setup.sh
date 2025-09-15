#!/bin/bash

# MyStack Quick Setup Script
# This script helps with initial configuration after deployment
# Run with: sudo bash /opt/mystack/scripts/quick-setup.sh

set -e

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

log "Starting MyStack Quick Setup..."

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\${input:-$default}"
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Collect configuration
echo -e "${BLUE}=== MyStack Configuration ===${NC}"
echo "Please provide the following information:"
echo ""

prompt_with_default "Enter your domain name" "yourdomain.com" "DOMAIN"
prompt_with_default "Enter your email address" "admin@$DOMAIN" "EMAIL"

# Generate secure passwords
POSTGRES_PASSWORD=$(generate_password)
REDIS_PASSWORD=$(generate_password)
N8N_AUTH_PASSWORD=$(generate_password)
WEBUI_SECRET_KEY=$(generate_password)

log "Generated secure passwords for all services"

# Create environment files for each service
log "Creating environment files..."

# Proxy environment
cat > /opt/mystack/proxy/.env << EOF
# Nginx Proxy Manager Environment Configuration
DOMAIN=$DOMAIN
EMAIL=$EMAIL
ADMIN_EMAIL=$EMAIL
ADMIN_PASSWORD=changeme123
SSL_EMAIL=$EMAIL
SSL_AGREE_TERMS=true
LOG_LEVEL=info
EOF

# n8n environment
cat > /opt/mystack/n8n/.env << EOF
# n8n Environment Configuration
POSTGRES_DB=n8n
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_NON_ROOT_USER=n8n
POSTGRES_NON_ROOT_PASSWORD=$N8N_AUTH_PASSWORD
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=$N8N_AUTH_PASSWORD
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
GENERIC_TIMEZONE=UTC
WEBHOOK_URL=https://n8n.$DOMAIN
EOF

# Ollama environment
cat > /opt/mystack/ollama/.env << EOF
# Ollama + OpenWebUI Environment Configuration
WEBUI_SECRET_KEY=$WEBUI_SECRET_KEY
DEFAULT_USER_ROLE=admin
WEBUI_AUTH=True
ENABLE_SIGNUP=False
OLLAMA_HOST=0.0.0.0:11434
EOF

# Set proper permissions
chown -R mystack:mystack /opt/mystack
chmod 600 /opt/mystack/*/.env

log "Environment files created successfully"

# Create DNS configuration template
log "Creating DNS configuration template..."
cat > /opt/mystack/DNS_SETUP.md << EOF
# DNS Configuration for MyStack

Configure the following DNS records with your DNS provider (Cloudflare, Hostinger, etc.):

## A Records (point to your server IP: $(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP"))

- proxy.$DOMAIN
- n8n.$DOMAIN
- ollama.$DOMAIN
- portainer.$DOMAIN
- dozzle.$DOMAIN
- demo.$DOMAIN

## CNAME Records (optional, for www subdomains)

- www.n8n.$DOMAIN → n8n.$DOMAIN
- www.ollama.$DOMAIN → ollama.$DOMAIN

## After DNS Configuration

1. Wait for DNS propagation (usually 5-15 minutes)
2. Access Nginx Proxy Manager: http://$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP"):81
3. Create proxy hosts for each service
4. Enable SSL certificates (Let's Encrypt)

## Service URLs (after proxy setup)

- Nginx Proxy Manager: https://proxy.$DOMAIN:81
- n8n: https://n8n.$DOMAIN
- OpenWebUI: https://ollama.$DOMAIN
- Portainer: https://portainer.$DOMAIN
- Dozzle: https://dozzle.$DOMAIN
- Demo Sites: https://demo.$DOMAIN
EOF

# Create proxy host configuration script
log "Creating proxy host configuration script..."
cat > /opt/mystack/scripts/configure-proxy-hosts.sh << 'EOF'
#!/bin/bash

# MyStack Proxy Host Configuration Helper
# This script provides instructions for configuring proxy hosts in Nginx Proxy Manager

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Nginx Proxy Manager Host Configuration ===${NC}"
echo ""
echo "Follow these steps to configure proxy hosts:"
echo ""

echo -e "${GREEN}1. Access Nginx Proxy Manager:${NC}"
echo "   http://YOUR_SERVER_IP:81"
echo "   Default login: admin@example.com / changeme"
echo ""

echo -e "${GREEN}2. Create Proxy Hosts:${NC}"
echo ""

services=(
    "n8n:5678:n8n workflow automation"
    "ollama:8080:OpenWebUI interface"
    "portainer:9000:Portainer container management"
    "dozzle:8080:Dozzle log viewer"
    "demo:80:Demo websites"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r service_name port description <<< "$service_info"
    echo "   • $service_name.$DOMAIN"
    echo "     - Forward Hostname/IP: nginx-websites (or appropriate container name)"
    echo "     - Forward Port: $port"
    echo "     - Description: $description"
    echo "     - Enable SSL: Yes"
    echo "     - Force SSL: Yes"
    echo "     - HTTP/2 Support: Yes"
    echo "     - Block Common Exploits: Yes"
    echo ""
done

echo -e "${GREEN}3. SSL Certificate Setup:${NC}"
echo "   • Use Let's Encrypt for each proxy host"
echo "   • Email: $EMAIL"
echo "   • Agree to Terms: Yes"
echo "   • Force SSL: Yes"
echo ""

echo -e "${GREEN}4. Test Configuration:${NC}"
echo "   • Wait for SSL certificates to be issued"
echo "   • Test each service URL"
echo "   • Verify HTTPS redirects work"
echo ""

echo -e "${YELLOW}Note: Make sure DNS records are configured before setting up proxy hosts!${NC}"
EOF

chmod +x /opt/mystack/scripts/configure-proxy-hosts.sh

# Create service management scripts
log "Creating service management scripts..."

# Start all services
cat > /opt/mystack/scripts/start-all.sh << 'EOF'
#!/bin/bash
# Start all MyStack services
cd /opt/mystack
bash scripts/deploy-all.sh
EOF

# Stop all services
cat > /opt/mystack/scripts/stop-all.sh << 'EOF'
#!/bin/bash
# Stop all MyStack services
cd /opt/mystack

services=("proxy" "monitoring" "n8n" "ollama" "websites")
for service in "${services[@]}"; do
    if [[ -f "$service/docker-compose.yml" ]]; then
        echo "Stopping $service..."
        cd "$service"
        docker-compose down
        cd /opt/mystack
    fi
done

echo "All services stopped"
EOF

# Make scripts executable
chmod +x /opt/mystack/scripts/*.sh

# Create initial backup
log "Creating initial backup..."
bash /opt/mystack/scripts/backup.sh manual

# Show completion message
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Setup Completed Successfully!             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}=== Next Steps ===${NC}"
echo ""
echo "1. Configure DNS records (see /opt/mystack/DNS_SETUP.md)"
echo "2. Wait for DNS propagation (5-15 minutes)"
echo "3. Run: bash /opt/mystack/scripts/configure-proxy-hosts.sh"
echo "4. Access Nginx Proxy Manager and set up proxy hosts"
echo "5. Test all services"
echo ""
echo -e "${BLUE}=== Service Credentials ===${NC}"
echo "Nginx Proxy Manager: admin@example.com / changeme"
echo "n8n: admin / $N8N_AUTH_PASSWORD"
echo "OpenWebUI: Create account on first access"
echo ""
echo -e "${BLUE}=== Useful Commands ===${NC}"
echo "• Check status: bash /opt/mystack/scripts/status.sh"
echo "• Start all: bash /opt/mystack/scripts/start-all.sh"
echo "• Stop all: bash /opt/mystack/scripts/stop-all.sh"
echo "• Create backup: bash /opt/mystack/scripts/backup.sh manual"
echo "• View logs: docker-compose logs -f [service]"
echo ""
echo -e "${YELLOW}Important: Save your passwords securely!${NC}"
echo "Passwords are stored in /opt/mystack/*/.env files"
echo ""
log "Quick setup completed successfully!"
