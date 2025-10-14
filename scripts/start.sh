#!/usr/bin/env bash
################################################################################
# start.sh - Start Qwen API Server
#
# This script starts the FastAPI server with proper configuration.
# It validates the environment, checks authentication, and launches the server.
#
# Usage:
#   bash scripts/start.sh [--port PORT] [--provider MODE]
#
# Options:
#   --port PORT        Server port (default: 8096)
#   --provider MODE    Provider mode: direct, proxy, auto (default: auto)
#   --background       Run server in background
#   --test             Test mode (don't actually start server)
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
readonly ENV_FILE="${PROJECT_ROOT}/.env"
readonly TOKEN_FILE="${PROJECT_ROOT}/.qwen_bearer_token"
readonly PID_FILE="${PROJECT_ROOT}/.server.pid"

# Default configuration
PORT=8096
PROVIDER_MODE="auto"
BACKGROUND_MODE=false
TEST_MODE=false

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
    echo -e "${MAGENTA}${BOLD}$1${NC}"
    echo -e "${MAGENTA}${BOLD}$(printf '=%.0s' {1..60})${NC}"
}

print_header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║         Qwen API - Server Startup Script            ║"
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
            --provider)
                PROVIDER_MODE="$2"
                shift 2
                ;;
            --background)
                BACKGROUND_MODE=true
                shift
                ;;
            --test)
                TEST_MODE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Usage: $0 [--port PORT] [--provider MODE] [--background] [--test]"
                exit 1
                ;;
        esac
    done
}

################################################################################
# Environment Validation
################################################################################

validate_environment() {
    log_step "Validating environment..."
    
    # Check if virtual environment exists
    if [ ! -d ".venv" ]; then
        log_error "Virtual environment not found!"
        log_info "Please run: bash scripts/deploy.sh"
        exit 1
    fi
    
    # Activate virtual environment
    source .venv/bin/activate
    
    # Load environment variables
    if [ -f "$ENV_FILE" ]; then
        set -a
        source "$ENV_FILE"
        set +a
        log_success "Environment variables loaded"
    else
        log_warning ".env file not found - using defaults"
    fi
    
    # Check for required packages
    if ! python -c "import fastapi" 2>/dev/null; then
        log_error "FastAPI not installed!"
        log_info "Please run: bash scripts/deploy.sh"
        exit 1
    fi
    
    log_success "Environment validated"
}

################################################################################
# Authentication Check
################################################################################

check_authentication() {
    log_step "Checking authentication..."
    
    # Check for bearer token
    if [ -f "$TOKEN_FILE" ]; then
        TOKEN_LENGTH=$(wc -c < "$TOKEN_FILE" | tr -d ' ')
        log_success "Bearer token found (${TOKEN_LENGTH} chars)"
        
        # Set token in environment
        export QWEN_BEARER_TOKEN=$(cat "$TOKEN_FILE")
        
    elif [ -n "${QWEN_BEARER_TOKEN:-}" ]; then
        log_success "Bearer token found in environment"
        
    elif [ -n "${QWEN_EMAIL:-}" ] && [ -n "${QWEN_PASSWORD:-}" ]; then
        log_warning "No bearer token - will use Playwright authentication"
        log_info "Email: ${QWEN_EMAIL}"
        
    else
        log_error "No authentication method found!"
        echo ""
        log_info "Please either:"
        log_info "  1. Run deploy.sh to extract token: bash scripts/deploy.sh"
        log_info "  2. Set QWEN_BEARER_TOKEN environment variable"
        log_info "  3. Set QWEN_EMAIL and QWEN_PASSWORD"
        echo ""
        exit 1
    fi
}

################################################################################
# Provider Configuration
################################################################################

configure_provider() {
    log_step "Configuring provider..."
    
    # Set provider mode
    export QWEN_PROVIDER_MODE="$PROVIDER_MODE"
    
    case "$PROVIDER_MODE" in
        direct)
            log_info "Provider Mode: Direct (Browser Mimicry)"
            log_info "  ✓ Uses QwenProvider"
            log_info "  ✓ Direct Qwen API access"
            log_info "  ✓ Full browser simulation"
            ;;
        proxy)
            log_info "Provider Mode: Proxy (qwen.aikit.club)"
            log_info "  ✓ Uses QwenProxyProvider"
            log_info "  ✓ Fast proxy API"
            log_info "  ✓ Simple HTTP requests"
            ;;
        auto)
            log_info "Provider Mode: Auto (Intelligent Fallback)"
            log_info "  ✓ Tries proxy first"
            log_info "  ✓ Falls back to direct if needed"
            log_info "  ✓ Best of both worlds"
            ;;
        *)
            log_error "Invalid provider mode: $PROVIDER_MODE"
            log_info "Valid modes: direct, proxy, auto"
            exit 1
            ;;
    esac
    
    log_success "Provider configured: $PROVIDER_MODE"
}

################################################################################
# Port Check
################################################################################

check_port() {
    log_step "Checking port availability..."
    
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        log_warning "Port $PORT is already in use"
        
        # Check if it's our server
        if [ -f "$PID_FILE" ]; then
            OLD_PID=$(cat "$PID_FILE")
            if ps -p "$OLD_PID" > /dev/null 2>&1; then
                log_info "Found existing server (PID: $OLD_PID)"
                read -p "Kill existing server and restart? [y/N] " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log_info "Stopping existing server..."
                    kill "$OLD_PID"
                    sleep 2
                    log_success "Existing server stopped"
                else
                    log_info "Keeping existing server running"
                    exit 0
                fi
            fi
        fi
        
        log_error "Port conflict - unable to start server"
        log_info "Please either:"
        log_info "  1. Stop the process using port $PORT"
        log_info "  2. Use a different port: --port 8097"
        exit 1
    fi
    
    log_success "Port $PORT is available"
}

################################################################################
# Health Check
################################################################################

perform_health_check() {
    log_step "Performing health check..."
    
    # Quick Python import check
    log_info "Testing imports..."
    
    python << 'PYTHON_CHECK'
import sys
try:
    from app.providers.provider_factory import ProviderFactory
    from app.core.config import settings
    print("✓ All imports successful")
except ImportError as e:
    print(f"✗ Import error: {e}")
    sys.exit(1)
PYTHON_CHECK

    if [ $? -eq 0 ]; then
        log_success "Health check passed"
    else
        log_error "Health check failed"
        exit 1
    fi
}

################################################################################
# Server Startup
################################################################################

start_server() {
    log_step "Starting server..."
    
    # Set environment variables
    export LISTEN_PORT=$PORT
    export HOST=0.0.0.0
    
    log_info "Server Configuration:"
    log_info "  Port: $PORT"
    log_info "  Host: 0.0.0.0"
    log_info "  Provider: $PROVIDER_MODE"
    log_info "  Anonymous Mode: ${ANONYMOUS_MODE:-true}"
    log_info "  Debug Logging: ${DEBUG_LOGGING:-true}"
    echo ""
    
    if [ "$TEST_MODE" = true ]; then
        log_warning "Test mode - not actually starting server"
        return 0
    fi
    
    # Start server
    if [ "$BACKGROUND_MODE" = true ]; then
        log_info "Starting server in background..."
        
        nohup python main.py > logs/server.log 2>&1 &
        SERVER_PID=$!
        
        # Save PID
        echo $SERVER_PID > "$PID_FILE"
        
        # Wait for server to start
        log_info "Waiting for server to initialize..."
        sleep 5
        
        # Check if server is running
        if ps -p $SERVER_PID > /dev/null 2>&1; then
            log_success "Server started successfully (PID: $SERVER_PID)"
            log_info "Logs: tail -f logs/server.log"
        else
            log_error "Server failed to start"
            log_info "Check logs: cat logs/server.log"
            exit 1
        fi
        
    else
        log_success "Starting server (Press Ctrl+C to stop)..."
        echo ""
        echo -e "${CYAN}Server URL:${NC} ${YELLOW}http://localhost:${PORT}${NC}"
        echo -e "${CYAN}Health Check:${NC} ${YELLOW}http://localhost:${PORT}/health${NC}"
        echo -e "${CYAN}OpenAI Endpoint:${NC} ${YELLOW}http://localhost:${PORT}/v1/chat/completions${NC}"
        echo ""
        
        # Start server in foreground
        python main.py
    fi
}

################################################################################
# Cleanup
################################################################################

cleanup() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            log_info "Stopping server (PID: $PID)..."
            kill "$PID"
            rm "$PID_FILE"
        fi
    fi
}

trap cleanup EXIT INT TERM

################################################################################
# Main Flow
################################################################################

main() {
    print_header
    
    parse_arguments "$@"
    validate_environment
    check_authentication
    configure_provider
    check_port
    perform_health_check
    start_server
    
    if [ "$BACKGROUND_MODE" = true ]; then
        echo ""
        echo -e "${GREEN}${BOLD}✅ Server is running!${NC}"
        echo ""
        echo -e "${CYAN}Server URL:${NC} ${YELLOW}http://localhost:${PORT}${NC}"
        echo -e "${CYAN}PID File:${NC} ${YELLOW}${PID_FILE}${NC}"
        echo -e "${CYAN}Stop Server:${NC} ${YELLOW}kill \$(cat ${PID_FILE})${NC}"
        echo ""
    fi
}

# Run main
main "$@"

