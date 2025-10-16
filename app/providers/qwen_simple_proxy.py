"""
Simple Qwen Proxy Provider - Uses public qwen.aikit.club instance

This provider acts as a simple proxy to the public Qwen instance,
which already provides an OpenAI-compatible API. No complex transformations needed!
"""

import httpx
from typing import Dict, Any, AsyncIterator, Optional, List
from loguru import logger

from app.providers.base import BaseProvider
from app.providers.base import ProviderConfig


class QwenSimpleProxy(BaseProvider):
    """
    Simple proxy to qwen.aikit.club public instance.
    
    The public instance already provides OpenAI-compatible API,
    so we just need to:
    1. Normalize model names (gpt-4 -> qwen-max-latest)
    2. Forward requests with Bearer token
    3. Return responses as-is
    """
    
    BASE_URL = "https://qwen.aikit.club"
    
    def __init__(self, auth_token: str):
        """
        Initialize simple proxy
        
        Args:
            auth_token: Qwen Bearer token from localStorage
        """
        config = ProviderConfig(
            name="qwen",
            api_endpoint=f"{self.BASE_URL}/v1/chat/completions",
            timeout=60,
            headers={
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        )
        super().__init__(config)
        
        # Store token (add Bearer prefix if not present)
        self.auth_token = auth_token if auth_token.startswith('Bearer ') else f'Bearer {auth_token}'
        
        logger.info(f"✅ Initialized QwenSimpleProxy with token length: {len(auth_token)}")
    
    def _normalize_model_name(self, model: str) -> str:
        """
        Normalize OpenAI-style model names to valid Qwen model names
        
        Args:
            model: Model name from OpenAI request (e.g., "gpt-4", "gpt-3.5-turbo")
            
        Returns:
            Valid Qwen model name (e.g., "qwen-max-latest", "qwen-turbo-latest")
        """
        # Direct Qwen model names pass through
        if model.startswith("qwen-"):
            return model
            
        # Map common OpenAI models to Qwen equivalents
        model_mapping = {
            "gpt-4": "qwen-max-latest",
            "gpt-4-turbo": "qwen-max-latest",
            "gpt-4o": "qwen-max-latest",
            "gpt-3.5-turbo": "qwen-turbo-latest",
            "gpt-3.5": "qwen-turbo-latest"
        }
        
        # Check exact match first
        if model in model_mapping:
            return model_mapping[model]
            
        # Check prefix match (e.g., "gpt-4-0613" -> "qwen-max-latest")
        for prefix, qwen_model in model_mapping.items():
            if model.startswith(prefix):
                return qwen_model
                
        # Default: use qwen-max-latest for unknown models
        return "qwen-max-latest"
    
    async def transform_request(self, request: Any) -> Dict[str, Any]:
        """
        Transform OpenAI request to Qwen format (simple!)
        
        The public instance accepts standard OpenAI format, so we just:
        1. Normalize the model name
        2. Pass everything else through
        
        Args:
            request: OpenAI ChatCompletionRequest
            
        Returns:
            Dictionary ready for qwen.aikit.club
        """
        # Normalize model name
        qwen_model = self._normalize_model_name(request.model)
        
        if qwen_model != request.model:
            logger.info(f"📝 Normalized model: {request.model} -> {qwen_model}")
        
        # Build simple request (OpenAI-compatible!)
        body = {
            "model": qwen_model,
            "messages": [msg.dict() for msg in request.messages],
            "stream": request.stream
        }
        
        # Add optional parameters if provided
        if request.temperature is not None:
            body["temperature"] = request.temperature
        if request.max_tokens is not None:
            body["max_tokens"] = request.max_tokens
        if request.top_p is not None:
            body["top_p"] = request.top_p
        
        logger.debug(f"📤 Simple proxy request: model={qwen_model}, messages={len(body['messages'])}, stream={request.stream}")
        
        return body
    
    def get_auth_headers(self) -> Dict[str, str]:
        """Get authentication headers with Bearer token"""
        return {
            "Authorization": self.auth_token,
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
    
    async def transform_response(self, response: httpx.Response) -> Dict[str, Any]:
        """
        Transform Qwen response to OpenAI format (pass-through!)
        
        The public instance already returns OpenAI-compatible responses,
        so we just return them as-is!
        
        Args:
            response: Raw HTTP response from qwen.aikit.club
            
        Returns:
            OpenAI-compatible response dictionary
        """
        if response.status_code != 200:
            error_text = response.text
            logger.error(f"❌ Qwen API error: {response.status_code} - {error_text}")
            raise ValueError(f"Qwen API error: {error_text}")
        
        # Public instance returns OpenAI-compatible JSON - just parse and return!
        result = response.json()
        logger.debug(f"✅ Response from public instance: {result.get('id', 'unknown')}")
        
        return result
    
    async def stream_response(self, response: httpx.Response) -> AsyncIterator[str]:
        """
        Stream SSE responses from Qwen API
        
        The public instance uses standard SSE format, so we just pass through!
        
        Args:
            response: HTTP response with streaming data
            
        Yields:
            SSE data lines (already in correct format!)
        """
        logger.info("🌊 Starting SSE stream from public instance")
        
        async for line in response.aiter_lines():
            if line.startswith('data: '):
                # Remove 'data: ' prefix and yield
                data = line[6:]
                
                # Check for end of stream
                if data == '[DONE]':
                    logger.info("✅ Stream completed")
                    break
                
                yield data


    async def chat_completion(self, request: Any) -> Dict[str, Any]:
        """
        Main chat completion entry point (required by BaseProvider)
        
        This method is called by the router and handles the complete
        request/response cycle for chat completions.
        
        Args:
            request: OpenAI ChatCompletionRequest
            
        Returns:
            OpenAI-compatible response dictionary
        """
        # Transform request to Qwen format (minimal transformation)
        body = await self.transform_request(request)
        
        # Get headers with Bearer token
        headers = self.get_auth_headers()
        
        # Make request to public instance
        async with httpx.AsyncClient(timeout=60.0) as client:
            if request.stream:
                # Streaming response
                response = await client.post(
                    self.config.api_endpoint,
                    headers=headers,
                    json=body
                )
                return await self.stream_response(response)
            else:
                # Non-streaming response
                response = await client.post(
                    self.config.api_endpoint,
                    headers=headers,
                    json=body
                )
                return await self.transform_response(response)
    
    def get_supported_models(self) -> List[str]:
        """
        Get list of supported models
        
        Returns:
            List of model names supported by this provider
        """
        return [
            "qwen-max-latest",
            "qwen-turbo-latest",
            "qwen3-coder-plus",
            "qwen-deep-research",
            "qwen-web-dev",
            "qwen-full-stack",
            # Also support OpenAI model names (will be normalized)
            "gpt-4",
            "gpt-4-turbo",
            "gpt-4o",
            "gpt-3.5-turbo"
        ]

