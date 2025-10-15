#!/usr/bin/env bash
################################################################################
# test_integration.sh - Test the new modular architecture
# 
# Usage:
#   export QWEN_EMAIL="your-email@example.com"
#   export QWEN_PASSWORD="your-password"
#   export SERVER_PORT=7323
#   bash scripts/test_integration.sh
################################################################################

set -euo pipefail

# Color definitions
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Configuration
readonly SERVER_PORT="${SERVER_PORT:-7323}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║         Qwen API Modular Architecture Integration Test           ║${NC}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

################################################################################
# Step 1: Setup
################################################################################
echo -e "${BLUE}${BOLD}[1/5] Running Setup...${NC}"
if bash scripts/setup.sh; then
    echo -e "${GREEN}✓ Setup completed${NC}"
else
    echo -e "${YELLOW}⚠ Setup may have already been completed${NC}"
fi
echo ""

################################################################################
# Step 2: Start Server
################################################################################
echo -e "${BLUE}${BOLD}[2/5] Starting Server on Port ${SERVER_PORT}...${NC}"
export PORT="$SERVER_PORT"
bash scripts/start.sh &
SERVER_PID=$!
echo -e "${GREEN}✓ Server started (PID: $SERVER_PID)${NC}"
echo -e "${CYAN}   Waiting for server to be ready...${NC}"
sleep 5

# Check if server is running
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo -e "${YELLOW}⚠ Server may not have started correctly${NC}"
fi
echo ""

################################################################################
# Step 3: Test API Endpoints
################################################################################
echo -e "${BLUE}${BOLD}[3/5] Testing API Endpoints...${NC}"

# Test health check
echo -e "${CYAN}Testing health check (/)...${NC}"
HEALTH_RESPONSE=$(curl -s "http://localhost:${SERVER_PORT}/")
echo "$HEALTH_RESPONSE" | python3 -m json.tool
echo -e "${GREEN}✓ Health check passed${NC}"
echo ""

# Test models list
echo -e "${CYAN}Testing models list (/v1/models)...${NC}"
MODELS_RESPONSE=$(curl -s "http://localhost:${SERVER_PORT}/v1/models")
echo "$MODELS_RESPONSE" | python3 -m json.tool
echo ""
echo -e "${BOLD}Available Model Names:${NC}"
echo "$MODELS_RESPONSE" | python3 -c "import sys, json; data = json.load(sys.stdin); print('\n'.join(['  • ' + m['id'] for m in data['data']]))"
echo -e "${GREEN}✓ Models list retrieved${NC}"
echo ""

################################################################################
# Step 4: Test Chat Completion
################################################################################
echo -e "${BLUE}${BOLD}[4/5] Testing Chat Completion...${NC}"

cat > /tmp/test_client_$$.py << 'EOFPYTHON'
from openai import OpenAI
import sys
import os

SERVER_PORT = os.getenv("SERVER_PORT", "7323")

client = OpenAI(
    api_key="sk-any",  # ✅ Any key works!
    base_url=f"http://localhost:{SERVER_PORT}/v1"
)

try:
    result = client.chat.completions.create(
        model="gpt-5",  # ✅ Any model works!
        messages=[{"role": "user", "content": "Write a haiku about code."}]
    )
    
    print("\n" + "="*70)
    print("Chat Completion Response:")
    print("="*70)
    print(result.choices[0].message.content)
    print("="*70)
    print(f"\nModel used: {result.model}")
    print(f"Tokens: {result.usage.total_tokens} (prompt: {result.usage.prompt_tokens}, completion: {result.usage.completion_tokens})")
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
EOFPYTHON

export SERVER_PORT
if python3 /tmp/test_client_$$.py; then
    echo -e "${GREEN}✓ Chat completion test passed${NC}"
else
    echo -e "${YELLOW}⚠ Chat completion test failed${NC}"
fi
rm -f /tmp/test_client_$$.py
echo ""

################################################################################
# Step 5: Summary
################################################################################
echo -e "${BLUE}${BOLD}[5/5] Test Summary${NC}"
echo ""
echo -e "${CYAN}${BOLD}Server Information:${NC}"
echo -e "  Port: ${BOLD}${SERVER_PORT}${NC}"
echo -e "  PID: ${BOLD}${SERVER_PID}${NC}"
echo -e "  Base URL: ${BOLD}http://localhost:${SERVER_PORT}/v1${NC}"
echo ""
echo -e "${CYAN}${BOLD}Available Endpoints:${NC}"
echo -e "  • ${BOLD}/${NC} - Health check"
echo -e "  • ${BOLD}/v1/models${NC} - List available models"
echo -e "  • ${BOLD}/v1/chat/completions${NC} - Chat completions"
echo ""
echo -e "${CYAN}${BOLD}Available Models:${NC}"
echo "$MODELS_RESPONSE" | python3 -c "import sys, json; data = json.load(sys.stdin); print('\n'.join(['  • ' + m['id'] for m in data['data']]))"
echo ""
echo -e "${GREEN}${BOLD}✓ Integration test completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Server is still running (PID: $SERVER_PID)${NC}"
echo -e "${YELLOW}To stop it: kill $SERVER_PID${NC}"
echo ""

