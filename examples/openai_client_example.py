#!/usr/bin/env python3
"""
OpenAI Client Example - Using Qwen API with OpenAI SDK
========================================================

This example demonstrates how to use the Qwen API server with the OpenAI Python SDK.
The server acts as a proxy, converting OpenAI-compatible requests to Qwen format.

Requirements:
    pip install openai

Usage:
    python3 examples/openai_client_example.py
"""

import os
from openai import OpenAI

# Configuration
BASE_URL = os.getenv("QWEN_API_BASE_URL", "http://localhost:8096/v1")
API_KEY = os.getenv("AUTH_TOKEN", "sk-test")

# Initialize OpenAI client pointing to Qwen API
client = OpenAI(
    base_url=BASE_URL,
    api_key=API_KEY
)

print("=" * 80)
print("Qwen API - OpenAI SDK Integration Example")
print("=" * 80)
print()

# Example 1: Simple Chat Completion
print("📝 Example 1: Simple Chat Completion")
print("-" * 80)

response = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "What is Python?"}],
    stream=False
)

print(f"Response: {response.choices[0].message.content}")
print()

# More examples...
