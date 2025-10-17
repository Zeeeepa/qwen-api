#!/usr/bin/env python3
"""
Model Registry - Centralized model configuration management
Loads and manages model definitions from YAML configuration
"""

import os
import yaml
from pathlib import Path
from typing import Dict, List, Optional, Any
from functools import lru_cache


class ModelRegistry:
    """
    Singleton model registry that loads model configurations from YAML
    and provides methods to query model information and capabilities
    """
    
    _instance = None
    _models: Dict[str, Dict[str, Any]] = {}
    _alias_map: Dict[str, str] = {}
    _default_model: str = "qwen3-max"
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._load_models()
        return cls._instance
    
    def _load_models(self):
        """Load model configurations from YAML file"""
        # Try multiple possible locations for config file
        possible_paths = [
            Path("config/models/qwen_models.yaml"),
            Path(__file__).parent.parent.parent.parent / "config" / "models" / "qwen_models.yaml",
            Path("/app/config/models/qwen_models.yaml"),
        ]
        
        config_path = None
        for path in possible_paths:
            if path.exists():
                config_path = path
                break
        
        if not config_path:
            print(f"⚠️  Warning: Model config file not found")
            self._load_fallback_models()
            return
        
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
            
            # Parse models from config
            for model_data in config.get('models', []):
                model_id = model_data['id']
                self._models[model_id] = {
                    'id': model_id,
                    'name': model_data.get('name', model_id),
                    'backend_id': model_data['backend_id'],
                    'capabilities': model_data.get('capabilities', {}),
                    'description': model_data.get('description', ''),
                    'special_mode': model_data.get('special_mode')
                }
                
                # Register aliases
                for alias in model_data.get('aliases', []):
                    self._alias_map[alias.lower()] = model_id
            
            # Set default model
            self._default_model = config.get('default_model', 'qwen3-max')
            
            print(f"✅ Loaded {len(self._models)} models from {config_path}")
            
        except Exception as e:
            print(f"❌ Error loading model config: {e}")
            self._load_fallback_models()
    
    def _load_fallback_models(self):
        """Load minimal fallback models"""
        fallback = {
            'qwen3-max': {
                'id': 'qwen3-max',
                'name': 'Qwen 3 Max',
                'backend_id': 'qwen3-max',
                'capabilities': {'vision': True, 'reasoning': False, 'web_search': True, 'tools': False},
                'description': 'Flagship Qwen 3 model',
                'special_mode': None
            }
        }
        self._models = fallback
        self._alias_map = {'qwen-max': 'qwen3-max'}
    
    def get_model(self, model_id: str) -> Optional[Dict[str, Any]]:
        """Get model configuration by ID"""
        normalized_id = model_id.lower().strip() if model_id else None
        if not normalized_id:
            return self._models.get(self._default_model)
        
        if normalized_id in self._models:
            return self._models[normalized_id]
        
        if normalized_id in self._alias_map:
            actual_id = self._alias_map[normalized_id]
            return self._models.get(actual_id)
        
        return None
    
    def get_backend_id(self, model_id: str) -> str:
        """Get the actual backend model ID"""
        model = self.get_model(model_id)
        if model:
            return model['backend_id']
        return self._default_model
    
    def list_models(self) -> List[Dict[str, Any]]:
        """Get list of all available models"""
        return list(self._models.values())
    
    def get_capabilities(self, model_id: str) -> Dict[str, bool]:
        """Get model capabilities"""
        model = self.get_model(model_id)
        if model:
            return model.get('capabilities', {})
        return {}
    
    def supports_capability(self, model_id: str, capability: str) -> bool:
        """Check if model supports capability"""
        capabilities = self.get_capabilities(model_id)
        return capabilities.get(capability, False)
    
    def get_default_model(self) -> str:
        """Get the default model ID"""
        return self._default_model


_registry = None

def get_registry() -> ModelRegistry:
    """Get the global ModelRegistry singleton"""
    global _registry
    if _registry is None:
        _registry = ModelRegistry()
    return _registry
