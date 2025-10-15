#!/usr/bin/env python3
"""
Qwen API Client
Handles actual API calls to Qwen backend
"""

from typing import Dict, Any, Optional
import httpx
from .config_loader import settings
from .logging_config import logger


class QwenClient:
    """Client for Qwen API interactions"""
    
    def __init__(self, bearer_token: Optional[str] = None):
        """
        Initialize Qwen client
        
        Args:
            bearer_token: Optional override for bearer token
        """
        self.bearer_token = bearer_token or settings.qwen_bearer_token
        self.api_base = settings.qwen_api_base
        
        if not self.bearer_token:
            raise ValueError("QWEN_BEARER_TOKEN not configured")
        
        logger.debug(f"Initialized QwenClient with base URL: {self.api_base}")
    
    async def chat_completion(
        self,
        model: str,
        messages: list,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        stream: bool = False,
        enable_thinking: bool = False,
        thinking_budget: Optional[int] = None,
        tools: Optional[list] = None,
        tool_choice: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Call Qwen chat completions API
        
        Args:
            model: Model name
            messages: Array of message objects
            temperature: Sampling temperature
            max_tokens: Maximum tokens to generate
            stream: Whether to stream response
            enable_thinking: Enable thinking mode
            thinking_budget: Thinking budget
            tools: Tool definitions
            tool_choice: Tool choice strategy
            
        Returns:
            API response as dict
            
        Raises:
            httpx.HTTPStatusError: On API errors
            httpx.TimeoutException: On timeout
        """
        # Build request payload
        payload = {
            "model": model,
            "messages": messages,
            "stream": stream,
        }
        
        # Add optional parameters
        if temperature is not None:
            payload["temperature"] = temperature
        if max_tokens is not None:
            payload["max_tokens"] = max_tokens
        if enable_thinking:
            payload["enable_thinking"] = enable_thinking
        if thinking_budget is not None:
            payload["thinking_budget"] = thinking_budget
        if tools is not None:
            payload["tools"] = tools
        if tool_choice is not None:
            payload["tool_choice"] = tool_choice
        
        logger.debug(f"Calling Qwen API: {len(messages)} messages, model={model}")
        
        # Make API call
        async with httpx.AsyncClient(timeout=60.0) as client:
            headers = {
                "Authorization": f"Bearer {self.bearer_token}",
                "Content-Type": "application/json"
            }
            
            url = f"{self.api_base}/chat/completions"
            
            response = await client.post(url, headers=headers, json=payload)
            response.raise_for_status()
            
            result = response.json()
            logger.debug(f"Qwen API response received: status={response.status_code}")
            
            return result

