#!/usr/bin/env python3
"""
Request Normalizer
Converts various OpenAI-compatible request formats to standard format
"""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel


class Message(BaseModel):
    """Standard message format"""
    role: str
    content: str


def normalize_messages(
    messages: Optional[List[Dict[str, Any]]] = None,
    input_text: Optional[str] = None,
    prompt: Optional[str] = None
) -> List[Dict[str, str]]:
    """
    Normalize various input formats to standard messages array
    
    Args:
        messages: Standard OpenAI messages array
        input_text: Alternative format: single input string
        prompt: Alternative format: single prompt string
        
    Returns:
        Normalized messages array
        
    Raises:
        ValueError: If no valid input provided
    """
    if messages:
        # Standard format: messages array
        return [{"role": msg.get("role", "user"), "content": msg.get("content", "")} 
                for msg in messages]
    
    if input_text:
        # Alternative format: input field
        return [{"role": "user", "content": input_text}]
    
    if prompt:
        # Alternative format: prompt field
        return [{"role": "user", "content": prompt}]
    
    raise ValueError("Request must include 'messages', 'input', or 'prompt' field")

