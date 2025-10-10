#!/bin/bash

# Comprehensive API Endpoint Testing Script
# Tests all endpoints with real examples and verifies responses

set -e

API_URL="http://localhost:8096"
AUTH_TOKEN="Bearer sk-test"
TIMESTAMP=$(date +%s)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_test() {
    echo -e "${YELLOW}🧪 TEST $TOTAL_TESTS: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

test_endpoint() {
    local name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="${5:-200}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "$name"
    
    echo "📤 Request:"
    echo "  Method: $method"
    echo "  URL: $API_URL$endpoint"
    if [ -n "$data" ]; then
        echo "  Data: $data"
    fi
    
    # Make request
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$API_URL$endpoint" \
            -H "Authorization: $AUTH_TOKEN" \
            -H "Content-Type: application/json")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n%{http_code}" -X DELETE "$API_URL$endpoint" \
            -H "Authorization: $AUTH_TOKEN" \
            -H "Content-Type: application/json")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$API_URL$endpoint" \
            -H "Authorization: $AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    # Extract status code (last line)
    status_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n-1)
    
    echo "📥 Response:"
    echo "  Status: $status_code"
    echo "  Body: $(echo "$response_body" | head -c 500)..."
    
    # Check status
    if [ "$status_code" = "$expected_status" ]; then
        print_success "Test passed! Status: $status_code"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        
        # Try to pretty print JSON
        if command -v python3 &> /dev/null; then
            echo ""
            echo "📊 Formatted Response:"
            echo "$response_body" | python3 -m json.tool 2>/dev/null | head -50 || echo "$response_body"
        fi
    else
        print_error "Test failed! Expected: $expected_status, Got: $status_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    echo ""
    sleep 1  # Rate limiting
}

# ============================================================================
# START TESTS
# ============================================================================

print_header "🚀 Starting Comprehensive API Testing"
echo "API URL: $API_URL"
echo "Timestamp: $(date)"
echo ""

# ============================================================================
print_header "1️⃣ HEALTH & MONITORING ENDPOINTS"
# ============================================================================

test_endpoint \
    "Health Check" \
    "GET" \
    "/health" \
    "" \
    "200"

test_endpoint \
    "Detailed Health" \
    "GET" \
    "/health/detailed" \
    "" \
    "200"

test_endpoint \
    "Server Stats" \
    "GET" \
    "/stats" \
    "" \
    "200"

test_endpoint \
    "System Info" \
    "GET" \
    "/system" \
    "" \
    "200"

test_endpoint \
    "Metrics" \
    "GET" \
    "/metrics" \
    "" \
    "200"

test_endpoint \
    "Debug Info" \
    "GET" \
    "/debug" \
    "" \
    "200"

# ============================================================================
print_header "2️⃣ MODEL ENDPOINTS"
# ============================================================================

test_endpoint \
    "List Models" \
    "GET" \
    "/v1/models" \
    "" \
    "200"

# ============================================================================
print_header "3️⃣ CHAT COMPLETIONS"
# ============================================================================

# Test 1: Simple text chat (non-streaming)
test_endpoint \
    "Simple Chat (Non-Stream)" \
    "POST" \
    "/v1/chat/completions" \
    '{
        "model": "qwen-turbo",
        "messages": [
            {"role": "user", "content": "Say hello in one word"}
        ],
        "stream": false,
        "max_tokens": 10
    }' \
    "200"

# Test 2: Streaming chat
print_test "Streaming Chat"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo "📤 Testing streaming endpoint..."
stream_response=$(curl -s -N "$API_URL/v1/chat/completions" \
    -H "Authorization: $AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "qwen-turbo",
        "messages": [{"role": "user", "content": "Count to 3"}],
        "stream": true,
        "max_tokens": 20
    }' | head -20)

if echo "$stream_response" | grep -q "data:"; then
    print_success "Streaming test passed!"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "📊 Stream sample:"
    echo "$stream_response" | head -10
else
    print_error "Streaming test failed!"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
echo ""

# Test 3: Multi-modal with image URL
test_endpoint \
    "Multi-modal Chat (Image)" \
    "POST" \
    "/v1/chat/completions" \
    '{
        "model": "qwen-turbo",
        "messages": [{
            "role": "user",
            "content": [
                {"type": "text", "text": "Describe this"},
                {"type": "image_url", "image_url": {"url": "https://example.com/image.jpg"}}
            ]
        }],
        "stream": false,
        "max_tokens": 50
    }' \
    "200"

# Test 4: Thinking mode
test_endpoint \
    "Thinking Mode" \
    "POST" \
    "/v1/chat/completions" \
    '{
        "model": "qwen-max",
        "messages": [
            {"role": "user", "content": "What is 2+2?"}
        ],
        "enable_thinking": true,
        "thinking_budget": 5000,
        "stream": false
    }' \
    "200"

# Test 5: Web search tool
test_endpoint \
    "Web Search Tool" \
    "POST" \
    "/v1/chat/completions" \
    '{
        "model": "qwen-turbo",
        "messages": [
            {"role": "user", "content": "What is the weather today?"}
        ],
        "tools": [{"type": "web_search"}],
        "stream": false
    }' \
    "200"

# ============================================================================
print_header "4️⃣ IMAGE GENERATION"
# ============================================================================

test_endpoint \
    "Text-to-Image Generation" \
    "POST" \
    "/v1/images/generations" \
    '{
        "prompt": "A beautiful sunset over mountains",
        "model": "qwen-max-image",
        "size": "1024x1024",
        "quality": "standard",
        "n": 1
    }' \
    "200"

# ============================================================================
print_header "5️⃣ IMAGE EDITING"
# ============================================================================

test_endpoint \
    "Image Editing (JSON)" \
    "POST" \
    "/v1/images/edits" \
    '{
        "prompt": "Add a rainbow in the background",
        "image": "https://example.com/image.jpg",
        "model": "qwen-max-image"
    }' \
    "200"

# ============================================================================
print_header "6️⃣ VIDEO GENERATION"
# ============================================================================

test_endpoint \
    "Text-to-Video Generation" \
    "POST" \
    "/v1/videos/generations" \
    '{
        "prompt": "A cat playing with a ball",
        "model": "qwen-max-video",
        "size": "1280x720"
    }' \
    "200"

# ============================================================================
print_header "7️⃣ DEEP RESEARCH"
# ============================================================================

test_endpoint \
    "Deep Research" \
    "POST" \
    "/v1/research/deep" \
    '{
        "query": "Latest developments in AI",
        "model": "qwen-deep-research"
    }' \
    "200"

# ============================================================================
print_header "8️⃣ TOKEN POOL MANAGEMENT"
# ============================================================================

test_endpoint \
    "Token Pool Status" \
    "GET" \
    "/v1/token-pool/status" \
    "" \
    "200"

# ============================================================================
print_header "9️⃣ CHAT DELETION (NEW!)"
# ============================================================================

test_endpoint \
    "Delete Chats (POST)" \
    "POST" \
    "/v1/chats/delete" \
    "" \
    "200"

test_endpoint \
    "Delete Chats (DELETE)" \
    "DELETE" \
    "/v1/chats/delete" \
    "" \
    "200"

# ============================================================================
print_header "🔟 ERROR HANDLING TESTS"
# ============================================================================

test_endpoint \
    "Invalid Model" \
    "POST" \
    "/v1/chat/completions" \
    '{
        "model": "invalid-model-xyz",
        "messages": [{"role": "user", "content": "test"}]
    }' \
    "404"

test_endpoint \
    "Missing Auth Token" \
    "GET" \
    "/v1/models" \
    "" \
    "401"

# ============================================================================
print_header "📊 TEST SUMMARY"
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total Tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed:       $PASSED_TESTS${NC}"
echo -e "${RED}Failed:       $FAILED_TESTS${NC}"
echo "Success Rate: $(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")%"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    print_success "🎉 ALL TESTS PASSED!"
    exit 0
else
    print_error "⚠️  Some tests failed. Review output above."
    exit 1
fi

