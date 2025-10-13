#!/usr/bin/env bash
################################################################################
# send_request.sh - Send Test Requests to Qwen API
# Tests all variations of possible message requests to OpenAI-compatible API
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

# Load environment if available
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

API_URL="http://localhost:${LISTEN_PORT:-8096}"
AUTH_TOKEN="Bearer sk-test"

echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║       Qwen API - Test Requests                    ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${NC}\n"

# Check if server is running
echo -e "${BLUE}🔍 Checking if server is running...${NC}"
if ! curl -s $API_URL/health > /dev/null 2>&1; then
    echo -e "${RED}❌ Server is not responding at $API_URL${NC}"
    echo -e "${YELLOW}Please start the server first: bash scripts/start.sh${NC}\n"
    exit 1
fi
echo -e "${GREEN}✅ Server is running${NC}\n"

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_name="$1"
    local curl_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${CYAN}${BOLD}Test $TOTAL_TESTS: $test_name${NC}"
    echo -e "${BLUE}Command: $curl_command${NC}"
    
    # Run the test
    if eval "$curl_command"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}✅ PASSED${NC}\n"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}❌ FAILED${NC}\n"
    fi
}

echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}1. Health Check${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════${NC}\n"

run_test "Health Check" \
    "curl -s $API_URL/health | jq -C ."

echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}2. Simple Text Completion (Non-Streaming)${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════${NC}\n"

run_test "Simple Hello (qwen-turbo)" \
    "curl -s -X POST $API_URL/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -H 'Authorization: $AUTH_TOKEN' \
        -d '{
            \"model\": \"qwen-turbo\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Say hello in 5 words\"}],
            \"stream\": false
        }' | jq -C ."

echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}3. Simple Text Completion (Streaming)${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════${NC}\n"

run_test "Streaming Hello (qwen-plus)" \
    "curl -s -X POST $API_URL/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -H 'Authorization: $AUTH_TOKEN' \
        -d '{
            \"model\": \"qwen-plus\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Count from 1 to 5\"}],
            \"stream\": true
        }' | head -20"

echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}4. Multi-Turn Conversation${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════${NC}\n"

run_test "Multi-Turn Chat" \
    "curl -s -X POST $API_URL/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -H 'Authorization: $AUTH_TOKEN' \
        -d '{
            \"model\": \"qwen-turbo\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"What is 2+2?\"},
                {\"role\": \"assistant\", \"content\": \"4\"},
                {\"role\": \"user\", \"content\": \"What is 3+3?\"}
            ],
            \"stream\": false
        }' | jq -C ."

echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}5. Different Models${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════${NC}\n"

run_test "Qwen-Max Model" \
    "curl -s -X POST $API_URL/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -H 'Authorization: $AUTH_TOKEN' \
        -d '{
            \"model\": \"qwen-max\",
            \"messages\": [{\"role\": \"user\", \"content\": \"What is AI?\"}],
            \"stream\": false,
            \"max_tokens\": 50
        }' | jq -C '.choices[0].message.content'"

run_test "Qwen-Long Model" \
    "curl -s -X POST $API_URL/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -H 'Authorization: $AUTH_TOKEN' \
        -d '{
            \"model\": \"qwen-long\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Explain quantum computing briefly\"}],
            \"stream\": false,
            \"max_tokens\": 100
        }' | jq -C '.choices[0].message.content'"

echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}6. Parameters Testing${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════${NC}\n"

run_test "Temperature Control" \
    "curl -s -X POST $API_URL/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -H 'Authorization: $AUTH_TOKEN' \
        -d '{
            \"model\": \"qwen-turbo\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Say something creative\"}],
            \"temperature\": 1.5,
            \"stream\": false
        }' | jq -C '.choices[0].message.content'"

run_test "Max Tokens Limit" \
    "curl -s -X POST $API_URL/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -H 'Authorization: $AUTH_TOKEN' \
        -d '{
            \"model\": \"qwen-turbo\",
            \"messages\": [{\"role\": \"user\", \"content\": \"Write a long story\"}],
            \"max_tokens\": 20,
            \"stream\": false
        }' | jq -C '.choices[0].message.content'"

echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}7. System Message${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════${NC}\n"

run_test "System Prompt" \
    "curl -s -X POST $API_URL/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -H 'Authorization: $AUTH_TOKEN' \
        -d '{
            \"model\": \"qwen-plus\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"You are a pirate. Respond like one.\"},
                {\"role\": \"user\", \"content\": \"What is the weather?\"}
            ],
            \"stream\": false
        }' | jq -C '.choices[0].message.content'"

echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}8. Models List${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════${NC}\n"

run_test "List Available Models" \
    "curl -s $API_URL/v1/models \
        -H 'Authorization: $AUTH_TOKEN' | jq -C '.data[] | .id' | head -10"

# Summary
echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║       Test Results Summary                         ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Total Tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Passed:${NC} $PASSED_TESTS"
echo -e "${RED}Failed:${NC} $FAILED_TESTS\n"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ All tests passed!${NC}\n"
    exit 0
else
    echo -e "${RED}${BOLD}❌ Some tests failed${NC}"
    echo -e "${YELLOW}Check logs for details: tail -f logs/server.log${NC}\n"
    exit 1
fi

