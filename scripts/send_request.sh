#!/usr/bin/env bash
################################################################################
# send_request.sh - Test All Qwen Model Endpoints
# Tests various Qwen models with OpenAI-compatible format
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Load environment
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

PORT=${LISTEN_PORT:-8096}
BASE_URL="http://localhost:$PORT/v1"
AUTH_TOKEN=${AUTH_TOKEN:-sk-test}

echo -e "${MAGENTA}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║       Qwen API - Comprehensive Endpoint Testing     ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Check if server is running
echo -e "${CYAN}Checking server status...${NC}"
if ! curl -s http://localhost:$PORT/health > /dev/null 2>&1; then
    echo -e "${RED}✗ Server is not running on port $PORT${NC}"
    echo -e "${YELLOW}Start the server first: bash scripts/start.sh${NC}\n"
    exit 1
fi
echo -e "${GREEN}✓ Server is running${NC}\n"

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run test
run_test() {
    local TEST_NAME="$1"
    local MODEL="$2"
    local PROMPT="$3"
    local EXTRA_PARAMS="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}Test #$TOTAL_TESTS: $TEST_NAME${NC}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Model:${NC} $MODEL"
    echo -e "${BLUE}Prompt:${NC} $PROMPT"
    
    # Build JSON payload
    PAYLOAD=$(cat <<EOF
{
  "model": "$MODEL",
  "messages": [
    {
      "role": "user",
      "content": "$PROMPT"
    }
  ],
  "stream": false
  $EXTRA_PARAMS
}
EOF
)
    
    echo -e "${BLUE}Request:${NC}"
    echo "$PAYLOAD" | jq -C '.' 2>/dev/null || echo "$PAYLOAD"
    echo ""
    
    # Send request
    echo -e "${YELLOW}⏳ Sending request...${NC}"
    RESPONSE=$(curl -s -X POST "$BASE_URL/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -d "$PAYLOAD" 2>&1)
    
    # Check response
    if echo "$RESPONSE" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}✓ Test Passed!${NC}\n"
        
        # Extract and print the actual content (remove quotes)
        CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null)
        
        echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}${BOLD}📝 ACTUAL RESPONSE:${NC}"
        echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${WHITE}$CONTENT${NC}"
        echo ""
        echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        # Show metadata
        echo -e "${BLUE}Metadata:${NC}"
        echo "$RESPONSE" | jq -C '{
          id: .id,
          model: .model,
          created: .created,
          finish_reason: .choices[0].finish_reason
        }' 2>/dev/null || echo "N/A"
        
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}✗ Test Failed!${NC}\n"
        
        echo -e "${RED}Error Response:${NC}"
        echo "$RESPONSE" | jq -C '.' 2>/dev/null || echo "$RESPONSE"
    fi
    
    echo ""
    sleep 2
}

# Test Suite
echo -e "${MAGENTA}${BOLD}Starting Test Suite...${NC}\n"

# Test 1: Linear Algebra Explanation
run_test \
    "Math Explanation - qwen-max-latest" \
    "qwen-max-latest" \
    "What is linear algebra? Explain it clearly and give 2 real-world applications."

# Test 2: Code Generation
run_test \
    "Code Generation - qwen3-coder-plus" \
    "qwen3-coder-plus" \
    "Write a Python function to find the factorial of a number using recursion. Include comments."

# Test 3: Fast Response
run_test \
    "Fast Response - qwen-turbo" \
    "qwen-turbo" \
    "Explain what APIs are in 2 sentences."

# Test 4: Technical Explanation
run_test \
    "Technical Deep Dive - qwen-plus" \
    "qwen-plus" \
    "What is the difference between machine learning and deep learning?"

# Test 5: Research Mode
run_test \
    "Research Mode - qwen-deep-research" \
    "qwen-deep-research" \
    "What are the key principles of REST API design?"

# Summary
echo -e "${MAGENTA}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║              Test Summary Report                     ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

echo -e "${CYAN}Results:${NC}"
echo -e "  ${BLUE}Total Tests:${NC} $TOTAL_TESTS"
echo -e "  ${GREEN}Passed:${NC} $PASSED_TESTS"
echo -e "  ${RED}Failed:${NC} $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}✓ All tests passed! 🎉${NC}"
    PASS_RATE="100%"
else
    PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
    echo -e "\n${YELLOW}⚠ Some tests failed. Pass rate: $PASS_RATE%${NC}"
fi

echo ""
echo -e "${CYAN}Additional Tests:${NC}"
echo -e "  ${YELLOW}→${NC} Test streaming: curl -N -X POST $BASE_URL/chat/completions \\"
echo -e "      -H 'Content-Type: application/json' \\"
echo -e "      -H 'Authorization: Bearer $AUTH_TOKEN' \\"
echo -e "      -d '{\"model\":\"qwen-turbo\",\"messages\":[{\"role\":\"user\",\"content\":\"Hi\"}],\"stream\":true}'"
echo ""
echo -e "  ${YELLOW}→${NC} List models: curl http://localhost:$PORT/v1/models"
echo ""

# Exit with appropriate code
if [ $FAILED_TESTS -eq 0 ]; then
    exit 0
else
    exit 1
fi
