#!/usr/bin/env bash
################################################################################
# start.sh - Qwen API Server Starter
#
# This script:
# - Validates environment configuration
# - Checks for existing server instances
# - Activates virtual environment
# - Starts FastAPI server
# - Monitors server health
# - Provides management information
################################################################################

set -euo pipefail

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Project paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly VENV_DIR="${PROJECT_ROOT}/.venv"
readonly ENV_FILE="${PROJECT_ROOT}/.env"
readonly PID_FILE="${PROJECT_ROOT}/server.pid"
readonly LOG_DIR="${PROJECT_ROOT}/logs"
readonly LOG_FILE="${LOG_DIR}/server.log"

# Configuration
readonly MAX_START_ATTEMPTS=30
readonly HEALTH_CHECK_INTERVAL=1
readonly DEFAULT_PORT=8096
readonly DEFAULT_HOST="0.0.0.0"

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
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}           Starting Qwen API Server                    ${NC}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"
}

print_footer() {
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}            Server Running Successfully! ✓             ${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════${NC}\n"
}

cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Server startup failed with exit code $exit_code"
        if [[ -f "$PID_FILE" ]]; then
            local pid
            pid=$(cat "$PID_FILE")
            kill "$pid" 2>/dev/null || true
            rm -f "$PID_FILE"
        fi
    fi
}

trap cleanup_on_exit EXIT

################################################################################
# Validation Functions
################################################################################

check_env_file() {
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error ".env file not found!"
        log_warning "Run 'bash scripts/setup.sh' first"
        echo ""
        exit 1
    fi
}

load_env() {
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
}

validate_token() {
    if [[ -z "${QWEN_BEARER_TOKEN:-}" ]]; then
        if [[ -z "${QWEN_EMAIL:-}" ]] || [[ -z "${QWEN_PASSWORD:-}" ]]; then
            log_error "No Bearer token and no credentials found!"
            log_warning "Please set QWEN_BEARER_TOKEN or QWEN_EMAIL/QWEN_PASSWORD in .env"
            echo ""
            exit 1
        fi
        log_warning "No Bearer token - will use Playwright authentication"
    else
        log_success "Bearer token configured (${#QWEN_BEARER_TOKEN} chars)"
    fi
}

check_venv() {
    if [[ ! -d "$VENV_DIR" ]]; then
        log_error "Virtual environment not found!"
        log_warning "Run 'bash scripts/setup.sh' first"
        echo ""
        exit 1
    fi
}

################################################################################
# Port Management
################################################################################

get_port() {
    echo "${LISTEN_PORT:-$DEFAULT_PORT}"
}

get_host() {
    echo "${HOST:-$DEFAULT_HOST}"
}

check_port() {
    local port=$1
    
    if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

kill_port() {
    local port=$1
    
    if check_port "$port"; then
        log_warning "Port $port is already in use"
        local old_pid
        old_pid=$(lsof -ti:"$port")
        log_warning "Killing process $old_pid..."
        kill -9 "$old_pid" 2>/dev/null || true
        sleep 2
        
        # Verify port is free
        if check_port "$port"; then
            log_error "Failed to free port $port"
            exit 1
        fi
        log_success "Port $port freed"
    fi
}

################################################################################
# Server Management
################################################################################

create_log_directory() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR"
    fi
}

activate_venv() {
    # shellcheck source=/dev/null
    source "$VENV_DIR/bin/activate"
}

start_server_process() {
    local port=$1
    local host=$2
    
    log_info "Starting server on ${BOLD}http://${host}:${port}${NC}"
    log_info "Logs: ${BOLD}${LOG_FILE}${NC}"
    echo ""
    
    # Start server with nohup
    nohup python3 main.py --port "$port" --host "$host" > "$LOG_FILE" 2>&1 &
    local server_pid=$!
    
    # Save PID
    echo "$server_pid" > "$PID_FILE"
    
    echo "$server_pid"
}

wait_for_health() {
    local port=$1
    local pid=$2
    
    log_info "Waiting for server to start..."
    
    local attempt=0
    while [[ $attempt -lt $MAX_START_ATTEMPTS ]]; do
        # Check if process is still running
        if ! ps -p "$pid" > /dev/null 2>&1; then
            log_error "Server process died unexpectedly!"
            log_warning "Check logs: tail -f $LOG_FILE"
            echo ""
            return 1
        fi
        
        # Check health endpoint
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            log_success "Server is ready!"
            echo ""
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -ne "${YELLOW}⏳ Starting... ($attempt/$MAX_START_ATTEMPTS)\r${NC}"
        sleep $HEALTH_CHECK_INTERVAL
    done
    
    log_error "Server startup timeout!"
    log_warning "Check logs: tail -f $LOG_FILE"
    echo ""
    return 1
}

test_health_endpoint() {
    local port=$1
    
    log_info "Testing health endpoint..."
    local health_response
    health_response=$(curl -s "http://localhost:$port/health" || echo "Failed to connect")
    echo -e "${GREEN}Response:${NC} $health_response"
    echo ""
}

################################################################################
# Information Display
################################################################################

print_server_info() {
    local port=$1
    local pid=$2
    
    echo -e "${CYAN}Server Information:${NC}"
    echo -e "  ${BLUE}URL:${NC} http://localhost:$port"
    echo -e "  ${BLUE}Health:${NC} http://localhost:$port/health"
    echo -e "  ${BLUE}Models:${NC} http://localhost:$port/v1/models"
    echo -e "  ${BLUE}PID:${NC} $pid (saved to server.pid)"
    echo -e "  ${BLUE}Logs:${NC} $LOG_FILE"
    echo ""
}

print_management_commands() {
    echo -e "${CYAN}Management Commands:${NC}"
    echo -e "  ${YELLOW}View logs:${NC} tail -f $LOG_FILE"
    echo -e "  ${YELLOW}Stop server:${NC} kill \$(cat server.pid)"
    echo -e "  ${YELLOW}Restart:${NC} bash scripts/start.sh"
    echo ""
}

print_test_commands() {
    echo -e "${CYAN}Test the API:${NC}"
    echo -e "  ${YELLOW}→${NC} Run ${BOLD}bash scripts/send_request.sh${NC} to test all endpoints"
    echo -e "  ${YELLOW}→${NC} Or use ${BOLD}curl http://localhost:$1/health${NC}"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header
    
    # Validation
    check_env_file
    load_env
    validate_token
    check_venv
    
    # Configuration
    local port host
    port=$(get_port)
    host=$(get_host)
    
    # Port management
    kill_port "$port"
    
    # Setup
    create_log_directory
    activate_venv
    
    # Start server
    local server_pid
    server_pid=$(start_server_process "$port" "$host")
    
    # Wait for startup
    if ! wait_for_health "$port" "$server_pid"; then
        exit 1
    fi
    
    # Success
    print_footer
    print_server_info "$port" "$server_pid"
    print_management_commands
    print_test_commands "$port"
    
    # Test health endpoint
    test_health_endpoint "$port"
}

main "$@"
