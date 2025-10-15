#!/usr/bin/env python3
"""
Model Name Mapper
Maps any model name to valid Qwen models
"""

from typing import Optional
from config_loader import settings
from logging_config import logger


# Valid Qwen models registry
VALID_QWEN_MODELS = {
    # Qwen 3.x models
    "qwen3-max": "qwen3-max",
    "qwen3-vl-plus": "qwen3-vl-plus",
    "qwen3-coder-plus": "qwen3-coder-plus",
    "qwen3-vl-30b-a3b": "qwen3-vl-30b-a3b",
    
    # Qwen 2.5 models
    "qwen2.5-vl-32b-instruct": "qwen2.5-vl-32b-instruct",
    "qwen2.5-14b-instruct-1m": "qwen2.5-14b-instruct-1m",
    "qwen2.5-coder-32b-instruct": "qwen2.5-coder-32b-instruct",
    "qwen2.5-72b-instruct": "qwen2.5-72b-instruct",
    
    # Legacy aliases (map to qwen3-max)
    "qwen-max-latest": "qwen3-max",
    "qwen-plus-latest": "qwen3-max",
    "qwen-turbo-latest": "qwen3-max",
    "qwen-max": "qwen3-max",
    "qwen-plus": "qwen3-max",
    "qwen-turbo": "qwen3-max",
}


def map_model_name(model: Optional[str]) -> str:
    """
    Map any model name to a valid Qwen model.
    
    Args:
        model: Input model name (can be None, empty, or any string)
        
    Returns:
        Valid Qwen model name
    """
    if not model:
        return settings.default_model
    
    # Normalize model name (lowercase, remove spaces)
    normalized = model.lower().strip().replace(" ", "-")
    
    # Check if it's a known Qwen model
    if normalized in VALID_QWEN_MODELS:
        return VALID_QWEN_MODELS[normalized]
    
    # Default fallback
    logger.debug(f"Unknown model '{model}', using default: {settings.default_model}")
    return settings.default_model


def list_available_models() -> list:
    """Return list of available models for /v1/models endpoint"""
    return [
        {
            "id": "qwen3-max",
            "object": "model",
            "owned_by": "qwen"
        },
        {
            "id": "qwen3-vl-plus",
            "object": "model",
            "owned_by": "qwen"
        },
        {
            "id": "qwen3-coder-plus",
            "object": "model",
            "owned_by": "qwen"
        },
        {
            "id": "qwen2.5-72b-instruct",
            "object": "model",
            "owned_by": "qwen"
        },
        {
            "id": "qwen2.5-coder-32b-instruct",
            "object": "model",
            "owned_by": "qwen"
        },
    ]

