#!/usr/bin/env bash
#
# install.sh - Complete installation with virtual environment
#
# This script:
# 1. Creates Python virtual environment
# 2. Installs all dependencies
# 3. Sets up the project structure
# 4. Ready to extract token and start server
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PY_API_DIR="$ROOT_DIR/py-api"
VENV_DIR="$ROOT_DIR/venv"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Qwen API Server - Installation Script             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check Python version
log_step "Checking Python version..."
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is not installed!"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
log_info "Python version: $PYTHON_VERSION"

# Create virtual environment
log_step "Creating virtual environment..."
if [ -d "$VENV_DIR" ]; then
    log_warn "Virtual environment already exists, removing..."
    rm -rf "$VENV_DIR"
fi

python3 -m venv "$VENV_DIR"
log_info "✅ Virtual environment created at: $VENV_DIR"

# Activate virtual environment
log_step "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
log_info "✅ Virtual environment activated"

# Upgrade pip
log_step "Upgrading pip..."
pip install --upgrade pip setuptools wheel -q
log_info "✅ pip upgraded"

# Install requirements
log_step "Installing dependencies from requirements.txt..."
if [ -f "$PY_API_DIR/requirements.txt" ]; then
    pip install -r "$PY_API_DIR/requirements.txt" -q
    log_info "✅ Dependencies installed"
else
    log_warn "requirements.txt not found, installing core dependencies..."
    pip install -q fastapi uvicorn[standard] httpx playwright pydantic python-jose[cryptography] python-dotenv jsonschema
    log_info "✅ Core dependencies installed"
fi

# Install Playwright browsers
log_step "Installing Playwright browsers..."
playwright install chromium --with-deps >/dev/null 2>&1
log_info "✅ Playwright browsers installed"

# Install package in development mode
log_step "Installing qwen-api package..."
cd "$PY_API_DIR"
pip install -e . -q
log_info "✅ qwen-api package installed"

# Create .env template if it doesn't exist
if [ ! -f "$ROOT_DIR/.env" ]; then
    log_step "Creating .env template..."
    cat > "$ROOT_DIR/.env" << EOF
# Qwen API Configuration
QWEN_BEARER_TOKEN=
HOST=0.0.0.0
PORT=7050
QWEN_JSON_PATH=$ROOT_DIR/qwen.json
OPENAPI_JSON_PATH=$ROOT_DIR/openapi.json
EOF
    log_info "✅ .env template created"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                   Installation Complete!                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_info "Virtual environment location: $VENV_DIR"
log_info "To activate: source venv/bin/activate"
echo ""
log_info "Next steps:"
echo "  1. Set environment variables:"
echo "     export QWEN_EMAIL=your@email.com"
echo "     export QWEN_PASSWORD=yourpassword"
echo ""
echo "  2. Extract Qwen token:"
echo "     bash scripts/setup.sh"
echo ""
echo "  3. Start the server:"
echo "     bash scripts/start.sh"
echo ""
echo "  Or use the all-in-one script:"
echo "     bash scripts/all.sh"
echo ""

