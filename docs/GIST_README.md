# 🚀 Qwen API - One-Line Deployment Script

**Complete deployment of OpenAI-compatible Qwen API server in a single command!**

This script automatically handles:
- ✅ Environment setup
- ✅ Dependency installation
- ✅ Bearer token extraction (via Playwright)
- ✅ Server startup
- ✅ Health verification
- ✅ Test execution

## 📋 Prerequisites

- **Python 3.8+** (Python 3.10+ recommended)
- **Git** (for cloning the repository)
- **Qwen Account** (Get one at https://chat.qwen.ai)

## 🎯 One-Line Deployment

### Step 1: Export Credentials

```bash
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"
```

### Step 2: Deploy with cURL

```bash
curl -sSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/deploy_qwen_api.sh | bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/deploy_qwen_api.sh | bash
```

That's it! The script will:
1. 🔍 Validate prerequisites
2. 📦 Clone repository
3. 🐍 Setup Python environment
4. 📚 Install dependencies
5. 🎭 Install Playwright browsers
6. 🔐 Extract Bearer token
7. 🚀 Start API server
8. ✅ Verify deployment

## 🌐 Using the API

### Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",  # ✅ Any key works!
    base_url="http://localhost:8096/v1"
)

response = client.chat.completions.create(
    model="gpt-4",  # ✅ Any model works!
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

### cURL

```bash
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-any" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### JavaScript/TypeScript

```javascript
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

## 📊 Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Root endpoint, service info |
| `/health` | GET | Health check |
| `/v1/models` | GET | List available models |
| `/v1/chat/completions` | POST | Chat completions (streaming & non-streaming) |
| `/docs` | GET | Interactive API documentation (Swagger UI) |

## 🎯 Model Mapping

**Any model name works!** The server intelligently maps model names:

| Your Request | Actual Model Used |
|--------------|-------------------|
| `gpt-4` | `qwen-turbo-latest` |
| `gpt-5` | `qwen-turbo-latest` |
| `claude-3` | `qwen-turbo-latest` |
| `qwen-turbo` | `qwen-turbo-latest` |
| `any-model-name` | `qwen-turbo-latest` |

## 🛠️ Configuration

Set these environment variables before deployment:

```bash
# Required
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"

# Optional
export QWEN_API_PORT=8096              # Default: 8096
export QWEN_BEARER_TOKEN="..."         # Skip Playwright extraction
```

## 📝 Useful Commands

```bash
# View logs
tail -f qwen-api/logs/server.log

# Stop server
kill $(cat qwen-api/server.pid)

# Check server status
curl http://localhost:8096/health

# Restart server
cd qwen-api && bash scripts/start.sh
```

## ✨ Features

- **🔐 Automatic Playwright Authentication** - No manual token extraction needed
- **🎯 Any API Key Works** - Anonymous mode enabled by default
- **📦 Any Model Name Works** - Smart defaulting to `qwen-turbo-latest`
- **🌊 Streaming Support** - Full SSE streaming for chat completions
- **📚 OpenAI Compatible** - Drop-in replacement for OpenAI API
- **💾 Token Caching** - 12-hour session caching for performance

## 🐛 Troubleshooting

### Server won't start

```bash
# Check if port is in use
lsof -i :8096

# Kill process using port
kill $(lsof -t -i:8096)

# Try again
curl -sSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/deploy_qwen_api.sh | bash
```

### Authentication fails

```bash
# Verify credentials
echo $QWEN_EMAIL
echo $QWEN_PASSWORD

# Try manual token extraction
cd qwen-api
source venv/bin/activate
python3 test_auth.py
```

### Python version issues

```bash
# Check Python version (need 3.8+)
python3 --version

# Install Python 3.10+ if needed
# Ubuntu/Debian:
sudo apt update && sudo apt install python3.10

# macOS:
brew install python@3.10
```

## 📖 Documentation

- **Full Documentation**: https://github.com/Zeeeepa/qwen-api
- **Issues**: https://github.com/Zeeeepa/qwen-api/issues
- **Pull Requests**: https://github.com/Zeeeepa/qwen-api/pulls

## 🎉 Success Output

After successful deployment, you should see:

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

## 📄 License

MIT License - See repository for details

## 👤 Author

**Zeeeepa**
- GitHub: [@Zeeeepa](https://github.com/Zeeeepa)
- Repository: [qwen-api](https://github.com/Zeeeepa/qwen-api)

---

**Made with ❤️ for the AI community**

