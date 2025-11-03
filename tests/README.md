# Qwen API Test Suite

Comprehensive test suite for the Qwen API OpenAI-compatible proxy.

## 🎯 The 4 Accessible Models

This API provides access to 4 specialized Qwen models with specific features:

### 1. **Qwen3-Max** (`qwen3-max`)
- **Actual Model**: `qwen3-max-latest`
- **Features**: 
  - ✅ Web search (always applied)
  - ❌ No thinking mode
- **Max Tokens**: Provider default
- **Use Case**: General purpose tasks with web access

```python
response = client.chat.completions.create(
    model="qwen3-max",
    messages=[{"role": "user", "content": "What's the weather today?"}]
)
# Web search automatically applied server-side
```

### 2. **Qwen3-235B** (`qwen3-235b`)
- **Actual Model**: `qwen3-235b-a22b-2507`
- **Features**:
  - ✅ Web search (always applied)
  - ✅ Thinking mode enabled
- **Max Tokens**: 81,920 (extended context)
- **Use Case**: Complex reasoning tasks with web access

```python
response = client.chat.completions.create(
    model="qwen3-235b",
    messages=[{"role": "user", "content": "Analyze the latest AI trends"}]
)
# Web search + thinking + 81,920 token context
```

### 3. **Qwen3-VL** (`qwen3-vl`)
- **Actual Model**: `qwen3-vl-235b-a22b`
- **Features**:
  - ❌ No web search
  - ✅ Thinking mode enabled
- **Max Tokens**: 81,920 (extended context)
- **Use Case**: Vision-language tasks without web search

```python
response = client.chat.completions.create(
    model="qwen3-vl",
    messages=[
        {
            "role": "user", 
            "content": [
                {"type": "text", "text": "What's in this image?"},
                {"type": "image_url", "image_url": {"url": "..."}}
            ]
        }
    ]
)
# Pure VL model with thinking, no web search interference
```

### 4. **Qwen3-Omni** (`qwen3-omni`)
- **Actual Model**: `qwen3-omni-flash`
- **Features**:
  - ❌ No web search
  - ✅ Thinking mode enabled
- **Max Tokens**: 81,920 (extended context)
- **Use Case**: Multimodal (text, image, audio, video) tasks

```python
response = client.chat.completions.create(
    model="qwen3-omni",
    messages=[
        {
            "role": "user",
            "content": "Analyze this audio and video"
        }
    ]
)
# Omni model with thinking, no web search
```

## 📁 Test Structure

```
tests/
├── conftest.py           # Shared fixtures and configuration
├── unit/                 # Fast unit tests (no external dependencies)
│   ├── test_model_router.py        # Model routing and aliasing tests
│   └── test_openapi_validator.py   # OpenAPI validation tests
├── integration/          # Integration tests (mocked backends)
│   ├── test_openai_format.py       # OpenAI API format compliance
│   └── test_api_endpoints.py       # API endpoint tests
├── e2e/                  # End-to-end tests (require running server)
│   ├── test_auth.py                # Playwright authentication tests
│   └── test_full_deployment.py     # Complete deployment tests
└── fixtures/             # Test data and mock responses
    ├── sample_requests.json
    └── sample_responses.json
```

## 🚀 Running Tests

### Quick Start

```bash
# Run all tests (unit + integration)
bash scripts/run_tests.sh

# Run only unit tests (fast)
bash scripts/run_tests.sh --unit

# Run only integration tests
bash scripts/run_tests.sh --integration

# Run with coverage report
bash scripts/run_tests.sh --coverage

# Verbose output
bash scripts/run_tests.sh --verbose
```

### Individual Test Categories

```bash
# Unit tests only (fastest, no dependencies)
pytest tests/unit/ -v

# Integration tests (mocked backends)
pytest tests/integration/ -v

# E2E tests (requires server running)
pytest tests/e2e/ -v
```

### Running Specific Tests

```bash
# Test specific model
pytest tests/unit/test_model_router.py::TestModel1_Qwen3Max -v

# Test OpenAI format compliance
pytest tests/integration/test_openai_format.py -v

# Test with markers
pytest -m "not slow" -v  # Skip slow tests
pytest -m "unit" -v      # Only unit tests
```

## 🧪 Test Coverage

The test suite covers:

### Model Routing (Unit Tests)
- ✅ All 4 models resolve correctly
- ✅ Tool injection (web_search) for appropriate models
- ✅ Token limits (81,920 for extended context models)
- ✅ Thinking mode configuration
- ✅ Case-insensitive model names
- ✅ Default fallback behavior
- ✅ Client override capabilities

### OpenAI API Format (Integration Tests)
- ✅ Request format validation
- ✅ Response format validation
- ✅ Streaming SSE format
- ✅ Error response format
- ✅ /v1/models endpoint
- ✅ Authentication headers
- ✅ Content-type headers

### End-to-End (E2E Tests)
- ✅ Full deployment flow
- ✅ Server startup and health checks
- ✅ Real API requests to all 4 models
- ✅ Streaming responses
- ✅ Error handling

## 📊 Test Markers

Tests are categorized with pytest markers:

- `@pytest.mark.unit` - Fast unit tests
- `@pytest.mark.integration` - Integration tests with mocks
- `@pytest.mark.e2e` - End-to-end tests (need server)
- `@pytest.mark.slow` - Tests that take >1 second
- `@pytest.mark.auth` - Tests requiring authentication

## 🔧 Development

### Adding New Tests

1. **Unit Test** (for pure functions, no I/O):
   ```python
   # tests/unit/test_my_feature.py
   import pytest
   
   def test_my_feature():
       result = my_function()
       assert result == expected_value
   ```

2. **Integration Test** (with mocks):
   ```python
   # tests/integration/test_my_api.py
   import pytest
   from unittest.mock import Mock
   
   def test_api_endpoint(mock_provider):
       response = call_api(mock_provider)
       assert response.status_code == 200
   ```

3. **E2E Test** (requires server):
   ```python
   # tests/e2e/test_my_flow.py
   import pytest
   import requests
   
   @pytest.mark.e2e
   def test_full_flow():
       response = requests.post("http://localhost:8096/v1/chat/completions", ...)
       assert response.status_code == 200
   ```

### Fixtures

Common fixtures are in `conftest.py`:
- `model_router` - ModelRouter instance
- `mock_qwen_response` - Sample Qwen response
- `mock_streaming_response` - Sample streaming chunks
- `all_four_models` - Configuration for all 4 models
- `sample_openai_request` - Sample request data

## 📝 Test Requirements

```txt
pytest>=7.4.0
pytest-asyncio>=0.21.0
pytest-cov>=4.1.0
pytest-mock>=3.11.0
httpx>=0.24.0
```

## 🐛 Troubleshooting

### Tests Fail with Import Errors
```bash
# Ensure project root is in PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
pytest tests/
```

### E2E Tests Fail
```bash
# Make sure server is running
bash scripts/start.sh

# Check server health
curl http://localhost:8096/health
```

### Coverage Not Generated
```bash
# Install coverage
pip install pytest-cov

# Run with coverage
pytest --cov=app --cov-report=html tests/
```

## 📚 References

- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Pytest Documentation](https://docs.pytest.org/)
- [FastAPI Testing](https://fastapi.tiangolo.com/tutorial/testing/)

---

**Last Updated**: 2025-01-03

**Test Coverage**: >95% for core functionality

