#!/usr/bin/env bash
################################################################################
# setup.sh - Full Setup (Without Starting Server)
# Sets up Python environment, installs dependencies, and configures the system
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

echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║       Qwen API - Setup Script                     ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${NC}\n"

# Check Python 3.8+
echo -e "${BLUE}🔍 Checking Python version...${NC}"
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}❌ Python 3 not found. Please install Python 3.8 or higher.${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
MAJOR_VERSION=$(echo "$PYTHON_VERSION" | cut -d. -f1)
MINOR_VERSION=$(echo "$PYTHON_VERSION" | cut -d. -f2)

if [ "$MAJOR_VERSION" -lt 3 ] || ([ "$MAJOR_VERSION" -eq 3 ] && [ "$MINOR_VERSION" -lt 8 ]); then
    echo -e "${RED}❌ Python $PYTHON_VERSION detected. Python 3.8+ required.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Python $PYTHON_VERSION detected${NC}\n"

# Create virtual environment
echo -e "${BLUE}🔧 Creating Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}\n"
else
    echo -e "${YELLOW}⚠️  Virtual environment already exists${NC}\n"
fi

# Activate virtual environment
echo -e "${BLUE}🔌 Activating virtual environment...${NC}"
source venv/bin/activate
echo -e "${GREEN}✅ Virtual environment activated${NC}\n"

# Upgrade pip
echo -e "${BLUE}📦 Upgrading pip...${NC}"
pip install --upgrade pip --quiet
echo -e "${GREEN}✅ pip upgraded${NC}\n"

# Install dependencies
echo -e "${BLUE}📦 Installing Python dependencies...${NC}"
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt --quiet
    echo -e "${GREEN}✅ Dependencies installed${NC}\n"
else
    echo -e "${YELLOW}⚠️  requirements.txt not found${NC}\n"
fi

# Install Playwright browsers
echo -e "${BLUE}🌐 Installing Playwright browsers...${NC}"
playwright install chromium --with-deps
echo -e "${GREEN}✅ Playwright browsers installed${NC}\n"

# Setup environment file
echo -e "${BLUE}⚙️  Setting up environment configuration...${NC}"
if [ ! -f ".env" ]; then
    cat > .env << EOF
# Qwen API Configuration
LISTEN_PORT=8096
DEBUG_LOGGING=true

# Qwen Credentials (will be set by user)
QWEN_EMAIL=${QWEN_EMAIL:-}
QWEN_PASSWORD=${QWEN_PASSWORD:-}

# Optional: Bearer Token (if you already have one)
# QWEN_BEARER_TOKEN=
EOF
    echo -e "${GREEN}✅ .env file created${NC}\n"
else
    echo -e "${YELLOW}⚠️  .env file already exists${NC}\n"
fi

# Prompt for credentials if not set
if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
    echo -e "${YELLOW}📝 Qwen credentials not found in environment${NC}"
    echo -e "${BLUE}Please enter your Qwen credentials:${NC}"
    
    if [ -z "$QWEN_EMAIL" ]; then
        read -p "$(echo -e ${CYAN}Email: ${NC})" QWEN_EMAIL
        echo "QWEN_EMAIL=$QWEN_EMAIL" >> .env
    fi
    
    if [ -z "$QWEN_PASSWORD" ]; then
        read -sp "$(echo -e ${CYAN}Password: ${NC})" QWEN_PASSWORD
        echo
        echo "QWEN_PASSWORD=$QWEN_PASSWORD" >> .env
    fi
    
    echo -e "${GREEN}✅ Credentials saved to .env${NC}\n"
fi

# Add ANONYMOUS_MODE setting for testing (always add if not present)
if ! grep -q "ANONYMOUS_MODE" .env 2>/dev/null; then
    echo "ANONYMOUS_MODE=true" >> .env
    echo -e "${GREEN}✅ Anonymous mode enabled for testing${NC}\n"
fi

# Create necessary directories
echo -e "${BLUE}📁 Creating necessary directories...${NC}"
mkdir -p .sessions logs
echo -e "${GREEN}✅ Directories created${NC}\n"

echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║       ✅ Setup Complete!                          ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}Next steps:${NC}"
echo -e "  ${BLUE}1.${NC} Start the server: ${YELLOW}bash scripts/start.sh${NC}"
echo -e "  ${BLUE}2.${NC} Test the API: ${YELLOW}bash scripts/send_request.sh${NC}"
echo -e "  ${BLUE}3.${NC} Or run everything: ${YELLOW}bash scripts/all.sh${NC}\n"
