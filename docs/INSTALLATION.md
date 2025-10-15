# 📦 Qwen API - Installation & Usage Guide

Complete guide for installing and running the Qwen OpenAI-compatible API server.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

```bash
# 1. Set credentials
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"

# 2. Run complete workflow
bash scripts/all.sh
```

That's it! The script will:
1. ✅ Extract JWT token from Qwen UI
2. ✅ Start OpenAI-compatible server on port 7050
3. ✅ Send test requests and display responses

---

## 📦 Installation

### Method 1: Pip Installation (Recommended)

```bash
# Clone repository
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api

# Install as package
cd py-api
pip install -e .

# Verify installation
qwen-api --help
```

After installation, you'll have these commands available:
- `qwen-api` - Start the API server
- `qwen-token` - Extract JWT token
- `qwen-validate` - Validate JSON schemas
- `qwen-check-token` - Check JWT expiration

### Method 2: Shell Scripts (No Installation)

```bash
# Clone repository
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api

# Run scripts directly
bash scripts/setup.sh
bash scripts/start.sh
bash scripts/send_request.sh
```

---

## 🎯 Usage

### Option A: Individual Scripts

#### 1. Setup (Extract Token)

```bash
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"

bash scripts/setup.sh
```

**What it does:**
- Launches headless Chrome
- Logs into Qwen UI
- Extracts JWT token from localStorage
- Validates token expiration
- Saves to `.env` file

**Output:**
```
[INFO] Checking dependencies...
[INFO] Extracting JWT token from Qwen UI...
[INFO] ✅ Token extracted successfully
[INFO] ✅ Token saved to .env
[INFO] ✅ Setup complete!
```

#### 2. Start Server

```bash
bash scripts/start.sh
```

**What it does:**
- Loads token from `.env`
- Validates token expiration
- Validates JSON schemas
- Starts FastAPI server on port 7050

**Output:**
```
[INFO] Token loaded: eyJhbGciOiJIUzI1...
[INFO] ✅ Token valid
[INFO] Starting OpenAI-compatible API server...
[INFO] Port: 7050

[INFO] 📍 Endpoints:
   Health: http://localhost:7050/
   Models: http://localhost:7050/v1/models
   Chat:   http://localhost:7050/v1/chat/completions
```

#### 3. Send Test Request

```bash
bash scripts/send_request.sh
```

**What it does:**
- Loads token from `.env`
- Checks server availability
- Sends test request to `/v1/chat/completions`
- Displays formatted response

**Output:**
```
[REQUEST] Endpoint: http://localhost:7050/v1/chat/completions
[REQUEST] Model: qwen-max-latest
[REQUEST] Message: What is 2+2?

[INFO] ✅ Response received!
[RESPONSE] Content:
2 + 2 = 4
```

#### 4. Complete Workflow

```bash
bash scripts/all.sh
```

**What it does:**
Runs all three steps sequentially:
1. Setup → Extract token
2. Start → Launch server
3. Request → Send test request

**Interactive:**
- Asks if you want to keep server running
- Press Ctrl+C to stop

---

### Option B: Using Pip Commands

After `pip install -e .`:

```bash
# Extract token
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"
qwen-token > token.txt

# Save to .env
echo "QWEN_BEARER_TOKEN=$(cat token.txt)" > .env

# Start server
source .env
export QWEN_BEARER_TOKEN
qwen-api
```

---

## 📁 Project Structure

```
qwen-api/
├── scripts/                    # Shell scripts
│   ├── setup.sh               # Extract token
│   ├── start.sh               # Start server
│   ├── send_request.sh        # Test API
│   └── all.sh                 # Complete workflow
│
├── py-api/                     # Python package
│   ├── setup.py               # Package configuration
│   └── qwen-api/              # Main package
│       ├── qwen_token_real.py        # Token extraction (Playwright)
│       ├── check_jwt_expiry.py       # JWT validation
│       ├── qwen_openai_server.py     # FastAPI server
│       ├── validate_json.py          # Schema validation
│       ├── get_qwen_token.py         # Token wrapper
│       ├── start.py                  # Server entry point
│       └── [other modules...]
│
├── qwen.json                   # Qwen API schema
├── openapi.json               # OpenAPI schema
├── README.md                  # Main documentation
└── .env                       # Token storage (generated)
```

---

## 🔌 API Reference

### Base URL
```
http://localhost:7050
```

### Endpoints

#### 1. Health Check
```bash
curl http://localhost:7050/
```

**Response:**
```json
{
  "status": "ok",
  "service": "qwen-openai-proxy",
  "qwen_api": "https://qwen.aikit.club/v1"
}
```

#### 2. List Models
```bash
curl http://localhost:7050/v1/models
```

**Response:**
```json
{
  "object": "list",
  "data": [
    {
      "id": "qwen-max-latest",
      "object": "model",
      "created": 1234567890,
      "owned_by": "qwen"
    },
    ...
  ]
}
```

#### 3. Chat Completions (OpenAI Compatible)

```bash
curl -X POST http://localhost:7050/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $QWEN_BEARER_TOKEN" \
  -d '{
    "model": "qwen-max-latest",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "temperature": 0.7,
    "max_tokens": 2000
  }'
```

**Response:**
```json
{
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "qwen-max-latest",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! How can I help you today?"
      },
      "finish_reason": "stop"
    }
  ]
}
```

---

## 🔍 Advanced Usage

### Custom Port

```bash
PORT=8080 bash scripts/start.sh
```

### Custom Model

```bash
bash scripts/send_request.sh "qwen-turbo" "Write a poem"
```

### Verbose Mode

```bash
VERBOSE=1 bash scripts/send_request.sh
```

### Python API

```python
import httpx

API_BASE = "http://localhost:7050"
TOKEN = "eyJhbGciOiJIUzI1..."

response = httpx.post(
    f"{API_BASE}/v1/chat/completions",
    headers={
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json"
    },
    json={
        "model": "qwen-max-latest",
        "messages": [
            {"role": "user", "content": "Hello!"}
        ]
    }
)

print(response.json()["choices"][0]["message"]["content"])
```

---

## 🐛 Troubleshooting

### Token Extraction Fails

**Problem:**
```
❌ Failed to extract token
```

**Solution:**
1. Check credentials:
   ```bash
   echo $QWEN_EMAIL
   echo $QWEN_PASSWORD
   ```
2. Verify Playwright installation:
   ```bash
   playwright install chromium --with-deps
   ```
3. Try manual extraction (see `get-token.md`)

### Server Won't Start

**Problem:**
```
❌ Error: QWEN_BEARER_TOKEN not set
```

**Solution:**
1. Check `.env` file exists:
   ```bash
   cat .env
   ```
2. Manually source it:
   ```bash
   source .env
   export QWEN_BEARER_TOKEN
   ```
3. Re-run setup:
   ```bash
   bash scripts/setup.sh
   ```

### Port Already in Use

**Problem:**
```
Error: Address already in use
```

**Solution:**
```bash
# Kill existing process
lsof -ti:7050 | xargs kill -9

# Or use custom port
PORT=8080 bash scripts/start.sh
```

### Token Expired

**Problem:**
```
❌ Token expired!
```

**Solution:**
```bash
# Re-extract token
bash scripts/setup.sh

# Restart server
bash scripts/start.sh
```

---

## 📊 Performance

- **Token Extraction**: ~10-15 seconds
- **Server Startup**: ~2-3 seconds
- **API Response Time**: ~1-3 seconds (depends on Qwen API)
- **Concurrent Requests**: Supports multiple simultaneous requests

---

## 🔐 Security Notes

1. **Never commit `.env` to git** (already in `.gitignore`)
2. **Token expires after 7 days** - re-run setup when expired
3. **Server runs on localhost** - not exposed externally
4. **Use HTTPS in production** - add reverse proxy (nginx/caddy)

---

## 📚 Additional Resources

- [Main README](README.md) - Overview and features
- [API Documentation](https://qwen-api.readme.io/reference/post_chat-completions)
- [Token Extraction Guide](get-token.md)
- [Quick Start Guide](quickstart.md)

---

## 🤝 Contributing

Found a bug? Want to add a feature?

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a PR

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file

---

## ✨ Credits

Built with ❤️ by Zeeeepa
- Repository: https://github.com/Zeeeepa/qwen-api
- Issues: https://github.com/Zeeeepa/qwen-api/issues

