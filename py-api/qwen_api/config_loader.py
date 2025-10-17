#!/usr/bin/env python3
"""
Configuration Loader
Centralized configuration management for Qwen API
"""

import os
from typing import Optional
from dataclasses import dataclass


@dataclass
class Settings:
    """Application settings"""
    # API Configuration
    qwen_bearer_token: Optional[str] = None
    qwen_api_base: str = "https://qwen.aikit.club/v1"
    host: str = "0.0.0.0"
    port: int = 7050
    
    # Logging Configuration
    log_level: str = "WARNING"  # Default: quiet logs
    
    # Model Configuration
    default_model: str = "qwen3-max"
    
    def __post_init__(self):
        """Load from environment variables"""
        self.qwen_bearer_token = os.getenv("QWEN_BEARER_TOKEN", self.qwen_bearer_token)
        self.qwen_api_base = os.getenv("QWEN_API_BASE", self.qwen_api_base)
        self.host = os.getenv("HOST", self.host)
        self.port = int(os.getenv("PORT", str(self.port)))
        self.log_level = os.getenv("LOG_LEVEL", self.log_level).upper()
        self.default_model = os.getenv("DEFAULT_MODEL", self.default_model)


# Global settings instance
settings = Settings()

