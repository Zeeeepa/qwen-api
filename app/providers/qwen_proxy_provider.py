#!/usr/bin/env python
"""
Qwen Proxy Provider - Using qwen.aikit.club OpenAI-Compatible Proxy
====================================================================

This provider uses the qwen.aikit.club proxy which provides an OpenAI-compatible
interface to Qwen models. This simplifies authentication and API calls significantly.

Key Features:
- ✅ Simple Bearer token authentication
- ✅ OpenAI-compatible request/response format
- ✅ No need to reverse-engineer internal Qwen APIs
- ✅ Supports all Qwen models (qwen-plus, qwen-turbo, qwen-max, etc.)
- ✅ Handles web search, thinking mode, vision automatically

Authentication Priority:
1. QWEN_BEARER_TOKEN environment variable (fastest, no browser)
2. Playwright extraction from localStorage (fallback)

API Endpoint: https://qwen.aikit.club/v1/
"""

import asyncio
import json
import time
from typing import Any, AsyncGenerator, Dict, List, Optional

import httpx

from app.auth.provider_auth import QwenAuth
from app.core.config import settings
from app.models.schemas import OpenAIRequest
from app.providers.base import BaseProvider, ProviderConfig
from app.utils.logger import get_logger

logger = get_logger()


class QwenProxyProvider(BaseProvider):
    """
    Provider that uses qwen.aikit.club proxy for OpenAI-compatible Qwen access
    """

    # API Configuration
    PROXY_BASE_URL = "https://qwen.aikit.club"
    CHAT_COMPLETIONS_ENDPOINT = f"{PROXY_BASE_URL}/v1/chat/completions"
    MODELS_ENDPOINT = f"{PROXY_BASE_URL}/v1/models"
    VALIDATE_ENDPOINT = f"{PROXY_BASE_URL}/v1/validate"
    
    # Request Configuration
    TIMEOUT = 60.0
    MAX_RETRIES = 3

    def __init__(self, config: ProviderConfig):
        """Initialize Qwen Proxy Provider"""
        super().__init__(config)
        self.auth = None
        self.bearer_token = None
        self.http_client = httpx.AsyncClient(timeout=self.TIMEOUT)

    async def initialize(self) -> bool:
        """
        Initialize provider and obtain Bearer token
        
        Priority:
        1. QWEN_BEARER_TOKEN from environment
        2. Extract from localStorage via Playwright
        """
        try:
            # Priority 1: Check environment variable
            if settings.QWEN_BEARER_TOKEN:
                logger.info("🔑 Using QWEN_BEARER_TOKEN from environment")
                self.bearer_token = settings.QWEN_BEARER_TOKEN
                
                # Validate token
                is_valid = await self._validate_token(self.bearer_token)
                if is_valid:
                    logger.info("✅ Bearer token validated successfully")
                    return True
                else:
                    logger.warning("⚠️  QWEN_BEARER_TOKEN is invalid, falling back to Playwright")

            # Priority 2: Use Playwright to extract token
            logger.info("🎭 No valid QWEN_BEARER_TOKEN found, using Playwright authentication")
            
            if not settings.QWEN_EMAIL or not settings.QWEN_PASSWORD:
                logger.error("❌ QWEN_EMAIL and QWEN_PASSWORD required for Playwright auth")
                return False

            # Initialize Qwen authentication
            self.auth = QwenAuth(config={
                "email": settings.QWEN_EMAIL,
                "password": settings.QWEN_PASSWORD
            })

            # Get session (which extracts Bearer token)
            session = await self.auth.get_valid_session()
            if not session or "bearer_token" not in session:
                logger.error("❌ Failed to extract Bearer token from Playwright")
                return False

            self.bearer_token = session["bearer_token"]
            logger.info(f"✅ Bearer token extracted successfully ({len(self.bearer_token)} chars)")

            # Validate extracted token
            is_valid = await self._validate_token(self.bearer_token)
            if not is_valid:
                logger.error("❌ Extracted Bearer token is invalid")
                return False

            logger.info("✅ Qwen Proxy Provider initialized successfully")
            return True

        except Exception as e:
            logger.error(f"❌ Failed to initialize Qwen Proxy Provider: {e}", exc_info=True)
            return False

    async def _validate_token(self, token: str) -> bool:
        """
        Validate Bearer token with the proxy
        
        Args:
            token: Bearer token to validate
            
        Returns:
            True if token is valid, False otherwise
        """
        try:
            response = await self.http_client.post(
                self.VALIDATE_ENDPOINT,
                json={"token": token},
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get("valid", False)
            else:
                logger.warning(f"⚠️  Token validation failed: {response.status_code}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Token validation error: {e}")
            return False

    async def get_auth_headers(self) -> Dict[str, str]:
        """Get authentication headers for proxy requests"""
        if not self.bearer_token:
            raise ValueError("Bearer token not initialized. Call initialize() first.")
        
        return {
            "Authorization": f"Bearer {self.bearer_token}",
            "Content-Type": "application/json",
        }

    async def chat_completion(
        self,
        request: OpenAIRequest
    ) -> AsyncGenerator[str, None]:
        """
        Send chat completion request to Qwen proxy
        
        This uses the standard OpenAI format - the proxy handles all Qwen-specific
        conversions internally.
        """
        try:
            # Ensure we're initialized
            if not self.bearer_token:
                logger.info("🔄 Bearer token not found, initializing...")
                initialized = await self.initialize()
                if not initialized:
                    raise ValueError("Failed to initialize Qwen Proxy Provider")

            # Build request body (standard OpenAI format)
            request_body = {
                "model": request.model,
                "messages": [
                    {
                        "role": msg.role,
                        "content": msg.content
                    }
                    for msg in request.messages
                ],
                "stream": request.stream if request.stream is not None else True,
            }

            # Optional parameters
            if request.temperature is not None:
                request_body["temperature"] = request.temperature
            if request.max_tokens is not None:
                request_body["max_tokens"] = request.max_tokens
            if request.top_p is not None:
                request_body["top_p"] = request.top_p

            logger.info(f"📤 Sending request to {self.CHAT_COMPLETIONS_ENDPOINT}")
            logger.debug(f"Request body: {json.dumps(request_body, indent=2)}")

            # Get auth headers
            headers = await self.get_auth_headers()

            # Make request
            async with self.http_client.stream(
                "POST",
                self.CHAT_COMPLETIONS_ENDPOINT,
                json=request_body,
                headers=headers
            ) as response:
                
                # Check for errors
                if response.status_code != 200:
                    error_text = await response.aread()
                    logger.error(f"❌ Proxy returned error {response.status_code}: {error_text.decode()}")
                    raise ValueError(f"Proxy error: {response.status_code}")

                # Stream response
                if request.stream:
                    async for line in response.aiter_lines():
                        if line.strip():
                            # Proxy returns SSE format: "data: {...}"
                            if line.startswith("data: "):
                                yield line + "\n\n"
                else:
                    # Non-streaming: read full response
                    content = await response.aread()
                    yield content.decode()

        except Exception as e:
            logger.error(f"❌ Chat completion error: {e}", exc_info=True)
            raise

    async def list_models(self) -> List[str]:
        """List available models from the proxy"""
        try:
            headers = await self.get_auth_headers()
            response = await self.http_client.get(
                self.MODELS_ENDPOINT,
                headers=headers
            )
            
            if response.status_code == 200:
                data = response.json()
                # Extract model IDs from OpenAI-format response
                return [model["id"] for model in data.get("data", [])]
            else:
                logger.error(f"❌ Failed to list models: {response.status_code}")
                return []
                
        except Exception as e:
            logger.error(f"❌ Error listing models: {e}")
            return []

    async def transform_request(self, request: OpenAIRequest) -> Dict:
        """
        Transform OpenAI request to Qwen proxy format
        
        Since the proxy is OpenAI-compatible, we can pass through the request
        with minimal transformation.
        """
        request_body = {
            "model": request.model,
            "messages": [
                {
                    "role": msg.role,
                    "content": msg.content
                }
                for msg in request.messages
            ],
            "stream": request.stream if request.stream is not None else True,
        }

        # Optional parameters
        if request.temperature is not None:
            request_body["temperature"] = request.temperature
        if request.max_tokens is not None:
            request_body["max_tokens"] = request.max_tokens
        if request.top_p is not None:
            request_body["top_p"] = request.top_p

        return request_body

    async def transform_response(self, response: Any, request: OpenAIRequest) -> AsyncGenerator[str, None]:
        """
        Transform Qwen proxy response to OpenAI format
        
        Since the proxy returns OpenAI-compatible responses, we can pass through
        with minimal transformation.
        """
        # If response is already a generator, pass through
        if hasattr(response, '__aiter__'):
            async for chunk in response:
                yield chunk
        else:
            # If response is a dict or string, yield it
            if isinstance(response, dict):
                yield json.dumps(response)
            else:
                yield str(response)

    async def cleanup(self):
        """Cleanup resources"""
        if self.http_client:
            await self.http_client.aclose()
