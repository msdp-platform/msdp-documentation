# Backstage SSH Tunnel Access Guide

## 🎯 **Problem: Network Access Issues**

If Backstage is running on the remote machine but you can't access it from your laptop due to network binding issues, SSH port forwarding provides a simple solution.

## 🚀 **Solution: SSH Port Forwarding**

### **Step 1: Start Backstage on Remote Machine (Simple)**

```bash
# SSH into remote machine
ssh santanubiswas@192.168.1.102

# Navigate to Backstage directory
cd /Users/santanubiswas/projects/msdp-backstage

# Set up Node.js path
export PATH="/Users/santanubiswas/.nvm/versions/node/v18.20.8/bin:$PATH"

# Start Backstage (will bind to localhost by default)
yarn start

# Keep this terminal open - Backstage will run here
```

### **Step 2: Create SSH Tunnel from Your Laptop**

Open a **new terminal on your laptop** and run:

```bash
# Create SSH tunnel for Backstage frontend (port 3000)
ssh -L 3000:localhost:3000 -L 7007:localhost:7007 santanubiswas@192.168.1.102

# This forwards:
# - Your laptop's port 3000 → Remote machine's port 3000 (Backstage frontend)
# - Your laptop's port 7007 → Remote machine's port 7007 (Backstage backend)
```

### **Step 3: Access Backstage from Your Laptop**

Once the SSH tunnel is established, open your browser and go to:

**🎛️ Backstage Service Catalog: `http://localhost:3000`**

## 🔧 **Alternative: One-Command SSH Tunnel**

```bash
# Single command to create tunnel with password
sshpass -p "SANTANUPATLA" ssh -L 3000:localhost:3000 -L 7007:localhost:7007 santanubiswas@192.168.1.102

# Keep this terminal open for the tunnel to work
```

## 📋 **Complete Workflow**

### **Terminal 1 (Remote Backstage):**
```bash
ssh santanubiswas@192.168.1.102
cd /Users/santanubiswas/projects/msdp-backstage
export PATH="/Users/santanubiswas/.nvm/versions/node/v18.20.8/bin:$PATH"
yarn start
```

### **Terminal 2 (SSH Tunnel):**
```bash
sshpass -p "SANTANUPATLA" ssh -L 3000:localhost:3000 -L 7007:localhost:7007 santanubiswas@192.168.1.102
```

### **Browser:**
```
http://localhost:3000  ← Access Backstage from your laptop
```

## 🎯 **Why This Works**

- **Remote Machine**: Backstage runs normally on localhost (127.0.0.1)
- **SSH Tunnel**: Forwards your laptop's ports to remote machine's ports
- **Your Browser**: Connects to localhost:3000 on your laptop, which tunnels to remote Backstage

## 🔧 **Troubleshooting**

### **If Backstage won't start:**
```bash
# Check Node.js and Yarn versions
node --version  # Should show v18.20.8
yarn --version  # Should show 4.4.1

# Try with minimal config
yarn start --config app-config.yaml
```

### **If SSH tunnel fails:**
```bash
# Check if ports are already in use on your laptop
lsof -i :3000
lsof -i :7007

# Kill processes using those ports if needed
kill -9 <PID>
```

### **If you see "Connection Refused":**
- Make sure Backstage is fully started (takes 2-3 minutes)
- Check Backstage logs for errors
- Ensure SSH tunnel is active

## ✅ **Benefits of SSH Tunnel Approach**

1. **Simple**: No complex network configuration needed
2. **Secure**: Traffic encrypted through SSH
3. **Reliable**: Works regardless of firewall settings
4. **Familiar**: Standard SSH port forwarding technique

## 🎉 **Expected Result**

Once working, you should see:
- **Backstage Home Page** at `http://localhost:3000`
- **MSDP Service Catalog** with all your microservices
- **Professional Admin Interface** for managing your platform

---

**This approach bypasses all network configuration issues and gets you access to Backstage immediately!** 🚀
