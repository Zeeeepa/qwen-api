#!/usr/bin/env bash
#
# start.sh - Start OpenAI-compatible API server
#
# This script:
# 1. Loads token from .env
# 2. Validates JSON schemas (qwen.json, openapi.json)
# 3. Starts FastAPI server on port 7050
# 4. Provides OpenAI-compatible endpoints
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

PORT=${PORT:-7050}

# Load .env
if [ ! -f ".env" ]; then
    log_error ".env file not found!"
    echo "Please run: bash setup.sh first"
    exit 1
fi

source .env

if [ -z "$QWEN_BEARER_TOKEN" ]; then
    log_error "QWEN_BEARER_TOKEN not found in .env"
    echo "Please run: bash setup.sh first"
    exit 1
fi

log_info "Token loaded: ${QWEN_BEARER_TOKEN:0:20}..."

# Validate token expiration
log_info "Checking token expiration..."
if ! python3 scripts/check_jwt_expiry.py "$QWEN_BEARER_TOKEN" > /dev/null 2>&1; then
    log_error "Token expired! Please run: bash setup.sh"
    exit 1
fi

log_info "✅ Token valid"

# Validate schemas if they exist
if [ -f "qwen.json" ]; then
    log_info "Validating qwen.json..."
    if ! jq empty qwen.json 2>/dev/null; then
        log_error "qwen.json is not valid JSON"
        exit 1
    fi
    export QWEN_SCHEMA_PATH="$(pwd)/qwen.json"
fi

if [ -f "openapi.json" ]; then
    log_info "Validating openapi.json..."
    if ! jq empty openapi.json 2>/dev/null; then
        log_error "openapi.json is not valid JSON"
        exit 1
    fi
    export OPENAPI_SCHEMA_PATH="$(pwd)/openapi.json"
fi

export VALIDATION_ENABLED=true

log_info "Starting OpenAI-compatible API server..."
log_info "Port: $PORT"
log_info "API Base: https://qwen.aikit.club/v1"
echo ""
log_info "📍 Endpoints:"
log_info "   Health: http://localhost:$PORT/"
log_info "   Models: http://localhost:$PORT/v1/models"
log_info "   Chat:   http://localhost:$PORT/v1/chat/completions"
echo ""

# Start server
exec python3 scripts/qwen_openai_server.py

