#!/usr/bin/env bash
################################################################################
# start.sh - Start Qwen API Server
# Starts the FastAPI server with proper configuration
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
echo -e "${CYAN}${BOLD}           Starting Qwen API Server                    ${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"

# Load environment
if [ ! -f ".env" ]; then
    echo -e "${RED}✗ .env file not found!${NC}"
    echo -e "${YELLOW}Run 'bash scripts/setup.sh' first${NC}\n"
    exit 1
fi

set -a
source .env
set +a

PORT=${LISTEN_PORT:-8096}
HOST=${HOST:-0.0.0.0}

# Check if Bearer token exists
if [ -z "$QWEN_BEARER_TOKEN" ]; then
    if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
        echo -e "${RED}✗ No Bearer token and no credentials found!${NC}"
        echo -e "${YELLOW}Please set QWEN_BEARER_TOKEN or QWEN_EMAIL/QWEN_PASSWORD in .env${NC}\n"
        exit 1
    fi
    echo -e "${YELLOW}⚠ No Bearer token - will use Playwright authentication${NC}"
else
    echo -e "${GREEN}✓ Bearer token configured (${#QWEN_BEARER_TOKEN} chars)${NC}"
fi

# Check if port is already in use
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Port $PORT is already in use${NC}"
    OLD_PID=$(lsof -ti:$PORT)
    echo -e "${YELLOW}Killing process $OLD_PID...${NC}"
    kill -9 $OLD_PID 2>/dev/null || true
    sleep 2
fi

# Activate virtual environment
if [ ! -d ".venv" ]; then
    echo -e "${RED}✗ Virtual environment not found!${NC}"
    echo -e "${YELLOW}Run 'bash scripts/setup.sh' first${NC}\n"
    exit 1
fi

source .venv/bin/activate

# Create logs directory
mkdir -p logs

# Start server in background
echo -e "${BLUE}Starting server on ${BOLD}http://${HOST}:${PORT}${NC}"
echo -e "${CYAN}Logs: ${BOLD}logs/server.log${NC}\n"

# Start server with nohup
nohup python3 main.py --port $PORT --host $HOST > logs/server.log 2>&1 &
SERVER_PID=$!

# Save PID
echo $SERVER_PID > server.pid

# Wait for server to start
echo -e "${CYAN}Waiting for server to start...${NC}"
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:$PORT/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Server is ready!${NC}\n"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    
    # Check if process is still running
    if ! ps -p $SERVER_PID > /dev/null 2>&1; then
        echo -e "${RED}✗ Server failed to start!${NC}"
        echo -e "${YELLOW}Check logs: tail -f logs/server.log${NC}\n"
        exit 1
    fi
    
    echo -ne "${YELLOW}⏳ Starting... ($ATTEMPT/$MAX_ATTEMPTS)\r${NC}"
    sleep 1
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo -e "${RED}✗ Server startup timeout!${NC}"
    echo -e "${YELLOW}Check logs: tail -f logs/server.log${NC}\n"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}            Server Running Successfully! ✓             ${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"

echo -e "${CYAN}Server Information:${NC}"
echo -e "  ${BLUE}URL:${NC} http://localhost:$PORT"
echo -e "  ${BLUE}Health:${NC} http://localhost:$PORT/health"
echo -e "  ${BLUE}Models:${NC} http://localhost:$PORT/v1/models"
echo -e "  ${BLUE}PID:${NC} $SERVER_PID (saved to server.pid)"
echo -e "  ${BLUE}Logs:${NC} logs/server.log"
echo ""

echo -e "${CYAN}Management Commands:${NC}"
echo -e "  ${YELLOW}View logs:${NC} tail -f logs/server.log"
echo -e "  ${YELLOW}Stop server:${NC} kill \$(cat server.pid)"
echo -e "  ${YELLOW}Restart:${NC} bash scripts/start.sh"
echo ""

echo -e "${CYAN}Test the API:${NC}"
echo -e "  ${YELLOW}→${NC} Run ${BOLD}bash scripts/send_request.sh${NC} to test all endpoints"
echo -e "  ${YELLOW}→${NC} Or use ${BOLD}curl http://localhost:$PORT/health${NC}"
echo ""

# Test health endpoint
echo -e "${BLUE}Testing health endpoint...${NC}"
HEALTH_RESPONSE=$(curl -s http://localhost:$PORT/health)
echo -e "${GREEN}Response:${NC} $HEALTH_RESPONSE\n"

