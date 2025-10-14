# Qwen API Deployment Scripts

Complete set of deployment and testing scripts for the Qwen API proxy server.

## 📁 Scripts Overview

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `setup.sh` | Environment setup & token retrieval | First time setup or token refresh |
| `start.sh` | Start the API server | When you need just the server running |
| `send_request.sh` | Test all model endpoints | Validate server functionality |
| `all.sh` | **Complete deployment pipeline** | **One-command deployment + testing** |

## 🚀 Quick Start

### Option 1: Complete Deployment (Recommended)
```bash
bash scripts/all.sh
```

This single command will:
1. ✅ Setup Python environment
2. ✅ Install all dependencies
3. ✅ Retrieve Bearer token
4. ✅ Start the server
5. ✅ Run comprehensive tests
6. ✅ Keep server running

### Option 2: Step-by-Step
```bash
# 1. Setup environment and retrieve token
bash scripts/setup.sh

# 2. Start the server
bash scripts/start.sh

# 3. Test endpoints (in another terminal)
bash scripts/send_request.sh
```

## 📋 Prerequisites

- **Python 3.8+**
- **uv package manager** (auto-installed if missing)
- **Qwen credentials** (email/password or Bearer token)

## ⚙️ Configuration

Create/edit `.env` file:

```bash
# Required for Playwright authentication
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password

# Or provide token directly (faster)
QWEN_BEARER_TOKEN=eyJhbGci...

# Server settings
LISTEN_PORT=8096
HOST=0.0.0.0
ANONYMOUS_MODE=true
DEBUG_LOGGING=true
```

## 📖 Detailed Script Documentation

### `setup.sh` - Environment Setup

**What it does:**
- Checks Python installation
- Installs/verifies uv package manager
- Creates virtual environment
- Installs all dependencies
- Installs Playwright browsers
- Retrieves Bearer token (if needed)

**Usage:**
```bash
bash scripts/setup.sh
```

**Output:**
- Virtual environment in `.venv/`
- Bearer token in `.env`
- All dependencies installed

### `start.sh` - Server Startup

**What it does:**
- Validates environment
- Checks Bearer token
- Starts FastAPI server
- Monitors health endpoint
- Provides server information

**Usage:**
```bash
bash scripts/start.sh
```

**Output:**
- Server running on `http://localhost:8096`
- PID saved to `server.pid`
- Logs in `logs/server.log`

**Management:**
```bash
# View logs
tail -f logs/server.log

# Stop server
kill $(cat server.pid)

# Restart
bash scripts/start.sh
```

### `send_request.sh` - Endpoint Testing

**What it does:**
- Tests 8 different Qwen models
- Sends various types of requests
- Validates responses
- Generates test report

**Models tested:**
1. `qwen-max-latest` - Most capable model
2. `qwen-turbo` - Fastest responses
3. `qwen-plus` - Balanced performance
4. `qwen-deep-research` - Research mode
5. `qwen3-coder-plus` - Code generation
6. `qwen-max` (with thinking) - Deep reasoning
7. `qwen-plus` - Multi-turn conversation
8. `qwen-max-latest` - Creative writing

**Usage:**
```bash
bash scripts/send_request.sh
```

**Output:**
```
Test Summary Report
═══════════════════
Total Tests: 8
Passed: 8
Failed: 0
✓ All tests passed! 🎉
```

### `all.sh` - Complete Deployment

**What it does:**
- Runs `setup.sh`
- Runs `start.sh`
- Runs `send_request.sh`
- Keeps server running
- Streams logs

**Usage:**
```bash
bash scripts/all.sh
```

**Interactive mode:**
- Shows live logs after testing
- Press `Ctrl+C` to stop watching logs
- Server continues running in background

## 📊 Testing Examples

### Test OpenAI SDK Compatibility

```python
import openai

client = openai.OpenAI(
    base_url="http://localhost:8096/v1",
    api_key="sk-test"
)

response = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "Hello!"}],
    stream=False
)

print(response.choices[0].message.content)
```

### Test Direct HTTP Requests

```bash
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-test" \
  -d '{
    "model": "qwen-turbo",
    "messages": [{"role": "user", "content": "Hi"}],
    "stream": false
  }'
```

### Test Streaming

```bash
curl -N -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-test" \
  -d '{
    "model": "qwen-turbo",
    "messages": [{"role": "user", "content": "Count 1 to 5"}],
    "stream": true
  }'
```

## 🔍 Troubleshooting

### Problem: Bearer token extraction fails

**Solution:**
```bash
# Check credentials in .env
cat .env | grep QWEN

# Manually test authentication
source .venv/bin/activate
python3 test_auth.py
```

### Problem: Server won't start

**Solution:**
```bash
# Check if port is in use
lsof -i :8096

# View server logs
tail -f logs/server.log

# Kill conflicting process
kill $(lsof -ti:8096)
```

### Problem: Tests fail

**Solution:**
```bash
# Check server health
curl http://localhost:8096/health

# Check Bearer token validity
curl -H "Authorization: Bearer $QWEN_BEARER_TOKEN" \
  https://qwen.aikit.club/v1/models

# Re-extract token
bash scripts/setup.sh
```

## 🎯 Advanced Usage

### Custom Port

```bash
# Set in .env
LISTEN_PORT=9000

# Or export
export LISTEN_PORT=9000
bash scripts/start.sh
```

### Debug Mode

```bash
# Enable in .env
DEBUG_LOGGING=true

# View detailed logs
tail -f logs/server.log
```

### Docker Deployment

```bash
# Build image
docker build -t qwen-api .

# Run with scripts
docker run -p 8096:8096 \
  -e QWEN_EMAIL=your@email.com \
  -e QWEN_PASSWORD=yourpassword \
  qwen-api bash scripts/all.sh
```

## 📈 Performance Tips

1. **Use Bearer Token directly** (faster than Playwright)
   ```bash
   export QWEN_BEARER_TOKEN="your-token-here"
   ```

2. **Choose appropriate model**:
   - `qwen-turbo` for speed
   - `qwen-max-latest` for quality
   - `qwen3-coder-plus` for code

3. **Enable streaming** for better UX:
   ```json
   {"stream": true}
   ```

4. **Monitor server resources**:
   ```bash
   top -p $(cat server.pid)
   ```

## 🔗 Related Files

- `test_auth.py` - Standalone authentication test
- `examples/openai_client_example.py` - OpenAI SDK usage
- `examples/direct_requests_example.py` - HTTP request examples
- `main.py` - Server entry point
- `.env` - Configuration file

## 📚 Additional Resources

- [Qwen API Documentation](https://qwen-api.readme.io/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Project README](../README.md)

## 🤝 Contributing

Found a bug or have a suggestion? Please:
1. Check existing issues
2. Create a new issue with details
3. Submit a PR with fixes

## 📝 License

Same as parent project.

