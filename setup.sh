#!/usr/bin/env bash
#
# setup.sh - Extract Qwen token and save to .env
#
# This script:
# 1. Checks for required environment variables (QWEN_EMAIL, QWEN_PASSWORD)
# 2. Installs required dependencies (playwright, jsonschema, httpx)
# 3. Extracts JWT token from Qwen UI using Playwright
# 4. Validates token expiration
# 5. Saves token to .env file
#

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Check environment variables
if [ -z "$QWEN_EMAIL" ] || [ -z "$QWEN_PASSWORD" ]; then
    log_error "QWEN_EMAIL and QWEN_PASSWORD must be set"
    echo "Usage: QWEN_EMAIL=your@email.com QWEN_PASSWORD=yourpass bash setup.sh"
    exit 1
fi

log_info "Checking dependencies..."

# Install Python dependencies if needed
pip list | grep -q playwright || {
    log_info "Installing playwright..."
    pip install playwright -q
    playwright install chromium --with-deps
}

pip list | grep -q jsonschema || {
    log_info "Installing jsonschema..."
    pip install jsonschema -q
}

pip list | grep -q httpx || {
    log_info "Installing httpx..."
    pip install httpx -q
}

# Check if token already exists and is valid
if [ -f ".env" ] && grep -q "QWEN_BEARER_TOKEN" .env; then
    TOKEN=$(grep QWEN_BEARER_TOKEN .env | cut -d'=' -f2)
    log_info "Checking existing token..."
    
    if python3 scripts/check_jwt_expiry.py "$TOKEN" > /dev/null 2>&1; then
        log_info "✅ Existing token is still valid!"
        python3 scripts/check_jwt_expiry.py "$TOKEN" --verbose
        exit 0
    else
        log_warning "Token expired, fetching new one..."
    fi
fi

log_info "Extracting JWT token from Qwen UI..."
log_info "Email: $QWEN_EMAIL"

# Extract token
if TOKEN=$(python3 scripts/qwen_token_real.py 2>/dev/null); then
    log_info "✅ Token extracted successfully"
    
    # Save to .env
    if [ -f ".env" ]; then
        # Remove old token if exists
        sed -i '/QWEN_BEARER_TOKEN/d' .env
    fi
    echo "QWEN_BEARER_TOKEN=$TOKEN" >> .env
    
    log_info "✅ Token saved to .env"
    
    # Verify token
    log_info "Verifying token expiration..."
    python3 scripts/check_jwt_expiry.py "$TOKEN" --verbose
    
    log_info "✅ Setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Run: bash start.sh"
    echo "  2. Run: bash send_request.sh"
    echo "  Or run everything: bash all.sh"
else
    log_error "Failed to extract token"
    exit 1
fi

