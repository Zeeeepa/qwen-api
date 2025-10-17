# Qwen API - OpenAI-Compatible API Server

<div align="center">

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Package](https://img.shields.io/badge/pip-installable-green.svg)](https://pypi.org)

**Professional OpenAI-compatible API server for Qwen models with native tools support**

[Features](#-features) • [Quick Start](#-quick-start) • [Installation](#-installation) • [CLI Commands](#-cli-commands) • [Usage](#-usage) • [Tools](#-native-tools)

</div>

---

## 🔥 What's New

**Latest Update**: Now installable as a Python package!

```bash
pip install -e .
qwen-api serve  # Clean CLI interface
```

- ✅ Professional Python package structure
- ✅ CLI interface with 4 commands
- ✅ Clean `pip install -e .` workflow
- ✅ Backward compatible with existing scripts

---

## 🎯 Features

### Core Features
- ✅ **OpenAI-Compatible API** - Drop-in replacement for OpenAI client libraries
- 🔄 **35+ Qwen Models** - qwen-max, qwen-plus, qwen-turbo, specialized variants
- 🔥 **Native Tools Support** - Web search, vision, deep research, code execution
- 🐍 **Python Package** - Install with `pip install -e .`
- 🖥️ **CLI Interface** - Professional command-line tools
- ⚡ **High Performance** - Async/await, streaming support
- 🔐 **Secure** - Environment-based configuration
- 📊 **Comprehensive** - Function calling, thinking mode, multimodal

### Native Tools
- 🌐 **Web Search** - Real-time web browsing (not simulated!)
- 👁️ **Vision** - Image analysis via multimodal input
- 🧠 **Deep Research** - Extended multi-source research mode (up to 8000 tokens)
- ⚡ **Code Execution** - Python code generation & execution (beta)

### Model Features
- 🧩 **Model Aliasing** - Flexible model name mapping
- 🤔 **Thinking Mode** - Chain-of-thought reasoning
- 🔍 **Search Integration** - Web search capabilities
- 🖼️ **Multimodal** - Image, video, audio support
- 🔧 **Function Calling** - Tool use and structured outputs

---

## 🚀 Quick Start

### Method A: Package Installation (Recommended)

```bash
# 1. Clone repository
git clone https://github.com/Zeeeepa/qwen-api
cd qwen-api

# 2. Set credentials
export QWEN_EMAIL="your-email@example.com"
export QWEN_PASSWORD="your-password"

# 3. Install package
pip install -e .
# OR use uv for faster installs:
# uv pip install -e .

# 4. Extract token (one-time)
qwen-api get-token

# 5. Start server
qwen-api serve
```

### Method B: Traditional Scripts

```bash
# 1. Clone repository
git clone https://github.com/Zeeeepa/qwen-api
cd qwen-api

# 2. Set credentials
export QWEN_EMAIL="developer@pixelium.uk"
export QWEN_PASSWORD="developer1?"

# 3. Run setup and start
bash scripts/setup.sh
bash scripts/start.sh
```

**Server will start on: `http://localhost:7050`**

---

## 📦 Installation

### Prerequisites

- **Python 3.10+**
- **Qwen Account** - Sign up at [qwen.aikit.club](https://qwen.aikit.club)
- **System Dependencies** (for Playwright):
  - Ubuntu/Debian: `apt-get install -y libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 libgbm1 libasound2`
  - Other platforms: See [Playwright docs](https://playwright.dev/python/docs/intro)

### Installation Steps

#### Using Package Manager (Recommended)

```bash
# Clone the repository
git clone https://github.com/Zeeeepa/qwen-api
cd qwen-api

# Install in editable mode
pip install -e .

# Or with uv (faster):
uv pip install -e .

# Playwright browser installation
playwright install chromium
```

#### Using Setup Script

```bash
# Clone the repository
git clone https://github.com/Zeeeepa/qwen-api
cd qwen-api

# Run automated setup
bash scripts/setup.sh
```

The setup script will:
1. Create a Python virtual environment
2. Install all dependencies
3. Install Playwright browsers
4. Prompt for Qwen credentials
5. Extract authentication token

---

## 🖥️ CLI Commands

After installation, the `qwen-api` command becomes available:

### `qwen-api serve`
Start the API server

```bash
# Start with defaults
qwen-api serve

# Custom host and port
qwen-api serve --host 0.0.0.0 --port 8096

# Enable development mode with auto-reload
qwen-api serve --reload

# Set log level
qwen-api serve --log-level debug

# Multiple workers
qwen-api serve --workers 4
```

**Options:**
- `--host`: Host to bind to (default: 0.0.0.0 from .env)
- `--port`: Port to bind to (default: 7050 from .env)
- `--reload`: Enable auto-reload for development
- `--workers`: Number of worker processes (default: 1)
- `--log-level`: Log level (debug/info/warning/error)

### `qwen-api health`
Check if the server is running

```bash
qwen-api health
# Output: ✓ Server is healthy
```

### `qwen-api get-token`
Extract Qwen authentication token

```bash
# Using environment variables
export QWEN_EMAIL="your-email@example.com"
export QWEN_PASSWORD="your-password"
qwen-api get-token

# Or pass credentials directly
qwen-api get-token --email your-email@example.com --password your-password
```

The token is automatically saved to your `.env` file.

### `qwen-api info`
Display server configuration

```bash
qwen-api info
# Output:
# Qwen API Configuration
#   Server: 0.0.0.0:7050
#   API Base: https://qwen.aikit.club/v1
#   Log Level: WARNING
#   Token Length: 1024 chars
#   Default Model: qwen3-max
```

---

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root:

```bash
# Qwen Credentials
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password
QWEN_BEARER_TOKEN=  # Auto-extracted by get-token command

# Server Configuration
HOST=0.0.0.0
PORT=7050
LOG_LEVEL=WARNING

# API Configuration
QWEN_API_BASE=https://qwen.aikit.club/v1
DEFAULT_MODEL=qwen3-max
```

### Manual Token Extraction

If automatic extraction fails:

1. Login to [https://qwen.aikit.club](https://qwen.aikit.club)
2. Open browser DevTools (F12)
3. Go to Application → Local Storage
4. Find the JWT token
5. Add it to `.env` as `QWEN_BEARER_TOKEN`

---

## 💻 Usage

### Python Client

```python
from openai import OpenAI

# Initialize client
client = OpenAI(
    api_key="sk-any",  # Any key works!
    base_url="http://localhost:7050/v1"
)

# Simple chat
response = client.chat.completions.create(
    model="qwen-max-latest",  # Or any Qwen model
    messages=[
        {"role": "user", "content": "Write a haiku about Python"}
    ]
)

print(response.choices[0].message.content)
```

### Streaming

```python
stream = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

### Function Calling

```python
tools = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get weather for a location",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {"type": "string"},
                "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
            },
            "required": ["location"]
        }
    }
}]

response = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "What's the weather in Tokyo?"}],
    tools=tools
)
```

### Web Search (Native Tool)

```python
response = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "What are the latest AI developments?"}],
    extra_body={"tools": [{"type": "web_search"}]}
)
```

### Vision (Image Analysis)

```python
response = client.chat.completions.create(
    model="qwen-vl-max",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "What's in this image?"},
            {"type": "image_url", "image_url": {"url": "https://example.com/image.jpg"}}
        ]
    }]
)
```

### Deep Research Mode

```python
response = client.chat.completions.create(
    model="qwen-deep-research",
    messages=[{"role": "user", "content": "Analyze the impact of quantum computing"}],
    extra_body={"tools": [{"type": "deep_research"}]}
)
```

---

## 🔥 Native Tools

Qwen API supports REAL native tools that actually execute (not simulated):

### Available Tools

#### 🌐 Web Search
Real-time web browsing and information retrieval

```python
response = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "Latest news about SpaceX"}],
    extra_body={"tools": [{"type": "web_search"}]}
)
```

**Features:**
- Real browser-based search
- Multi-source aggregation
- Citation tracking
- Up-to-date information

#### 👁️ Vision (Multimodal)
Image analysis and understanding

```python
response = client.chat.completions.create(
    model="qwen-vl-max",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "Describe this image"},
            {"type": "image_url", "image_url": {"url": "image.jpg"}}
        ]
    }]
)
```

**Supported Models:**
- `qwen-vl-max` - Best vision model
- `qwen-vl-plus` - Fast vision model
- `qwen-vl-ocr` - OCR specialized

#### 🧠 Deep Research
Extended research mode with multi-source analysis

```python
response = client.chat.completions.create(
    model="qwen-deep-research",
    messages=[{"role": "user", "content": "Research quantum computing applications"}],
    extra_body={
        "tools": [{"type": "deep_research"}],
        "max_tokens": 8000  # Up to 8000 tokens for comprehensive research
    }
)
```

**Features:**
- Multi-source synthesis
- Extended context (8000 tokens)
- Structured analysis
- Citation tracking

#### ⚡ Code Execution (Beta)
Python code generation and execution

```python
response = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "Calculate fibonacci(10) and plot it"}],
    extra_body={"tools": [{"type": "code_interpreter"}]}
)
```

**Note:** Code execution runs in a sandboxed environment.

### Tool Configuration

Tools can be configured via `extra_body`:

```python
response = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "Your query"}],
    extra_body={
        "tools": [
            {"type": "web_search"},
            {"type": "deep_research"}
        ],
        "tool_choice": "auto"  # or "required" or {"type": "function", "function": {"name": "tool_name"}}
    }
)
```

---

## 📊 Supported Models

### General Purpose
- `qwen-max-latest` - Latest flagship model
- `qwen-plus-latest` - Balanced performance/cost
- `qwen-turbo-latest` - Fast responses
- `qwen-long` - Extended context (up to 1M tokens)

### Specialized Models
- `qwen-vl-max` - Vision (image analysis)
- `qwen-vl-plus` - Vision (fast)
- `qwen-vl-ocr` - OCR specialized
- `qwen-audio` - Audio processing
- `qwen-deep-research` - Extended research

### Code Models
- `qwen-coder-plus` - Code generation
- `qwen-coder-turbo` - Fast code generation

### With Thinking/Search
Add suffixes to any model:
- `-thinking` - Chain-of-thought reasoning
- `-search` - Web search integration
- Example: `qwen-max-latest-thinking`

### Model Aliasing

The server supports flexible model naming:

```python
# All of these work:
client.chat.completions.create(model="gpt-4", ...)          # Maps to qwen-max-latest
client.chat.completions.create(model="qwen-max-latest", ...)
client.chat.completions.create(model="qwen3-max", ...)      # Also works
```

See [MODEL_ALIAS_SYSTEM.md](./MODEL_ALIAS_SYSTEM.md) for details.

---

## 🐳 Docker Deployment

### Using Docker Compose

```bash
# Create .env file
cat > .env << EOF
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password
PORT=7050
EOF

# Start server
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop server
docker-compose down
```

### Manual Docker

```bash
# Build image
docker build -t qwen-api .

# Run container
docker run -d \
  -p 7050:7050 \
  -e QWEN_EMAIL=your-email@example.com \
  -e QWEN_PASSWORD=your-password \
  --name qwen-api \
  qwen-api

# Check logs
docker logs -f qwen-api
```

---

## 🧪 Testing

The project includes comprehensive tests in the `tests/` directory:

```bash
# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/test_native_tools.py -v

# Run with coverage
pytest tests/ --cov=qwen_api --cov-report=html
```

### Test Files
- `test_client.py` - Basic client functionality
- `test_native_tools.py` - Native tools (web search, vision, research)
- `test_model_aliases.py` - Model aliasing system
- `test_no_tools.py` - Non-tool functionality
- `quick_test.py` - Quick smoke tests

---

## 🛠️ Development

### Setup Development Environment

```bash
# Clone and install in editable mode
git clone https://github.com/Zeeeepa/qwen-api
cd qwen-api
pip install -e ".[dev]"

# Install pre-commit hooks
pre-commit install

# Run linters
black py-api/
ruff check py-api/
mypy py-api/
```

### Project Structure

```
qwen-api/
├── py-api/
│   └── qwen_api/          # Main package
│       ├── __init__.py
│       ├── cli.py         # CLI interface
│       ├── api_server.py  # FastAPI server
│       ├── config_loader.py
│       ├── qwen_client.py
│       └── ...
├── scripts/
│   ├── all.sh            # One-command deploy
│   ├── setup.sh          # Setup script
│   ├── start.sh          # Start server
│   └── send_request.sh   # Test request
├── tests/                # Test suite
├── pyproject.toml        # Package metadata
├── .env.example          # Example config
└── README.md
```

---

## 🔍 Troubleshooting

### Token Extraction Fails

**Solution 1: Manual extraction**
1. Login to [qwen.aikit.club](https://qwen.aikit.club)
2. Open DevTools (F12) → Application → Local Storage
3. Find JWT token
4. Add to `.env`: `QWEN_BEARER_TOKEN=your-token`

**Solution 2: Update credentials**
```bash
qwen-api get-token --email new-email@example.com --password new-password
```

### Port Already in Use

```bash
# Check what's using the port
lsof -i :7050

# Use different port
qwen-api serve --port 8096
```

### Server Won't Start

```bash
# Check configuration
qwen-api info

# Check logs
tail -f logs/server.log

# Verify installation
qwen-api --version
```

### Playwright Browser Issues

```bash
# Reinstall browsers
playwright install chromium

# With system dependencies (Ubuntu/Debian)
playwright install --with-deps chromium
```

### Connection Timeout

- Check if server is running: `qwen-api health`
- Verify firewall settings
- Check `.env` configuration
- Ensure token is valid (re-run `qwen-api get-token`)

---

## 📚 Additional Documentation

- [Native Tools Documentation](./NATIVE_TOOLS.md) - Detailed tools guide
- [Model Alias System](./MODEL_ALIAS_SYSTEM.md) - Model mapping details
- [API Documentation](./docs/API.md) - Complete API reference

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

---

## 📝 License

MIT License - see [LICENSE](./LICENSE) file for details

---

## 🙏 Acknowledgments

- Built on [FastAPI](https://fastapi.tiangolo.com/)
- Uses [Playwright](https://playwright.dev/) for browser automation
- OpenAI client compatibility via [OpenAI Python SDK](https://github.com/openai/openai-python)

---

## 📧 Support

- GitHub Issues: [Report bugs](https://github.com/Zeeeepa/qwen-api/issues)
- Documentation: [Full docs](./docs/)
- Email: developer@pixelium.uk

---

<div align="center">

**Made with ❤️ for the AI community**

[⬆ Back to Top](#qwen-api---openai-compatible-api-server)

</div>

