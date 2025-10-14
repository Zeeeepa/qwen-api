#!/usr/bin/env bash
################################################################################
# setup.sh - Complete Environment Setup for Qwen API Server
# Features:
# - Python environment setup with uv
# - Dependency installation
# - Playwright browser setup (with Ubuntu 24.04 compatibility)
# - Bearer token extraction (automated + manual fallback)
# - Environment validation
# - Error handling and user guidance
################################################################################

set -e

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${MAGENTA}[STEP $1]${NC} $2"; }

# Header
print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                   QWEN API - COMPLETE SETUP WIZARD"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Footer
print_footer() {
    echo -e "${GREEN}${BOLD}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                         SETUP COMPLETED SUCCESSFULLY! ✓"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Check system requirements
check_system_requirements() {
    log_step "1/8" "Checking system requirements..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 not found! Please install Python 3.8+"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')")
    log_info "Python version: $PYTHON_VERSION"
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        log_error "curl not found! Please install curl"
        exit 1
    fi
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
    else
        OS_NAME="$(uname -s)"
        OS_VERSION="$(uname -r)"
    fi
    log_info "Detected OS: $OS_NAME $OS_VERSION"
    
    log_success "System requirements satisfied"
}

# Install uv package manager
install_uv() {
    log_step "2/8" "Setting up UV package manager..."
    
    if ! command -v uv &> /dev/null; then
        log_warning "UV not found, installing..."
        
        # Install uv
        curl -LsSf https://astral.sh/uv/install.sh | sh
        
        # Add to PATH for current session
        export PATH="$HOME/.cargo/bin:$PATH"
        
        # Verify installation
        if ! command -v uv &> /dev/null; then
            log_error "UV installation failed!"
            exit 1
        fi
        
        log_success "UV installed successfully"
    else
        UV_VERSION=$(uv --version)
        log_success "UV already installed: $UV_VERSION"
    fi
}

# Create virtual environment
setup_virtual_environment() {
    log_step "3/8" "Setting up Python virtual environment..."
    
    if [ ! -d ".venv" ]; then
        log_info "Creating virtual environment..."
        uv venv
        
        if [ ! -d ".venv" ]; then
            log_error "Virtual environment creation failed!"
            exit 1
        fi
        
        log_success "Virtual environment created"
    else
        log_success "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    source .venv/bin/activate
}

# Install dependencies
install_dependencies() {
    log_step "4/8" "Installing Python dependencies..."
    
    # Check if requirements.txt exists
    if [ ! -f "requirements.txt" ]; then
        log_error "requirements.txt not found!"
        exit 1
    fi
    
    log_info "Installing from requirements.txt..."
    if uv pip install -r requirements.txt; then
        log_success "Main dependencies installed"
    else
        log_error "Failed to install main dependencies"
        exit 1
    fi
    
    # Install Playwright for Python
    log_info "Installing Playwright Python package..."
    if uv pip install playwright pytest-playwright; then
        log_success "Playwright Python package installed"
    else
        log_error "Failed to install Playwright"
        exit 1
    fi
}

# Install system dependencies and browser
install_system_dependencies() {
    log_step "5/8" "Installing system dependencies and browser..."
    
    # Install system dependencies based on OS
    case "$OS_NAME" in
        *Ubuntu*|*Debian*)
            install_ubuntu_dependencies
            ;;
        *CentOS*|*Red*Hat*|*Fedora*)
            install_centos_dependencies
            ;;
        *Darwin*|*Mac*)
            install_macos_dependencies
            ;;
        *)
            log_warning "Unsupported OS: $OS_NAME - attempting generic installation"
            install_generic_dependencies
            ;;
    esac
    
    # Install Chromium browser
    log_info "Installing Chromium browser..."
    if python3 -m playwright install chromium; then
        log_success "Chromium browser installed"
    else
        log_warning "Chromium installation had issues, but continuing..."
    fi
}

# Ubuntu/Debian specific dependencies
install_ubuntu_dependencies() {
    log_info "Installing Ubuntu/Debian dependencies..."
    
    # Handle Ubuntu 24.04+ with t64 libraries
    if [[ "$OS_VERSION" == "24.04" || "$OS_VERSION" > "24.04" ]]; then
        log_info "Ubuntu 24.04+ detected - installing t64 compatible packages"
        
        local packages=(
            libasound2t64 libatk-bridge2.0-0t64 libatk1.0-0t64
            libatspi2.0-0t64 libcups2t64 libdrm2 libgbm1
            libglib2.0-0t64 libnspr4 libnss3 libpango-1.0-0
            libx11-6 libxcb1 libxcomposite1 libxdamage1
            libxext6 libxfixes3 libxkbcommon0 libxrandr2
            xvfb fonts-liberation fonts-noto-color-emoji
            libnss3-dev libgdk-pixbuf2.0-dev libgtk-3-dev
        )
    else
        # Standard Ubuntu/Debian packages
        local packages=(
            libasound2 libatk-bridge2.0-0 libatk1.0-0
            libatspi2.0-0 libcups2 libdrm2 libgbm1
            libglib2.0-0 libnspr4 libnss3 libpango-1.0-0
            libx11-6 libxcb1 libxcomposite1 libxdamage1
            libxext6 libxfixes3 libxkbcommon0 libxrandr2
            xvfb fonts-liberation fonts-noto-color-emoji
            libnss3-dev libgdk-pixbuf2.0-dev libgtk-3-dev
        )
    fi
    
    if [ "$EUID" -ne 0 ]; then
        log_info "Installing system packages (requires sudo)..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq "${packages[@]}"
    else
        apt-get update -qq
        apt-get install -y -qq "${packages[@]}"
    fi
    
    log_success "Ubuntu/Debian dependencies installed"
}

# CentOS/RHEL/Fedora specific dependencies
install_centos_dependencies() {
    log_info "Installing CentOS/RHEL/Fedora dependencies..."
    
    local packages=(
        alsa-lib-devel atk-devel cups-devel dbus-devel
        gdk-pixbuf2-devel glib2-devel gtk3-devel
        libXcomposite-devel libXdamage-devel libXrandr-devel
        libxkbcommon-devel mesa-libgbm-devel nss-devel
        pango-devel xorg-x11-server-Xvfb
        liberation-fonts noto-emoji-fonts
    )
    
    if command -v dnf &> /dev/null; then
        if [ "$EUID" -ne 0 ]; then
            sudo dnf install -y "${packages[@]}"
        else
            dnf install -y "${packages[@]}"
        fi
    elif command -v yum &> /dev/null; then
        if [ "$EUID" -ne 0 ]; then
            sudo yum install -y "${packages[@]}"
        else
            yum install -y "${packages[@]}"
        fi
    fi
    
    log_success "CentOS/RHEL/Fedora dependencies installed"
}

# macOS specific dependencies
install_macos_dependencies() {
    log_info "Installing macOS dependencies..."
    
    if command -v brew &> /dev/null; then
        brew install libomp
    else
        log_warning "Homebrew not found - some dependencies may be missing"
    fi
    
    log_success "macOS dependencies handled"
}

# Generic dependency installation
install_generic_dependencies() {
    log_info "Attempting generic system dependency installation..."
    
    if command -v playwright &> /dev/null; then
        if [ "$EUID" -ne 0 ]; then
            sudo playwright install-deps chromium || true
        else
            playwright install-deps chromium || true
        fi
    else
        python3 -m playwright install-deps chromium || true
    fi
    
    log_warning "Generic installation attempted - may need manual intervention"
}

# Setup environment configuration
setup_environment() {
    log_step "6/8" "Setting up environment configuration..."
    
    # Create .env from example if it doesn't exist
    if [ ! -f ".env" ]; then
        log_warning ".env file not found, creating from template..."
        
        if [ -f ".env.example" ]; then
            cp .env.example .env
            log_success "Created .env from .env.example"
        else
            # Create basic .env file
            cat > .env << 'EOF'
# Qwen API Configuration
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password-here
QWEN_BEARER_TOKEN=your-bearer-token-here

# Server Configuration
LISTEN_PORT=8096
HOST=0.0.0.0
LOG_LEVEL=INFO

# Feature Flags
ANONYMOUS_MODE=false
DEBUG_LOGGING=true
ENABLE_RATE_LIMITING=true

# API Settings
MAX_TOKENS=4096
TIMEOUT=30
EOF
            log_success "Created basic .env file"
        fi
        
        log_warning "Please edit .env and add your Qwen credentials"
    else
        log_success ".env file already exists"
    fi
    
    # Validate .env structure
    if ! grep -q "QWEN_EMAIL" .env || ! grep -q "QWEN_PASSWORD" .env; then
        log_warning ".env file may be missing required Qwen credentials"
    fi
}

# Extract bearer token
extract_bearer_token() {
    log_step "7/8" "Extracting Bearer Token..."
    
    # Load environment variables
    set -a
    source .env
    set +a
    
    # Check if we already have a valid token
    if [ -n "$QWEN_BEARER_TOKEN" ] && [ "$QWEN_BEARER_TOKEN" != "your-bearer-token-here" ]; then
        log_success "Bearer token already configured"
        echo -e "${CYAN}Token preview: ${QWEN_BEARER_TOKEN:0:20}...${QWEN_BEARER_TOKEN: -20}${NC}"
        echo -e "${CYAN}Token length: ${#QWEN_BEARER_TOKEN} characters${NC}"
        return 0
    fi
    
    # Check if credentials are configured
    if [ -z "$QWEN_EMAIL" ] || [ "$QWEN_EMAIL" = "your-email@example.com" ] || \
       [ -z "$QWEN_PASSWORD" ] || [ "$QWEN_PASSWORD" = "your-password-here" ]; then
        log_error "Qwen credentials not properly configured in .env"
        echo -e "${YELLOW}Please edit .env and add your real email and password:${NC}"
        echo -e "  ${WHITE}QWEN_EMAIL=your-real-email@example.com${NC}"
        echo -e "  ${WHITE}QWEN_PASSWORD=your-real-password${NC}"
        echo ""
        echo -e "${YELLOW}Then run this script again.${NC}"
        exit 1
    fi
    
    log_info "Attempting automated token extraction..."
    
    # Try automated extraction (updated path: tests/integration/test_auth.py)
    if python3 tests/integration/test_auth.py > /tmp/token_extraction.log 2>&1; then
        # Extract token from output
        TOKEN=$(grep "QWEN_BEARER_TOKEN=" /tmp/token_extraction.log | cut -d'=' -f2 | tr -d '[:space:]')
        
        if [ -n "$TOKEN" ] && [ ${#TOKEN} -gt 50 ]; then
            save_bearer_token "$TOKEN"
            return 0
        fi
    fi
    
    log_warning "Automated extraction failed, using manual method..."
    manual_token_extraction
}

# Save bearer token to .env
save_bearer_token() {
    local token="$1"
    
    log_info "Saving bearer token to .env..."
    
    # Create backup
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    
    # Update or add token
    if grep -q "QWEN_BEARER_TOKEN=" .env; then
        sed -i.tmp "s|QWEN_BEARER_TOKEN=.*|QWEN_BEARER_TOKEN=$token|" .env
        rm -f .env.tmp
    else
        echo "QWEN_BEARER_TOKEN=$token" >> .env
    fi
    
    log_success "Bearer token saved to .env"
    echo -e "${CYAN}Token length: ${#token} characters${NC}"
    echo -e "${CYAN}Token preview: ${token:0:20}...${token: -20}${NC}"
}

# Manual token extraction fallback
manual_token_extraction() {
    log_warning "Automated token extraction unavailable or failed"
    echo -e "${YELLOW}${BOLD}Manual Token Extraction Required${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}Follow these steps to get your Bearer Token:${NC}"
    echo ""
    echo -e "  ${BOLD}1.${NC} ${WHITE}Open your browser and go to: ${CYAN}https://chat.qwen.ai${NC}"
    echo -e "  ${BOLD}2.${NC} ${WHITE}Log in with your Qwen account${NC}"
    echo -e "  ${BOLD}3.${NC} ${WHITE}Press ${BOLD}F12${NC} to open Developer Tools${NC}"
    echo -e "  ${BOLD}4.${NC} ${WHITE}Go to the ${BOLD}Console${NC} tab${NC}"
    echo -e "  ${BOLD}5.${NC} ${WHITE}Copy and paste this code:${NC}"
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
    cat << 'JSCODE'
// Token Extraction Script for Qwen
(function() {
    if (window.location.hostname !== "chat.qwen.ai") {
        alert("Please navigate to https://chat.qwen.ai first!");
        window.open("https://chat.qwen.ai", "_blank");
        return;
    }
    
    const token = localStorage.getItem("token");
    if (!token) {
        const keys = Object.keys(localStorage);
        console.log("Available localStorage keys:", keys);
        alert("Token not found in 'token' key. Check console for available keys.");
        return;
    }
    
    // Try to copy to clipboard
    navigator.clipboard.writeText(token).then(() => {
        alert(`✅ Token copied to clipboard! (${token.length} chars)`);
        console.log("Token:", token);
    }).catch(() => {
        // Fallback: show prompt
        prompt("📋 Copy your token (select and press Ctrl+C):", token);
    });
})();
JSCODE
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${BOLD}6.${NC} ${WHITE}Press ${BOLD}Enter${NC} to execute the code${NC}"
    echo -e "  ${BOLD}7.${NC} ${WHITE}The token will be copied to your clipboard${NC}"
    echo -e "  ${BOLD}8.${NC} ${WHITE}Paste it below when prompted${NC}"
    echo ""
    echo -e "${YELLOW}Press Enter to continue and paste your token...${NC}"
    read -r
    
    echo -e "${CYAN}Please paste your Bearer Token:${NC}"
    read -r MANUAL_TOKEN
    
    # Clean the token
    MANUAL_TOKEN=$(echo "$MANUAL_TOKEN" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Validate token
    if [ -z "$MANUAL_TOKEN" ]; then
        log_error "No token provided!"
        exit 1
    fi
    
    if [ ${#MANUAL_TOKEN} -lt 50 ]; then
        log_warning "Token seems short (${#MANUAL_TOKEN} chars). Expected > 50 characters."
        echo -e "${YELLOW}Are you sure this is the correct token? (y/N):${NC}"
        read -r CONFIRM
        if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
            log_error "Token rejected by user"
            exit 1
        fi
    fi
    
    save_bearer_token "$MANUAL_TOKEN"
}

# Final validation and summary
final_validation() {
    log_step "8/8" "Final validation and cleanup..."
    
    # Reload environment to verify token
    set -a
    source .env
    set +a
    
    # Verify token is loadable
    if [ -n "$QWEN_BEARER_TOKEN" ]; then
        log_success "✓ Token loads successfully into environment"
    else
        log_error "✗ Token failed to load into environment"
        exit 1
    fi
    
    # Test token with Python
    log_info "Validating token with Python..."
    if python3 -c "
import os
from dotenv import load_dotenv
load_dotenv()
token = os.getenv('QWEN_BEARER_TOKEN')
if token and len(token) > 50:
    print('✅ Token validated successfully')
    print(f'   Length: {len(token)} characters')
else:
    print('❌ Token validation failed')
    exit(1)
"; then
        log_success "Token validation passed"
    else
        log_error "Token validation failed"
        exit 1
    fi
    
    # Cleanup
    rm -f /tmp/token_extraction.log .env.tmp .env.bak
    
    log_success "Setup validation completed"
}

# Main execution
main() {
    print_header
    
    # Check if we're in the right directory
    if [ ! -f "requirements.txt" ] && [ ! -f "main.py" ]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Execute setup steps
    check_system_requirements
    install_uv
    setup_virtual_environment
    install_dependencies
    install_system_dependencies
    setup_environment
    extract_bearer_token
    final_validation
    
    print_footer
    
    # Show next steps
    echo -e "${CYAN}${BOLD}Next Steps:${NC}"
    echo -e "  ${GREEN}→${NC} ${WHITE}Start the server:${NC} ${BOLD}bash scripts/start.sh${NC}"
    echo -e "  ${GREEN}→${NC} ${WHITE}Test the API:${NC} ${BOLD}bash scripts/send_request.sh${NC}"
    echo -e "  ${GREEN}→${NC} ${WHITE}Run complete test suite:${NC} ${BOLD}bash scripts/all.sh${NC}"
    echo ""
    echo -e "${CYAN}Your environment is now ready! The Bearer Token has been configured.${NC}"
    echo ""
    
    # Offer to start server
    echo -e "${YELLOW}Would you like to start the server now? (y/N):${NC}"
    read -r start_server
    if [[ $start_server =~ ^[Yy]$ ]]; then
        echo ""
        bash scripts/start.sh
    fi
}

# Run main function
main "$@"
