#!/usr/bin/env bash
################################################################################
# setup.sh - Complete Setup with Python Version Management & Playwright
#
# This script:
# 1. Checks and sets up correct Python version (3.10+)
# 2. Creates virtual environment with proper Python version
# 3. Installs all dependencies
# 4. Installs Playwright and Chromium browser
# 5. Uses Playwright to automatically login to chat.qwen.ai
# 6. Extracts token from localStorage
# 7. Saves token to .env file
# 8. Activates virtual environment for subsequent scripts
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
readonly VENV_DIR="${PROJECT_ROOT}/.venv"
readonly VENV_ACTIVATE="${VENV_DIR}/bin/activate"

# Required Python version
readonly MIN_PYTHON_MAJOR=3
readonly MIN_PYTHON_MINOR=10

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
    echo "║        🚀 Qwen API - Complete Setup with Python & Playwright 🚀          ║"
    echo "║                                                                          ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

################################################################################
# Check Credentials
################################################################################

check_credentials() {
    log_step "1/8" "Checking credentials..."
    
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
# Find Compatible Python Version
################################################################################

find_python() {
    log_step "2/8" "Finding compatible Python version (>= 3.10)..."
    
    # List of Python commands to try
    local python_variants=(
        "python3.13"
        "python3.12"
        "python3.11"
        "python3.10"
        "python3"
        "python"
    )
    
    for cmd in "${python_variants[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            local version=$($cmd --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
            local major=$(echo $version | cut -d. -f1)
            local minor=$(echo $version | cut -d. -f2)
            
            log_info "Found $cmd: Python $version"
            
            # Check if version meets minimum requirements
            if [ "$major" -gt "$MIN_PYTHON_MAJOR" ] || \
               ([ "$major" -eq "$MIN_PYTHON_MAJOR" ] && [ "$minor" -ge "$MIN_PYTHON_MINOR" ]); then
                log_success "Using $cmd (Python $version)"
                # Store in global variable instead of echoing
                PYTHON_CMD="$cmd"
                return 0
            else
                log_warning "$cmd is too old (Python $version < 3.10)"
            fi
        fi
    done
    
    log_error "No compatible Python version found (need >= 3.10)"
    echo ""
    echo -e "${YELLOW}Please install Python 3.10 or higher:${NC}"
    echo -e "  ${CYAN}Ubuntu/Debian: sudo apt install python3.11${NC}"
    echo -e "  ${CYAN}macOS: brew install python@3.11${NC}"
    echo ""
    exit 1
}

################################################################################
# Install System Dependencies
################################################################################

install_system_deps() {
    log_step "3/8" "Installing system dependencies..."
    
    if [ "$(uname)" == "Darwin" ]; then
        log_info "macOS detected"
        if ! command -v brew &> /dev/null; then
            log_error "Homebrew required. Install from https://brew.sh"
            exit 1
        fi
        
        # Ensure Python 3.10+ is installed
        if ! brew list python@3.11 &>/dev/null; then
            log_info "Installing Python 3.11..."
            brew install python@3.11
        fi
        
    elif [ -f /etc/debian_version ]; then
        log_info "Debian/Ubuntu detected"
        
        # Update package list
        log_info "Updating package list..."
        sudo apt-get update -qq
        
        # Install Python 3.11 if not present
        if ! command -v python3.11 &> /dev/null; then
            log_info "Installing Python 3.11..."
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository -y ppa:deadsnakes/ppa 2>/dev/null || true
            sudo apt-get update -qq
            sudo apt-get install -y python3.11 python3.11-venv python3.11-dev
        fi
        
        # Install other dependencies
        log_info "Installing system packages..."
        sudo apt-get install -y -qq \
            python3-pip \
            curl \
            git \
            build-essential \
            libssl-dev \
            libffi-dev
    fi
    
    log_success "System dependencies installed"
}

################################################################################
# Setup Python Virtual Environment
################################################################################

setup_python_env() {
    log_step "4/8" "Setting up Python virtual environment..."
    
    # Python command already set by find_python() in main flow
    if [ -z "$PYTHON_CMD" ]; then
        log_error "Failed to find compatible Python version"
        exit 1
    fi
    
    log_info "Using Python: $PYTHON_CMD"
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    log_info "Python version: $PYTHON_VERSION"
    
    # Remove old virtual environment if it exists with wrong Python version
    if [ -d "$VENV_DIR" ]; then
        if [ -f "$VENV_ACTIVATE" ]; then
            # Check if existing venv has correct Python version
            EXISTING_PYTHON=$("$VENV_DIR/bin/python" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
            EXISTING_MAJOR=$(echo $EXISTING_PYTHON | cut -d. -f1)
            EXISTING_MINOR=$(echo $EXISTING_PYTHON | cut -d. -f2)
            
            if [ "$EXISTING_MAJOR" -lt "$MIN_PYTHON_MAJOR" ] || \
               ([ "$EXISTING_MAJOR" -eq "$MIN_PYTHON_MAJOR" ] && [ "$EXISTING_MINOR" -lt "$MIN_PYTHON_MINOR" ]); then
                log_warning "Existing venv has old Python $EXISTING_PYTHON, recreating..."
                rm -rf "$VENV_DIR"
            else
                log_info "Existing venv has compatible Python $EXISTING_PYTHON"
            fi
        fi
    fi
    
    # Create virtual environment if needed
    if [ ! -d "$VENV_DIR" ]; then
        log_info "Creating virtual environment with $PYTHON_CMD..."
        $PYTHON_CMD -m venv "$VENV_DIR"
        log_success "Virtual environment created"
    else
        log_success "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    log_info "Activating virtual environment..."
    source "$VENV_ACTIVATE"
    
    # Verify activation
    if [ "$VIRTUAL_ENV" != "$VENV_DIR" ]; then
        log_error "Failed to activate virtual environment"
        exit 1
    fi
    
    log_success "Virtual environment activated"
    log_info "Virtual env: $VIRTUAL_ENV"
    log_info "Python: $(python --version)"
    
    # Upgrade pip
    log_info "Upgrading pip..."
    python -m pip install --upgrade pip --quiet
    log_success "pip upgraded"
}

################################################################################
# Install Python Dependencies
################################################################################

install_python_deps() {
    log_step "5/8" "Installing Python dependencies..."
    
    # Ensure we're in virtual environment
    if [ -z "${VIRTUAL_ENV:-}" ]; then
        log_info "Activating virtual environment..."
        source "$VENV_ACTIVATE"
    fi
    
    # Install requirements
    log_info "Installing packages from requirements.txt..."
    pip install -r requirements.txt --quiet
    
    log_success "Python dependencies installed"
}

################################################################################
# Install Playwright
################################################################################

install_playwright() {
    log_step "6/8" "Installing Playwright..."
    
    # Ensure we're in virtual environment
    if [ -z "${VIRTUAL_ENV:-}" ]; then
        source "$VENV_ACTIVATE"
    fi
    
    # Install Playwright package (should already be in requirements.txt)
    log_info "Verifying Playwright installation..."
    pip show playwright &>/dev/null || pip install playwright --quiet
    
    # Install Chromium browser with dependencies
    log_info "Installing Chromium browser (this may take a minute)..."
    
    if [ "$(uname)" == "Linux" ]; then
        # Install system dependencies for Playwright on Linux
        log_info "Installing Playwright system dependencies..."
        playwright install-deps chromium 2>&1 | grep -v "^Downloading" || true
    fi
    
    # Install browser
    playwright install chromium 2>&1 | grep -v "^Downloading" || true
    
    log_success "Playwright installed"
}

################################################################################
# Extract Token with Playwright
################################################################################

extract_token() {
    log_step "7/8" "Extracting token with Playwright..."
    
    # Ensure we're in virtual environment
    if [ -z "${VIRTUAL_ENV:-}" ]; then
        source "$VENV_ACTIVATE"
    fi
    
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
                sed -i.bak '/^QWEN_BEARER_TOKEN=/d' "$ENV_FILE" 2>/dev/null || \
                    sed -i '' '/^QWEN_BEARER_TOKEN=/d' "$ENV_FILE" 2>/dev/null || true
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
    log_step "8/8" "Verifying setup..."
    
    # Ensure we're in virtual environment
    if [ -z "${VIRTUAL_ENV:-}" ]; then
        source "$VENV_ACTIVATE"
    fi
    
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
# Create Activation Helper
################################################################################

create_activation_helper() {
    echo ""
    log_info "Creating virtual environment activation helper..."
    
    # Create activate.sh helper script
    cat > "${PROJECT_ROOT}/activate.sh" << 'EOF'
#!/usr/bin/env bash
# Quick activation script for virtual environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_ACTIVATE="${SCRIPT_DIR}/.venv/bin/activate"

if [ -f "$VENV_ACTIVATE" ]; then
    source "$VENV_ACTIVATE"
    echo "✓ Virtual environment activated"
    echo "Python: $(python --version)"
    echo "Location: $VIRTUAL_ENV"
else
    echo "✗ Virtual environment not found"
    echo "Run: bash scripts/setup.sh"
    exit 1
fi
EOF
    
    chmod +x "${PROJECT_ROOT}/activate.sh"
    log_success "Created activate.sh helper"
}

################################################################################
# Main Flow
################################################################################

main() {
    print_header
    
    check_credentials
    find_python
    install_system_deps
    setup_python_env
    install_python_deps
    install_playwright
    extract_token
    verify_setup
    create_activation_helper
    
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
    echo -e "${CYAN}${BOLD}Virtual Environment:${NC}"
    echo -e "  ${YELLOW}$VENV_DIR${NC}"
    echo -e "  ${CYAN}Python: $(python --version)${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}To activate manually:${NC}"
    echo -e "  ${YELLOW}source .venv/bin/activate${NC}"
    echo -e "  ${YELLOW}# or${NC}"
    echo -e "  ${YELLOW}source activate.sh${NC}"
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
