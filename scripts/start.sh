#!/usr/bin/env bash
################################################################################
# start.sh - Start OpenAI API Server and Run Tests
# Starts the Qwen API server and validates all 4 endpoints
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

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_header() {
    echo -e "\n${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║$1${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

# Get network IP address
get_network_ip() {
    # Try to get the primary network IP (not localhost)
    if command -v ip &>/dev/null; then
        # Linux
        ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo "localhost"
    elif command -v ifconfig &>/dev/null; then
        # macOS/BSD
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1 || echo "localhost"
    else
        echo "localhost"
    fi
}

print_header "       Qwen API - Starting Server & Running Tests           "

# Check if setup was run
if [ ! -d "venv" ]; then
    print_error "Virtual environment not found!"
    print_info "Please run: bash scripts/setup.sh"
    exit 1
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source venv/bin/activate
print_success "Virtual environment activated"

# Check if server is already running
PORT=8096
if lsof -i :$PORT > /dev/null 2>&1; then
    print_warning "Port $PORT is already in use"
    print_info "Stopping existing server..."
    
    # Try to kill existing process
    PID=$(lsof -t -i:$PORT)
    if [ -n "$PID" ]; then
        kill $PID 2>/dev/null || true
        sleep 2
    fi
fi

# Get network information
NETWORK_IP=$(get_network_ip)
LOCALHOST="localhost"

print_info "Starting Qwen API server..."
print_info "Port: $PORT"

# Start server in background
nohup python start.py > logs/server.log 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > server.pid

print_success "Server starting (PID: $SERVER_PID)"

# Wait for server to be ready
print_info "Waiting for server to be ready..."
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s http://localhost:$PORT/health > /dev/null 2>&1; then
        break
    fi
    sleep 1
    WAITED=$((WAITED + 1))
    echo -ne "${CYAN}⏳ Waiting... ${WAITED}s${NC}\r"
done

if [ $WAITED -ge $MAX_WAIT ]; then
    print_error "Server failed to start within ${MAX_WAIT}s"
    print_info "Check logs: tail -f logs/server.log"
    exit 1
fi

echo "" # Clear the waiting line
print_success "Server is ready!"

# Display server information
print_header "       🚀 Server Running Successfully!                         "

echo -e "${GREEN}${BOLD}📡 Server Information:${NC}"
echo -e "   ${CYAN}Status:${NC}         ${GREEN}● Running${NC}"
echo -e "   ${CYAN}PID:${NC}            ${YELLOW}$SERVER_PID${NC}"
echo -e "   ${CYAN}Port:${NC}           ${YELLOW}$PORT${NC}"
echo ""
echo -e "${GREEN}${BOLD}🌐 Access URLs:${NC}"
echo -e "   ${CYAN}Local:${NC}          ${YELLOW}http://$LOCALHOST:$PORT${NC}"
if [ "$NETWORK_IP" != "localhost" ]; then
    echo -e "   ${CYAN}Network:${NC}        ${YELLOW}http://$NETWORK_IP:$PORT${NC}"
    echo -e "   ${CYAN}(For LAN):${NC}      Use this URL from other devices on your network"
fi
echo ""
echo -e "${GREEN}${BOLD}🔗 Endpoints:${NC}"
echo -e "   ${CYAN}API Base:${NC}       ${YELLOW}http://$LOCALHOST:$PORT/v1${NC}"
echo -e "   ${CYAN}Health:${NC}         ${YELLOW}http://$LOCALHOST:$PORT/health${NC}"
echo -e "   ${CYAN}Models:${NC}         ${YELLOW}http://$LOCALHOST:$PORT/v1/models${NC}"
echo -e "   ${CYAN}Docs:${NC}           ${YELLOW}http://$LOCALHOST:$PORT/docs${NC}"

if [ "$NETWORK_IP" != "localhost" ]; then
    echo ""
    echo -e "${GREEN}${BOLD}📱 Network Access (OpenAI SDK):${NC}"
    echo -e "${YELLOW}from openai import OpenAI"
    echo -e "client = OpenAI("
    echo -e "    api_key=\"sk-any\","
    echo -e "    base_url=\"http://$NETWORK_IP:$PORT/v1\""
    echo -e ")${NC}"
fi

# Display model information
echo ""
echo -e "${GREEN}${BOLD}🤖 Available Models:${NC}"
echo -e "   ${CYAN}1.${NC} ${YELLOW}qwen3${NC} or ${YELLOW}qwen3-max${NC}"
echo -e "      → qwen3-max-latest"
echo -e "      → ${GREEN}✅ Web Search${NC}, ${RED}❌ No Thinking${NC}"
echo ""
echo -e "   ${CYAN}2.${NC} ${YELLOW}qwen3-web${NC} or ${YELLOW}qwen3-235b${NC}"
echo -e "      → qwen3-235b-a22b-2507"
echo -e "      → ${GREEN}✅ Web Search + Thinking${NC}, ${CYAN}81,920 tokens${NC}"
echo ""
echo -e "   ${CYAN}3.${NC} ${YELLOW}qwen3-vl${NC}"
echo -e "      → qwen3-vl-235b-a22b"
echo -e "      → ${RED}❌ No Web Search${NC}, ${GREEN}✅ Thinking${NC}, ${CYAN}81,920 tokens${NC}"
echo ""
echo -e "   ${CYAN}4.${NC} ${YELLOW}qwen3-omni${NC}"
echo -e "      → qwen3-omni-flash"
echo -e "      → ${RED}❌ No Web Search${NC}, ${GREEN}✅ Thinking${NC}, ${CYAN}81,920 tokens${NC}"

# Run comprehensive tests
print_header "       🧪 Running Comprehensive Endpoint Tests                 "

print_info "Testing all 4 models with different scenarios..."

# Test function
test_model() {
    local MODEL=$1
    local DESCRIPTION=$2
    
    echo -e "\n${CYAN}Testing: ${YELLOW}$MODEL${NC} - $DESCRIPTION"
    
    RESPONSE=$(curl -s -X POST http://localhost:$PORT/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer sk-any" \
        -d "{
            \"model\": \"$MODEL\",
            \"messages\": [{\"role\": \"user\", \"content\": \"What model are you?\"}]
        }" 2>/dev/null)
    
    if echo "$RESPONSE" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
        ACTUAL_MODEL=$(echo "$RESPONSE" | jq -r '.model // "unknown"')
        print_success "$MODEL → $ACTUAL_MODEL"
        return 0
    else
        print_error "$MODEL failed"
        print_warning "Response: $RESPONSE"
        return 1
    fi
}

# Test all 4 models
PASSED=0
FAILED=0

echo -e "${CYAN}${BOLD}Test 1/4: Qwen3-Max (Default alias)${NC}"
if test_model "qwen3" "Fast responses with web search"; then
    PASSED=$((PASSED + 1))
else
    FAILED=$((FAILED + 1))
fi

echo -e "\n${CYAN}${BOLD}Test 2/4: Qwen3-235B (Web + Thinking)${NC}"
if test_model "qwen3-web" "Complex reasoning with internet"; then
    PASSED=$((PASSED + 1))
else
    FAILED=$((FAILED + 1))
fi

echo -e "\n${CYAN}${BOLD}Test 3/4: Qwen3-VL (Vision-Language)${NC}"
if test_model "qwen3-vl" "Image analysis, no web"; then
    PASSED=$((PASSED + 1))
else
    FAILED=$((FAILED + 1))
fi

echo -e "\n${CYAN}${BOLD}Test 4/4: Qwen3-Omni (Multimodal)${NC}"
if test_model "qwen3-omni" "Text + Image + Audio + Video"; then
    PASSED=$((PASSED + 1))
else
    FAILED=$((FAILED + 1))
fi

# Test results
echo ""
print_header "       📊 Test Results                                         "

echo -e "${GREEN}${BOLD}✅ Passed:${NC} $PASSED/4"
echo -e "${RED}${BOLD}❌ Failed:${NC} $FAILED/4"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}🎉 All tests passed! Server is working correctly!${NC}"
else
    echo -e "\n${YELLOW}${BOLD}⚠️  Some tests failed. Check logs for details.${NC}"
fi

# Final information
print_header "       ℹ️  Useful Commands                                      "

echo -e "${CYAN}View logs:${NC}          ${YELLOW}tail -f logs/server.log${NC}"
echo -e "${CYAN}Stop server:${NC}        ${YELLOW}kill $SERVER_PID${NC} or ${YELLOW}kill \$(cat server.pid)${NC}"
echo -e "${CYAN}Restart:${NC}            ${YELLOW}bash scripts/start.sh${NC}"
echo -e "${CYAN}Run more tests:${NC}     ${YELLOW}python tests/test_endpoint_behavior_standalone.py${NC}"
echo -e "${CYAN}Health check:${NC}       ${YELLOW}curl http://localhost:$PORT/health${NC}"

echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}Server is running! Press Ctrl+C to view logs (server stays running)${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}\n"

