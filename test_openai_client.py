#!/usr/bin/env python
"""
Test OpenAI API compatibility with Qwen API Server
"""
import os
from openai import OpenAI

print("🧪 Testing Qwen API via OpenAI client...")
print()

# Get Bearer token from environment (set by server startup)
bearer_token = os.getenv("QWEN_BEARER_TOKEN", "")
if not bearer_token:
    # Try to read from server log
    try:
        with open("/tmp/server.log", "r") as f:
            for line in f:
                if "📝 Token:" in line:
                    bearer_token = line.split("Token:")[1].strip()
                    break
    except:
        pass

if not bearer_token:
    print("❌ No QWEN_BEARER_TOKEN found. Please set it or start the server first.")
    exit(1)

print(f"🔑 Using token: {bearer_token[:50]}...")
print()

# Initialize client pointing to local Qwen API server
client = OpenAI(
    api_key=bearer_token,  # Use actual compressed token
    base_url="http://localhost:8080/v1"  # Note: /v1 base path
)

print(f"📡 Base URL: {client.base_url}")
print(f"🔑 API Key: {client.api_key[:20]}...")
print()

try:
    print("📤 Sending request to Qwen API...")
    response = client.chat.completions.create(
        model="qwen-max-latest",
        messages=[{"role": "user", "content": "What is your model name?"}],
        stream=False
    )
    
    # Print response
    print()
    print("✅ Response received successfully!")
    print("=" * 60)
    print(f"Model: {response.model}")
    print(f"ID: {response.id}")
    print(f"Created: {response.created}")
    print()
    print("Message:")
    print(f"  Role: {response.choices[0].message.role}")
    print(f"  Content: {response.choices[0].message.content}")
    print()
    print("Usage:")
    print(f"  Prompt tokens: {response.usage.prompt_tokens}")
    print(f"  Completion tokens: {response.usage.completion_tokens}")
    print(f"  Total tokens: {response.usage.total_tokens}")
    print("=" * 60)
    print()
    print("🎉 OpenAI API compatibility verified!")
    
except Exception as e:
    print()
    print(f"❌ Error occurred:")
    print(f"   Type: {type(e).__name__}")
    print(f"   Message: {str(e)}")
    import traceback
    traceback.print_exc()
