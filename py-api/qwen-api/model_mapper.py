#!/usr/bin/env python3
"""
Model Name Mapper
Maps any model name to valid Qwen models using ModelRegistry
"""

from typing import Optional, List, Dict, Any
from .config_loader import settings
from .logging_config import logger
from .models.registry import get_registry


def map_model_name(model: Optional[str]) -> str:
    """Map any model name to a valid Qwen backend model ID"""
    registry = get_registry()
    
    if not model:
        return registry.get_default_model()
    
    backend_id = registry.get_backend_id(model)
    
    if backend_id == registry.get_default_model() and model.lower() != backend_id.lower():
        logger.debug(f"Model '{model}' mapped to default: {backend_id}")
    
    return backend_id


def list_available_models() -> List[Dict[str, Any]]:
    """Return list of available models for /v1/models endpoint"""
    registry = get_registry()
    models = registry.list_models()
    
    result = []
    for model in models:
        model_dict = {
            "id": model['id'],
            "object": "model",
            "owned_by": "qwen",
            "capabilities": model.get('capabilities', {})
        }
        result.append(model_dict)
    
    return result


def get_model_capabilities(model_id: str) -> Dict[str, bool]:
    """Get capabilities for a specific model"""
    registry = get_registry()
    return registry.get_capabilities(model_id)


def supports_vision(model_id: str) -> bool:
    """Check if model supports vision/image inputs"""
    registry = get_registry()
    return registry.supports_capability(model_id, 'vision')


def supports_tools(model_id: str) -> bool:
    """Check if model supports tool/function calling"""
    registry = get_registry()
    return registry.supports_capability(model_id, 'tools')


# Backwards compatibility
def _get_legacy_models_dict() -> dict:
    """Legacy compatibility - DEPRECATED"""
    registry = get_registry()
    models = registry.list_models()
    
    legacy_dict = {}
    for model in models:
        legacy_dict[model['id']] = model['backend_id']
        if model['id'] in registry._alias_map.values():
            for alias, target_id in registry._alias_map.items():
                if target_id == model['id']:
                    legacy_dict[alias] = model['backend_id']
    
    return legacy_dict


VALID_QWEN_MODELS = _get_legacy_models_dict()
