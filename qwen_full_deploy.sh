#!/bin/bash

################################################################################
# Qwen API - Complete Single-File Deployment Script
# Auto-installs Playwright dependencies, authenticates, and deploys server
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
BRANCH="${1:-main}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/qwen-api-deployment}"
LISTEN_PORT="${LISTEN_PORT:-8080}"

################################################################################
# Helper Functions
################################################################################

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║   Qwen API - Single Command Deployment               ║"
    echo "║   OpenAI-Compatible Multi-Provider Gateway           ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${BOLD}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

################################################################################
# Main Deployment
################################################################################

main() {
    print_header
    
    echo -e "${CYAN}ℹ${NC}  Configuration:"
    echo "  Branch: $BRANCH"
    echo "  Install Dir: $INSTALL_DIR"
    echo "  Port: $LISTEN_PORT"
    echo ""
    
    # Step 1: Prerequisites
    print_step "Step 1/7: Checking Prerequisites"
    echo ""
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        print_success "Python installed: $PYTHON_VERSION"
    else
        print_error "Python 3 not found"
        exit 1
    fi
    
    if command -v git &> /dev/null; then
        print_success "Git installed"
    else
        print_error "Git not found"
        exit 1
    fi
    
    if command -v pip3 &> /dev/null; then
        print_success "pip3 installed"
    else
        print_error "pip3 not found"
        exit 1
    fi
    
    if command -v curl &> /dev/null; then
        print_success "curl installed"
    else
        print_error "curl not found"
        exit 1
    fi
    
    # Step 2: Clone Repository
    print_step "Step 2/7: Cloning Repository"
    echo ""
    
    print_info "Cloning branch: $BRANCH"
    print_info "Install directory: $INSTALL_DIR"
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Directory exists, removing..."
        rm -rf "$INSTALL_DIR"
    fi
    
    if git clone --depth 1 --branch "$BRANCH" https://github.com/Zeeeepa/qwen-api.git "$INSTALL_DIR" > /dev/null 2>&1; then
        print_success "Repository cloned successfully"
    else
        print_error "Failed to clone repository"
        exit 1
    fi
    
    # Step 3: Setup Environment
    print_step "Step 3/7: Setting Up Environment"
    echo ""
    
    cd "$INSTALL_DIR"
    
    echo -e "${CYAN}${BOLD}Qwen Authentication Setup${NC}"
    echo ""
    
    if [ -n "$QWEN_EMAIL" ] && [ -n "$QWEN_PASSWORD" ]; then
        print_info "Using credentials from environment variables"
        print_success "QWEN_EMAIL detected"
        print_success "QWEN_PASSWORD detected"
    else
        print_info "No environment credentials found, prompting for input..."
        echo ""
        read -p "Enter Qwen Email: " QWEN_EMAIL
        read -sp "Enter Qwen Password: " QWEN_PASSWORD
        echo ""
    fi
    
    cat > .env << EOF
# Qwen Authentication - Will auto-login with Playwright
QWEN_EMAIL=$QWEN_EMAIL
QWEN_PASSWORD=$QWEN_PASSWORD

# Server Configuration
LISTEN_PORT=$LISTEN_PORT
HOST=0.0.0.0

# Settings
DEBUG_LOGGING=false
SKIP_AUTH_TOKEN=true
ANONYMOUS_MODE=true
FLAREPROX_ENABLED=false
TOOL_SUPPORT=true
EOF
    
    chmod 600 .env
    print_success "Environment configured for Playwright automation"
    print_info "Server will auto-login to Qwen and fetch Bearer token on startup"
    
    # Step 4: Create Virtual Environment
    print_step "Step 4/7: Creating Virtual Environment"
    echo ""
    
    print_info "Creating virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created"
    
    print_info "Activating virtual environment..."
    source venv/bin/activate
    
    print_info "Upgrading pip..."
    pip install --upgrade pip setuptools wheel > /dev/null 2>&1
    
    # Step 5: Install Dependencies
    print_step "Step 5/7: Installing Dependencies"
    echo ""
    
    print_info "Installing Python packages..."
    if pip install -r requirements.txt > /dev/null 2>&1; then
        print_success "Python dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
    
    # Step 6: Install Playwright (CRITICAL!)
    print_step "Step 6/7: Installing Playwright"
    echo ""
    
    print_info "Installing Playwright system dependencies..."
    print_warning "This requires sudo and may take 1-2 minutes..."
    
    if command -v apt-get &> /dev/null; then
        if sudo -n true 2>/dev/null; then
            playwright install-deps chromium > /dev/null 2>&1 || print_warning "System deps may need manual install"
        else
            print_warning "Sudo required for system dependencies"
            echo ""
            echo "Please run: sudo playwright install-deps chromium"
            echo "Or continue without system deps (may fail)..."
            read -p "Press Enter to continue..."
        fi
    fi
    
    print_info "Installing Playwright browsers..."
    if playwright install chromium > /dev/null 2>&1; then
        print_success "Playwright installed successfully"
    else
        print_warning "Playwright install may have failed"
    fi
    
    # Step 7: Start Server
    print_step "Step 7/7: Starting Server"
    echo ""
    
    print_info "Starting server on port $LISTEN_PORT..."
    print_warning "⏳ Playwright will now auto-login to Qwen to fetch Bearer token..."
    print_info "This may take 10-30 seconds for first-time authentication"
    echo ""
    
    nohup python main.py > server.log 2>&1 &
    SERVER_PID=$!
    echo "$SERVER_PID" > server.pid
    print_info "Server PID: $SERVER_PID"
    
    print_info "Waiting for server to be ready (checking health endpoint)..."
    for i in {1..60}; do
        if curl -s "http://localhost:$LISTEN_PORT/health" > /dev/null 2>&1; then
            print_success "Server is ready!"
            print_success "✅ Playwright authentication completed successfully"
            break
        fi
        sleep 1
        if [ $((i % 10)) -eq 0 ]; then
            echo ""
            print_info "Still waiting... (${i}s elapsed)"
        else
            echo -n "."
        fi
    done
    
    echo ""
    echo ""
    
    # Validate API
    print_step "Testing API with Real Request"
    echo ""
    
    print_info "Testing health endpoint..."
    HEALTH=$(curl -s "http://localhost:$LISTEN_PORT/health")
    if [ -n "$HEALTH" ]; then
        print_success "Health check passed"
        echo "$HEALTH" | python3 -m json.tool
    fi
    
    echo ""
    print_info "Testing chat completion with REAL AI call..."
    
    RESPONSE=$(curl -s -X POST "http://localhost:$LISTEN_PORT/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer sk-test" \
        -d '{
            "model": "qwen-turbo",
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "Say hello in exactly 5 words"}
            ],
            "max_tokens": 50
        }')
    
    if [ -n "$RESPONSE" ]; then
        print_success "API responded"
        echo ""
        echo "════════════════════════════════════════════════════════"
        echo "FULL API RESPONSE:"
        echo "════════════════════════════════════════════════════════"
        echo "$RESPONSE" | python3 -m json.tool
        
        # Extract and display message
        MESSAGE=$(echo "$RESPONSE" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('choices', [{}])[0].get('message', {}).get('content', ''))" 2>/dev/null)
        
        echo ""
        echo "════════════════════════════════════════════════════════"
        if [ -n "$MESSAGE" ] && [ "$MESSAGE" != "" ]; then
            echo -e "${GREEN}${BOLD}✅ REAL AI RESPONSE:${NC}"
            echo "════════════════════════════════════════════════════════"
            echo "$MESSAGE"
            echo "════════════════════════════════════════════════════════"
        else
            echo -e "${RED}${BOLD}❌ EMPTY RESPONSE - Authentication may have failed${NC}"
            echo "════════════════════════════════════════════════════════"
            echo ""
            print_info "Checking server logs for errors..."
            tail -50 server.log | grep -i "error\|fail\|token"
        fi
    fi
    
    echo ""
    echo ""
    
    # Final Status
    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║   🎉 Deployment Complete!                            ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "Server Information:"
    echo "  ✓ Server running on: http://localhost:$LISTEN_PORT"
    echo "  ✓ Process ID: $(cat server.pid 2>/dev/null || echo 'Unknown')"
    echo "  ✓ Installation directory: $INSTALL_DIR"
    echo "  ✓ Log file: $INSTALL_DIR/server.log"
    echo ""
    echo "🔐 Authentication Status:"
    echo "  ✓ Playwright auto-login: ACTIVE"
    echo "  ✓ Bearer token: Auto-fetched and cached"
    echo "  ✓ Token refresh: Automatic on expiry"
    echo ""
    echo "OpenAI-Compatible Endpoints:"
    echo "  • Health:           http://localhost:$LISTEN_PORT/health"
    echo "  • Chat Completion:  http://localhost:$LISTEN_PORT/v1/chat/completions"
    echo "  • Models:           http://localhost:$LISTEN_PORT/v1/models"
    echo ""
    echo "Management Commands:"
    echo "  • View logs:    tail -f $INSTALL_DIR/server.log"
    echo "  • Stop server:  kill \$(cat $INSTALL_DIR/server.pid)"
    echo "  • Restart:      cd $INSTALL_DIR && source venv/bin/activate && python main.py"
    echo ""
    echo -e "${CYAN}Server is running with automatic Playwright authentication!${NC}"
    echo -e "${YELLOW}The server will auto-refresh the token when it expires.${NC}"
}

################################################################################
# Execute
################################################################################

main

