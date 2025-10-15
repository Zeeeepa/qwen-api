# Qwen API - Scripts Documentation

Complete guide to the automated deployment and testing scripts for the Qwen API server.

## 📋 Overview

The Qwen API includes 4 production-ready scripts that handle the complete workflow from initial setup to continuous testing:

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **deploy.sh** | Complete deployment setup | First-time installation or token refresh |
| **start.sh** | Start the API server | Launch the server with custom config |
| **send_openai_request.sh** | Test OpenAI-compatible API | Validate server functionality |
| **all.sh** | Complete workflow orchestration | One-command deployment + testing |

## 🚀 Quick Start

### One-Line Deployment

```bash
export QWEN_EMAIL=your-email@example.com
export QWEN_PASSWORD=your-password
bash scripts/all.sh
```

This single command will:
1. ✅ Install all dependencies
2. ✅ Launch browser to extract authentication token
3. ✅ Start server in background
4. ✅ Run API tests with visible responses
5. ✅ Keep server running for manual testing

---

## 📚 Detailed Documentation

### 1. deploy.sh - Complete Deployment

**Purpose:** Handles complete environment setup including Playwright authentication.

**Features:**
- System dependency installation
- Python environment setup with uv
- Playwright browser installation
- **Automatic token extraction via browser login**
- Environment configuration
- Comprehensive validation

**Usage:**

```bash
# Basic deployment
export QWEN_EMAIL=developer@pixelium.uk
export QWEN_PASSWORD=developer1?
bash scripts/deploy.sh
```

**What It Does:**

```
Step 1/7: Validates credentials
Step 2/7: Installs system dependencies
Step 3/7: Sets up Python environment
Step 4/7: Installs Playwright browser
Step 5/7: Extracts token via browser login ← KEY FEATURE
Step 6/7: Configures environment
Step 7/7: Verifies installation
```

**Token Extraction Process:**

The script uses Playwright to:
1. Open browser (headless)
2. Navigate to https://chat.qwen.ai
3. Fill in your email/password
4. Wait for successful login
5. Extract `web_api_token` from localStorage
6. Save to `.env` and `.qwen_bearer_token`

**Output Files:**
- `.env` - Environment configuration
- `.qwen_bearer_token` - Extracted bearer token
- `.venv/` - Python virtual environment
- `logs/` - Deployment logs

---

### 2. start.sh - Server Startup

**Purpose:** Launches the FastAPI server with proper configuration.

**Features:**
- Environment validation
- Authentication verification
- Provider configuration
- Port availability check
- Health check
- Background/foreground modes

**Usage:**

```bash
# Basic start (foreground)
bash scripts/start.sh

# Custom port
bash scripts/start.sh --port 8097

# Provider selection
bash scripts/start.sh --provider direct   # Browser-mimicking
bash scripts/start.sh --provider proxy    # Fast proxy
bash scripts/start.sh --provider auto     # Intelligent fallback

# Background mode
bash scripts/start.sh --background

# Test mode (validation only)
bash scripts/start.sh --test
```

**Provider Modes:**

| Mode | Description | Use Case |
|------|-------------|----------|
| `direct` | QwenProvider - Full browser mimicry | Maximum compatibility |
| `proxy` | QwenProxyProvider - qwen.aikit.club | Speed and simplicity |
| `auto` | Try proxy, fallback to direct | Best of both worlds |

**Server Information:**

```
Server URL:     http://localhost:8096
Health Check:   http://localhost:8096/health
API Docs:       http://localhost:8096/docs
OpenAI API:     http://localhost:8096/v1/chat/completions
```

---

### 3. send_openai_request.sh - API Testing

**Purpose:** Test the OpenAI-compatible API with various options.

**Features:**
- Single model testing
- All models testing
- Streaming support
- Verbose output
- Performance metrics

**Usage:**

```bash
# Basic test
bash scripts/send_openai_request.sh

# Custom port
bash scripts/send_openai_request.sh --port 8097

# Specific model
bash scripts/send_openai_request.sh --model qwen3-coder-plus

# Test all models
bash scripts/send_openai_request.sh --all-models

# Streaming test
bash scripts/send_openai_request.sh --stream

# Verbose output
bash scripts/send_openai_request.sh --verbose
```

**Available Models:**

- `qwen-max-latest` - Latest flagship model
- `qwen3-coder-plus` - Code generation specialist
- `qwen-deep-research` - Deep research capabilities
- `qwen-turbo` - Fast responses
- `qwen-plus` - Enhanced capabilities

**Example Output:**

```
✓ Server is running on port 8096
ℹ Health check response: {"status": "healthy"}

Testing model: qwen-max-latest
ℹ Sending request...
✓ Request completed in 1247ms (HTTP 200)

Response content:
────────────────────────────────────────────────────────
I am Qwen, a large language model created by Alibaba Cloud.
────────────────────────────────────────────────────────

ℹ Tokens: 42
```

---

### 4. all.sh - Complete Orchestration

**Purpose:** Master script that runs the entire workflow automatically.

**Features:**
- Complete deployment
- Automatic server startup
- Continuous testing
- Interactive mode
- Server monitoring

**Usage:**

```bash
# Complete workflow
export QWEN_EMAIL=your-email@example.com
export QWEN_PASSWORD=your-password
bash scripts/all.sh

# Custom configuration
bash scripts/all.sh --port 8097 --provider direct

# Skip deployment (if already deployed)
bash scripts/all.sh --skip-deploy

# Skip tests
bash scripts/all.sh --no-test
```

**Workflow Steps:**

```
STEP 1/4: DEPLOYMENT
  → Runs deploy.sh
  → Installs dependencies
  → Extracts authentication token

STEP 2/4: START SERVER
  → Runs start.sh in background
  → Waits for server readiness
  → Validates health endpoint

STEP 3/4: TEST API
  → Runs send_openai_request.sh
  → Validates OpenAI compatibility
  → Shows response in real-time

STEP 4/4: CONTINUOUS TESTING
  → Interactive options menu
  → Continuous tests every 30s
  → Manual testing mode
  → All models testing
```

**Interactive Options:**

After successful deployment, you'll see:

```
What would you like to do?

  1) Run continuous tests (every 30s)
  2) Keep server running (manual testing)
  3) Test all models
  4) Exit and stop server

Choose option [1-4]:
```

---

## 🔧 Configuration Options

### Environment Variables

```bash
# Authentication (Required for first run)
export QWEN_EMAIL=your-email@example.com
export QWEN_PASSWORD=your-password

# Or use bearer token directly (skip Playwright)
export QWEN_BEARER_TOKEN=your-token-here

# Server Configuration
export LISTEN_PORT=8096
export HOST=0.0.0.0

# Provider Mode
export QWEN_PROVIDER_MODE=auto  # auto, direct, proxy

# Features
export ANONYMOUS_MODE=true
export DEBUG_LOGGING=true
export ENABLE_STREAMING=true
export ENABLE_IMAGES=true
```

### Provider Configuration

Edit `.env` or set environment variables:

```env
# Provider Modes:
QWEN_PROVIDER_MODE=auto    # Default: try proxy, fallback to direct
QWEN_PROVIDER_MODE=direct  # Browser-mimicking via QwenProvider
QWEN_PROVIDER_MODE=proxy   # Fast proxy via QwenProxyProvider
```

---

## 🎯 Common Workflows

### First-Time Setup

```bash
# 1. Clone repository
git clone https://github.com/your-org/qwen-api
cd qwen-api

# 2. Set credentials
export QWEN_EMAIL=your-email@example.com
export QWEN_PASSWORD=your-password

# 3. Run complete workflow
bash scripts/all.sh
```

### Daily Usage

```bash
# Start server (using saved token)
bash scripts/start.sh

# In another terminal: test API
bash scripts/send_openai_request.sh
```

### Token Refresh

```bash
# Re-extract token when expired
export QWEN_EMAIL=your-email@example.com
export QWEN_PASSWORD=your-password
bash scripts/deploy.sh
```

### Development Testing

```bash
# Start server in background
bash scripts/start.sh --background

# Run comprehensive tests
bash scripts/send_openai_request.sh --all-models --verbose

# Stop server
kill $(cat .server.pid)
```

---

## 🔍 Troubleshooting

### Issue: Token Extraction Failed

**Symptoms:**
```
❌ Failed to extract token from output
```

**Solutions:**
1. Check credentials are correct
2. Verify internet connection
3. Try manual token extraction:
   ```bash
   # Visit https://chat.qwen.ai
   # Login with credentials
   # Open browser console (F12)
   # Run: localStorage.getItem('web_api_token')
   # Copy token and set manually:
   export QWEN_BEARER_TOKEN=your-token-here
   ```

### Issue: Port Already in Use

**Symptoms:**
```
⚠ Port 8096 is already in use
```

**Solutions:**
```bash
# Option 1: Use different port
bash scripts/start.sh --port 8097

# Option 2: Stop existing server
kill $(cat .server.pid)
# or
lsof -ti:8096 | xargs kill
```

### Issue: Server Not Responding

**Symptoms:**
```
✗ Server is not responding on port 8096
```

**Solutions:**
```bash
# 1. Check if server is running
ps aux | grep "python main.py"

# 2. View logs
tail -f logs/server.log

# 3. Restart server
bash scripts/start.sh
```

### Issue: API Request Failed

**Symptoms:**
```
✗ Request failed (HTTP 500)
```

**Solutions:**
1. Check server logs: `tail -f logs/server.log`
2. Verify token is valid: `cat .qwen_bearer_token`
3. Try different provider: `bash scripts/start.sh --provider direct`
4. Re-extract token: `bash scripts/deploy.sh`

---

## 📊 Testing & Validation

### Quick Health Check

```bash
curl http://localhost:8096/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-14T19:42:00Z"
}
```

### Test Chat Completion

```bash
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-max-latest",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

### Test Streaming

```bash
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "model": "qwen-max-latest",
    "messages": [
      {"role": "user", "content": "Count to 5"}
    ],
    "stream": true
  }'
```

---

## 🎨 Advanced Usage

### Custom Provider Selection

```bash
# Force direct browser-mimicking mode
export QWEN_PROVIDER_MODE=direct
bash scripts/start.sh

# Force proxy mode
export QWEN_PROVIDER_MODE=proxy
bash scripts/start.sh
```

### Performance Benchmarking

```bash
# Test all models with timing
bash scripts/send_openai_request.sh --all-models --verbose

# Run 100 continuous tests
for i in {1..100}; do
  echo "Test $i/100"
  bash scripts/send_openai_request.sh
  sleep 1
done
```

### Monitoring

```bash
# Watch logs in real-time
tail -f logs/server.log

# Monitor server status
watch -n 1 'curl -s http://localhost:8096/health | jq'

# Check process info
ps aux | grep "python main.py"
```

---

## 📁 File Structure

```
qwen-api/
├── scripts/
│   ├── deploy.sh              ← Complete deployment
│   ├── start.sh               ← Server startup
│   ├── send_openai_request.sh ← API testing
│   └── all.sh                 ← Master orchestrator
├── .env                       ← Environment config (created)
├── .qwen_bearer_token         ← Extracted token (created)
├── .server.pid                ← Server PID (created)
├── logs/
│   └── server.log             ← Server logs (created)
└── .venv/                     ← Python environment (created)
```

---

## 🔐 Security Notes

1. **Token Storage**: Tokens are stored in `.qwen_bearer_token` with restricted permissions (600)
2. **Environment Variables**: Never commit `.env` or token files to git
3. **Credentials**: Use environment variables, not hardcoded values
4. **Token Expiry**: Re-run `deploy.sh` when token expires

---

## 🎓 Best Practices

1. **Always use all.sh for first-time setup** - It handles everything automatically
2. **Keep tokens secure** - Add `.env` and `.qwen_bearer_token` to `.gitignore`
3. **Monitor logs** - Check `logs/server.log` for issues
4. **Use background mode for testing** - `start.sh --background` for parallel testing
5. **Refresh tokens regularly** - Re-run `deploy.sh` every few weeks

---

## 📞 Support

For issues or questions:
1. Check logs: `tail -f logs/server.log`
2. Review this documentation
3. Open an issue on GitHub
4. Check Qwen API status: https://chat.qwen.ai

---

## 🎉 Success Indicators

You'll know everything is working when you see:

```
✅ DEPLOYMENT SUCCESSFUL!

Server Information:
  🌐 URL: http://localhost:8096
  🏥 Health: http://localhost:8096/health
  📚 Docs: http://localhost:8096/docs
  🔧 Provider: auto

✓ Request completed in 1247ms (HTTP 200)

Response content:
────────────────────────────────────────────────────────
I am Qwen, a large language model created by Alibaba Cloud.
────────────────────────────────────────────────────────
```

**Happy coding! 🚀**

