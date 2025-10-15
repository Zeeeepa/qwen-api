# 🚀 Qwen OpenAI Proxy - One-Command Deployment

Complete deployment guide for the Qwen OpenAI API Proxy - a universal OpenAI-compatible server that accepts **any API key** and **any model name**.

## ✨ Quick Start (3 commands!)

```bash
export QWEN_EMAIL="developer@pixelium.uk"
export QWEN_PASSWORD="developer1?"
git clone https://github.com/Zeeeepa/qwen-api
cd qwen-api
bash scripts/all.sh
```

That's it! Your server will be running at `http://localhost:7000` 🎉

## 📋 What Does It Do?

The deployment script automatically:

1. ✅ Installs system dependencies (Python, curl, jq, etc.)
2. ✅ Sets up Python virtual environment
3. ✅ Installs all Python packages
4. ✅ Installs Playwright browsers
5. ✅ Extracts your Qwen authentication token
6. ✅ Validates the token
7. ✅ Starts the OpenAI-compatible API server

## 🎯 Key Features

### Universal Compatibility
- ✅ **Any API key works** - Server uses its own stored token
- ✅ **Any model name works** - Maps to qwen3-max automatically
- ✅ **OpenAI SDK compatible** - Drop-in replacement
- ✅ **No configuration needed** - Just provide credentials and go!

### Supported Models
```
User Requests:       Server Maps To:
----------------     ---------------
gpt-5           →    qwen3-max
GLM-4.5V        →    qwen3-max
claude-3        →    qwen3-max
o1              →    qwen3-max
qwen3-max       →    qwen3-max (use actual model)
qwen3-coder-plus→    qwen3-coder-plus
...any model... →    qwen3-max (default)
```

## 💻 Usage Examples

### Python (OpenAI SDK)

```python
from openai import OpenAI

# ANY API key works - server ignores it!
client = OpenAI(
    api_key="sk-anything-you-want",  # Can be random!
    base_url="http://localhost:7000/v1"
)

# ANY model name works - maps to qwen3-max!
response = client.chat.completions.create(
    model="gpt-5",  # Or GLM-4.5V, claude-3, etc.
    messages=[
        {"role": "user", "content": "Write a haiku about code"}
    ]
)

print(response.choices[0].message.content)
```

### cURL

```bash
curl -X POST http://localhost:7000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-any" \
  -d '{
    "model": "gpt-5",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### JavaScript/TypeScript

```javascript
import OpenAI from 'openai';

const client = new OpenAI({
    apiKey: 'sk-whatever',  // Any key works!
    baseURL: 'http://localhost:7000/v1'
});

const response = await client.chat.completions.create({
    model: 'gpt-5',  // Any model works!
    messages: [{ role: 'user', content: 'Hello!' }]
});

console.log(response.choices[0].message.content);
```

## 🔧 Configuration

### Environment Variables

```bash
# Required (for token extraction)
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"

# Optional
export PORT=7000  # Default port (optional)
```

### Custom Port

```bash
PORT=8080 bash scripts/all.sh
```

## 📊 Server Management

### View Logs
```bash
tail -f server.log
```

### Stop Server
```bash
kill $(cat server.pid)
```

### Restart Server
```bash
bash scripts/all.sh
```

### Check Server Status
```bash
curl http://localhost:7000/v1/models
```

## 🐛 Troubleshooting

### Server Won't Start

1. Check logs:
   ```bash
   tail -50 server.log
   ```

2. Verify token is valid:
   ```bash
   source .env
   python3 py-api/qwen-api/check_jwt_expiry.py "$QWEN_BEARER_TOKEN" --verbose
   ```

3. Check if port is in use:
   ```bash
   lsof -i :7000
   ```

### Token Expired

Re-run the deployment script to get a fresh token:
```bash
bash scripts/all.sh
```

### Dependencies Missing

Install manually:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv curl git jq

# macOS
brew install python3 curl jq

# Then run deployment again
bash scripts/all.sh
```

## 🏗️ Architecture

```
┌─────────────────┐
│  User Request   │
│  (any API key)  │
│  (any model)    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  Qwen OpenAI Proxy      │
│  (localhost:7000)       │
│                         │
│  • Ignores user API key │
│  • Maps model names     │
│  • Uses stored token    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Qwen API               │
│  (qwen.aikit.club)      │
│                         │
│  • Receives proxied req │
│  • Uses server token    │
│  • Uses mapped model    │
└─────────────────────────┘
```

## 📦 Files Structure

```
qwen-api/
├── scripts/
│   └── all.sh           # One-command deployment
├── py-api/
│   ├── start.py         # Server entry point
│   ├── setup.py         # Package config
│   └── qwen-api/
│       ├── qwen_openai_server.py   # Main server
│       ├── get_qwen_token.py       # Token extraction
│       └── check_jwt_expiry.py     # Token validation
├── .env                 # Environment variables (auto-generated)
├── server.log          # Server logs (auto-generated)
├── server.pid          # Server PID (auto-generated)
└── DEPLOYMENT.md       # This file
```

## 🔐 Security Notes

- ✅ Token is extracted automatically during deployment
- ✅ Token is stored in `.env` file (gitignored)
- ✅ Server uses stored token for all requests
- ✅ User API keys are ignored (not stored or logged)
- ⚠️ Keep your `.env` file secure
- ⚠️ Don't commit `.env` to version control

## 🌟 Advanced Usage

### Use Specific Qwen Models

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:7000/v1"
)

# Use Qwen's best coder model
response = client.chat.completions.create(
    model="qwen3-coder-plus",
    messages=[{"role": "user", "content": "Write Python code for quicksort"}]
)

# Use Qwen's vision model
response = client.chat.completions.create(
    model="qwen3-vl-plus",
    messages=[{"role": "user", "content": "Describe this image: ..."}]
)
```

### Available Qwen Models

- `qwen3-max` - Best general-purpose model
- `qwen3-coder-plus` - Best for coding tasks
- `qwen3-vl-plus` - Vision + Language model
- `qwen2.5-72b-instruct` - Large instruction-following model
- `qwen2.5-coder-32b-instruct` - Coding specialist

## 🆘 Support

- 📖 [GitHub Issues](https://github.com/Zeeeepa/qwen-api/issues)
- 💬 [Discussions](https://github.com/Zeeeepa/qwen-api/discussions)
- 📧 Email: developer@pixelium.uk

## 📝 License

MIT License - see LICENSE file for details

---

**Made with ❤️ for the AI developer community**

