#!/usr/bin/env python

"""
提供商工厂和路由机制
负责根据模型名称自动选择合适的提供商
"""

import json
import time
from pathlib import Path
from typing import Any, AsyncGenerator, Dict, List, Optional, Union

from app.core.config import settings
from app.models.schemas import OpenAIRequest
from app.providers.base import BaseProvider, ProviderConfig, provider_registry
from app.providers.qwen_provider import QwenProvider
from app.providers.qwen_proxy_provider import QwenProxyProvider
from app.utils.logger import get_logger

logger = get_logger()


class ProviderFactory:
    """提供商工厂"""

    def __init__(self):
        self._initialized = False
        self._default_provider = "qwen"
        self._use_proxy = True  # Use proxy provider by default for better reliability

    def _load_provider_configs(self) -> Dict[str, Dict[str, str]]:
        """
        Load provider configurations from environment variables or JSON file.
        
        Priority:
        1. Environment variables (QWEN_BEARER_TOKEN - fastest)
        2. Environment variables (QWEN_EMAIL, QWEN_PASSWORD - automated)
        3. JSON config file (config/providers.json)
        """
        import os
        
        configs = {}
        
        # Check for Bearer token first (fastest method)
        qwen_bearer_token = os.getenv("QWEN_BEARER_TOKEN")
        
        # Also check for email/password (fallback for automated login)
        qwen_email = os.getenv("QWEN_EMAIL")
        qwen_password = os.getenv("QWEN_PASSWORD")
        
        # If we have either bearer token OR credentials, configure Qwen
        if qwen_bearer_token or (qwen_email and qwen_password):
            if qwen_bearer_token:
                logger.info("✅ Loading Qwen Bearer token from environment variables")
            else:
                logger.info("✅ Loading Qwen credentials from environment variables")
                
            configs["qwen"] = {
                "name": "qwen",
                "loginUrl": "https://chat.qwen.ai/auth?action=signin",
                "chatUrl": "https://chat.qwen.ai",
                "baseUrl": "https://chat.qwen.ai",
                "email": qwen_email or "",
                "password": qwen_password or "",
                "bearer_token": qwen_bearer_token,  # Add Bearer token if provided
                "enabled": True
            }
            return configs
        
        # Fallback to JSON file if env vars not set
        config_path = Path("config/providers.json")
        if config_path.exists():
            try:
                with open(config_path, encoding='utf-8') as f:
                    data = json.load(f)
                    for provider in data.get("providers", []):
                        if provider.get("enabled", True):
                            configs[provider["name"]] = provider
                    return configs
            except Exception as e:
                logger.warning(f"Failed to load provider configs: {e}")
        
        logger.warning("⚠️ No Qwen credentials found in environment variables or config file")
        return {}

    def initialize(self):
        """初始化所有提供商"""
        if self._initialized:
            return

        try:
            # Load provider configurations
            provider_configs = self._load_provider_configs()

            # Choose provider based on configuration
            if self._use_proxy:
                # Use proxy provider (qwen.aikit.club) - RECOMMENDED
                logger.info("🚀 Using Qwen Proxy Provider (qwen.aikit.club)")
                config = ProviderConfig(
                    name="qwen",
                    api_endpoint="https://qwen.aikit.club/v1/chat/completions"
                )
                qwen_provider = QwenProxyProvider(config=config)
                
                # Note: Provider initialization happens lazily on first request
                # to avoid blocking the event loop during startup. The provider
                # will call initialize() automatically when needed.
                
            else:
                # Use direct provider (chat.qwen.ai) - LEGACY
                logger.info("⚠️  Using Direct Qwen Provider (legacy mode)")
                qwen_config = provider_configs.get("qwen")
                if qwen_config:
                    logger.info("🔐 Initializing Qwen provider with authentication")
                    qwen_provider = QwenProvider(auth_config=qwen_config)
                else:
                    logger.info("⚠️ Initializing Qwen provider without authentication (manual token required)")
                    qwen_provider = QwenProvider()

            provider_registry.register(
                qwen_provider,
                qwen_provider.get_supported_models()
            )

            self._initialized = True
            logger.info(f"✅ Initialized {len(provider_registry.list_providers())} providers (Qwen only)")

        except Exception as e:
            logger.error(f"❌ Provider factory initialization failed: {e}")
            raise

    def get_provider_for_model(self, model: str) -> Optional[BaseProvider]:
        """根据模型名称获取提供商"""
        if not self._initialized:
            self.initialize()

        # 首先尝试从配置的映射中获取
        provider_mapping = settings.provider_model_mapping
        provider_name = provider_mapping.get(model)

        if provider_name:
            provider = provider_registry.get_provider_by_name(provider_name)
            if provider:
                logger.debug(f"🎯 模型 {model} 映射到提供商 {provider_name}")
                return provider

        # 尝试从注册表中直接获取
        provider = provider_registry.get_provider(model)
        if provider:
            logger.debug(f"🎯 模型 {model} 找到提供商 {provider.name}")
            return provider

        # 使用默认提供商
        default_provider = provider_registry.get_provider_by_name(self._default_provider)
        if default_provider:
            logger.warning(f"⚠️ 模型 {model} 未找到专用提供商，使用默认提供商 {self._default_provider}")
            return default_provider

        logger.error(f"❌ 无法为模型 {model} 找到任何提供商")
        return None

    def list_supported_models(self) -> List[str]:
        """列出所有支持的模型"""
        if not self._initialized:
            self.initialize()
        return provider_registry.list_models()

    def list_providers(self) -> List[str]:
        """列出所有提供商"""
        if not self._initialized:
            self.initialize()
        return provider_registry.list_providers()

    def get_models_for_provider(self, provider_name: str) -> List[str]:
        """获取指定提供商支持的模型"""
        if not self._initialized:
            self.initialize()

        provider = provider_registry.get_provider_by_name(provider_name)
        if provider:
            return provider.get_supported_models()
        return []


class ProviderRouter:
    """提供商路由器"""

    def __init__(self):
        self.factory = ProviderFactory()

    async def route_request(
        self,
        request: OpenAIRequest,
        **kwargs
    ) -> Union[Dict[str, Any], AsyncGenerator[str, None]]:
        """路由请求到合适的提供商"""
        logger.info(f"🚦 路由请求: 模型={request.model}, 流式={request.stream}")

        # 获取提供商
        provider = self.factory.get_provider_for_model(request.model)
        if not provider:
            error_msg = f"不支持的模型: {request.model}"
            logger.error(f"❌ {error_msg}")
            return {
                "error": {
                    "message": error_msg,
                    "type": "invalid_request_error",
                    "code": "model_not_found"
                }
            }

        logger.info(f"✅ 使用提供商: {provider.name}")

        try:
            # 调用提供商处理请求
            result = await provider.chat_completion(request, **kwargs)
            logger.info(f"🎉 请求处理完成: {provider.name}")
            return result

        except Exception as e:
            error_msg = f"提供商 {provider.name} 处理请求失败: {str(e)}"
            logger.error(f"❌ {error_msg}")
            return provider.handle_error(e, "路由处理")

    def get_models_list(self) -> Dict[str, Any]:
        """获取模型列表（OpenAI格式）"""
        models = []
        current_time = int(time.time())

        # 按提供商分组获取模型
        for provider_name in self.factory.list_providers():
            provider_models = self.factory.get_models_for_provider(provider_name)
            for model in provider_models:
                models.append({
                    "id": model,
                    "object": "model",
                    "created": current_time,
                    "owned_by": provider_name
                })

        return {
            "object": "list",
            "data": models
        }


# 全局路由器实例
_router: Optional[ProviderRouter] = None


def get_provider_router() -> ProviderRouter:
    """获取全局提供商路由器"""
    global _router
    if _router is None:
        _router = ProviderRouter()
        # 确保工厂已初始化
        _router.factory.initialize()
    return _router


def initialize_providers():
    """初始化提供商系统"""
    logger.info("🚀 初始化提供商系统...")
    router = get_provider_router()
    logger.info("✅ 提供商系统初始化完成")
    return router
