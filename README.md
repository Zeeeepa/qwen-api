# Qwen API - OpenAI Compatible API Gateway

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)

Transform Qwen's powerful AI models into an OpenAI-compatible API with intelligent model routing, automatic tool injection, and server-side feature management.

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api

# 2. Set credentials
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"

# 3. Setup (one command!)
bash scripts/setup.sh

# 4. Start server (automatically tests all endpoints!)
bash scripts/start.sh
```

**That's it!** The server will:
- ✅ Start automatically on port 8096
- ✅ Show network IP for LAN access
- ✅ Test all 4 model endpoints
- ✅ Display configuration and usage examples

---

## 🤖 Available Models

Four powerful models with server-side defaults - clients don't need to specify tools or thinking mode:

### 1. Qwen3 / Qwen3-Max (Fast + Current)
```python
model = "qwen3"  # or "qwen3-max"
# Server automatically applies: web_search
# Thinking: ❌ Disabled (fast responses)
# Max Tokens: Provider default
```
**Best for:** Current events, news, fast Q&A with web verification

### 2. Qwen3-Web / Qwen3-235B (Deep Research)
```python
model = "qwen3-web"  # or "qwen3-235b"
# Server automatically applies: web_search + thinking
# Thinking: ✅ Enabled
# Max Tokens: 81,920 (extended context)
```
**Best for:** Complex reasoning with internet, multi-step analysis, research

### 3. Qwen3-VL (Vision-Language)
```python
model = "qwen3-vl"
# Server automatically applies: thinking (NO web_search)
# Thinking: ✅ Enabled
# Max Tokens: 81,920 (extended context)
```
**Best for:** Image analysis, visual question answering, document interpretation

### 4. Qwen3-Omni (Multimodal)
```python
model = "qwen3-omni"
# Server automatically applies: thinking (NO web_search)
# Thinking: ✅ Enabled
# Max Tokens: 81,920 (extended context)
```
**Best for:** Text + Image + Audio + Video, cross-modal understanding

---

## 💻 Usage Examples

### Python (OpenAI SDK)

```python
from openai import OpenAI

# Local usage
client = OpenAI(
    api_key="sk-any",  # Any non-empty string works
    base_url="http://localhost:8096/v1"
)

# Network usage (use IP shown by start.sh)
client = OpenAI(
    api_key="sk-any",
    base_url="http://192.168.1.100:8096/v1"  # Your network IP
)

# Example 1: Fast Q&A with web search
response = client.chat.completions.create(
    model="qwen3",  # Server auto-applies web_search
    messages=[
        {"role": "user", "content": "What's new in AI today?"}
    ]
)
print(response.choices[0].message.content)

# Example 2: Complex reasoning with web + thinking
response = client.chat.completions.create(
    model="qwen3-web",  # Server auto-applies web_search + thinking
    messages=[
        {"role": "user", "content": "Analyze the impact of quantum computing on cryptography"}
    ]
)
print(response.choices[0].message.content)

# Example 3: Image analysis (Vision-Language)
response = client.chat.completions.create(
    model="qwen3-vl",  # Server auto-applies thinking, NO web
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "What architectural style is this?"},
                {"type": "image_url", "image_url": {"url": "https://example.com/building.jpg"}}
            ]
        }
    ]
)
print(response.choices[0].message.content)

# Example 4: Multimodal analysis
response = client.chat.completions.create(
    model="qwen3-omni",  # Server auto-applies thinking, NO web
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "Analyze this presentation"},
                {"type": "image_url", "image_url": {"url": "https://example.com/slide.jpg"}},
                # Audio and video support coming soon
            ]
        }
    ]
)
print(response.choices[0].message.content)
```

### cURL

```bash
# Test endpoint
curl http://localhost:8096/health

# List models
curl http://localhost:8096/v1/models \
  -H "Authorization: Bearer sk-any"

# Chat completion (qwen3)
curl http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-any" \
  -d '{
    "model": "qwen3",
    "messages": [
      {"role": "user", "content": "What are the latest AI developments?"}
    ]
  }'

# Chat completion with streaming (qwen3-web)
curl http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-any" \
  -d '{
    "model": "qwen3-web",
    "messages": [
      {"role": "user", "content": "Explain quantum entanglement"}
    ],
    "stream": true
  }'
```

---

## 📋 Project Structure

```
qwen-api/
├── app/                      # Application code
│   ├── __init__.py
│   ├── core/                # Core functionality
│   ├── models/              # Data models
│   ├── providers/           # Provider integrations
│   ├── utils/               # Utilities
│   ├── cli.py              # CLI interface
│   └── model_router.py     # Intelligent routing
├── bin/                      # Executable scripts
│   ├── demo_4_models.py    # Model configuration demo
│   ├── extract_qwen_token.py  # Token extraction
│   ├── main.py             # Main application
│   ├── setup.py            # Setup utilities
│   └── start.py            # Server startup
├── docs/                     # Documentation
│   ├── DEPLOYMENT.md       # Deployment guide
│   ├── GET_TOKEN.md        # Token extraction guide
│   ├── INSTALL.md          # Installation guide
│   ├── MODELS.md           # Model specifications
│   └── QUICKSTART.md       # Quick start guide
├── scripts/                  # Deployment scripts
│   ├── setup.sh            # Complete environment setup
│   ├── start.sh            # Start server & test endpoints
│   ├── send_request.sh     # Send test requests
│   └── deploy_qwen_api.sh  # Full deployment
├── tests/                    # Test suite
│   ├── unit/               # Unit tests
│   ├── integration/        # Integration tests
│   ├── e2e/                # End-to-end tests
│   └── conftest.py         # Test configuration
├── .env.example             # Environment template
├── .gitignore              # Git ignore rules
├── LICENSE                 # MIT License
├── Makefile                # Make commands
├── README.md               # This file
├── pyproject.toml          # Python project config
├── pytest.ini              # Pytest configuration
├── qwen.json               # API specification
└── requirements.txt        # Python dependencies
```

---

## ⚙️ Configuration

### Environment Variables

Create a `.env` file or set environment variables:

```bash
# Required for token extraction
QWEN_EMAIL=your@email.com
QWEN_PASSWORD=yourpassword

# Optional server configuration
PORT=8096                    # Server port (default: 8096)
HOST=0.0.0.0                # Server host (default: 0.0.0.0)
LOG_LEVEL=INFO              # Logging level (default: INFO)
```

### Model Routing

The server automatically routes model aliases to actual Qwen models with server-side features:

| Client Request | Actual Model | Web Search | Thinking | Max Tokens |
|----------------|--------------|------------|----------|------------|
| `qwen3` or `qwen3-max` | `qwen3-max-latest` | ✅ Auto-injected | ❌ Disabled | Default |
| `qwen3-web` or `qwen3-235b` | `qwen3-235b-a22b-2507` | ✅ Auto-injected | ✅ Enabled | 81,920 |
| `qwen3-vl` | `qwen3-vl-235b-a22b` | ❌ Not applied | ✅ Enabled | 81,920 |
| `qwen3-omni` | `qwen3-omni-flash` | ❌ Not applied | ✅ Enabled | 81,920 |

**Key Features:**
- ✅ Server-side tool injection (clients don't need to specify)
- ✅ Automatic thinking mode configuration
- ✅ Token limit management
- ✅ Case-insensitive model names
- ✅ Backward compatible with all aliases

---

## 🧪 Testing

### Run All Tests

```bash
# Run complete test suite
pytest tests/ -v

# Run specific test categories
pytest tests/unit/ -v           # Unit tests
pytest tests/integration/ -v    # Integration tests
pytest tests/e2e/ -v           # End-to-end tests

# Run with coverage
pytest tests/ --cov=app --cov-report=html
```

### Run Standalone Tests

```bash
# Test all 4 model configurations
python bin/demo_4_models.py

# Test endpoint behavior
python tests/test_endpoint_behavior_standalone.py

# Send test request
bash scripts/send_request.sh
```

### Manual Testing

The `start.sh` script automatically tests all 4 endpoints when starting:

```bash
bash scripts/start.sh

# Output shows test results:
# ✅ qwen3 → qwen3-max-latest
# ✅ qwen3-web → qwen3-235b-a22b-2507
# ✅ qwen3-vl → qwen3-vl-235b-a22b
# ✅ qwen3-omni → qwen3-omni-flash
```

---

## 🚀 Deployment

### Local Development

```bash
# Setup and start in one go
bash scripts/setup.sh && bash scripts/start.sh
```

### Production Deployment

```bash
# Use the comprehensive deployment script
bash scripts/deploy_qwen_api.sh
```

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed deployment options including:
- Docker deployment
- systemd service setup
- Nginx reverse proxy
- SSL/TLS configuration

---

## 📚 Documentation

- **[Quick Start Guide](docs/QUICKSTART.md)** - Get started in 5 minutes
- **[Installation Guide](docs/INSTALL.md)** - Detailed installation instructions
- **[Model Specifications](docs/MODELS.md)** - Complete model documentation
- **[Token Extraction](docs/GET_TOKEN.md)** - How to get your Bearer token
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Production deployment

---

## 🔧 Development

### Setup Development Environment

```bash
# Clone and setup
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install Playwright browsers
playwright install chromium --with-deps

# Extract token (if credentials set)
python bin/extract_qwen_token.py

# Run in development mode
python bin/start.py
```

### Make Commands

```bash
make setup          # Setup environment
make start          # Start server
make test           # Run tests
make clean          # Clean cache files
make format         # Format code
make lint           # Lint code
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Qwen](https://qwen.ai/) - For providing powerful AI models
- [OpenAI](https://openai.com/) - For the API specification standard
- [FastAPI](https://fastapi.tiangolo.com/) - For the excellent web framework
- [Playwright](https://playwright.dev/) - For browser automation

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Zeeeepa/qwen-api/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Zeeeepa/qwen-api/discussions)

---

## 🌟 Star History

If you find this project useful, please consider giving it a ⭐ on GitHub!

---

**Built with ❤️ by the Qwen API community**

