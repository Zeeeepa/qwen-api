#!/usr/bin/env python3
"""
Test script for universal OpenAI client compatibility
Tests that ANY API key works and ANY model name maps correctly
"""

import os
from openai import OpenAI

# Configuration
PORT = int(os.getenv("PORT", "7050"))
BASE_URL = f"http://localhost:{PORT}/v1"

print("=" * 70)
print("🧪 TESTING UNIVERSAL OPENAI CLIENT COMPATIBILITY")
print("=" * 70)

# Test 1: Random API key with unknown model
print("\n📝 Test 1: Random API key with unknown model (gpt-5)")
print("-" * 70)
client1 = OpenAI(
    api_key="sk-random123fake456",  # Completely fake key
    base_url=BASE_URL
)

try:
    response = client1.chat.completions.create(
        model="gpt-5",  # Non-existent model
        messages=[{"role": "user", "content": "Say 'Test 1 passed'"}],
        temperature=0.7
    )
    print(f"✅ SUCCESS")
    print(f"   Model used: {response.model}")
    print(f"   Response: {response.choices[0].message.content[:100]}...")
except Exception as e:
    print(f"❌ FAILED: {e}")

# Test 2: Another fake key with GLM-4.6 (valid model)
print("\n📝 Test 2: Different fake key with valid model (GLM-4.6)")
print("-" * 70)
client2 = OpenAI(
    api_key="sk-any123123",
    base_url=BASE_URL
)

try:
    response = client2.chat.completions.create(
        model="GLM-4.6",
        messages=[{"role": "user", "content": "Say 'Test 2 passed'"}]
    )
    print(f"✅ SUCCESS")
    print(f"   Model used: {response.model}")
    print(f"   Response: {response.choices[0].message.content[:100]}...")
except Exception as e:
    print(f"❌ FAILED: {e}")

# Test 3: No model specified (should use default)
print("\n📝 Test 3: No model parameter (should default to GLM-4.6)")
print("-" * 70)
client3 = OpenAI(
    api_key="totally-fake-key-xyz",
    base_url=BASE_URL
)

try:
    response = client3.chat.completions.create(
        model=None,  # Will use default
        messages=[{"role": "user", "content": "Say 'Test 3 passed'"}]
    )
    print(f"✅ SUCCESS")
    print(f"   Model used: {response.model}")
    print(f"   Response: {response.choices[0].message.content[:100]}...")
except Exception as e:
    print(f"❌ FAILED: {e}")

# Test 4: qwen-plus-latest (valid Qwen model)
print("\n📝 Test 4: Valid Qwen model (qwen-plus-latest)")
print("-" * 70)
client4 = OpenAI(
    api_key="another-fake-key",
    base_url=BASE_URL
)

try:
    response = client4.chat.completions.create(
        model="qwen-plus-latest",
        messages=[{"role": "user", "content": "Say 'Test 4 passed'"}]
    )
    print(f"✅ SUCCESS")
    print(f"   Model used: {response.model}")
    print(f"   Response: {response.choices[0].message.content[:100]}...")
except Exception as e:
    print(f"❌ FAILED: {e}")

# Test 5: Mixed case model name
print("\n📝 Test 5: Mixed case model name (GlM-4.5V)")
print("-" * 70)
client5 = OpenAI(
    api_key="yet-another-fake",
    base_url=BASE_URL
)

try:
    response = client5.chat.completions.create(
        model="GlM-4.5V",  # Mixed case, should normalize to GLM-4.5V
        messages=[{"role": "user", "content": "Say 'Test 5 passed'"}]
    )
    print(f"✅ SUCCESS")
    print(f"   Model used: {response.model}")
    print(f"   Response: {response.choices[0].message.content[:100]}...")
except Exception as e:
    print(f"❌ FAILED: {e}")

print("\n" + "=" * 70)
print("🎉 ALL TESTS COMPLETED")
print("=" * 70)

