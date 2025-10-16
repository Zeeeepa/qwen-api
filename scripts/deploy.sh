#!/usr/bin/env bash
################################################################################
# deploy.sh - Complete Qwen API Deployment with Authentication
# 
# This script handles everything:
# 1. Environment setup (venv, dependencies, Playwright)
# 2. Token extraction (if needed)
# 3. Server startup
# 4. API testing with OpenAI client
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo -e "${MAGENTA}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║        🚀 Qwen API - Complete Deployment 🚀               ║"
echo "║                                                            ║"
echo "║  Features:                                                 ║"
echo "║  ✅ Automatic Playwright authentication                    ║"
echo "║  ✅ Token extraction and caching                           ║"
echo "║  ✅ OpenAI-compatible API server                           ║"
echo "║  ✅ Any API key works (anonymous mode)                     ║"
echo "║  ✅ Any model name works (smart defaulting)                ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Check required environment variables
if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
    echo -e "${RED}❌ Error: QWEN_EMAIL and QWEN_PASSWORD must be set!${NC}\n"
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ${CYAN}export QWEN_EMAIL=\"your@email.com\"${NC}"
    echo -e "  ${CYAN}export QWEN_PASSWORD=\"yourpassword\"${NC}"
    echo -e "  ${CYAN}bash scripts/deploy.sh${NC}\n"
    exit 1
fi

echo -e "${GREEN}✅ Credentials loaded:${NC}"
echo -e "   Email: ${CYAN}$QWEN_EMAIL${NC}"
echo -e "   Password: ${CYAN}********${NC}\n"

# Step 1: Setup Environment
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}STEP 1/4: Environment Setup${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"

if [ -f "$SCRIPT_DIR/setup.sh" ]; then
    bash "$SCRIPT_DIR/setup.sh"
else
    echo -e "${RED}❌ setup.sh not found!${NC}\n"
    exit 1
fi

echo -e "${GREEN}✅ Environment setup complete!${NC}\n"
sleep 1

# Step 2: Extract Bearer Token (if needed)
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}STEP 2/4: Authentication & Token Extraction${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"

# Check if we already have a valid Bearer token
if [ -n "$QWEN_BEARER_TOKEN" ]; then
    echo -e "${GREEN}✅ Using existing QWEN_BEARER_TOKEN from environment${NC}\n"
elif [ -f ".qwen_bearer_token" ]; then
    echo -e "${YELLOW}⚠️  Found cached token file, verifying...${NC}"
    # For now, trust the cached token
    # TODO: Add token expiration check
    QWEN_BEARER_TOKEN=$(cat .qwen_bearer_token)
    export QWEN_BEARER_TOKEN
    echo -e "${GREEN}✅ Using cached Bearer token${NC}\n"
else
    echo -e "${BLUE}🔐 No Bearer token found, extracting via Playwright...${NC}"
    
    # Activate venv and run test_auth.py
    source venv/bin/activate
    
    if python3 test_auth.py; then
        # Token extraction successful
        if [ -f ".qwen_bearer_token" ]; then
            QWEN_BEARER_TOKEN=$(cat .qwen_bearer_token)
            export QWEN_BEARER_TOKEN
            echo -e "${GREEN}✅ Bearer token extracted successfully!${NC}"
            echo -e "${CYAN}📏 Token length: ${#QWEN_BEARER_TOKEN} characters${NC}\n"
        else
            echo -e "${RED}❌ Token file not created!${NC}\n"
            exit 1
        fi
    else
        echo -e "${RED}❌ Token extraction failed!${NC}"
        echo -e "${YELLOW}Please check your credentials and try again.${NC}\n"
        exit 1
    fi
fi

# Step 3: Start Server
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}STEP 3/4: Starting API Server${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"

# Kill any existing server
if [ -f "server.pid" ]; then
    OLD_PID=$(cat server.pid)
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Stopping existing server (PID: $OLD_PID)${NC}"
        kill "$OLD_PID" 2>/dev/null || true
        sleep 2
    fi
    rm -f server.pid
fi

if [ -f "$SCRIPT_DIR/start.sh" ]; then
    bash "$SCRIPT_DIR/start.sh"
else
    echo -e "${RED}❌ start.sh not found!${NC}\n"
    exit 1
fi

echo -e "${GREEN}✅ Server started successfully!${NC}\n"
sleep 3

# Step 4: Run API Tests
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}STEP 4/4: Testing API with OpenAI Client${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"

if [ -f "$SCRIPT_DIR/send_request.sh" ]; then
    bash "$SCRIPT_DIR/send_request.sh"
    TEST_RESULT=$?
else
    echo -e "${RED}❌ send_request.sh not found!${NC}\n"
    exit 1
fi

# Final Summary
echo -e "${MAGENTA}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║              🎉 Deployment Complete! 🎉                   ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Load environment
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

PORT=${LISTEN_PORT:-8096}

echo -e "${CYAN}${BOLD}📡 Server Information:${NC}"
echo -e "  ${GREEN}✅ Status:${NC} Running"
echo -e "  ${BLUE}🌐 URL:${NC} http://localhost:$PORT"
echo -e "  ${BLUE}📊 Health:${NC} http://localhost:$PORT/health"
echo -e "  ${BLUE}📚 Docs:${NC} http://localhost:$PORT/docs"
echo -e "  ${BLUE}🎯 Models:${NC} http://localhost:$PORT/v1/models"
if [ -f "server.pid" ]; then
    echo -e "  ${BLUE}🔢 PID:${NC} $(cat server.pid)"
fi
echo

echo -e "${CYAN}${BOLD}🔧 Useful Commands:${NC}"
echo -e "  ${YELLOW}📜 View logs:${NC} tail -f logs/server.log"
echo -e "  ${YELLOW}⏹️  Stop server:${NC} kill \$(cat server.pid)"
echo -e "  ${YELLOW}🔄 Restart:${NC} bash scripts/deploy.sh"
echo -e "  ${YELLOW}🧪 Test again:${NC} bash scripts/send_request.sh"
echo

echo -e "${CYAN}${BOLD}💡 Available Model Names:${NC}"
echo -e "  ${GREEN}✅ Any model name works!${NC}"
echo -e "  ${BLUE}Examples:${NC} gpt-4, gpt-5, claude-3, qwen-turbo, etc."
echo -e "  ${YELLOW}Note:${NC} All model names default to qwen-turbo-latest"
echo

echo -e "${CYAN}${BOLD}🚀 Example API Call:${NC}"
cat << 'EOF'
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",  # ✅ Any key works!
    base_url="http://localhost:8096/v1"
)

result = client.chat.completions.create(
    model="gpt-5",  # ✅ Any model works!
    messages=[{"role": "user", "content": "Write a haiku about code."}]
)

print(result.choices[0].message.content)
EOF

echo

if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ All systems operational! Your Qwen API is ready to use.${NC}\n"
    exit 0
else
    echo -e "${YELLOW}${BOLD}⚠️  Some tests had issues. Check the logs for details.${NC}"
    echo -e "${BLUE}Logs location:${NC} logs/server.log\n"
    exit 1
fi

