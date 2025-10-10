#!/usr/bin/env bash

#############################################################################
# Qwen API - Single-Script Auto Deployment with Interactive Setup
#############################################################################
# This script handles:
# - Cloning the repository
# - Interactive credential collection
# - Environment setup
# - Dependency installation
# - Server startup
# - Validation with actual OpenAI API call
# - Continuous server operation
#############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Zeeeepa/qwen-api.git"
DEFAULT_BRANCH="${1:-main}"  # Accept branch as first argument, default to main
INSTALL_DIR="${HOME}/qwen-api-deploy"
SERVER_PORT=8080
VALIDATION_TIMEOUT=30

#############################################################################
# Helper Functions
#############################################################################

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${GREEN}▸${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${BOLD}$1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        return 1
    fi
    return 0
}

#############################################################################
# System Requirements Check
#############################################################################

check_prerequisites() {
    print_header "Checking System Prerequisites"
    
    local missing_deps=0
    
    # Check Python
    if check_command python3; then
        local python_version=$(python3 --version | awk '{print $2}')
        print_success "Python installed: ${python_version}"
        
        # Check if version is 3.10+
        local major=$(echo "$python_version" | cut -d. -f1)
        local minor=$(echo "$python_version" | cut -d. -f2)
        if [ "$major" -lt 3 ] || ([ "$major" -eq 3 ] && [ "$minor" -lt 10 ]); then
            print_error "Python 3.10+ required (found ${python_version})"
            missing_deps=1
        fi
    else
        missing_deps=1
    fi
    
    # Check Git
    if check_command git; then
        print_success "Git installed: $(git --version | awk '{print $3}')"
    else
        missing_deps=1
    fi
    
    # Check pip
    if check_command pip3; then
        print_success "pip3 installed: $(pip3 --version | awk '{print $2}')"
    else
        print_warning "pip3 not found, attempting to bootstrap..."
        python3 -m ensurepip --upgrade || {
            print_error "Failed to bootstrap pip"
            missing_deps=1
        }
    fi
    
    # Check curl for API testing
    if check_command curl; then
        print_success "curl installed"
    else
        print_warning "curl not found (optional, for API testing)"
    fi
    
    if [ $missing_deps -ne 0 ]; then
        print_error "Missing required dependencies. Please install them first."
        echo ""
        echo "Installation commands by OS:"
        echo "  Ubuntu/Debian: sudo apt-get update && sudo apt-get install -y python3 python3-pip git curl"
        echo "  CentOS/RHEL:   sudo yum install -y python3 python3-pip git curl"
        echo "  macOS:         brew install python3 git curl"
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

#############################################################################
# Interactive Credential Collection
#############################################################################

collect_credentials() {
    print_header "Interactive Credential Setup"
    
    print_info "This script will collect your Qwen credentials securely."
    print_info "Your credentials will be stored locally in .env file only."
    echo ""
    
    # Qwen Email
    while true; do
        read -p "$(echo -e ${CYAN}Enter your Qwen email address:${NC} )" QWEN_EMAIL
        if [[ "$QWEN_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_error "Invalid email format. Please try again."
        fi
    done
    
    # Qwen Password
    while true; do
        read -s -p "$(echo -e ${CYAN}Enter your Qwen password:${NC} )" QWEN_PASSWORD
        echo ""
        if [ -n "$QWEN_PASSWORD" ]; then
            read -s -p "$(echo -e ${CYAN}Confirm your Qwen password:${NC} )" QWEN_PASSWORD_CONFIRM
            echo ""
            if [ "$QWEN_PASSWORD" == "$QWEN_PASSWORD_CONFIRM" ]; then
                break
            else
                print_error "Passwords do not match. Please try again."
            fi
        else
            print_error "Password cannot be empty. Please try again."
        fi
    done
    
    # Optional: FlareProx configuration
    echo ""
    read -p "$(echo -e ${CYAN}Enable FlareProx for IP rotation? [y/N]:${NC} )" enable_flareprox
    if [[ "$enable_flareprox" =~ ^[Yy]$ ]]; then
        FLAREPROX_ENABLED="true"
        read -p "$(echo -e ${CYAN}Cloudflare API Token:${NC} )" CLOUDFLARE_API_TOKEN
        read -p "$(echo -e ${CYAN}Cloudflare Account ID:${NC} )" CLOUDFLARE_ACCOUNT_ID
        read -p "$(echo -e ${CYAN}Number of proxies [default: 3]:${NC} )" PROXY_COUNT
        FLAREPROX_PROXY_COUNT="${PROXY_COUNT:-3}"
    else
        FLAREPROX_ENABLED="false"
    fi
    
    # Optional: Custom port
    echo ""
    read -p "$(echo -e ${CYAN}Server port [default: 8080]:${NC} )" custom_port
    SERVER_PORT="${custom_port:-8080}"
    
    print_success "Credentials collected successfully"
}

#############################################################################
# Repository Clone
#############################################################################

clone_repository() {
    print_header "Cloning Repository"
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Installation directory already exists: $INSTALL_DIR"
        read -p "$(echo -e ${YELLOW}Remove existing directory and continue? [y/N]:${NC} )" confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            print_step "Removing existing directory..."
            rm -rf "$INSTALL_DIR"
        else
            print_info "Using existing directory"
            cd "$INSTALL_DIR"
            return 0
        fi
    fi
    
    print_step "Cloning repository from: $REPO_URL"
    print_step "Branch: $DEFAULT_BRANCH"
    
    git clone --depth 1 --branch "$DEFAULT_BRANCH" "$REPO_URL" "$INSTALL_DIR" || {
        print_error "Failed to clone repository"
        exit 1
    }
    
    cd "$INSTALL_DIR"
    print_success "Repository cloned successfully"
}

#############################################################################
# Environment Setup
#############################################################################

setup_environment() {
    print_header "Setting Up Environment"
    
    print_step "Creating .env configuration file..."
    
    cat > .env <<EOF
# Qwen API Server Configuration
# Auto-generated by autodeploy.sh on $(date)

# ============================================
# Qwen Provider Authentication (REQUIRED)
# ============================================
QWEN_EMAIL=${QWEN_EMAIL}
QWEN_PASSWORD=${QWEN_PASSWORD}

# ============================================
# Server Configuration
# ============================================
LISTEN_PORT=${SERVER_PORT}
HOST=0.0.0.0
DEBUG_LOGGING=false

# ============================================
# Authentication Settings
# ============================================
SKIP_AUTH_TOKEN=false
ANONYMOUS_MODE=true

# ============================================
# Feature Flags
# ============================================
FLAREPROX_ENABLED=${FLAREPROX_ENABLED}
EOF

    # Add FlareProx config if enabled
    if [ "$FLAREPROX_ENABLED" == "true" ]; then
        cat >> .env <<EOF
CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
CLOUDFLARE_ACCOUNT_ID=${CLOUDFLARE_ACCOUNT_ID}
FLAREPROX_PROXY_COUNT=${FLAREPROX_PROXY_COUNT}
EOF
    fi
    
    cat >> .env <<EOF
TOOL_SUPPORT=true
SCAN_LIMIT=200000
EOF
    
    chmod 600 .env  # Secure the .env file
    print_success "Environment configured"
}

#############################################################################
# Install Dependencies
#############################################################################

install_dependencies() {
    print_header "Installing Dependencies"
    
    # Create virtual environment
    print_step "Creating virtual environment..."
    python3 -m venv venv || {
        print_error "Failed to create virtual environment"
        exit 1
    }
    
    # Activate virtual environment
    print_step "Activating virtual environment..."
    source venv/bin/activate || {
        print_error "Failed to activate virtual environment"
        exit 1
    }
    
    # Upgrade pip
    print_step "Upgrading pip..."
    pip install --upgrade pip setuptools wheel -q
    
    # Install package in development mode
    print_step "Installing qwen-api package..."
    pip install -e . -q || {
        print_error "Failed to install package"
        exit 1
    }
    
    # Install playwright browsers
    print_step "Installing Playwright browsers (this may take a moment)..."
    playwright install chromium --with-deps -q || {
        print_warning "Playwright browser installation failed (will retry on first use)"
    }
    
    print_success "Dependencies installed successfully"
}

#############################################################################
# Start Server
#############################################################################

start_server() {
    print_header "Starting Server"
    
    # Make sure we're in virtual environment
    if [ -z "$VIRTUAL_ENV" ]; then
        print_step "Activating virtual environment..."
        source venv/bin/activate
    fi
    
    print_step "Starting Qwen API server on port ${SERVER_PORT}..."
    print_info "Server logs will be displayed below"
    print_info "Press Ctrl+C to stop the server"
    echo ""
    
    # Start server in background with output to log
    nohup python main.py > server.log 2>&1 &
    SERVER_PID=$!
    
    print_info "Server PID: ${SERVER_PID}"
    print_step "Waiting for server to start..."
    
    # Wait for server to be ready
    local max_attempts=30
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "http://localhost:${SERVER_PORT}/" > /dev/null 2>&1; then
            print_success "Server is ready!"
            return 0
        fi
        sleep 1
        ((attempt++))
        echo -n "."
    done
    
    echo ""
    print_error "Server failed to start within ${max_attempts} seconds"
    print_info "Checking logs..."
    tail -n 20 server.log
    kill $SERVER_PID 2>/dev/null
    exit 1
}

#############################################################################
# Validate Server
#############################################################################

validate_server() {
    print_header "Validating Server"
    
    print_step "Testing health endpoint..."
    local health_response=$(curl -s "http://localhost:${SERVER_PORT}/health")
    if [ $? -eq 0 ]; then
        print_success "Health check passed"
        echo -e "${CYAN}Response:${NC} $health_response"
    else
        print_error "Health check failed"
        return 1
    fi
    
    echo ""
    print_step "Testing OpenAI-compatible API endpoint..."
    print_info "Sending test chat completion request..."
    
    # Create test request
    local test_request='{
  "model": "qwen-max",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Say hello in exactly 5 words"}
  ],
  "max_tokens": 50,
  "temperature": 0.7,
  "stream": false
}'
    
    # Make API call
    local api_response=$(curl -s -w "\n%{http_code}" -X POST \
        "http://localhost:${SERVER_PORT}/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer test-token" \
        -d "$test_request")
    
    local http_code=$(echo "$api_response" | tail -n1)
    local response_body=$(echo "$api_response" | head -n-1)
    
    if [ "$http_code" == "200" ]; then
        print_success "API validation successful!"
        echo ""
        echo -e "${CYAN}${BOLD}API Response:${NC}"
        echo "$response_body" | python3 -m json.tool 2>/dev/null || echo "$response_body"
        
        # Extract and display the actual message
        local message=$(echo "$response_body" | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null)
        if [ -n "$message" ]; then
            echo ""
            echo -e "${GREEN}${BOLD}Assistant Response:${NC} $message"
        fi
    else
        print_error "API validation failed (HTTP ${http_code})"
        echo -e "${RED}Response:${NC} $response_body"
        return 1
    fi
    
    return 0
}

#############################################################################
# Display Usage Information
#############################################################################

display_usage() {
    print_header "Server Running - Usage Information"
    
    cat <<EOF
${GREEN}✓${NC} ${BOLD}Server is running successfully!${NC}

${CYAN}${BOLD}Server Details:${NC}
  • Address:  http://localhost:${SERVER_PORT}
  • PID:      ${SERVER_PID}
  • Logs:     ${INSTALL_DIR}/server.log

${CYAN}${BOLD}Example API Usage:${NC}

${YELLOW}1. Chat Completion:${NC}
curl -X POST http://localhost:${SERVER_PORT}/chat/completions \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer any-token" \\
  -d '{
    "model": "qwen-max",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'

${YELLOW}2. Streaming Chat:${NC}
curl -X POST http://localhost:${SERVER_PORT}/chat/completions \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer any-token" \\
  -d '{
    "model": "qwen-max",
    "messages": [{"role": "user", "content": "Tell me a story"}],
    "stream": true
  }'

${YELLOW}3. List Available Models:${NC}
curl http://localhost:${SERVER_PORT}/models \\
  -H "Authorization: Bearer any-token"

${YELLOW}4. Health Check:${NC}
curl http://localhost:${SERVER_PORT}/health

${CYAN}${BOLD}Available Models:${NC}
  • qwen-max, qwen-max-latest, qwen-plus, qwen-turbo
  • qwen-thinking (deep reasoning), qwen-deep-research
  • qwen-vl-max (multimodal), qwen-omni (audio)
  • And 30+ more variants!

${CYAN}${BOLD}Management Commands:${NC}
  • Stop server:    kill ${SERVER_PID}
  • View logs:      tail -f ${INSTALL_DIR}/server.log
  • Restart:        cd ${INSTALL_DIR} && ./autodeploy.sh

${CYAN}${BOLD}Documentation:${NC}
  • README:         ${INSTALL_DIR}/README.md
  • API Docs:       http://localhost:${SERVER_PORT}/docs

${GREEN}The server will continue running in the background.${NC}
${YELLOW}Press Ctrl+C to stop monitoring (server will keep running).${NC}

EOF
}

#############################################################################
# Monitor Server Logs
#############################################################################

monitor_logs() {
    print_header "Monitoring Server Logs"
    print_info "Press Ctrl+C to stop monitoring (server continues running)"
    echo ""
    
    # Trap Ctrl+C to exit gracefully
    trap 'echo ""; print_info "Log monitoring stopped. Server is still running."; exit 0' INT
    
    # Tail logs
    tail -f server.log
}

#############################################################################
# Cleanup on Exit
#############################################################################

cleanup() {
    if [ -n "$SERVER_PID" ]; then
        if ps -p $SERVER_PID > /dev/null 2>&1; then
            print_info "Server (PID: ${SERVER_PID}) is still running"
        fi
    fi
}

trap cleanup EXIT

#############################################################################
# Main Execution
#############################################################################

main() {
    clear
    cat <<EOF
${CYAN}${BOLD}
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     Qwen API - Single-Script Auto Deployment                 ║
║     OpenAI-Compatible Multi-Provider Gateway                 ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
${NC}
EOF

    print_info "This script will automatically:"
    echo "  1. Check system prerequisites"
    echo "  2. Collect credentials interactively"
    echo "  3. Clone repository"
    echo "  4. Setup environment"
    echo "  5. Install dependencies"
    echo "  6. Start server"
    echo "  7. Validate with API call"
    echo "  8. Continue running server"
    echo ""
    
    read -p "$(echo -e ${GREEN}Press Enter to continue or Ctrl+C to cancel...${NC})"
    
    # Execute deployment steps
    check_prerequisites
    collect_credentials
    clone_repository
    setup_environment
    install_dependencies
    start_server
    
    # Validate server
    if validate_server; then
        display_usage
        monitor_logs
    else
        print_error "Server validation failed"
        print_info "Checking recent logs..."
        tail -n 30 server.log
        print_info "Server is still running. Check logs: ${INSTALL_DIR}/server.log"
    fi
}

# Run main function
main "$@"

