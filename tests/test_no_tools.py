#!/usr/bin/env python3
"""Test without tools to isolate issue"""
import os
from openai import OpenAI

port = os.getenv("SERVER_PORT", "8000")
client = OpenAI(
    api_key="sk-any",
    base_url=f"http://localhost:{port}/v1"
)

print("🧪 Test 1: Unknown model WITHOUT tools...")
try:
    result = client.chat.completions.create(
        model="gpt-5",  # Unknown, should route to qwen3-max-latest
        messages=[{"role": "user", "content": "Say hello"}],
        max_tokens=50
    )
    print(f"✅ Response: {result.choices[0].message.content}")
    print(f"   Model: {result.model}\n")
except Exception as e:
    print(f"❌ Error: {e}\n")

print("🧪 Test 2: Qwen_Research (no auto-tools)...")
try:
    result = client.chat.completions.create(
        model="Qwen_Research",
        messages=[{"role": "user", "content": "Say hello"}],
        max_tokens=50
    )
    print(f"✅ Response: {result.choices[0].message.content}")
    print(f"   Model: {result.model}\n")
except Exception as e:
    print(f"❌ Error: {e}\n")

print("🧪 Test 3: Direct Qwen model name...")
try:
    result = client.chat.completions.create(
        model="qwen3-max-latest",
        messages=[{"role": "user", "content": "Say hello"}],
        max_tokens=50
    )
    print(f"✅ Response: {result.choices[0].message.content}")
    print(f"   Model: {result.model}\n")
except Exception as e:
    print(f"❌ Error: {e}\n")

