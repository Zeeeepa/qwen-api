#!/usr/bin/env bash
#
# all.sh - Run complete workflow
#
# This script runs all steps sequentially:
# 1. Setup: Extract token and save to .env
# 2. Start: Launch API server in background
# 3. Request: Send test request and display response
# 4. Cleanup: Optionally stop server
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_step() { echo -e "${CYAN}[STEP $1]${NC} $2"; }
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

PORT=${PORT:-7050}
SERVER_PID=""

# Cleanup function
cleanup() {
    if [ -n "$SERVER_PID" ]; then
        log_info "Stopping server (PID: $SERVER_PID)..."
        kill $SERVER_PID 2>/dev/null || true
        # Also kill any process on the port
        lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
    fi
}

# Trap EXIT signal
trap cleanup EXIT INT TERM

echo ""
echo "╔════════════════════════════════════════╗"
echo "║   Qwen API Complete Workflow Runner    ║"
echo "╚════════════════════════════════════════╝"
echo ""

#############################################
# STEP 1: Setup
#############################################
log_step "1/3" "Running setup.sh..."
echo "────────────────────────────────────────"

if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
    log_error "QWEN_EMAIL and QWEN_PASSWORD must be set"
    echo ""
    echo "Usage:"
    echo "  export QWEN_EMAIL=your@email.com"
    echo "  export QWEN_PASSWORD=yourpassword"
    echo "  bash all.sh"
    exit 1
fi

bash setup.sh
SETUP_STATUS=$?

if [ $SETUP_STATUS -ne 0 ]; then
    log_error "Setup failed!"
    exit 1
fi

echo ""
log_info "✅ Step 1 complete: Token extracted and saved"
echo ""
sleep 2

#############################################
# STEP 2: Start Server
#############################################
log_step "2/3" "Starting API server..."
echo "────────────────────────────────────────"

# Kill any existing server on port
lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
sleep 1

# Start server in background
bash start.sh > /tmp/qwen_server.log 2>&1 &
SERVER_PID=$!

log_info "Server starting (PID: $SERVER_PID)..."
log_info "Waiting for server to be ready..."

# Wait for server to be ready (max 30 seconds)
MAX_RETRIES=30
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -s "http://localhost:$PORT/" > /dev/null 2>&1; then
        log_info "✅ Server is ready!"
        break
    fi
    RETRY=$((RETRY + 1))
    sleep 1
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    log_error "Server failed to start!"
    echo ""
    echo "Server logs:"
    cat /tmp/qwen_server.log
    exit 1
fi

echo ""
log_info "✅ Step 2 complete: API server running on port $PORT"
echo ""
sleep 2

#############################################
# STEP 3: Send Request
#############################################
log_step "3/3" "Sending test request..."
echo "────────────────────────────────────────"
echo ""

# Send first test request
log_info "Test 1: Simple math question"
bash send_request.sh "qwen-max-latest" "What is 2+2?"
echo ""
sleep 2

# Send second test request
log_info "Test 2: Code help question"
bash send_request.sh "qwen-max-latest" "Can you help me fix my code??"
echo ""

log_info "✅ Step 3 complete: All requests successful"
echo ""

#############################################
# Summary
#############################################
echo ""
echo "╔════════════════════════════════════════╗"
echo "║          Workflow Complete! ✅         ║"
echo "╚════════════════════════════════════════╝"
echo ""
log_info "Summary:"
echo "  1. ✅ Token extracted and saved to .env"
echo "  2. ✅ API server running on http://localhost:$PORT"
echo "  3. ✅ Test requests sent successfully"
echo ""
log_info "Server Details:"
echo "  PID: $SERVER_PID"
echo "  Health: http://localhost:$PORT/"
echo "  Models: http://localhost:$PORT/v1/models"
echo "  Chat:   http://localhost:$PORT/v1/chat/completions"
echo ""

# Ask if user wants to keep server running
echo -n "Keep server running? (y/n) [default: n]: "
read -t 10 KEEP_RUNNING || KEEP_RUNNING="n"

if [ "$KEEP_RUNNING" = "y" ] || [ "$KEEP_RUNNING" = "Y" ]; then
    log_info "Server will keep running (PID: $SERVER_PID)"
    log_info "To stop: kill $SERVER_PID"
    # Don't cleanup
    trap - EXIT INT TERM
    echo ""
    log_info "Press Ctrl+C to stop all processes"
    
    # Wait for user interrupt
    wait $SERVER_PID
else
    log_info "Stopping server..."
fi

log_info "✅ All done!"

