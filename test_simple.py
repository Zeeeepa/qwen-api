#!/usr/bin/env python3
"""Simple test of the working server"""

import os
import time
from openai import OpenAI

print("🧪 Testing Qwen API Server\n")

# Get token
token = os.getenv("QWEN_BEARER_TOKEN", "")
if not token:
    print("❌ QWEN_BEARER_TOKEN not set!")
    exit(1)

print(f"🔑 Token: {token[:50]}...\n")

# Create client
client = OpenAI(
    api_key=token,
    base_url="http://localhost:8080/v1"
)

print("📤 Sending request...\n")

try:
    start = time.time()
    
    response = client.chat.completions.create(
        model="qwen-max",
        messages=[{"role": "user", "content": "Say 'Hello from Qwen!' and nothing else."}],
        stream=False
    )
    
    elapsed = time.time() - start
    
    print("="*60)
    print("✅ SUCCESS!")
    print("="*60)
    print(f"Model: {response.model}")
    print(f"ID: {response.id}")
    print(f"Time: {elapsed:.2f}s")
    print(f"\nResponse:")
    print(f"  {response.choices[0].message.content}")
    print("="*60)
    
except Exception as e:
    print(f"\n❌ FAILED: {e}\n")
    import traceback
    traceback.print_exc()

