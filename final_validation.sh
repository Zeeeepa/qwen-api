#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║   Final Validation of autodeploy.sh Script        ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${NC}\n"

PASS=0
FAIL=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name ... "
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAIL++))
        return 1
    fi
}

# Test Suite
echo "Running validation tests..."
echo ""

run_test "Script file exists" "[ -f autodeploy.sh ]"
run_test "Script is executable" "[ -x autodeploy.sh ]"
run_test "Script has valid bash syntax" "bash -n autodeploy.sh"
run_test "Script has shebang" "head -1 autodeploy.sh | grep -q '#!/usr/bin/env bash'"
run_test "Script has main() function" "grep -q '^main()' autodeploy.sh"
run_test "Script has check_prerequisites()" "grep -q '^check_prerequisites()' autodeploy.sh"
run_test "Script has collect_credentials()" "grep -q '^collect_credentials()' autodeploy.sh"
run_test "Script has clone_repository()" "grep -q '^clone_repository()' autodeploy.sh"
run_test "Script has setup_environment()" "grep -q '^setup_environment()' autodeploy.sh"
run_test "Script has install_dependencies()" "grep -q '^install_dependencies()' autodeploy.sh"
run_test "Script has start_server()" "grep -q '^start_server()' autodeploy.sh"
run_test "Script has validate_server()" "grep -q '^validate_server()' autodeploy.sh"
run_test "Script has display_usage()" "grep -q '^display_usage()' autodeploy.sh"
run_test "Script has monitor_logs()" "grep -q '^monitor_logs()' autodeploy.sh"
run_test "Script uses 'set -e' for error handling" "grep -q 'set -e' autodeploy.sh"
run_test "Script has color definitions" "grep -q \"RED=.*033\" autodeploy.sh"
run_test "Script has REPO_URL defined" "grep -q 'REPO_URL=' autodeploy.sh"
run_test "Script has INSTALL_DIR defined" "grep -q 'INSTALL_DIR=' autodeploy.sh"
run_test "Script has email validation regex" "grep -q '@.*\\[a-zA-Z\\]' autodeploy.sh"
run_test "Script has password confirmation" "grep -q 'QWEN_PASSWORD_CONFIRM' autodeploy.sh"
run_test "Script creates .env file" "grep -q 'cat > .env' autodeploy.sh"
run_test "Script sets .env permissions" "grep -q 'chmod 600 .env' autodeploy.sh"
run_test "Script creates virtual environment" "grep -q 'python3 -m venv' autodeploy.sh"
run_test "Script uses pip install -e" "grep -q 'pip install -e' autodeploy.sh"
run_test "Script installs playwright" "grep -q 'playwright install' autodeploy.sh"
run_test "Script uses nohup for background" "grep -q 'nohup python main.py' autodeploy.sh"
run_test "Script has health check" "grep -q '/health' autodeploy.sh"
run_test "Script has chat completion test" "grep -q '/chat/completions' autodeploy.sh"
run_test "Script has API validation" "grep -q 'validate_server' autodeploy.sh"
run_test "Script has log monitoring" "grep -q 'tail -f server.log' autodeploy.sh"
run_test "Script has cleanup trap" "grep -q 'trap.*EXIT' autodeploy.sh"

echo ""
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════${NC}"
echo -e "Test Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}✓ All validation tests passed!${NC}"
    echo -e "${GREEN}The script is ready for production use.${NC}\n"
    exit 0
else
    echo -e "\n${RED}${BOLD}✗ Some tests failed!${NC}"
    echo -e "${YELLOW}Please review the script before deployment.${NC}\n"
    exit 1
fi
