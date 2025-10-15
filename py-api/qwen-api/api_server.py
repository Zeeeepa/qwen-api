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


# Pydantic models for OpenAI compatibility with enhanced documentation
class Message(BaseModel):
    """Chat message with role and content"""
    role: str = Field(
        ...,
        description="Message role: 'system', 'user', or 'assistant'",
        example="user"
    )
    content: str = Field(
        ...,
        description="Message content text",
        example="Hello, how can you help me today?"
    )


class ChatRequest(BaseModel):
    """
    Chat completion request in OpenAI-compatible format.
    Supports multiple input formats for flexibility.
    """
    model: Optional[str] = Field(
        None,
        description="Model name (any value accepted, auto-mapped to Qwen models)",
        example="gpt-4"
    )
    messages: Optional[List[Message]] = Field(
        None,
        description="Array of conversation messages in OpenAI format",
        example=[{"role": "user", "content": "Write a haiku about code"}]
    )
    input: Optional[str] = Field(
        None,
        description="Simple text input (alternative to messages array)",
        example="Write a haiku about code"
    )
    prompt: Optional[str] = Field(
        None,
        description="Prompt text (alternative to messages array)",
        example="Write a haiku about code"
    )
    text: Optional[Dict[str, Any]] = Field(
        None,
        description="Nested text input object",
        example={"input": "Write a haiku about code"}
    )
    temperature: Optional[float] = Field(
        0.7,
        ge=0.0,
        le=2.0,
        description="Sampling temperature (0.0-2.0). Higher = more random",
        example=0.7
    )
    max_tokens: Optional[int] = Field(
        None,
        gt=0,
        description="Maximum tokens to generate (null = model default)",
        example=1000
    )
    stream: Optional[bool] = Field(
        False,
        description="Enable Server-Sent Events streaming",
        example=False
    )
    enable_thinking: Optional[bool] = Field(
        False,
        description="Enable chain-of-thought reasoning mode",
        example=False
    )
    thinking_budget: Optional[int] = Field(
        None,
        gt=0,
        description="Maximum thinking tokens for reasoning (requires enable_thinking=true)",
        example=500
    )
    tools: Optional[List[Dict[str, Any]]] = Field(
        None,
        description="Array of available functions in OpenAI tools format",
        example=[{
            "type": "function",
            "function": {
                "name": "get_weather",
                "description": "Get current weather",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "location": {"type": "string"}
                    }
                }
            }
        }]
    )
    tool_choice: Optional[str] = Field(
        None,
        description="Tool selection: 'auto', 'none', or specific function name",
        example="auto"
    )


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


# Create FastAPI app with full OpenAPI documentation
app = FastAPI(
    title="Qwen OpenAI Proxy",
    version="2.0.0",
    description="""
## Qwen OpenAI-Compatible API

A fully OpenAI-compatible proxy for Qwen LLM models with enhanced features.

### Features
- 🔑 **Universal API Key**: Accepts any API key (server-side authentication)
- 🤖 **Smart Model Mapping**: Maps unknown models to best Qwen equivalents
- 🔄 **Streaming Support**: Full SSE streaming for real-time responses
- 🛠️ **Tool Calling**: Native function calling support
- 🧠 **Chain-of-Thought**: Optional thinking mode for complex reasoning
- 📊 **Usage Tracking**: Token usage statistics for cost management

### Authentication
The server uses server-side authentication with Qwen API. Client API keys are ignored.

### Endpoints
- **GET /** - Health check and service information
- **GET /v1/models** - List available models
- **POST /v1/chat/completions** - Chat completions (streaming & non-streaming)

### Example Usage
```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",  # Any key works!
    base_url="http://localhost:7050/v1"
)

response = client.chat.completions.create(
    model="gpt-4",  # Maps to qwen3-max
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)
```
    """,
    openapi_tags=[
        {
            "name": "Health",
            "description": "Service health and status endpoints"
        },
        {
            "name": "Models",
            "description": "Model discovery and listing"
        },
        {
            "name": "Chat",
            "description": "Chat completion endpoints"
        }
    ],
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
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


@app.get(
    "/",
    tags=["Health"],
    summary="Health Check",
    response_description="Service status and information"
)
async def root():
    """
    Health check endpoint for service monitoring.
    
    Returns service metadata including:
    - Service status
    - Version information
    - Available endpoints
    - API capabilities
    """
    return {
        "status": "ok",
        "service": "Qwen OpenAI Proxy",
        "version": "2.0.0",
        "endpoints": [
            "/v1/models",
            "/v1/chat/completions"
        ],
        "features": {
            "streaming": True,
            "tools": True,
            "thinking_mode": True,
            "universal_api_key": True,
            "model_mapping": True
        },
        "documentation": {
            "swagger": "/docs",
            "redoc": "/redoc",
            "openapi_schema": "/openapi.json"
        }
    }


@app.get(
    "/v1/models",
    tags=["Models"],
    summary="List Available Models",
    response_description="List of available models with metadata"
)
async def list_models():
    """
    List all available Qwen models in OpenAI-compatible format.
    
    Returns a list of models with:
    - Model ID (e.g., "qwen3-max", "qwen3-plus")
    - Model capabilities
    - Creation timestamp
    - Ownership information
    
    **Note**: This endpoint accepts any model name in chat completions.
    Unknown models are automatically mapped to the best Qwen equivalent.
    """
    models = list_available_models()
    
    # Add timestamps
    timestamp = int(datetime.now().timestamp())
    for model in models:
        model["created"] = timestamp
    
    return {
        "object": "list",
        "data": models
    }


@app.post(
    "/v1/chat/completions",
    tags=["Chat"],
    summary="Create Chat Completion",
    response_description="Chat completion response or stream",
    responses={
        200: {
            "description": "Successful completion",
            "content": {
                "application/json": {
                    "example": {
                        "id": "chatcmpl-1234567890",
                        "object": "chat.completion",
                        "created": 1234567890,
                        "model": "qwen3-max",
                        "choices": [{
                            "index": 0,
                            "message": {
                                "role": "assistant",
                                "content": "Hello! How can I help you today?"
                            },
                            "finish_reason": "stop"
                        }],
                        "usage": {
                            "prompt_tokens": 10,
                            "completion_tokens": 20,
                            "total_tokens": 30
                        }
                    }
                }
            }
        },
        400: {"description": "Bad request - Invalid parameters"},
        500: {"description": "Internal server error"}
    }
)
async def chat_completions(
    request: ChatRequest,
    authorization: Optional[str] = Header(None, description="API key (any value accepted)")
):
    """
    Create a chat completion using Qwen models.
    
    ## Features
    - **Universal API Key**: Accepts any API key (server handles authentication)
    - **Smart Model Mapping**: Unknown models automatically mapped to Qwen equivalents
    - **Streaming**: Set `stream=true` for real-time SSE responses
    - **Tool Calling**: Pass `tools` array for function calling
    - **Chain-of-Thought**: Enable `enable_thinking=true` for reasoning steps
    
    ## Request Formats
    Supports multiple input formats:
    1. **Standard OpenAI format**: `messages` array
    2. **Simple text**: `input` or `prompt` string
    3. **Nested text**: `text.input` object
    
    ## Model Mapping Examples
    - `gpt-4` → `qwen3-max`
    - `gpt-3.5-turbo` → `qwen3-plus`
    - `claude-3-opus` → `qwen3-max`
    - Any unknown model → `qwen3-max` (default)
    
    ## Streaming
    When `stream=true`, returns Server-Sent Events (SSE):
    ```
    data: {"choices": [{"delta": {"content": "Hello"}}]}
    data: {"choices": [{"delta": {"content": " world"}}]}
    data: [DONE]
    ```
    
    ## Tool Calling
    Pass tools in OpenAI format:
    ```json
    {
        "tools": [{
            "type": "function",
            "function": {
                "name": "get_weather",
                "parameters": {...}
            }
        }],
        "tool_choice": "auto"
    }
    ```
    
    ## Parameters
    - **model**: Model name (any value accepted, auto-mapped)
    - **messages**: Array of message objects with role and content
    - **temperature**: Controls randomness (0.0-2.0, default: 0.7)
    - **max_tokens**: Maximum tokens to generate
    - **stream**: Enable streaming responses (default: false)
    - **enable_thinking**: Enable chain-of-thought reasoning
    - **tools**: Array of available functions
    - **tool_choice**: Tool selection strategy ("auto", "none", or function name)
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
