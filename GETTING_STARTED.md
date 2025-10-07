# Qwen API - Getting Started

Complete guide to get you up and running with the Qwen API server in minutes.

## 📋 Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- Optional: Docker & Docker Compose

## 🚀 Quick Start (3 Steps)

### Step 1: Install

```bash
# Clone repository (if not already cloned)
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api

# Install dependencies
pip install -e .
```

### Step 2: Start Server

```bash
# Start on default port (8000)
python main.py

# Or start on custom port
python main.py --port 8081
```

### Step 3: Test

```bash
# In another terminal
python test_server.py
```

## 📊 What You'll See

When you start the server:

```
============================================================
 🚀 Qwen API Server
============================================================

📍 Server: http://0.0.0.0:8000
📚 Docs: http://0.0.0.0:8000/docs
🔍 Health: http://0.0.0.0:8000/health
📋 Models: http://0.0.0.0:8000/v1/models

✅ Available Endpoints:
   - POST /v1/validate        - Validate token
   - POST /v1/refresh         - Refresh token
   - GET  /v1/models          - List models
   - POST /v1/chat/completions - Chat completions
   - POST /v1/images/generations - Image generation
   - POST /v1/images/edits    - Image editing
   - POST /v1/videos/generations - Video generation

============================================================

📊 Loaded 27 models:
   - qwen-max
   - qwen-max-latest
   - qwen-max-0428
   - qwen-max-thinking
   - qwen-max-search
   ... and 22 more
```

## 🔑 Get Your Token

To use the API, you need a compressed Qwen token:

1. **Visit Qwen Chat**: Go to [chat.qwen.ai](https://chat.qwen.ai) and log in

2. **Run Token Extractor**: Open browser console (F12) and paste this JavaScript:

```javascript
// Token extraction script (from README.md)
// This extracts and compresses your credentials
```

3. **Copy Token**: The script will copy a compressed token to your clipboard

4. **Use Token**: Use this token in API requests:

```bash
export QWEN_TOKEN="YOUR_COMPRESSED_TOKEN"
```

## 💡 First API Call

### Using cURL

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer $QWEN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-turbo-latest",
    "messages": [{"role": "user", "content": "Hello, Qwen!"}]
  }'
```

### Using Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    api_key="YOUR_COMPRESSED_TOKEN",
    base_url="http://localhost:8000/v1"
)

response = client.chat.completions.create(
    model="qwen-turbo-latest",
    messages=[
        {"role": "user", "content": "Hello, Qwen!"}
    ]
)

print(response.choices[0].message.content)
```

### Using JavaScript

```javascript
const response = await fetch("http://localhost:8000/v1/chat/completions", {
  method: "POST",
  headers: {
    "Authorization": "Bearer YOUR_COMPRESSED_TOKEN",
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    model: "qwen-turbo-latest",
    messages: [{role: "user", content: "Hello, Qwen!"}]
  })
});

const data = await response.json();
console.log(data.choices[0].message.content);
```

## 📚 Explore Features

### List Available Models

```bash
curl http://localhost:8000/v1/models
```

### Validate Your Token

```bash
curl -X POST http://localhost:8000/v1/validate \
  -H "Content-Type: application/json" \
  -d "{\"token\": \"$QWEN_TOKEN\"}"
```

### Stream Responses

```python
stream = client.chat.completions.create(
    model="qwen-turbo-latest",
    messages=[{"role": "user", "content": "Count to 10"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

### Enable Web Search

```python
response = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "What are the latest AI news?"}],
    tools=[{"type": "web_search"}]
)
```

### Enable Thinking Mode

```python
response = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "Solve this complex problem..."}],
    enable_thinking=True,
    thinking_budget=30000
)
```

## 🐳 Using Docker

### Quick Docker Start

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Manual Docker

```bash
# Build
docker build -t qwen-api .

# Run
docker run -d \
  --name qwen-api \
  -p 8000:8000 \
  qwen-api

# Logs
docker logs -f qwen-api
```

## 🔧 Common Issues

### Port Already in Use

```bash
# Check what's using port 8000
lsof -i :8000

# Use a different port
python main.py --port 8081
```

### Module Not Found

```bash
# Reinstall dependencies
pip install -e .
```

### Connection Refused

```bash
# Make sure server is running
python main.py

# Check health endpoint
curl http://localhost:8000/health
```

### Invalid Token

- Token must be compressed format from browser script
- Check token hasn't expired
- Ensure Bearer prefix in Authorization header

## 📖 Learn More

- **Deployment Guide**: See [DEPLOYMENT.md](DEPLOYMENT.md)
- **Implementation Details**: See [IMPLEMENTATION.md](IMPLEMENTATION.md)
- **API Specification**: See [qwen.json](qwen.json)
- **Interactive Docs**: http://localhost:8000/docs

## 🎯 Next Steps

1. **Integrate with your app** - Use the OpenAI SDK
2. **Deploy to production** - See DEPLOYMENT.md
3. **Customize** - Modify main.py for your needs
4. **Scale** - Add load balancing and caching

## 💡 Tips

- **Development**: Use `--reload` flag for auto-restart
- **Production**: Use nginx reverse proxy
- **Security**: Always use HTTPS in production
- **Performance**: Enable caching and connection pooling

## 📞 Need Help?

- **Issues**: https://github.com/Zeeeepa/qwen-api/issues
- **Discussions**: https://github.com/Zeeeepa/qwen-api/discussions
- **Documentation**: All .md files in repository

## ✅ Checklist

- [ ] Server starts successfully
- [ ] Health endpoint responds
- [ ] Models list loads
- [ ] Token validates
- [ ] Chat completion works
- [ ] Can access /docs

If all checked, you're ready to build! 🚀

---

Happy coding! 🎉

