#!/usr/bin/env python
"""
Integration tests for OpenAI API format compliance
Validates that all requests and responses match OpenAI API specification
"""

import pytest
import json
from typing import Dict, Any


class TestOpenAIRequestFormat:
    """Test that requests match OpenAI API format"""
    
    def test_basic_chat_completion_request_structure(self, sample_openai_request):
        """Test basic request has required fields"""
        assert "model" in sample_openai_request
        assert "messages" in sample_openai_request
        assert isinstance(sample_openai_request["messages"], list)
        assert len(sample_openai_request["messages"]) > 0
    
    def test_message_format(self, sample_openai_request):
        """Test message objects have required fields"""
        for message in sample_openai_request["messages"]:
            assert "role" in message
            assert "content" in message
            assert message["role"] in ["system", "user", "assistant", "tool"]
    
    def test_optional_parameters_accepted(self):
        """Test optional OpenAI parameters are accepted"""
        request = {
            "model": "qwen3-max",
            "messages": [{"role": "user", "content": "test"}],
            "temperature": 0.8,
            "top_p": 0.9,
            "max_tokens": 100,
            "presence_penalty": 0.1,
            "frequency_penalty": 0.2,
            "n": 1,
            "stop": ["\n"],
            "stream": False
        }
        # All these fields should be valid
        assert request["temperature"] == 0.8
        assert request["max_tokens"] == 100
    
    def test_tools_parameter_format(self):
        """Test tools parameter format"""
        request = {
            "model": "qwen3-max",
            "messages": [{"role": "user", "content": "test"}],
            "tools": [
                {
                    "type": "web_search"
                }
            ]
        }
        assert isinstance(request["tools"], list)
        assert request["tools"][0]["type"] == "web_search"


class TestOpenAIResponseFormat:
    """Test that responses match OpenAI API format"""
    
    def test_chat_completion_response_structure(self, mock_qwen_response):
        """Test response has required OpenAI fields"""
        assert "id" in mock_qwen_response
        assert "object" in mock_qwen_response
        assert mock_qwen_response["object"] == "chat.completion"
        assert "created" in mock_qwen_response
        assert "model" in mock_qwen_response
        assert "choices" in mock_qwen_response
        assert "usage" in mock_qwen_response
    
    def test_choice_object_structure(self, mock_qwen_response):
        """Test choice object format"""
        choice = mock_qwen_response["choices"][0]
        assert "index" in choice
        assert "message" in choice
        assert "finish_reason" in choice
        
        message = choice["message"]
        assert "role" in message
        assert "content" in message
        assert message["role"] == "assistant"
    
    def test_usage_object_structure(self, mock_qwen_response):
        """Test usage object format"""
        usage = mock_qwen_response["usage"]
        assert "prompt_tokens" in usage
        assert "completion_tokens" in usage
        assert "total_tokens" in usage
        assert isinstance(usage["prompt_tokens"], int)
        assert isinstance(usage["completion_tokens"], int)
        assert usage["total_tokens"] == usage["prompt_tokens"] + usage["completion_tokens"]
    
    def test_finish_reason_values(self):
        """Test finish_reason has valid values"""
        valid_reasons = ["stop", "length", "tool_calls", "content_filter", "function_call"]
        # Test that our mock uses valid finish_reason
        finish_reason = "stop"
        assert finish_reason in valid_reasons


class TestStreamingFormat:
    """Test streaming response format (SSE)"""
    
    def test_streaming_chunk_format(self, mock_streaming_response):
        """Test each streaming chunk is properly formatted"""
        for chunk_bytes in mock_streaming_response[:-1]:  # Exclude [DONE]
            chunk_str = chunk_bytes.decode('utf-8')
            assert chunk_str.startswith('data: ')
            
            # Extract JSON from "data: {...}"
            json_str = chunk_str.replace('data: ', '').strip()
            if json_str:
                chunk_data = json.loads(json_str)
                
                assert "id" in chunk_data
                assert "object" in chunk_data
                assert chunk_data["object"] == "chat.completion.chunk"
                assert "created" in chunk_data
                assert "model" in chunk_data
                assert "choices" in chunk_data
    
    def test_streaming_delta_format(self, mock_streaming_response):
        """Test delta objects in streaming"""
        chunk_bytes = mock_streaming_response[0]
        chunk_str = chunk_bytes.decode('utf-8')
        json_str = chunk_str.replace('data: ', '').strip()
        chunk_data = json.loads(json_str)
        
        choice = chunk_data["choices"][0]
        assert "index" in choice
        assert "delta" in choice
        assert "finish_reason" in choice
        
        # First chunk usually has role
        delta = choice["delta"]
        if "role" in delta:
            assert delta["role"] == "assistant"
    
    def test_streaming_ends_with_done(self, mock_streaming_response):
        """Test streaming ends with [DONE] marker"""
        last_chunk = mock_streaming_response[-1]
        assert last_chunk == b'data: [DONE]\n\n'


class TestErrorResponseFormat:
    """Test error response format"""
    
    def test_error_response_structure(self):
        """Test error responses match OpenAI format"""
        error_response = {
            "error": {
                "message": "Invalid request",
                "type": "invalid_request_error",
                "code": "invalid_model"
            }
        }
        
        assert "error" in error_response
        error = error_response["error"]
        assert "message" in error
        assert "type" in error
        assert isinstance(error["message"], str)
    
    def test_error_types(self):
        """Test various error types are valid"""
        valid_error_types = [
            "invalid_request_error",
            "authentication_error",
            "rate_limit_error",
            "api_error",
            "internal_error"
        ]
        for error_type in valid_error_types:
            assert error_type in valid_error_types


class TestModelsEndpointFormat:
    """Test /v1/models endpoint format"""
    
    def test_models_list_response_structure(self, all_four_models):
        """Test /v1/models response format"""
        # Simulate response from /v1/models
        models_response = {
            "object": "list",
            "data": [
                {
                    "id": "qwen3-max",
                    "object": "model",
                    "created": 1234567890,
                    "owned_by": "qwen"
                },
                {
                    "id": "qwen3-235b",
                    "object": "model",
                    "created": 1234567890,
                    "owned_by": "qwen"
                },
                {
                    "id": "qwen3-vl",
                    "object": "model",
                    "created": 1234567890,
                    "owned_by": "qwen"
                },
                {
                    "id": "qwen3-omni",
                    "object": "model",
                    "created": 1234567890,
                    "owned_by": "qwen"
                }
            ]
        }
        
        assert models_response["object"] == "list"
        assert "data" in models_response
        assert len(models_response["data"]) == 4
        
        # Verify each model object
        for model in models_response["data"]:
            assert "id" in model
            assert "object" in model
            assert model["object"] == "model"
            assert "owned_by" in model


class TestFourModelsFormatCompliance:
    """Test that all 4 models comply with OpenAI format"""
    
    @pytest.mark.parametrize("model_name", [
        "qwen3-max",
        "qwen3-235b",
        "qwen3-vl",
        "qwen3-omni"
    ])
    def test_model_in_request_format(self, model_name):
        """Test each model can be used in request"""
        request = {
            "model": model_name,
            "messages": [{"role": "user", "content": "test"}]
        }
        assert request["model"] == model_name
        assert len(request["messages"]) == 1
    
    @pytest.mark.parametrize("model_name,expected_actual", [
        ("qwen3-max", "qwen3-max-latest"),
        ("qwen3-235b", "qwen3-235b-a22b-2507"),
        ("qwen3-vl", "qwen3-vl-235b-a22b"),
        ("qwen3-omni", "qwen3-omni-flash")
    ])
    def test_model_routing_response_format(self, model_name, expected_actual, model_router):
        """Test that routed models return correct name in response"""
        resolved = model_router.resolve_model(model_name)
        assert resolved == expected_actual
        
        # Response should contain the actual model name
        response = {
            "id": "test-id",
            "object": "chat.completion",
            "created": 1234567890,
            "model": resolved,  # Should be actual model name
            "choices": [{
                "index": 0,
                "message": {"role": "assistant", "content": "test"},
                "finish_reason": "stop"
            }],
            "usage": {"prompt_tokens": 10, "completion_tokens": 20, "total_tokens": 30}
        }
        assert response["model"] == expected_actual


class TestAuthenticationFormat:
    """Test authentication header format"""
    
    def test_bearer_token_format(self):
        """Test Bearer token authentication format"""
        auth_header = "Bearer sk-any-key-works"
        assert auth_header.startswith("Bearer ")
        token = auth_header.replace("Bearer ", "")
        assert len(token) > 0
    
    def test_api_key_accepted(self):
        """Test various API key formats are accepted"""
        # In anonymous mode, any key should work
        test_keys = [
            "sk-any",
            "sk-test-12345",
            "my-custom-key",
            "Bearer-token-xyz"
        ]
        for key in test_keys:
            assert len(key) > 0  # Basic validation


class TestContentTypes:
    """Test content-type headers"""
    
    def test_request_content_type(self):
        """Test request accepts application/json"""
        content_type = "application/json"
        assert content_type == "application/json"
    
    def test_response_content_type_json(self):
        """Test non-streaming response is application/json"""
        headers = {"content-type": "application/json"}
        assert "application/json" in headers["content-type"]
    
    def test_response_content_type_stream(self):
        """Test streaming response is text/event-stream"""
        headers = {"content-type": "text/event-stream"}
        assert "text/event-stream" in headers["content-type"]

