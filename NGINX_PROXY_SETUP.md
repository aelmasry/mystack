# Nginx Proxy Manager Setup Guide

## 🌐 **Access Nginx Proxy Manager**

1. **Open your browser** and go to: `http://72.60.193.101:81`
2. **Default Login Credentials:**
   - Email: `admin@example.com`
   - Password: `changeme`

## 🔧 **Step 1: Change Default Password**

1. Login to Nginx Proxy Manager
2. Click on your profile (top right)
3. Change the default password to something secure

## 📝 **Step 2: Configure Cloudflare DNS**

Before setting up the proxy, you need to configure your DNS records in Cloudflare:

### **DNS Records to Add in Cloudflare:**

1. **Main Domain A Record:**
   - Type: `A`
   - Name: `@` (or `alisalem.me`)
   - Content: `72.60.193.101`
   - TTL: `Auto`

2. **Subdomain A Records:**
   - Type: `A`
   - Name: `n8n`
   - Content: `72.60.193.101`
   - TTL: `Auto`

   - Type: `A`
   - Name: `ollama`
   - Content: `72.60.193.101`
   - TTL: `Auto`

   - Type: `A`
   - Name: `demo`
   - Content: `72.60.193.101`
   - TTL: `Auto`

   - Type: `A`
   - Name: `proxy`
   - Content: `72.60.193.101`
   - TTL: `Auto`

   - Type: `A`
   - Name: `portainer`
   - Content: `72.60.193.101`
   - TTL: `Auto`

   - Type: `A`
   - Name: `dozzle`
   - Content: `72.60.193.101`
   - TTL: `Auto`

## 🔒 **Step 3: Create Proxy Host for n8n**

1. **In Nginx Proxy Manager, click "Proxy Hosts"**
2. **Click "Add Proxy Host"**
3. **Fill in the details:**

   **Details Tab:**
   - Domain Names: `n8n.alisalem.me`
   - Scheme: `http`
   - Forward Hostname/IP: `n8n-app` (container name)
   - Forward Port: `5678`
   - ✅ Block Common Exploits
   - ✅ Websockets Support

   **SSL Tab:**
   - ✅ Force SSL
   - ✅ HTTP/2 Support
   - ✅ HSTS Enabled
   - ✅ HSTS Subdomains
   - Certificate: `Request a new SSL Certificate`
   - ✅ I Agree to the Let's Encrypt Terms of Service
   - Email Address: `your-email@example.com` (use your real email)

4. **Click "Save"**

## 🔄 **Step 4: Update n8n Configuration**

After setting up the proxy, we need to update n8n to work with HTTPS:

### **Update n8n Environment Variables:**

```bash
# In n8n docker-compose.yml, update these variables:
- N8N_PROTOCOL=https
- WEBHOOK_URL=https://n8n.alisalem.me
- N8N_SECURE_COOKIE=true
```

## 🌐 **Step 5: Test the Setup**

1. **Wait 2-3 minutes** for DNS propagation and SSL certificate generation
2. **Test the subdomain:** `https://n8n.alisalem.me`
3. **You should see:**
   - ✅ Green lock icon (SSL certificate)
   - ✅ n8n login page
   - ✅ No security warnings

## 🔧 **Step 6: Repeat for Other Services**

### **OpenWebUI (ollama.alisalem.me):**
- Domain: `ollama.alisalem.me`
- Forward to: `ollama-webui:8080`

### **Demo Websites (demo.alisalem.me):**
- Domain: `demo.alisalem.me`
- Forward to: `nginx-websites:80`

### **Portainer (portainer.alisalem.me):**
- Domain: `portainer.alisalem.me`
- Forward to: `portainer:9000`

### **Dozzle (dozzle.alisalem.me):**
- Domain: `dozzle.alisalem.me`
- Forward to: `dozzle:8080`

## 🚨 **Troubleshooting**

### **If SSL Certificate Fails:**
1. Check DNS propagation: `nslookup n8n.alisalem.me`
2. Ensure port 80 and 443 are open
3. Wait 5-10 minutes and try again

### **If n8n Shows Security Warnings:**
1. Update n8n environment variables
2. Restart n8n container
3. Clear browser cache

### **If Subdomain Doesn't Work:**
1. Check Cloudflare DNS settings
2. Verify container names in proxy configuration
3. Check container network connectivity

## 📋 **Quick Commands**

```bash
# Check DNS propagation
nslookup n8n.alisalem.me

# Check container status
docker ps

# Check n8n logs
docker logs n8n-app

# Restart n8n after config changes
cd /opt/mystack/n8n && docker-compose restart n8n
```

## 🎯 **Expected Results**

After setup, you should have:
- ✅ `https://n8n.alisalem.me` - n8n with SSL
- ✅ `https://ollama.alisalem.me` - OpenWebUI with SSL
- ✅ `https://demo.alisalem.me` - Demo websites with SSL
- ✅ `https://portainer.alisalem.me` - Portainer with SSL
- ✅ `https://dozzle.alisalem.me` - Dozzle with SSL

All services will have valid SSL certificates and work seamlessly with your domain!
