# Backstage Step 2: Configuration for MSDP Integration

## 🎯 **Step 2: Post-Installation Configuration**

Following official Backstage documentation for configuration:
- https://backstage.io/docs/conf/
- https://backstage.io/docs/auth/
- https://backstage.io/docs/features/software-catalog/

---

## 🔧 **Configuration Tasks**

### **Task 1: Enhanced Authentication Configuration**
### **Task 2: MSDP Service Catalog Setup**
### **Task 3: API Proxy Configuration for MSDP Services**
### **Task 4: Database Configuration**
### **Task 5: Essential Plugins Setup**

---

## 📋 **Task 1: Enhanced Authentication Configuration**

### **Current Status:**
- ✅ Guest authentication working
- 🔧 Need to add GitHub OAuth for production

### **Commands for Remote Machine (192.168.1.102):**

#### **1.1: Stop current Backstage**
```bash
# In your SSH session:
Ctrl+C
```

#### **1.2: Create enhanced auth configuration**
```bash
cd /Users/santanubiswas/projects/msdp-backstage-remote

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
      - http://192.168.1.189:*  # Your laptop IP
      - http://localhost:*
    credentials: true

  database:
    client: better-sqlite3
    connection: ':memory:'

auth:
  environment: development
  providers:
    guest: {}
    # GitHub OAuth (optional - for production)
    # github:
    #   development:
    #     clientId: ${GITHUB_CLIENT_ID}
    #     clientSecret: ${GITHUB_CLIENT_SECRET}

catalog:
  import:
    entityFilename: catalog-info.yaml
  
  rules:
    - allow: [Component, System, API, Resource, Location, User, Group]

  locations:
    - type: file
      target: ./catalog-info/msdp-services.yaml

# API Proxies for MSDP Services (Your laptop: 192.168.1.189)
proxy:
  '/api/msdp':
    target: http://192.168.1.189:3000
    changeOrigin: true
    headers:
      X-Forwarded-Host: $host

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

integrations:
  github:
    - host: github.com
      # token: ${GITHUB_TOKEN}  # Optional for private repos

techdocs:
  builder: 'local'
  generator:
    runIn: 'local'
  publisher:
    type: 'local'
EOF
```

#### **1.3: Copy to packages**
```bash
cp app-config.local.yaml packages/app/
cp app-config.local.yaml packages/backend/
```

---

## 📋 **Task 2: MSDP Service Catalog Setup**

#### **2.1: Create MSDP service catalog directory**
```bash
mkdir -p catalog-info
```

#### **2.2: Create MSDP services catalog**
```bash
cat > catalog-info/msdp-services.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: msdp-platform
  description: Microservice Delivery Platform
  tags:
    - platform
    - microservices
    - nodejs
spec:
  owner: platform-team
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: api-gateway
  description: MSDP API Gateway
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - nodejs
    - gateway
    - msdp-core
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - msdp-gateway-api
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: location-service
  description: MSDP Location Management Service
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - nodejs
    - microservice
    - location
    - msdp-core
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - location-api
  dependsOn:
    - resource:location-database
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: merchant-service
  description: MSDP Merchant/VendaBuddy Service
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - nodejs
    - microservice
    - merchant
    - vendabuddy
    - msdp-core
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - merchant-api
  dependsOn:
    - resource:merchant-database
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: user-service
  description: MSDP User Management Service
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - nodejs
    - microservice
    - user
    - authentication
    - msdp-core
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - user-api
  dependsOn:
    - resource:user-database
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: order-service
  description: MSDP Order Management Service
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - nodejs
    - microservice
    - order
    - ecommerce
    - msdp-core
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - order-api
  dependsOn:
    - resource:order-database
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payment-service
  description: MSDP Payment Processing Service
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - nodejs
    - microservice
    - payment
    - fintech
    - msdp-core
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - payment-api
  dependsOn:
    - resource:payment-database
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: customer-app
  description: MSDP Customer Web Application
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - nextjs
    - frontend
    - customer
    - webapp
spec:
  type: website
  lifecycle: production
  owner: frontend-team
  system: msdp-platform
  consumesApis:
    - msdp-gateway-api
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: vendabuddy-app
  description: MSDP VendaBuddy Merchant Application
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - nextjs
    - frontend
    - merchant
    - vendabuddy
    - webapp
spec:
  type: website
  lifecycle: production
  owner: frontend-team
  system: msdp-platform
  consumesApis:
    - msdp-gateway-api
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: admin-dashboard
  description: MSDP Admin Dashboard
  annotations:
    backstage.io/techdocs-ref: dir:.
  tags:
    - nextjs
    - frontend
    - admin
    - dashboard
spec:
  type: website
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  consumesApis:
    - msdp-gateway-api
---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: msdp-gateway-api
  description: MSDP API Gateway REST API
spec:
  type: openapi
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  definition:
    $text: http://192.168.1.189:3000/api/docs
---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: location-api
  description: Location Service REST API
spec:
  type: openapi
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  definition:
    $text: http://192.168.1.189:3001/api/docs
---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: merchant-api
  description: Merchant Service REST API
spec:
  type: openapi
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  definition:
    $text: http://192.168.1.189:3002/api/docs
---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: user-api
  description: User Service REST API
spec:
  type: openapi
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  definition:
    $text: http://192.168.1.189:3003/api/docs
---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: order-api
  description: Order Service REST API
spec:
  type: openapi
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  definition:
    $text: http://192.168.1.189:3006/api/docs
---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: payment-api
  description: Payment Service REST API
spec:
  type: openapi
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  definition:
    $text: http://192.168.1.189:3007/api/docs
EOF
```

#### **2.3: Create teams and ownership structure**
```bash
cat > catalog-info/msdp-teams.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: platform-team
  description: MSDP Platform Engineering Team
spec:
  type: team
  children: []
---
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: frontend-team
  description: MSDP Frontend Development Team
spec:
  type: team
  children: []
---
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: admin
  description: MSDP Platform Administrator
spec:
  memberOf: [platform-team]
EOF
```

---

## 📋 **Task 3: Start Configured Backstage**

#### **3.1: Copy configurations**
```bash
cp app-config.local.yaml packages/app/
cp app-config.local.yaml packages/backend/
```

#### **3.2: Start Backstage with full configuration**
```bash
export BACKSTAGE_APP_CONFIG_app_listen_host=0.0.0.0
export BACKSTAGE_APP_CONFIG_backend_listen_host=0.0.0.0
yarn start --config app-config.local.yaml
```

---

## 🎯 **Expected Results After Configuration**

### **✅ What You Should See:**
1. **Service Catalog**: All MSDP services visible
2. **API Documentation**: Links to your service APIs
3. **System Overview**: MSDP platform architecture
4. **Teams**: Platform and frontend teams
5. **Network Access**: Accessible from your laptop

### **🌐 Access Points:**
- **Backstage UI**: http://192.168.1.102:3000
- **Service Catalog**: All MSDP microservices listed
- **API Proxies**: Direct access to your laptop services

---

## 🚀 **Let's Start Configuration!**

**Run the commands above step by step on your remote machine (192.168.1.102).**

**Start with Task 1.1 (stopping current Backstage) and let me know when you complete each task!** 

This will transform your basic Backstage into a fully configured MSDP service catalog! 🎯
