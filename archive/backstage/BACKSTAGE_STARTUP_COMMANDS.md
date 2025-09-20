# Backstage Startup Commands

## 🚀 **Remote Backstage (192.168.1.102) - Always Working Commands**

### **🔧 Complete Startup Script:**

```bash
# SSH into remote machine
ssh santanubiswas@192.168.1.102
# Password: SANTANUPATLA

# Load Node.js environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 20

# Navigate to Backstage
cd /Users/santanubiswas/projects/msdp-backstage-remote

# Start Backstage with network access
export BACKSTAGE_APP_CONFIG_app_listen_host=0.0.0.0
export BACKSTAGE_APP_CONFIG_backend_listen_host=0.0.0.0
yarn start --config app-config.local.yaml
```

### **🔧 Background Startup (Non-Interactive):**

```bash
# From your laptop - one command to start remote Backstage
sshpass -p "SANTANUPATLA" ssh santanubiswas@192.168.1.102 "export NVM_DIR=\$HOME/.nvm && [ -s \$NVM_DIR/nvm.sh ] && . \$NVM_DIR/nvm.sh && nvm use 20 && cd /Users/santanubiswas/projects/msdp-backstage-remote && export BACKSTAGE_APP_CONFIG_app_listen_host=0.0.0.0 && export BACKSTAGE_APP_CONFIG_backend_listen_host=0.0.0.0 && nohup yarn start --config app-config.local.yaml > backstage.log 2>&1 &"
```

### **🔧 Create Startup Script on Remote Machine:**

```bash
# Create this script on remote machine for easy startup
cat > /Users/santanubiswas/projects/start-backstage.sh << 'EOF'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 20

cd /Users/santanubiswas/projects/msdp-backstage-remote

export BACKSTAGE_APP_CONFIG_app_listen_host=0.0.0.0
export BACKSTAGE_APP_CONFIG_backend_listen_host=0.0.0.0

echo "🚀 Starting MSDP Backstage..."
echo "📍 Frontend: http://192.168.1.102:3000"
echo "📍 Backend: http://192.168.1.102:7007"

yarn start --config app-config.local.yaml
EOF

chmod +x /Users/santanubiswas/projects/start-backstage.sh
```

### **🔧 Then Just Run:**

```bash
# SSH and start
ssh santanubiswas@192.168.1.102
/Users/santanubiswas/projects/start-backstage.sh
```

## 💻 **Local Backstage (Your Laptop) - Commands**

### **🔧 Local Startup:**

```bash
# Navigate to local Backstage
cd /Users/santanu/github/msdp-platform-core/msdp-backstage

# Ensure Node.js 20
nvm use 20

# Start Backstage
yarn start
```

## 🎯 **Access Points**

### **✅ Remote Backstage:**
- **URL**: http://192.168.1.102:3000
- **Backend API**: http://192.168.1.102:7007
- **Status**: Network accessible ✅

### **✅ Local Backstage:**
- **URL**: http://localhost:3000
- **Backend API**: http://localhost:7007
- **Status**: Local access ✅

## 📋 **Management Commands**

### **Check Status:**
```bash
# Check if remote Backstage is running
curl -s -o /dev/null -w "Remote Backstage: HTTP %{http_code}\n" http://192.168.1.102:3000

# Check remote process
ssh santanubiswas@192.168.1.102 "ps aux | grep yarn"
```

### **Stop Remote Backstage:**
```bash
# Stop via SSH
ssh santanubiswas@192.168.1.102 "pkill -f 'yarn.*start'"
```

### **View Remote Logs:**
```bash
# View logs
ssh santanubiswas@192.168.1.102 "tail -f /Users/santanubiswas/projects/msdp-backstage-remote/backstage.log"
```

---

## 🎉 **You Now Have TWO Working Backstage Instances!**

- 💻 **Local**: http://localhost:3000
- 🖥️ **Remote**: http://192.168.1.102:3000

**Both ready for Step 2: MSDP Configuration!** 🚀
