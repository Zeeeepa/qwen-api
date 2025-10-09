#!/bin/bash
set -e

# ============================================
# Z.AI2API - One-Command Deployment Script
# OpenAI-Compatible Multi-Provider API Gateway
# ============================================

BRANCH="${1:-main}"
REPO="https://github.com/Zeeeepa/qwen-api.git"
INSTALL_DIR="qwen-api"

echo "🚀 Starting Z.AI2API Deployment..."
echo "📦 Branch: $BRANCH"
echo ""

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    echo "   Please install Python 3.10+ and try again."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VERSION="3.10"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Python $REQUIRED_VERSION or higher is required (found: $PYTHON_VERSION)"
    exit 1
fi

echo "✅ Python $PYTHON_VERSION detected"

# Clone repository
echo ""
echo "📥 Cloning repository..."
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️  Directory $INSTALL_DIR already exists. Removing..."
    rm -rf "$INSTALL_DIR"
fi

git clone --depth 1 -b "$BRANCH" "$REPO" "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "✅ Repository cloned successfully"

# Create virtual environment
echo ""
echo "🔧 Setting up virtual environment..."
python3 -m venv .venv
source .venv/bin/activate

echo "✅ Virtual environment created"

# Install dependencies
echo ""
echo "📦 Installing dependencies (this may take a few minutes)..."
pip install --upgrade pip > /dev/null 2>&1
pip install -e . > /dev/null 2>&1

# Install Playwright browsers
echo ""
echo "🎭 Installing Playwright browsers..."
playwright install chromium > /dev/null 2>&1

echo "✅ Dependencies installed successfully"

# Setup environment configuration
echo ""
echo "⚙️  Setting up environment configuration..."

if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ Created .env file from template"
    
    # Configure default settings for quick start
    cat >> .env << 'EOF'

# Quick Start Configuration (Added by deployment script)
LISTEN_PORT=8080
SKIP_AUTH_TOKEN=true
DEBUG_LOGGING=true
ANONYMOUS_MODE=true
EOF
    
    echo ""
    echo "⚠️  IMPORTANT: Edit .env file with your Qwen credentials!"
    echo ""
    echo "   Required: Set ONE of these authentication methods:"
    echo "   1. QWEN_BEARER_TOKEN=... (Recommended - fastest)"
    echo "   2. QWEN_EMAIL=... and QWEN_PASSWORD=... (Automated login)"
    echo ""
    echo "   Quick edit: nano .env"
    echo ""
else
    echo "✅ .env file already exists"
fi

# Create start script
echo "📝 Creating start script..."
cat > start_server.sh << 'EOFSTART'
#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
exec python3 main.py
EOFSTART
chmod +x start_server.sh

echo "✅ Start script created"

# Create systemd service file (optional)
cat > qwen-api.service << 'EOFSERVICE'
[Unit]
Description=Z.AI2API - OpenAI-Compatible Multi-Provider Gateway
After=network.target

[Service]
Type=simple
User=%USER%
WorkingDirectory=%WORKDIR%
ExecStart=%WORKDIR%/start_server.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Replace placeholders in service file
sed -i "s|%USER%|$USER|g" qwen-api.service
sed -i "s|%WORKDIR%|$(pwd)|g" qwen-api.service

echo "✅ Systemd service file created (qwen-api.service)"

# Print deployment summary
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🎉 Z.AI2API Deployed Successfully! 🎉               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Installation Directory: $(pwd)"
echo "🌐 Default Server URL: http://localhost:8080"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  NEXT STEPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  Configure your Qwen credentials:"
echo "   nano .env"
echo ""
echo "   Add ONE of these authentication methods:"
echo "   • QWEN_BEARER_TOKEN=... (Recommended - fastest)"
echo "   • QWEN_EMAIL=... and QWEN_PASSWORD=..."
echo ""
echo "2️⃣  Start the server:"
echo "   ./start_server.sh"
echo ""
echo "   Or run in background:"
echo "   nohup ./start_server.sh > server.log 2>&1 &"
echo ""
echo "3️⃣  Test the API:"
echo "   curl http://localhost:8080/health"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📖 OPTIONAL: Install as systemd service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   sudo cp qwen-api.service /etc/systemd/system/"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable qwen-api"
echo "   sudo systemctl start qwen-api"
echo "   sudo systemctl status qwen-api"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 USEFUL COMMANDS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "View logs:    tail -f server.log"
echo "Stop server:  pkill -f 'python3 main.py'"
echo "Restart:      ./start_server.sh"
echo "Health check: curl http://localhost:8080/health"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 Documentation: https://github.com/Zeeeepa/qwen-api"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 OpenAI-Compatible Endpoint: http://localhost:8080/v1"
echo ""
echo "   Example usage with OpenAI SDK:"
echo "   --------------------------------"
echo "   from openai import OpenAI"
echo "   client = OpenAI("
echo "       api_key='any-key',  # No validation needed"
echo "       base_url='http://localhost:8080/v1'"
echo "   )"
echo "   response = client.chat.completions.create("
echo "       model='qwen-max',"
echo "       messages=[{'role': 'user', 'content': 'Hello!'}]"
echo "   )"
echo ""
echo "✨ Happy coding!"
echo ""

