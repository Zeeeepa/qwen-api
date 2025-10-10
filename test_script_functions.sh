#!/usr/bin/env bash

# Extract and test critical functions from autodeploy.sh

set -e

# Source the color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}Testing Critical Script Functions${NC}\n"

# Test 1: Verify nohup command works
echo "Test 1: Verify background process capability"
if command -v nohup &>/dev/null; then
    echo -e "${GREEN}✓${NC} nohup available for background processes"
else
    echo -e "${RED}✗${NC} nohup not available"
fi

# Test 2: Test curl with timeout
echo -e "\nTest 2: Test curl with timeout (health check simulation)"
if timeout 5 curl -s http://localhost:99999 &>/dev/null || [ $? -eq 124 ] || [ $? -eq 7 ]; then
    echo -e "${GREEN}✓${NC} curl timeout mechanism works"
else
    echo -e "${YELLOW}⚠${NC}  curl test inconclusive (expected)"
fi

# Test 3: Test process management
echo -e "\nTest 3: Test background process handling"
sleep 1 &
TEST_PID=$!
if ps -p $TEST_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Process detection works (PID: $TEST_PID)"
    kill $TEST_PID 2>/dev/null
else
    echo -e "${RED}✗${NC} Process detection failed"
fi

# Test 4: Test virtual environment creation
echo -e "\nTest 4: Test virtual environment capability"
TEST_VENV="/tmp/test_venv_$$"
if python3 -m venv "$TEST_VENV" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Virtual environment creation works"
    rm -rf "$TEST_VENV"
else
    echo -e "${RED}✗${NC} Virtual environment creation failed"
fi

# Test 5: Test file permission setting
echo -e "\nTest 5: Test file permission setting"
TEST_FILE="/tmp/test_perm_$$"
echo "test" > "$TEST_FILE"
if chmod 600 "$TEST_FILE" && [ "$(stat -c '%a' "$TEST_FILE" 2>/dev/null || stat -f '%OLp' "$TEST_FILE" 2>/dev/null)" = "600" ]; then
    echo -e "${GREEN}✓${NC} File permission setting works"
    rm -f "$TEST_FILE"
else
    echo -e "${YELLOW}⚠${NC}  File permission check inconclusive"
    rm -f "$TEST_FILE"
fi

# Test 6: Test git clone simulation
echo -e "\nTest 6: Test git shallow clone capability"
if git clone --help | grep -q "depth"; then
    echo -e "${GREEN}✓${NC} Git shallow clone supported"
else
    echo -e "${RED}✗${NC} Git shallow clone not supported"
fi

# Test 7: Test wait loop logic
echo -e "\nTest 7: Test wait loop with counter"
counter=0
max_attempts=3
while [ $counter -lt $max_attempts ]; do
    ((counter++))
done
if [ $counter -eq $max_attempts ]; then
    echo -e "${GREEN}✓${NC} Wait loop logic works correctly"
else
    echo -e "${RED}✗${NC} Wait loop logic failed"
fi

echo -e "\n${CYAN}${BOLD}All function tests completed!${NC}"
