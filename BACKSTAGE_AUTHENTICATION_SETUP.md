# Backstage Authentication Setup for MSDP

## 🔐 **Why You're Logging in as Guest**

### **Current Configuration:**
```yaml
auth:
  environment: development
  providers:
    guest: {}  # ← Only guest authentication enabled
```

**Result**: Only guest access available, no admin authentication configured yet.

---

## 🎯 **Authentication Options for MSDP Backstage**

### **Option 1: GitHub OAuth (Recommended)**
**Best for production and team collaboration**

### **Option 2: Local Admin User**
**Simple admin account for development**

### **Option 3: Corporate SSO**
**Enterprise authentication (LDAP, SAML, etc.)**

---

## 🔧 **Setup Option 1: GitHub OAuth Authentication**

### **Step 1: Create GitHub OAuth App**

1. **Go to GitHub**: https://github.com/settings/developers
2. **Click**: "New OAuth App"
3. **Fill in**:
   - **Application name**: `MSDP Backstage`
   - **Homepage URL**: `http://192.168.1.102:3000`
   - **Authorization callback URL**: `http://192.168.1.102:7007/api/auth/github/handler/frame`
4. **Save** and copy `Client ID` and `Client Secret`

### **Step 2: Configure Backstage for GitHub Auth**

**Run on remote machine (192.168.1.102):**

```bash
cd /Users/santanubiswas/projects/msdp-backstage-remote

# Stop current Backstage
pkill -f 'yarn.*start' || fg (then Ctrl+C)

# Create enhanced auth configuration
cat > app-config.local.yaml << 'EOF'
app:
  title: MSDP Service Catalog
  baseUrl: http://192.168.1.102:3000
  listen:
    host: 0.0.0.0
    port: 3000

organization:
  name: MSDP Platform

backend:
  baseUrl: http://192.168.1.102:7007
  listen:
    host: 0.0.0.0
    port: 7007
  
  cors:
    origin: 
      - http://192.168.1.102:3000
      - http://192.168.1.189:*
      - http://localhost:*
    credentials: true

  database:
    client: better-sqlite3
    connection: ':memory:'

auth:
  environment: development
  providers:
    guest: {}
    github:
      development:
        clientId: YOUR_GITHUB_CLIENT_ID
        clientSecret: YOUR_GITHUB_CLIENT_SECRET
        signIn:
          resolvers:
            - resolver: emailMatchingUserEntityName

catalog:
  rules:
    - allow: [Component, System, API, Resource, Location, User, Group]
  locations:
    - type: file
      target: ./catalog-info/msdp-services.yaml
    - type: file
      target: ./catalog-info/msdp-users.yaml

proxy:
  '/api/msdp':
    target: http://192.168.1.189:3000
    changeOrigin: true
  '/api/location':
    target: http://192.168.1.189:3001
    changeOrigin: true
  '/api/merchant':
    target: http://192.168.1.189:3002
    changeOrigin: true
  '/api/user':
    target: http://192.168.1.189:3003
    changeOrigin: true
  '/api/order':
    target: http://192.168.1.189:3006
    changeOrigin: true
  '/api/payment':
    target: http://192.168.1.189:3007
    changeOrigin: true
EOF
```

### **Step 3: Create Admin User Catalog**

```bash
cat > catalog-info/msdp-users.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: platform-admins
  description: MSDP Platform Administrators
spec:
  type: team
  children: []
---
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: global-admins
  description: MSDP Global Administrators
spec:
  type: team
  children: []
---
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: santanu
  description: MSDP Platform Owner
spec:
  profile:
    displayName: Santanu Biswas
    email: your-email@example.com
  memberOf: 
    - platform-admins
    - global-admins
EOF
```

---

## 🔧 **Setup Option 2: Simple Local Admin (Easier)**

### **For Development/Testing - No GitHub Required**

```yaml
# Simpler auth configuration
auth:
  environment: development
  providers:
    guest: {}
    # Simple local auth
    localdev:
      development:
        users:
          - name: admin
            displayName: MSDP Admin
            email: admin@msdp.local
            memberOf: [platform-admins]
          - name: santanu
            displayName: Santanu Biswas  
            email: santanu@msdp.local
            memberOf: [platform-admins, global-admins]
```

---

## 🎯 **Quick Fix: Add Admin User to Current Setup**

### **Simplest Approach - Run on Remote Machine:**

```bash
# Add admin user to existing guest setup
cat > catalog-info/admin-user.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: admin
  description: MSDP Administrator
spec:
  profile:
    displayName: MSDP Admin
    email: admin@msdp.local
  memberOf: [platform-team]
EOF

# Restart Backstage
yarn start --config app-config.local.yaml
```

---

## 💡 **Recommendation**

### **For Now (Quick Solution):**
- **Keep guest authentication** for immediate exploration
- **Add admin user entity** to the catalog
- **Explore current functionality** 

### **For Production (Later):**
- **Set up GitHub OAuth** for proper authentication
- **Configure team permissions** and access control
- **Integrate with your organization's auth**

**Would you like to:**
1. **Continue exploring with guest access** (easiest)
2. **Set up GitHub OAuth now** (more secure)
3. **Add simple admin user** (middle ground)

**What's your preference for authentication?** 🚀
