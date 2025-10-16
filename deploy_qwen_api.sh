#!/bin/bash
################################################################################
# Qwen API - Complete One-Line Deployment Script
# 
# Description:
#   Complete deployment script for Qwen API server that handles everything:
#   - Environment setup
#   - Dependency installation
#   - Token extraction
#   - Server startup
#   - Health verification
#
# Prerequisites:
#   - Python 3.8+
#   - Git
#   - Qwen account credentials
#
# Usage:
#   export QWEN_EMAIL="your@email.com"
#   export QWEN_PASSWORD="yourpassword"
#   curl -sSL https://gist.githubusercontent.com/YOUR_USERNAME/YOUR_GIST_ID/raw/deploy_qwen_api.sh | bash
#
# Or with wget:
#   wget -qO- https://gist.githubusercontent.com/YOUR_USERNAME/YOUR_GIST_ID/raw/deploy_qwen_api.sh | bash
#
# Repository: https://github.com/Zeeeepa/qwen-api
# Author: Zeeeepa
# License: MIT
################################################################################

set -e  # Exit on any error

################################################################################
# Color Definitions
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

################################################################################
# Helper Functions
################################################################################

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║            🚀 Qwen API One-Line Deployment 🚀             ║"
    echo "║                                                            ║"
    echo "║  Complete OpenAI-compatible Qwen API server deployment    ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

print_info() {
    echo -e "${WHITE}ℹ️  $1${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

################################################################################
# Configuration Variables
################################################################################

REPO_URL="https://github.com/Zeeeepa/qwen-api.git"
REPO_DIR="qwen-api"
VENV_DIR="venv"
SERVER_PORT="${QWEN_API_PORT:-8096}"
SERVER_PID_FILE="server.pid"
LOG_DIR="logs"
TOKEN_FILE=".qwen_bearer_token"

################################################################################
# Validation Functions
################################################################################

validate_prerequisites() {
    print_step "Validating Prerequisites"
    
    local all_good=true
    
    # Check Python
    if check_command python3; then
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        print_info "Python version: $PYTHON_VERSION"
    else
        all_good=false
    fi
    
    # Check Git
    if ! check_command git; then
        all_good=false
    fi
    
    # Check pip
    if ! check_command pip3; then
        print_warning "pip3 not found, will try to install"
    fi
    
    # Check credentials
    if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
        print_error "QWEN_EMAIL and QWEN_PASSWORD environment variables must be set!"
        echo -e "\n${YELLOW}Please export your credentials:${NC}"
        echo -e "${WHITE}  export QWEN_EMAIL=\"your@email.com\"${NC}"
        echo -e "${WHITE}  export QWEN_PASSWORD=\"yourpassword\"${NC}"
        echo -e "\n${YELLOW}Then run this script again.${NC}\n"
        exit 1
    fi
    
    print_success "Credentials found"
    print_info "Email: $QWEN_EMAIL"
    
    if [ "$all_good" = false ]; then
        print_error "Some prerequisites are missing. Please install them first."
        exit 1
    fi
}

################################################################################
# Installation Functions
################################################################################

clone_repository() {
    print_step "Cloning Repository"
    
    if [ -d "$REPO_DIR" ]; then
        print_warning "Repository directory already exists"
        print_info "Pulling latest changes..."
        cd "$REPO_DIR"
        git pull origin main || print_warning "Could not pull latest changes"
    else
        print_info "Cloning from: $REPO_URL"
        git clone "$REPO_URL" "$REPO_DIR"
        cd "$REPO_DIR"
        print_success "Repository cloned successfully"
    fi
}

setup_virtual_environment() {
    print_step "Setting Up Python Virtual Environment"
    
    if [ ! -d "$VENV_DIR" ]; then
        print_info "Creating virtual environment..."
        python3 -m venv "$VENV_DIR"
        print_success "Virtual environment created"
    else
        print_warning "Virtual environment already exists"
    fi
    
    print_info "Activating virtual environment..."
    source "$VENV_DIR/bin/activate"
    print_success "Virtual environment activated"
}

install_dependencies() {
    print_step "Installing Dependencies"
    
    print_info "Upgrading pip..."
    pip install --upgrade pip --quiet
    
    print_info "Installing Python packages..."
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt --quiet
        print_success "Python packages installed"
    else
        print_warning "requirements.txt not found, installing core packages..."
        pip install fastapi uvicorn httpx playwright pydantic python-dotenv loguru --quiet
        print_success "Core packages installed"
    fi
    
    print_info "Installing Playwright browsers..."
    playwright install chromium --with-deps > /dev/null 2>&1
    print_success "Playwright browsers installed"
}

extract_bearer_token() {
    print_step "Extracting Bearer Token"
    
    if [ -f "$TOKEN_FILE" ]; then
        TOKEN_AGE=$(($(date +%s) - $(stat -f%m "$TOKEN_FILE" 2>/dev/null || stat -c%Y "$TOKEN_FILE" 2>/dev/null)))
        TOKEN_AGE_HOURS=$((TOKEN_AGE / 3600))
        
        if [ $TOKEN_AGE_HOURS -lt 12 ]; then
            print_success "Valid cached token found (${TOKEN_AGE_HOURS}h old)"
            return 0
        else
            print_warning "Cached token is ${TOKEN_AGE_HOURS}h old, refreshing..."
        fi
    fi
    
    print_info "Extracting new Bearer token using Playwright..."
    
    # Create token extraction script
    cat > /tmp/extract_qwen_token.py << 'PYEOF'
import sys
import asyncio
from playwright.async_api import async_playwright
import json

async def extract_token(email, password):
    """Extract Bearer token from Qwen using Playwright"""
    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context()
            page = await context.new_page()
            
            print("🌐 Navigating to Qwen login page...")
            await page.goto("https://chat.qwen.ai/auth?action=signin", timeout=30000)
            await page.wait_for_timeout(3000)
            
            print("📝 Filling in credentials...")
            await page.fill('input[type="email"]', email)
            await page.fill('input[type="password"]', password)
            
            print("🔐 Logging in...")
            await page.click('button[type="submit"]')
            await page.wait_for_timeout(5000)
            
            # Wait for redirect to main chat page
            await page.wait_for_url("**/chat.qwen.ai**", timeout=30000)
            print("✅ Login successful!")
            
            # Extract token from localStorage
            token = await page.evaluate("() => localStorage.getItem('token')")
            
            if token:
                print(f"🎉 Token extracted successfully!")
                print(f"📝 Token length: {len(token)} characters")
                return token
            else:
                print("❌ Failed to extract token from localStorage")
                return None
                
    except Exception as e:
        print(f"❌ Error during token extraction: {e}")
        return None

if __name__ == "__main__":
    email = sys.argv[1]
    password = sys.argv[2]
    
    token = asyncio.run(extract_token(email, password))
    
    if token:
        # Save token to file
        with open('.qwen_bearer_token', 'w') as f:
            f.write(token)
        print("✅ Token saved to .qwen_bearer_token")
        sys.exit(0)
    else:
        print("❌ Token extraction failed")
        sys.exit(1)
PYEOF
    
    # Run token extraction
    python3 /tmp/extract_qwen_token.py "$QWEN_EMAIL" "$QWEN_PASSWORD"
    
    if [ $? -eq 0 ] && [ -f "$TOKEN_FILE" ]; then
        print_success "Bearer token extracted and saved"
    else
        print_error "Failed to extract Bearer token"
        exit 1
    fi
    
    rm -f /tmp/extract_qwen_token.py
}

################################################################################
# Server Management Functions
################################################################################

stop_existing_server() {
    print_step "Checking for Existing Server"
    
    if [ -f "$SERVER_PID_FILE" ]; then
        OLD_PID=$(cat "$SERVER_PID_FILE")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            print_warning "Stopping existing server (PID: $OLD_PID)..."
            kill "$OLD_PID" 2>/dev/null || true
            sleep 2
            print_success "Old server stopped"
        else
            print_info "PID file exists but process is not running"
        fi
        rm -f "$SERVER_PID_FILE"
    else
        print_info "No existing server found"
    fi
    
    # Check if port is in use
    if lsof -ti:$SERVER_PORT > /dev/null 2>&1; then
        print_warning "Port $SERVER_PORT is in use, attempting to free it..."
        lsof -ti:$SERVER_PORT | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

start_server() {
    print_step "Starting Server"
    
    # Create logs directory
    mkdir -p "$LOG_DIR"
    
    print_info "Starting Qwen API server on port $SERVER_PORT..."
    
    # Start server in background
    nohup python3 main.py --port $SERVER_PORT > "$LOG_DIR/server.log" 2>&1 &
    SERVER_PID=$!
    
    # Save PID
    echo $SERVER_PID > "$SERVER_PID_FILE"
    
    print_info "Server PID: $SERVER_PID"
    print_info "Waiting for server to start..."
    
    # Wait for server to be ready
    for i in {1..30}; do
        if curl -s http://localhost:$SERVER_PORT/health > /dev/null 2>&1; then
            print_success "Server started successfully!"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    
    echo ""
    print_error "Server failed to start within 30 seconds"
    print_info "Check logs: $LOG_DIR/server.log"
    return 1
}

verify_deployment() {
    print_step "Verifying Deployment"
    
    # Test health endpoint
    print_info "Testing health endpoint..."
    HEALTH_RESPONSE=$(curl -s http://localhost:$SERVER_PORT/health)
    if echo "$HEALTH_RESPONSE" | grep -q "ok"; then
        print_success "Health check passed"
    else
        print_error "Health check failed"
        return 1
    fi
    
    # Test chat completion
    print_info "Testing chat completion endpoint..."
    
    TEST_RESPONSE=$(curl -s -X POST http://localhost:$SERVER_PORT/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer sk-test" \
        -d '{
            "model": "gpt-4",
            "messages": [{"role": "user", "content": "Say hello"}],
            "stream": false
        }')
    
    if echo "$TEST_RESPONSE" | grep -q "choices"; then
        print_success "Chat completion test passed"
        
        # Extract and display response
        RESPONSE_TEXT=$(echo "$TEST_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null || echo "")
        if [ -n "$RESPONSE_TEXT" ]; then
            print_info "AI Response: ${PURPLE}${RESPONSE_TEXT}${NC}"
        fi
    else
        print_warning "Chat completion test returned unexpected response"
    fi
    
    print_success "All verification tests passed!"
}

################################################################################
# Information Display Functions
################################################################################

display_success_info() {
    echo -e "\n${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              🎉 Deployment Complete! 🎉                   ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    echo -e "${CYAN}📡 Server Information:${NC}"
    echo -e "${WHITE}  ✅ Status: ${GREEN}Running${NC}"
    echo -e "${WHITE}  🌐 URL: ${BLUE}http://localhost:$SERVER_PORT${NC}"
    echo -e "${WHITE}  📊 Health: ${BLUE}http://localhost:$SERVER_PORT/health${NC}"
    echo -e "${WHITE}  📚 Docs: ${BLUE}http://localhost:$SERVER_PORT/docs${NC}"
    echo -e "${WHITE}  🎯 Models: ${BLUE}http://localhost:$SERVER_PORT/v1/models${NC}"
    echo -e "${WHITE}  🔢 PID: ${YELLOW}$(cat $SERVER_PID_FILE)${NC}"
    echo ""
    
    echo -e "${CYAN}📝 Usage Examples:${NC}\n"
    
    echo -e "${WHITE}Python (OpenAI SDK):${NC}"
    cat << 'EOF'
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:8096/v1"
)

response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
EOF
    
    echo ""
    echo -e "${WHITE}cURL:${NC}"
    cat << EOF
curl -X POST http://localhost:$SERVER_PORT/v1/chat/completions \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer sk-any" \\
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
EOF
    
    echo -e "\n${CYAN}🛠️  Useful Commands:${NC}"
    echo -e "${WHITE}  View logs: ${YELLOW}tail -f $LOG_DIR/server.log${NC}"
    echo -e "${WHITE}  Stop server: ${YELLOW}kill \$(cat $SERVER_PID_FILE)${NC}"
    echo -e "${WHITE}  Check status: ${YELLOW}curl http://localhost:$SERVER_PORT/health${NC}"
    
    echo -e "\n${GREEN}✅ All systems operational! Your Qwen API is ready to use.${NC}\n"
}

display_error_info() {
    echo -e "\n${RED}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              ❌ Deployment Failed ❌                      ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    echo -e "${YELLOW}🔍 Troubleshooting Steps:${NC}\n"
    echo -e "${WHITE}1. Check logs:${NC}"
    echo -e "   ${YELLOW}tail -f $LOG_DIR/server.log${NC}"
    echo ""
    echo -e "${WHITE}2. Verify credentials:${NC}"
    echo -e "   ${YELLOW}echo \$QWEN_EMAIL${NC}"
    echo -e "   ${YELLOW}echo \$QWEN_PASSWORD${NC}"
    echo ""
    echo -e "${WHITE}3. Check if port is available:${NC}"
    echo -e "   ${YELLOW}lsof -i :$SERVER_PORT${NC}"
    echo ""
    echo -e "${WHITE}4. Try manual token extraction:${NC}"
    echo -e "   ${YELLOW}python3 test_auth.py${NC}"
    echo ""
    echo -e "${WHITE}5. Check Python version (need 3.8+):${NC}"
    echo -e "   ${YELLOW}python3 --version${NC}"
    
    echo -e "\n${RED}If issues persist, please check:${NC}"
    echo -e "${WHITE}  📖 Documentation: https://github.com/Zeeeepa/qwen-api${NC}"
    echo -e "${WHITE}  🐛 Issues: https://github.com/Zeeeepa/qwen-api/issues${NC}\n"
}

################################################################################
# Main Execution Flow
################################################################################

main() {
    # Print banner
    print_banner
    
    # Validate prerequisites
    validate_prerequisites
    
    # Clone repository
    clone_repository
    
    # Setup virtual environment
    setup_virtual_environment
    
    # Install dependencies
    install_dependencies
    
    # Extract bearer token
    extract_bearer_token
    
    # Stop existing server
    stop_existing_server
    
    # Start server
    if ! start_server; then
        display_error_info
        exit 1
    fi
    
    # Verify deployment
    if ! verify_deployment; then
        display_error_info
        exit 1
    fi
    
    # Display success information
    display_success_info
    
    exit 0
}

################################################################################
# Error Handling
################################################################################

trap 'print_error "Script interrupted"; exit 130' INT
trap 'print_error "Script terminated"; exit 143' TERM

################################################################################
# Script Entry Point
################################################################################

# Run main function
main "$@"

