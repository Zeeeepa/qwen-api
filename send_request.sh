#!/usr/bin/env bash
#
# send_request.sh - Send test request to API server
#
# This script:
# 1. Loads token from .env
# 2. Sends test request to local server
# 3. Displays formatted response
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_request() { echo -e "${BLUE}[REQUEST]${NC} $1"; }
log_response() { echo -e "${YELLOW}[RESPONSE]${NC} $1"; }

PORT=${PORT:-7050}
ENDPOINT="http://localhost:$PORT/v1/chat/completions"

# Load .env
if [ ! -f ".env" ]; then
    log_error ".env file not found!"
    echo "Please run: bash setup.sh first"
    exit 1
fi

source .env

if [ -z "$QWEN_BEARER_TOKEN" ]; then
    log_error "QWEN_BEARER_TOKEN not found in .env"
    exit 1
fi

# Check if server is running
log_info "Checking if server is running..."
if ! curl -s "http://localhost:$PORT/" > /dev/null 2>&1; then
    log_error "Server not running! Please run: bash start.sh"
    exit 1
fi

log_info "✅ Server is running"
echo ""

# Get model from argument or use default
MODEL=${1:-qwen-max-latest}
MESSAGE=${2:-"Can you help me fix my code??"}

log_request "Endpoint: $ENDPOINT"
log_request "Model: $MODEL"
log_request "Message: $MESSAGE"
echo ""

# Send request
log_info "Sending request..."

RESPONSE=$(curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $QWEN_BEARER_TOKEN" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [
      {
        \"role\": \"user\",
        \"content\": \"$MESSAGE\"
      }
    ],
    \"temperature\": 0.7,
    \"max_tokens\": 2000
  }")

# Check response
if echo "$RESPONSE" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
    log_info "✅ Response received!"
    echo ""
    
    # Extract fields
    ID=$(echo "$RESPONSE" | jq -r '.id')
    MODEL_USED=$(echo "$RESPONSE" | jq -r '.model')
    CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')
    
    log_response "ID: $ID"
    log_response "Model: $MODEL_USED"
    echo ""
    log_response "Content:"
    echo "$CONTENT"
    echo ""
    
    # Display full response if requested
    if [ "$VERBOSE" = "1" ]; then
        echo ""
        log_info "Full Response JSON:"
        echo "$RESPONSE" | jq .
    fi
else
    log_error "Failed to get valid response"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    exit 1
fi

log_info "✅ Request completed successfully"

