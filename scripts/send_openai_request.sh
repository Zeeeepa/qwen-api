#!/usr/bin/env bash
################################################################################
# send_openai_request.sh - Test OpenAI-Compatible API
#
# This script sends test requests to the Qwen API server and displays responses.
# It validates that the server is working correctly with OpenAI-compatible format.
#
# Usage:
#   bash scripts/send_openai_request.sh [--port PORT] [--model MODEL]
#
# Options:
#   --port PORT        Server port (default: 8096)
#   --model MODEL      Model to test (default: qwen-max-latest)
#   --stream           Test streaming responses
#   --all-models       Test all available models
#   --verbose          Show full request/response
################################################################################

set -euo pipefail

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Script configuration
PORT=8096
MODEL="qwen-max-latest"
STREAM_MODE=false
ALL_MODELS=false
VERBOSE=false

# Available models
declare -a MODELS=(
    "qwen-max-latest"
    "qwen3-coder-plus"
    "qwen-deep-research"
    "qwen-turbo"
    "qwen-plus"
)

################################################################################
# Utility Functions
################################################################################

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

log_step() {
    echo ""
    echo -e "${MAGENTA}${BOLD}$1${NC}"
    echo -e "${MAGENTA}${BOLD}$(printf '=%.0s' {1..60})${NC}"
}

print_header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║        Qwen API - OpenAI Request Tester              ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

################################################################################
# Argument Parsing
################################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)
                PORT="$2"
                shift 2
                ;;
            --model)
                MODEL="$2"
                shift 2
                ;;
            --stream)
                STREAM_MODE=true
                shift
                ;;
            --all-models)
                ALL_MODELS=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Usage: $0 [--port PORT] [--model MODEL] [--stream] [--all-models] [--verbose]"
                exit 1
                ;;
        esac
    done
}

################################################################################
# Server Check
################################################################################

check_server() {
    log_step "Checking server status..."
    
    local base_url="http://localhost:${PORT}"
    
    # Check if server is responding
    if curl -s -f "${base_url}/health" > /dev/null 2>&1; then
        log_success "Server is running on port $PORT"
    else
        log_error "Server is not responding on port $PORT"
        log_info "Please start the server first: bash scripts/start.sh"
        exit 1
    fi
    
    # Get health status
    log_info "Health check response:"
    curl -s "${base_url}/health" | python -m json.tool || echo "Failed to parse health response"
}

################################################################################
# Send Test Request
################################################################################

send_test_request() {
    local model=$1
    local base_url="http://localhost:${PORT}"
    
    log_step "Testing model: $model"
    
    # Prepare request
    local request_payload=$(cat <<EOF
{
  "model": "$model",
  "messages": [
    {
      "role": "user",
      "content": "Hello! Can you briefly tell me what you are and respond in one short sentence?"
    }
  ],
  "stream": $STREAM_MODE,
  "temperature": 0.7,
  "max_tokens": 200
}
EOF
)
    
    if [ "$VERBOSE" = true ]; then
        log_info "Request payload:"
        echo "$request_payload" | python -m json.tool
        echo ""
    fi
    
    # Send request
    log_info "Sending request..."
    
    local start_time=$(date +%s%N)
    
    if [ "$STREAM_MODE" = true ]; then
        # Streaming request
        local response=$(curl -s -N -X POST "${base_url}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -H "Accept: text/event-stream" \
            -d "$request_payload" 2>&1)
        
        local status=$?
        
    else
        # Non-streaming request
        local response=$(curl -s -w "\n%{http_code}" -X POST "${base_url}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$request_payload" 2>&1)
        
        local status=$?
    fi
    
    local end_time=$(date +%s%N)
    local duration=$((($end_time - $start_time) / 1000000))
    
    # Check response
    if [ $status -eq 0 ]; then
        if [ "$STREAM_MODE" = true ]; then
            # Parse streaming response
            log_success "Request completed in ${duration}ms"
            
            echo ""
            log_info "Streaming response:"
            echo -e "${WHITE}${BOLD}────────────────────────────────────────────────────────${NC}"
            echo "$response" | grep "data:" | while read -r line; do
                if [[ "$line" == *"[DONE]"* ]]; then
                    continue
                fi
                
                content=$(echo "$line" | sed 's/data: //' | python -c "import sys, json; data = json.load(sys.stdin); print(data['choices'][0]['delta'].get('content', ''), end='')" 2>/dev/null || echo "")
                echo -n "$content"
            done
            echo ""
            echo -e "${WHITE}${BOLD}────────────────────────────────────────────────────────${NC}"
            
        else
            # Parse non-streaming response
            local http_code=$(echo "$response" | tail -n1)
            local body=$(echo "$response" | sed '$d')
            
            if [ "$http_code" = "200" ]; then
                log_success "Request completed in ${duration}ms (HTTP $http_code)"
                
                # Extract and display response
                echo ""
                log_info "Response content:"
                echo -e "${WHITE}${BOLD}────────────────────────────────────────────────────────${NC}"
                
                if command -v python &> /dev/null; then
                    echo "$body" | python -c "import sys, json; data = json.load(sys.stdin); print(data['choices'][0]['message']['content'])" 2>/dev/null || echo "$body"
                else
                    echo "$body" | grep -o '"content":"[^"]*"' | cut -d'"' -f4
                fi
                
                echo -e "${WHITE}${BOLD}────────────────────────────────────────────────────────${NC}"
                
                if [ "$VERBOSE" = true ]; then
                    echo ""
                    log_info "Full response:"
                    echo "$body" | python -m json.tool 2>/dev/null || echo "$body"
                fi
                
                # Extract stats
                local usage=$(echo "$body" | python -c "import sys, json; data = json.load(sys.stdin); print(f\"Tokens: {data.get('usage', {}).get('total_tokens', 'N/A')}\")" 2>/dev/null || echo "")
                if [ -n "$usage" ]; then
                    log_info "$usage"
                fi
                
            else
                log_error "Request failed (HTTP $http_code)"
                echo ""
                log_info "Error response:"
                echo "$body" | python -m json.tool 2>/dev/null || echo "$body"
                return 1
            fi
        fi
        
    else
        log_error "Request failed"
        echo "$response"
        return 1
    fi
    
    return 0
}

################################################################################
# Test All Models
################################################################################

test_all_models() {
    log_step "Testing all available models..."
    
    local success_count=0
    local failure_count=0
    
    for model in "${MODELS[@]}"; do
        echo ""
        if send_test_request "$model"; then
            ((success_count++))
        else
            ((failure_count++))
        fi
        sleep 1  # Brief pause between requests
    done
    
    echo ""
    log_step "Test Summary"
    log_success "Successful: $success_count/${#MODELS[@]}"
    if [ $failure_count -gt 0 ]; then
        log_error "Failed: $failure_count/${#MODELS[@]}"
    fi
}

################################################################################
# Quick Test
################################################################################

quick_test() {
    log_step "Running quick connectivity test..."
    
    local base_url="http://localhost:${PORT}"
    
    # Test 1: Health endpoint
    echo ""
    log_info "Test 1/3: Health endpoint"
    if curl -s -f "${base_url}/health" > /dev/null 2>&1; then
        log_success "✓ Health endpoint responding"
    else
        log_error "✗ Health endpoint failed"
        return 1
    fi
    
    # Test 2: Models endpoint
    echo ""
    log_info "Test 2/3: Models endpoint"
    if curl -s -f "${base_url}/v1/models" > /dev/null 2>&1; then
        log_success "✓ Models endpoint responding"
        
        # List available models
        log_info "Available models:"
        curl -s "${base_url}/v1/models" | python -c "import sys, json; data = json.load(sys.stdin); [print(f\"  - {m['id']}\") for m in data.get('data', [])]" 2>/dev/null || true
    else
        log_warning "⚠ Models endpoint not available"
    fi
    
    # Test 3: Chat completion
    echo ""
    log_info "Test 3/3: Chat completion"
    if send_test_request "qwen-max-latest"; then
        log_success "✓ Chat completion working"
    else
        log_error "✗ Chat completion failed"
        return 1
    fi
    
    return 0
}

################################################################################
# Main Flow
################################################################################

main() {
    print_header
    
    parse_arguments "$@"
    check_server
    
    if [ "$ALL_MODELS" = true ]; then
        test_all_models
    else
        send_test_request "$MODEL"
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}✅ Test completed!${NC}"
    echo ""
    echo -e "${CYAN}Additional options:${NC}"
    echo -e "  ${YELLOW}--all-models${NC}  Test all available models"
    echo -e "  ${YELLOW}--stream${NC}      Test streaming responses"
    echo -e "  ${YELLOW}--verbose${NC}     Show full request/response"
    echo ""
}

# Run main
main "$@"

