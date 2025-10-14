#!/usr/bin/env bash
################################################################################
# all.sh - Complete End-to-End Deployment and Testing
#
# This script orchestrates:
# 1. Environment setup (setup.sh)
# 2. Server startup (start.sh)
# 3. Comprehensive testing (send_request.sh)
# 4. Log monitoring
################################################################################

set -euo pipefail

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Project paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly PID_FILE="${PROJECT_ROOT}/server.pid"
readonly ENV_FILE="${PROJECT_ROOT}/.env"
readonly LOGS_DIR="${PROJECT_ROOT}/logs"

cd "$PROJECT_ROOT"

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
}

print_step_header() {
    local step=$1
    local title=$2
    
    echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}${BOLD}STEP $step/3: $title${NC}"
    echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────${NC}\n"
}

print_footer() {
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║            🎉 Deployment Complete! 🎉               ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Deployment failed with exit code $exit_code"
        
        # Show last 20 lines of log if available
        if [[ -f "$LOGS_DIR/server.log" ]]; then
            echo -e "\n${YELLOW}Last 20 lines of server log:${NC}"
            echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
            tail -20 "$LOGS_DIR/server.log"
            echo -e "${CYAN}════════════════════════════════════════════════════${NC}\n"
        fi
    fi
}

trap cleanup_on_exit EXIT

################################################################################
# Validation Functions
################################################################################

check_project_root() {
    if [[ ! -f "main.py" ]]; then
        log_error "main.py not found!"
        log_warning "Please run this script from the project root directory"
        echo ""
        exit 1
    fi
}

check_script_exists() {
    local script_name=$1
    local script_path="${SCRIPT_DIR}/${script_name}"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "$script_name not found at $script_path"
        echo ""
        exit 1
    fi
    
    # Make script executable
    chmod +x "$script_path"
}

check_dependencies() {
    local missing_deps=()
    
    # Check for basic dependencies
    for dep in curl jq; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install them first:"
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
}

################################################################################
# Process Management
################################################################################

kill_existing_server() {
    local port
    
    # Load port from env if available
    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck source=/dev/null
        set -a
        source "$ENV_FILE"
        set +a
    fi
    
    port="${LISTEN_PORT:-8096}"
    
    # Kill by PID file (safe method)
    if [[ -f "$PID_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$PID_FILE")
        
        if ps -p "$old_pid" > /dev/null 2>&1; then
            log_warning "Stopping existing server (PID: $old_pid)"
            kill "$old_pid" 2>/dev/null || true
            sleep 3
            
            # Force kill if still running
            if ps -p "$old_pid" > /dev/null 2>&1; then
                log_warning "Server didn't stop gracefully, forcing..."
                kill -9 "$old_pid" 2>/dev/null || true
                sleep 2
            fi
        fi
        
        rm -f "$PID_FILE"
        log_success "Stopped existing server"
    fi
    
    # Check if port is still in use (could be different process)
    if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
        local port_pid
        port_pid=$(lsof -ti ":$port")
        
        # Only kill if it's our known server process
        if [[ -n "$port_pid" ]]; then
            log_warning "Port $port is still in use by process $port_pid"
            echo -e "${YELLOW}Kill this process? (y/N):${NC}"
            read -r response
            if [[ $response =~ ^[Yy]$ ]]; then
                kill -9 "$port_pid" 2>/dev/null || true
                sleep 2
                log_success "Freed port $port"
            else
                log_error "Cannot start server - port $port is occupied"
                exit 1
            fi
        fi
    fi
}

################################################################################
# Deployment Steps
################################################################################

run_setup() {
    print_step_header "1" "Running Environment Setup"
    
    check_script_exists "setup.sh"
    
    log_info "Starting comprehensive setup..."
    if bash "${SCRIPT_DIR}/setup.sh"; then
        log_success "Setup completed successfully!"
    else
        log_error "Setup failed!"
        exit 1
    fi
    
    echo ""
    sleep 2
}

run_server_start() {
    print_step_header "2" "Starting API Server"
    
    # Clean up any existing servers first
    kill_existing_server
    
    check_script_exists "start.sh"
    
    log_info "Starting server..."
    if bash "${SCRIPT_DIR}/start.sh"; then
        log_success "Server started successfully!"
    else
        log_error "Server startup failed!"
        exit 1
    fi
    
    echo ""
    sleep 3
}

run_tests() {
    print_step_header "3" "Running API Tests"
    
    check_script_exists "send_request.sh"
    
    local test_result=0
    log_info "Executing comprehensive API tests..."
    if bash "${SCRIPT_DIR}/send_request.sh"; then
        log_success "All tests passed!"
    else
        test_result=$?
        if [[ $test_result -eq 0 ]]; then
            log_success "Tests completed"
        else
            log_warning "Some tests failed (exit code: $test_result)"
        fi
    fi
    
    return $test_result
}

################################################################################
# Information Display
################################################################################

load_config() {
    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck source=/dev/null
        set -a
        source "$ENV_FILE"
        set +a
    fi
}

print_server_info() {
    local port="${LISTEN_PORT:-8096}"
    
    echo -e "${CYAN}${BOLD}Server Information:${NC}"
    echo -e "  ${BLUE}📍 Local URL:${NC}    http://localhost:$port"
    echo -e "  ${BLUE}🌐 Health Check:${NC} http://localhost:$port/health"
    echo -e "  ${BLUE}🤖 Models API:${NC}   http://localhost:$port/v1/models"
    echo -e "  ${BLUE}📊 Logs:${NC}         $LOGS_DIR/server.log"
    
    if [[ -f "$PID_FILE" ]]; then
        echo -e "  ${BLUE}🔧 Process ID:${NC}   $(cat "$PID_FILE")"
    fi
    echo ""
}

print_useful_commands() {
    local port="${LISTEN_PORT:-8096}"
    
    echo -e "${CYAN}${BOLD}Useful Commands:${NC}"
    echo -e "  ${YELLOW}📋 View logs:${NC}        ${BOLD}tail -f logs/server.log${NC}"
    echo -e "  ${YELLOW}🛑 Stop server:${NC}      ${BOLD}kill \\\$(cat server.pid)${NC}"
    echo -e "  ${YELLOW}🧪 Run tests:${NC}        ${BOLD}bash scripts/send_request.sh${NC}"
    echo -e "  ${YELLOW}🔁 Restart server:${NC}   ${BOLD}bash scripts/start.sh${NC}"
    echo ""
}

print_api_examples() {
    local port="${LISTEN_PORT:-8096}"
    
    echo -e "${CYAN}${BOLD}Example API Usage:${NC}"
    
    echo -e "${BLUE}Python Example:${NC}"
    cat << 'PYTHON_EOF'
import openai

client = openai.OpenAI(
    base_url="http://localhost:8096/v1",
    api_key="sk-test"  # or use your QWEN_BEARER_TOKEN
)

response = client.chat.completions.create(
    model="qwen-turbo",
    messages=[{"role": "user", "content": "Hello! Explain quantum computing."}],
    stream=False
)

print(response.choices[0].message.content)
PYTHON_EOF

    echo ""
    
    echo -e "${BLUE}cURL Example:${NC}"
    echo "curl -X POST http://localhost:$port/v1/chat/completions \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -H 'Authorization: Bearer sk-test' \\"
    echo "  -d '{
    \"model\": \"qwen-turbo\",
    \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}],
    \"stream\": false
}'"
    echo ""
}

watch_logs() {
    echo -e "${CYAN}${BOLD}Server is running in background...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop watching logs (server will keep running)${NC}"
    echo -e "${YELLOW}To stop server: kill \\\$(cat server.pid)${NC}\n"
    
    echo -e "${CYAN}${BOLD}Streaming logs (Ctrl+C to exit):${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}\n"
    
    # Trap Ctrl+C gracefully
    trap 'echo -e "\n${YELLOW}Stopped watching logs. Server still running.${NC}\n"; exit 0' INT
    
    if [[ -f "$LOGS_DIR/server.log" ]]; then
        tail -f "$LOGS_DIR/server.log"
    else
        log_warning "Log file not found: $LOGS_DIR/server.log"
        echo -e "${YELLOW}Waiting for logs to appear...${NC}"
        sleep 5
        if [[ -f "$LOGS_DIR/server.log" ]]; then
            tail -f "$LOGS_DIR/server.log"
        else
            log_error "Log file still not found after waiting"
        fi
    fi
}

handle_test_failure() {
    echo -e "${YELLOW}${BOLD}⚠ Some tests failed. Check the logs for details.${NC}"
    echo -e "${BLUE}Logs location:${NC} $LOGS_DIR/server.log\n"
    
    echo -e "${CYAN}Server is still running. You can:${NC}"
    echo -e "  ${YELLOW}→${NC} Check logs: tail -f logs/server.log"
    echo -e "  ${YELLOW}→${NC} Run tests manually: bash scripts/send_request.sh"
    echo -e "  ${YELLOW}→${NC} Stop server: kill \\\$(cat server.pid)"
    echo -e "  ${YELLOW}→${NC} Restart: bash scripts/start.sh"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header
    
    # Initial validation
    check_project_root
    check_dependencies
    
    # Create logs directory
    mkdir -p "$LOGS_DIR"
    
    # Step 1: Setup environment
    run_setup
    
    # Step 2: Start server
    run_server_start
    
    # Step 3: Run tests
    local test_result=0
    run_tests || test_result=$?
    
    # Display final information
    print_footer
    load_config
    print_server_info
    print_useful_commands
    print_api_examples
    
    # Handle test results and offer log watching
    if [[ $test_result -eq 0 ]]; then
        log_success "🎉 All systems operational! Your Qwen API is ready to use."
        echo ""
        echo -e "${GREEN}${BOLD}Would you like to watch the server logs? (Y/n):${NC}"
        read -r watch_logs_response
        if [[ ! $watch_logs_response =~ ^[Nn]$ ]]; then
            watch_logs
        else
            echo -e "${CYAN}Server continues running in background. Use commands above to manage it.${NC}"
        fi
    else
        handle_test_failure
        echo -e "${GREEN}${BOLD}Would you like to watch the server logs for debugging? (Y/n):${NC}"
        read -r watch_logs_response
        if [[ ! $watch_logs_response =~ ^[Nn]$ ]]; then
            watch_logs
        fi
        exit 1
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
