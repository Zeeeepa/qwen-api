# Qwen API - OpenAI-Compatible API Proxy

![Version](https://img.shields.io/badge/version-0.2.0-blue)
![Python](https://img.shields.io/badge/python-3.11+-green)
![License](https://img.shields.io/badge/license-MIT-orange)

A production-ready, OpenAI-compatible API proxy for Qwen models with intelligent model routing, automatic tool injection, and comprehensive validation.

---

## 🌟 Key Features

### ✨ Intelligent Model Routing
- **Smart Aliases**: Use friendly names like `Qwen_Research`, `Qwen_Think`, `Qwen_Code`
- **Auto-Tool Injection**: Web search automatically added server-side
- **Default Fallback**: Unknown models → `qwen3-max-latest` with web search
- **Backward Compatible**: Direct Qwen model names work unchanged

### 🔒 Security & Validation
- **OpenAPI Validation**: All requests validated against official OpenAI spec
- **Anonymous Mode**: Works without API keys (or any key works)
- **Bearer Token Caching**: Automated authentication with Playwright
- **Request/Response Sanitization**: Full validation middleware

### 🚀 Performance
- **Async/Await**: Non-blocking I/O for high concurrency
- **Streaming Support**: Full SSE streaming for real-time responses
- **Request Tracking**: Built-in monitoring and analytics
- **Health Checks**: `/health` and `/v1/models` endpoints

---

## 📋 Model Aliases

### 1. **"Qwen"** (Default Fallback)
- **Alias for:** `qwen3-max-latest`
- **Auto-Tools:** `web_search` (always applied)
- **Max Tokens:** Provider default
- **Use Case:** General purpose, unknown model names
- **Example:**
  ```python
  # These all route to qwen3-max-latest + web_search:
  model="gpt-4"
  model="claude-3-opus"
  model="random-model-name"
  ```

### 2. **"Qwen_Research"** Alias
- **Routes to:** `qwen-deep-research`
- **Auto-Tools:** **NONE** (clean research mode)
- **Max Tokens:** Provider default
- **Use Case:** Deep research without tool interference
- **Example:**
  ```python
  client = OpenAI(api_key="sk-any", base_url="http://localhost:8096/v1")
  response = client.chat.completions.create(
      model="Qwen_Research",  # Case-insensitive
      messages=[{"role": "user", "content": "Research quantum computing"}]
  )
  ```

### 3. **"Qwen_Think"** Alias
- **Routes to:** `qwen3-235b-a22b-2507`
- **Auto-Tools:** `web_search` (always applied)
- **Max Tokens:** `81,920` (extended context)
- **Use Case:** Complex reasoning with web access
- **Example:**
  ```python
  response = client.chat.completions.create(
      model="Qwen_Think",
      messages=[{"role": "user", "content": "Solve this complex problem..."}]
  )
  # Server automatically adds web_search tool + 81920 token limit
  ```

### 4. **"Qwen_Code"** Alias
- **Routes to:** `qwen3-coder-plus`
- **Auto-Tools:** `web_search` (always applied)
- **Max Tokens:** Provider default
- **Use Case:** Code generation with web documentation access
- **Example:**
  ```python
  response = client.chat.completions.create(
      model="Qwen_Code",
      messages=[{"role": "user", "content": "Write a Python REST API"}]
  )
  # Web search helps with latest library documentation
  ```

---

## 🔧 Direct Qwen Models (No Aliasing)

These models pass through without transformation:

```python
# Backward compatibility - work as expected:
model="qwen2.5-max"
model="qwen2.5-turbo"
model="qwen-deep-research"
model="qwen-max-latest"
model="qwen3-max-latest"
model="qwen3-235b-a22b-2507"
model="qwen3-coder-plus"
model="qwen-math-plus"
model="qwen-math-turbo"
model="qwen-coder-turbo"
model="qwen-vl-max"
model="qwen-vl-plus"
```

---

## 🚀 Quick Start

### Option 1: One-Line Deployment (Recommended)

```bash
# Set your Qwen credentials
export QWEN_EMAIL="your-email@example.com"
export QWEN_PASSWORD="your-password"

# Deploy everything (setup + auth + server + tests)
curl -sSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/deploy_qwen_api.sh | bash
```

### Option 2: Manual Deployment

```bash
# Clone repository
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api

# Set credentials
export QWEN_EMAIL="your-email@example.com"
export QWEN_PASSWORD="your-password"

# Run deployment script
bash scripts/all.sh
```

### Option 3: Step-by-Step

```bash
# 1. Setup environment
bash scripts/setup.sh

# 2. Extract authentication token
python3 scripts/extract_bearer_token.py

# 3. Start server
bash scripts/start.sh

# 4. Test API (optional)
bash scripts/send_request.sh
```

---

## 📦 Installation Details

### System Requirements

- **Python:** 3.11 or higher
- **OS:** Linux, macOS, Windows (WSL2)
- **Memory:** 512MB minimum, 2GB recommended
- **Disk:** 500MB for dependencies + browsers

### Dependencies

```bash
# Core dependencies (auto-installed by setup script)
pip install -r requirements.txt

# Key packages:
# - fastapi + granian (async web server)
# - playwright (browser automation)
# - httpx (HTTP client)
# - pydantic (data validation)
```

### Manual Setup

```bash
# 1. Create virtual environment
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# 3. Install Playwright browsers
playwright install --with-deps chromium

# 4. Create .env file
cat > .env << EOF
LISTEN_PORT=8096
ANONYMOUS_MODE=true
EOF

# 5. Create directories
mkdir -p logs cache
```

---

## 🔐 Authentication

### Automated (Recommended)

The deployment script automatically:
1. Launches headless Chromium browser
2. Logs into Qwen with your credentials
3. Extracts Bearer token from network traffic
4. Caches token to `.qwen_bearer_token`
5. Reuses cached token until expiration

### Manual Token Extraction

```bash
# Run Playwright authentication
python3 scripts/extract_bearer_token.py

# Token saved to: .qwen_bearer_token
# Format: Bearer eyJ...
```

### Anonymous Mode

**No credentials needed!** The server works in anonymous mode:

```python
# Any API key works:
client = OpenAI(api_key="sk-anything", base_url="http://localhost:8096/v1")
client = OpenAI(api_key="fake-key-123", base_url="http://localhost:8096/v1")
client = OpenAI(api_key="", base_url="http://localhost:8096/v1")
```

---

## 🎯 Usage Examples

### Python (OpenAI SDK)

```python
from openai import OpenAI

# Initialize client
client = OpenAI(
    api_key="sk-any",  # Any key works!
    base_url="http://localhost:8096/v1"
)

# Example 1: Unknown model → Default fallback
response = client.chat.completions.create(
    model="gpt-4",  # Routes to qwen3-max-latest + web_search
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)

# Example 2: Research mode (no tools)
response = client.chat.completions.create(
    model="Qwen_Research",  # qwen-deep-research, no tools
    messages=[{"role": "user", "content": "Research topic..."}]
)

# Example 3: Thinking mode (extended context)
response = client.chat.completions.create(
    model="Qwen_Think",  # qwen3-235b-a22b-2507 + web_search + 81920 tokens
    messages=[{"role": "user", "content": "Complex reasoning..."}]
)

# Example 4: Code generation
response = client.chat.completions.create(
    model="Qwen_Code",  # qwen3-coder-plus + web_search
    messages=[{"role": "user", "content": "Write FastAPI endpoint"}]
)

# Example 5: Streaming
stream = client.chat.completions.create(
    model="Qwen_Think",
    messages=[{"role": "user", "content": "Write a story"}],
    stream=True
)
for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

### cURL

```bash
# Test with any model name
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-any" \
  -d '{
    "model": "Qwen_Think",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'

# Streaming
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-any" \
  -d '{
    "model": "Qwen_Code",
    "messages": [{"role": "user", "content": "Write Python code"}],
    "stream": true
  }'
```

### Node.js

```javascript
import OpenAI from 'openai';

const client = new OpenAI({
  apiKey: 'sk-any',
  baseURL: 'http://localhost:8096/v1'
});

// Use any model alias
const response = await client.chat.completions.create({
  model: 'Qwen_Think',
  messages: [{ role: 'user', content: 'Hello!' }]
});

console.log(response.choices[0].message.content);
```

---

## 🧪 Testing

### Run Comprehensive Test Suite

```bash
# Test all routing scenarios + tool integration
python3 test_all_routing_scenarios.py
```

### Expected Output

```
🚀 COMPREHENSIVE ROUTING & TOOL INTEGRATION TESTS
================================================================================

Testing against: http://localhost:8096/v1
Total scenarios: 5 routing + 2 web search tests

✅ SCENARIO 1: Default Fallback (gpt-5 → qwen3-max-latest + web_search)
✅ SCENARIO 2: Qwen_Research (→ qwen-deep-research, no tools)
✅ SCENARIO 3: Qwen_Think (→ qwen3-235b-a22b-2507 + web_search + 81920 tokens)
✅ SCENARIO 4: Qwen_Code (→ qwen3-coder-plus + web_search)
✅ SCENARIO 5: Direct Model (qwen2.5-max → qwen2.5-max, no changes)
✅ WEB SEARCH TEST 1: gpt-4 with web search
✅ WEB SEARCH TEST 2: Qwen_Think with web search

📊 TEST SUMMARY
Total Tests: 7
Passed: 7
Failed: 0
Pass Rate: 100.0%

🎉 ALL TESTS PASSED! 🎉
```

### Manual Testing

```bash
# Health check
curl http://localhost:8096/health

# List models
curl http://localhost:8096/v1/models

# Simple request
python3 scripts/send_request.sh
```

---

## 📁 Project Structure

```
qwen-api/
├── app/
│   ├── core/
│   │   └── openai.py          # OpenAI endpoints (/chat/completions)
│   ├── middleware/
│   │   └── openapi_validator.py  # Request/response validation
│   ├── model_router.py        # ⭐ Intelligent routing + tool injection
│   ├── providers/
│   │   ├── base.py
│   │   ├── provider_factory.py
│   │   └── qwen_simple_proxy.py
│   └── utils/
│       ├── logger.py
│       └── request_tracker.py
├── scripts/
│   ├── setup.sh               # Environment setup
│   ├── extract_bearer_token.py  # Playwright authentication
│   ├── start.sh               # Start server
│   ├── deploy.sh              # All-in-one deployment
│   └── send_request.sh        # Test script
├── start.py                   # Server entry point (replaces main.py)
├── test_all_routing_scenarios.py  # Comprehensive test suite
├── requirements.txt
├── qwen.json                  # OpenAPI spec for validation
└── README.md                  # This file
```

---

## 🔧 Configuration

### Environment Variables

```bash
# .env file configuration
LISTEN_PORT=8096              # Server port
ANONYMOUS_MODE=true           # Allow any API key
LOG_LEVEL=INFO                # DEBUG, INFO, WARNING, ERROR

# Optional: Runtime settings
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password
```

### Server Settings

Edit `start.py` to customize:

```python
# Port binding
port = int(os.getenv("LISTEN_PORT", "8096"))

# Log level
log_level = os.getenv("LOG_LEVEL", "INFO").upper()

# Worker configuration (Granian)
workers = 1  # Increase for production
threads = 1  # HTTP/1.1 threads
```

### Model Router Configuration

Edit `app/model_router.py` to customize aliases:

```python
MODEL_CONFIGS = {
    "qwen_research": {
        "actual_model": "qwen-deep-research",
        "tools": [],  # No tools
        "max_tokens": None,
    },
    "qwen_think": {
        "actual_model": "qwen3-235b-a22b-2507",
        "tools": ["web_search"],
        "max_tokens": 81920,  # Extended context
    },
    # Add your custom aliases here...
}
```

---

## 🚨 Troubleshooting

### Server won't start

```bash
# Check port availability
lsof -i :8096

# Check logs
tail -f logs/server.log

# Verify Python version
python3 --version  # Should be 3.11+

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### Authentication issues

```bash
# Re-extract token
rm .qwen_bearer_token
python3 scripts/extract_bearer_token.py

# Check token validity
cat .qwen_bearer_token
```

### Connection errors in tests

```bash
# Ensure server is running
curl http://localhost:8096/health

# Check server logs for errors
tail -20 logs/server.log

# Restart server
pkill -f "python3 start.py"
bash scripts/start.sh
```

### Tool injection not working

```bash
# Check model router logs
grep "Auto-injecting tools" logs/server.log

# Verify model alias resolution
grep "Model transformation" logs/server.log

# Expected output:
# 📝 Model transformation: gpt-4 → qwen3-max-latest
# 🛠️ Auto-injecting tools for gpt-4: ['web_search']
```

---

## 📊 API Endpoints

### Chat Completions

```
POST /v1/chat/completions
```

**Request:**
```json
{
  "model": "Qwen_Think",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"}
  ],
  "stream": false,
  "max_tokens": 1000,
  "temperature": 0.7
}
```

**Response:**
```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "qwen3-235b-a22b-2507",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Hello! How can I help you today?"
    },
    "finish_reason": "stop"
  }]
}
```

### List Models

```
GET /v1/models
```

**Response:**
```json
{
  "object": "list",
  "data": [
    {
      "id": "qwen3-max-latest",
      "object": "model",
      "created": 1234567890,
      "owned_by": "qwen"
    },
    {
      "id": "qwen-deep-research",
      "object": "model",
      "created": 1234567890,
      "owned_by": "qwen"
    }
  ]
}
```

### Health Check

```
GET /health
```

**Response:**
```json
{
  "status": "ok",
  "service": "qwen-ai2api-server",
  "version": "0.2.0"
}
```

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Qwen Team** - For the amazing language models
- **OpenAI** - For the API specification
- **FastAPI** - For the excellent web framework
- **Playwright** - For browser automation

---

## 📝 Changelog

### v0.2.0 (Current)
- ✨ Added intelligent model routing
- ✨ Implemented 4 model aliases (Qwen, Qwen_Research, Qwen_Think, Qwen_Code)
- ✨ Auto-tool injection (web_search)
- ✨ OpenAPI validation middleware
- ✨ Comprehensive test suite
- 🐛 Fixed streaming response handling
- 📚 Complete documentation

### v0.1.0
- 🎉 Initial release
- ✅ OpenAI-compatible endpoints
- ✅ Bearer token authentication
- ✅ Basic request/response handling

---

**Made with ❤️ for the AI community**

