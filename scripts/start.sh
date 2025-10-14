#!/usr/bin/env bash
################################################################################
# start.sh - Qwen API Server Startup Script
# Features:
# - Environment validation
# - Port conflict resolution
# - Graceful startup with health checks
# - PID management for clean shutdown
# - Comprehensive logging
# - Auto-restart on failure (optional)
################################################################################

set -e

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Default configuration
DEFAULT_PORT=8096
DEFAULT_HOST="0.0.0.0"
MAX_STARTUP_ATTEMPTS=30
STARTUP_WAIT_SECONDS=2
HEALTH_CHECK_TIMEOUT=5

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${MAGENTA}[STEP $1]${NC} $2"; }

# Header
print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                   QWEN API SERVER - STARTUP MANAGER"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Footer
print_footer() {
    echo -e "${GREEN}${BOLD}"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                     SERVER IS RUNNING SUCCESSFULLY! ✓"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Check if server is already running
check_existing_server() {
    log_step "1/7" "Checking for existing server instances..."
    
    local port=${1:-$DEFAULT_PORT}
    
    # Check by PID file
    if [ -f "server.pid" ]; then
        local pid=$(cat server.pid)
        if ps -p "$pid" > /dev/null 2>&1; then
            log_warning "Server already running with PID: $pid"
            echo -e "${YELLOW}Would you like to stop it and start a new instance? (y/N):${NC}"
            read -r response
            if [[ $response =~ ^[Yy]$ ]]; then
                kill "$pid" 2>/dev/null || true
                sleep 2
                rm -f server.pid
                log_success "Stopped existing server"
            else
                log_info "Keeping existing server running"
                exit 0
            fi
        else
            rm -f server.pid
            log_warning "Removed stale PID file"
        fi
    fi
    
    # Check by port
    if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
        local port_pid=$(lsof -ti ":$port")
        log_warning "Port $port is in use by process: $port_pid"
        echo -e "${YELLOW}Would you like to kill the process and free the port? (y/N):${NC}"
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
    
    log_success "No conflicting server instances found"
}

# Validate environment setup
validate_environment() {
    log_step "2/7" "Validating environment setup..."
    
    # Check virtual environment
    if [ ! -d ".venv" ]; then
        log_error "Virtual environment not found!"
        echo -e "${YELLOW}Run 'bash scripts/setup.sh' first${NC}"
        exit 1
    fi
    
    # Check .env file
    if [ ! -f ".env" ]; then
        log_error ".env file not found!"
        echo -e "${YELLOW}Run 'bash scripts/setup.sh' first${NC}"
        exit 1
    fi
    
    # Load environment variables
    set -a
    source .env
    set +a
    
    # Validate Bearer token
    if [ -z "$QWEN_BEARER_TOKEN" ] || [ "$QWEN_BEARER_TOKEN" = "your-bearer-token-here" ]; then
        log_error "Bearer token not configured!"
        echo -e "${YELLOW}Run 'bash scripts/setup.sh' to configure your token${NC}"
        exit 1
    fi
    
    log_success "Environment validation passed"
    log_info "Bearer token: ${#QWEN_BEARER_TOKEN} characters"
}

# Parse command line arguments
parse_arguments() {
    local port=$DEFAULT_PORT
    local host=$DEFAULT_HOST
    local debug_mode=false
    local auto_restart=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--port)
                port="$2"
                shift 2
                ;;
            -h|--host)
                host="$2"
                shift 2
                ;;
            -d|--debug)
                debug_mode=true
                shift
                ;;
            -r|--restart)
                auto_restart=true
                shift
                ;;
            *)
                log_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    echo "$port $host $debug_mode $auto_restart"
}

# Setup logging directory
setup_logging() {
    log_step "3/7" "Setting up logging..."
    
    # Create logs directory
    mkdir -p logs
    
    # Create log file with timestamp
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="logs/server_${timestamp}.log"
    
    # Create symlink to latest log
    ln -sf "$log_file" logs/server.log
    
    echo "$log_file"
}

# Activate virtual environment
activate_environment() {
    log_step "4/7" "Activating Python environment..."
    
    source .venv/bin/activate
    
    # Verify Python environment (check for core packages)
    if ! python3 -c "import fastapi, httpx, pydantic" 2>/dev/null; then
        log_error "Required Python packages not found!"
        echo -e "${YELLOW}Run 'bash scripts/setup.sh' to install dependencies${NC}"
        exit 1
    fi
    
    log_success "Python environment activated"
}

# Start server process
start_server_process() {
    local port="$1"
    local host="$2"
    local debug_mode="$3"
    local log_file="$4"
    
    log_step "5/7" "Starting server process..."
    
    log_info "Starting server on: http://${host}:${port}"
    log_info "Log file: $log_file"
    
    # Build command
    local cmd="python3 main.py --port $port --host $host"
    
    if [ "$debug_mode" = "true" ]; then
        cmd="$cmd --debug"
        log_info "Debug mode enabled"
    fi
    
    # Start server with nohup
    nohup $cmd > "$log_file" 2>&1 &
    local server_pid=$!
    
    # Save PID
    echo $server_pid > server.pid
    
    log_success "Server started with PID: $server_pid"
    echo $server_pid
}

# Wait for server to be ready
wait_for_server_ready() {
    local port="$1"
    local host="$2"
    local pid="$3"
    
    log_step "6/7" "Waiting for server to be ready..."
    
    local attempt=1
    local max_attempts=$MAX_STARTUP_ATTEMPTS
    
    while [ $attempt -le $max_attempts ]; do
        # Check if process is still running
        if ! ps -p "$pid" > /dev/null 2>&1; then
            log_error "Server process died unexpectedly!"
            log_info "Check logs: tail -f logs/server.log"
            exit 1
        fi
        
        # Check health endpoint
        if curl -s -f -m $HEALTH_CHECK_TIMEOUT "http://${host}:${port}/health" > /dev/null 2>&1; then
            log_success "Server is ready and responding!"
            return 0
        fi
        
        # Check models endpoint as fallback
        if curl -s -f -m $HEALTH_CHECK_TIMEOUT "http://${host}:${port}/v1/models" > /dev/null 2>&1; then
            log_success "Server is ready (models endpoint responding)!"
            return 0
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "Server startup timeout after ${max_attempts} attempts"
            log_info "Last logs:"
            tail -20 logs/server.log
            exit 1
        fi
        
        echo -ne "${YELLOW}⏳ Waiting for server... (${attempt}/${max_attempts})\r${NC}"
        sleep $STARTUP_WAIT_SECONDS
        attempt=$((attempt + 1))
    done
}

# Verify server functionality
verify_server_functionality() {
    local port="$1"
    local host="$2"
    
    log_step "7/7" "Verifying server functionality..."
    
    # Test health endpoint
    log_info "Testing health endpoint..."
    local health_response
    health_response=$(curl -s -f "http://${host}:${port}/health" || echo "ERROR")
    
    if [ "$health_response" != "ERROR" ]; then
        log_success "Health endpoint: $health_response"
    else
        log_warning "Health endpoint not responding as expected"
    fi
    
    # Test models endpoint
    log_info "Testing models endpoint..."
    if curl -s -f "http://${host}:${port}/v1/models" > /dev/null 2>&1; then
        log_success "Models endpoint responding"
    else
        log_warning "Models endpoint not available"
    fi
    
    # Test chat completion endpoint (basic check)
    log_info "Testing API availability..."
    if curl -s -f -H "Content-Type: application/json" \
         "http://${host}:${port}/v1/chat/completions" > /dev/null 2>&1; then
        log_success "Chat completions endpoint available"
    else
        log_warning "Chat completions endpoint not ready yet"
    fi
    
    log_success "Server verification completed"
}

# Display server information
display_server_info() {
    local port="$1"
    local host="$2"
    local pid="$3"
    
    echo ""
    echo -e "${CYAN}${BOLD}Server Information:${NC}"
    echo -e "  ${WHITE}📍 Local URL:${NC}    http://localhost:${port}"
    echo -e "  ${WHITE}🌐 Network URL:${NC}  http://${host}:${port}"
    echo -e "  ${WHITE}🔧 Process ID:${NC}   $pid"
    echo -e "  ${WHITE}📊 Health Check:${NC} http://localhost:${port}/health"
    echo -e "  ${WHITE}🤖 Models API:${NC}   http://localhost:${port}/v1/models"
    echo -e "  ${WHITE}📝 Log File:${NC}     logs/server.log"
    echo ""
    
    echo -e "${CYAN}${BOLD}Management Commands:${NC}"
    echo -e "  ${GREEN}View logs:${NC}        ${BOLD}tail -f logs/server.log${NC}"
    echo -e "  ${GREEN}Stop server:${NC}      ${BOLD}kill \\\$(cat server.pid)${NC}"
    echo -e "  ${GREEN}Quick test:${NC}       ${BOLD}bash scripts/send_request.sh${NC}"
    echo -e "  ${GREEN}Restart server:${NC}   ${BOLD}bash scripts/start.sh${NC}"
    echo ""
}

# Cleanup function for signal handling
cleanup() {
    log_info "Shutting down server..."
    
    if [ -f "server.pid" ]; then
        local pid=$(cat server.pid)
        if ps -p "$pid" > /dev/null 2>&1; then
            kill "$pid" 2>/dev/null || true
            sleep 2
        fi
        rm -f server.pid
    fi
    
    log_success "Cleanup completed"
    exit 0
}

# Set up signal handlers
setup_signal_handlers() {
    trap cleanup SIGINT SIGTERM EXIT
}

# Main execution
main() {
    print_header
    
    # Parse arguments
    read -r port host debug_mode auto_restart <<< "$(parse_arguments "$@")"
    
    log_info "Configuration: Port=$port, Host=$host, Debug=$debug_mode"
    
    # Execute startup sequence
    check_existing_server "$port"
    validate_environment
    setup_signal_handlers
    local log_file=$(setup_logging)
    activate_environment
    local server_pid=$(start_server_process "$port" "$host" "$debug_mode" "$log_file")
    wait_for_server_ready "$port" "$host" "$server_pid"
    verify_server_functionality "$port" "$host"
    
    print_footer
    display_server_info "$port" "$host" "$server_pid"
    
    # Show initial logs
    echo -e "${CYAN}${BOLD}Initial Server Output:${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
    tail -10 "$log_file"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}Server is running. Press Ctrl+C to stop.${NC}"
    
    # Wait for user interruption or process exit
    wait "$server_pid" 2>/dev/null || true
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
