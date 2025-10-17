#!/usr/bin/env python3
"""
OpenAI-Compatible API Server for Qwen
Proxies OpenAI format requests to Qwen API

Features:
- Accepts ANY API key (always uses server's stored token)
- Maps unknown models to GLM-4.6 (default)
- Supports all existing Qwen models
- Works with any OpenAI-compatible client
"""

import os
import sys
import json
import asyncio
from typing import List, Optional, Dict, Any, Union
from datetime import datetime

import uvicorn
from fastapi import FastAPI, HTTPException, Header, Request
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field
import httpx


# Load environment variables
QWEN_TOKEN = os.getenv("QWEN_BEARER_TOKEN")
QWEN_API_BASE = "https://qwen.aikit.club/v1"
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "7050"))

# Model mapping - map any unknown model to default
DEFAULT_MODEL = "qwen3-max"  # Best general-purpose model
VALID_QWEN_MODELS = {
    # Qwen 3.x Main Models
    "qwen3-max": "qwen3-max",
    "qwen3-max-latest": "qwen3-max",
    "qwen3-vl-plus": "qwen3-vl-plus",
    "qwen3-vl-235b-a22b": "qwen3-vl-plus",
    "qwen3-coder-plus": "qwen3-coder-plus",
    "qwen3-coder": "qwen3-coder-plus",
    "qwen3-vl-30b-a3b": "qwen3-vl-30b-a3b",
    "qwen3-omni-flash": "qwen3-omni-flash",
    "qwen3-next-80b-a3b": "qwen-plus-2025-09-11",
    "qwen-plus-2025-09-11": "qwen-plus-2025-09-11",
    "qwen3-235b-a22b": "qwen3-235b-a22b",
    "qwen3-235b-a22b-2507": "qwen3-235b-a22b",
    "qwen3-30b-a3b": "qwen3-30b-a3b",
    "qwen3-30b-a3b-2507": "qwen3-30b-a3b",
    "qwen3-coder-30b-a3b-instruct": "qwen3-coder-30b-a3b-instruct",
    "qwen3-coder-flash": "qwen3-coder-30b-a3b-instruct",
    
    # Qwen 2.5 Models
    "qwen-max-latest": "qwen-max-latest",
    "qwen2.5-max": "qwen-max-latest",
    "qwen-plus-2025-01-25": "qwen-plus-2025-01-25",
    "qwen2.5-plus": "qwen-plus-2025-01-25",
    "qwq-32b": "qwq-32b",
    "qwen-turbo-2025-02-11": "qwen-turbo-2025-02-11",
    "qwen2.5-turbo": "qwen-turbo-2025-02-11",
    "qwen2.5-omni-7b": "qwen2.5-omni-7b",
    "qvq-72b-preview-0310": "qvq-72b-preview-0310",
    "qvq-max": "qvq-72b-preview-0310",
    "qwen2.5-vl-32b-instruct": "qwen2.5-vl-32b-instruct",
    "qwen2.5-14b-instruct-1m": "qwen2.5-14b-instruct-1m",
    "qwen2.5-coder-32b-instruct": "qwen2.5-coder-32b-instruct",
    "qwen2.5-72b-instruct": "qwen2.5-72b-instruct",
    
    # Special purpose models
    "qwen-deep-research": "qwen3-max",
    "qwen-web-dev": "qwen3-max",
    "qwen-full-stack": "qwen3-max",
    
    # Legacy aliases
    "qwen-max": "qwen3-max",
    "qwen-plus": "qwen-plus-2025-01-25",
    "qwen-turbo": "qwen-turbo-2025-02-11",
}


# Helper function to map model names
def map_model_name(model: Optional[str]) -> str:
    """
    Map any model name to a valid Qwen model.
    - If model is None or empty, use DEFAULT_MODEL
    - If model exists in VALID_QWEN_MODELS, use it
    - Otherwise, use DEFAULT_MODEL
    """
    if not model:
        return DEFAULT_MODEL
    
    # Normalize model name (lowercase, remove spaces)
    normalized = model.lower().strip().replace(" ", "-")
    
    # Check if it's a known Qwen model
    if normalized in VALID_QWEN_MODELS:
        return VALID_QWEN_MODELS[normalized]
    
    # Default fallback
    print(f"⚠️  Unknown model '{model}', using default: {DEFAULT_MODEL}", file=sys.stderr)
    return DEFAULT_MODEL


# Pydantic models for OpenAI compatibility
class Message(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    model: Optional[str] = None  # Optional - Qwen API doesn't require it
    messages: Optional[List[Message]] = None  # Make optional to support alternative formats
    input: Optional[str] = None  # Alternative format: input field
    prompt: Optional[str] = None  # Alternative format: prompt field
    text: Optional[Dict[str, Any]] = None  # Alternative format: text configuration
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = None
    stream: Optional[bool] = False
    enable_thinking: Optional[bool] = False
    thinking_budget: Optional[int] = None
    tools: Optional[List[Dict[str, Any]]] = None
    tool_choice: Optional[str] = None


class ChatChoice(BaseModel):
    index: int
    message: Message
    finish_reason: str


class Usage(BaseModel):
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


class ChatResponse(BaseModel):
    id: str
    object: str = "chat.completion"
    created: int
    model: str
    choices: List[ChatChoice]
    usage: Usage


class Model(BaseModel):
    id: str
    object: str = "model"
    created: int
    owned_by: str = "qwen"


class ModelListResponse(BaseModel):
    object: str = "list"
    data: List[Model]


# Create FastAPI app
app = FastAPI(title="Qwen OpenAI Proxy", version="1.0.0")


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "Qwen OpenAI Proxy",
        "version": "1.0.0",
        "endpoints": [
            "/v1/models",
            "/v1/chat/completions"
        ]
    }


@app.get("/v1/models")
async def list_models():
    """List available models (OpenAI compatible)"""
    models = [
        {
            "id": "qwen3-max",
            "object": "model",
            "created": int(datetime.now().timestamp()),
            "owned_by": "qwen"
        },
        {
            "id": "qwen3-vl-plus",
            "object": "model",
            "created": int(datetime.now().timestamp()),
            "owned_by": "qwen"
        },
        {
            "id": "qwen3-coder-plus",
            "object": "model",
            "created": int(datetime.now().timestamp()),
            "owned_by": "qwen"
        },
        {
            "id": "qwen2.5-72b-instruct",
            "object": "model",
            "created": int(datetime.now().timestamp()),
            "owned_by": "qwen"
        },
        {
            "id": "qwen2.5-coder-32b-instruct",
            "object": "model",
            "created": int(datetime.now().timestamp()),
            "owned_by": "qwen"
        },
    ]
    
    return {
        "object": "list",
        "data": models
    }


@app.post("/v1/chat/completions")
async def chat_completions(
    request: ChatRequest,
    authorization: Optional[str] = Header(None)
):
    """
    OpenAI-compatible chat completions endpoint
    
    Features:
    - Accepts ANY API key (ignores it, always uses server's stored token)
    - Maps unknown models to qwen-turbo-latest (default Qwen model)
    - Supports all existing Qwen models (qwen-max, qwen-plus, qwen-turbo)
    - Full OpenAI API compatibility
    """
    # ALWAYS use server's stored token - ignore user's API key
    # This allows: api_key="sk-anything", api_key="random123", etc.
    if not QWEN_TOKEN:
        raise HTTPException(
            status_code=500, 
            detail="Server error: QWEN_BEARER_TOKEN not configured"
        )
    
    token = QWEN_TOKEN
    
    # Map model name to valid Qwen model
    mapped_model = map_model_name(request.model)
    print(f"🎯 Model mapping: '{request.model or 'none'}' → '{mapped_model}'", file=sys.stderr)
    
    # Normalize request format - handle different OpenAI SDK formats
    qwen_messages = []
    
    if request.messages:
        # Standard format: messages array
        for msg in request.messages:
            qwen_messages.append({
                "role": msg.role,
                "content": msg.content
            })
    elif request.input:
        # Alternative format: input field (e.g., client.responses.create(input="..."))
        qwen_messages.append({
            "role": "user",
            "content": request.input
        })
    elif request.prompt:
        # Alternative format: prompt field
        qwen_messages.append({
            "role": "user",
            "content": request.prompt
        })
    else:
        # No valid input provided
        raise HTTPException(
            status_code=400,
            detail="Request must include 'messages', 'input', or 'prompt' field"
        )
    
    print(f"📝 Normalized messages: {len(qwen_messages)} message(s)", file=sys.stderr)
    
    # Build Qwen request - IMPORTANT: Must include the mapped model field
    qwen_request = {
        "model": mapped_model,  # Use the mapped model name
        "messages": qwen_messages,
        "stream": request.stream,
    }
    
    # Only add optional fields if they are provided
    if request.temperature is not None:
        qwen_request["temperature"] = request.temperature
    if request.max_tokens is not None:
        qwen_request["max_tokens"] = request.max_tokens
    if request.enable_thinking:
        qwen_request["enable_thinking"] = request.enable_thinking
    if request.thinking_budget is not None:
        qwen_request["thinking_budget"] = request.thinking_budget
    if request.tools is not None:
        qwen_request["tools"] = request.tools
    if request.tool_choice is not None:
        qwen_request["tool_choice"] = request.tool_choice
    
    # Call Qwen API
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            url = f"{QWEN_API_BASE}/chat/completions"
            
            print(f"📤 Sending request to Qwen API: {url}", file=sys.stderr)
            print(f"   Messages: {len(qwen_messages)}", file=sys.stderr)
            print(f"   Request payload: {json.dumps(qwen_request, indent=2)}", file=sys.stderr)
            
            response = await client.post(
                url,
                headers=headers,
                json=qwen_request
            )
            
            print(f"📥 Response status: {response.status_code}", file=sys.stderr)
            
            if response.status_code != 200:
                error_detail = response.text
                print(f"❌ Error response: {error_detail}", file=sys.stderr)
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Qwen API error: {error_detail}"
                )
            
            # Parse Qwen response and convert to OpenAI format
            qwen_response = response.json()
            
            # Qwen response might already be in OpenAI format
            # If not, convert it
            if "choices" in qwen_response:
                # Ensure the response includes the mapped model name
                qwen_response["model"] = mapped_model
                return qwen_response
            
            # Otherwise construct OpenAI format response
            return {
                "id": f"chatcmpl-{int(datetime.now().timestamp())}",
                "object": "chat.completion",
                "created": int(datetime.now().timestamp()),
                "model": mapped_model,  # Return the actual model used
                "choices": [{
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": qwen_response.get("output", {}).get("text", "")
                    },
                    "finish_reason": "stop"
                }],
                "usage": qwen_response.get("usage", {
                    "prompt_tokens": 0,
                    "completion_tokens": 0,
                    "total_tokens": 0
                })
            }
            
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Request timeout")
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/v1/responses")
@app.post("/v1/completions")
async def generic_completions(
    request: Request,
    authorization: Optional[str] = Header(None)
):
    """
    Catch-all for other OpenAI-compatible endpoints
    Redirects to chat completions with model mapping
    """
    body = await request.json()
    
    # Extract message from various possible formats
    message_content = None
    if "input" in body:
        message_content = body["input"]
    elif "prompt" in body:
        message_content = body["prompt"]
    elif "messages" in body:
        # Already in chat format, forward to chat completions
        return await chat_completions(
            ChatRequest(**body),
            authorization=authorization
        )
    
    if not message_content:
        raise HTTPException(status_code=400, detail="No input/prompt/messages provided")
    
    # Convert to chat completion format
    chat_request = ChatRequest(
        model=body.get("model"),
        messages=[Message(role="user", content=message_content)],
        temperature=body.get("temperature", 0.7),
        stream=body.get("stream", False)
    )
    
    return await chat_completions(chat_request, authorization=authorization)


def main():
    """Main entry point"""
    if not QWEN_TOKEN:
        print("❌ Error: QWEN_BEARER_TOKEN not set in environment", file=sys.stderr)
        print("   Please run setup.sh first to extract token", file=sys.stderr)
        sys.exit(1)
    
    print(f"🚀 Starting Qwen OpenAI Proxy on port {PORT}...", file=sys.stderr)
    print(f"   Token loaded: {QWEN_TOKEN[:20]}...", file=sys.stderr)
    print(f"   Access server at: http://localhost:{PORT}", file=sys.stderr)
    print(f"   OpenAI endpoint: http://localhost:{PORT}/v1/chat/completions", file=sys.stderr)
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=PORT,
        log_level="info"
    )


if __name__ == "__main__":
    main()
