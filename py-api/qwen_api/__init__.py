"""
Qwen API - OpenAI-compatible API server for Qwen models
"""

__version__ = "1.0.0"
__author__ = "Qwen API Contributors"
__license__ = "MIT"

from .config_loader import settings
from .api_server import app

__all__ = ["settings", "app", "__version__"]

