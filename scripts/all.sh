#!/bin/bash
################################################################################
# all.sh - Complete One-Command Deployment for Qwen OpenAI Proxy
#
# Usage:
#   export QWEN_EMAIL="your@email.com"
#   export QWEN_PASSWORD="yourpassword"
#   bash scripts/all.sh
#
# Or in one line:
#   export QWEN_EMAIL="your@email.com" && export QWEN_PASSWORD="yourpassword" && bash scripts/all.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                        ║${NC}"
echo -e "${BLUE}║        🚀 Qwen OpenAI Proxy - One-Click Deploy 🚀     ║${NC}"
echo -e "${BLUE}║                                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check required environment variables
if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
    echo -e "${RED}❌ Error: QWEN_EMAIL and QWEN_PASSWORD must be set${NC}"
    echo ""
    echo "Usage:"
    echo "  export QWEN_EMAIL='your@email.com'"
    echo "  export QWEN_PASSWORD='yourpassword'"
    echo "  bash scripts/all.sh"
    echo ""
    echo "Or in one line:"
    echo "  QWEN_EMAIL='your@email.com' QWEN_PASSWORD='yourpassword' bash scripts/all.sh"
    exit 1
fi

# Configuration
PORT="${PORT:-7000}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${YELLOW}📋 Configuration:${NC}"
echo "   Email: $QWEN_EMAIL"
echo "   Port: $PORT"
echo "   Project: $PROJECT_ROOT"
echo ""

cd "$PROJECT_ROOT"

#############################################
# Step 1: Install System Dependencies
#############################################
echo -e "${YELLOW}📦 Step 1/6: Installing system dependencies...${NC}"

if command -v apt-get &> /dev/null; then
    sudo apt-get update -qq > /dev/null 2>&1
    sudo apt-get install -y -qq python3 python3-pip python3-venv curl git jq > /dev/null 2>&1
    echo -e "${GREEN}✅ System dependencies installed (apt-get)${NC}"
elif command -v yum &> /dev/null; then
    sudo yum install -y python3 python3-pip git curl jq > /dev/null 2>&1
    echo -e "${GREEN}✅ System dependencies installed (yum)${NC}"
elif command -v brew &> /dev/null; then
    brew install python3 curl jq > /dev/null 2>&1
    echo -e "${GREEN}✅ System dependencies installed (brew)${NC}"
else
    echo -e "${YELLOW}⚠️  Unknown package manager, assuming dependencies are installed${NC}"
fi

#############################################
# Step 2: Setup Python Environment
#############################################
echo -e "${YELLOW}🐍 Step 2/6: Setting up Python environment...${NC}"

# Create virtual environment
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
else
    echo -e "${GREEN}✅ Virtual environment exists${NC}"
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip -q

# Install dependencies
if [ -f "py-api/setup.py" ]; then
    cd py-api
    pip install -e . -q
    cd ..
    echo -e "${GREEN}✅ Python package installed${NC}"
fi

# Install additional requirements
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt -q
    echo -e "${GREEN}✅ Requirements installed${NC}"
fi

# Install OpenAI client for testing
pip install openai -q 2>/dev/null || true

#############################################
# Step 3: Install Playwright
#############################################
echo -e "${YELLOW}🌐 Step 3/6: Installing Playwright browsers...${NC}"

pip install playwright -q
playwright install chromium > /dev/null 2>&1 || playwright install > /dev/null 2>&1
echo -e "${GREEN}✅ Playwright browsers installed${NC}"

#############################################
# Step 4: Extract Qwen Token
#############################################
echo -e "${YELLOW}🔑 Step 4/6: Extracting Qwen authentication token...${NC}"

# Try to extract token
if [ -f "py-api/qwen-api/get_qwen_token.py" ]; then
    QWEN_BEARER_TOKEN=$(python3 py-api/qwen-api/get_qwen_token.py 2>&1 | grep -E '^eyJ' || echo "")
    
    if [ -n "$QWEN_BEARER_TOKEN" ]; then
        echo "QWEN_BEARER_TOKEN=$QWEN_BEARER_TOKEN" > .env
        echo -e "${GREEN}✅ Token extracted ($(echo $QWEN_BEARER_TOKEN | wc -c) chars)${NC}"
    else
        echo -e "${RED}❌ Failed to extract token${NC}"
        echo -e "${YELLOW}💡 Trying alternative method...${NC}"
        
        # Try setup.sh if it exists
        if [ -f "scripts/setup.sh" ]; then
            bash scripts/setup.sh
            if [ -f ".env" ] && grep -q "QWEN_BEARER_TOKEN" .env; then
                echo -e "${GREEN}✅ Token extracted via setup.sh${NC}"
            else
                echo -e "${RED}❌ Token extraction failed${NC}"
                exit 1
            fi
        else
            echo -e "${RED}❌ No token extraction method available${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}⚠️  get_qwen_token.py not found, trying setup.sh...${NC}"
    if [ -f "scripts/setup.sh" ]; then
        bash scripts/setup.sh
    else
        echo -e "${RED}❌ No token extraction method available${NC}"
        exit 1
    fi
fi

# Verify token exists
if [ ! -f ".env" ] || ! grep -q "QWEN_BEARER_TOKEN" .env; then
    echo -e "${RED}❌ Token not found in .env${NC}"
    exit 1
fi

#############################################
# Step 5: Validate Token
#############################################
echo -e "${YELLOW}✅ Step 5/6: Validating token...${NC}"

source .env

if [ -f "py-api/qwen-api/check_jwt_expiry.py" ]; then
    if python3 py-api/qwen-api/check_jwt_expiry.py "$QWEN_BEARER_TOKEN" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Token is valid${NC}"
    else
        echo -e "${RED}❌ Token is expired or invalid${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Token validation skipped (check_jwt_expiry.py not found)${NC}"
fi

#############################################
# Step 6: Start Server
#############################################
echo -e "${YELLOW}🌐 Step 6/6: Starting server...${NC}"

# Kill existing servers
pkill -f "python3.*start.py" 2>/dev/null || true
sleep 1

# Start server
export QWEN_BEARER_TOKEN
export PORT=$PORT

if [ -f "py-api/start.py" ]; then
    cd py-api
    nohup python3 start.py > ../server.log 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > ../server.pid
    cd ..
    
    # Wait for server
    sleep 3
    
    # Verify server is running
    if ps -p $SERVER_PID > /dev/null; then
        echo -e "${GREEN}✅ Server started (PID: $SERVER_PID)${NC}"
    else
        echo -e "${RED}❌ Server failed to start${NC}"
        echo -e "${YELLOW}📋 Last 20 lines of log:${NC}"
        tail -20 server.log
        exit 1
    fi
else
    echo -e "${RED}❌ start.py not found${NC}"
    exit 1
fi

#############################################
# Success Summary
#############################################
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📡 Server Information:${NC}"
echo "   URL: http://localhost:$PORT"
echo "   OpenAI Endpoint: http://localhost:$PORT/v1/chat/completions"
echo "   Models Endpoint: http://localhost:$PORT/v1/models"
echo "   PID: $SERVER_PID (saved to server.pid)"
echo "   Logs: $PROJECT_ROOT/server.log"
echo ""
echo -e "${BLUE}🧪 Quick Test:${NC}"
echo "python3 << 'EOF'
from openai import OpenAI

client = OpenAI(
    api_key=\"sk-any\",
    base_url=\"http://localhost:$PORT/v1\"
)

result = client.chat.completions.create(
    model=\"gpt-5\",
    messages=[{\"role\": \"user\", \"content\": \"Hello!\"}]
)

print(result.choices[0].message.content)
EOF"
echo ""
echo -e "${BLUE}📋 Management:${NC}"
echo "   View logs:    tail -f server.log"
echo "   Stop server:  kill $SERVER_PID"
echo "   Restart:      bash scripts/all.sh"
echo ""
echo -e "${GREEN}✨ Server is ready! Any API key and model name will work!${NC}"
echo ""

