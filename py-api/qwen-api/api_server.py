#!/usr/bin/env python3
"""
Qwen OpenAI-Compatible API Server
Clean, modular FastAPI application using backend modules
"""

from typing import List, Optional, Dict, Any
from datetime import datetime

from fastapi import FastAPI, HTTPException, Header, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from .config_loader import settings
from .logging_config import logger
from .model_mapper import map_model_name, list_available_models
from .request_normalizer import normalize_messages
from .qwen_client import QwenClient


# Pydantic models for OpenAI compatibility
class Message(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    model: Optional[str] = None
    messages: Optional[List[Message]] = None
    input: Optional[str] = None
    prompt: Optional[str] = None
    text: Optional[Dict[str, Any]] = None
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


# Create FastAPI app
app = FastAPI(
    title="Qwen OpenAI Proxy",
    version="2.0.0",
    description="OpenAI-compatible API for Qwen models"
)

# Initialize Qwen client (singleton)
qwen_client = None


def get_qwen_client() -> QwenClient:
    """Get or create Qwen client instance"""
    global qwen_client
    if qwen_client is None:
        qwen_client = QwenClient()
    return qwen_client


@app.on_event("startup")
async def startup_event():
    """Initialize on startup"""
    logger.info(f"🚀 Starting Qwen OpenAI Proxy v2.0.0")
    logger.info(f"   Server: http://{settings.host}:{settings.port}")
    logger.info(f"   Log level: {settings.log_level}")
    
    # Validate token
    try:
        get_qwen_client()
        logger.info("✅ Qwen client initialized successfully")
    except ValueError as e:
        logger.error(f"❌ Failed to initialize: {e}")
        raise


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "Qwen OpenAI Proxy",
        "version": "2.0.0",
        "endpoints": [
            "/v1/models",
            "/v1/chat/completions"
        ]
    }


@app.get("/v1/models")
async def list_models():
    """List available models (OpenAI compatible)"""
    models = list_available_models()
    
    # Add timestamps
    timestamp = int(datetime.now().timestamp())
    for model in models:
        model["created"] = timestamp
    
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
    - Accepts ANY API key (ignores it, uses server's token)
    - Maps unknown models to default Qwen model
    - Full OpenAI API compatibility
    """
    try:
        # Get client
        client = get_qwen_client()
        
        # Map model name
        mapped_model = map_model_name(request.model)
        logger.debug(f"Model mapping: '{request.model or 'none'}' → '{mapped_model}'")
        
        # Normalize request format
        messages_list = [
            {"role": msg.role, "content": msg.content}
            for msg in (request.messages or [])
        ] if request.messages else None
        
        normalized_messages = normalize_messages(
            messages=messages_list,
            input_text=request.input,
            prompt=request.prompt
        )
        
        logger.debug(f"Normalized {len(normalized_messages)} message(s)")
        
        # Call Qwen API via client
        qwen_response = await client.chat_completion(
            model=mapped_model,
            messages=normalized_messages,
            temperature=request.temperature,
            max_tokens=request.max_tokens,
            stream=request.stream,
            enable_thinking=request.enable_thinking,
            thinking_budget=request.thinking_budget,
            tools=request.tools,
            tool_choice=request.tool_choice
        )
        
        # Qwen API already returns OpenAI format
        # Just ensure model field is set correctly
        if "choices" in qwen_response:
            qwen_response["model"] = mapped_model
            return qwen_response
        
        # Fallback: construct OpenAI format response
        return {
            "id": f"chatcmpl-{int(datetime.now().timestamp())}",
            "object": "chat.completion",
            "created": int(datetime.now().timestamp()),
            "model": mapped_model,
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
        
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error processing request: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/v1/responses")
@app.post("/v1/completions")
async def generic_completions(
    request: Request,
    authorization: Optional[str] = Header(None)
):
    """
    Catch-all for other OpenAI-compatible endpoints
    Redirects to chat completions
    """
    body = await request.json()
    
    # Convert to chat completion format
    if "messages" in body:
        chat_request = ChatRequest(**body)
    else:
        # Extract message from various formats
        message_content = body.get("input") or body.get("prompt")
        if not message_content:
            raise HTTPException(status_code=400, detail="No input/prompt/messages provided")
        
        chat_request = ChatRequest(
            model=body.get("model"),
            messages=[Message(role="user", content=message_content)],
            temperature=body.get("temperature", 0.7),
            stream=body.get("stream", False)
        )
    
    return await chat_completions(chat_request, authorization=authorization)

