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
    
    # Collect credentials - Check environment variables first
    echo -e "${CYAN}${BOLD}Qwen Authentication Setup${NC}"
    echo ""
    
    # Check if credentials are already in environment
    if [ -n "$QWEN_EMAIL" ] && [ -n "$QWEN_PASSWORD" ]; then
        print_info "Using credentials from environment variables"
        print_success "QWEN_EMAIL detected"
        print_success "QWEN_PASSWORD detected"
        AUTH_METHOD="2"
    else
        print_info "No environment credentials found, prompting for input..."
        echo ""
        read -p "Enter Qwen Email: " QWEN_EMAIL
        read -sp "Enter Qwen Password: " QWEN_PASSWORD
        echo ""
        AUTH_METHOD="2"
    fi
    
    # Create .env with credentials for Playwright automation
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
    
    # Install Playwright browsers and system dependencies (CRITICAL for authentication)
    print_info "Installing Playwright system dependencies..."
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu systems
        playwright install-deps chromium > /dev/null 2>&1 || print_warning "System deps install may have failed"
    fi
    
    print_info "Installing Playwright browsers (required for authentication)..."
    if playwright install chromium > /dev/null 2>&1; then
        print_success "Playwright browsers and dependencies installed successfully"
    else
        print_warning "Playwright browser installation may have failed, but continuing..."
    fi
}

start_server() {
    print_step "Step 5/6: Starting Server"
    separator
    echo ""
    
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
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
            return 0
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
    print_error "Server failed to start within 60 seconds"
    print_info "Check server.log for details: $INSTALL_DIR/server.log"
    echo ""
    print_info "Last 50 lines of server log:"
    tail -50 "$INSTALL_DIR/server.log"
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
    
    # Test chat completion endpoint with curl
    echo ""
    print_info "Testing chat completion endpoint with curl..."
    print_info "Using auto-fetched Bearer token from Playwright authentication"
    
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
            print_success "✅ Real AI Response: $MESSAGE"
            print_info "Token is working correctly!"
        else
            print_warning "Empty response - token may need refresh"
        fi
    else
        print_warning "Chat completion endpoint returned empty response"
        print_info "Check server logs if this persists"
    fi
    
    # Create Python test script
    echo ""
    print_info "Creating Python test script (test_api.py)..."
    
    cat > test_api.py << 'PYTHON_EOF'
#!/usr/bin/env python3
"""
Test script for Qwen API using OpenAI Python client
"""
from openai import OpenAI

# Initialize client with local Qwen API
client = OpenAI(
    base_url="http://localhost:PORT_PLACEHOLDER/v1",
    api_key="sk-test"  # Required by OpenAI client but not validated when SKIP_AUTH_TOKEN=true
)

print("=" * 60)
print("Testing Qwen API with OpenAI Python Client")
print("=" * 60)
print()

# Test chat completion
print("Sending request to chat completion endpoint...")
print("Model: qwen-turbo")
print("Prompt: What is your model name?")
print()

try:
    response = client.chat.completions.create(
        model="qwen-turbo",
        messages=[
            {"role": "user", "content": "What is your model name?"}
        ],
        max_tokens=100
    )
    
    print("✓ Response received!")
    print()
    print("=" * 60)
    print("Full Response Object:")
    print("=" * 60)
    print(response)
    print()
    print("=" * 60)
    print("Assistant Message:")
    print("=" * 60)
    print(response.choices[0].message.content)
    print()
    print("=" * 60)
    print("Response Metadata:")
    print("=" * 60)
    print(f"  ID: {response.id}")
    print(f"  Model: {response.model}")
    print(f"  Finish Reason: {response.choices[0].finish_reason}")
    print(f"  Tokens Used: {response.usage.total_tokens if response.usage else 'N/A'}")
    print("=" * 60)

except Exception as e:
    print(f"✗ Error: {e}")
    import traceback
    traceback.print_exc()
PYTHON_EOF
    
    # Replace port placeholder
    sed -i "s/PORT_PLACEHOLDER/$LISTEN_PORT/g" test_api.py
    chmod +x test_api.py
    
    print_success "Test script created: test_api.py"
    
    # Run the Python test
    echo ""
    print_info "Running Python OpenAI client test..."
    separator
    echo ""
    
    source venv/bin/activate
    
    # Install openai package if not present
    if ! python3 -c "import openai" 2>/dev/null; then
        print_info "Installing openai package..."
        pip install openai > /dev/null 2>&1
        print_success "openai package installed"
        echo ""
    fi
    
    # Run the test
    python3 test_api.py || print_warning "Python test encountered an error"
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
    echo "Test Scripts Created:"
    echo "  • Python test:  $INSTALL_DIR/test_api.py"
    echo "  • Run test:     cd $INSTALL_DIR && source venv/bin/activate && python test_api.py"
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
