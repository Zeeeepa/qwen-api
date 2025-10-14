#!/usr/bin/env python3
"""
Test OpenAI client with Qwen API
Validates actual API responses

Originally located at: test_openai_client.py (root)
Migrated to: tests/integration/test_openai_client.py (2025-10-14)
"""
import openai
import sys

try:
    import pytest
    HAS_PYTEST = True
except ImportError:
    HAS_PYTEST = False

print("=" * 60)
print("🧪 Testing OpenAI Client with Qwen API")
print("=" * 60)
print()

# Initialize client with correct AUTH_TOKEN
client = openai.OpenAI(
    base_url="http://localhost:8096/v1",
    api_key="sk-your-api-key"  # Default AUTH_TOKEN from config
)

print("✅ Client initialized")
print(f"   Base URL: http://localhost:8096/v1")
print(f"   API Key: sk-your-api-key")
print()

# Test 1: Simple question (non-streaming)
print("📝 Test 1: Simple Question (Non-Streaming)")
print("-" * 60)
try:
    response = client.chat.completions.create(
        model="qwen-turbo",
        messages=[{"role": "user", "content": "What is Python? Answer in 2 sentences."}],
        stream=False,
        max_tokens=100
    )
    
    content = response.choices[0].message.content
    print(f"✅ Response received:")
    print(f"   Model: {response.model}")
    print(f"   Content: {content}")
    print()
    
    if content and len(content) > 10:
        print("✅ Test 1 PASSED - Got valid response")
    else:
        print("❌ Test 1 FAILED - Empty or invalid response")
        sys.exit(1)
        
except Exception as e:
    print(f"❌ Test 1 FAILED: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print()

# Test 2: Streaming response
print("📝 Test 2: Streaming Response")
print("-" * 60)
try:
    stream = client.chat.completions.create(
        model="qwen-plus",
        messages=[{"role": "user", "content": "Count from 1 to 5"}],
        stream=True,
        max_tokens=50
    )
    
    print("✅ Stream started, receiving chunks:")
    print("   ", end="", flush=True)
    
    full_response = ""
    chunk_count = 0
    
    for chunk in stream:
        if chunk.choices[0].delta.content:
            content = chunk.choices[0].delta.content
            full_response += content
            print(content, end="", flush=True)
            chunk_count += 1
    
    print()
    print()
    
    if chunk_count > 0 and len(full_response) > 0:
        print(f"✅ Test 2 PASSED - Received {chunk_count} chunks")
        print(f"   Full response: {full_response[:100]}...")
    else:
        print("❌ Test 2 FAILED - No streaming data received")
        sys.exit(1)
        
except Exception as e:
    print(f"❌ Test 2 FAILED: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print()
print("=" * 60)
print("🎉 All OpenAI Client Tests PASSED!")
print("=" * 60)
print()
print("✅ Server is responding correctly to OpenAI SDK requests")
print("✅ Non-streaming responses work")
print("✅ Streaming responses work")
print()
