#!/usr/bin/env bash
################################################################################
# setup.sh - Complete Setup with Playwright Token Extraction
#
# This script:
# 1. Installs dependencies
# 2. Uses Playwright to automatically login to chat.qwen.ai
# 3. Extracts token from localStorage
# 4. Saves token to .env file
#
# Usage:
#   export QWEN_EMAIL=your-email@example.com
#   export QWEN_PASSWORD=your-password
#   bash scripts/setup.sh
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
    echo -e "${MAGENTA}${BOLD}$(printf '=%.0s' {1..80})${NC}"
}

print_header() {
    clear
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                          ║"
    echo "║             🚀 Qwen API - Complete Setup with Playwright 🚀              ║"
    echo "║                                                                          ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

################################################################################
# Check Credentials
################################################################################

check_credentials() {
    log_step "1/6" "Checking credentials..."
    
    if [ -z "${QWEN_EMAIL:-}" ] || [ -z "${QWEN_PASSWORD:-}" ]; then
        log_error "Missing credentials!"
        echo ""
        echo -e "${YELLOW}Please set your credentials:${NC}"
        echo -e "  ${CYAN}export QWEN_EMAIL=your-email@example.com${NC}"
        echo -e "  ${CYAN}export QWEN_PASSWORD='your-password'${NC}"
        echo ""
        exit 1
    fi
    
    log_success "Credentials found"
    log_info "Email: ${QWEN_EMAIL}"
}

################################################################################
# Install System Dependencies
################################################################################

install_system_deps() {
    log_step "2/6" "Installing system dependencies..."
    
    if [ "$(uname)" == "Darwin" ]; then
        log_info "macOS detected"
        if ! command -v brew &> /dev/null; then
            log_error "Homebrew required. Install from https://brew.sh"
            exit 1
        fi
        brew install python@3.10 || true
        
    elif [ -f /etc/debian_version ]; then
        log_info "Debian/Ubuntu detected"
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            python3 \
            python3-pip \
            python3-venv \
            curl \
            git \
            build-essential
    fi
    
    log_success "System dependencies installed"
}

################################################################################
# Setup Python Environment
################################################################################

setup_python_env() {
    log_step "3/6" "Setting up Python environment..."
    
    # Install uv if not present
    if ! command -v uv &> /dev/null; then
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
        log_info "Virtual environment exists"
    fi
    
    # Activate virtual environment
    source .venv/bin/activate
    
    # Install dependencies
    log_info "Installing Python packages..."
    uv pip install -r requirements.txt --quiet
    
    log_success "Python environment ready"
}

################################################################################
# Install Playwright
################################################################################

install_playwright() {
    log_step "4/6" "Installing Playwright..."
    
    source .venv/bin/activate
    
    # Install Playwright package
    log_info "Installing Playwright Python package..."
    uv pip install playwright pytest-playwright --quiet
    
    # Install browser
    log_info "Installing Chromium browser (this may take a minute)..."
    playwright install chromium --with-deps 2>&1 | grep -v "^Downloading" || true
    
    log_success "Playwright installed"
}

################################################################################
# Extract Token with Playwright
################################################################################

extract_token() {
    log_step "5/6" "Extracting token with Playwright..."
    
    source .venv/bin/activate
    
    log_info "Starting automated browser login..."
    log_info "This will open a headless browser and extract your token"
    echo ""
    
    # Create token extraction script
    cat > /tmp/extract_qwen_token.py << 'PYTHON_SCRIPT'
import asyncio
import os
import sys
from playwright.async_api import async_playwright

async def extract_token():
    email = os.getenv("QWEN_EMAIL")
    password = os.getenv("QWEN_PASSWORD")
    
    if not email or not password:
        print("❌ ERROR: QWEN_EMAIL and QWEN_PASSWORD must be set")
        sys.exit(1)
    
    print(f"🌐 Opening browser to https://chat.qwen.ai/auth?action=signin")
    print(f"📧 Email: {email}")
    print("")
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        )
        page = await context.new_page()
        
        try:
            # Navigate to login page
            print("🔗 Navigating to login page...")
            await page.goto("https://chat.qwen.ai/auth?action=signin", 
                          wait_until='networkidle', timeout=30000)
            
            # Wait for login form
            print("⏳ Waiting for login form...")
            await page.wait_for_selector('input[type="email"], input[type="text"], input[name="email"]', 
                                        timeout=10000)
            
            # Fill email
            print("✏️  Filling email...")
            email_input = await page.query_selector('input[type="email"], input[type="text"], input[name="email"]')
            await email_input.fill(email)
            
            # Fill password
            print("🔒 Filling password...")
            password_input = await page.query_selector('input[type="password"], input[name="password"]')
            await password_input.fill(password)
            
            # Click login
            print("🚀 Clicking login button...")
            submit_button = await page.query_selector('button[type="submit"]')
            await submit_button.click()
            
            # Wait for successful login
            print("⏳ Waiting for login to complete...")
            try:
                await page.wait_for_url('**/chat**', timeout=20000)
                print("✅ Login successful - URL changed to chat page")
            except:
                try:
                    await page.wait_for_load_state('networkidle', timeout=20000)
                    print("✅ Login successful - network idle")
                except:
                    print("⚠️  Timeout waiting for login, checking for token anyway...")
            
            # Wait a bit for token to be set
            await asyncio.sleep(3)
            
            # Extract token with retries
            print("")
            print("🔑 Extracting token from localStorage...")
            
            token = None
            for attempt in range(10):
                token = await page.evaluate('''() => {
                    return localStorage.getItem('web_api_token')
                        || localStorage.getItem('token')
                        || localStorage.getItem('access_token');
                }''')
                
                if token:
                    print(f"✅ Token found on attempt {attempt + 1}")
                    break
                
                print(f"⏳ Attempt {attempt + 1}/10 - waiting for token...")
                await asyncio.sleep(2)
            
            await browser.close()
            
            if token:
                print("")
                print("="*80)
                print("✅ SUCCESS! Token extracted")
                print("="*80)
                print(f"Token length: {len(token)} characters")
                print("")
                print(f"TOKEN:{token}")
                return 0
            else:
                print("")
                print("❌ Failed to extract token after 10 attempts")
                print("Token not found in localStorage")
                return 1
                
        except Exception as e:
            print(f"❌ Error during token extraction: {e}")
            await browser.close()
            return 1

sys.exit(asyncio.run(extract_token()))
PYTHON_SCRIPT

    # Run token extraction
    TOKEN_OUTPUT=$(python /tmp/extract_qwen_token.py 2>&1)
    EXTRACTION_STATUS=$?
    
    echo "$TOKEN_OUTPUT"
    
    if [ $EXTRACTION_STATUS -eq 0 ]; then
        # Extract token from output
        BEARER_TOKEN=$(echo "$TOKEN_OUTPUT" | grep "^TOKEN:" | cut -d: -f2-)
        
        if [ -n "$BEARER_TOKEN" ]; then
            echo ""
            log_success "Token extracted successfully!"
            log_info "Token length: ${#BEARER_TOKEN} characters"
            
            # Save to .env
            if [ -f "$ENV_FILE" ]; then
                # Remove old token line if exists
                sed -i.bak '/^QWEN_BEARER_TOKEN=/d' "$ENV_FILE"
            else
                # Create new .env
                cat > "$ENV_FILE" << EOF
# Qwen API Configuration
QWEN_EMAIL=${QWEN_EMAIL}
QWEN_PASSWORD=${QWEN_PASSWORD}

# Server Configuration
LISTEN_PORT=8096
HOST=0.0.0.0

# Mode Configuration
ANONYMOUS_MODE=true
DEBUG_LOGGING=true

# Provider Configuration
QWEN_PROVIDER_MODE=auto
EOF
            fi
            
            # Append token
            echo "QWEN_BEARER_TOKEN=$BEARER_TOKEN" >> "$ENV_FILE"
            
            # Also save to separate token file
            echo "$BEARER_TOKEN" > "$TOKEN_FILE"
            chmod 600 "$TOKEN_FILE" 2>/dev/null || true
            
            log_success "Token saved to .env and .qwen_bearer_token"
            
            # Export for current session
            export QWEN_BEARER_TOKEN="$BEARER_TOKEN"
            
        else
            log_error "Failed to extract token from output"
            exit 1
        fi
    else
        log_error "Token extraction failed"
        exit 1
    fi
    
    # Cleanup
    rm -f /tmp/extract_qwen_token.py
}

################################################################################
# Verify Setup
################################################################################

verify_setup() {
    log_step "6/6" "Verifying setup..."
    
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
    
    # Check .env
    if [ -f "$ENV_FILE" ]; then
        log_success ".env file configured"
    else
        log_error ".env file not found"
        exit 1
    fi
    
    log_success "Setup verified"
}

################################################################################
# Main Flow
################################################################################

main() {
    print_header
    
    check_credentials
    install_system_deps
    setup_python_env
    install_playwright
    extract_token
    verify_setup
    
    # Final summary
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                          ║"
    echo "║                    ✅ SETUP COMPLETE! ✅                                  ║"
    echo "║                                                                          ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}Next steps:${NC}"
    echo -e "  1. Start server: ${YELLOW}bash scripts/start.sh${NC}"
    echo -e "  2. Test API: ${YELLOW}bash scripts/send_request.sh${NC}"
    echo -e "  3. Or run everything: ${YELLOW}bash scripts/all.sh${NC}"
    echo ""
    echo -e "${CYAN}Token location:${NC}"
    echo -e "  • ${YELLOW}$ENV_FILE${NC}"
    echo -e "  • ${YELLOW}$TOKEN_FILE${NC}"
    echo ""
}

# Run main
main "$@"

