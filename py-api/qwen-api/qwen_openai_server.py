#!/usr/bin/env python3
"""
OpenAI-Compatible API Server for Qwen
Proxies OpenAI format requests to Qwen API
"""

import os
import sys
import json
import asyncio
from typing import List, Optional, Dict, Any
from datetime import datetime

import uvicorn
from fastapi import FastAPI, HTTPException, Header
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel
import httpx


# Load environment variables
QWEN_TOKEN = os.getenv("QWEN_BEARER_TOKEN")
QWEN_API_BASE = "https://qwen.aikit.club/v1"
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "7050"))


# Pydantic models for OpenAI compatibility
class Message(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    model: Optional[str] = None  # Optional - Qwen API doesn't require it
    messages: List[Message]
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
            "id": "qwen-max-latest",
            "object": "model",
            "created": int(datetime.now().timestamp()),
            "owned_by": "qwen"
        },
        {
            "id": "qwen-plus-latest",
            "object": "model",
            "created": int(datetime.now().timestamp()),
            "owned_by": "qwen"
        },
        {
            "id": "qwen-turbo-latest",
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
    Proxies to Qwen API
    """
    # Verify token
    if not QWEN_TOKEN:
        raise HTTPException(status_code=500, detail="QWEN_BEARER_TOKEN not set")
    
    # Use authorization header if provided, otherwise use env token
    token = QWEN_TOKEN
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "")
    
    # Convert OpenAI format to Qwen format
    qwen_messages = []
    for msg in request.messages:
        qwen_messages.append({
            "role": msg.role,
            "content": msg.content
        })
    
    # Build Qwen request - IMPORTANT: Don't send model field to Qwen API
    qwen_request = {
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
                return qwen_response
            
            # Otherwise construct OpenAI format response
            return {
                "id": f"chatcmpl-{int(datetime.now().timestamp())}",
                "object": "chat.completion",
                "created": int(datetime.now().timestamp()),
                "model": request.model,
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
