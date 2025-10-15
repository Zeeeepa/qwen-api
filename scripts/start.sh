#!/usr/bin/env bash
#
# start.sh - Start the Qwen OpenAI-compatible API server
#
# This script:
# 1. Loads token from .env
# 2. Validates token expiration
# 3. Validates JSON schemas
# 4. Starts FastAPI server using uvicorn
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PY_API_DIR="$ROOT_DIR/py-api"
VENV_DIR="$ROOT_DIR/venv"

PORT=${PORT:-7050}

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    log_error "Virtual environment not found!"
    echo ""
    echo "Please run first: bash scripts/install.sh"
    exit 1
fi

# Activate virtual environment
log_info "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Load .env
if [ ! -f "$ROOT_DIR/.env" ]; then
    log_error ".env file not found!"
    echo "Please run: bash $SCRIPT_DIR/setup.sh first"
    exit 1
fi

source "$ROOT_DIR/.env"

if [ -z "$QWEN_BEARER_TOKEN" ]; then
    log_error "QWEN_BEARER_TOKEN not found in .env"
    exit 1
fi

log_info "Token loaded: ${QWEN_BEARER_TOKEN:0:20}..."

# Check token expiration
log_info "Checking token expiration..."
if ! python "$PY_API_DIR/qwen-api/check_jwt_expiry.py" "$QWEN_BEARER_TOKEN" >/dev/null 2>&1; then
    log_error "Token expired! Please run: bash $SCRIPT_DIR/setup.sh"
    exit 1
fi
log_info "✅ Token valid"

# Validate schemas
log_info "Validating qwen.json..."
python "$PY_API_DIR/qwen-api/validate_json.py" "$ROOT_DIR/qwen.json" >/dev/null 2>&1 || true

log_info "Validating openapi.json..."
python "$PY_API_DIR/qwen-api/validate_json.py" "$ROOT_DIR/openapi.json" >/dev/null 2>&1 || true

# Export paths
export QWEN_JSON_PATH="$ROOT_DIR/qwen.json"
export OPENAPI_JSON_PATH="$ROOT_DIR/openapi.json"
export QWEN_BEARER_TOKEN

log_info "Starting OpenAI-compatible API server..."
log_info "Port: $PORT"
log_info "API Base: https://qwen.aikit.club/v1"
echo ""
log_info "📍 Endpoints:"
log_info "   Health: http://localhost:$PORT/"
log_info "   Models: http://localhost:$PORT/v1/models"
log_info "   Chat:   http://localhost:$PORT/v1/chat/completions"
echo ""

# Start server using the installed qwen-api command or direct python
log_info "Starting server..."
cd "$PY_API_DIR" && python start.py
