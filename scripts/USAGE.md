# Qwen API Scripts Usage Guide

Complete guide for installing, configuring, and running the Qwen OpenAI-compatible API server with proper virtual environment management.

## Quick Start (Recommended)

```bash
# 1. Set your Qwen credentials
export QWEN_EMAIL=your@email.com
export QWEN_PASSWORD=yourpassword

# 2. Run all-in-one script (automatically installs, sets up, and starts)
bash scripts/all.sh
```

That's it! The server will be running at `http://localhost:7050`

## Step-by-Step Installation

### 1. Install Dependencies (First Time Only)

```bash
bash scripts/install.sh
```

This script will:
- ✅ Create Python virtual environment at `venv/`
- ✅ Install all required dependencies (FastAPI, Playwright, etc.)
- ✅ Install Playwright browsers
- ✅ Set up project structure
- ✅ Create `.env` template

### 2. Extract Qwen Token

```bash
export QWEN_EMAIL=your@email.com
export QWEN_PASSWORD=yourpassword
bash scripts/setup.sh
```

This script will:
- ✅ Activate virtual environment
- ✅ Use Playwright to login and extract JWT token from Qwen
- ✅ Validate token expiration
- ✅ Save token to `.env` file

### 3. Start the Server

```bash
bash scripts/start.sh
```

This script will:
- ✅ Activate virtual environment
- ✅ Load token from `.env`
- ✅ Validate token is not expired
- ✅ Start FastAPI server on port 7050

## Virtual Environment

All scripts automatically manage the virtual environment:

- **Location**: `venv/` in project root
- **Automatic activation**: All scripts activate it automatically
- **Manual activation**: `source venv/bin/activate`
- **Deactivation**: `deactivate`

## Using the API

### Example: Standard OpenAI Format

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-anything123",  # Any API key works!
    base_url="http://localhost:7050/v1"
)

response = client.chat.completions.create(
    model="gpt-4",  # Any model name → qwen-turbo-latest
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

### Example: Alternative Format

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-whatever",
    base_url="http://localhost:7050/v1"
)

# Using responses.create() format
result = client.chat.completions.create(
    model="gpt-5",  # Non-existent → qwen-turbo-latest
    messages=[{"role": "user", "content": "Write a haiku"}]
)

print(result.choices[0].message.content)
```

### cURL Example

```bash
curl http://localhost:7050/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-anything" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Available Scripts

| Script | Purpose | Prerequisites |
|--------|---------|---------------|
| `install.sh` | Install dependencies & create venv | Python 3.8+ |
| `setup.sh` | Extract Qwen token | `install.sh`, QWEN_EMAIL, QWEN_PASSWORD |
| `start.sh` | Start API server | `install.sh`, `.env` with token |
| `all.sh` | Run complete workflow | QWEN_EMAIL, QWEN_PASSWORD |
| `send_request.sh` | Send test request | Running server |

## Environment Variables

### Required for Setup

```bash
export QWEN_EMAIL=your@email.com
export QWEN_PASSWORD=yourpassword
```

### Optional Configuration

```bash
export PORT=7050              # Server port (default: 7050)
export HOST=0.0.0.0           # Server host (default: 0.0.0.0)
```

## Server Features

✅ **Universal API Key**: Accepts ANY API key, always uses server's stored token  
✅ **Universal Model Mapping**: Any unknown model → `qwen-turbo-latest`  
✅ **Multiple Request Formats**: Supports standard messages array + alternative formats  
✅ **OpenAI Compatible**: Drop-in replacement for OpenAI API  
✅ **Valid Qwen Models**:
   - `qwen-max-latest` / `qwen-max`
   - `qwen-plus-latest` / `qwen-plus`
   - `qwen-turbo-latest` / `qwen-turbo`

## API Endpoints

- **Health Check**: `GET http://localhost:7050/`
- **List Models**: `GET http://localhost:7050/v1/models`
- **Chat Completions**: `POST http://localhost:7050/v1/chat/completions`

## Troubleshooting

### Virtual Environment Not Found

```bash
# Solution: Run install script
bash scripts/install.sh
```

### Token Expired

```bash
# Solution: Re-run setup to get new token
export QWEN_EMAIL=your@email.com
export QWEN_PASSWORD=yourpassword
bash scripts/setup.sh
```

### Port Already in Use

```bash
# Solution: Change port
export PORT=8080
bash scripts/start.sh
```

### Dependencies Not Installed

```bash
# Solution: Reinstall
rm -rf venv
bash scripts/install.sh
```

## Development

### Running Tests

```bash
# Activate venv first
source venv/bin/activate

# Run tests
pytest tests/
```

### Installing in Editable Mode

The package is automatically installed in editable mode by `install.sh`:

```bash
cd py-api
pip install -e .
```

## Architecture

```
qwen-api/
├── venv/                    # Virtual environment (auto-created)
├── py-api/
│   ├── start.py            # Server entry point
│   ├── setup.py            # Package configuration
│   └── qwen-api/           # Main package
│       └── qwen_openai_server.py  # FastAPI server
├── tests/                  # Test files
├── scripts/                # Management scripts
│   ├── install.sh         # Dependency installation
│   ├── setup.sh           # Token extraction
│   ├── start.sh           # Server startup
│   └── all.sh             # All-in-one
└── .env                   # Configuration (auto-created)
```

## Security Notes

- 🔒 Token is stored in `.env` file (never commit this!)
- 🔒 Server ignores client API keys, uses only stored token
- 🔒 Token validation before each server start
- 🔒 Automatic token expiration checking

## Support

For issues or questions:
1. Check this guide
2. Review `.env` file has valid token
3. Ensure virtual environment is activated
4. Check server logs for errors

