#!/usr/bin/env bash
################################################################################
# setup.sh - Environment Setup and Bearer Token Retrieval
# This script sets up the Python environment and extracts the Bearer token
# Updated to handle Ubuntu 24.04 (Noble) t64 library transitions
# Enhanced token extraction with multiple methods
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}    Qwen API - Environment Setup & Token Retrieval     ${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"

# Step 1: Check Python
echo -e "${BLUE}[1/7]${NC} Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 not found!${NC}"
    exit 1
fi
PYTHON_VERSION=$(python3 --version | awk '{print $2}')
echo -e "${GREEN}✓ Python $PYTHON_VERSION found${NC}\n"

# Step 2: Check uv
echo -e "${BLUE}[2/7]${NC} Checking uv package manager..."
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}⚠ uv not found, installing...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi
echo -e "${GREEN}✓ uv package manager ready${NC}\n"

# Step 3: Create virtual environment
echo -e "${BLUE}[3/7]${NC} Setting up virtual environment..."
if [ ! -d ".venv" ]; then
    uv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment already exists${NC}"
fi
echo ""

# Step 4: Install dependencies
echo -e "${BLUE}[4/7]${NC} Installing dependencies..."
source .venv/bin/activate
uv pip install -r requirements.txt --quiet
echo -e "${GREEN}✓ Dependencies installed${NC}\n"

# Step 5: Install pytest-playwright
echo -e "${BLUE}[5/7]${NC} Installing Playwright Python package..."
pip install pytest-playwright --quiet 2>/dev/null || pip install pytest-playwright
echo -e "${GREEN}✓ Playwright Python package installed${NC}\n"

# Step 6: Install Playwright system dependencies
echo -e "${BLUE}[6/7]${NC} Installing Playwright system dependencies..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    OS=$(uname -s)
fi

echo -e "${CYAN}Detected OS: $OS $VERSION${NC}"

# Handle Ubuntu 24.04 (Noble) t64 library issues
if [ "$OS" = "ubuntu" ] && [ "$VERSION" = "24.04" ]; then
    echo -e "${YELLOW}⚠ Ubuntu 24.04 detected - installing t64 compatible dependencies${NC}"
    
    if [ "$EUID" -ne 0 ]; then
        echo -e "${CYAN}Installing system dependencies (requires sudo)...${NC}"
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            libasound2t64 \
            libatk-bridge2.0-0t64 \
            libatk1.0-0t64 \
            libatspi2.0-0t64 \
            libcups2t64 \
            libdrm2 \
            libgbm1 \
            libglib2.0-0t64 \
            libnspr4 \
            libnss3 \
            libpango-1.0-0 \
            libx11-6 \
            libxcb1 \
            libxcomposite1 \
            libxdamage1 \
            libxext6 \
            libxfixes3 \
            libxkbcommon0 \
            libxrandr2 \
            xvfb \
            fonts-liberation \
            fonts-noto-color-emoji \
            2>&1 | grep -v "Selecting previously unselected" | grep -v "Unpacking" | grep -v "Setting up" || true
        
        echo -e "${GREEN}✓ System dependencies installed${NC}"
    else
        apt-get update -qq
        apt-get install -y -qq \
            libasound2t64 \
            libatk-bridge2.0-0t64 \
            libatk1.0-0t64 \
            libatspi2.0-0t64 \
            libcups2t64 \
            libdrm2 \
            libgbm1 \
            libglib2.0-0t64 \
            libnspr4 \
            libnss3 \
            libpango-1.0-0 \
            libx11-6 \
            libxcb1 \
            libxcomposite1 \
            libxdamage1 \
            libxext6 \
            libxfixes3 \
            libxkbcommon0 \
            libxrandr2 \
            xvfb \
            fonts-liberation \
            fonts-noto-color-emoji \
            2>&1 | grep -v "Selecting previously unselected" | grep -v "Unpacking" | grep -v "Setting up" || true
        
        echo -e "${GREEN}✓ System dependencies installed${NC}"
    fi
    
    # Now install Chromium browser
    echo -e "${CYAN}Installing Chromium browser...${NC}"
    playwright install chromium --quiet 2>/dev/null || playwright install chromium
    echo -e "${GREEN}✓ Chromium browser installed${NC}\n"
    
else
    # For other OS versions, try the standard Playwright installer
    if [ "$EUID" -ne 0 ]; then
        echo -e "${CYAN}Installing Playwright dependencies (requires sudo)...${NC}"
        if sudo playwright install-deps chromium --quiet 2>/dev/null; then
            echo -e "${GREEN}✓ System dependencies installed${NC}"
        else
            echo -e "${YELLOW}⚠ Standard installation failed, trying manual approach...${NC}"
            sudo playwright install-deps chromium
        fi
    else
        if playwright install-deps chromium --quiet 2>/dev/null; then
            echo -e "${GREEN}✓ System dependencies installed${NC}"
        else
            echo -e "${YELLOW}⚠ Standard installation failed, trying manual approach...${NC}"
            playwright install-deps chromium
        fi
    fi
    
    # Install Chromium browser
    echo -e "${CYAN}Installing Chromium browser...${NC}"
    playwright install chromium --quiet 2>/dev/null || playwright install chromium
    echo -e "${GREEN}✓ Chromium browser installed${NC}\n"
fi

# Step 7: Retrieve Bearer Token
echo -e "${BLUE}[7/7]${NC} Retrieving Bearer Token..."

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
if [ -n "$QWEN_BEARER_TOKEN" ] && [ "$QWEN_BEARER_TOKEN" != "your-bearer-token-here" ]; then
    echo -e "${GREEN}✓ Bearer token found in .env (${#QWEN_BEARER_TOKEN} chars)${NC}"
    echo -e "${CYAN}Token preview: ${QWEN_BEARER_TOKEN:0:30}...${QWEN_BEARER_TOKEN: -30}${NC}\n"
else
    # Check credentials
    if [ -z "$QWEN_EMAIL" ] || [ "$QWEN_EMAIL" = "your-email@example.com" ]; then
        echo -e "${RED}✗ QWEN_EMAIL not properly configured in .env${NC}"
        echo -e "${YELLOW}Please edit .env and add your real email address${NC}\n"
        exit 1
    fi
    
    if [ -z "$QWEN_PASSWORD" ] || [ "$QWEN_PASSWORD" = "your-password" ]; then
        echo -e "${RED}✗ QWEN_PASSWORD not properly configured in .env${NC}"
        echo -e "${YELLOW}Please edit .env and add your real password${NC}\n"
        exit 1
    fi

    echo -e "${CYAN}Attempting to extract Bearer token...${NC}\n"
    
    # Try automated extraction first
    echo -e "${BLUE}Method 1:${NC} Automated Playwright extraction..."
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
            echo -e "${YELLOW}⚠ Automated extraction didn't find token${NC}\n"
            cat /tmp/token_extraction.log
            
            # Fall back to manual method
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
            
            echo -e "${YELLOW}After you have the token, press Enter to continue...${NC}"
            read -r
            
            echo -e "${CYAN}Please paste your Bearer token:${NC}"
            read -r MANUAL_TOKEN
            
            if [ -n "$MANUAL_TOKEN" ]; then
                # Trim whitespace
                MANUAL_TOKEN=$(echo "$MANUAL_TOKEN" | xargs)
                
                # Validate token (basic check - should be a long string)
                if [ ${#MANUAL_TOKEN} -lt 50 ]; then
                    echo -e "${RED}✗ Token seems too short (${#MANUAL_TOKEN} chars). Expected > 50 chars${NC}"
                    echo -e "${YELLOW}Please run the script again and make sure to copy the full token${NC}\n"
                    exit 1
                fi
                
                # Save to .env
                if ! grep -q "QWEN_BEARER_TOKEN=" .env; then
                    echo "" >> .env
                    echo "QWEN_BEARER_TOKEN=$MANUAL_TOKEN" >> .env
                else
                    sed -i.bak "s|QWEN_BEARER_TOKEN=.*|QWEN_BEARER_TOKEN=$MANUAL_TOKEN|" .env
                fi
                
                echo -e "${GREEN}✓ Bearer token saved to .env${NC}"
                echo -e "${CYAN}Token preview: ${MANUAL_TOKEN:0:30}...${MANUAL_TOKEN: -30}${NC}"
                echo -e "${CYAN}Token length: ${#MANUAL_TOKEN} characters${NC}\n"
            else
                echo -e "${RED}✗ No token provided${NC}\n"
                exit 1
            fi
        fi
    else
        echo -e "${YELLOW}⚠ Automated extraction failed${NC}\n"
        cat /tmp/token_extraction.log
        
        # Fall back to manual method (same as above)
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
        
        echo -e "${YELLOW}After you have the token, press Enter to continue...${NC}"
        read -r
        
        echo -e "${CYAN}Please paste your Bearer token:${NC}"
        read -r MANUAL_TOKEN
        
        if [ -n "$MANUAL_TOKEN" ]; then
            # Trim whitespace
            MANUAL_TOKEN=$(echo "$MANUAL_TOKEN" | xargs)
            
            # Validate token
            if [ ${#MANUAL_TOKEN} -lt 50 ]; then
                echo -e "${RED}✗ Token seems too short (${#MANUAL_TOKEN} chars). Expected > 50 chars${NC}"
                echo -e "${YELLOW}Please run the script again and make sure to copy the full token${NC}\n"
                exit 1
            fi
            
            # Save to .env
            if ! grep -q "QWEN_BEARER_TOKEN=" .env; then
                echo "" >> .env
                echo "QWEN_BEARER_TOKEN=$MANUAL_TOKEN" >> .env
            else
                sed -i.bak "s|QWEN_BEARER_TOKEN=.*|QWEN_BEARER_TOKEN=$MANUAL_TOKEN|" .env
            fi
            
            echo -e "${GREEN}✓ Bearer token saved to .env${NC}"
            echo -e "${CYAN}Token preview: ${MANUAL_TOKEN:0:30}...${MANUAL_TOKEN: -30}${NC}"
            echo -e "${CYAN}Token length: ${#MANUAL_TOKEN} characters${NC}\n"
        else
            echo -e "${RED}✗ No token provided${NC}\n"
            exit 1
        fi
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
