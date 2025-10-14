#!/usr/bin/env bash
################################################################################
# deploy.sh - Complete Deployment Script for Qwen API
#
# This script handles the complete deployment process:
# 1. System dependencies installation
# 2. Python environment setup
# 3. Playwright browser installation
# 4. Token extraction via Playwright login
# 5. Environment configuration
#
# Usage:
#   export QWEN_EMAIL=your-email@example.com
#   export QWEN_PASSWORD=your-password
#   bash scripts/deploy.sh
################################################################################

set -euo pipefail

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly ENV_FILE="${PROJECT_ROOT}/.env"
readonly TOKEN_FILE="${PROJECT_ROOT}/.qwen_bearer_token"
readonly SESSION_DIR="${PROJECT_ROOT}/.sessions"
readonly LOG_DIR="${PROJECT_ROOT}/logs"

# Default configuration
DEFAULT_PORT=8096
PYTHON_VERSION="3.10"

cd "$PROJECT_ROOT"

################################################################################
# Utility Functions
################################################################################

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

log_step() {
    echo ""
    echo -e "${MAGENTA}${BOLD}[$1] $2${NC}"
    echo -e "${MAGENTA}${BOLD}$(printf '=%.0s' {1..60})${NC}"
}

print_header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║       Qwen API - Automated Deployment Script        ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_footer() {
    echo ""
    echo -e "${MAGENTA}${BOLD}$(printf '=%.0s' {1..60})${NC}"
    echo ""
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Environment Validation
################################################################################

validate_credentials() {
    log_step "1/7" "Validating credentials..."
    
    if [ -z "${QWEN_EMAIL:-}" ] || [ -z "${QWEN_PASSWORD:-}" ]; then
        log_error "Missing required credentials!"
        echo ""
        echo -e "${YELLOW}Please export your credentials:${NC}"
        echo -e "  ${CYAN}export QWEN_EMAIL=your-email@example.com${NC}"
        echo -e "  ${CYAN}export QWEN_PASSWORD=your-password${NC}"
        echo ""
        exit 1
    fi
    
    log_success "Credentials validated"
    log_info "Email: ${QWEN_EMAIL}"
}

################################################################################
# System Dependencies
################################################################################

install_system_dependencies() {
    log_step "2/7" "Installing system dependencies..."
    
    if [ "$(uname)" == "Darwin" ]; then
        log_info "Detected macOS"
        if ! check_command brew; then
            log_error "Homebrew not found. Please install from https://brew.sh"
            exit 1
        fi
        
        log_info "Installing Python..."
        brew install python@${PYTHON_VERSION} || true
        
    elif [ -f /etc/debian_version ]; then
        log_info "Detected Debian/Ubuntu"
        
        log_info "Updating package list..."
        sudo apt-get update -qq
        
        log_info "Installing dependencies..."
        sudo apt-get install -y -qq \
            python${PYTHON_VERSION} \
            python3-pip \
            python3-venv \
            curl \
            git \
            build-essential \
            ca-certificates
            
    elif [ -f /etc/redhat-release ]; then
        log_info "Detected RedHat/CentOS/Fedora"
        sudo dnf install -y python${PYTHON_VERSION} python3-pip git curl
    else
        log_warning "Unknown OS - attempting to continue..."
    fi
    
    log_success "System dependencies installed"
}

################################################################################
# Python Environment
################################################################################

setup_python_environment() {
    log_step "3/7" "Setting up Python environment..."
    
    # Install uv if not present
    if ! check_command uv; then
        log_info "Installing uv package manager..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    
    log_success "uv package manager ready"
    
    # Create virtual environment
    if [ ! -d ".venv" ]; then
        log_info "Creating virtual environment..."
        uv venv
    else
        log_info "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    source .venv/bin/activate
    
    # Install Python dependencies
    log_info "Installing Python packages..."
    uv pip install -r requirements.txt --quiet
    
    log_success "Python environment ready"
}

################################################################################
# Playwright Installation
################################################################################

install_playwright() {
    log_step "4/7" "Installing Playwright browser..."
    
    source .venv/bin/activate
    
    # Install Playwright Python package
    log_info "Installing Playwright..."
    uv pip install playwright pytest-playwright --quiet
    
    # Install browser
    log_info "Installing Chromium browser..."
    playwright install chromium --with-deps 2>&1 | grep -v "^Downloading" || true
    
    log_success "Playwright browser installed"
}

################################################################################
# Token Extraction
################################################################################

extract_token() {
    log_step "5/7" "Extracting authentication token..."
    
    source .venv/bin/activate
    
    # Create token extraction script
    cat > /tmp/extract_token.py << 'PYTHON_SCRIPT'
import asyncio
import os
import sys
from playwright.async_api import async_playwright

async def extract_token():
    email = os.getenv("QWEN_EMAIL")
    password = os.getenv("QWEN_PASSWORD")
    
    if not email or not password:
        print("ERROR: QWEN_EMAIL and QWEN_PASSWORD must be set")
        sys.exit(1)
    
    print("🌐 Starting Playwright automation...")
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        )
        page = await context.new_page()
        
        try:
            # Navigate to login page
            print("🔗 Navigating to Qwen login...")
            await page.goto("https://chat.qwen.ai/auth?action=signin", wait_until='networkidle', timeout=30000)
            
            # Fill credentials
            print("✏️  Filling credentials...")
            await page.wait_for_selector('input[type="email"], input[type="text"]', timeout=10000)
            
            email_input = await page.query_selector('input[type="email"], input[type="text"]')
            await email_input.fill(email)
            
            password_input = await page.query_selector('input[type="password"]')
            await password_input.fill(password)
            
            # Click login
            print("🔐 Logging in...")
            submit_button = await page.query_selector('button[type="submit"]')
            await submit_button.click()
            
            # Wait for login success
            print("⏳ Waiting for login to complete...")
            await page.wait_for_url('**/chat**', timeout=20000)
            await asyncio.sleep(3)
            
            # Extract token
            print("🔑 Extracting token...")
            for attempt in range(10):
                token = await page.evaluate('''() => {
                    return localStorage.getItem('web_api_token')
                        || localStorage.getItem('token')
                        || localStorage.getItem('access_token');
                }''')
                
                if token:
                    print(f"✅ Token extracted: {len(token)} characters")
                    print(f"TOKEN:{token}")
                    await browser.close()
                    return
                
                await asyncio.sleep(2)
            
            print("❌ Failed to extract token")
            sys.exit(1)
            
        except Exception as e:
            print(f"❌ Error: {e}")
            await browser.close()
            sys.exit(1)

asyncio.run(extract_token())
PYTHON_SCRIPT

    # Run token extraction
    log_info "Launching browser to extract token..."
    
    TOKEN_OUTPUT=$(python /tmp/extract_token.py 2>&1)
    EXTRACTION_STATUS=$?
    
    if [ $EXTRACTION_STATUS -eq 0 ]; then
        # Extract token from output
        BEARER_TOKEN=$(echo "$TOKEN_OUTPUT" | grep "^TOKEN:" | cut -d: -f2-)
        
        if [ -n "$BEARER_TOKEN" ]; then
            # Save to .env
            log_info "Saving token to .env..."
            
            if [ -f "$ENV_FILE" ]; then
                # Update existing .env
                sed -i.bak '/^QWEN_BEARER_TOKEN=/d' "$ENV_FILE"
            fi
            
            echo "QWEN_BEARER_TOKEN=$BEARER_TOKEN" >> "$ENV_FILE"
            echo "$BEARER_TOKEN" > "$TOKEN_FILE"
            
            log_success "Token saved successfully"
            log_info "Token length: ${#BEARER_TOKEN} characters"
        else
            log_error "Failed to extract token from output"
            exit 1
        fi
    else
        log_error "Token extraction failed"
        echo "$TOKEN_OUTPUT"
        exit 1
    fi
    
    # Cleanup
    rm -f /tmp/extract_token.py
}

################################################################################
# Environment Configuration
################################################################################

configure_environment() {
    log_step "6/7" "Configuring environment..."
    
    # Create necessary directories
    mkdir -p "$SESSION_DIR" "$LOG_DIR"
    
    # Create or update .env file
    if [ ! -f "$ENV_FILE" ]; then
        log_info "Creating .env file..."
        cat > "$ENV_FILE" << EOF
# Qwen API Configuration
QWEN_EMAIL=${QWEN_EMAIL}
QWEN_PASSWORD=${QWEN_PASSWORD}

# Server Configuration
LISTEN_PORT=${DEFAULT_PORT}
HOST=0.0.0.0

# Mode Configuration
ANONYMOUS_MODE=true
DEBUG_LOGGING=true

# Provider Configuration
QWEN_PROVIDER_MODE=auto

# Feature Flags
ENABLE_STREAMING=true
ENABLE_IMAGES=true
EOF
    else
        log_info ".env file already exists"
    fi
    
    # Set proper permissions
    chmod 600 "$ENV_FILE" 2>/dev/null || true
    chmod 600 "$TOKEN_FILE" 2>/dev/null || true
    
    log_success "Environment configured"
}

################################################################################
# Verification
################################################################################

verify_installation() {
    log_step "7/7" "Verifying installation..."
    
    source .venv/bin/activate
    
    # Check Python packages
    log_info "Checking Python packages..."
    if python -c "import fastapi, httpx, playwright" 2>/dev/null; then
        log_success "All Python packages installed"
    else
        log_error "Missing Python packages"
        exit 1
    fi
    
    # Check token
    if [ -f "$TOKEN_FILE" ]; then
        TOKEN_LENGTH=$(wc -c < "$TOKEN_FILE" | tr -d ' ')
        if [ "$TOKEN_LENGTH" -gt 100 ]; then
            log_success "Bearer token validated (${TOKEN_LENGTH} chars)"
        else
            log_warning "Token seems too short (${TOKEN_LENGTH} chars)"
        fi
    else
        log_error "Token file not found"
        exit 1
    fi
    
    log_success "Installation verified"
}

################################################################################
# Main Deployment Flow
################################################################################

main() {
    print_header
    
    log_info "Starting deployment process..."
    log_info "This will take 2-5 minutes..."
    echo ""
    
    # Run all deployment steps
    validate_credentials
    install_system_dependencies
    setup_python_environment
    install_playwright
    extract_token
    configure_environment
    verify_installation
    
    # Final summary
    print_footer
    echo -e "${GREEN}${BOLD}🎉 Deployment Complete!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. Start the server: ${YELLOW}bash scripts/start.sh${NC}"
    echo -e "  2. Test the API: ${YELLOW}bash scripts/send_openai_request.sh${NC}"
    echo -e "  3. Or run everything: ${YELLOW}bash scripts/all.sh${NC}"
    echo ""
    echo -e "${CYAN}Server will run on:${NC} ${YELLOW}http://localhost:${DEFAULT_PORT}${NC}"
    echo ""
    print_footer
}

# Run deployment
main "$@"

