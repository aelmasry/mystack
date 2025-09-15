#!/bin/bash
echo "🧹 Cleaning up system..."

# Clean Docker
docker system prune -f
docker volume prune -f
docker image prune -f

# Clean system
apt autoremove -y
apt autoclean

# Clean logs
journalctl --vacuum-time=7d
find /var/log -name "*.log" -type f -mtime +7 -delete 2>/dev/null

echo "✅ Cleanup completed!"
