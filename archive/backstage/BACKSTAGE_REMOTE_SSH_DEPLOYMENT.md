# Backstage Remote SSH Deployment Guide

## 🔒 **Security Notice**

**⚠️ Important Security Considerations:**

1. **Password Exposure**: Avoid sharing passwords in documentation or chat
2. **SSH Security**: Consider using SSH keys instead of passwords
3. **Network Security**: Ensure the target machine is on a trusted network
4. **Access Control**: Implement proper firewall rules

## 🎯 **Remote Deployment Strategy**

### **Target Machine Setup:**
- **Host**: 192.168.1.102
- **User**: santanubiswas
- **Purpose**: Backstage service catalog and admin platform
- **Network**: Same subnet as MSDP services

## 🚀 **Deployment Steps**

### **Step 1: Secure SSH Connection**

```bash
# Test SSH connection first
ssh santanubiswas@192.168.1.102

# For better security, consider setting up SSH keys
ssh-keygen -t rsa -b 4096 -C "msdp-backstage-deployment"
ssh-copy-id santanubiswas@192.168.1.102
```

### **Step 2: Remote System Preparation**

```bash
# Connect to remote machine
ssh santanubiswas@192.168.1.102

# Update system
sudo apt update && sudo apt upgrade -y  # For Ubuntu/Debian
# OR
sudo yum update -y  # For CentOS/RHEL
# OR
brew update  # For macOS

# Install required dependencies
# Node.js (v18 or higher)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Git
sudo apt install git -y

# Yarn (recommended for Backstage)
npm install -g yarn
```

### **Step 3: Clone MSDP Repository**

```bash
# On remote machine (192.168.1.102)
cd /home/santanubiswas
mkdir -p projects
cd projects

# Clone the platform repository
git clone https://github.com/your-org/msdp-platform-core.git
cd msdp-platform-core

# Create Backstage directory
mkdir backstage-deployment
cd backstage-deployment
```

### **Step 4: Create Backstage Instance**

```bash
# On remote machine
npx @backstage/create-app@latest msdp-backstage --skip-install
cd msdp-backstage

# Install dependencies
yarn install
```

### **Step 5: Configure for MSDP Integration**

```bash
# Create network configuration
cat > app-config.production.yaml << 'EOF'
app:
  title: MSDP Service Catalog
  baseUrl: http://192.168.1.102:3000

organization:
  name: MSDP Platform

backend:
  # Bind to all interfaces for network access
  listen:
    port: 3000
    host: 0.0.0.0
  
  # Base URL for backend
  baseUrl: http://192.168.1.102:7007
  
  # CORS configuration for MSDP services
  cors:
    origin: 
      - http://192.168.1.100:4000  # Admin Dashboard
      - http://192.168.1.100:4002  # Customer App
      - http://192.168.1.100:4003  # VendaBuddy
      - http://192.168.1.100:3000  # API Gateway
      - http://localhost:3000
    credentials: true

  # Database configuration
  database:
    client: pg
    connection:
      host: localhost
      port: 5432
      user: backstage
      password: backstage_password
      database: backstage_plugin_catalog

# Catalog configuration
catalog:
  import:
    entityFilename: catalog-info.yaml
    pullRequestBranchName: backstage-integration
  
  rules:
    - allow: [Component, System, API, Resource, Location, User, Group]

  providers:
    msdp:
      production:
        # MSDP services running on laptop
        baseUrl: http://192.168.1.100:3000
        services:
          location-service:
            url: http://192.168.1.100:3001
            healthCheck: /health
          merchant-service:
            url: http://192.168.1.100:3002
            healthCheck: /health
          user-service:
            url: http://192.168.1.100:3003
            healthCheck: /health
          order-service:
            url: http://192.168.1.100:3006
            healthCheck: /health
          payment-service:
            url: http://192.168.1.100:3007
            healthCheck: /health

# Proxy configuration for MSDP API access
proxy:
  '/api/msdp':
    target: http://192.168.1.100:3000
    changeOrigin: true
    headers:
      X-Forwarded-Host: $host
      X-Forwarded-Proto: $scheme

  '/api/location':
    target: http://192.168.1.100:3001
    changeOrigin: true
    
  '/api/merchant':
    target: http://192.168.1.100:3002
    changeOrigin: true

  '/api/user':
    target: http://192.168.1.100:3003
    changeOrigin: true

  '/api/order':
    target: http://192.168.1.100:3006
    changeOrigin: true

  '/api/payment':
    target: http://192.168.1.100:3007
    changeOrigin: true

# Authentication (basic setup)
auth:
  environment: production
  providers:
    guest: {}

# Integrations
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN} # Set this as environment variable
EOF
```

### **Step 6: Set Up Database**

```bash
# Create PostgreSQL container for Backstage
cat > docker-compose.backstage.yaml << 'EOF'
version: '3.8'
services:
  backstage-db:
    image: postgres:13
    restart: always
    environment:
      POSTGRES_USER: backstage
      POSTGRES_PASSWORD: backstage_password
      POSTGRES_DB: backstage_plugin_catalog
    ports:
      - "5432:5432"
    volumes:
      - backstage-db-data:/var/lib/postgresql/data

  # Optional: Monitoring stack
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--web.external-url=http://192.168.1.102:9090'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_SERVER_ROOT_URL=http://192.168.1.102:3001
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  backstage-db-data:
  grafana-data:
EOF

# Start the database
docker-compose -f docker-compose.backstage.yaml up -d backstage-db
```

### **Step 7: Create MSDP Service Catalog**

```bash
# Create catalog directory
mkdir -p catalog-info/msdp-services

# Location Service catalog entry
cat > catalog-info/msdp-services/location-service.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: location-service
  description: MSDP Location Management Service
  annotations:
    github.com/project-slug: msdp-platform/msdp-platform-core
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
    $text: http://192.168.1.100:3001/api/docs
EOF

# Merchant Service catalog entry
cat > catalog-info/msdp-services/merchant-service.yaml << 'EOF'
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: merchant-service
  description: MSDP Merchant/VendaBuddy Service
  annotations:
    github.com/project-slug: msdp-platform/msdp-platform-core
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
    $text: http://192.168.1.100:3002/api/docs
EOF

# Create similar files for user-service, order-service, payment-service...
```

### **Step 8: Configure Monitoring**

```bash
# Create Prometheus configuration
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'msdp-services'
    static_configs:
      - targets: 
        - '192.168.1.100:3001'  # Location Service
        - '192.168.1.100:3002'  # Merchant Service
        - '192.168.1.100:3003'  # User Service
        - '192.168.1.100:3006'  # Order Service
        - '192.168.1.100:3007'  # Payment Service
        - '192.168.1.100:3000'  # API Gateway
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'backstage'
    static_configs:
      - targets: ['localhost:7007']
    metrics_path: '/metrics'
    scrape_interval: 30s
EOF
```

### **Step 9: Start Backstage**

```bash
# Set environment variables
export NODE_ENV=production
export GITHUB_TOKEN=your_github_token_here

# Build and start Backstage
yarn build:backend
yarn start:backend &

# In another terminal session
yarn start:frontend &

# Or use PM2 for process management
npm install -g pm2
pm2 start "yarn start:backend" --name backstage-backend
pm2 start "yarn start:frontend" --name backstage-frontend
pm2 save
pm2 startup
```

### **Step 10: Configure Firewall (Optional)**

```bash
# Allow required ports
sudo ufw allow 3000  # Backstage Frontend
sudo ufw allow 7007  # Backstage Backend
sudo ufw allow 9090  # Prometheus
sudo ufw allow 3001  # Grafana
sudo ufw allow 22    # SSH

# Enable firewall
sudo ufw enable
```

## 🔧 **Automated Deployment Script**

```bash
#!/bin/bash
# deploy-backstage-remote.sh

set -e

REMOTE_HOST="192.168.1.102"
REMOTE_USER="santanubiswas"
LAPTOP_IP="192.168.1.100"

echo "🚀 Deploying Backstage to remote machine..."

# Function to run commands on remote machine
run_remote() {
    ssh $REMOTE_USER@$REMOTE_HOST "$1"
}

# Function to copy files to remote machine
copy_to_remote() {
    scp -r "$1" $REMOTE_USER@$REMOTE_HOST:"$2"
}

echo "📋 Step 1: Preparing remote environment..."
run_remote "mkdir -p /home/santanubiswas/projects"

echo "📋 Step 2: Installing dependencies..."
run_remote "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
run_remote "npm install -g yarn"

echo "📋 Step 3: Creating Backstage application..."
run_remote "cd /home/santanubiswas/projects && npx @backstage/create-app@latest msdp-backstage --skip-install"

echo "📋 Step 4: Configuring Backstage..."
# Copy configuration files
copy_to_remote "app-config.production.yaml" "/home/santanubiswas/projects/msdp-backstage/"
copy_to_remote "docker-compose.backstage.yaml" "/home/santanubiswas/projects/msdp-backstage/"
copy_to_remote "catalog-info/" "/home/santanubiswas/projects/msdp-backstage/"

echo "📋 Step 5: Installing and starting services..."
run_remote "cd /home/santanubiswas/projects/msdp-backstage && yarn install"
run_remote "cd /home/santanubiswas/projects/msdp-backstage && docker-compose -f docker-compose.backstage.yaml up -d"

echo "📋 Step 6: Building and starting Backstage..."
run_remote "cd /home/santanubiswas/projects/msdp-backstage && yarn build:backend"
run_remote "cd /home/santanubiswas/projects/msdp-backstage && pm2 start 'yarn start:backend' --name backstage-backend"
run_remote "cd /home/santanubiswas/projects/msdp-backstage && pm2 start 'yarn start:frontend' --name backstage-frontend"

echo "✅ Deployment completed!"
echo "🌐 Access Backstage at: http://$REMOTE_HOST:3000"
echo "📊 Access Grafana at: http://$REMOTE_HOST:3001"
echo "📈 Access Prometheus at: http://$REMOTE_HOST:9090"
```

## 🎯 **Access Points After Deployment**

```
┌─────────────────────────────────────────────────────────────┐
│                    ACCESS ENDPOINTS                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 🎛️ BACKSTAGE (Remote Machine - 192.168.1.102):           │
│ ├── Service Catalog: http://192.168.1.102:3000            │
│ ├── Backend API: http://192.168.1.102:7007                │
│ ├── Grafana: http://192.168.1.102:3001                    │
│ └── Prometheus: http://192.168.1.102:9090                 │
│                                                             │
│ 🚀 MSDP SERVICES (Your Laptop - 192.168.1.100):          │
│ ├── API Gateway: http://192.168.1.100:3000                │
│ ├── Customer App: http://192.168.1.100:4002               │
│ ├── VendaBuddy: http://192.168.1.100:4003                 │
│ └── All Backend Services: http://192.168.1.100:300X       │
│                                                             │
│ 🔄 INTEGRATION:                                            │
│ ├── Backstage manages laptop services remotely             │
│ ├── Cross-network service discovery                        │
│ ├── Unified admin interface                                │
│ └── Real-time monitoring and alerts                       │
└─────────────────────────────────────────────────────────────┘
```

## ⚠️ **Security Recommendations**

1. **Change default passwords** in all configuration files
2. **Set up SSH key authentication** instead of password
3. **Configure firewall rules** to limit access
4. **Use environment variables** for sensitive data
5. **Enable HTTPS** for production usage
6. **Regular security updates** on the remote machine

## 🎯 **Next Steps**

1. **Test SSH connection** to the target machine
2. **Run the deployment script** or follow manual steps
3. **Verify Backstage is accessible** from your network
4. **Configure MSDP services** to report to Backstage
5. **Set up monitoring dashboards** in Grafana

**Would you like me to create the deployment script and help you execute it step by step?** 🚀
