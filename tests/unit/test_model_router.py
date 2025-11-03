#!/usr/bin/env python
"""
Unit tests for Model Router - The 4 Accessible Models
Tests the intelligent model routing with aliases and tool injection
"""

import pytest
from app.model_router import ModelRouter, MODEL_CONFIGS, KNOWN_QWEN_MODELS


class TestModelRouterBasics:
    """Test basic model router functionality"""
    
    def test_router_initialization(self, model_router):
        """Test that router initializes correctly"""
        assert model_router is not None
        assert len(model_router._config_lookup) == len(MODEL_CONFIGS)
        assert len(model_router._known_models) == len(KNOWN_QWEN_MODELS)
    
    def test_model_configs_has_four_models(self):
        """Test that we have exactly 4 accessible models configured"""
        # Exclude _default
        accessible_models = [k for k in MODEL_CONFIGS.keys() if k != "_default"]
        assert len(accessible_models) == 4
        assert "qwen3-max" in MODEL_CONFIGS
        assert "qwen3-235b" in MODEL_CONFIGS
        assert "qwen3-vl" in MODEL_CONFIGS
        assert "qwen3-omni" in MODEL_CONFIGS


class TestModel1_Qwen3Max:
    """Test Model 1: Qwen3-Max (no thinking, web search always applied)"""
    
    def test_qwen3_max_configuration(self):
        """Test Qwen3-Max has correct configuration"""
        config = MODEL_CONFIGS["qwen3-max"]
        assert config["actual_model"] == "qwen3-max-latest"
        assert config["tools"] == ["web_search"]
        assert config["max_tokens"] is None
        assert config["thinking"] is False
    
    def test_qwen3_max_resolves_correctly(self, model_router):
        """Test that qwen3-max resolves to qwen3-max-latest"""
        result = model_router.resolve_model("qwen3-max")
        assert result == "qwen3-max-latest"
    
    def test_qwen3_max_case_insensitive(self, model_router):
        """Test case-insensitive resolution"""
        assert model_router.resolve_model("QWEN3-MAX") == "qwen3-max-latest"
        assert model_router.resolve_model("Qwen3-Max") == "qwen3-max-latest"
        assert model_router.resolve_model("qwen3_max") == "qwen3-max-latest"
    
    def test_qwen3_max_auto_injects_web_search(self, model_router):
        """Test that web_search is automatically injected"""
        tools = model_router.get_default_tools("qwen3-max", existing_tools=None)
        assert tools is not None
        assert len(tools) == 1
        assert tools[0]["type"] == "web_search"
    
    def test_qwen3_max_respects_client_tools(self, model_router):
        """Test that client-specified tools are not overridden"""
        client_tools = [{"type": "custom_tool"}]
        tools = model_router.get_default_tools("qwen3-max", existing_tools=client_tools)
        assert tools == client_tools
    
    def test_qwen3_max_no_max_tokens(self, model_router):
        """Test that max_tokens is None (provider default)"""
        max_tokens = model_router.get_max_tokens("qwen3-max", client_max_tokens=None)
        assert max_tokens is None


class TestModel2_Qwen3_235B:
    """Test Model 2: Qwen3-235B (web search + thinking, 81,920 tokens)"""
    
    def test_qwen3_235b_configuration(self):
        """Test Qwen3-235B has correct configuration"""
        config = MODEL_CONFIGS["qwen3-235b"]
        assert config["actual_model"] == "qwen3-235b-a22b-2507"
        assert config["tools"] == ["web_search"]
        assert config["max_tokens"] == 81920
        assert config["thinking"] is True
    
    def test_qwen3_235b_resolves_correctly(self, model_router):
        """Test that qwen3-235b resolves correctly"""
        result = model_router.resolve_model("qwen3-235b")
        assert result == "qwen3-235b-a22b-2507"
    
    def test_qwen3_235b_auto_injects_web_search(self, model_router):
        """Test web_search injection"""
        tools = model_router.get_default_tools("qwen3-235b", existing_tools=None)
        assert tools is not None
        assert len(tools) == 1
        assert tools[0]["type"] == "web_search"
    
    def test_qwen3_235b_has_81920_tokens(self, model_router):
        """Test that max_tokens is 81,920"""
        max_tokens = model_router.get_max_tokens("qwen3-235b", client_max_tokens=None)
        assert max_tokens == 81920
    
    def test_qwen3_235b_client_can_override_tokens(self, model_router):
        """Test client can override max_tokens"""
        max_tokens = model_router.get_max_tokens("qwen3-235b", client_max_tokens=50000)
        assert max_tokens == 50000


class TestModel3_Qwen3VL:
    """Test Model 3: Qwen3-VL (NO web search + thinking, 81,920 tokens)"""
    
    def test_qwen3_vl_configuration(self):
        """Test Qwen3-VL has correct configuration"""
        config = MODEL_CONFIGS["qwen3-vl"]
        assert config["actual_model"] == "qwen3-vl-235b-a22b"
        assert config["tools"] == []  # NO web search
        assert config["max_tokens"] == 81920
        assert config["thinking"] is True
    
    def test_qwen3_vl_resolves_correctly(self, model_router):
        """Test that qwen3-vl resolves correctly"""
        result = model_router.resolve_model("qwen3-vl")
        assert result == "qwen3-vl-235b-a22b"
    
    def test_qwen3_vl_no_web_search(self, model_router):
        """Test that NO web_search is injected"""
        tools = model_router.get_default_tools("qwen3-vl", existing_tools=None)
        assert tools is None  # No tools configured
    
    def test_qwen3_vl_has_81920_tokens(self, model_router):
        """Test that max_tokens is 81,920"""
        max_tokens = model_router.get_max_tokens("qwen3-vl", client_max_tokens=None)
        assert max_tokens == 81920
    
    def test_qwen3_vl_client_can_add_tools(self, model_router):
        """Test client can add their own tools"""
        client_tools = [{"type": "custom_vl_tool"}]
        tools = model_router.get_default_tools("qwen3-vl", existing_tools=client_tools)
        assert tools == client_tools


class TestModel4_Qwen3Omni:
    """Test Model 4: Qwen3-Omni (NO web search + thinking, 81,920 tokens)"""
    
    def test_qwen3_omni_configuration(self):
        """Test Qwen3-Omni has correct configuration"""
        config = MODEL_CONFIGS["qwen3-omni"]
        assert config["actual_model"] == "qwen3-omni-flash"
        assert config["tools"] == []  # NO web search
        assert config["max_tokens"] == 81920
        assert config["thinking"] is True
    
    def test_qwen3_omni_resolves_correctly(self, model_router):
        """Test that qwen3-omni resolves correctly"""
        result = model_router.resolve_model("qwen3-omni")
        assert result == "qwen3-omni-flash"
    
    def test_qwen3_omni_no_web_search(self, model_router):
        """Test that NO web_search is injected"""
        tools = model_router.get_default_tools("qwen3-omni", existing_tools=None)
        assert tools is None
    
    def test_qwen3_omni_has_81920_tokens(self, model_router):
        """Test that max_tokens is 81,920"""
        max_tokens = model_router.get_max_tokens("qwen3-omni", client_max_tokens=None)
        assert max_tokens == 81920


class TestDefaultFallback:
    """Test default fallback behavior for unknown models"""
    
    def test_unknown_model_falls_back_to_qwen3_max(self, model_router):
        """Test unknown models fall back to qwen3-max-latest"""
        result = model_router.resolve_model("gpt-4")
        assert result == "qwen3-max-latest"
        
        result = model_router.resolve_model("claude-3-opus")
        assert result == "qwen3-max-latest"
        
        result = model_router.resolve_model("random-model-9999")
        assert result == "qwen3-max-latest"
    
    def test_default_injects_web_search(self, model_router):
        """Test default fallback injects web_search"""
        tools = model_router.get_default_tools("unknown-model", existing_tools=None)
        assert tools is not None
        assert len(tools) == 1
        assert tools[0]["type"] == "web_search"


class TestKnownQwenModels:
    """Test that known Qwen models pass through unchanged"""
    
    def test_direct_model_names_pass_through(self, model_router):
        """Test direct model names are not aliased"""
        # These should pass through unchanged
        assert model_router.resolve_model("qwen3-max-latest") == "qwen3-max-latest"
        assert model_router.resolve_model("qwen3-235b-a22b-2507") == "qwen3-235b-a22b-2507"
        assert model_router.resolve_model("qwen3-vl-235b-a22b") == "qwen3-vl-235b-a22b"
        assert model_router.resolve_model("qwen3-omni-flash") == "qwen3-omni-flash"
    
    def test_direct_models_no_tool_injection(self, model_router):
        """Test direct model names don't get tools injected"""
        tools = model_router.get_default_tools("qwen3-max-latest", existing_tools=None)
        assert tools is None  # Direct models don't get auto-injection


class TestRequestTransformation:
    """Test complete request transformation pipeline"""
    
    def test_transform_qwen3_max_request(self, model_router):
        """Test full transformation for Qwen3-Max"""
        from unittest.mock import Mock
        
        request = Mock()
        request.model = "qwen3-max"
        request.tools = None
        request.max_tokens = None
        
        transformed = model_router.transform_request(request)
        
        assert transformed.model == "qwen3-max-latest"
        assert transformed.tools is not None
        assert len(transformed.tools) == 1
        assert transformed.tools[0]["type"] == "web_search"
        assert transformed.max_tokens is None
    
    def test_transform_qwen3_235b_request(self, model_router):
        """Test full transformation for Qwen3-235B"""
        from unittest.mock import Mock
        
        request = Mock()
        request.model = "qwen3-235b"
        request.tools = None
        request.max_tokens = None
        
        transformed = model_router.transform_request(request)
        
        assert transformed.model == "qwen3-235b-a22b-2507"
        assert transformed.tools is not None
        assert transformed.tools[0]["type"] == "web_search"
        assert transformed.max_tokens == 81920
    
    def test_transform_qwen3_vl_request(self, model_router):
        """Test full transformation for Qwen3-VL (no tools)"""
        from unittest.mock import Mock
        
        request = Mock()
        request.model = "qwen3-vl"
        request.tools = None
        request.max_tokens = None
        
        transformed = model_router.transform_request(request)
        
        assert transformed.model == "qwen3-vl-235b-a22b"
        assert transformed.tools is None  # No tools for VL model
        assert transformed.max_tokens == 81920
    
    def test_transform_qwen3_omni_request(self, model_router):
        """Test full transformation for Qwen3-Omni (no tools)"""
        from unittest.mock import Mock
        
        request = Mock()
        request.model = "qwen3-omni"
        request.tools = None
        request.max_tokens = None
        
        transformed = model_router.transform_request(request)
        
        assert transformed.model == "qwen3-omni-flash"
        assert transformed.tools is None  # No tools for Omni model
        assert transformed.max_tokens == 81920


class TestEdgeCases:
    """Test edge cases and error handling"""
    
    def test_empty_model_name(self, model_router):
        """Test empty model name falls back to default"""
        result = model_router.resolve_model("")
        assert result == "qwen3-max-latest"
    
    def test_none_existing_tools_treated_as_empty(self, model_router):
        """Test None existing_tools is treated as no tools"""
        tools = model_router.get_default_tools("qwen3-max", existing_tools=None)
        assert tools is not None
    
    def test_empty_existing_tools_list(self, model_router):
        """Test empty list existing_tools allows injection"""
        tools = model_router.get_default_tools("qwen3-max", existing_tools=[])
        assert tools is not None  # Empty list means client didn't specify, so inject
    
    def test_special_characters_in_model_name(self, model_router):
        """Test model names with special characters"""
        result = model_router.resolve_model("qwen3@max!!")
        assert result == "qwen3-max-latest"  # Falls back to default

