#!/usr/bin/env bash
################################################################################
# send_request.sh - Send OpenAI API Request to Qwen
#
# This script sends a test request to the Qwen API server asking "What is GRAPH-RAG?"
# and displays the response in a formatted way.
#
# Usage:
#   bash scripts/send_request.sh [--port PORT]
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

# Default configuration
PORT=8096

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --port)
            PORT="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 [--port PORT]"
            exit 1
            ;;
    esac
done

################################################################################
# Functions
################################################################################

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                          ║"
    echo "║              🚀 Qwen API - OpenAI Request Test 🚀                        ║"
    echo "║                                                                          ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_server() {
    log_info "Checking server status on port $PORT..."
    
    if curl -s -f "http://localhost:${PORT}/health" > /dev/null 2>&1; then
        log_success "Server is running"
        return 0
    else
        log_error "Server is not responding"
        log_info "Please start the server first: bash scripts/start.sh"
        exit 1
    fi
}

send_request() {
    echo ""
    log_info "Sending OpenAI API request..."
    log_info "Question: \"What is GRAPH-RAG?\""
    log_info "Model: qwen-max-latest"
    echo ""
    
    # Send request and capture response
    RESPONSE=$(curl -s -X POST "http://localhost:${PORT}/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer test-token" \
        -d '{
            "model": "qwen-max-latest",
            "messages": [
                {
                    "role": "user",
                    "content": "What is GRAPH-RAG?"
                }
            ],
            "stream": false,
            "temperature": 0.7,
            "max_tokens": 500
        }' 2>&1)
    
    # Check if request was successful
    if echo "$RESPONSE" | grep -q '"choices"'; then
        log_success "Response received!"
        echo ""
        
        # Parse and display response
        echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}${BOLD}║                      QWEN API RESPONSE                                   ║${NC}"
        echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        # Extract content using python
        CONTENT=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    content = data['choices'][0]['message']['content']
    print(content)
except Exception as e:
    print('Error parsing response:', e, file=sys.stderr)
    sys.exit(1)
")
        
        if [ $? -eq 0 ]; then
            # Display content with word wrapping
            echo "$CONTENT" | fold -s -w 78
            echo ""
            echo -e "${GREEN}${BOLD}$(printf '═%.0s' {1..78})${NC}"
            echo ""
            
            # Extract and display usage statistics
            USAGE=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    usage = data.get('usage', {})
    print(f\"Total: {usage.get('total_tokens', 'N/A')}\")
    print(f\"Prompt: {usage.get('prompt_tokens', 'N/A')}\")
    print(f\"Completion: {usage.get('completion_tokens', 'N/A')}\")
except:
    pass
" 2>/dev/null)
            
            if [ -n "$USAGE" ]; then
                log_info "Token Usage:"
                echo "$USAGE" | while read line; do
                    echo -e "  ${CYAN}•${NC} $line"
                done
                echo ""
            fi
            
            log_success "Request completed successfully!"
            return 0
        else
            log_error "Failed to parse response"
            echo "$RESPONSE"
            return 1
        fi
    else
        log_error "Request failed"
        echo ""
        echo -e "${RED}Response:${NC}"
        echo "$RESPONSE" | head -20
        return 1
    fi
}

################################################################################
# Main
################################################################################

main() {
    print_header
    check_server
    send_request
    echo ""
}

main "$@"

