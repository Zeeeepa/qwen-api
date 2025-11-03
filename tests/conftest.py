#!/usr/bin/env python
"""
Pytest configuration and shared fixtures for all tests
"""

import pytest
import sys
from pathlib import Path
from typing import Dict, Any
from unittest.mock import Mock, AsyncMock

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


@pytest.fixture
def mock_qwen_response():
    """Mock Qwen API response"""
    return {
        "id": "test-completion-id",
        "object": "chat.completion",
        "created": 1234567890,
        "model": "qwen3-max-latest",
        "choices": [
            {
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": "This is a test response from Qwen."
                },
                "finish_reason": "stop"
            }
        ],
        "usage": {
            "prompt_tokens": 10,
            "completion_tokens": 20,
            "total_tokens": 30
        }
    }


@pytest.fixture
def mock_streaming_response():
    """Mock streaming SSE response"""
    return [
        b'data: {"id":"test","object":"chat.completion.chunk","created":1234567890,"model":"qwen3-max-latest","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"},"finish_reason":null}]}\n\n',
        b'data: {"id":"test","object":"chat.completion.chunk","created":1234567890,"model":"qwen3-max-latest","choices":[{"index":0,"delta":{"content":" world"},"finish_reason":null}]}\n\n',
        b'data: {"id":"test","object":"chat.completion.chunk","created":1234567890,"model":"qwen3-max-latest","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}\n\n',
        b'data: [DONE]\n\n'
    ]


@pytest.fixture
def sample_openai_request():
    """Sample OpenAI-compatible request"""
    return {
        "model": "qwen3-max",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Hello, how are you?"}
        ],
        "temperature": 0.7,
        "max_tokens": 100,
        "stream": False
    }


@pytest.fixture
def sample_openai_streaming_request():
    """Sample OpenAI-compatible streaming request"""
    return {
        "model": "qwen3-235b",
        "messages": [
            {"role": "user", "content": "Tell me a story."}
        ],
        "stream": True
    }


@pytest.fixture
def all_four_models():
    """The 4 accessible models with their configurations"""
    return {
        "qwen3-max": {
            "actual_model": "qwen3-max-latest",
            "tools": ["web_search"],
            "max_tokens": None,
            "thinking": False
        },
        "qwen3-235b": {
            "actual_model": "qwen3-235b-a22b-2507",
            "tools": ["web_search"],
            "max_tokens": 81920,
            "thinking": True
        },
        "qwen3-vl": {
            "actual_model": "qwen3-vl-235b-a22b",
            "tools": [],
            "max_tokens": 81920,
            "thinking": True
        },
        "qwen3-omni": {
            "actual_model": "qwen3-omni-flash",
            "tools": [],
            "max_tokens": 81920,
            "thinking": True
        }
    }


@pytest.fixture
def mock_bearer_token():
    """Mock bearer token"""
    return "mock_bearer_token_12345"


@pytest.fixture
def mock_qwen_provider(mock_bearer_token):
    """Mock Qwen provider"""
    from app.providers.qwen_simple_proxy import QwenSimpleProxy
    from unittest.mock import Mock, AsyncMock
    
    provider = Mock(spec=QwenSimpleProxy)
    provider.chat_completion = AsyncMock(return_value={
        "id": "test-id",
        "object": "chat.completion",
        "created": 1234567890,
        "model": "qwen3-max-latest",
        "choices": [{
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "Test response"
            },
            "finish_reason": "stop"
        }],
        "usage": {
            "prompt_tokens": 10,
            "completion_tokens": 20,
            "total_tokens": 30
        }
    })
    return provider


@pytest.fixture
def model_router():
    """Model router instance"""
    from app.model_router import ModelRouter
    return ModelRouter()


@pytest.fixture
def openai_validator():
    """OpenAPI validator instance"""
    from app.middleware.openapi_validator import OpenAPIValidator
    # Use qwen.json if it exists
    import os
    spec_path = "qwen.json" if os.path.exists("qwen.json") else None
    if spec_path:
        return OpenAPIValidator(spec_path)
    return None


# Test markers
def pytest_configure(config):
    """Configure custom pytest markers"""
    config.addinivalue_line(
        "markers", "unit: Unit tests (fast, no external dependencies)"
    )
    config.addinivalue_line(
        "markers", "integration: Integration tests (may use mocks)"
    )
    config.addinivalue_line(
        "markers", "e2e: End-to-end tests (require running server)"
    )
    config.addinivalue_line(
        "markers", "slow: Slow tests (may take >1s)"
    )
    config.addinivalue_line(
        "markers", "auth: Tests that require authentication"
    )

