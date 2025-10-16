#!/usr/bin/env bash
################################################################################
# send_request.sh - Test Qwen API with OpenAI Python Client
# Uses the official OpenAI Python package for compatibility testing
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Load environment
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

PORT=${LISTEN_PORT:-8096}
BASE_URL="http://localhost:$PORT"

echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║      Testing Qwen API with OpenAI Client          ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${NC}\n"

# Check if server is running
echo -e "${BLUE}🔍 Checking server status...${NC}"
if ! curl -s -f "$BASE_URL/health" > /dev/null 2>&1; then
    echo -e "${RED}❌ Server not responding at $BASE_URL${NC}"
    echo -e "${YELLOW}Please start the server first:${NC} bash scripts/start.sh\n"
    exit 1
fi

echo -e "${GREEN}✅ Server is running at $BASE_URL${NC}\n"

# Activate venv
echo -e "${BLUE}🔧 Activating Python environment...${NC}"
source venv/bin/activate

# Install openai package if not present
if ! python3 -c "import openai" 2>/dev/null; then
    echo -e "${YELLOW}📦 Installing openai package...${NC}"
    pip install --quiet openai
fi

echo -e "${GREEN}✅ Python environment ready${NC}\n"

# Test 1: Simple Chat Completion
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}TEST 1: Simple Chat Completion${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

python3 << 'EOF'
from openai import OpenAI
import json

print("🤖 Creating OpenAI client...")
client = OpenAI(
    api_key="sk-any",  # ✅ Any key works in anonymous mode!
    base_url="http://localhost:8096/v1"
)

print("📝 Sending request: 'Write a haiku about code'\n")

try:
    result = client.chat.completions.create(
        model="qwen-max-latest",  # ✅ Using actual Qwen model name
        messages=[{"role": "user", "content": "Write a haiku about code."}]
    )
    
    print("━" * 60)
    print("✅ RESPONSE RECEIVED")
    print("━" * 60)
    print(result.choices[0].message.content)
    print("━" * 60)
    print(f"\n📊 Model used: {result.model}")
    print(f"📏 Tokens: {result.usage.total_tokens if result.usage else 'N/A'}")
    print(f"⏱️  Finish reason: {result.choices[0].finish_reason}\n")
    
except Exception as e:
    print(f"❌ Error: {e}\n")
    exit(1)
EOF

TEST1_RESULT=$?

# Test 2: Different Model Names
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}TEST 2: Model Name Flexibility${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

python3 << 'EOF'
from openai import OpenAI

client = OpenAI(
    api_key="sk-test-123",  # Different key
    base_url="http://localhost:8096/v1"
)

test_models = ["qwen3-coder-plus", "qwen-max-latest", "qwen-deep-research", "gpt-4"]  # Test actual Qwen models + generic

print("Testing multiple model names...\n")

for model_name in test_models:
    try:
        result = client.chat.completions.create(
            model=model_name,
            messages=[{"role": "user", "content": "Hi!"}],
            max_tokens=10
        )
        response = result.choices[0].message.content
        print(f"✅ {model_name:20} → {response[:50]}")
    except Exception as e:
        print(f"❌ {model_name:20} → Error: {e}")

print()
EOF

TEST2_RESULT=$?

# Test 3: Streaming Response
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}TEST 3: Streaming Response${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

python3 << 'EOF'
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:8096/v1"
)

print("🌊 Testing streaming response...\n")
print("Response: ", end="", flush=True)

try:
    stream = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": "Count to 5."}],
        stream=True
    )
    
    for chunk in stream:
        if chunk.choices[0].delta.content:
            print(chunk.choices[0].delta.content, end="", flush=True)
    
    print("\n\n✅ Streaming test successful!\n")
    
except Exception as e:
    print(f"\n❌ Streaming error: {e}\n")
    exit(1)
EOF

TEST3_RESULT=$?

# Test 4: Get Models List
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}TEST 4: Available Models${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

python3 << 'EOF'
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:8096/v1"
)

print("📚 Fetching available models...\n")

try:
    models = client.models.list()
    
    print("Available Models:")
    print("─" * 60)
    for model in models.data:
        print(f"  • {model.id}")
    print("─" * 60)
    print(f"\nTotal: {len(models.data)} models\n")
    
except Exception as e:
    print(f"❌ Error fetching models: {e}\n")
    exit(1)
EOF

TEST4_RESULT=$?

# Summary
echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║              Test Results Summary                  ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${NC}\n"

if [ $TEST1_RESULT -eq 0 ]; then
    echo -e "  ${GREEN}✅ Test 1: Simple Chat Completion${NC}"
else
    echo -e "  ${RED}❌ Test 1: Simple Chat Completion${NC}"
fi

if [ $TEST2_RESULT -eq 0 ]; then
    echo -e "  ${GREEN}✅ Test 2: Model Name Flexibility${NC}"
else
    echo -e "  ${RED}❌ Test 2: Model Name Flexibility${NC}"
fi

if [ $TEST3_RESULT -eq 0 ]; then
    echo -e "  ${GREEN}✅ Test 3: Streaming Response${NC}"
else
    echo -e "  ${RED}❌ Test 3: Streaming Response${NC}"
fi

if [ $TEST4_RESULT -eq 0 ]; then
    echo -e "  ${GREEN}✅ Test 4: Available Models${NC}"
else
    echo -e "  ${RED}❌ Test 4: Available Models${NC}"
fi

echo

# Overall result
if [ $TEST1_RESULT -eq 0 ] && [ $TEST2_RESULT -eq 0 ] && [ $TEST3_RESULT -eq 0 ] && [ $TEST4_RESULT -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ All tests passed! API is working correctly.${NC}\n"
    
    # Print SERVER_PORT and model info
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║              Server Information                    ║${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BLUE}🌐 SERVER_PORT:${NC} $PORT"
    echo -e "${BLUE}🔗 API URL:${NC} http://localhost:$PORT/v1"
    echo -e "\n${BLUE}📚 Available Qwen Models:${NC}"
    echo -e "   • qwen-max-latest"
    echo -e "   • qwen3-coder-plus"
    echo -e "   • qwen-deep-research"
    echo -e "   • qwen-plus-latest"
    echo -e "   • qwen-turbo-latest"
    echo -e "   • qwen-vl-max-latest"
    echo -e "   • qwen-math-plus-latest"
    echo -e "   • qwen-coder-turbo-latest"
    echo -e "   • qwen2.5-coder-32b-instruct"
    echo -e "   • qwen2.5-72b-instruct"
    echo -e "   • ...and more\n"
    
    echo -e "${GREEN}💡 Tip:${NC} Any model name defaults to qwen-max-latest\n"
    
    exit 0
else
    echo -e "${YELLOW}${BOLD}⚠️  Some tests failed. Check the output above.${NC}\n"
    exit 1
fi
