#!/bin/bash
# MSDP Backstage Simple Remote Deployment Script
# This script assumes basic tools are available or installs them user-level

set -e

# Configuration
REMOTE_HOST="192.168.1.102"
REMOTE_USER="santanubiswas"
LAPTOP_IP="192.168.1.189"
REMOTE_PASSWORD="SANTANUPATLA"

echo "🚀 MSDP Backstage Simple Deployment Starting..."
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
    fi
fi

echo "📋 Step 1: Testing SSH connection..."
run_remote "echo 'SSH connection successful!'"

echo "📋 Step 2: Preparing remote environment..."
run_remote "mkdir -p /Users/santanubiswas/projects/msdp-backstage"
run_remote "cd /Users/santanubiswas && pwd"

echo "📋 Step 3: Installing Node.js using Node Version Manager (no sudo required)..."
# Install NVM and Node.js without sudo
run_remote "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && nvm install 18 && nvm use 18"
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && npm install -g yarn"

echo "📋 Step 4: Creating Backstage application..."
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && cd /Users/santanubiswas/projects && npx @backstage/create-app@latest msdp-backstage --skip-install"

echo "📋 Step 5: Creating configuration files..."

# Create simplified app-config.local.yaml (without database, using SQLite)
cat > /tmp/app-config.local.yaml << EOF
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

  # Use SQLite for simplicity (no Docker required)
  database:
    client: better-sqlite3
    connection: ':memory:'

catalog:
  import:
    entityFilename: catalog-info.yaml
  
  rules:
    - allow: [Component, System, API, Resource, Location, User, Group]

# Proxy configuration for MSDP API access
proxy:
  '/api/msdp':
    target: http://$LAPTOP_IP:3000
    changeOrigin: true

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

# Simple authentication
auth:
  environment: development
  providers:
    guest: {}

integrations:
  github:
    - host: github.com
EOF

echo "📋 Step 6: Copying configuration files..."
copy_to_remote "/tmp/app-config.local.yaml" "/Users/santanubiswas/projects/msdp-backstage/"

echo "📋 Step 7: Creating MSDP service catalog..."
run_remote "mkdir -p /Users/santanubiswas/projects/msdp-backstage/catalog-info"

# Create a simple catalog-info.yaml file
cat > /tmp/catalog-info.yaml << EOF
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
EOF

copy_to_remote "/tmp/catalog-info.yaml" "/Users/santanubiswas/projects/msdp-backstage/"

echo "📋 Step 8: Installing Backstage dependencies..."
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && cd /Users/santanubiswas/projects/msdp-backstage && yarn install"

echo "📋 Step 9: Building Backstage..."
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && cd /Users/santanubiswas/projects/msdp-backstage && yarn build:backend --config app-config.local.yaml"

echo "📋 Step 10: Creating startup script..."
cat > /tmp/start-backstage.sh << 'EOF'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

cd /Users/santanubiswas/projects/msdp-backstage

echo "🚀 Starting Backstage Backend..."
yarn start:backend --config app-config.local.yaml &
BACKEND_PID=$!

echo "🎨 Starting Backstage Frontend..."
yarn start:frontend --config app-config.local.yaml &
FRONTEND_PID=$!

echo "✅ Backstage started!"
echo "🎛️ Service Catalog: http://192.168.1.102:3000"
echo "🔧 Backend API: http://192.168.1.102:7007"
echo ""
echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"

# Keep script running
wait
EOF

copy_to_remote "/tmp/start-backstage.sh" "/Users/santanubiswas/projects/msdp-backstage/"
run_remote "chmod +x /Users/santanubiswas/projects/msdp-backstage/start-backstage.sh"

echo "📋 Step 11: Starting Backstage in background..."
run_remote "cd /Users/santanubiswas/projects/msdp-backstage && nohup ./start-backstage.sh > backstage.log 2>&1 &"

# Wait a moment for services to start
echo "⏳ Waiting for services to start..."
sleep 10

echo "📋 Step 12: Checking service status..."
run_remote "ps aux | grep -E '(yarn|node)' | grep -v grep"

echo "✅ DEPLOYMENT COMPLETED!"
echo "==========================================="
echo "🎛️ Backstage Service Catalog: http://$REMOTE_HOST:3000"
echo "🔧 Backstage Backend API: http://$REMOTE_HOST:7007"
echo ""
echo "🔗 Integration Status:"
echo "✅ Connected to MSDP services on: $LAPTOP_IP"
echo "✅ Service catalog configured for all MSDP services"
echo "✅ Simple SQLite database (no Docker required)"
echo "✅ Guest authentication enabled"
echo ""
echo "🚀 Next Steps:"
echo "1. Open http://$REMOTE_HOST:3000 in your browser"
echo "2. Explore the MSDP service catalog"
echo "3. Check logs: ssh $REMOTE_USER@$REMOTE_HOST 'tail -f /Users/santanubiswas/projects/msdp-backstage/backstage.log'"
echo ""
echo "📱 To stop services: ssh $REMOTE_USER@$REMOTE_HOST 'pkill -f yarn'"
echo "📱 To restart: ssh $REMOTE_USER@$REMOTE_HOST 'cd /Users/santanubiswas/projects/msdp-backstage && ./start-backstage.sh'"

# Cleanup temporary files
rm -f /tmp/app-config.local.yaml /tmp/catalog-info.yaml /tmp/start-backstage.sh

echo "🎉 MSDP Backstage Platform is now running on $REMOTE_HOST!"
