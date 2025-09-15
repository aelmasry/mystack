# 🌐 Browser Access Guide - MyStack Services

Your server IP: **72.60.193.101**

## 🚀 **Direct Access via IP Address**

### **Management & Control Services**

| Service | URL | Purpose | Default Login |
|---------|-----|---------|---------------|
| **Nginx Proxy Manager** | http://72.60.193.101:81 | SSL/HTTPS Management | admin@example.com / changeme |
| **Portainer** | http://72.60.193.101:9000 | Docker Container Management | Create admin account on first visit |
| **Dozzle** | http://72.60.193.101:8080 | Real-time Container Logs | No login required |

### **Application Services**

| Service | URL | Purpose | Default Login |
|---------|-----|---------|---------------|
| **n8n Workflows** | http://72.60.193.101:5678 | Workflow Automation | admin / (check .env file) |
| **OpenWebUI (AI)** | http://72.60.193.101:3000 | AI Chat Interface | Create account on first visit |
| **Demo Websites** | http://72.60.193.101:8081 | Static Website Hosting | No login required |

### **Main Website (via Proxy)**
| Service | URL | Purpose |
|---------|-----|---------|
| **Main Site** | http://72.60.193.101 | Main website (via Nginx Proxy Manager) |

## 🔧 **Quick Access Links**

Click these links to open services directly:

- [🔧 Nginx Proxy Manager](http://72.60.193.101:81)
- [🐳 Portainer](http://72.60.193.101:9000)
- [📊 Dozzle Logs](http://72.60.193.101:8080)
- [⚡ n8n Workflows](http://72.60.193.101:5678)
- [🤖 OpenWebUI AI](http://72.60.193.101:3000)
- [🌐 Demo Websites](http://72.60.193.101:8081)
- [🏠 Main Website](http://72.60.193.101)

## 🔐 **Default Credentials**

### Nginx Proxy Manager
- **URL**: http://72.60.193.101:81
- **Email**: admin@example.com
- **Password**: changeme

### n8n
- **URL**: http://72.60.193.101:5678
- **Username**: admin
- **Password**: Check `/opt/mystack/n8n/.env` file

### Portainer
- **URL**: http://72.60.193.101:9000
- **First Visit**: Create admin account

### OpenWebUI
- **URL**: http://72.60.193.101:3000
- **First Visit**: Create account

## 🛠️ **Service Management**

### Check Service Status
```bash
bash /opt/mystack/scripts/status.sh
```

### View Service Logs
```bash
# View n8n logs
cd /opt/mystack/n8n && docker-compose logs -f

# View all logs via Dozzle
# Visit: http://72.60.193.101:8080
```

### Restart Services
```bash
# Restart all services
cd /opt/mystack && sudo bash scripts/deploy-all.sh

# Restart individual service
cd /opt/mystack/n8n && docker-compose restart
```

## 🔒 **Security Notes**

### For Development/Testing:
- All services are accessible via IP
- Default passwords are used
- No SSL certificates required

### For Production:
1. **Change default passwords** in `.env` files
2. **Set up SSL certificates** via Nginx Proxy Manager
3. **Configure firewall** to restrict access
4. **Use domain names** instead of IP addresses

## 🌍 **Setting Up Domain Names (Optional)**

If you want to use domain names instead of IP addresses:

1. **Configure DNS**: Point your domain to `72.60.193.101`
2. **Access Nginx Proxy Manager**: http://72.60.193.101:81
3. **Create Proxy Hosts** for each service:
   - `n8n.yourdomain.com` → `n8n-app:5678`
   - `ollama.yourdomain.com` → `ollama-webui:8080`
   - `portainer.yourdomain.com` → `portainer:9000`
   - `dozzle.yourdomain.com` → `dozzle:8080`
   - `demo.yourdomain.com` → `nginx-websites:80`

## 🐛 **Troubleshooting**

### Service Not Accessible?
1. **Check if service is running**:
   ```bash
   docker ps | grep [service-name]
   ```

2. **Check service logs**:
   ```bash
   cd /opt/mystack/[service-name] && docker-compose logs -f
   ```

3. **Check firewall**:
   ```bash
   sudo ufw status
   ```

4. **Restart service**:
   ```bash
   cd /opt/mystack/[service-name] && docker-compose restart
   ```

### Port Already in Use?
```bash
# Check what's using a port
sudo netstat -tlnp | grep :[port]

# Stop conflicting service
docker stop [container-name]
```

## 📱 **Mobile Access**

All services are accessible from mobile devices using the same URLs:
- http://72.60.193.101:81 (Nginx Proxy Manager)
- http://72.60.193.101:9000 (Portainer)
- http://72.60.193.101:8080 (Dozzle)
- http://72.60.193.101:5678 (n8n)
- http://72.60.193.101:3000 (OpenWebUI)
- http://72.60.193.101:8081 (Demo Websites)

## 🎯 **Next Steps**

1. **Test all services** by visiting each URL
2. **Change default passwords** for security
3. **Set up SSL certificates** via Nginx Proxy Manager
4. **Configure domain names** (optional)
5. **Set up automated backups**

Your MyStack is now fully accessible via browser! 🚀
