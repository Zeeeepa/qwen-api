#!/usr/bin/env bash
################################################################################
# send_request.sh - Comprehensive Qwen API Endpoint Testing
#
# Tests multiple Qwen models with various prompts:
# - qwen-max-latest
# - qwen3-coder-plus
# - qwen-turbo
# - qwen-plus
# - qwen-deep-research
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

# Project paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly ENV_FILE="${PROJECT_ROOT}/.env"
readonly VENV_ACTIVATE="${PROJECT_ROOT}/.venv/bin/activate"

# Test configuration
readonly DEFAULT_PORT=8096
readonly REQUEST_TIMEOUT=30

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

cd "$PROJECT_ROOT"

# Activate virtual environment if it exists
if [ -f "$VENV_ACTIVATE" ]; then
    source "$VENV_ACTIVATE"
fi

################################################################################
# Utility Functions
################################################################################

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_info() {
    echo -e "${CYAN}$1${NC}"
}

print_header() {
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║       Qwen API - Comprehensive Endpoint Testing     ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

print_footer() {
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║              Test Summary Report                     ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

################################################################################
# Dependency Checks
################################################################################

check_dependencies() {
    local missing_deps=()
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Install with:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "jq")
                    echo "  Ubuntu/Debian: sudo apt-get install jq"
                    echo "  macOS: brew install jq"
                    ;;
                "curl")
                    echo "  Ubuntu/Debian: sudo apt-get install curl"
                    echo "  macOS: brew install curl"
                    ;;
            esac
        done
        exit 1
    fi
    
    log_success "All dependencies available"
}

################################################################################
# Configuration
################################################################################

load_config() {
    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck source=/dev/null
        set -a
        source "$ENV_FILE"
        set +a
    else
        log_error ".env file not found at $ENV_FILE"
        log_warning "Run setup first: bash scripts/setup.sh"
        exit 1
    fi
}

get_port() {
    echo "${LISTEN_PORT:-$DEFAULT_PORT}"
}

get_auth_token() {
    # Use QWEN_BEARER_TOKEN if available, otherwise fall back to default
    if [ -n "${QWEN_BEARER_TOKEN:-}" ] && [ "$QWEN_BEARER_TOKEN" != "your-bearer-token-here" ]; then
        echo "$QWEN_BEARER_TOKEN"
    else
        echo "sk-test"  # Default fallback
    fi
}

################################################################################
# Server Health Check
################################################################################

check_server() {
    local port=$1
    
    log_info "Checking server status on port $port..."
    
    if ! curl -s --max-time 5 "http://localhost:$port/health" > /dev/null 2>&1; then
        log_error "Server is not running on port $port"
        log_warning "Start the server first: bash scripts/start.sh"
        echo ""
        exit 1
    fi
    
    log_success "Server is running and healthy"
    echo ""
}

################################################################################
# Available Models Check
################################################################################

check_available_models() {
    local base_url=$1
    local auth_token=$2
    
    log_info "Checking available models..."
    
    local models_response
    models_response=$(curl -s --max-time 10 \
        -H "Authorization: Bearer $auth_token" \
        "$base_url/models")
    
    if echo "$models_response" | jq -e '.data' > /dev/null 2>&1; then
        log_success "Models endpoint responding"
        echo -e "${BLUE}Available models:${NC}"
        echo "$models_response" | jq -r '.data[].id' | while read -r model; do
            echo "  - $model"
        done
    else
        log_warning "Could not fetch available models"
    fi
    echo ""
}

################################################################################
# Test Execution
################################################################################

run_test() {
    local test_name="$1"
    local model="$2"
    local prompt="$3"
    local extra_params="${4:-}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}Test #$TOTAL_TESTS: $test_name${NC}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Model:${NC} $model"
    echo -e "${BLUE}Prompt:${NC} $prompt"
    
    # Build JSON payload with proper escaping
    local payload
    if ! payload=$(jq -n \
        --arg model "$model" \
        --arg content "$prompt" \
        '{
            model: $model,
            messages: [
                {
                    role: "user",
                    content: $content
                }
            ],
            stream: false
        }' 2>/dev/null); then
        log_error "Failed to create JSON payload"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    # Add extra parameters if provided
    if [[ -n "$extra_params" ]]; then
        if ! payload=$(echo "$payload" | jq ". + $extra_params" 2>/dev/null); then
            log_warning "Failed to add extra parameters, using base payload"
        fi
    fi
    
    echo -e "${BLUE}Request:${NC}"
    echo "$payload" | jq -C '.' 2>/dev/null || echo "$payload"
    echo ""
    
    # Send request
    log_warning "⏳ Sending request (timeout: ${REQUEST_TIMEOUT}s)..."
    
    local response
    local http_code
    local curl_output
    
    curl_output=$(curl -s -w "\n%{http_code}" --max-time "$REQUEST_TIMEOUT" \
        -X POST "$BASE_URL/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -d "$payload" 2>&1)
    
    # Extract HTTP status code from last line
    http_code=$(echo "$curl_output" | tail -1)
    response=$(echo "$curl_output" | head -n -1)
    
    # Validate response
    if [[ "$http_code" == "200" ]]; then
        if echo "$response" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
            log_success "Test Passed! (HTTP $http_code)"
            echo ""
            
            # Extract content
            local content
            content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
            
            echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CYAN}${BOLD}📝 RESPONSE CONTENT:${NC}"
            echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
            # Truncate very long responses for readability
            if [ ${#content} -gt 2000 ]; then
                echo -e "${WHITE}${content:0:1000}${NC}"
                echo -e "${YELLOW}...[Content truncated - ${#content} chars total]...${NC}"
                echo -e "${WHITE}${content: -500}${NC}"
            else
                echo -e "${WHITE}$content${NC}"
            fi
            
            echo ""
            echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
            # Show metadata
            echo -e "${BLUE}Metadata:${NC}"
            echo "$response" | jq -C '{
                id: .id,
                model: .model,
                created: .created,
                finish_reason: .choices[0].finish_reason,
                usage: .usage
            }' 2>/dev/null || echo "N/A"
            
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
            log_error "Test Failed! Invalid response format (HTTP $http_code)"
            echo -e "${RED}Response:${NC}"
            echo "$response" | head -100
        fi
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "Test Failed! (HTTP ${http_code:-N/A})"
        echo ""
        
        echo -e "${RED}Error Details:${NC}"
        
        # Try to extract error message
        if echo "$response" | jq -e '.error.message' > /dev/null 2>&1; then
            local error_msg
            error_msg=$(echo "$response" | jq -r '.error.message')
            echo -e "${RED}Error: $error_msg${NC}"
        fi
        
        # Show raw response for debugging
        echo -e "${YELLOW}Raw response:${NC}"
        if echo "$response" | jq -e '.' > /dev/null 2>&1; then
            echo "$response" | jq -C '.' | head -50
        else
            echo "$response" | head -20
        fi
    fi
    
    echo ""
    sleep 2
}

################################################################################
# Test Suite
################################################################################

run_test_suite() {
    log_info "Starting Test Suite..."
    echo ""
    
    # Test 1: Math Explanation
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
    
    # Test 5: Research Mode (if available)
    run_test \
        "Research Mode - qwen-deep-research" \
        "qwen-deep-research" \
        "What are the key principles of REST API design?" \
        '{"max_tokens": 500}'
}

################################################################################
# Results Display
################################################################################

print_results() {
    local pass_rate
    if [ $TOTAL_TESTS -gt 0 ]; then
        pass_rate=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
    else
        pass_rate=0
    fi
    
    print_footer
    
    echo -e "${CYAN}${BOLD}Test Results:${NC}"
    echo -e "  ${BLUE}Total Tests:${NC} $TOTAL_TESTS"
    echo -e "  ${GREEN}Passed:${NC} $PASSED_TESTS"
    echo -e "  ${RED}Failed:${NC} $FAILED_TESTS"
    echo -e "  ${MAGENTA}Success Rate:${NC} $pass_rate%"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 && $TOTAL_TESTS -gt 0 ]]; then
        echo -e "${GREEN}${BOLD}🎉 All tests passed! Your Qwen API is working perfectly!${NC}"
    elif [[ $PASSED_TESTS -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}⚠ Some tests failed, but the API is partially working${NC}"
    else
        echo -e "${RED}${BOLD}❌ All tests failed. Please check your setup and server logs${NC}"
    fi
    echo ""
}

print_additional_tests() {
    local port=$1
    
    echo -e "${CYAN}${BOLD}Additional Testing Options:${NC}"
    echo -e "  ${YELLOW}→${NC} Test streaming mode:"
    echo -e "    ${BLUE}curl -N -X POST http://localhost:$port/v1/chat/completions \\\\${NC}"
    echo -e "      ${BLUE}-H 'Content-Type: application/json' \\\\${NC}"
    echo -e "      ${BLUE}-H 'Authorization: Bearer $AUTH_TOKEN' \\\\${NC}"
    echo -e "      ${BLUE}-d '{\"model\":\"qwen-turbo\",\"messages\":[{\"role\":\"user\",\"content\":\"Hi\"}],\"stream\":true}'${NC}"
    echo ""
    echo -e "  ${YELLOW}→${NC} List available models:"
    echo -e "    ${BLUE}curl -s http://localhost:$port/v1/models | jq${NC}"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header
    
    # Check dependencies first
    check_dependencies
    
    # Load configuration
    load_config
    
    local port auth_token base_url
    port=$(get_port)
    auth_token=$(get_auth_token)
    base_url="http://localhost:$port/v1"
    
    # Export for use in run_test
    export BASE_URL="$base_url"
    export AUTH_TOKEN="$auth_token"
    
    log_info "Configuration:"
    echo -e "  ${BLUE}Port:${NC} $port"
    echo -e "  ${BLUE}Base URL:${NC} $base_url"
    echo -e "  ${BLUE}Auth Token:${NC} ${auth_token:0:10}...[${#auth_token} chars]"
    echo ""
    
    # Check server health
    check_server "$port"
    
    # Check available models
    check_available_models "$base_url" "$auth_token"
    
    # Run tests
    run_test_suite
    
    # Display results
    print_results
    print_additional_tests "$port"
    
    # Exit with appropriate code
    if [[ $FAILED_TESTS -eq 0 && $TOTAL_TESTS -gt 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
