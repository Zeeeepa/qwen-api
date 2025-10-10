#!/usr/bin/env python3
"""
Minimal working Qwen -> OpenAI API server
Tests the complete flow with actual API calls
"""

import asyncio
import json
import os
import time
import uuid
from typing import List, Optional

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
from contextlib import asynccontextmanager

# Get token from environment
BEARER_TOKEN = os.getenv("QWEN_BEARER_TOKEN", "")

if not BEARER_TOKEN:
    print("❌ QWEN_BEARER_TOKEN environment variable must be set!")
    print("Set it to your compressed Qwen token")
    exit(1)

# ============================================================================
# Models
# ============================================================================

class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    model: str
    messages: List[Message]
    stream: Optional[bool] = False

# ============================================================================
# Qwen Client
# ============================================================================

class QwenClient:
    def __init__(self, token: str):
        self.token = token
        self.client = httpx.AsyncClient(timeout=60.0)
    
    async def chat(self, request: ChatRequest):
        """Send request to Qwen API"""
        model = request.model.replace('-thinking', '').replace('-latest', '')
        thinking = '-thinking' in request.model
        
        # Build Qwen request (Deno format)
        qwen_req = {
            "model": model,
            "messages": [{"role": m.role, "content": m.content} for m in request.messages],
            "stream": True,
            "incremental_output": True,
            "chat_type": "t2t",
            "session_id": str(uuid.uuid4()),
            "chat_id": str(uuid.uuid4()),
            "feature_config": {
                "output_schema": "phase",
                "thinking_enabled": thinking
            }
        }
        
        headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json',
            'User-Agent': 'Mozilla/5.0',
            'Origin': 'https://chat.qwen.ai',
            'Referer': 'https://chat.qwen.ai/'
        }
        
        print(f"📤 Sending to Qwen API: model={model}, thinking={thinking}")
        
        try:
            response = await self.client.post(
                "https://chat.qwen.ai/api/chat/completions",
                json=qwen_req,
                headers=headers
            )
            
            print(f"📥 Qwen response status: {response.status_code}")
            
            if response.status_code != 200:
                error_text = response.text[:500]
                print(f"❌ Qwen API error: {error_text}")
                raise HTTPException(status_code=response.status_code, detail=f"Qwen API error: {error_text}")
            
            if request.stream:
                return self._stream(response, request.model)
            else:
                return await self._non_stream(response, request.model)
        
        except Exception as e:
            print(f"❌ Exception: {e}")
            raise HTTPException(status_code=500, detail=str(e))
    
    async def _non_stream(self, response, model):
        """Collect streaming response"""
        content = ""
        line_count = 0
        
        async for line in response.aiter_lines():
            if line.startswith('data: '):
                line_count += 1
                try:
                    data = json.loads(line[6:])
                    if data.get('choices') and data['choices'][0].get('delta'):
                        chunk = data['choices'][0]['delta'].get('content', '')
                        content += chunk
                except Exception as e:
                    print(f"⚠️ Line parse error: {e}")
        
        print(f"✅ Received {line_count} lines, {len(content)} chars")
        
        return {
            "id": f"chatcmpl-{int(time.time())}",
            "object": "chat.completion",
            "created": int(time.time()),
            "model": model,
            "choices": [{
                "index": 0,
                "message": {"role": "assistant", "content": content},
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": 0,
                "completion_tokens": len(content.split()),
                "total_tokens": len(content.split())
            }
        }
    
    async def _stream(self, response, model):
        """Stream response"""
        async def generate():
            msg_id = f"chatcmpl-{int(time.time())}"
            async for line in response.aiter_lines():
                if line.startswith('data: '):
                    try:
                        data = json.loads(line[6:])
                        if data.get('choices') and data['choices'][0].get('delta'):
                            content = data['choices'][0]['delta'].get('content', '')
                            finish = data['choices'][0].get('finish_reason')
                            
                            chunk = {
                                "id": msg_id,
                                "object": "chat.completion.chunk",
                                "created": int(time.time()),
                                "model": model,
                                "choices": [{
                                    "index": 0,
                                    "delta": {"content": content} if content else {},
                                    "finish_reason": finish
                                }]
                            }
                            yield f"data: {json.dumps(chunk)}\n\n"
                    except:
                        pass
            yield "data: [DONE]\n\n"
        
        return StreamingResponse(generate(), media_type="text/event-stream")

# ============================================================================
# FastAPI App
# ============================================================================

qwen_client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global qwen_client
    print("🔧 Initializing Qwen client...")
    qwen_client = QwenClient(BEARER_TOKEN)
    print(f"✅ Ready! Token: {BEARER_TOKEN[:50]}...")
    yield
    print("👋 Shutdown")

app = FastAPI(lifespan=lifespan)

@app.get("/health")
async def health():
    return {"status": "healthy", "token_set": bool(BEARER_TOKEN)}

@app.post("/v1/chat/completions")
async def chat_completions(request: ChatRequest):
    print(f"\n{'='*60}")
    print(f"📨 NEW REQUEST")
    print(f"   Model: {request.model}")
    print(f"   Messages: {len(request.messages)}")
    print(f"   Stream: {request.stream}")
    print(f"{'='*60}\n")
    
    try:
        result = await qwen_client.chat(request)
        
        if isinstance(result, StreamingResponse):
            print("✅ Returning streaming response")
            return result
        else:
            print(f"✅ Returning complete response ({len(result['choices'][0]['message']['content'])} chars)")
            return JSONResponse(content=result)
    
    except Exception as e:
        print(f"\n❌ ERROR: {e}\n")
        raise

if __name__ == "__main__":
    import uvicorn
    print("\n" + "="*60)
    print("🚀 Qwen API Server")
    print("📡 http://0.0.0.0:8080")
    print("="*60 + "\n")
    uvicorn.run(app, host="0.0.0.0", port=8080, log_level="warning")

