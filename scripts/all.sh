#!/usr/bin/env bash
################################################################################
# all.sh - Complete End-to-End Deployment and Testing
# Runs: setup.sh + start.sh + send_request.sh + keeps server running
# This is the "one command to rule them all" script
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
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║        🚀 Qwen API - Complete Deployment 🚀         ║"
echo "║                                                      ║"
echo "║  This script will:                                   ║"
echo "║  1. ✅ Setup Python environment                     ║"
echo "║  2. 📦 Install all dependencies                     ║"
echo "║  3. 🌐 Install Playwright browsers                  ║"
echo "║  4. 🔑 Retrieve/validate Bearer token               ║"
echo "║  5. 🚀 Start the API server                         ║"
echo "║  6. 🧪 Run comprehensive tests                      ║"
echo "║  7. 📊 Display results                              ║"
echo "║  8. 🔄 Keep server running                          ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Check if running in project root
if [ ! -f "main.py" ]; then
    echo -e "${RED}✗ Error: main.py not found!${NC}"
    echo -e "${YELLOW}Please run this script from the project root directory${NC}\n"
    exit 1
fi

# Step 1: Setup
echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}${BOLD}STEP 1/3: Running Setup${NC}"
echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────${NC}\n"

if [ -f "$SCRIPT_DIR/setup.sh" ]; then
    bash "$SCRIPT_DIR/setup.sh"
else
    echo -e "${RED}✗ setup.sh not found at $SCRIPT_DIR/setup.sh${NC}\n"
    exit 1
fi

echo -e "${GREEN}✓ Setup completed successfully!${NC}\n"
sleep 2

# Step 2: Start Server
echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}${BOLD}STEP 2/3: Starting Server${NC}"
echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────${NC}\n"

# Kill any existing server
if [ -f "server.pid" ]; then
    OLD_PID=$(cat server.pid)
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ Killing existing server (PID: $OLD_PID)${NC}"
        kill "$OLD_PID" 2>/dev/null || true
        sleep 2
    fi
    rm -f server.pid
fi

if [ -f "$SCRIPT_DIR/start.sh" ]; then
    bash "$SCRIPT_DIR/start.sh"
else
    echo -e "${RED}✗ start.sh not found at $SCRIPT_DIR/start.sh${NC}\n"
    exit 1
fi

echo -e "${GREEN}✓ Server started successfully!${NC}\n"
sleep 3

# Step 3: Run Tests
echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}${BOLD}STEP 3/3: Running Tests${NC}"
echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────${NC}\n"

if [ -f "$SCRIPT_DIR/send_request.sh" ]; then
    bash "$SCRIPT_DIR/send_request.sh"
    TEST_RESULT=$?
else
    echo -e "${RED}✗ send_request.sh not found at $SCRIPT_DIR/send_request.sh${NC}\n"
    exit 1
fi

# Final Summary
echo -e "${MAGENTA}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║            🎉 Deployment Complete! 🎉               ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Load environment
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

PORT=${LISTEN_PORT:-8096}

echo -e "${CYAN}Server Information:${NC}"
echo -e "  ${BLUE}URL:${NC} http://localhost:$PORT"
echo -e "  ${BLUE}Health:${NC} http://localhost:$PORT/health"
echo -e "  ${BLUE}Models:${NC} http://localhost:$PORT/v1/models"
if [ -f "server.pid" ]; then
    echo -e "  ${BLUE}PID:${NC} $(cat server.pid)"
fi
echo ""

echo -e "${CYAN}Useful Commands:${NC}"
echo -e "  ${YELLOW}View logs:${NC} tail -f logs/server.log"
echo -e "  ${YELLOW}Stop server:${NC} kill \$(cat server.pid)"
echo -e "  ${YELLOW}Run tests again:${NC} bash scripts/send_request.sh"
echo ""

echo -e "${CYAN}Example API Call (OpenAI Compatible):${NC}"
echo -e "${BLUE}python3 -c '
import openai

client = openai.OpenAI(
    base_url=\"http://localhost:$PORT/v1\",
    api_key=\"sk-test\"
)

response = client.chat.completions.create(
    model=\"qwen-max-latest\",
    messages=[{\"role\": \"user\", \"content\": \"Hello!\"}],
    stream=False
)

print(response.choices[0].message.content)
'${NC}"
echo ""

echo -e "${CYAN}Or using curl:${NC}"
echo -e "${BLUE}curl -X POST http://localhost:$PORT/v1/chat/completions \\\\${NC}"
echo -e "${BLUE}  -H 'Content-Type: application/json' \\\\${NC}"
echo -e "${BLUE}  -H 'Authorization: Bearer sk-test' \\\\${NC}"
echo -e "${BLUE}  -d '{${NC}"
echo -e "${BLUE}    \"model\": \"qwen-turbo\",${NC}"
echo -e "${BLUE}    \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}],${NC}"
echo -e "${BLUE}    \"stream\": false${NC}"
echo -e "${BLUE}  }'${NC}"
echo ""

if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ All systems operational! Your Qwen API is ready to use.${NC}\n"
    
    echo -e "${CYAN}${BOLD}Server is running in background...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop watching logs (server will keep running)${NC}"
    echo -e "${YELLOW}To stop server: kill \$(cat server.pid)${NC}\n"
    
    # Follow logs
    echo -e "${CYAN}${BOLD}Streaming logs (Ctrl+C to exit):${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}\n"
    
    # Trap Ctrl+C
    trap 'echo -e "\n${YELLOW}Stopped watching logs. Server still running.${NC}\n"; exit 0' INT
    
    tail -f logs/server.log
    
else
    echo -e "${YELLOW}${BOLD}⚠️ Some tests failed. Check the logs for details.${NC}"
    echo -e "${BLUE}Logs location:${NC} logs/server.log\n"
    
    echo -e "${CYAN}Server is still running. You can:${NC}"
    echo -e "  ${YELLOW}→${NC} Check logs: tail -f logs/server.log"
    echo -e "  ${YELLOW}→${NC} Run tests: bash scripts/send_request.sh"
    echo -e "  ${YELLOW}→${NC} Stop server: kill \$(cat server.pid)"
    echo ""
    
    exit 1
fi

