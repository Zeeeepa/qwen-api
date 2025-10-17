#!/usr/bin/env python3
"""
Model Name Mapper with Alias System
Maps any model name to valid Qwen models with automatic feature injection
"""

from typing import Optional, List, Dict, Any
from dataclasses import dataclass, field
from .config_loader import settings
from .logging_config import logger


@dataclass
class ModelConfig:
    """
    Configuration for a model including automatic features
    
    Attributes:
        qwen_model: Actual Qwen model to use
        auto_tools: Tools to automatically inject (e.g., web_search)
        thinking_enabled: Whether to enable thinking mode
        max_tokens_override: Override max_tokens if user doesn't specify
    """
    qwen_model: str
    auto_tools: List[Dict[str, Any]] = field(default_factory=list)
    thinking_enabled: bool = False
    max_tokens_override: Optional[int] = None


# Model Alias Configuration
# These aliases automatically inject tools and features
ALIAS_CONFIGS = {
    # Default model with web search
    "qwen": ModelConfig(
        qwen_model="qwen3-max-latest",
        auto_tools=[{"type": "web_search"}]
    ),
    
    # Deep research mode (no auto-tools)
    "qwen_research": ModelConfig(
        qwen_model="qwen-deep-research"
    ),
    
    # Thinking mode with web search and extended context
    "qwen_think": ModelConfig(
        qwen_model="qwen3-235b-a22b-2507",
        auto_tools=[{"type": "web_search"}],
        thinking_enabled=True,
        max_tokens_override=81920
    ),
    
    # Coder model with web search
    "qwen_code": ModelConfig(
        qwen_model="qwen3-coder-plus",
        auto_tools=[{"type": "web_search"}]
    ),
}


# Valid Qwen models registry (for direct model name usage)
VALID_QWEN_MODELS = {
    # Qwen 3.x models
    "qwen3-max": "qwen3-max",
    "qwen3-max-latest": "qwen3-max-latest",
    "qwen3-vl-plus": "qwen3-vl-plus",
    "qwen3-vl-max": "qwen3-vl-max",
    "qwen3-coder-plus": "qwen3-coder-plus",
    "qwen3-vl-30b-a3b": "qwen3-vl-30b-a3b",
    "qwen3-235b-a22b-2507": "qwen3-235b-a22b-2507",
    
    # Special models
    "qwen-deep-research": "qwen-deep-research",
    
    # Qwen 2.5 models
    "qwen2.5-vl-32b-instruct": "qwen2.5-vl-32b-instruct",
    "qwen2.5-14b-instruct-1m": "qwen2.5-14b-instruct-1m",
    "qwen2.5-coder-32b-instruct": "qwen2.5-coder-32b-instruct",
    "qwen2.5-72b-instruct": "qwen2.5-72b-instruct",
    
    # Legacy aliases (map to qwen3-max)
    "qwen-max-latest": "qwen3-max-latest",
    "qwen-plus-latest": "qwen3-max-latest",
    "qwen-turbo-latest": "qwen3-max-latest",
    "qwen-max": "qwen3-max-latest",
    "qwen-plus": "qwen3-max-latest",
    "qwen-turbo": "qwen3-max-latest",
}


def normalize_model_name(model: str) -> str:
    """Normalize model name for matching"""
    return model.lower().strip().replace(" ", "-").replace("_", "-")


def get_alias_config(model: str) -> Optional[ModelConfig]:
    """
    Get alias configuration if model matches an alias
    
    Args:
        model: Model name to check
        
    Returns:
        ModelConfig if alias found, None otherwise
    """
    normalized = normalize_model_name(model)
    return ALIAS_CONFIGS.get(normalized)


def map_model_name(model: Optional[str]) -> ModelConfig:
    """
    Map any model name to a ModelConfig with automatic features.
    
    Priority:
    1. Check for model alias (Qwen, Qwen_Research, etc.)
    2. Check for direct Qwen model name
    3. Fallback to default "Qwen" alias with web_search
    
    Args:
        model: Input model name (can be None, empty, or any string)
        
    Returns:
        ModelConfig with target model and auto-features
    """
    # Handle None/empty
    if not model:
        logger.debug("No model specified, using default 'Qwen' alias")
        return ALIAS_CONFIGS["qwen"]
    
    # Check for alias first (highest priority)
    alias_config = get_alias_config(model)
    if alias_config:
        logger.debug(f"Model '{model}' matched alias → {alias_config.qwen_model} with auto-features")
        return alias_config
    
    # Normalize for direct model lookup
    normalized = normalize_model_name(model)
    
    # Check if it's a known Qwen model (direct usage, no auto-features)
    if normalized in VALID_QWEN_MODELS:
        qwen_model = VALID_QWEN_MODELS[normalized]
        logger.debug(f"Model '{model}' → direct Qwen model: {qwen_model}")
        return ModelConfig(qwen_model=qwen_model)
    
    # Default fallback to "Qwen" alias with web_search
    logger.info(f"Unknown model '{model}', routing to default 'Qwen' alias with web_search")
    return ALIAS_CONFIGS["qwen"]


def list_available_models() -> list:
    """
    Return list of available models for /v1/models endpoint
    Includes both aliases and direct Qwen models
    """
    models = []
    
    # Add model aliases first
    for alias_name, config in ALIAS_CONFIGS.items():
        models.append({
            "id": alias_name,
            "object": "model",
            "owned_by": "qwen-alias"
        })
    
    # Add direct Qwen models
    direct_models = [
        "qwen3-max",
        "qwen3-max-latest",
        "qwen3-vl-plus",
        "qwen3-coder-plus",
        "qwen-deep-research",
        "qwen2.5-72b-instruct",
        "qwen2.5-coder-32b-instruct",
    ]
    
    for model_id in direct_models:
        models.append({
            "id": model_id,
            "object": "model",
            "owned_by": "qwen"
        })
    
    return models
