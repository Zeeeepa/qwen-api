#!/usr/bin/env bash
################################################################################
# Qwen API - Complete Single-Command Deployment Script
################################################################################
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/codegen-bot/fix-deployment-env-vars-1760019050/qwen_deploy.sh -o qwen_deploy.sh
#   bash qwen_deploy.sh [branch_name]
#
# Example:
#   bash qwen_deploy.sh codegen-bot/fix-deployment-env-vars-1760019050
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/Zeeeepa/qwen-api.git"
BRANCH="${1:-main}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/qwen-api-deployment}"
LISTEN_PORT="${LISTEN_PORT:-8080}"

################################################################################
# Functions
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
    echo -e "\n${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${BOLD}$1${NC}"
}

print_error() {
    echo -e "${RED}✗${NC} ${BOLD}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
}

separator() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

check_prerequisites() {
    print_step "Step 1/6: Checking Prerequisites"
    separator
    echo ""
    
    # Check Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        print_success "Python installed: $PYTHON_VERSION"
    else
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        print_success "Git installed"
    else
        print_error "Git is required but not installed"
        exit 1
    fi
    
    # Check pip
    if command -v pip3 &> /dev/null; then
        print_success "pip3 installed"
    else
        print_error "pip3 is required but not installed"
        exit 1
    fi
    
    # Check curl
    if command -v curl &> /dev/null; then
        print_success "curl installed"
    else
        print_error "curl is required but not installed"
        exit 1
    fi
}

clone_repository() {
    print_step "Step 2/6: Cloning Repository"
    separator
    echo ""
    
    print_info "Cloning branch: $BRANCH"
    print_info "Install directory: $INSTALL_DIR"
    
    # Remove existing directory if present
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone the repository
    if git clone --depth 1 -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR" > /dev/null 2>&1; then
        print_success "Repository cloned successfully"
    else
        print_error "Failed to clone repository"
        exit 1
    fi
}

setup_environment() {
    print_step "Step 3/6: Setting Up Environment"
    separator
    echo ""
    
    cd "$INSTALL_DIR"
    
    # Collect credentials
    echo -e "${CYAN}${BOLD}Qwen Authentication${NC}"
    echo ""
    echo "Choose authentication method:"
    echo "1) Bearer Token (Recommended - Fast & Reliable)"
    echo "2) Email + Password (Automated Playwright Login)"
    echo ""
    read -p "Enter choice (1 or 2): " AUTH_METHOD
    
    if [ "$AUTH_METHOD" = "1" ]; then
        echo ""
        echo -e "${YELLOW}To get your Bearer Token:${NC}"
        echo "1. Open https://chat.qwen.ai in your browser"
        echo "2. Open Developer Tools (F12)"
        echo "3. Go to Console tab"
        echo "4. Paste and run:"
        echo "   localStorage.getItem('web_api_auth_token')"
        echo ""
        read -p "Enter Bearer Token: " BEARER_TOKEN
        
        cat > .env << EOF
# Qwen Authentication
QWEN_BEARER_TOKEN=$BEARER_TOKEN

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
    else
        echo ""
        read -p "Enter Qwen Email: " QWEN_EMAIL
        read -sp "Enter Qwen Password: " QWEN_PASSWORD
        echo ""
        
        cat > .env << EOF
# Qwen Authentication
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
    fi
    
    chmod 600 .env
    print_success "Environment configured (.env created with secure permissions)"
}

install_dependencies() {
    print_step "Step 4/6: Installing Dependencies"
    separator
    echo ""
    
    cd "$INSTALL_DIR"
    
    print_info "Creating virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created"
    
    print_info "Activating virtual environment..."
    source venv/bin/activate
    
    print_info "Upgrading pip..."
    pip install --upgrade pip setuptools wheel > /dev/null 2>&1
    
    print_info "Installing package and dependencies..."
    if pip install -r requirements.txt > /dev/null 2>&1; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

start_server() {
    print_step "Step 5/6: Starting Server"
    separator
    echo ""
    
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    print_info "Starting server on port $LISTEN_PORT..."
    nohup python main.py > server.log 2>&1 &
    SERVER_PID=$!
    echo "$SERVER_PID" > server.pid
    print_info "Server PID: $SERVER_PID"
    
    print_info "Waiting for server to be ready..."
    for i in {1..30}; do
        if curl -s "http://localhost:$LISTEN_PORT/health" > /dev/null 2>&1; then
            print_success "Server is ready!"
            return 0
        fi
        sleep 1
        echo -n "."
    done
    
    echo ""
    print_error "Server failed to start within 30 seconds"
    print_info "Check server.log for details: $INSTALL_DIR/server.log"
    exit 1
}

validate_api() {
    print_step "Step 6/6: Validating API"
    separator
    echo ""
    
    cd "$INSTALL_DIR"
    
    # Test health endpoint
    print_info "Testing health endpoint..."
    HEALTH_RESPONSE=$(curl -s "http://localhost:$LISTEN_PORT/health")
    if [ -n "$HEALTH_RESPONSE" ]; then
        print_success "Health check passed"
        echo "$HEALTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_RESPONSE"
    else
        print_warning "Health endpoint returned empty response"
    fi
    
    # Test chat completion endpoint
    echo ""
    print_info "Testing chat completion endpoint..."
    
    CHAT_RESPONSE=$(curl -s -X POST "http://localhost:$LISTEN_PORT/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer sk-test" \
        -d '{
            "model": "qwen-turbo",
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "Say hello in exactly 5 words"}
            ],
            "stream": false
        }' 2>/dev/null)
    
    if [ -n "$CHAT_RESPONSE" ]; then
        print_success "Chat completion endpoint responded"
        echo ""
        echo "Response (formatted):"
        echo "$CHAT_RESPONSE" | python3 -m json.tool 2>&1 | head -40
        
        # Extract message
        MESSAGE=$(echo "$CHAT_RESPONSE" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('choices', [{}])[0].get('message', {}).get('content', ''))" 2>/dev/null)
        
        if [ -n "$MESSAGE" ]; then
            echo ""
            print_success "Assistant Response: $MESSAGE"
        fi
    else
        print_warning "Chat completion endpoint returned empty response"
        print_info "This may be normal if credentials need to be configured"
    fi
}

print_final_status() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║   🎉 Deployment Complete!                            ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "Server Information:"
    echo "  ✓ Server running on: http://localhost:$LISTEN_PORT"
    echo "  ✓ Process ID: $(cat $INSTALL_DIR/server.pid 2>/dev/null || echo 'Unknown')"
    echo "  ✓ Installation directory: $INSTALL_DIR"
    echo "  ✓ Log file: $INSTALL_DIR/server.log"
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
    echo -e "${CYAN}Server is now running in the background!${NC}"
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header
    
    print_info "Configuration:"
    echo "  Branch: $BRANCH"
    echo "  Install Dir: $INSTALL_DIR"
    echo "  Port: $LISTEN_PORT"
    
    check_prerequisites
    clone_repository
    setup_environment
    install_dependencies
    start_server
    validate_api
    print_final_status
}

# Run main function
main

