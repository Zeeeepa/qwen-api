# 🚀 Auto-Deploy Script - Quick Setup Guide

## Overview

The `autodeploy.sh` script provides a **single-command deployment solution** that handles everything from cloning to running your Qwen API server with full validation.

## Features

✅ **One-Command Deployment** - Clone, setup, install, and run in one go  
✅ **Interactive Setup** - Secure credential collection with validation  
✅ **Smart Prerequisites Check** - Verifies Python 3.10+, git, pip, curl  
✅ **Auto Environment Setup** - Creates and configures `.env` file  
✅ **Dependency Management** - Virtual environment + package installation  
✅ **Live Validation** - Tests API with actual OpenAI-compatible request  
✅ **Background Server** - Runs continuously with log monitoring  
✅ **Beautiful Output** - Color-coded, formatted progress indicators  

## Quick Start

### Method 1: Direct Download & Run

```bash
# Download and run script
curl -fsSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/autodeploy.sh -o autodeploy.sh
chmod +x autodeploy.sh
./autodeploy.sh

# Or specify a branch
./autodeploy.sh codegen-bot/single-script-auto-deploy-1760015412
```

### Method 2: Clone & Run

```bash
# Clone repository
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api

# Run deployment script
./autodeploy.sh
```

## What It Does

### 1. **Prerequisites Check** ✓
- Verifies Python 3.10+
- Checks git, pip3, curl
- Offers installation commands if missing

### 2. **Interactive Credential Collection** 🔐
- Prompts for Qwen email (with format validation)
- Securely collects password (hidden input)
- Optional FlareProx configuration
- Custom port selection

### 3. **Repository Clone** 📦
```bash
# Clones to: ~/qwen-api-deploy
# Supports custom branches
# Handles existing directories
```

### 4. **Environment Setup** ⚙️
```bash
# Creates .env with:
# - Qwen credentials
# - Server configuration
# - Optional FlareProx settings
# - Secure file permissions (600)
```

### 5. **Dependency Installation** 📚
```bash
# - Creates Python virtual environment
# - Installs package in development mode
# - Installs Playwright browsers
# - All dependencies from requirements.txt
```

### 6. **Server Startup** 🚀
```bash
# - Starts server in background
# - Waits for readiness (30s timeout)
# - Logs to server.log
# - Returns server PID
```

### 7. **API Validation** ✅
```bash
# Tests two endpoints:
# 1. Health check: GET /health
# 2. Chat completion: POST /chat/completions
#    - Sends test message
#    - Validates response format
#    - Displays actual AI response
```

### 8. **Continuous Operation** ♾️
```bash
# - Shows usage examples
# - Lists available models
# - Displays management commands
# - Monitors server logs (Ctrl+C safe)
```

## Usage Examples

### Basic Deployment
```bash
./autodeploy.sh
```

### Deploy Specific Branch
```bash
./autodeploy.sh codegen-bot/feature-branch
```

### Deploy to Custom Location
```bash
# Edit script to change INSTALL_DIR
# Default: ~/qwen-api-deploy
```

## Interactive Prompts

During execution, you'll be prompted for:

```
1. Qwen Email: your-email@example.com
   ✓ Validates email format

2. Qwen Password: ••••••••
   ✓ Hidden input
   ✓ Confirmation required

3. Enable FlareProx? [y/N]
   If yes:
   - Cloudflare API Token
   - Cloudflare Account ID
   - Number of proxies [default: 3]

4. Server Port [default: 8080]
   ✓ Custom port or press Enter for default
```

## Script Output

### Successful Deployment
```
═══════════════════════════════════════════════════════
  Checking System Prerequisites
═══════════════════════════════════════════════════════

✓ Python installed: 3.11.5
✓ Git installed: 2.39.2
✓ pip3 installed: 23.2.1
✓ curl installed
✓ All prerequisites satisfied

═══════════════════════════════════════════════════════
  Interactive Credential Setup
═══════════════════════════════════════════════════════

ℹ  This script will collect your Qwen credentials securely.
ℹ  Your credentials will be stored locally in .env file only.

Enter your Qwen email address: user@example.com
Enter your Qwen password: ••••••••
Confirm your Qwen password: ••••••••
Enable FlareProx for IP rotation? [y/N]: n
Server port [default: 8080]: 

✓ Credentials collected successfully

[... more steps ...]

═══════════════════════════════════════════════════════
  Validating Server
═══════════════════════════════════════════════════════

▸ Testing health endpoint...
✓ Health check passed
Response: {"status":"healthy","version":"1.0.0"}

▸ Testing OpenAI-compatible API endpoint...
ℹ  Sending test chat completion request...
✓ API validation successful!

API Response:
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1760015412,
  "model": "qwen-max",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! How are you today?"
      },
      "finish_reason": "stop"
    }
  ]
}

Assistant Response: Hello! How are you today?

═══════════════════════════════════════════════════════
  Server Running - Usage Information
═══════════════════════════════════════════════════════

✓ Server is running successfully!

Server Details:
  • Address:  http://localhost:8080
  • PID:      12345
  • Logs:     /home/user/qwen-api-deploy/server.log

[... usage examples ...]
```

## Post-Deployment

### Server Management

```bash
# View logs in real-time
tail -f ~/qwen-api-deploy/server.log

# Stop server
kill <PID>  # PID shown in output

# Restart server
cd ~/qwen-api-deploy
source venv/bin/activate
python main.py

# Or re-run deployment script
./autodeploy.sh
```

### API Testing

```bash
# Test health endpoint
curl http://localhost:8080/health

# Test chat completion
curl -X POST http://localhost:8080/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer any-token" \
  -d '{
    "model": "qwen-max",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'

# List available models
curl http://localhost:8080/models \
  -H "Authorization: Bearer any-token"
```

## Troubleshooting

### Prerequisites Missing

**Error**: Python 3.10+ required
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y python3.11 python3.11-venv

# macOS
brew install python@3.11
```

**Error**: Git not installed
```bash
# Ubuntu/Debian
sudo apt-get install -y git

# macOS
brew install git
```

### Clone Fails

**Error**: Fatal: unable to access repository
```bash
# Check internet connection
# Verify repository URL
# Try manual clone:
git clone https://github.com/Zeeeepa/qwen-api.git ~/qwen-api-deploy
```

### Server Won't Start

**Error**: Server failed to start within 30 seconds

1. Check logs:
```bash
cat ~/qwen-api-deploy/server.log
```

2. Verify credentials in `.env`:
```bash
cat ~/qwen-api-deploy/.env
```

3. Test manually:
```bash
cd ~/qwen-api-deploy
source venv/bin/activate
python main.py
```

### Port Already in Use

**Error**: Address already in use

```bash
# Find process using port
lsof -i :8080

# Kill the process
kill <PID>

# Or use different port when prompted
# Server port [default: 8080]: 8081
```

### Playwright Installation Fails

**Warning**: Playwright browser installation failed

```bash
# Install manually
cd ~/qwen-api-deploy
source venv/bin/activate
playwright install chromium --with-deps

# Or install system dependencies first (Ubuntu)
sudo playwright install-deps chromium
```

### API Validation Fails

**Error**: API validation failed (HTTP 401)

- Verify Qwen credentials are correct
- Check if Qwen account is active
- Review server logs for authentication errors

**Error**: API validation failed (HTTP 500)

- Check server logs for detailed error
- Verify all dependencies installed correctly
- Ensure Qwen service is accessible

## Advanced Usage

### Custom Installation Directory

Edit script variable:
```bash
INSTALL_DIR="/opt/qwen-api"  # Instead of ~/qwen-api-deploy
```

### Skip Interactive Prompts

Create `.env` file before running:
```bash
# Create pre-configured .env
cat > .env <<EOF
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password
LISTEN_PORT=8080
FLAREPROX_ENABLED=false
EOF

# Modify script to skip credential collection
# (Advanced users only)
```

### Run as System Service

After deployment, create systemd service:

```bash
sudo tee /etc/systemd/system/qwen-api.service <<EOF
[Unit]
Description=Qwen API Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/home/$USER/qwen-api-deploy
ExecStart=/home/$USER/qwen-api-deploy/venv/bin/python main.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable qwen-api
sudo systemctl start qwen-api
```

## Security Notes

🔒 **Credential Storage**:
- Stored in `.env` file with 600 permissions
- Never committed to git
- Local to deployment directory only

🔒 **Network Security**:
- Server binds to 0.0.0.0 by default
- Use reverse proxy (nginx) for production
- Enable HTTPS with Let's Encrypt

🔒 **API Authentication**:
- Anonymous mode enabled by default
- Customize in `.env`:
  ```bash
  ANONYMOUS_MODE=false
  AUTH_TOKEN=sk-your-secure-token
  ```

## Performance Tips

⚡ **Optimization**:
- Use FlareProx for IP rotation
- Enable connection pooling
- Monitor with `/health` endpoint
- Check logs for slow requests

⚡ **Scaling**:
- Run multiple instances on different ports
- Use load balancer (nginx, HAProxy)
- Monitor with Prometheus + Grafana

## Support

📖 **Documentation**: [README.md](./README.md)  
🐛 **Issues**: [GitHub Issues](https://github.com/Zeeeepa/qwen-api/issues)  
💬 **Discussions**: [GitHub Discussions](https://github.com/Zeeeepa/qwen-api/discussions)  

## License

MIT License - See [LICENSE](./LICENSE)

---

**Made with ❤️ by the Qwen API Team**

Enjoy your automated deployment! 🚀

