# 🚀 Qwen API - Deployment Guide

Complete guide to deploying your OpenAI-compatible Qwen API server with automatic authentication.

## ✨ Features

- **🔐 Automatic Playwright Authentication** - No manual token extraction needed
- **🎯 Any API Key Works** - Anonymous mode enabled by default
- **📦 Any Model Name Works** - Smart defaulting to `qwen-turbo-latest`
- **🌊 Streaming Support** - Full SSE streaming for chat completions
- **📚 OpenAI Compatible** - Drop-in replacement for OpenAI API
- **💾 Token Caching** - 12-hour session caching for performance

---

## 🎯 Quick Start (3 Commands)

```bash
# 1. Set your Qwen credentials
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"

# 2. Navigate to project
cd qwen-api

# 3. Deploy everything!
bash scripts/deploy.sh
```

That's it! The script will:
1. ✅ Create Python environment
2. ✅ Install all dependencies  
3. ✅ Install Playwright browsers
4. ✅ Extract Bearer token automatically
5. ✅ Start API server
6. ✅ Run comprehensive tests
7. ✅ Display results and usage info

---

## 📋 Prerequisites

- **Python 3.8+** (Python 3.10+ recommended)
- **Git** (for cloning the repository)
- **Qwen Account** (Get one at https://chat.qwen.ai)

---

## 🔧 Detailed Setup

### Option A: One-Command Deployment (Recommended)

```bash
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"
bash scripts/deploy.sh
```

### Option B: Step-by-Step Deployment

```bash
# Step 1: Setup environment
bash scripts/setup.sh

# Step 2: Extract Bearer token (optional, deploy.sh does this automatically)
source venv/bin/activate
python3 test_auth.py

# Step 3: Start server
bash scripts/start.sh

# Step 4: Test API
bash scripts/send_request.sh
```

---

## 🌐 Using the API

### Python (OpenAI Package)

```python
from openai import OpenAI

# Create client
client = OpenAI(
    api_key="sk-any",  # ✅ Any key works!
    base_url="http://localhost:8096/v1"
)

# Chat completion
result = client.chat.completions.create(
    model="gpt-5",  # ✅ Any model works!
    messages=[
        {"role": "user", "content": "Write a haiku about code."}
    ]
)

print(result.choices[0].message.content)
```

### Python (Streaming)

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:8096/v1"
)

stream = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

### cURL

```bash
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-any" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

### JavaScript/TypeScript

```typescript
import OpenAI from 'openai';

const client = new OpenAI({
    apiKey: 'sk-any',
    baseURL: 'http://localhost:8096/v1'
});

const response = await client.chat.completions.create({
    model: 'gpt-4',
    messages: [{ role: 'user', content: 'Hello!' }]
});

console.log(response.choices[0].message.content);
```

---

## 📊 Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Root endpoint, service info |
| `/health` | GET | Health check |
| `/v1/models` | GET | List available models |
| `/v1/chat/completions` | POST | Chat completions (streaming & non-streaming) |
| `/docs` | GET | Interactive API documentation (Swagger UI) |

---

## 🎯 Model Mapping

**Any model name works!** The server intelligently maps model names:

| Your Request | Actual Model Used |
|--------------|-------------------|
| `gpt-4` | `qwen-turbo-latest` |
| `gpt-5` | `qwen-turbo-latest` |
| `claude-3` | `qwen-turbo-latest` |
| `qwen-turbo` | `qwen-turbo-latest` |
| `any-model-name` | `qwen-turbo-latest` |

This makes the API a perfect **drop-in replacement** for OpenAI or Claude!

---

## 🔐 Authentication Modes

The server supports **two authentication modes**:

### Mode 1: Automatic (Recommended)

Set email/password and let Playwright handle authentication:

```bash
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"
bash scripts/deploy.sh
```

### Mode 2: Manual Bearer Token

If you already have a Bearer token:

```bash
export QWEN_BEARER_TOKEN="your-bearer-token-here"
bash scripts/deploy.sh
```

**How to get a Bearer token manually:**

1. Go to https://chat.qwen.ai and log in
2. Open browser DevTools (F12)
3. Go to Console tab
4. Run: `localStorage.getItem('token')`
5. Copy the token and export it

---

## 🛠️ Configuration

Edit `.env` file for customization:

```bash
# Server Configuration
LISTEN_PORT=8096              # Change server port
DEBUG_LOGGING=true            # Enable debug logs

# Authentication (Priority 1: Bearer token)
QWEN_BEARER_TOKEN=            # Manual Bearer token (optional)

# Authentication (Priority 2: Playwright automation)
QWEN_EMAIL=your@email.com     # Your Qwen email
QWEN_PASSWORD=yourpassword    # Your Qwen password

# API Settings
ANONYMOUS_MODE=true           # Allow any API key (recommended)
```

---

## 📁 Project Structure

```
qwen-api/
├── app/
│   ├── auth/               # Authentication system
│   │   ├── provider_auth.py    # Playwright authentication
│   │   ├── session_store.py    # Session caching
│   │   └── token_compressor.py # Token utilities
│   ├── core/               # API core
│   │   ├── config.py           # Configuration management
│   │   └── openai.py           # OpenAI-compatible endpoints
│   ├── models/             # Data models
│   ├── providers/          # Provider implementations
│   └── utils/              # Utility functions
├── scripts/
│   ├── deploy.sh           # 🎯 Complete deployment (USE THIS!)
│   ├── setup.sh            # Environment setup only
│   ├── start.sh            # Start server only
│   └── send_request.sh     # Test API only
├── test_auth.py            # Authentication test script
├── main.py                 # Server entry point
├── .env                    # Configuration file
└── requirements.txt        # Python dependencies
```

---

## 🔧 Useful Commands

```bash
# View logs
tail -f logs/server.log

# Stop server
kill $(cat server.pid)

# Restart server
bash scripts/deploy.sh

# Test API only (server must be running)
bash scripts/send_request.sh

# Extract token only
source venv/bin/activate
python3 test_auth.py
```

---

## 🐛 Troubleshooting

### Server won't start

```bash
# Check if port is already in use
lsof -i :8096

# Kill existing process
kill $(lsof -t -i:8096)

# Try again
bash scripts/deploy.sh
```

### Authentication fails

```bash
# Verify credentials
echo $QWEN_EMAIL
echo $QWEN_PASSWORD

# Try manual token extraction
source venv/bin/activate
python3 test_auth.py

# Check if token was saved
cat .qwen_bearer_token
```

### Playwright browser issues

```bash
# Reinstall Playwright browsers
source venv/bin/activate
playwright install chromium --with-deps
```

### Python version issues

```bash
# Check Python version (need 3.8+)
python3 --version

# Create venv with specific Python
python3.10 -m venv venv
```

---

## 📈 Performance Tips

1. **Use Bearer token mode** - Fastest, no Playwright overhead
2. **Token caching works** - First request extracts token, next 12 hours use cache
3. **Streaming is efficient** - Use `stream=True` for long responses
4. **Monitor logs** - Check `logs/server.log` for performance metrics

---

## 🔒 Security Notes

- **Local use only by default** - Server binds to `0.0.0.0` but should be behind firewall
- **No API key validation** - Anonymous mode allows any key (disable for production)
- **Bearer token storage** - Tokens cached in `.qwen_bearer_token` (gitignored)
- **Credentials in .env** - Never commit `.env` file to git

---

## 🎉 Success Indicators

After running `bash scripts/deploy.sh`, you should see:

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║              🎉 Deployment Complete! 🎉                   ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

📡 Server Information:
  ✅ Status: Running
  🌐 URL: http://localhost:8096
  📊 Health: http://localhost:8096/health
  📚 Docs: http://localhost:8096/docs
  🎯 Models: http://localhost:8096/v1/models
  🔢 PID: 12345

✅ All systems operational! Your Qwen API is ready to use.
```

---

## 💡 Pro Tips

1. **Export credentials permanently** in your `~/.bashrc` or `~/.zshrc`:
   ```bash
   export QWEN_EMAIL="your@email.com"
   export QWEN_PASSWORD="yourpassword"
   ```

2. **Use tmux/screen** for persistent server:
   ```bash
   tmux new -s qwen
   bash scripts/deploy.sh
   # Detach with Ctrl+B then D
   ```

3. **Monitor in real-time**:
   ```bash
   watch -n 1 'curl -s http://localhost:8096/health | jq'
   ```

4. **Test with different models**:
   ```python
   for model in ["gpt-4", "claude-3", "qwen-turbo"]:
       result = client.chat.completions.create(
           model=model,
           messages=[{"role": "user", "content": "Hi!"}]
       )
       print(f"{model}: {result.choices[0].message.content}")
   ```

---

## 🙏 Support

If you encounter issues:

1. Check `logs/server.log` for detailed error messages
2. Verify your credentials are correct
3. Ensure Python 3.8+ is installed
4. Try manual token extraction with `test_auth.py`
5. Check if port 8096 is available

---

## 📝 License

[Your License Here]

---

**Happy coding! 🚀**

