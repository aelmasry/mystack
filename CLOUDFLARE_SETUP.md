# 🌐 Cloudflare DNS Setup for alisalem.me

This guide will help you configure Cloudflare DNS to point all your subdomains to your server.

## 📋 **DNS Records to Add in Cloudflare**

Your server IP: **72.60.193.101**

### **A Records (Required)**

Add these A records in your Cloudflare DNS dashboard:

| Type | Name | Content | TTL | Proxy Status |
|------|------|---------|-----|--------------|
| A | @ | 72.60.193.101 | Auto | 🟠 Proxied |
| A | www | 72.60.193.101 | Auto | 🟠 Proxied |
| A | proxy | 72.60.193.101 | Auto | 🟠 Proxied |
| A | n8n | 72.60.193.101 | Auto | 🟠 Proxied |
| A | ollama | 72.60.193.101 | Auto | 🟠 Proxied |
| A | portainer | 72.60.193.101 | Auto | 🟠 Proxied |
| A | dozzle | 72.60.193.101 | Auto | 🟠 Proxied |
| A | demo | 72.60.193.101 | Auto | 🟠 Proxied |

## 🔧 **Step-by-Step Setup**

### 1. **Access Cloudflare Dashboard**
1. Go to [dash.cloudflare.com](https://dash.cloudflare.com)
2. Select your domain `alisalem.me`
3. Click on **DNS** in the left sidebar

### 2. **Add A Records**
For each subdomain above:
1. Click **Add record**
2. Select **A** as the type
3. Enter the **Name** (e.g., `n8n`)
4. Enter **IPv4 address**: `72.60.193.101`
5. Set **TTL** to **Auto**
6. Enable **Proxy** (orange cloud) for SSL
7. Click **Save**

### 3. **Verify DNS Propagation**
After adding all records, wait 5-15 minutes for DNS propagation, then test:

```bash
# Test DNS resolution
nslookup n8n.alisalem.me
nslookup ollama.alisalem.me
nslookup portainer.alisalem.me
```

## 🌐 **Service URLs After DNS Setup**

Once DNS is configured, your services will be accessible at:

| Service | URL | Purpose |
|---------|-----|---------|
| **Main Site** | https://alisalem.me | Under construction page |
| **Nginx Proxy Manager** | https://proxy.alisalem.me:81 | SSL/HTTPS management |
| **n8n Workflows** | https://n8n.alisalem.me | Workflow automation |
| **OpenWebUI (AI)** | https://ollama.alisalem.me | AI chat interface |
| **Portainer** | https://portainer.alisalem.me | Docker management |
| **Dozzle** | https://dozzle.alisalem.me | Container logs |
| **Demo Sites** | https://demo.alisalem.me | Demo websites |

## 🔒 **SSL Certificate Setup**

### 1. **Access Nginx Proxy Manager**
1. Go to https://proxy.alisalem.me:81
2. Login with: `admin@example.com` / `changeme`

### 2. **Create Proxy Hosts**
For each service, create a proxy host:

#### **Main Site (alisalem.me)**
- **Domain Names**: `alisalem.me`, `www.alisalem.me`
- **Forward Hostname/IP**: `nginx-websites`
- **Forward Port**: `80`
- **Enable SSL**: ✅ Yes
- **Force SSL**: ✅ Yes
- **HTTP/2 Support**: ✅ Yes
- **Block Common Exploits**: ✅ Yes

#### **n8n (n8n.alisalem.me)**
- **Domain Names**: `n8n.alisalem.me`
- **Forward Hostname/IP**: `n8n-app`
- **Forward Port**: `5678`
- **Enable SSL**: ✅ Yes
- **Force SSL**: ✅ Yes

#### **OpenWebUI (ollama.alisalem.me)**
- **Domain Names**: `ollama.alisalem.me`
- **Forward Hostname/IP**: `ollama-webui`
- **Forward Port**: `8080`
- **Enable SSL**: ✅ Yes
- **Force SSL**: ✅ Yes

#### **Portainer (portainer.alisalem.me)**
- **Domain Names**: `portainer.alisalem.me`
- **Forward Hostname/IP**: `portainer`
- **Forward Port**: `9000`
- **Enable SSL**: ✅ Yes
- **Force SSL**: ✅ Yes

#### **Dozzle (dozzle.alisalem.me)**
- **Domain Names**: `dozzle.alisalem.me`
- **Forward Hostname/IP**: `dozzle`
- **Forward Port**: `8080`
- **Enable SSL**: ✅ Yes
- **Force SSL**: ✅ Yes

#### **Demo Sites (demo.alisalem.me)**
- **Domain Names**: `demo.alisalem.me`
- **Forward Hostname/IP**: `nginx-websites`
- **Forward Port**: `80`
- **Enable SSL**: ✅ Yes
- **Force SSL**: ✅ Yes

### 3. **SSL Certificate Configuration**
For each proxy host:
1. Go to **SSL** tab
2. Select **Let's Encrypt**
3. Enter email: `admin@alisalem.me`
4. Check **I Agree to the Let's Encrypt Terms of Service**
5. Click **Save**
6. Wait for certificate to be issued (usually 1-2 minutes)

## 🔧 **Environment Configuration**

Update your environment files with the new domain:

### **n8n Configuration**
```bash
# Update n8n webhook URL
cd /opt/mystack/n8n
sed -i 's|WEBHOOK_URL=.*|WEBHOOK_URL=https://n8n.alisalem.me|' .env
```

### **Ollama Configuration**
```bash
# Update Ollama configuration
cd /opt/mystack/ollama
echo "WEBHOOK_URL=https://ollama.alisalem.me" >> .env
```

## 🧪 **Testing Your Setup**

### 1. **Test DNS Resolution**
```bash
# Test each subdomain
curl -I https://alisalem.me
curl -I https://n8n.alisalem.me
curl -I https://ollama.alisalem.me
curl -I https://portainer.alisalem.me
curl -I https://dozzle.alisalem.me
curl -I https://demo.alisalem.me
```

### 2. **Test SSL Certificates**
```bash
# Check SSL certificate
openssl s_client -connect n8n.alisalem.me:443 -servername n8n.alisalem.me
```

### 3. **Test Service Access**
- Visit each URL in your browser
- Verify SSL certificates are working
- Test service functionality

## 🚨 **Troubleshooting**

### **DNS Not Working**
1. Check if DNS records are correct in Cloudflare
2. Wait for DNS propagation (up to 24 hours)
3. Clear your browser cache and DNS cache

### **SSL Certificate Issues**
1. Ensure domain is pointing to your server
2. Check if ports 80 and 443 are open
3. Verify Let's Encrypt can reach your server

### **Service Not Accessible**
1. Check if containers are running: `docker ps`
2. Check service logs: `docker-compose logs -f`
3. Verify proxy host configuration in Nginx Proxy Manager

## 📱 **Mobile Access**

All services will work on mobile devices using the same URLs:
- https://alisalem.me
- https://n8n.alisalem.me
- https://ollama.alisalem.me
- https://portainer.alisalem.me
- https://dozzle.alisalem.me
- https://demo.alisalem.me

## 🎉 **You're All Set!**

Once DNS propagation is complete and SSL certificates are issued, your MyStack will be fully accessible via your custom domain with secure HTTPS connections!

**Next Steps:**
1. Configure DNS records in Cloudflare
2. Set up proxy hosts in Nginx Proxy Manager
3. Test all services
4. Update any hardcoded URLs in your applications
5. Set up monitoring and backups
