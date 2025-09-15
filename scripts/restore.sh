#!/bin/bash

# MyStack Restore Script
# This script restores services from backup files
# Usage: sudo bash /opt/mystack/scripts/restore.sh <backup_file>
# Example: sudo bash /opt/mystack/scripts/restore.sh /opt/mystack/backups/daily/mystack_backup_daily_20241201_020000.tar.gz

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

# Check if backup file is provided
if [[ $# -eq 0 ]]; then
    error "Usage: $0 <backup_file>"
    error "Example: $0 /opt/mystack/backups/daily/mystack_backup_daily_20241201_020000.tar.gz"
    exit 1
fi

BACKUP_FILE="$1"

# Verify backup file exists
if [[ ! -f "$BACKUP_FILE" ]]; then
    error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

log "Starting MyStack restore from: $BACKUP_FILE"

# Create temporary directory for restore
TEMP_RESTORE_DIR="/tmp/mystack_restore_$$"
mkdir -p "$TEMP_RESTORE_DIR"

# Extract backup
log "Extracting backup file..."
if tar -xzf "$BACKUP_FILE" -C "$TEMP_RESTORE_DIR"; then
    log "Backup extracted successfully"
else
    error "Failed to extract backup file"
    exit 1
fi

# Function to restore a service
restore_service() {
    local service_name=$1
    local source_path=$2
    local target_path=$3
    
    if [[ -d "$source_path" ]]; then
        log "Restoring $service_name to $target_path"
        
        # Create target directory if it doesn't exist
        mkdir -p "$(dirname "$target_path")"
        
        # Backup existing data if it exists
        if [[ -d "$target_path" ]]; then
            local backup_name="${target_path}_backup_$(date +%Y%m%d_%H%M%S)"
            log "Backing up existing $service_name data to $backup_name"
            mv "$target_path" "$backup_name"
        fi
        
        # Restore data
        cp -r "$source_path" "$target_path"
        chown -R mystack:mystack "$target_path" 2>/dev/null || true
        log "$service_name restored successfully"
    else
        warn "$service_name source path not found in backup: $source_path"
    fi
}

# Function to restore database
restore_database() {
    local db_name=$1
    local container_name=$2
    local backup_file=$3
    
    if [[ -f "$backup_file" ]]; then
        log "Restoring $db_name database to $container_name"
        
        # Check if container is running
        if docker ps | grep -q "$container_name"; then
            # Drop and recreate database
            docker exec "$container_name" psql -U postgres -c "DROP DATABASE IF EXISTS $db_name;" 2>/dev/null || true
            docker exec "$container_name" psql -U postgres -c "CREATE DATABASE $db_name;" 2>/dev/null || true
            
            # Restore database
            if docker exec -i "$container_name" psql -U postgres "$db_name" < "$backup_file" 2>/dev/null; then
                log "$db_name database restored successfully"
            else
                warn "Failed to restore $db_name database"
            fi
        else
            warn "$db_name container not running: $container_name"
        fi
    else
        warn "$db_name backup file not found: $backup_file"
    fi
}

# Function to restore Redis data
restore_redis() {
    local container_name=$1
    local backup_file=$2
    
    if [[ -f "$backup_file" ]]; then
        log "Restoring Redis data to $container_name"
        
        if docker ps | grep -q "$container_name"; then
            # Stop Redis gracefully
            docker exec "$container_name" redis-cli SHUTDOWN SAVE 2>/dev/null || true
            sleep 2
            
            # Copy backup file
            if docker cp "$backup_file" "$container_name:/data/dump.rdb" 2>/dev/null; then
                # Restart Redis
                docker restart "$container_name" 2>/dev/null || true
                log "Redis data restored successfully"
            else
                warn "Failed to restore Redis data"
            fi
        else
            warn "Redis container not running: $container_name"
        fi
    else
        warn "Redis backup file not found: $backup_file"
    fi
}

# Show backup manifest if available
if [[ -f "$TEMP_RESTORE_DIR/backup_manifest.txt" ]]; then
    log "Backup manifest:"
    cat "$TEMP_RESTORE_DIR/backup_manifest.txt"
    echo ""
fi

# Confirm restore
echo -e "${YELLOW}WARNING: This will overwrite existing data!${NC}"
echo -e "${YELLOW}Make sure you have a current backup before proceeding.${NC}"
echo ""
read -p "Do you want to continue with the restore? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    log "Restore cancelled by user"
    rm -rf "$TEMP_RESTORE_DIR"
    exit 0
fi

# Stop services before restore
log "Stopping services before restore..."
cd /opt/mystack

# Stop all services
for service_dir in proxy n8n ollama websites monitoring; do
    if [[ -f "$service_dir/docker-compose.yml" ]]; then
        log "Stopping $service_dir service..."
        cd "$service_dir"
        docker-compose down 2>/dev/null || true
        cd /opt/mystack
    fi
done

# Restore services
log "Starting restore process..."

# Restore n8n data
restore_service "n8n data" "$TEMP_RESTORE_DIR/n8n/data" "/opt/mystack/n8n/data"

# Restore website data
restore_service "websites" "$TEMP_RESTORE_DIR/websites/static-files" "/opt/mystack/websites/static-files"

# Restore proxy configuration
restore_service "proxy config" "$TEMP_RESTORE_DIR/proxy/data" "/opt/mystack/proxy/data"

# Restore shared configurations
restore_service "shared configs" "$TEMP_RESTORE_DIR/shared/configs" "/opt/mystack/shared/configs"

# Restore environment files
if [[ -d "$TEMP_RESTORE_DIR/env_files" ]]; then
    log "Restoring environment files..."
    find "$TEMP_RESTORE_DIR/env_files" -name ".env" -type f | while read -r env_file; do
        relative_path=$(echo "$env_file" | sed "s|$TEMP_RESTORE_DIR/env_files/||")
        target_file="/opt/mystack/$relative_path"
        target_dir=$(dirname "$target_file")
        
        mkdir -p "$target_dir"
        cp "$env_file" "$target_file"
        chown mystack:mystack "$target_file" 2>/dev/null || true
        log "Restored environment file: $target_file"
    done
fi

# Start services
log "Starting services..."
bash /opt/mystack/scripts/deploy-all.sh

# Wait for services to be ready
log "Waiting for services to be ready..."
sleep 30

# Restore databases (after services are running)
log "Restoring databases..."

# Find database backup files
if [[ -d "$TEMP_RESTORE_DIR/databases" ]]; then
    for db_backup in "$TEMP_RESTORE_DIR/databases"/*.sql; do
        if [[ -f "$db_backup" ]]; then
            db_name=$(basename "$db_backup" | cut -d'_' -f1)
            restore_database "$db_name" "n8n-postgres" "$db_backup"
        fi
    done
fi

# Restore Redis data
if [[ -d "$TEMP_RESTORE_DIR/redis" ]]; then
    for redis_backup in "$TEMP_RESTORE_DIR/redis"/*.rdb; do
        if [[ -f "$redis_backup" ]]; then
            restore_redis "n8n-redis" "$redis_backup"
        fi
    done
fi

# Clean up temporary directory
rm -rf "$TEMP_RESTORE_DIR"

# Verify restore
log "Verifying restore..."
echo ""
echo "=== Service Status After Restore ==="

services=(
    "proxy:Nginx Proxy Manager"
    "monitoring:Portainer + Dozzle"
    "n8n:n8n Stack"
    "ollama:Ollama + OpenWebUI"
    "websites:Websites"
)

for service_info in "${services[@]}"; do
    IFS=':' read -r service_dir service_name <<< "$service_info"
    compose_file="/opt/mystack/$service_dir/docker-compose.yml"
    
    if [[ -f "$compose_file" ]]; then
        cd "$(dirname "$compose_file")"
        echo -e "${BLUE}$service_name:${NC}"
        docker-compose ps
        echo ""
    fi
done

# Show running containers
log "All running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

log "Restore completed successfully!"
echo ""
echo "=== Post-Restore Checklist ==="
echo "1. Verify all services are running: /opt/mystack/scripts/health-check.sh"
echo "2. Test service access via web interfaces"
echo "3. Verify SSL certificates are working"
echo "4. Check that data has been restored correctly"
echo "5. Update any configuration that may have changed"
echo ""
warn "Important:"
warn "- Test all services thoroughly after restore"
warn "- Verify SSL certificates are still valid"
warn "- Check that all workflows and configurations are working"
warn "- Consider running a fresh backup after successful restore"
