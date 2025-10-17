#!/usr/bin/env python3
"""Quick test to see model routing"""
import os
from openai import OpenAI

port = os.getenv("SERVER_PORT", "8000")
client = OpenAI(
    api_key="sk-any",
    base_url=f"http://localhost:{port}/v1"
)

print("🧪 Testing simple request with 'Qwen' model...")
try:
    result = client.chat.completions.create(
        model="Qwen",
        messages=[{"role": "user", "content": "Say hello"}],
        max_tokens=50
    )
    print(f"✅ Response: {result.choices[0].message.content}")
    print(f"   Model used: {result.model}")
except Exception as e:
    print(f"❌ Error: {e}")

