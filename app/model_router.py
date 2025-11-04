#!/usr/bin/env python
"""
Intelligent Model Router
Provides smart model aliasing and auto-tool injection
"""

from typing import Dict, List, Optional, Any
from app.utils.logger import get_logger

logger = get_logger()


# Model routing configuration
# These are the 4 accessible models with specific features
MODEL_CONFIGS = {
    # Model 1: Qwen3-Max (no thinking, web search always applied)
    # Aliases: qwen3, qwen3-max
    "qwen3": {
        "actual_model": "qwen3-max-latest",
        "tools": ["web_search"],
        "max_tokens": None,
        "thinking": False,
        "description": "Qwen3-Max: No thinking option, web search feature always applied"
    },
    "qwen3-max": {
        "actual_model": "qwen3-max-latest",
        "tools": ["web_search"],
        "max_tokens": None,
        "thinking": False,
        "description": "Qwen3-Max: No thinking option, web search feature always applied"
    },
    
    # Model 2: Qwen3-235B-A22B-2507 (web search + thinking, 81,920 tokens)
    # Aliases: qwen3-web, qwen3-235b
    "qwen3-web": {
        "actual_model": "qwen3-235b-a22b-2507",
        "tools": ["web_search"],
        "max_tokens": 81920,
        "thinking": True,
        "description": "Qwen3-235B: Web search + thinking, 81,920 tokens"
    },
    "qwen3-235b": {
        "actual_model": "qwen3-235b-a22b-2507",
        "tools": ["web_search"],
        "max_tokens": 81920,
        "thinking": True,
        "description": "Qwen3-235B: Web search + thinking, 81,920 tokens"
    },
    
    # Model 3: Qwen3-VL-235B-A22B (NO web search + thinking, 81,920 tokens)
    # Alias: qwen3-vl
    "qwen3-vl": {
        "actual_model": "qwen3-vl-235b-a22b",
        "tools": [],  # NO web search
        "max_tokens": 81920,
        "thinking": True,
        "description": "Qwen3-VL-235B: No web search, thinking enabled, 81,920 tokens"
    },
    
    # Model 4: Qwen3-Omni-Flash (NO web search + thinking, 81,920 tokens)
    # Alias: qwen3-omni
    "qwen3-omni": {
        "actual_model": "qwen3-omni-flash",
        "tools": [],  # NO web search
        "max_tokens": 81920,
        "thinking": True,
        "description": "Qwen3-Omni-Flash: No web search, thinking enabled, 81,920 tokens"
    },
    
    # Default fallback configuration (maps to Qwen3-Max)
    "_default": {
        "actual_model": "qwen3-max-latest",
        "tools": ["web_search"],
        "max_tokens": None,
        "thinking": False,
        "description": "Default fallback to Qwen3-Max with web search"
    }
}


# Known Qwen models that should NOT be aliased
# These pass through directly without any transformation
# Includes the 4 primary models and their variants
KNOWN_QWEN_MODELS = {
    # Primary 4 models
    "qwen3-max-latest",
    "qwen3-235b-a22b-2507",
    "qwen3-vl-235b-a22b",
    "qwen3-omni-flash",
    
    # Legacy/variant models
    "qwen2.5-max",
    "qwen2.5-turbo",
    "qwen-deep-research",
    "qwen-max-latest",
    "qwen3-coder-plus",
    "qwen-math-plus",
    "qwen-math-turbo",
    "qwen-coder-turbo",
    "qwen-vl-max",
    "qwen-vl-plus",
}


class ModelRouter:
    """
    Intelligent model router with aliasing and tool injection
    
    Features:
    - Model name normalization (case-insensitive)
    - Alias resolution (Qwen_Research → qwen-deep-research)
    - Default fallback (unknown models → qwen3-max-latest)
    - Auto-tool injection based on model configuration
    - Token limit configuration per model
    """
    
    def __init__(self):
        # Create case-insensitive lookup for model configs
        self._config_lookup = {
            key.lower(): value
            for key, value in MODEL_CONFIGS.items()
        }
        
        # Create case-insensitive lookup for known models
        self._known_models = {
            model.lower(): model
            for model in KNOWN_QWEN_MODELS
        }
        
        logger.info(f"🧭 ModelRouter initialized with {len(MODEL_CONFIGS)} aliases")
    
    def resolve_model(self, requested_model: str) -> str:
        """
        Resolve requested model name to actual Qwen model
        
        Logic:
        1. Normalize to lowercase
        2. Check if it's a known Qwen model → return as-is (with original case)
        3. Check if it's a configured alias → return actual_model
        4. Otherwise → return default model (qwen3-max-latest)
        
        Args:
            requested_model: Model name from client request
            
        Returns:
            Actual Qwen model name to use
        """
        normalized = requested_model.lower()
        
        # Check if it's a known Qwen model (pass through)
        if normalized in self._known_models:
            original_model = self._known_models[normalized]
            logger.debug(f"🎯 Known model: {requested_model} → {original_model} (pass-through)")
            return original_model
        
        # Check if it's a configured alias
        if normalized in self._config_lookup:
            config = self._config_lookup[normalized]
            actual = config["actual_model"]
            logger.info(f"🔄 Alias resolved: {requested_model} → {actual}")
            return actual
        
        # Fallback to default
        default_config = MODEL_CONFIGS["_default"]
        actual = default_config["actual_model"]
        logger.info(f"⚡ Unknown model fallback: {requested_model} → {actual}")
        return actual
    
    def get_model_config(self, requested_model: str) -> Dict[str, Any]:
        """
        Get configuration for a model
        
        Args:
            requested_model: Original model name from client
            
        Returns:
            Configuration dict with tools, max_tokens, etc.
        """
        normalized = requested_model.lower()
        
        # Check if it's a configured alias
        if normalized in self._config_lookup:
            return self._config_lookup[normalized]
        
        # Check if it's a known Qwen model (no auto-injection)
        if normalized in self._known_models:
            return {
                "actual_model": self._known_models[normalized],
                "tools": [],  # Don't inject tools for direct model names
                "max_tokens": None,
                "description": "Direct Qwen model"
            }
        
        # Return default config
        return MODEL_CONFIGS["_default"]
    
    def get_default_tools(self, requested_model: str, existing_tools: Optional[List] = None) -> Optional[List[Dict[str, str]]]:
        """
        Get tools to inject based on model configuration
        
        Logic:
        - If client already specified tools, don't override (respect client choice)
        - Otherwise, return configured tools for this model
        
        Args:
            requested_model: Model name from client
            existing_tools: Tools already specified by client (if any)
            
        Returns:
            List of tool objects to use, or None if no injection needed
        """
        # If client already specified tools, don't override
        if existing_tools is not None and len(existing_tools) > 0:
            logger.debug(f"🛠️  Client specified {len(existing_tools)} tools, not injecting defaults")
            return existing_tools
        
        # Get model configuration
        config = self.get_model_config(requested_model)
        configured_tools = config.get("tools", [])
        
        # If no tools configured, return None
        if not configured_tools:
            logger.debug(f"🚫 No default tools for model: {requested_model}")
            return None
        
        # Convert tool names to tool objects
        tool_objects = [{"type": tool_name} for tool_name in configured_tools]
        logger.info(f"🛠️  Auto-injecting tools for {requested_model}: {configured_tools}")
        return tool_objects
    
    def get_max_tokens(self, requested_model: str, client_max_tokens: Optional[int] = None) -> Optional[int]:
        """
        Get max_tokens to use based on model configuration
        
        Logic:
        - If client specified max_tokens, use that (client override)
        - Otherwise, use configured max_tokens for this model
        - If nothing configured, return None (use provider default)
        
        Args:
            requested_model: Model name from client
            client_max_tokens: Max tokens specified by client (if any)
            
        Returns:
            Max tokens to use, or None for provider default
        """
        # Get model configuration
        config = self.get_model_config(requested_model)
        configured_max = config.get("max_tokens")
        
        # If client specified, use client value
        if client_max_tokens is not None:
            logger.debug(f"🎛️  Using client-specified max_tokens: {client_max_tokens}")
            return client_max_tokens
        
        # Otherwise use configured value
        if configured_max is not None:
            logger.info(f"🎛️  Using configured max_tokens for {requested_model}: {configured_max}")
            return configured_max
        
        logger.debug(f"🎛️  No max_tokens configured for {requested_model}, using provider default")
        return None
    
    def transform_request(self, request: Any) -> Any:
        """
        Transform an OpenAI request with intelligent routing
        
        This is the main entry point that applies all transformations:
        1. Resolve model name
        2. Inject tools if needed
        3. Configure token limits
        
        Args:
            request: OpenAIRequest object
            
        Returns:
            Modified request object (or same object if no changes)
        """
        original_model = request.model
        
        # Step 1: Resolve model name
        resolved_model = self.resolve_model(original_model)
        if resolved_model != original_model:
            logger.info(f"📝 Model transformation: {original_model} → {resolved_model}")
            request.model = resolved_model
        
        # Step 2: Auto-inject tools if needed
        tools = self.get_default_tools(original_model, request.tools)
        if tools is not None and tools != request.tools:
            logger.info(f"🔧 Injecting tools: {[t['type'] for t in tools]}")
            request.tools = tools
        
        # Step 3: Configure max_tokens if needed
        max_tokens = self.get_max_tokens(original_model, request.max_tokens)
        if max_tokens is not None and max_tokens != request.max_tokens:
            logger.info(f"📊 Setting max_tokens: {max_tokens}")
            request.max_tokens = max_tokens
        
        return request


# Global router instance
_router: Optional[ModelRouter] = None


def get_model_router() -> ModelRouter:
    """Get global ModelRouter instance (singleton pattern)"""
    global _router
    if _router is None:
        _router = ModelRouter()
    return _router
