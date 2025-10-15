#!/usr/bin/env bash
#
# setup.sh - Extract and validate Qwen JWT token
#
# This script:
# 1. Checks for required environment variables
# 2. Installs dependencies
# 3. Extracts JWT token from Qwen UI using Playwright
# 4. Validates token expiration
# 5. Saves token to .env file
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
PY_API_DIR="$ROOT_DIR/py-api/qwen-api"
VENV_DIR="$ROOT_DIR/venv"

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

# Check environment variables
if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
    log_error "QWEN_EMAIL and QWEN_PASSWORD must be set"
    echo ""
    echo "Usage:"
    echo "  export QWEN_EMAIL=your@email.com"
    echo "  export QWEN_PASSWORD=yourpassword"
    echo "  bash $0"
    exit 1
fi

log_info "Dependencies already installed in virtual environment"

# Check if token already exists and is valid
if [ -f "$ROOT_DIR/.env" ]; then
    source "$ROOT_DIR/.env"
    if [ -n "$QWEN_BEARER_TOKEN" ]; then
        log_info "Checking existing token..."
        if python3 "$PY_API_DIR/check_jwt_expiry.py" "$QWEN_BEARER_TOKEN" 2>/dev/null; then
            log_info "✅ Existing token is still valid!"
            python3 "$PY_API_DIR/check_jwt_expiry.py" "$QWEN_BEARER_TOKEN"
            exit 0
        fi
    fi
fi

log_info "Extracting JWT token from Qwen UI..."
log_info "This may take 10-15 seconds..."

# Extract token
TOKEN=$(python3 "$PY_API_DIR/qwen_token_real.py")

if [ -z "$TOKEN" ]; then
    log_error "Failed to extract token"
    exit 1
fi

log_info "✅ Token extracted successfully"

# Save to .env
echo "QWEN_BEARER_TOKEN=$TOKEN" > "$ROOT_DIR/.env"
log_info "✅ Token saved to .env"

# Validate token
log_info "Validating token..."
python3 "$PY_API_DIR/check_jwt_expiry.py" "$TOKEN"

log_info "✅ Setup complete!"
