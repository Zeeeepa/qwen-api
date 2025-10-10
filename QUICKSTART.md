# Qwen API - Quick Start Guide

Deploy a production-ready OpenAI-compatible API for Qwen models in **one command**.

## 🚀 One-Command Deployment

```bash
curl -fsSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/quick_deploy.sh | bash
```

That's it! The script will:
1. ✅ Clone the repository
2. ✅ Prompt for your Qwen credentials interactively
3. ✅ Set up Python environment
4. ✅ Install all dependencies (including Playwright)
5. ✅ Configure environment
6. ✅ Start the server
7. ✅ Validate with a real API call
8. ✅ Continue running in the background

## 📋 Prerequisites

- **Python 3.8+**
- **Git**
- **Qwen Account** (free at https://chat.qwen.ai)

## 🎯 What You Get

After deployment, you'll have:

- **OpenAI-Compatible API** running on `http://localhost:8096`
- **Automatic Authentication** via Playwright (no manual token extraction)
- **Encrypted Session Storage** for persistent authentication
- **Background Server** continuing to respond to requests

## 💻 Example Usage

### Health Check
```bash
curl http://localhost:8096/health
```

### Chat Completion
```bash
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test" \
  -d '{
    "model": "qwen-turbo",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": false
  }'
```

### Streaming Response
```bash
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test" \
  -d '{
    "model": "qwen-plus",
    "messages": [{"role": "user", "content": "Explain quantum computing"}],
    "stream": true
  }'
```

## 🎨 Supported Models

All Qwen models are supported with various capabilities:

### Base Models
- `qwen-max` - Most capable model
- `qwen-plus` - Balanced performance
- `qwen-turbo` - Fast responses
- `qwen-long` - Extended context

### Specialized Variants
- **Thinking**: Add `-thinking` suffix (e.g., `qwen-max-thinking`)
- **Search**: Add `-search` suffix for web-grounded responses
- **Image**: Add `-image` suffix for image understanding
- **Video**: Add `-video` suffix for video analysis
- **Deep Research**: Add `-deep-research` suffix

### Code Generation
- `qwen-coder-plus` - Specialized for coding tasks

## 🛠️ Management Commands

### View Logs
```bash
tail -f qwen-api-deployment/server.log
```

### Stop Server
```bash
kill $(cat qwen-api-deployment/server.pid)
```

### Restart Server
```bash
cd qwen-api-deployment && \
source venv/bin/activate && \
kill $(cat server.pid) 2>/dev/null || true && \
nohup python main.py > server.log 2>&1 & echo $! > server.pid
```

## 🔐 Authentication

The script uses **Playwright automation** to authenticate with Qwen:

1. You provide your Qwen email and password **interactively**
2. Playwright logs in automatically
3. Bearer token is extracted and cached
4. Session is encrypted and stored locally
5. Token refreshes automatically when expired

**Security Notes:**
- Credentials are stored in `.env` (local only)
- Session tokens are encrypted with Fernet
- No credentials are sent to any third-party

## 🌐 Use with OpenAI SDK

### Python
```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8096/v1",
    api_key="test"  # Any value works
)

response = client.chat.completions.create(
    model="qwen-turbo",
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

### Node.js
```javascript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'http://localhost:8096/v1',
  apiKey: 'test'  // Any value works
});

const response = await client.chat.completions.create({
  model: 'qwen-turbo',
  messages: [{ role: 'user', content: 'Hello!' }]
});

console.log(response.choices[0].message.content);
```

## 🐛 Troubleshooting

### Server Won't Start
```bash
# Check logs
cat qwen-api-deployment/server.log

# Verify port is available
lsof -i :8096
```

### Authentication Fails
```bash
# Delete cached session to force re-login
rm qwen-api-deployment/.sessions/qwen_session.json

# Restart server
cd qwen-api-deployment && \
kill $(cat server.pid) 2>/dev/null || true && \
nohup python main.py > server.log 2>&1 & echo $! > server.pid
```

### Empty API Responses
This may indicate:
- First-time authentication in progress (wait 30 seconds)
- Rate limiting (wait a few minutes)
- Account restrictions (check Qwen account status)

Check server logs for details:
```bash
tail -50 qwen-api-deployment/server.log | grep -A 5 "Raw Qwen"
```

## 📚 Advanced Configuration

### Custom Port
```bash
LISTEN_PORT=3000 curl -fsSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/quick_deploy.sh | bash
```

### Specific Branch
```bash
curl -fsSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/quick_deploy.sh | bash -s develop
```

### Manual Bearer Token (Skip Playwright)
If you already have a Bearer token:

```bash
# Edit .env file
cd qwen-api-deployment
echo "QWEN_BEARER_TOKEN=your_token_here" >> .env

# Restart server
kill $(cat server.pid) && \
nohup python main.py > server.log 2>&1 & echo $! > server.pid
```

## 🤝 Contributing

Found a bug or have a feature request? Open an issue on GitHub!

## 📄 License

MIT License - See LICENSE file for details

---

**Made with ❤️ for the AI community**

Repository: https://github.com/Zeeeepa/qwen-api
