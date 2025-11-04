#!/usr/bin/env bash
################################################################################
# setup.sh - Complete Environment Setup with Token Extraction
# Sets up Python environment, installs dependencies, and extracts Bearer token
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

# Progress indicators
STEP=0
TOTAL_STEPS=7

print_step() {
    STEP=$((STEP + 1))
    echo -e "\n${CYAN}${BOLD}[Step $STEP/$TOTAL_STEPS]${NC} ${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║       Qwen API - Complete Setup Script                    ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Step 1: Check Python version
print_step "Checking Python version"
if ! command -v python3 &>/dev/null; then
    print_error "Python 3 not found. Please install Python 3.8 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
MAJOR_VERSION=$(echo "$PYTHON_VERSION" | cut -d. -f1)
MINOR_VERSION=$(echo "$PYTHON_VERSION" | cut -d. -f2)

if [ "$MAJOR_VERSION" -lt 3 ] || ([ "$MAJOR_VERSION" -eq 3 ] && [ "$MINOR_VERSION" -lt 8 ]); then
    print_error "Python $PYTHON_VERSION detected. Python 3.8+ required."
    exit 1
fi

print_success "Python $PYTHON_VERSION detected"

# Step 2: Create virtual environment
print_step "Creating Python virtual environment"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_warning "Virtual environment already exists"
fi

# Step 3: Activate virtual environment
print_step "Activating virtual environment"
source venv/bin/activate
print_success "Virtual environment activated"

# Step 4: Upgrade pip
print_step "Upgrading pip"
python -m pip install --upgrade pip > /dev/null 2>&1
print_success "Pip upgraded to latest version"

# Step 5: Install dependencies
print_step "Installing dependencies"
print_info "This may take a few minutes..."

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt > /dev/null 2>&1
    print_success "Python dependencies installed"
else
    print_error "requirements.txt not found"
    exit 1
fi

# Step 6: Install Playwright browsers
print_step "Installing Playwright browsers"
print_info "This may take a few minutes on first run..."

playwright install chromium --with-deps > /dev/null 2>&1
print_success "Playwright browsers installed"

# Step 7: Extract Bearer token
print_step "Extracting Bearer token"

# Check if credentials are set
if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
    print_warning "QWEN_EMAIL or QWEN_PASSWORD not set"
    print_info "You can set them now or manually later:"
    echo -e "${YELLOW}    export QWEN_EMAIL=\"your@email.com\"${NC}"
    echo -e "${YELLOW}    export QWEN_PASSWORD=\"yourpassword\"${NC}"
    echo -e "${YELLOW}    python extract_qwen_token.py${NC}"
else
    print_info "Credentials found, extracting token..."
    
    if [ -f "extract_qwen_token.py" ]; then
        # Run token extraction
        python extract_qwen_token.py
        
        if [ $? -eq 0 ] && [ -f ".qwen_bearer_token" ]; then
            TOKEN_PREVIEW=$(head -c 20 .qwen_bearer_token)
            print_success "Bearer token extracted successfully"
            print_info "Token preview: ${TOKEN_PREVIEW}..."
            print_success "Token saved to .qwen_bearer_token"
        else
            print_error "Failed to extract token"
            print_warning "You can try manually later with: python extract_qwen_token.py"
        fi
    else
        print_error "extract_qwen_token.py not found"
    fi
fi

# Final summary
echo -e "\n${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                  Setup Complete! ✅                        ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}\n"

print_success "Environment setup completed successfully"

echo -e "${CYAN}📋 What was done:${NC}"
echo -e "   ✅ Python $PYTHON_VERSION environment created"
echo -e "   ✅ All dependencies installed"
echo -e "   ✅ Playwright browsers ready"
if [ -f ".qwen_bearer_token" ]; then
    echo -e "   ✅ Bearer token extracted and cached"
else
    echo -e "   ⚠️  Bearer token not extracted (set credentials first)"
fi

echo -e "\n${CYAN}🚀 Next steps:${NC}"
echo -e "   1. Start the server:    ${YELLOW}bash scripts/start.sh${NC}"
echo -e "   2. Run tests:           ${YELLOW}bash scripts/run_tests.sh${NC}"
echo -e "   3. Send test request:   ${YELLOW}bash scripts/send_request.sh${NC}"

echo -e "\n${CYAN}💡 Configuration:${NC}"
echo -e "   • Port:         ${YELLOW}8096${NC}"
echo -e "   • API Base:     ${YELLOW}http://localhost:8096/v1${NC}"
echo -e "   • Docs:         ${YELLOW}http://localhost:8096/docs${NC}"
echo -e "   • Health:       ${YELLOW}http://localhost:8096/health${NC}"

echo -e "\n${CYAN}📚 Available Models:${NC}"
echo -e "   • ${YELLOW}qwen3${NC} or ${YELLOW}qwen3-max${NC}    → qwen3-max-latest (web search, no thinking)"
echo -e "   • ${YELLOW}qwen3-web${NC} or ${YELLOW}qwen3-235b${NC}  → qwen3-235b-a22b-2507 (web + thinking, 81K tokens)"
echo -e "   • ${YELLOW}qwen3-vl${NC}              → qwen3-vl-235b-a22b (no web, thinking, 81K tokens)"
echo -e "   • ${YELLOW}qwen3-omni${NC}            → qwen3-omni-flash (no web, thinking, 81K tokens)"

echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}\n"

