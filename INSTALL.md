# Installation Guide - Qwen API Proxy

Complete step-by-step installation guide for the Qwen API proxy server.

## 📋 Prerequisites

### Required
- **Python 3.8+** (Python 3.10+ recommended)
- **Linux/macOS/WSL** (Windows users should use WSL2)
- **Git**
- **4GB RAM minimum** (8GB+ recommended)

### Optional (for Bearer token extraction)
- **Playwright system dependencies** (for automated token extraction)
- Or manually provide `QWEN_BEARER_TOKEN`

---

## 🚀 Quick Install (Recommended)

### Option 1: One-Command Installation
```bash
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api
bash scripts/all.sh
```

This will:
1. ✅ Install all dependencies
2. ✅ Setup virtual environment
3. ✅ Install Playwright (with prompts for system deps)
4. ✅ Extract Bearer token
5. ✅ Start the server
6. ✅ Run comprehensive tests

### Option 2: Step-by-Step Installation
```bash
# 1. Clone repository
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api

# 2. Setup environment
bash scripts/setup.sh

# 3. Start server
bash scripts/start.sh

# 4. Test endpoints
bash scripts/send_request.sh
```

---

## 🔧 Detailed Installation

### Step 1: Clone Repository
```bash
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api
```

### Step 2: Configure Credentials

Create `.env` file:
```bash
cp .env.example .env
```

Edit `.env` and add your credentials:
```bash
# Required for token extraction
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password

# Or provide token directly (faster)
QWEN_BEARER_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Server configuration
LISTEN_PORT=8096
HOST=0.0.0.0
ANONYMOUS_MODE=true
DEBUG_LOGGING=true
```

### Step 3: Install Dependencies

#### Automatic (Recommended)
```bash
bash scripts/setup.sh
```

#### Manual
```bash
# Install uv package manager
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create virtual environment
uv venv

# Activate virtual environment
source .venv/bin/activate

# Install Python dependencies
uv pip install -r requirements.txt
```

### Step 4: Install Playwright (For Token Extraction)

Playwright is needed **ONLY** if you want automatic Bearer token extraction. If you provide `QWEN_BEARER_TOKEN` directly in `.env`, you can skip this step.

#### Option A: Let setup.sh handle it
```bash
bash scripts/setup.sh
# Follow the prompts when Playwright installation is needed
```

#### Option B: Manual Playwright Installation

**On Ubuntu/Debian:**

**Ubuntu 24.04+ (Noble and newer):**
```bash
# Activate virtual environment
source .venv/bin/activate

# Install Playwright browsers
playwright install chromium

# Install system dependencies manually (t64 variants for Ubuntu 24.04+)
sudo apt-get update
sudo apt-get install -y \
    libnss3 \
    libatk1.0-0t64 \
    libatk-bridge2.0-0t64 \
    libcups2t64 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2t64 \
    libatspi2.0-0t64 \
    libglib2.0-0t64
```

**Ubuntu 22.04 and older (Jammy and earlier):**
```bash
# Activate virtual environment
source .venv/bin/activate

# Install Playwright browsers
playwright install chromium

# Install system dependencies (standard packages)
sudo playwright install-deps chromium
# Or manually:
sudo apt-get install -y \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2
```

**On macOS:**
```bash
# Activate virtual environment
source .venv/bin/activate

# Install Playwright browsers
playwright install chromium

# System dependencies are usually already available on macOS
```

**On other Linux distributions:**
```bash
# Activate virtual environment
source .venv/bin/activate

# Install Playwright browsers
playwright install chromium

# Install system dependencies manually
# For Fedora/RHEL/CentOS:
sudo dnf install -y \
    nss \
    atk \
    cups-libs \
    libdrm \
    cairo \
    pango \
    alsa-lib

# For Arch Linux:
sudo pacman -S \
    nss \
    atk \
    cups \
    libdrm \
    cairo \
    pango \
    alsa-lib
```

### Step 5: Extract Bearer Token

#### Option A: Automatic (using Playwright)
```bash
source .venv/bin/activate
python3 test_auth.py
```

The token will be saved to `.env` automatically.

#### Option B: Manual Extraction

1. Go to https://chat.qwen.ai/
2. Open browser DevTools (F12)
3. Go to Application/Storage → Local Storage
4. Find `web_api_token` key
5. Copy the value
6. Add to `.env`:
   ```bash
   QWEN_BEARER_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

### Step 6: Start the Server

```bash
bash scripts/start.sh
```

Or manually:
```bash
source .venv/bin/activate
python3 main.py --port 8096 --host 0.0.0.0
```

### Step 7: Verify Installation

```bash
# Check health endpoint
curl http://localhost:8096/health

# Run comprehensive tests
bash scripts/send_request.sh

# Test with OpenAI SDK
python3 examples/openai_client_example.py
```

---

## 🐛 Troubleshooting

### Check Your Ubuntu Version First

If you're on Ubuntu, check which version you're running:
```bash
lsb_release -a
# Or
cat /etc/os-release
```

**Important:** Ubuntu 24.04+ (Noble) uses `t64` package variants. If you see "Noble" or version 24.04+, use the Ubuntu 24.04+ instructions below.

---

### Issue: "sudo: playwright: command not found"

**Problem:** The setup script is trying to run `sudo playwright` but `playwright` is not in the system PATH.

**Solution 1 (Recommended):** Install Playwright system dependencies manually:
```bash
source .venv/bin/activate
sudo .venv/bin/playwright install-deps chromium
```

**Solution 2:** Skip Playwright and provide token manually:
1. Get Bearer token manually (see Step 5, Option B)
2. Add to `.env`: `QWEN_BEARER_TOKEN=your-token-here`
3. Continue with installation

### Issue: "Playwright browser installation failed"

**Problem:** System dependencies are missing.

**Solution for Ubuntu 24.04+ (Noble):**
```bash
# Ubuntu 24.04 uses t64 package variants
sudo apt-get update
sudo apt-get install -y \
    libnss3 \
    libatk1.0-0t64 \
    libatk-bridge2.0-0t64 \
    libcups2t64 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2t64 \
    libatspi2.0-0t64 \
    libglib2.0-0t64

# Then retry
source .venv/bin/activate
playwright install chromium
```

**Solution for Ubuntu 22.04 and older:**
```bash
# Ubuntu 22.04 and earlier use standard package names
sudo apt-get update
sudo apt-get install -y \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2

# Then retry
source .venv/bin/activate
playwright install chromium
```

### Issue: "Invalid or expired Qwen token"

**Problem:** Bearer token has expired (tokens expire after ~12 hours).

**Solution:**
```bash
# Re-extract token
source .venv/bin/activate
python3 test_auth.py

# Or run full setup
bash scripts/setup.sh
```

### Issue: "Port 8096 already in use"

**Problem:** Another service is using port 8096.

**Solution 1:** Kill the existing process:
```bash
lsof -ti:8096 | xargs kill -9
```

**Solution 2:** Use a different port:
```bash
# Edit .env
LISTEN_PORT=8097

# Or start with custom port
python3 main.py --port 8097
```

### Issue: "Module not found" errors

**Problem:** Dependencies not installed correctly.

**Solution:**
```bash
source .venv/bin/activate
uv pip install -r requirements.txt --force-reinstall
```

### Issue: "Permission denied" when running scripts

**Problem:** Scripts don't have execute permissions.

**Solution:**
```bash
chmod +x scripts/*.sh
```

---

## 🎯 Alternative Installation Methods

### Using Docker (Coming Soon)

```bash
# Build image
docker build -t qwen-api .

# Run with environment variables
docker run -p 8096:8096 \
    -e QWEN_EMAIL=your@email.com \
    -e QWEN_PASSWORD=yourpassword \
    qwen-api
```

### Using System Python (Not Recommended)

If you prefer not to use virtual environments:

```bash
# Install dependencies globally
pip install -r requirements.txt

# Start server
python3 main.py
```

⚠️ **Warning:** This can cause conflicts with system packages. Virtual environment is strongly recommended.

---

## 📚 Post-Installation

### Verify Installation

```bash
# 1. Check server status
curl http://localhost:8096/health

# Expected output:
# {"status":"ok","service":"qwen-ai2api-server","version":"0.2.0"}

# 2. List available models
curl http://localhost:8096/v1/models

# 3. Test chat completion
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-test" \
  -d '{
    "model": "qwen-turbo",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": false
  }'
```

### Run Comprehensive Tests

```bash
# Run all tests
bash scripts/send_request.sh

# Expected output:
# ✓ Test #1: Math Explanation - Passed
# ✓ Test #2: Code Generation - Passed
# ✓ Test #3: Fast Response - Passed
# ✓ Test #4: Technical Deep Dive - Passed
# ✓ Test #5: Research Mode - Passed
#
# Test Summary: 5/5 passed (100%)
```

### Configure for Production

1. **Disable Debug Mode**
   ```bash
   # In .env
   DEBUG_LOGGING=false
   ```

2. **Enable Authentication**
   ```bash
   # In .env
   ANONYMOUS_MODE=false
   AUTH_TOKENS_FILE=auth_tokens.txt
   ```
   
   Create `auth_tokens.txt`:
   ```
   sk-your-secret-key-1
   sk-your-secret-key-2
   ```

3. **Setup Systemd Service** (Linux)
   ```bash
   sudo nano /etc/systemd/system/qwen-api.service
   ```
   
   Add:
   ```ini
   [Unit]
   Description=Qwen API Proxy Server
   After=network.target

   [Service]
   Type=simple
   User=your-username
   WorkingDirectory=/path/to/qwen-api
   ExecStart=/path/to/qwen-api/.venv/bin/python3 main.py
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```
   
   Enable and start:
   ```bash
   sudo systemctl enable qwen-api
   sudo systemctl start qwen-api
   sudo systemctl status qwen-api
   ```

---

## 🔗 Next Steps

- Read [QUICKSTART.md](QUICKSTART.md) for usage examples
- Check [scripts/README.md](scripts/README.md) for script documentation
- See [examples/](examples/) for code samples
- Review [GET_TOKEN.md](GET_TOKEN.md) for token extraction details

---

## 💬 Getting Help

- **Issues:** https://github.com/Zeeeepa/qwen-api/issues
- **Discussions:** https://github.com/Zeeeepa/qwen-api/discussions
- **Documentation:** Check the `docs/` folder

---

## 📝 License

Same as parent project.
