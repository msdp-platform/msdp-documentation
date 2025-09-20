# Backstage Remote Manual Setup Guide (192.168.1.102)

## 🎯 **Step-by-Step Manual Commands**

Follow these commands exactly in your terminal to check and complete the remote Backstage setup.

---

## 📋 **Step 1: Check Current Remote Status**

### **Command 1: SSH into the remote machine**
```bash
ssh santanubiswas@192.168.1.102
# Enter password: SANTANUPATLA
```

### **Command 2: Check what was created**
```bash
cd /Users/santanubiswas/projects
ls -la
```
**Expected**: You should see `msdp-backstage-remote` directory if creation completed

### **Command 3: Check Node.js and Yarn**
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
node --version
yarn --version
```
**Expected**: Node.js v20.19.5 and Yarn version

---

## 📋 **Step 2: Complete Backstage Installation (if needed)**

### **If Backstage app doesn't exist, create it:**
```bash
cd /Users/santanubiswas/projects
npx @backstage/create-app@latest
# When prompted, enter: msdp-backstage-remote
```

### **If Backstage app exists, navigate to it:**
```bash
cd /Users/santanubiswas/projects/msdp-backstage-remote
ls -la
```

---

## 📋 **Step 3: Start Backstage (Official Method)**

### **Command: Start Backstage following official docs**
```bash
cd /Users/santanubiswas/projects/msdp-backstage-remote
yarn start
```

**Expected Output:**
- `Starting app, backend`
- `Loaded config from app-config.yaml`
- `Project is running at: http://localhost:3000/`
- Various plugin initialization messages
- No critical errors

---

## 📋 **Step 4: Verification Tests**

### **Open a NEW terminal on your laptop and test:**

### **Command 1: Test direct access (may not work due to network binding)**
```bash
curl http://192.168.1.102:3000
```

### **Command 2: Create SSH tunnel for access**
```bash
ssh -L 3001:localhost:3000 -L 7008:localhost:7007 santanubiswas@192.168.1.102
# Enter password: SANTANUPATLA
# Keep this terminal open
```

### **Command 3: Test via SSH tunnel**
```bash
# In another terminal on your laptop:
curl http://localhost:3001
```

### **Command 4: Open in browser**
```
http://localhost:3001  (via SSH tunnel)
```

---

## 📋 **Step 5: Status Check Commands**

### **On the remote machine, check processes:**
```bash
ps aux | grep -E "(yarn|node|webpack)" | grep -v grep
```

### **Check logs if needed:**
```bash
cd /Users/santanubiswas/projects/msdp-backstage-remote
# If running in background, check logs:
tail -f backstage.log
```

---

## 🎯 **Expected Results**

### **✅ Success Indicators:**
- Backstage starts without critical errors
- Frontend serves HTML content
- Backend initializes all plugins
- No module errors (like isolated-vm)
- Accessible via SSH tunnel

### **❌ Common Issues:**
- **Module errors**: Usually Node.js version incompatibility
- **Network access**: Frontend only binds to localhost by default
- **Port conflicts**: If ports 3000/7007 are in use

---

## 🚀 **Quick Commands Summary**

```bash
# 1. SSH into remote
ssh santanubiswas@192.168.1.102

# 2. Set up Node.js environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# 3. Navigate to projects
cd /Users/santanubiswas/projects

# 4. Check/create Backstage app
ls -la
# If needed: npx @backstage/create-app@latest

# 5. Start Backstage
cd msdp-backstage-remote
yarn start
```

---

## 💡 **Next Steps After Verification**

Once remote Backstage is working:
1. **Choose primary instance** (local vs remote)
2. **Proceed to Step 2**: Configuration
3. **Configure MSDP integration**
4. **Set up service catalog**

**Start with Command 1 and let me know what you see at each step!** 🚀
