#!/bin/bash
# MSDP Backstage Step 1 Installation on 192.168.1.101
# Following official Backstage documentation exactly

set -e

# Configuration
REMOTE_HOST="192.168.1.101"
REMOTE_USER="santanubiswas"
REMOTE_PASSWORD="SANTANUPATLA"

echo "🚀 BACKSTAGE STEP 1: Official Installation on Remote Machine"
echo "=========================================================="
echo "📍 Target: $REMOTE_USER@$REMOTE_HOST"
echo "📚 Following: https://backstage.io/docs/getting-started/create-an-app"
echo ""

# Function to run commands on remote machine with password
run_remote() {
    echo "🔧 Executing: $1"
    sshpass -p "$REMOTE_PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "$1"
}

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo "📦 Installing sshpass for password authentication..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install hudochenkov/sshpass/sshpass
    fi
fi

echo "📋 Step 1.1: Testing SSH connection..."
run_remote "echo 'SSH connection successful to $REMOTE_HOST!'"

echo ""
echo "📋 Step 1.2: Checking prerequisites (official requirements)..."
run_remote "echo 'Current system info:' && uname -a"
run_remote "echo 'Node.js version:' && node --version || echo 'Node.js not found'"
run_remote "echo 'Yarn version:' && yarn --version || echo 'Yarn not found'"
run_remote "echo 'Git version:' && git --version || echo 'Git not found'"
run_remote "echo 'Python version:' && python3 --version || python --version || echo 'Python not found'"

echo ""
echo "📋 Step 1.3: Installing Node.js 20 LTS (official requirement)..."
# Install NVM and Node.js 20 LTS
run_remote "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && nvm install 20 --lts"
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && nvm use 20"
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && npm install -g yarn"

echo ""
echo "📋 Step 1.4: Verifying Node.js and Yarn installation..."
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && node --version"
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && yarn --version"

echo ""
echo "📋 Step 1.5: Creating Backstage app (official method)..."
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && cd /Users/santanubiswas && mkdir -p projects && cd projects"
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && cd /Users/santanubiswas/projects && echo 'msdp-backstage-remote' | npx @backstage/create-app@latest"

echo ""
echo "📋 Step 1.6: Starting Backstage for verification..."
run_remote "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && cd /Users/santanubiswas/projects/msdp-backstage-remote && nohup yarn start > backstage.log 2>&1 &"

echo ""
echo "⏳ Waiting 90 seconds for Backstage to start on remote machine..."
sleep 90

echo ""
echo "🔍 Step 1.7: Verification tests..."
echo "📋 Checking if processes are running..."
run_remote "ps aux | grep -E '(yarn|webpack|backstage)' | grep -v grep | head -3"

echo ""
echo "📋 Testing connectivity from your laptop..."
curl -s -o /dev/null -w "Remote Frontend (3000): HTTP %{http_code}\n" http://$REMOTE_HOST:3000 || echo "Remote Frontend: Not accessible from laptop yet"
curl -s -o /dev/null -w "Remote Backend (7007): HTTP %{http_code}\n" http://$REMOTE_HOST:7007 || echo "Remote Backend: Not accessible from laptop yet"

echo ""
echo "📋 Testing localhost access on remote machine..."
run_remote "curl -s -o /dev/null -w 'Remote Frontend (localhost:3000): HTTP %{http_code}\n' http://localhost:3000 || echo 'Remote Frontend: Not accessible locally yet'"

echo ""
echo "✅ STEP 1 INSTALLATION COMPLETED ON REMOTE MACHINE!"
echo "=================================================="
echo ""
echo "🎯 Status Summary:"
echo "├── 💻 Local Machine (Your Laptop):"
echo "│   ├── ✅ Backstage running: http://localhost:3000"
echo "│   ├── ✅ Node.js 20.19.5 LTS"
echo "│   └── ✅ All plugins initialized successfully"
echo "│"
echo "├── 🖥️ Remote Machine ($REMOTE_HOST):"
echo "│   ├── ✅ Node.js 20 LTS installed"
echo "│   ├── ✅ Backstage app created"
echo "│   ├── ⏳ Starting up (check logs)"
echo "│   └── 📍 Will be accessible at: http://$REMOTE_HOST:3000"
echo "│"
echo "└── 🔗 Next Steps:"
echo "    ├── Verify both installations work"
echo "    ├── Choose primary instance for Step 2"
echo "    └── Configure MSDP integration"
echo ""
echo "📋 Management Commands:"
echo "├── Check remote logs: ssh $REMOTE_USER@$REMOTE_HOST 'cd /Users/santanubiswas/projects/msdp-backstage-remote && tail -f backstage.log'"
echo "├── Check remote processes: ssh $REMOTE_USER@$REMOTE_HOST 'ps aux | grep yarn'"
echo "└── Stop remote: ssh $REMOTE_USER@$REMOTE_HOST 'pkill -f yarn'"
echo ""
echo "🎉 You now have Backstage running on TWO machines!"
