#!/usr/bin/env bash
################################################################################
# start.sh - Start Already-Setup Server
# Starts the Qwen API server (assumes setup is already complete)
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
echo -e "${CYAN}${BOLD}║       Qwen API - Start Server                     ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${NC}\n"

# Check if setup was done
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ Virtual environment not found!${NC}"
    echo -e "${YELLOW}Please run: bash scripts/setup.sh first${NC}\n"
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found!${NC}"
    echo -e "${YELLOW}Please run: bash scripts/setup.sh first${NC}\n"
    exit 1
fi

# Activate virtual environment
echo -e "${BLUE}🔌 Activating virtual environment...${NC}"
source venv/bin/activate
echo -e "${GREEN}✅ Virtual environment activated${NC}\n"

# Load environment variables
echo -e "${BLUE}⚙️  Loading environment variables...${NC}"
set -a
source .env
set +a

# Load Playwright-extracted token if available
if [ -f ".qwen_bearer_token" ]; then
    export QWEN_BEARER_TOKEN=$(cat .qwen_bearer_token)
    echo -e "${GREEN}✅ Loaded Bearer token from .qwen_bearer_token${NC}"
fi

# Ensure direct provider mode for Playwright tokens
export QWEN_USE_PROXY=false

echo -e "${GREEN}✅ Environment loaded (Direct provider mode)${NC}\n"

# Check if server is already running
if [ -f "server.pid" ]; then
    OLD_PID=$(cat server.pid)
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Server already running (PID: $OLD_PID)${NC}"
        echo -e "${BLUE}To restart, kill the old process first:${NC}"
        echo -e "  ${YELLOW}kill $OLD_PID${NC}\n"
        exit 1
    else
        echo -e "${YELLOW}⚠️  Stale PID file found, removing...${NC}"
        rm -f server.pid
    fi
fi

# Start the server in background
echo -e "${BLUE}🚀 Starting Qwen API server...${NC}"
nohup python main.py > logs/server.log 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > server.pid

echo -e "${GREEN}✅ Server started (PID: $SERVER_PID)${NC}\n"

# Wait for server to start
echo -e "${BLUE}⏳ Waiting for server to initialize...${NC}"
sleep 5

# Check if server is running
if ps -p $SERVER_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Server is running!${NC}\n"
    
    # Try health check
    echo -e "${BLUE}🏥 Checking server health...${NC}"
    if curl -s http://localhost:${LISTEN_PORT:-8096}/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Health check passed!${NC}\n"
    else
        echo -e "${YELLOW}⚠️  Server started but health check failed${NC}"
        echo -e "${BLUE}Check logs for details:${NC} ${YELLOW}tail -f logs/server.log${NC}\n"
    fi
    
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║       Server Running Successfully!                ║${NC}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${CYAN}Server Details:${NC}"
    echo -e "  ${BLUE}PID:${NC} $SERVER_PID"
    echo -e "  ${BLUE}Port:${NC} ${LISTEN_PORT:-8096}"
    echo -e "  ${BLUE}URL:${NC} http://localhost:${LISTEN_PORT:-8096}"
    echo -e "  ${BLUE}Logs:${NC} tail -f logs/server.log\n"
    
    echo -e "${CYAN}Test the API:${NC}"
    echo -e "  ${YELLOW}bash scripts/send_request.sh${NC}\n"
else
    echo -e "${RED}❌ Server failed to start!${NC}"
    echo -e "${BLUE}Check logs for details:${NC} ${YELLOW}cat logs/server.log${NC}\n"
    rm -f server.pid
    exit 1
fi
