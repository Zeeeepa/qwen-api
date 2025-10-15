# Qwen OpenAI-Compatible API

> **Transform Qwen language models into an OpenAI-compatible API server with automated token management**

This project provides a complete workflow to:
1. 🔑 Automatically extract JWT tokens from Qwen's web interface
2. 🚀 Run an OpenAI-compatible API server for Qwen models
3. 🧪 Test the API with real requests
4. 📦 Run everything with a single command

## ✨ Features

- **🤖 Automated Token Extraction**: Uses Playwright to log into Qwen and extract JWT tokens
- **🔄 OpenAI-Compatible API**: Drop-in replacement for OpenAI API clients
- **✅ Schema Validation**: Full JSON Schema and OpenAPI 3.1 specifications
- **🎯 Simple Workflow**: Four scripts to handle everything
- **⚡ Fast Setup**: Get running in minutes
- **🔒 Secure**: Token stored in `.env` file, never hardcoded

## 🎬 Quick Start

### Prerequisites

- Python 3.8+
- pip (Python package manager)
- curl (for testing)
- jq (for JSON formatting)

### Environment Variables

Set these before running any scripts:

```bash
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"
```

### One-Command Setup

Run everything at once:

```bash
bash scripts/all.sh
```

This will:
1. Extract your Qwen token
2. Start the API server
3. Send test requests
4. Show you the results

### Step-by-Step Usage

#### 1. Extract Token (`setup.sh`)

```bash
bash scripts/setup.sh
```

**What it does:**
- Installs required dependencies (playwright, jsonschema, httpx)
- Logs into chat.qwen.ai using your credentials
- Extracts JWT token from the browser
- Validates token expiration
- Saves token to `.env` file

**Output:**
```
[INFO] Checking dependencies...
[INFO] Extracting JWT token from Qwen UI...
[INFO] ✅ Token extracted successfully
[INFO] ✅ Token saved to .env
[INFO] Token valid for 7.0 more days
```

#### 2. Start Server (`start.sh`)

```bash
bash scripts/start.sh
```

**What it does:**
- Loads token from `.env`
- Validates token expiration
- Validates JSON schemas (qwen.json, openapi.json)
- Starts FastAPI server on port 7050

**Output:**
```
[INFO] Token loaded: eyJhbGciOiJIUzI1NiIs...
[INFO] ✅ Token valid
[INFO] Starting OpenAI-compatible API server...
[INFO] Port: 7050
[INFO] 📍 Endpoints:
   Health: http://localhost:7050/
   Models: http://localhost:7050/v1/models
   Chat:   http://localhost:7050/v1/chat/completions
```

#### 3. Send Test Request (`send_request.sh`)

```bash
# Default test message
bash scripts/send_request.sh

# Custom model and message
bash scripts/send_request.sh "qwen-plus-latest" "Explain quantum computing"

# Verbose mode (shows full JSON)
VERBOSE=1 bash scripts/send_request.sh
```

**What it does:**
- Checks if server is running
- Sends chat completion request
- Displays formatted response

**Output:**
```
[INFO] ✅ Server is running
[REQUEST] Endpoint: http://localhost:7050/v1/chat/completions
[REQUEST] Model: qwen-max-latest
[REQUEST] Message: Can you help me fix my code??

[INFO] ✅ Response received!
[RESPONSE] ID: chatcmpl-111b07d0-b497-435d-b54e-51637c32592d
[RESPONSE] Model: qwen-max-latest
[RESPONSE] Content:
Of course! Please provide the code you're working on...
```

#### 4. Run Everything (`all.sh`)

```bash
bash scripts/all.sh
```

**What it does:**
- Runs scripts/setup.sh
- Starts server in background
- Sends multiple test requests
- Asks if you want to keep server running

## 📡 API Endpoints

### Health Check

```bash
curl http://localhost:7050/
```

**Response:**
```json
{
  "status": "ok",
  "service": "Qwen OpenAI Proxy",
  "version": "1.0.0",
  "endpoints": [
    "/v1/models",
    "/v1/chat/completions"
  ]
}
```

### List Models

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
      "created": 1760529209,
      "owned_by": "qwen"
    },
    {
      "id": "qwen-plus-latest",
      "object": "model",
      "created": 1760529209,
      "owned_by": "qwen"
    },
    {
      "id": "qwen-turbo-latest",
      "object": "model",
      "created": 1760529209,
      "owned_by": "qwen"
    }
  ]
}
```

### Chat Completion

```bash
curl -X POST http://localhost:7050/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "model": "qwen-max-latest",
    "messages": [
      {
        "role": "user",
        "content": "Hello! Can you help me?"
      }
    ],
    "temperature": 0.7,
    "max_tokens": 2000
  }'
```

**Response:**
```json
{
  "id": "chatcmpl-5677e4f8-6c45-4012-bc50-70bfff540b56",
  "object": "chat.completion",
  "created": 1760529402,
  "model": "qwen-max-latest",
  "system_fingerprint": "fp_gf3tp4qp9",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! Yes, I'd be happy to help you..."
      },
      "finish_reason": "stop"
    }
  ]
}
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `QWEN_EMAIL` | Your Qwen account email | ✅ Yes | - |
| `QWEN_PASSWORD` | Your Qwen account password | ✅ Yes | - |
| `QWEN_BEARER_TOKEN` | JWT token (auto-generated) | ⚠️ Auto | - |
| `PORT` | Server port | ❌ No | 7050 |

### JSON Schema Files

**qwen.json** - Defines the structure of Qwen API requests and responses:
- Message format
- Chat request parameters
- Response structure
- Error formats

**openapi.json** - OpenAPI 3.1 specification:
- Complete API documentation
- Endpoint definitions
- Request/response examples
- Authentication details

## 🏗️ Project Structure

```
qwen-api/
├── setup.sh                      # Step 1: Extract token
├── start.sh                      # Step 2: Start server
├── send_request.sh               # Step 3: Send test request
├── all.sh                        # Step 4: Run all steps
├── qwen.json                     # Qwen API schema
├── openapi.json                  # OpenAPI 3.1 spec
├── .env                          # Token storage (auto-generated)
├── scripts/
│   ├── qwen_token_real.py       # Token extraction
│   ├── check_jwt_expiry.py      # Token validation
│   └── qwen_openai_server.py    # FastAPI server
└── README.md                     # This file
```

## 🐍 Python Scripts

### qwen_token_real.py

Automated token extraction using Playwright:
```bash
python3 scripts/qwen_token_real.py
```

Outputs token to stdout (for automation).

### check_jwt_expiry.py

Check token expiration:
```bash
python3 scripts/check_jwt_expiry.py "YOUR_TOKEN"

# Verbose mode
python3 scripts/check_jwt_expiry.py "YOUR_TOKEN" --verbose
```

### qwen_openai_server.py

FastAPI server (usually run via `start.sh`):
```bash
python3 scripts/qwen_openai_server.py
```

## 🔍 Available Models

| Model ID | Description | Best For |
|----------|-------------|----------|
| `qwen-max-latest` | Most capable model | Complex tasks, reasoning |
| `qwen-plus-latest` | Balanced performance | General use |
| `qwen-turbo-latest` | Fastest responses | Simple tasks, speed |

## 💡 Usage Examples

### Python with OpenAI Library

```python
from openai import OpenAI

client = OpenAI(
    api_key="your-token",
    base_url="http://localhost:7050/v1"
)

response = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[
        {"role": "user", "content": "Explain Python decorators"}
    ]
)

print(response.choices[0].message.content)
```

### curl

```bash
TOKEN=$(grep QWEN_BEARER_TOKEN .env | cut -d'=' -f2)

curl -X POST http://localhost:7050/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "model": "qwen-max-latest",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### JavaScript/Node.js

```javascript
const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: 'your-token',
  baseURL: 'http://localhost:7050/v1'
});

async function main() {
  const completion = await openai.chat.completions.create({
    model: 'qwen-max-latest',
    messages: [{ role: 'user', content: 'Hello!' }]
  });
  
  console.log(completion.choices[0].message.content);
}

main();
```

## 🔒 Security Notes

- **Never commit `.env` file**: It contains your JWT token
- **Token expires in 7 days**: Re-run `setup.sh` when expired
- **Secure your credentials**: Use environment variables, not hardcoded values
- **HTTPS in production**: Use reverse proxy (nginx, caddy) with SSL

## 🐛 Troubleshooting

### "QWEN_EMAIL and QWEN_PASSWORD must be set"

**Solution:** Export environment variables:
```bash
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"
```

### "Token expired! Please run: bash scripts/setup.sh"

**Solution:** Your JWT token has expired (7-day validity). Re-run setup:
```bash
bash scripts/setup.sh
```

### "Server not running!"

**Solution:** Start the server first:
```bash
bash scripts/start.sh
```

Or run everything:
```bash
bash scripts/all.sh
```

### "Address already in use" (Port 7050)

**Solution:** Stop the existing server:
```bash
lsof -ti:7050 | xargs kill -9
```

Or use a different port:
```bash
PORT=8080 bash scripts/start.sh
```

### Token extraction fails

**Solution:** Check your credentials and internet connection:
```bash
# Verify credentials
echo $QWEN_EMAIL
echo $QWEN_PASSWORD

# Check Playwright installation
playwright install chromium
```

### "Failed to get valid response"

**Solution:** Check server logs and token validity:
```bash
# Check token expiration
python3 scripts/check_jwt_expiry.py "$QWEN_BEARER_TOKEN" --verbose

# Check server logs
tail -f /tmp/qwen_server.log
```

## 📊 Token Management

### Token Lifecycle

1. **Extraction**: `setup.sh` extracts token from Qwen UI
2. **Storage**: Token saved to `.env` file
3. **Validation**: `start.sh` checks expiration before starting
4. **Usage**: Server uses token for API requests
5. **Expiration**: Token valid for ~7 days
6. **Refresh**: Re-run `setup.sh` to get new token

### Manual Token Check

```bash
# Load token
source .env

# Check expiration
python3 scripts/check_jwt_expiry.py "$QWEN_BEARER_TOKEN" --verbose
```

**Output:**
```
🕐 Token expiration: 2025-10-22 11:51:00 UTC
🕐 Current time:     2025-10-15 11:51:03 UTC
✅ Token valid for 7.0 more days
```

## 🚀 Production Deployment

### Using Docker

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY . .

RUN pip install playwright jsonschema httpx fastapi uvicorn && \
    playwright install chromium --with-deps

ENV QWEN_EMAIL="" \
    QWEN_PASSWORD="" \
    PORT=7050

CMD ["bash", "all.sh"]
```

### Using systemd

Create `/etc/systemd/system/qwen-api.service`:
```ini
[Unit]
Description=Qwen OpenAI API Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/qwen-api
Environment="QWEN_EMAIL=your@email.com"
Environment="QWEN_PASSWORD=yourpassword"
Environment="PORT=7050"
ExecStart=/usr/bin/bash /opt/qwen-api/start.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

### Reverse Proxy (nginx)

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:7050;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📝 API Schema Reference

Full schemas are available in:
- `qwen.json` - JSON Schema definitions
- `openapi.json` - OpenAPI 3.1 specification

View OpenAPI docs:
```bash
# Install redoc-cli
npm install -g redoc-cli

# Generate HTML docs
redoc-cli bundle openapi.json -o api-docs.html
```

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source. See LICENSE file for details.

## 🙏 Acknowledgments

- **Qwen AI**: For providing the language models
- **FastAPI**: For the excellent web framework
- **Playwright**: For browser automation
- **OpenAI**: For the API specification standard

## 📞 Support

- **Issues**: Open a GitHub issue
- **Discussions**: Join GitHub discussions
- **Documentation**: https://qwen-api.readme.io

## 🔗 Links

- **Qwen API Documentation**: https://qwen-api.readme.io/reference/post_chat-completions
- **OpenAI API Reference**: https://platform.openai.com/docs/api-reference
- **FastAPI Documentation**: https://fastapi.tiangolo.com
- **Playwright Documentation**: https://playwright.dev/python

---

**Made with ❤️ for the Qwen community**

🌟 **Star this repo if it helped you!**
