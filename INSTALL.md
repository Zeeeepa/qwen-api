# Qwen API - Installation Guide

## Quick Start

### 1. Install as Package

The easiest way to use Qwen API is to install it as a Python package:

```bash
# Clone the repository
git clone https://github.com/Zeeeepa/qwen-api
cd qwen-api

# Install in editable mode
pip install -e .

# Or using uv (recommended for faster installs)
uv pip install -e .
```

### 2. Set Up Environment

Create a `.env` file in the project root:

```bash
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password
QWEN_BEARER_TOKEN=  # Will be auto-extracted
SERVER_PORT=8096
SERVER_HOST=0.0.0.0
```

### 3. Extract Token (One-time Setup)

```bash
qwen-api get-token --email your-email@example.com --password your-password
```

Or use environment variables:

```bash
export QWEN_EMAIL=your-email@example.com
export QWEN_PASSWORD=your-password
qwen-api get-token
```

### 4. Start the Server

```bash
qwen-api serve
```

With custom options:

```bash
qwen-api serve --host 0.0.0.0 --port 8096 --reload
```

## CLI Commands

### `qwen-api serve`
Start the API server

Options:
- `--host`: Host to bind to (default: from .env or 0.0.0.0)
- `--port`: Port to bind to (default: from .env or 8096)
- `--reload`: Enable auto-reload for development
- `--workers`: Number of worker processes
- `--log-level`: Log level (debug, info, warning, error)

### `qwen-api health`
Check if the server is running

### `qwen-api get-token`
Extract Qwen authentication token

Options:
- `--email`: Qwen account email
- `--password`: Qwen account password

### `qwen-api info`
Display server configuration

## Alternative: Using Shell Scripts

For those who prefer the traditional approach:

```bash
# One-command deployment
bash scripts/all.sh

# Or step by step:
bash scripts/setup.sh   # Setup environment
bash scripts/start.sh   # Start server
bash scripts/send_request.sh  # Test the API
```

## Usage with OpenAI Client

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",  # Any key works!
    base_url="http://localhost:8096/v1"
)

result = client.chat.completions.create(
    model="qwen3-coder-plus",  # Any model works!
    messages=[{"role": "user", "content": "Write a haiku about code."}]
)

print(result.choices[0].message.content)
```

## Development

Install with dev dependencies:

```bash
pip install -e ".[dev]"
```

Run tests:

```bash
pytest
```

Format code:

```bash
black py-api/
ruff check py-api/
```

## Troubleshooting

### Token Extraction Fails

If automatic token extraction fails, you can manually get the token:
1. Login to https://qwen.aikit.club
2. Open browser DevTools (F12)
3. Go to Application → Local Storage
4. Find the JWT token
5. Add it to your `.env` file as `QWEN_BEARER_TOKEN`

### Server Won't Start

1. Check if port is already in use:
   ```bash
   lsof -i :8096
   ```

2. Verify installation:
   ```bash
   qwen-api info
   ```

3. Check logs:
   ```bash
   tail -f logs/server.log
   ```

## Features

✅ OpenAI-compatible API  
✅ Multiple model support  
✅ Native tool/function calling  
✅ Thinking mode  
✅ Streaming support  
✅ Model aliasing system  
✅ Automatic feature injection  

## License

MIT License - see LICENSE file for details

