#!/usr/bin/env bash
################################################################################
# all.sh - Complete Qwen API Deployment & Testing
#
# This is the master orchestration script that runs the complete workflow:
# 1. Deploy (install dependencies, extract token)
# 2. Start server in background
# 3. Test OpenAI API requests
# 4. Keep server running with visible test results
#
# Usage:
#   export QWEN_EMAIL=your-email@example.com
#   export QWEN_PASSWORD=your-password
#   bash scripts/all.sh
#
# Options:
#   --port PORT        Server port (default: 8096)
#   --provider MODE    Provider mode: direct, proxy, auto (default: auto)
#   --skip-deploy      Skip deployment step
#   --no-test          Skip testing step
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
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default configuration
PORT=8096
PROVIDER_MODE="auto"
SKIP_DEPLOY=false
NO_TEST=false
SERVER_PID=""

cd "$PROJECT_ROOT"

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
    echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}${BOLD}║  $1${NC}"
    echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_banner() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║   ██████╗ ██╗    ██╗███████╗███╗   ██╗     █████╗ ██████╗██║
    ║  ██╔═══██╗██║    ██║██╔════╝████╗  ██║    ██╔══██╗██╔══██╗██║
    ║  ██║   ██║██║ █╗ ██║█████╗  ██╔██╗ ██║    ███████║██████╔╝██║
    ║  ██║▄▄ ██║██║███╗██║██╔══╝  ██║╚██╗██║    ██╔══██║██╔═══╝ ██║
    ║  ╚██████╔╝╚███╔███╔╝███████╗██║ ╚████║    ██║  ██║██║     ██║
    ║   ╚══▀▀═╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═══╝    ╚═╝  ╚═╝╚═╝     ╚═╝
    ║                                                           ║
    ║            Complete Deployment & Testing Suite            ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
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
            --provider)
                PROVIDER_MODE="$2"
                shift 2
                ;;
            --skip-deploy)
                SKIP_DEPLOY=true
                shift
                ;;
            --no-test)
                NO_TEST=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Usage: $0 [--port PORT] [--provider MODE] [--skip-deploy] [--no-test]"
                exit 1
                ;;
        esac
    done
}

################################################################################
# Cleanup Handler
################################################################################

cleanup() {
    echo ""
    log_info "Shutting down..."
    
    if [ -n "$SERVER_PID" ] && ps -p "$SERVER_PID" > /dev/null 2>&1; then
        log_info "Stopping server (PID: $SERVER_PID)..."
        kill "$SERVER_PID" 2>/dev/null || true
        
        # Wait for graceful shutdown
        local count=0
        while ps -p "$SERVER_PID" > /dev/null 2>&1 && [ $count -lt 10 ]; do
            sleep 1
            ((count++))
        done
        
        # Force kill if still running
        if ps -p "$SERVER_PID" > /dev/null 2>&1; then
            log_warning "Force killing server..."
            kill -9 "$SERVER_PID" 2>/dev/null || true
        fi
        
        log_success "Server stopped"
    fi
    
    # Clean up PID file
    rm -f .server.pid
    
    echo ""
    log_info "Cleanup complete"
}

trap cleanup EXIT INT TERM

################################################################################
# Step 1: Setup
################################################################################

run_setup() {
    log_step "STEP 1/4: SETUP & TOKEN EXTRACTION"
    
    if [ "$SKIP_DEPLOY" = true ]; then
        log_warning "Skipping setup (--skip-deploy flag)"
        return 0
    fi
    
    # Check if already set up
    if [ -f ".venv/bin/activate" ] && [ -f ".qwen_bearer_token" ]; then
        TOKEN_AGE=$(($(date +%s) - $(stat -c %Y .qwen_bearer_token 2>/dev/null || stat -f %m .qwen_bearer_token 2>/dev/null || echo 0)))
        
        if [ $TOKEN_AGE -lt 86400 ]; then  # Less than 24 hours old
            log_info "Recent installation detected (token age: $((TOKEN_AGE / 3600))h)"
            log_info "Using existing setup"
            return 0
        else
            log_warning "Token is older than 24 hours, refreshing..."
        fi
    fi
    
    log_info "Running setup script with Playwright token extraction..."
    echo ""
    
    # Check credentials
    if [ -z "${QWEN_EMAIL:-}" ] || [ -z "${QWEN_PASSWORD:-}" ]; then
        log_error "Missing credentials!"
        echo ""
        echo -e "${YELLOW}Please set your credentials:${NC}"
        echo -e "  ${CYAN}export QWEN_EMAIL=your-email@example.com${NC}"
        echo -e "  ${CYAN}export QWEN_PASSWORD='your-password'${NC}"
        echo ""
        exit 1
    fi
    
    bash "${SCRIPT_DIR}/setup.sh"
    
    if [ $? -eq 0 ]; then
        log_success "Setup completed successfully"
    else
        log_error "Setup failed"
        exit 1
    fi
}

################################################################################
# Step 2: Start Server
################################################################################

start_server() {
    log_step "STEP 2/4: START SERVER"
    
    log_info "Starting server in background..."
    log_info "Port: $PORT"
    log_info "Provider: $PROVIDER_MODE"
    echo ""
    
    # Start server in background
    bash "${SCRIPT_DIR}/start.sh" --port "$PORT" --provider "$PROVIDER_MODE" --background
    
    if [ $? -eq 0 ]; then
        # Get server PID
        if [ -f ".server.pid" ]; then
            SERVER_PID=$(cat .server.pid)
            log_success "Server started (PID: $SERVER_PID)"
        else
            log_error "Server PID file not found"
            exit 1
        fi
        
        # Wait for server to be ready
        log_info "Waiting for server to initialize..."
        
        local max_attempts=30
        local attempt=0
        local server_ready=false
        
        while [ $attempt -lt $max_attempts ]; do
            if curl -s -f "http://localhost:${PORT}/health" > /dev/null 2>&1; then
                server_ready=true
                break
            fi
            
            sleep 1
            ((attempt++))
            echo -n "."
        done
        
        echo ""
        
        if [ "$server_ready" = true ]; then
            log_success "Server is ready!"
            
            # Display server info
            echo ""
            log_info "Server Information:"
            echo -e "  ${CYAN}URL:${NC} ${YELLOW}http://localhost:${PORT}${NC}"
            echo -e "  ${CYAN}Health:${NC} ${YELLOW}http://localhost:${PORT}/health${NC}"
            echo -e "  ${CYAN}Docs:${NC} ${YELLOW}http://localhost:${PORT}/docs${NC}"
            echo -e "  ${CYAN}PID:${NC} ${YELLOW}${SERVER_PID}${NC}"
            echo -e "  ${CYAN}Logs:${NC} ${YELLOW}tail -f logs/server.log${NC}"
            
        else
            log_error "Server failed to start within 30 seconds"
            log_info "Check logs: cat logs/server.log"
            exit 1
        fi
        
    else
        log_error "Failed to start server"
        exit 1
    fi
}

################################################################################
# Step 3: Test API
################################################################################

test_api() {
    log_step "STEP 3/4: TEST API"
    
    if [ "$NO_TEST" = true ]; then
        log_warning "Skipping tests (--no-test flag)"
        return 0
    fi
    
    log_info "Running OpenAI API test..."
    log_info "Asking: 'What is GRAPH-RAG?'"
    echo ""
    
    # Run test with send_request.sh
    bash "${SCRIPT_DIR}/send_request.sh" --port "$PORT"
    
    if [ $? -eq 0 ]; then
        log_success "API test passed!"
    else
        log_error "API test failed"
        return 1
    fi
}

################################################################################
# Step 4: Run Continuous Test
################################################################################

run_continuous_test() {
    log_step "STEP 4/4: CONTINUOUS TESTING"
    
    log_info "Running continuous tests (Press Ctrl+C to stop)..."
    echo ""
    
    local test_count=0
    local success_count=0
    local failure_count=0
    
    while true; do
        ((test_count++))
        
        echo ""
        echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}${BOLD}  Test #${test_count} - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════${NC}"
        echo ""
        
        # Send test request
        if bash "${SCRIPT_DIR}/send_openai_request.sh" --port "$PORT" > /tmp/test_output.txt 2>&1; then
            ((success_count++))
            log_success "Test passed (Success: $success_count, Failed: $failure_count)"
            
            # Display response
            cat /tmp/test_output.txt | tail -20
        else
            ((failure_count++))
            log_error "Test failed (Success: $success_count, Failed: $failure_count)"
            cat /tmp/test_output.txt | tail -20
        fi
        
        # Show stats
        echo ""
        echo -e "${CYAN}Statistics:${NC}"
        echo -e "  Total Tests: $test_count"
        echo -e "  Success Rate: $(awk "BEGIN {printf \"%.1f\", ($success_count/$test_count)*100}")%"
        
        # Wait before next test
        log_info "Waiting 30 seconds before next test..."
        sleep 30
    done
}

################################################################################
# Summary Display
################################################################################

display_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║           ✅ DEPLOYMENT SUCCESSFUL!                   ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}Server Information:${NC}"
    echo -e "  🌐 URL: ${YELLOW}http://localhost:${PORT}${NC}"
    echo -e "  🏥 Health: ${YELLOW}http://localhost:${PORT}/health${NC}"
    echo -e "  📚 Docs: ${YELLOW}http://localhost:${PORT}/docs${NC}"
    echo -e "  🔧 Provider: ${YELLOW}${PROVIDER_MODE}${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}Useful Commands:${NC}"
    echo -e "  View logs: ${YELLOW}tail -f logs/server.log${NC}"
    echo -e "  Stop server: ${YELLOW}kill \$(cat .server.pid)${NC}"
    echo -e "  Test API: ${YELLOW}bash scripts/send_openai_request.sh${NC}"
    echo -e "  Restart: ${YELLOW}bash scripts/all.sh${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}Example API Call:${NC}"
    cat << 'EOF'
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-max-latest",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
EOF
    echo ""
}

################################################################################
# Interactive Mode
################################################################################

interactive_mode() {
    log_step "INTERACTIVE OPTIONS"
    
    echo -e "${CYAN}What would you like to do?${NC}"
    echo ""
    echo "  1) Run continuous tests (every 30s)"
    echo "  2) Keep server running (manual testing)"
    echo "  3) Test all models"
    echo "  4) Exit and stop server"
    echo ""
    
    read -p "Choose option [1-4]: " -n 1 -r
    echo ""
    echo ""
    
    case $REPLY in
        1)
            run_continuous_test
            ;;
        2)
            log_info "Server is running in background"
            log_info "Press Ctrl+C to stop..."
            while true; do
                sleep 10
            done
            ;;
        3)
            bash "${SCRIPT_DIR}/send_openai_request.sh" --port "$PORT" --all-models
            interactive_mode
            ;;
        4)
            log_info "Stopping server..."
            exit 0
            ;;
        *)
            log_warning "Invalid option"
            interactive_mode
            ;;
    esac
}

################################################################################
# Main Flow
################################################################################

main() {
    print_banner
    
    parse_arguments "$@"
    
    # Show configuration
    log_info "Configuration:"
    echo -e "  Port: ${YELLOW}${PORT}${NC}"
    echo -e "  Provider: ${YELLOW}${PROVIDER_MODE}${NC}"
    echo -e "  Skip Setup: ${YELLOW}${SKIP_DEPLOY}${NC}"
    echo -e "  Skip Tests: ${YELLOW}${NO_TEST}${NC}"
    
    # Run workflow
    run_setup        # Step 1: Setup + Playwright token extraction
    start_server     # Step 2: Start server
    test_api         # Step 3: Test API with "What is GRAPH-RAG?"
    display_summary  # Step 4: Show summary
    
    # Interactive mode
    interactive_mode
}

# Run main
main "$@"
