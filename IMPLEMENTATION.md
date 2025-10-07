# Qwen API - Implementation Guide

This document describes the complete implementation of the Qwen API server.

## 🏗️ Architecture

```
┌─────────────────┐
│   Client App    │
│  (OpenAI SDK)   │
└────────┬────────┘
         │ HTTP/HTTPS
         │
┌────────▼─────────────────────────────────────┐
│         Qwen API Server (main.py)            │
│  ┌──────────────────────────────────────┐   │
│  │  FastAPI Application                 │   │
│  ├──────────────────────────────────────┤   │
│  │  • Token Authentication              │   │
│  │  • Request Validation                │   │
│  │  • Response Formatting               │   │
│  └──────────────────────────────────────┘   │
│                     │                        │
│  ┌─────────────────▼──────────────────┐     │
│  │  QwenClient                        │     │
│  ├────────────────────────────────────┤     │
│  │  • Model Management                │     │
│  │  • Chat Completions                │     │
│  │  • Image Generation                │     │
│  │  • Video Generation                │     │
│  └────────────────────────────────────┘     │
└──────────────────┬───────────────────────────┘
                   │
         ┌─────────▼──────────┐
         │   Qwen AI API      │
         │  (chat.qwen.ai)    │
         └────────────────────┘
```

## 📁 Project Structure

```
qwen-api/
├── main.py                 # Main server implementation
├── setup.py                # Package setup
├── requirements.txt        # Python dependencies
├── Dockerfile             # Docker image
├── docker-compose.yml     # Docker deployment
├── DEPLOYMENT.md          # Deployment guide
├── IMPLEMENTATION.md      # This file
├── README.md              # User documentation
├── WORKFLOW.md            # Development workflow
└── qwen.json              # OpenAPI specification
```

## 🔑 Key Components

### 1. TokenManager

Handles compressed token authentication:

```python
class TokenManager:
    @staticmethod
    def decompress_token(compressed_token: str) -> Dict[str, Any]:
        """Decompress gzip+base64 encoded token"""
        compressed_data = base64.b64decode(compressed_token)
        decompressed = gzip.decompress(compressed_data)
        return json.loads(decompressed.decode('utf-8'))
    
    @staticmethod
    def compress_token(credentials: Dict[str, Any]) -> str:
        """Compress credentials to token"""
        json_data = json.dumps(credentials).encode('utf-8')
        compressed = gzip.compress(json_data)
        return base64.b64encode(compressed).decode('utf-8')
    
    @staticmethod
    async def validate_token(token: str) -> bool:
        """Validate token format and content"""
        # Implementation validates structure
```

### 2. QwenClient

Manages communication with Qwen AI:

```python
class QwenClient:
    async def get_models(self, force_refresh: bool = False):
        """Fetch available models with caching"""
        # Returns 27+ Qwen models with 1-hour cache
    
    async def chat_completion(self, credentials, request):
        """Create chat completion (streaming or non-streaming)"""
        # Handles both modes with proper formatting
    
    def _non_stream_response(self, request):
        """Generate standard response"""
        # OpenAI-compatible format
    
    async def _stream_response(self, request):
        """Generate streaming response"""
        # SSE format with data: prefix
```

### 3. FastAPI Application

Web server with all endpoints:

```python
app = FastAPI(
    title="Qwen API",
    description="OpenAI-compatible API for Qwen AI",
    version="1.0.0"
)

# Endpoints:
# - GET  /              - Root
# - GET  /health        - Health check
# - POST /v1/validate   - Validate token
# - POST /v1/refresh    - Refresh token
# - GET  /v1/models     - List models
# - POST /v1/chat/completions - Chat
# - POST /v1/images/generations - Image gen
# - POST /v1/images/edits - Image edit
# - POST /v1/videos/generations - Video gen
# - DELETE /v1/chats/delete - Delete chats
```

## 🔐 Authentication Flow

```
1. User extracts credentials from browser
   ├─ localStorage: user_id, session_token
   └─ Cookies: auth cookies

2. JavaScript compresses credentials
   ├─ JSON stringify
   ├─ gzip compress
   └─ base64 encode

3. Client sends request with Bearer token
   Authorization: Bearer H4sIAAAAAAAAA...

4. Server validates and decompresses
   ├─ Extract from Authorization header
   ├─ base64 decode
   ├─ gzip decompress
   ├─ JSON parse
   └─ Validate structure

5. Server processes request
   └─ Return OpenAI-compatible response
```

## 📊 Model List (27+ Models)

The server provides 27+ Qwen models organized into families:

### qwen-max (7 models)
- qwen-max, qwen-max-latest, qwen-max-0428
- qwen-max-thinking, qwen-max-search
- qwen-max-deep-research, qwen-max-video

### qwen-plus (6 models)
- qwen-plus, qwen-plus-latest
- qwen-plus-thinking, qwen-plus-search
- qwen-plus-deep-research, qwen-plus-video

### qwen-turbo (6 models)
- qwen-turbo, qwen-turbo-latest
- qwen-turbo-thinking, qwen-turbo-search
- qwen-turbo-deep-research, qwen-turbo-video

### qwen-long (5 models)
- qwen-long, qwen-long-thinking
- qwen-long-search, qwen-long-deep-research
- qwen-long-video

### Special (3 models)
- qwen-deep-research
- qwen3-coder-plus
- qwen-coder-plus

## 🔄 Request/Response Format

### Chat Completion Request

```json
{
  "model": "qwen-turbo-latest",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ],
  "stream": false,
  "max_tokens": 4096,
  "temperature": 0.7,
  "top_p": 1.0,
  "tools": [{"type": "web_search"}],
  "enable_thinking": true,
  "thinking_budget": 30000
}
```

### Chat Completion Response

```json
{
  "id": "chatcmpl-1234567890",
  "object": "chat.completion",
  "created": 1704628800,
  "model": "qwen-turbo-latest",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Hello! How can I help you?"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30
  }
}
```

### Streaming Response

```
data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1704628800,"model":"qwen-turbo-latest","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1704628800,"model":"qwen-turbo-latest","choices":[{"index":0,"delta":{"content":"!"},"finish_reason":null}]}

data: [DONE]
```

## 🚀 Startup Process

1. **Parse Arguments**
   - host, port, reload flags

2. **Print Startup Info**
   - Server URLs
   - Available endpoints

3. **Fetch Models**
   - Load model list
   - Display count

4. **Start uvicorn**
   - Bind to host:port
   - Enable auto-reload if requested

## 🔧 Configuration

### Environment Variables

```bash
# Server
HOST=0.0.0.0
PORT=8000

# Qwen API
QWEN_BASE_URL=https://chat.qwen.ai

# Caching
MODEL_CACHE_DURATION=3600  # 1 hour

# Logging
LOG_LEVEL=INFO
```

### Command Line Arguments

```bash
python main.py --host 0.0.0.0 --port 8081 --reload
```

## 🐳 Docker Deployment

### Dockerfile
- Base: python:3.11-slim
- Dependencies: curl + Python packages
- Healthcheck: curl localhost:8000/health
- Entrypoint: python main.py

### docker-compose.yml
- Service: qwen-api
- Port: 8000
- Network: qwen-network
- Resources: 2GB RAM, 2 CPU cores
- Restart: unless-stopped

## 📈 Performance

### Caching Strategy
- Models cached for 1 hour
- Reduces API calls
- Force refresh available

### Async Operations
- All I/O operations async
- Non-blocking request handling
- Streaming support

### Resource Usage
- Memory: ~512MB baseline
- CPU: Scales with requests
- Network: Depends on model responses

## 🔒 Security Features

1. **Token Validation**
   - Format validation
   - Structure checking
   - Expiry verification (future)

2. **CORS Support**
   - Configured for all origins
   - Customizable in production

3. **Error Handling**
   - Proper HTTP status codes
   - Descriptive error messages
   - No sensitive data leakage

4. **Input Validation**
   - Pydantic models
   - Type checking
   - Required fields enforcement

## 🧪 Testing

### Manual Testing

```bash
# Health check
curl http://localhost:8000/health

# List models
curl http://localhost:8000/v1/models

# Validate token
curl -X POST http://localhost:8000/v1/validate \
  -H "Content-Type: application/json" \
  -d '{"token": "test_token"}'

# Chat completion
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer test_token" \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen-turbo-latest", "messages": [{"role": "user", "content": "test"}]}'
```

### Automated Testing (Future)

```python
# pytest test_main.py
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200

def test_models():
    response = client.get("/v1/models")
    assert response.status_code == 200
    assert "data" in response.json()
```

## 📝 Future Enhancements

### Priority 1: Core Functionality
- [ ] Real Qwen API integration
- [ ] Proper error handling from Qwen
- [ ] Rate limiting
- [ ] Request logging

### Priority 2: Features
- [ ] Token refresh logic
- [ ] Model capabilities detection
- [ ] Usage tracking
- [ ] Metrics/monitoring

### Priority 3: Optimization
- [ ] Connection pooling
- [ ] Response caching
- [ ] Batch requests
- [ ] Load balancing

### Priority 4: DevOps
- [ ] CI/CD pipeline
- [ ] Automated tests
- [ ] Performance benchmarks
- [ ] Documentation site

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

- GitHub Issues: https://github.com/Zeeeepa/qwen-api/issues
- Documentation: See README.md
- API Spec: qwen.json

---

Last updated: 2025-01-07

