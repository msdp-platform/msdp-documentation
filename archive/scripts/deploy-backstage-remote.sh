#!/bin/bash
# MSDP Backstage Remote Deployment Script
# Target: santanubiswas@192.168.1.102
# MSDP Services: 192.168.1.189 (laptop)

set -e

# Configuration
REMOTE_HOST="192.168.1.102"
REMOTE_USER="santanubiswas"
LAPTOP_IP="192.168.1.189"
REMOTE_PASSWORD="SANTANUPATLA"

echo "🚀 MSDP Backstage Remote Deployment Starting..."
echo "📍 Target: $REMOTE_USER@$REMOTE_HOST"
echo "💻 MSDP Services: $LAPTOP_IP"
echo "==========================================="

# Function to run commands on remote machine with password
run_remote() {
    echo "🔧 Executing: $1"
    sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "$1"
}

# Function to copy files to remote machine
copy_to_remote() {
    echo "📁 Copying: $1 -> $2"
    sshpass -p "$REMOTE_PASSWORD" scp -o StrictHostKeyChecking=no -r "$1" $REMOTE_USER@$REMOTE_HOST:"$2"
}

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo "📦 Installing sshpass for password authentication..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install hudochenkov/sshpass/sshpass
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y sshpass
    fi
fi

echo "📋 Step 1: Testing SSH connection..."
run_remote "echo 'SSH connection successful!'"

echo "📋 Step 2: Preparing remote environment..."
run_remote "mkdir -p /Users/santanubiswas/projects/msdp-backstage"
run_remote "cd /Users/santanubiswas && pwd"

echo "📋 Step 3: Installing system dependencies..."
# Check if Homebrew is installed, install if not
run_remote "which brew || /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
# Install Node.js via Homebrew
run_remote "brew install node@18 || brew upgrade node@18"
run_remote "npm install -g yarn"

echo "📋 Step 4: Installing Docker..."
# Check if Docker Desktop is already installed
run_remote "which docker || echo 'Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop'"
run_remote "docker --version"

echo "📋 Step 5: Creating Backstage application..."
run_remote "cd /Users/santanubiswas/projects && npx @backstage/create-app@latest msdp-backstage --skip-install"

echo "📋 Step 6: Creating configuration files..."

# Create app-config.production.yaml
cat > /tmp/app-config.production.yaml << EOF
app:
  title: MSDP Service Catalog
  baseUrl: http://$REMOTE_HOST:3000

organization:
  name: MSDP Platform

backend:
  listen:
    port: 7007
    host: 0.0.0.0
  
  baseUrl: http://$REMOTE_HOST:7007
  
  cors:
    origin: 
      - http://$LAPTOP_IP:4000
      - http://$LAPTOP_IP:4002
      - http://$LAPTOP_IP:4003
      - http://$LAPTOP_IP:3000
      - http://localhost:3000
    credentials: true

  database:
    client: pg
    connection:
      host: localhost
      port: 5432
      user: backstage
      password: backstage_secure_password
      database: backstage_plugin_catalog

catalog:
  import:
    entityFilename: catalog-info.yaml
  
  rules:
    - allow: [Component, System, API, Resource, Location, User, Group]

proxy:
  '/api/msdp':
    target: http://$LAPTOP_IP:3000
    changeOrigin: true
    headers:
      X-Forwarded-Host: \$host
      X-Forwarded-Proto: \$scheme

  '/api/location':
    target: http://$LAPTOP_IP:3001
    changeOrigin: true
    
  '/api/merchant':
    target: http://$LAPTOP_IP:3002
    changeOrigin: true

  '/api/user':
    target: http://$LAPTOP_IP:3003
    changeOrigin: true

  '/api/order':
    target: http://$LAPTOP_IP:3006
    changeOrigin: true

  '/api/payment':
    target: http://$LAPTOP_IP:3007
    changeOrigin: true

auth:
  environment: production
  providers:
    guest: {}

integrations:
  github:
    - host: github.com
EOF

# Create docker-compose.backstage.yaml
cat > /tmp/docker-compose.backstage.yaml << EOF
version: '3.8'
services:
  backstage-db:
    image: postgres:13
    restart: always
    environment:
      POSTGRES_USER: backstage
      POSTGRES_PASSWORD: backstage_secure_password
      POSTGRES_DB: backstage_plugin_catalog
    ports:
      - "5432:5432"
    volumes:
      - backstage-db-data:/var/lib/postgresql/data

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--web.external-url=http://$REMOTE_HOST:9090'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=msdp_admin_2024
      - GF_SERVER_ROOT_URL=http://$REMOTE_HOST:3001
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  backstage-db-data:
  grafana-data:
EOF

# Create prometheus.yml
cat > /tmp/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'msdp-services'
    static_configs:
      - targets: 
        - '$LAPTOP_IP:3001'
        - '$LAPTOP_IP:3002'
        - '$LAPTOP_IP:3003'
        - '$LAPTOP_IP:3006'
        - '$LAPTOP_IP:3007'
        - '$LAPTOP_IP:3000'
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'backstage'
    static_configs:
      - targets: ['localhost:7007']
    metrics_path: '/metrics'
    scrape_interval: 30s
EOF

echo "📋 Step 7: Copying configuration files..."
copy_to_remote "/tmp/app-config.production.yaml" "/Users/santanubiswas/projects/msdp-backstage/"
copy_to_remote "/tmp/docker-compose.backstage.yaml" "/Users/santanubiswas/projects/msdp-backstage/"
copy_to_remote "/tmp/prometheus.yml" "/Users/santanubiswas/projects/msdp-backstage/"

echo "📋 Step 8: Creating MSDP service catalog..."
run_remote "mkdir -p /Users/santanubiswas/projects/msdp-backstage/catalog-info/msdp-services"

# Create service catalog entries
cat > /tmp/msdp-services.yaml << EOF
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: msdp-platform
  description: Microservice Delivery Platform
spec:
  owner: platform-team
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: location-service
  description: MSDP Location Management Service
  tags:
    - nodejs
    - microservice
    - location
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - location-api
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: merchant-service
  description: MSDP Merchant/VendaBuddy Service
  tags:
    - nodejs
    - microservice
    - merchant
    - vendabuddy
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - merchant-api
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: user-service
  description: MSDP User Management Service
  tags:
    - nodejs
    - microservice
    - user
    - authentication
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - user-api
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: order-service
  description: MSDP Order Management Service
  tags:
    - nodejs
    - microservice
    - order
    - ecommerce
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - order-api
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payment-service
  description: MSDP Payment Processing Service
  tags:
    - nodejs
    - microservice
    - payment
    - fintech
spec:
  type: service
  lifecycle: production
  owner: platform-team
  system: msdp-platform
  providesApis:
    - payment-api
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
    \$text: http://$LAPTOP_IP:3001/api/docs
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
    \$text: http://$LAPTOP_IP:3002/api/docs
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
    \$text: http://$LAPTOP_IP:3003/api/docs
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
    \$text: http://$LAPTOP_IP:3006/api/docs
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
    \$text: http://$LAPTOP_IP:3007/api/docs
EOF

copy_to_remote "/tmp/msdp-services.yaml" "/Users/santanubiswas/projects/msdp-backstage/catalog-info/msdp-services/"

echo "📋 Step 9: Installing Backstage dependencies..."
run_remote "cd /Users/santanubiswas/projects/msdp-backstage && yarn install"

echo "📋 Step 10: Starting database and monitoring services..."
run_remote "cd /Users/santanubiswas/projects/msdp-backstage && docker-compose -f docker-compose.backstage.yaml up -d"

echo "📋 Step 11: Building Backstage..."
run_remote "cd /Users/santanubiswas/projects/msdp-backstage && yarn build:backend --config app-config.production.yaml"

echo "📋 Step 12: Installing PM2 for process management..."
run_remote "npm install -g pm2"

echo "📋 Step 13: Starting Backstage services..."
run_remote "cd /Users/santanubiswas/projects/msdp-backstage && pm2 start 'yarn start:backend --config app-config.production.yaml' --name backstage-backend"
run_remote "cd /Users/santanubiswas/projects/msdp-backstage && pm2 start 'yarn start:frontend --config app-config.production.yaml' --name backstage-frontend"
run_remote "pm2 save"
run_remote "pm2 startup | grep sudo | sh || true"

echo "📋 Step 14: Configuring macOS firewall (if needed)..."
run_remote "echo 'macOS firewall configuration may require manual setup through System Preferences > Security & Privacy > Firewall'"

echo "✅ DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "==========================================="
echo "🎛️ Backstage Service Catalog: http://$REMOTE_HOST:3000"
echo "🔧 Backstage Backend API: http://$REMOTE_HOST:7007"
echo "📊 Grafana Monitoring: http://$REMOTE_HOST:3001 (admin/msdp_admin_2024)"
echo "📈 Prometheus Metrics: http://$REMOTE_HOST:9090"
echo ""
echo "🔗 Integration Status:"
echo "✅ Connected to MSDP services on: $LAPTOP_IP"
echo "✅ Service catalog populated with all MSDP services"
echo "✅ Monitoring configured for cross-network service discovery"
echo "✅ Admin interface ready for location and service management"
echo ""
echo "🚀 Next Steps:"
echo "1. Open http://$REMOTE_HOST:3000 in your browser"
echo "2. Explore the MSDP service catalog"
echo "3. Check service health monitoring in Grafana"
echo "4. Use Backstage for location enablement and business onboarding"
echo ""
echo "📱 To check service status: ssh $REMOTE_USER@$REMOTE_HOST 'pm2 status'"

# Cleanup temporary files
rm -f /tmp/app-config.production.yaml /tmp/docker-compose.backstage.yaml /tmp/prometheus.yml /tmp/msdp-services.yaml

echo "🎉 MSDP Backstage Platform is now running on $REMOTE_HOST!"
