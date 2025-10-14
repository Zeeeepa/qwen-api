#!/usr/bin/env bash
################################################################################
# setup.sh - Environment Setup and Bearer Token Retrieval
# This script sets up the Python environment and extracts the Bearer token
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}    Qwen API - Environment Setup & Token Retrieval     ${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"

# Step 1: Check Python
echo -e "${BLUE}[1/6]${NC} Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 not found!${NC}"
    exit 1
fi
PYTHON_VERSION=$(python3 --version | awk '{print $2}')
echo -e "${GREEN}✓ Python $PYTHON_VERSION found${NC}\n"

# Step 2: Check uv
echo -e "${BLUE}[2/6]${NC} Checking uv package manager..."
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}⚠ uv not found, installing...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi
echo -e "${GREEN}✓ uv package manager ready${NC}\n"

# Step 3: Create virtual environment
echo -e "${BLUE}[3/6]${NC} Setting up virtual environment..."
if [ ! -d ".venv" ]; then
    uv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment already exists${NC}"
fi
echo ""

# Step 4: Install dependencies
echo -e "${BLUE}[4/6]${NC} Installing dependencies..."
source .venv/bin/activate
uv pip install -r requirements.txt --quiet
echo -e "${GREEN}✓ Dependencies installed${NC}\n"

# Step 5: Install Playwright browsers
echo -e "${BLUE}[5/6]${NC} Installing Playwright browsers..."
if ! playwright install chromium --quiet 2>/dev/null; then
    echo -e "${YELLOW}⚠ Installing Playwright system dependencies...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y -qq libasound2 > /dev/null 2>&1
    playwright install-deps chromium > /dev/null 2>&1
    playwright install chromium > /dev/null 2>&1
fi
echo -e "${GREEN}✓ Playwright browsers ready${NC}\n"

# Step 6: Retrieve Bearer Token
echo -e "${BLUE}[6/6]${NC} Retrieving Bearer Token..."

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠ .env file not found, creating from .env.example...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
    else
        cat > .env << 'EOF'
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password
LISTEN_PORT=8096
ANONYMOUS_MODE=true
DEBUG_LOGGING=true
EOF
    fi
    echo -e "${YELLOW}⚠ Please edit .env and add your QWEN_EMAIL and QWEN_PASSWORD${NC}"
    echo -e "${YELLOW}⚠ Then run this script again${NC}\n"
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

# Check if we already have a Bearer token
if [ -n "$QWEN_BEARER_TOKEN" ]; then
    echo -e "${GREEN}✓ Bearer token found in .env (${#QWEN_BEARER_TOKEN} chars)${NC}"
    echo -e "${CYAN}Token preview: ${QWEN_BEARER_TOKEN:0:30}...${QWEN_BEARER_TOKEN: -30}${NC}\n"
else
    # Check credentials
    if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
        echo -e "${RED}✗ QWEN_EMAIL or QWEN_PASSWORD not set in .env${NC}"
        echo -e "${YELLOW}Please edit .env and add your credentials${NC}\n"
        exit 1
    fi

    echo -e "${CYAN}Extracting Bearer token using Playwright...${NC}"
    
    # Run token extraction
    if python3 test_auth.py > /tmp/token_extraction.log 2>&1; then
        # Extract token from output
        TOKEN=$(grep "QWEN_BEARER_TOKEN=" /tmp/token_extraction.log | cut -d'=' -f2)
        
        if [ -n "$TOKEN" ]; then
            # Add token to .env if not already there
            if ! grep -q "QWEN_BEARER_TOKEN=" .env; then
                echo "" >> .env
                echo "QWEN_BEARER_TOKEN=$TOKEN" >> .env
            else
                # Update existing token
                sed -i.bak "s|QWEN_BEARER_TOKEN=.*|QWEN_BEARER_TOKEN=$TOKEN|" .env
            fi
            
            echo -e "${GREEN}✓ Bearer token extracted and saved to .env${NC}"
            echo -e "${CYAN}Token preview: ${TOKEN:0:30}...${TOKEN: -30}${NC}"
            echo -e "${CYAN}Token length: ${#TOKEN} characters${NC}\n"
        else
            echo -e "${RED}✗ Failed to extract token${NC}"
            cat /tmp/token_extraction.log
            exit 1
        fi
    else
        echo -e "${RED}✗ Token extraction failed${NC}"
        cat /tmp/token_extraction.log
        exit 1
    fi
fi

echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}            Setup Complete! ✓                          ${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}Environment Status:${NC}"
echo -e "  ${BLUE}Python:${NC} $PYTHON_VERSION"
echo -e "  ${BLUE}Virtual Env:${NC} .venv"
echo -e "  ${BLUE}Dependencies:${NC} Installed"
echo -e "  ${BLUE}Playwright:${NC} Ready"
echo -e "  ${BLUE}Bearer Token:${NC} ${GREEN}✓${NC} Configured"
echo ""

echo -e "${CYAN}Next Steps:${NC}"
echo -e "  ${YELLOW}→${NC} Run ${BOLD}bash scripts/start.sh${NC} to start the server"
echo -e "  ${YELLOW}→${NC} Run ${BOLD}bash scripts/all.sh${NC} for complete deployment + testing"
echo ""

