#!/usr/bin/env python

"""
多提供商架构包
提供统一的提供商接口和路由机制
"""

from app.providers.base import BaseProvider, ProviderConfig, provider_registry
from app.providers.provider_factory import (
    ProviderFactory,
    ProviderRouter,
    get_provider_router,
    initialize_providers,
)
from app.providers.qwen_provider import QwenProvider
from app.providers.qwen_proxy_provider import QwenProxyProvider

__all__ = [
    "BaseProvider",
    "ProviderConfig",
    "provider_registry",
    "QwenProvider",
    "QwenProxyProvider",
    "ProviderFactory",
    "ProviderRouter",
    "get_provider_router",
    "initialize_providers"
]
