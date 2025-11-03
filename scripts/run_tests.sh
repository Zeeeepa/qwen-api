#!/bin/bash
################################################################################
# Test Runner Script
# Runs comprehensive test suite for qwen-api
#
# Usage:
#   bash scripts/run_tests.sh [options]
#
# Options:
#   --unit          Run only unit tests (fast)
#   --integration   Run only integration tests
#   --e2e           Run only e2e tests (requires server running)
#   --coverage      Generate coverage report
#   --verbose       Verbose output
#   --help          Show this help message
################################################################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
RUN_UNIT=false
RUN_INTEGRATION=false
RUN_E2E=false
RUN_ALL=true
COVERAGE=false
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit)
            RUN_UNIT=true
            RUN_ALL=false
            shift
            ;;
        --integration)
            RUN_INTEGRATION=true
            RUN_ALL=false
            shift
            ;;
        --e2e)
            RUN_E2E=true
            RUN_ALL=false
            shift
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            head -n 20 "$0" | grep "^#" | sed 's/^# //'
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# If --all not explicitly disabled, run all tests
if [ "$RUN_ALL" = true ]; then
    RUN_UNIT=true
    RUN_INTEGRATION=true
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║          🧪 Qwen API Test Runner 🧪                       ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}⚠️  Virtual environment not found. Creating...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
fi

# Activate virtual environment
echo -e "${BLUE}🔄 Activating virtual environment...${NC}"
source venv/bin/activate

# Install/upgrade testing dependencies
echo -e "${BLUE}📦 Installing test dependencies...${NC}"
pip install -q --upgrade pip
pip install -q pytest pytest-asyncio pytest-cov pytest-mock
pip install -q -r requirements.txt

echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Run tests
PYTEST_ARGS=()
if [ "$VERBOSE" = true ]; then
    PYTEST_ARGS+=("-v")
else
    PYTEST_ARGS+=("-q")
fi

if [ "$COVERAGE" = true ]; then
    PYTEST_ARGS+=("--cov=app" "--cov-report=html" "--cov-report=term")
fi

TEST_PASSED=true

# Run unit tests
if [ "$RUN_UNIT" = true ]; then
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Running Unit Tests (fast, no external dependencies)      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if pytest tests/unit/ "${PYTEST_ARGS[@]}" -m "not slow"; then
        echo -e "${GREEN}✅ Unit tests passed!${NC}"
    else
        echo -e "${RED}❌ Unit tests failed!${NC}"
        TEST_PASSED=false
    fi
    echo ""
fi

# Run integration tests
if [ "$RUN_INTEGRATION" = true ]; then
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Running Integration Tests (with mocked backends)         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if pytest tests/integration/ "${PYTEST_ARGS[@]}"; then
        echo -e "${GREEN}✅ Integration tests passed!${NC}"
    else
        echo -e "${RED}❌ Integration tests failed!${NC}"
        TEST_PASSED=false
    fi
    echo ""
fi

# Run e2e tests (requires server)
if [ "$RUN_E2E" = true ]; then
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Running End-to-End Tests (requires server running)       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if server is running
    if curl -s http://localhost:8096/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Server is running${NC}"
        
        if pytest tests/e2e/ "${PYTEST_ARGS[@]}"; then
            echo -e "${GREEN}✅ E2E tests passed!${NC}"
        else
            echo -e "${RED}❌ E2E tests failed!${NC}"
            TEST_PASSED=false
        fi
    else
        echo -e "${YELLOW}⚠️  Server not running. Skipping E2E tests.${NC}"
        echo -e "${YELLOW}💡 Start server with: bash scripts/start.sh${NC}"
    fi
    echo ""
fi

# Show coverage report if enabled
if [ "$COVERAGE" = true ]; then
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Coverage Report                                           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📊 Coverage report generated at: htmlcov/index.html${NC}"
    echo -e "${YELLOW}💡 Open with: open htmlcov/index.html (macOS) or xdg-open htmlcov/index.html (Linux)${NC}"
    echo ""
fi

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Test Summary                                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$TEST_PASSED" = true ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}║              🎉 Test Suite Successful! 🎉                 ║${NC}"
    echo -e "${GREEN}║                                                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}║              ❌ Test Suite Failed ❌                       ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo -e "  • Run with --verbose for more details"
    echo -e "  • Check test logs above for specific failures"
    echo -e "  • Ensure all dependencies are installed"
    exit 1
fi

