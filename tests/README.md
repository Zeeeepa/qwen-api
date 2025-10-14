# Qwen API Tests

This directory contains all tests for the Qwen API project.

## Structure

```
tests/
├── __init__.py
├── README.md (this file)
├── conftest.py (pytest configuration)
├── unit/
│   ├── __init__.py
│   ├── test_configs.py (configuration tests)
│   └── test_qwen_provider.py (provider unit tests)
└── integration/
    ├── __init__.py
    ├── test_auth.py (authentication integration tests)
    └── test_openai_client.py (OpenAI client integration tests)
```

## Test Categories

### Unit Tests (`unit/`)
Fast tests that don't require external dependencies:
- Configuration parsing
- Provider initialization
- Internal logic

**Run**: `pytest tests/unit/ -v`

### Integration Tests (`integration/`)
Tests that require external services:
- Qwen API authentication (Playwright)
- OpenAI client compatibility
- End-to-end API calls

**Run**: `pytest tests/integration/ -v`

## Running Tests

### All tests:
```bash
pytest tests/
```

### Specific category:
```bash
pytest tests/unit/        # Fast unit tests only
pytest tests/integration/ # Integration tests only
```

### Single test file:
```bash
pytest tests/integration/test_auth.py -v
```

### With coverage:
```bash
pytest tests/ --cov=app --cov-report=html
```

## Requirements

Tests require:
- Python 3.8+
- pytest
- pytest-asyncio
- Playwright (for integration tests)
- OpenAI client (for API compatibility tests)

Install with:
```bash
pip install -r requirements.txt
playwright install chromium
```

## Environment Variables

Integration tests may require:
```bash
export QWEN_EMAIL="your-email@example.com"
export QWEN_PASSWORD="your-password"
export QWEN_BEARER_TOKEN="your-token"  # Optional if using automated extraction
```

See `.env.example` for complete list.

