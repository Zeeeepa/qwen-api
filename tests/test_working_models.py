#!/usr/bin/env python3
"""
Test all variations with VERIFIED WORKING MODELS ONLY
Models: qwen3-max, qwen3-coder-plus, qwen2.5-72b-instruct, qwen2.5-coder-32b-instruct
"""

import json
import time
from openai import OpenAI

BASE_URL = "http://localhost:7050/v1"
API_KEY = "sk-any"
client = OpenAI(api_key=API_KEY, base_url=BASE_URL)

WORKING_MODELS = [
    "qwen3-max",
    "qwen3-coder-plus",
    "qwen2.5-72b-instruct",
    "qwen2.5-coder-32b-instruct"
]

def test_basic(model):
    """Test basic completion"""
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Say 'OK'"}],
            max_tokens=10
        )
        print(f"✓ {model}: {response.choices[0].message.content}")
        return True
    except Exception as e:
        print(f"✗ {model}: {str(e)[:80]}")
        return False

def test_streaming(model):
    """Test streaming"""
    try:
        stream = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Count 1 2 3"}],
            max_tokens=20,
            stream=True
        )
        chunks = []
        for chunk in stream:
            if chunk.choices[0].delta.content:
                chunks.append(chunk.choices[0].delta.content)
        result = "".join(chunks)
        print(f"✓ {model} (stream): {result[:30]}")
        return True
    except Exception as e:
        print(f"✗ {model} (stream): {str(e)[:80]}")
        return False

def test_system_message(model):
    """Test with system message"""
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "Hi"}
            ],
            max_tokens=20
        )
        print(f"✓ {model} (system): {response.choices[0].message.content[:30]}")
        return True
    except Exception as e:
        print(f"✗ {model} (system): {str(e)[:80]}")
        return False

def test_multi_turn(model):
    """Test multi-turn conversation"""
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "user", "content": "My name is Alice"},
                {"role": "assistant", "content": "Hello Alice!"},
                {"role": "user", "content": "What's my name?"}
            ],
            max_tokens=20
        )
        print(f"✓ {model} (multi-turn): {response.choices[0].message.content[:30]}")
        return True
    except Exception as e:
        print(f"✗ {model} (multi-turn): {str(e)[:80]}")
        return False

def test_temperature(model):
    """Test with different temperatures"""
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Random word"}],
            max_tokens=10,
            temperature=0.9
        )
        print(f"✓ {model} (temp=0.9): {response.choices[0].message.content[:30]}")
        return True
    except Exception as e:
        print(f"✗ {model} (temp): {str(e)[:80]}")
        return False

def test_max_tokens(model):
    """Test max_tokens parameter"""
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Tell me a story"}],
            max_tokens=5
        )
        print(f"✓ {model} (max_tokens=5): {response.choices[0].message.content}")
        return True
    except Exception as e:
        print(f"✗ {model} (max_tokens): {str(e)[:80]}")
        return False

def main():
    print("="*80)
    print("  TESTING ALL VARIATIONS WITH WORKING MODELS")
    print("="*80)
    
    results = {}
    
    for model in WORKING_MODELS:
        print(f"\n{'='*80}")
        print(f"  Testing: {model}")
        print(f"{'='*80}\n")
        
        results[model] = {
            "basic": test_basic(model),
            "streaming": test_streaming(model),
            "system": test_system_message(model),
            "multi_turn": test_multi_turn(model),
            "temperature": test_temperature(model),
            "max_tokens": test_max_tokens(model)
        }
        
        time.sleep(1)
    
    # Summary
    print(f"\n{'='*80}")
    print("  SUMMARY")
    print(f"{'='*80}\n")
    
    for model, tests in results.items():
        passed = sum(1 for v in tests.values() if v)
        total = len(tests)
        print(f"{model}: {passed}/{total} tests passed ({100*passed//total}%)")
        for test_name, result in tests.items():
            status = "✓" if result else "✗"
            print(f"  {status} {test_name}")
        print()
    
    total_tests = sum(len(tests) for tests in results.values())
    total_passed = sum(sum(1 for v in tests.values() if v) for tests in results.values())
    
    print(f"{'='*80}")
    print(f"OVERALL: {total_passed}/{total_tests} tests passed ({100*total_passed//total_tests}%)")
    print(f"{'='*80}\n")

if __name__ == "__main__":
    main()

