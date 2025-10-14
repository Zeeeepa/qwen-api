#!/usr/bin/env bash
################################################################################
# setup.sh - Qwen API Environment Setup and Bearer Token Retrieval
# 
# This script:
# - Validates Python installation
# - Sets up uv package manager
# - Creates virtual environment
# - Installs Python dependencies
# - Installs Playwright with system dependencies
# - Retrieves Bearer token (automated or manual)
#
# Compatible with Ubuntu 24.04 (Noble) t64 library transitions
################################################################################

set -euo pipefail

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Project paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly VENV_DIR="${PROJECT_ROOT}/.venv"
readonly ENV_FILE="${PROJECT_ROOT}/.env"
readonly ENV_EXAMPLE="${PROJECT_ROOT}/.env.example"

# Configuration
readonly MIN_PYTHON_VERSION="3.8"
readonly MIN_TOKEN_LENGTH=50

cd "$PROJECT_ROOT"

################################################################################
# Utility Functions
################################################################################

log_step() {
    echo -e "${BLUE}[$1/$2]${NC} $3"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_info() {
    echo -e "${CYAN}$1${NC}"
}

print_header() {
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}    Qwen API - Environment Setup & Token Retrieval     ${NC}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"
}

print_footer() {
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}            Setup Complete! ✓                          ${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"
}

version_compare() {
    printf '%s\n%s' "$1" "$2" | sort -V | head -n1
}

################################################################################
# Setup Functions
################################################################################

check_python() {
    log_step 1 7 "Checking Python installation..."
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 not found!"
        echo -e "${YELLOW}Please install Python 3.${MIN_PYTHON_VERSION}+ first${NC}\n"
        exit 1
    fi
    
    local python_version
    python_version=$(python3 --version | awk '{print $2}')
    
    if [[ "$(version_compare "$python_version" "$MIN_PYTHON_VERSION")" == "$python_version" ]]; then
        log_error "Python version $python_version is too old (minimum: $MIN_PYTHON_VERSION)"
        exit 1
    fi
    
    log_success "Python $python_version found"
    echo ""
}

setup_uv() {
    log_step 2 7 "Setting up uv package manager..."
    
    if ! command -v uv &> /dev/null; then
        log_warning "uv not found, installing..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.cargo/bin:$PATH"
        log_success "uv installed"
    else
        log_success "uv already installed"
    fi
    echo ""
}

create_venv() {
    log_step 3 7 "Setting up virtual environment..."
    
    if [[ -d "$VENV_DIR" ]]; then
        log_success "Virtual environment already exists"
    else
        uv venv "$VENV_DIR"
        log_success "Virtual environment created"
    fi
    echo ""
}

install_dependencies() {
    log_step 4 7 "Installing Python dependencies..."
    
    # shellcheck source=/dev/null
    source "$VENV_DIR/bin/activate"
    
    uv pip install -r requirements.txt --quiet
    log_success "Core dependencies installed"
    
    pip install pytest-playwright --quiet 2>/dev/null || pip install pytest-playwright
    log_success "Playwright Python package installed"
    echo ""
}

detect_os() {
    local os_id version_id
    
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        os_id="$ID"
        version_id="$VERSION_ID"
    else
        os_id=$(uname -s)
        version_id=""
    fi
    
    echo "$os_id $version_id"
}

install_playwright_ubuntu_noble() {
    log_warning "Ubuntu 24.04 detected - installing t64 compatible dependencies"
    
    local sudo_cmd=""
    [[ "$EUID" -ne 0 ]] && sudo_cmd="sudo"
    
    log_info "Installing system dependencies..."
    
    # Ubuntu 24.04 (Noble) specific t64 libraries
    local -a packages=(
        libasound2t64
        libatk-bridge2.0-0t64
        libatk1.0-0t64
        libatspi2.0-0t64
        libcups2t64
        libdrm2
        libgbm1
        libglib2.0-0t64
        libnspr4
        libnss3
        libpango-1.0-0
        libx11-6
        libxcb1
        libxcomposite1
        libxdamage1
        libxext6
        libxfixes3
        libxkbcommon0
        libxrandr2
        xvfb
        fonts-liberation
        fonts-noto-color-emoji
    )
    
    $sudo_cmd apt-get update -qq
    $sudo_cmd apt-get install -y -qq "${packages[@]}" 2>&1 | \
        grep -v "Selecting previously unselected\|Unpacking\|Setting up" || true
    
    log_success "System dependencies installed"
    
    log_info "Installing Chromium browser..."
    playwright install chromium --quiet 2>/dev/null || playwright install chromium
    log_success "Chromium browser installed"
}

install_playwright_standard() {
    local sudo_cmd=""
    [[ "$EUID" -ne 0 ]] && sudo_cmd="sudo"
    
    log_info "Installing Playwright system dependencies..."
    
    if $sudo_cmd playwright install-deps chromium --quiet 2>/dev/null; then
        log_success "System dependencies installed"
    else
        log_warning "Standard installation method, using alternative approach..."
        $sudo_cmd playwright install-deps chromium
    fi
    
    log_info "Installing Chromium browser..."
    playwright install chromium --quiet 2>/dev/null || playwright install chromium
    log_success "Chromium browser installed"
}

install_playwright() {
    log_step 5 7 "Installing Playwright and system dependencies..."
    
    local os_info
    os_info=$(detect_os)
    log_info "Detected OS: $os_info"
    
    if [[ "$os_info" == "ubuntu 24.04" ]]; then
        install_playwright_ubuntu_noble
    else
        install_playwright_standard
    fi
    echo ""
}

create_env_file() {
    if [[ -f "$ENV_EXAMPLE" ]]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
    else
        cat > "$ENV_FILE" << 'EOF'
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password
LISTEN_PORT=8096
ANONYMOUS_MODE=true
DEBUG_LOGGING=true
EOF
    fi
}

load_env() {
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
}

validate_credentials() {
    if [[ -z "${QWEN_EMAIL:-}" ]] || [[ "$QWEN_EMAIL" == "your-email@example.com" ]]; then
        log_error "QWEN_EMAIL not properly configured in .env"
        log_warning "Please edit .env and add your real email address"
        return 1
    fi
    
    if [[ -z "${QWEN_PASSWORD:-}" ]] || [[ "$QWEN_PASSWORD" == "your-password" ]]; then
        log_error "QWEN_PASSWORD not properly configured in .env"
        log_warning "Please edit .env and add your real password"
        return 1
    fi
    
    return 0
}

check_existing_token() {
    if [[ -n "${QWEN_BEARER_TOKEN:-}" ]] && [[ "$QWEN_BEARER_TOKEN" != "your-bearer-token-here" ]]; then
        log_success "Bearer token found in .env (${#QWEN_BEARER_TOKEN} chars)"
        log_info "Token preview: ${QWEN_BEARER_TOKEN:0:30}...${QWEN_BEARER_TOKEN: -30}"
        return 0
    fi
    return 1
}

extract_token_automated() {
    log_info "Method 1: Automated Playwright extraction..."
    
    local log_file="/tmp/token_extraction_$$.log"
    
    if python3 test_auth.py > "$log_file" 2>&1; then
        local token
        token=$(grep "QWEN_BEARER_TOKEN=" "$log_file" | cut -d'=' -f2)
        
        if [[ -n "$token" ]]; then
            save_token_to_env "$token"
            log_success "Bearer token extracted and saved (${#token} chars)"
            log_info "Token preview: ${token:0:30}...${token: -30}"
            rm -f "$log_file"
            return 0
        else
            log_warning "Automated extraction didn't find token"
            cat "$log_file"
            rm -f "$log_file"
            return 1
        fi
    else
        log_warning "Automated extraction failed"
        cat "$log_file"
        rm -f "$log_file"
        return 1
    fi
}

print_manual_instructions() {
    echo -e "\n${BLUE}Method 2:${NC} Manual token extraction"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Please follow these steps to get your token manually:${NC}\n"
    
    echo -e "${WHITE}1.${NC} Open your browser and go to: ${CYAN}https://chat.qwen.ai${NC}"
    echo -e "${WHITE}2.${NC} Log in to your Qwen account"
    echo -e "${WHITE}3.${NC} Press ${BOLD}F12${NC} to open Developer Console"
    echo -e "${WHITE}4.${NC} Go to the ${BOLD}Console${NC} tab"
    echo -e "${WHITE}5.${NC} Copy and paste this JavaScript code:\n"
    
    echo -e "${CYAN}─────────────────────────────────────────────────────────${NC}"
    cat << 'JSEOF'
javascript:(function(){
    if(window.location.hostname!=="chat.qwen.ai"){
        alert("🚀 Please run this on chat.qwen.ai");
        window.open("https://chat.qwen.ai","_blank");
        return;
    }
    const token=localStorage.getItem("token");
    if(!token){
        alert("❌ Token not found in localStorage!");
        console.log("Available localStorage keys:", Object.keys(localStorage));
        return;
    }
    navigator.clipboard.writeText(token).then(()=>{
        alert("🔑 Token copied to clipboard! 🎉");
        console.log("Token length:", token.length, "characters");
    }).catch(()=>{
        prompt("🔰 Your token (copy it manually):", token);
    });
})();
JSEOF
    echo -e "${CYAN}─────────────────────────────────────────────────────────${NC}\n"
    
    echo -e "${WHITE}6.${NC} Press ${BOLD}Enter${NC} to run the code"
    echo -e "${WHITE}7.${NC} The token will be copied to your clipboard"
    echo -e "${WHITE}8.${NC} Paste it below when prompted\n"
}

extract_token_manual() {
    print_manual_instructions
    
    echo -e "${YELLOW}After you have the token, press Enter to continue...${NC}"
    read -r
    
    echo -e "${CYAN}Please paste your Bearer token:${NC}"
    read -r manual_token
    
    if [[ -z "$manual_token" ]]; then
        log_error "No token provided"
        return 1
    fi
    
    # Trim whitespace
    manual_token=$(echo "$manual_token" | xargs)
    
    # Validate token length
    if [[ ${#manual_token} -lt $MIN_TOKEN_LENGTH ]]; then
        log_error "Token seems too short (${#manual_token} chars). Expected > $MIN_TOKEN_LENGTH chars"
        log_warning "Please run the script again and make sure to copy the full token"
        return 1
    fi
    
    save_token_to_env "$manual_token"
    log_success "Bearer token saved to .env (${#manual_token} chars)"
    log_info "Token preview: ${manual_token:0:30}...${manual_token: -30}"
    return 0
}

save_token_to_env() {
    local token="$1"
    
    if grep -q "QWEN_BEARER_TOKEN=" "$ENV_FILE"; then
        # Update existing token
        sed -i.bak "s|QWEN_BEARER_TOKEN=.*|QWEN_BEARER_TOKEN=$token|" "$ENV_FILE"
    else
        # Add new token
        echo "" >> "$ENV_FILE"
        echo "QWEN_BEARER_TOKEN=$token" >> "$ENV_FILE"
    fi
}

retrieve_token() {
    log_step 6 7 "Retrieving Bearer Token..."
    
    # Check if .env exists
    if [[ ! -f "$ENV_FILE" ]]; then
        log_warning ".env file not found, creating from template..."
        create_env_file
        log_warning "Please edit .env and add your QWEN_EMAIL and QWEN_PASSWORD"
        log_warning "Then run this script again"
        echo ""
        exit 1
    fi
    
    # Load environment variables
    load_env
    
    # Check if we already have a valid token
    if check_existing_token; then
        echo ""
        return 0
    fi
    
    # Validate credentials
    if ! validate_credentials; then
        echo ""
        exit 1
    fi
    
    log_info "Attempting to extract Bearer token..."
    echo ""
    
    # Try automated extraction first
    if extract_token_automated; then
        echo ""
        return 0
    fi
    
    # Fall back to manual extraction
    if extract_token_manual; then
        echo ""
        return 0
    fi
    
    log_error "Failed to retrieve Bearer token"
    echo ""
    exit 1
}

print_status() {
    log_step 7 7 "Verifying installation..."
    
    local python_version
    python_version=$(python3 --version | awk '{print $2}')
    
    echo -e "${CYAN}Environment Status:${NC}"
    echo -e "  ${BLUE}Python:${NC} $python_version"
    echo -e "  ${BLUE}Virtual Env:${NC} .venv"
    echo -e "  ${BLUE}Dependencies:${NC} ${GREEN}✓${NC} Installed"
    echo -e "  ${BLUE}Playwright:${NC} ${GREEN}✓${NC} Ready"
    echo -e "  ${BLUE}Bearer Token:${NC} ${GREEN}✓${NC} Configured"
    echo ""
}

print_next_steps() {
    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "  ${YELLOW}→${NC} Run ${BOLD}bash scripts/start.sh${NC} to start the server"
    echo -e "  ${YELLOW}→${NC} Run ${BOLD}bash scripts/all.sh${NC} for complete deployment + testing"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header
    
    check_python
    setup_uv
    create_venv
    install_dependencies
    install_playwright
    retrieve_token
    print_status
    
    print_footer
    print_next_steps
}

main "$@"
