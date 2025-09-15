#!/bin/bash

# MyStack Backup Script
# This script creates compressed backups of essential service data
# Usage: sudo bash /opt/mystack/scripts/backup.sh [daily|weekly|manual]
# Run with: sudo bash /opt/mystack/scripts/backup.sh daily

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

# Configuration
BACKUP_TYPE=${1:-daily}
BACKUP_BASE_DIR="/opt/mystack/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$BACKUP_BASE_DIR/$BACKUP_TYPE"
BACKUP_FILE="mystack_backup_${BACKUP_TYPE}_${TIMESTAMP}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

log "Starting MyStack backup (type: $BACKUP_TYPE)"
log "Backup file: $BACKUP_FILE"

# Create temporary directory for backup
TEMP_BACKUP_DIR="/tmp/mystack_backup_$$"
mkdir -p "$TEMP_BACKUP_DIR"

# Function to backup a service
backup_service() {
    local service_name=$1
    local source_path=$2
    local target_path=$3
    
    if [[ -d "$source_path" ]]; then
        log "Backing up $service_name from $source_path"
        cp -r "$source_path" "$TEMP_BACKUP_DIR/$target_path"
        log "$service_name backup completed"
    else
        warn "$service_name source path not found: $source_path"
    fi
}

# Function to backup database
backup_database() {
    local db_name=$1
    local container_name=$2
    local backup_file="$TEMP_BACKUP_DIR/databases/${db_name}_${TIMESTAMP}.sql"
    
    if docker ps | grep -q "$container_name"; then
        log "Backing up $db_name database from $container_name"
        mkdir -p "$TEMP_BACKUP_DIR/databases"
        
        # Create database dump
        if docker exec "$container_name" pg_dump -U postgres "$db_name" > "$backup_file" 2>/dev/null; then
            log "$db_name database backup completed"
        else
            warn "Failed to backup $db_name database"
        fi
    else
        warn "$db_name container not running: $container_name"
    fi
}

# Function to backup Redis data
backup_redis() {
    local container_name=$1
    local backup_file="$TEMP_BACKUP_DIR/redis/redis_backup_${TIMESTAMP}.rdb"
    
    if docker ps | grep -q "$container_name"; then
        log "Backing up Redis data from $container_name"
        mkdir -p "$TEMP_BACKUP_DIR/redis"
        
        # Trigger Redis BGSAVE
        docker exec "$container_name" redis-cli BGSAVE
        
        # Wait for save to complete
        sleep 5
        
        # Copy the RDB file
        if docker cp "$container_name:/data/dump.rdb" "$backup_file" 2>/dev/null; then
            log "Redis backup completed"
        else
            warn "Failed to backup Redis data"
        fi
    else
        warn "Redis container not running: $container_name"
    fi
}

# Start backup process
log "Creating backup in temporary directory: $TEMP_BACKUP_DIR"

# Backup n8n data
backup_service "n8n data" "/opt/mystack/n8n/data" "n8n/data"

# Backup n8n database
backup_database "n8n" "n8n-postgres"

# Backup Redis data
backup_redis "n8n-redis"

# Backup website data
backup_service "websites" "/opt/mystack/websites/static-files" "websites/static-files"

# Backup proxy configuration
backup_service "proxy config" "/opt/mystack/proxy/data" "proxy/data"

# Backup shared configurations
backup_service "shared configs" "/opt/mystack/shared/configs" "shared/configs"

# Backup environment files
log "Backing up environment files"
find /opt/mystack -name ".env" -type f | while read -r env_file; do
    relative_path=$(echo "$env_file" | sed 's|/opt/mystack/||')
    target_dir="$TEMP_BACKUP_DIR/env_files/$(dirname "$relative_path")"
    mkdir -p "$target_dir"
    cp "$env_file" "$TEMP_BACKUP_DIR/env_files/$relative_path"
done

# Create backup manifest
log "Creating backup manifest"
cat > "$TEMP_BACKUP_DIR/backup_manifest.txt" << EOF
MyStack Backup Manifest
======================

Backup Type: $BACKUP_TYPE
Created: $(date)
Hostname: $(hostname)
Backup Script Version: 1.0

Included Services:
- n8n workflow data
- n8n PostgreSQL database
- n8n Redis data
- Website static files
- Proxy configuration
- Shared configurations
- Environment files

Excluded (by design):
- Large LLM models (stored outside /opt/mystack)
- Docker images
- Log files
- Temporary files

Backup Size: $(du -sh "$TEMP_BACKUP_DIR" | cut -f1)
EOF

# Create compressed backup
log "Creating compressed backup archive..."
cd "$TEMP_BACKUP_DIR"
tar -czf "$BACKUP_DIR/$BACKUP_FILE" . 2>/dev/null

# Verify backup
if [[ -f "$BACKUP_DIR/$BACKUP_FILE" ]]; then
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    log "Backup created successfully: $BACKUP_FILE ($BACKUP_SIZE)"
else
    error "Failed to create backup file"
    exit 1
fi

# Clean up temporary directory
rm -rf "$TEMP_BACKUP_DIR"

# Show backup information
log "Backup completed successfully!"
echo ""
echo "=== Backup Information ==="
echo "Backup Type: $BACKUP_TYPE"
echo "Backup File: $BACKUP_FILE"
echo "Backup Size: $BACKUP_SIZE"
echo "Location: $BACKUP_DIR/$BACKUP_FILE"
echo "Created: $(date)"
echo ""

# List recent backups
log "Recent backups in $BACKUP_TYPE:"
ls -laht "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -5 || echo "No previous backups found"

# Show disk usage
log "Backup directory disk usage:"
du -sh "$BACKUP_BASE_DIR"/* 2>/dev/null || echo "No backup directories found"

# Optional: Upload to remote storage (uncomment and configure as needed)
# log "Uploading backup to remote storage..."
# rsync -avz "$BACKUP_DIR/$BACKUP_FILE" user@remote-server:/backups/mystack/

# Optional: Send notification (uncomment and configure as needed)
# log "Sending backup notification..."
# curl -X POST -H 'Content-type: application/json' \
#     --data '{"text":"MyStack backup completed successfully: '$BACKUP_FILE'"}' \
#     YOUR_WEBHOOK_URL

log "Backup process completed!"
