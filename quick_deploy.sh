#!/usr/bin/env bash
#
# Qwen API - One-Command Deployment Script  
# Clone, Deploy, Start, Validate, and Run OpenAI-Compatible API
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/quick_deploy.sh | bash
#   
# Or with specific branch:
#   curl -fsSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/quick_deploy.sh | bash -s main
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Zeeeepa/qwen-api.git"
BRANCH="${1:-main}"
DEPLOY_DIR="qwen-api-deployment"
PORT="${PORT:-8096}"

# Function: Print colored message
print_msg() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function: Print section header
print_header() {
    echo ""
    print_msg "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_msg "$BLUE" "  $1"
    print_msg "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function: Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function: Check dependencies
check_dependencies() {
    print_header "Checking Dependencies"
    
    local missing_deps=()
    
    if ! command_exists python3; then
        missing_deps+=("python3")
    fi
    
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_msg "$RED" "❌ Missing dependencies: ${missing_deps[*]}"
        print_msg "$YELLOW" "Please install missing dependencies and try again."
        exit 1
    fi
    
    print_msg "$GREEN" "✅ All dependencies satisfied"
}

# Function: Interactive credential prompt
get_credentials() {
    print_header "Qwen Account Configuration"
    
    print_msg "$YELLOW" "⚠️  Authentication Required"
    print_msg "$BLUE" "This deployment uses Playwright automation to authenticate with Qwen."
    print_msg "$BLUE" "Your credentials will be stored securely in a local encrypted session."
    echo ""
    
    # Email
    while [ -z "$QWEN_EMAIL" ]; do
        read -p "Enter your Qwen email: " QWEN_EMAIL
        if [ -z "$QWEN_EMAIL" ]; then
            print_msg "$RED" "Email cannot be empty!"
        fi
    done
    
    # Password
    while [ -z "$QWEN_PASSWORD" ]; do
        read -s -p "Enter your Qwen password: " QWEN_PASSWORD
        echo ""
        if [ -z "$QWEN_PASSWORD" ]; then
            print_msg "$RED" "Password cannot be empty!"
        fi
    done
    
    print_msg "$GREEN" "✅ Credentials captured"
}

# Function: Clone repository
clone_repo() {
    print_header "Cloning Repository"
    
    if [ -d "$DEPLOY_DIR" ]; then
        print_msg "$YELLOW" "⚠️  Directory '$DEPLOY_DIR' already exists"
        read -p "Remove and re-clone? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$DEPLOY_DIR"
        else
            print_msg "$YELLOW" "Using existing directory"
            cd "$DEPLOY_DIR"
            git pull origin "$BRANCH" || true
            return
        fi
    fi
    
    git clone -b "$BRANCH" "$REPO_URL" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
    print_msg "$GREEN" "✅ Repository cloned"
}

# Function: Setup Python environment
setup_python_env() {
    print_header "Setting Up Python Environment"
    
    # Create virtual environment
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        print_msg "$GREEN" "✅ Virtual environment created"
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip > /dev/null 2>&1
    
    # Install dependencies
    print_msg "$BLUE" "Installing dependencies..."
    pip install -r requirements.txt > /dev/null 2>&1
    
    # Install Playwright browsers
    print_msg "$BLUE" "Installing Playwright browsers..."
    playwright install chromium > /dev/null 2>&1
    
    print_msg "$GREEN" "✅ Python environment ready"
}

# Function: Configure environment
configure_env() {
    print_header "Configuring Environment"
    
    cat > .env << EOF
# Qwen Authentication
QWEN_EMAIL=$QWEN_EMAIL
QWEN_PASSWORD=$QWEN_PASSWORD

# Server Configuration
PORT=$PORT
HOST=0.0.0.0

# Optional: Set log level (DEBUG, INFO, WARNING, ERROR)
LOG_LEVEL=INFO
EOF
    
    print_msg "$GREEN" "✅ Environment configured"
    print_msg "$BLUE" "   Email: $QWEN_EMAIL"
    print_msg "$BLUE" "   Port:  $PORT"
}

# Function: Start server
start_server() {
    print_header "Starting Server"
    
    # Kill existing server if running
    if [ -f "server.pid" ]; then
        OLD_PID=$(cat server.pid)
        if kill -0 "$OLD_PID" 2>/dev/null; then
            print_msg "$YELLOW" "Stopping existing server (PID: $OLD_PID)"
            kill "$OLD_PID" 2>/dev/null || true
            sleep 2
        fi
    fi
    
    # Start server
    source venv/bin/activate
    nohup python main.py > server.log 2>&1 &
    echo $! > server.pid
    
    print_msg "$BLUE" "⏳ Waiting for server to start..."
    sleep 5
    
    # Check if server is running
    if ! curl -s http://localhost:$PORT/health > /dev/null; then
        print_msg "$RED" "❌ Server failed to start"
        print_msg "$YELLOW" "Check server.log for details:"
        tail -20 server.log
        exit 1
    fi
    
    print_msg "$GREEN" "✅ Server started (PID: $(cat server.pid))"
}

# Function: Validate API with real call
validate_api() {
    print_header "Validating API Endpoint"
    
    print_msg "$BLUE" "Making test API call..."
    
    # Make API request
    RESPONSE=$(curl -s -X POST "http://localhost:$PORT/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer test" \
        -d '{
            "model": "qwen-turbo",
            "messages": [{"role": "user", "content": "Say \"Hello World\""}],
            "stream": false
        }')
    
    # Check response
    if echo "$RESPONSE" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
        CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')
        
        if [ -n "$CONTENT" ] && [ "$CONTENT" != "null" ]; then
            print_msg "$GREEN" "✅ API Validation SUCCESS!"
            print_msg "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print_msg "$GREEN" "Response: $CONTENT"
            print_msg "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        else
            print_msg "$YELLOW" "⚠️  API returned empty content"
            print_msg "$YELLOW" "This may indicate:"
            print_msg "$YELLOW" "  - First-time authentication in progress"
            print_msg "$YELLOW" "  - Rate limiting or account restrictions"
            print_msg "$YELLOW" "  - Qwen API temporary unavailability"
            print_msg "$BLUE" ""
            print_msg "$BLUE" "Full response:"
            echo "$RESPONSE" | jq '.'
        fi
    else
        print_msg "$RED" "❌ API call failed"
        print_msg "$YELLOW" "Response:"
        echo "$RESPONSE" | jq '.' || echo "$RESPONSE"
    fi
}

# Function: Print final instructions
print_final_info() {
    print_header "Deployment Complete! 🎉"
    
    cat << EOF

${GREEN}✅ Qwen API is now running!${NC}

${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${GREEN}API Endpoint:${NC}
  http://localhost:$PORT

${GREEN}Health Check:${NC}
  curl http://localhost:$PORT/health

${GREEN}Example API Call:${NC}
  curl -X POST http://localhost:$PORT/v1/chat/completions \\
    -H "Content-Type: application/json" \\
    -H "Authorization: Bearer test" \\
    -d '{
      "model": "qwen-turbo",
      "messages": [{"role": "user", "content": "Hello!"}],
      "stream": false
    }'

${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${GREEN}Management Commands:${NC}
  
  ${YELLOW}View Logs:${NC}
    tail -f $(pwd)/server.log
  
  ${YELLOW}Stop Server:${NC}
    kill \$(cat $(pwd)/server.pid)
  
  ${YELLOW}Restart Server:${NC}
    cd $(pwd) && source venv/bin/activate && \\
    kill \$(cat server.pid) 2>/dev/null || true && \\
    nohup python main.py > server.log 2>&1 & echo \$! > server.pid

${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${GREEN}Supported Models:${NC}
  - qwen-max
  - qwen-plus
  - qwen-turbo
  - qwen-long
  - qwen-coder-plus
  + more variants with -thinking, -search, -image, -video suffixes

${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${YELLOW}Note:${NC} The first API call may take longer as Playwright 
      authenticates with Qwen. Subsequent calls use cached tokens.

${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${GREEN}Documentation:${NC}
  https://github.com/Zeeeepa/qwen-api

${GREEN}Server is running in background. Enjoy! 🚀${NC}

EOF
}

# Main execution flow
main() {
    print_msg "$GREEN" "╔════════════════════════════════════════════════╗"
    print_msg "$GREEN" "║   Qwen API - One-Command Deployment Script    ║"
    print_msg "$GREEN" "║   OpenAI-Compatible API for Qwen Models       ║"
    print_msg "$GREEN" "╚════════════════════════════════════════════════╝"
    
    check_dependencies
    get_credentials
    clone_repo
    setup_python_env
    configure_env
    start_server
    validate_api
    print_final_info
}

# Run main function
main

