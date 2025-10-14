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
        if [[ -f "logs/server.log" ]]; then
            echo -e "\n${YELLOW}Last 20 lines of server log:${NC}"
            echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
            tail -20 logs/server.log
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
}

################################################################################
# Process Management
################################################################################

kill_all_existing_servers() {
    local port
    
    # Load port from env if available
    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck source=/dev/null
        set -a
        source "$ENV_FILE"
        set +a
    fi
    
    port="${LISTEN_PORT:-8096}"
    
    # Kill by PID file
    if [[ -f "$PID_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$PID_FILE")
        
        if ps -p "$old_pid" > /dev/null 2>&1; then
            log_warning "Killing existing server from PID file (PID: $old_pid)"
            kill -9 "$old_pid" 2>/dev/null || true
            sleep 2
        fi
        
        rm -f "$PID_FILE"
    fi
    
    # Kill by port (may be multiple processes)
    if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "Port $port is in use, killing all processes..."
        
        local pids
        pids=$(lsof -ti:"$port" 2>/dev/null || true)
        
        if [[ -n "$pids" ]]; then
            echo "$pids" | while read -r pid; do
                if [[ -n "$pid" ]]; then
                    log_info "Killing process $pid"
                    kill -9 "$pid" 2>/dev/null || true
                fi
            done
            
            sleep 3
            
            # Final verification
            if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
                log_error "Failed to free port $port"
                log_warning "Please manually kill processes: sudo lsof -ti:$port | xargs kill -9"
                exit 1
            fi
            
            log_success "All processes killed, port $port is now free"
        fi
    fi
}

################################################################################
# Deployment Steps
################################################################################

run_setup() {
    print_step_header "1" "Running Setup"
    
    check_script_exists "setup.sh"
    bash "${SCRIPT_DIR}/setup.sh"
    
    log_success "Setup completed successfully!"
    echo ""
    sleep 2
}

run_server_start() {
    print_step_header "2" "Starting Server"
    
    # Clean up any existing servers first
    kill_all_existing_servers
    
    check_script_exists "start.sh"
    bash "${SCRIPT_DIR}/start.sh"
    
    log_success "Server started successfully!"
    echo ""
    sleep 3
}

run_tests() {
    print_step_header "3" "Running Tests"
    
    check_script_exists "send_request.sh"
    
    local test_result=0
    bash "${SCRIPT_DIR}/send_request.sh" || test_result=$?
    
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
    
    echo -e "${CYAN}Server Information:${NC}"
    echo -e "  ${BLUE}URL:${NC} http://localhost:$port"
    echo -e "  ${BLUE}Health:${NC} http://localhost:$port/health"
    echo -e "  ${BLUE}Models:${NC} http://localhost:$port/v1/models"
    
    if [[ -f "$PID_FILE" ]]; then
        echo -e "  ${BLUE}PID:${NC} $(cat "$PID_FILE")"
    fi
    echo ""
}

print_useful_commands() {
    echo -e "${CYAN}Useful Commands:${NC}"
    echo -e "  ${YELLOW}View logs:${NC} tail -f logs/server.log"
    echo -e "  ${YELLOW}Stop server:${NC} kill \$(cat server.pid)"
    echo -e "  ${YELLOW}Run tests again:${NC} bash scripts/send_request.sh"
    echo ""
}

print_api_examples() {
    local port="${LISTEN_PORT:-8096}"
    
    echo -e "${CYAN}Example API Call (OpenAI Compatible):${NC}"
    echo -e "${BLUE}python3 << 'PYEOF'
import openai

client = openai.OpenAI(
    base_url=\"http://localhost:$port/v1\",
    api_key=\"sk-test\"
)

response = client.chat.completions.create(
    model=\"qwen-max-latest\",
    messages=[{\"role\": \"user\", \"content\": \"Hello!\"}],
    stream=False
)

print(response.choices[0].message.content)
PYEOF${NC}"
    echo ""
    
    echo -e "${CYAN}Or using curl:${NC}"
    echo -e "${BLUE}curl -X POST http://localhost:$port/v1/chat/completions \\\\
  -H 'Content-Type: application/json' \\\\
  -H 'Authorization: Bearer sk-test' \\\\
  -d '{
    \"model\": \"qwen-turbo\",
    \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}],
    \"stream\": false
  }'${NC}"
    echo ""
}

watch_logs() {
    echo -e "${CYAN}${BOLD}Server is running in background...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop watching logs (server will keep running)${NC}"
    echo -e "${YELLOW}To stop server: kill \$(cat server.pid)${NC}\n"
    
    echo -e "${CYAN}${BOLD}Streaming logs (Ctrl+C to exit):${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}\n"
    
    # Trap Ctrl+C gracefully
    trap 'echo -e "\n${YELLOW}Stopped watching logs. Server still running.${NC}\n"; exit 0' INT
    
    tail -f logs/server.log
}

handle_test_failure() {
    echo -e "${YELLOW}${BOLD}⚠ Some tests failed. Check the logs for details.${NC}"
    echo -e "${BLUE}Logs location:${NC} logs/server.log\n"
    
    echo -e "${CYAN}Server is still running. You can:${NC}"
    echo -e "  ${YELLOW}→${NC} Check logs: tail -f logs/server.log"
    echo -e "  ${YELLOW}→${NC} Run tests: bash scripts/send_request.sh"
    echo -e "  ${YELLOW}→${NC} Stop server: kill \$(cat server.pid)"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header
    check_project_root
    
    # Step 1: Setup
    run_setup
    
    # Step 2: Start Server
    run_server_start
    
    # Step 3: Run Tests
    local test_result=0
    run_tests || test_result=$?
    
    # Display Results
    print_footer
    load_config
    print_server_info
    print_useful_commands
    print_api_examples
    
    # Handle results
    if [[ $test_result -eq 0 ]]; then
        log_success "All systems operational! Your Qwen API is ready to use."
        echo ""
        watch_logs
    else
        handle_test_failure
        exit 1
    fi
}

main "$@"
