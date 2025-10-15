#!/usr/bin/env python3
"""
Comprehensive API Test Suite
Tests all endpoints from qwen.json and openapi.json schemas
"""

import os
import json
import requests
import time
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:7050"
TOKEN = os.getenv("QWEN_BEARER_TOKEN")

# Test results storage
results = {
    "total_tests": 0,
    "passed": 0,
    "failed": 0,
    "tests": []
}

def log_test(name, status, details=""):
    """Log test result"""
    result = {
        "name": name,
        "status": status,
        "details": details,
        "timestamp": datetime.now().isoformat()
    }
    results["tests"].append(result)
    results["total_tests"] += 1
    if status == "PASS":
        results["passed"] += 1
        print(f"✅ {name}")
    else:
        results["failed"] += 1
        print(f"❌ {name}")
    if details:
        print(f"   {details}")

def test_endpoint(method, endpoint, data=None, description=""):
    """Generic endpoint tester"""
    url = f"{BASE_URL}{endpoint}"
    headers = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}
    
    try:
        if method == "GET":
            response = requests.get(url, headers=headers, timeout=30)
        elif method == "POST":
            response = requests.post(url, headers=headers, json=data, timeout=30)
        elif method == "DELETE":
            response = requests.delete(url, headers=headers, timeout=30)
        
        if response.status_code in [200, 201]:
            log_test(f"{method} {endpoint}", "PASS", f"Status: {response.status_code}")
            return response.json()
        else:
            log_test(f"{method} {endpoint}", "FAIL", f"Status: {response.status_code}")
            return None
    except Exception as e:
        log_test(f"{method} {endpoint}", "FAIL", f"Error: {str(e)}")
        return None

print("=" * 70)
print("COMPREHENSIVE API TEST SUITE")
print("=" * 70)
print()

# Test 1: Health/Root endpoint
print("🏥 TEST 1: Health Check")
print("-" * 70)
test_endpoint("GET", "/", description="Server health check")
print()

# Test 2: List models
print("🤖 TEST 2: List Models")
print("-" * 70)
models_response = test_endpoint("GET", "/v1/models", description="Get available models")
if models_response:
    print(f"   Models available: {len(models_response.get('data', []))}")
print()

# Test 3: Basic chat completion
print("💬 TEST 3: Basic Chat Completion")
print("-" * 70)
chat_data = {
    "model": "qwen-max-latest",
    "messages": [
        {"role": "user", "content": "What is 2+2?"}
    ],
    "temperature": 0.7
}
chat_response = test_endpoint("POST", "/v1/chat/completions", chat_data, "Simple math question")
if chat_response:
    content = chat_response.get('choices', [{}])[0].get('message', {}).get('content', '')
    print(f"   Response: {content[:100]}...")
print()

# Test 4: Chat with thinking mode
print("🧠 TEST 4: Chat with Thinking Mode")
print("-" * 70)
thinking_data = {
    "model": "qwen-max-latest",
    "messages": [
        {"role": "user", "content": "Explain quantum computing in simple terms"}
    ],
    "enable_thinking": True,
    "thinking_budget": 30000,
    "temperature": 0.8
}
thinking_response = test_endpoint("POST", "/v1/chat/completions", thinking_data, "Thinking mode enabled")
if thinking_response:
    content = thinking_response.get('choices', [{}])[0].get('message', {}).get('content', '')
    reasoning = thinking_response.get('choices', [{}])[0].get('message', {}).get('reasoning_content', '')
    print(f"   Response length: {len(content)} chars")
    if reasoning:
        print(f"   Reasoning present: Yes ({len(reasoning)} chars)")
print()

# Test 5: Multi-turn conversation
print("🔄 TEST 5: Multi-turn Conversation")
print("-" * 70)
conversation_data = {
    "model": "qwen-max-latest",
    "messages": [
        {"role": "user", "content": "Tell me a joke"},
        {"role": "assistant", "content": "Why did the programmer quit his job? Because he didn't get arrays!"},
        {"role": "user", "content": "That's funny! Tell me another one"}
    ]
}
conv_response = test_endpoint("POST", "/v1/chat/completions", conversation_data, "Multi-turn chat")
print()

# Test 6: Streaming chat (if supported)
print("📡 TEST 6: Streaming Chat")
print("-" * 70)
stream_data = {
    "model": "qwen-max-latest",
    "messages": [
        {"role": "user", "content": "Count from 1 to 5"}
    ],
    "stream": True
}
try:
    url = f"{BASE_URL}/v1/chat/completions"
    headers = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}
    response = requests.post(url, headers=headers, json=stream_data, stream=True, timeout=30)
    if response.status_code == 200:
        chunks_received = 0
        for line in response.iter_lines():
            if line:
                chunks_received += 1
        log_test("POST /v1/chat/completions (streaming)", "PASS", f"Received {chunks_received} chunks")
    else:
        log_test("POST /v1/chat/completions (streaming)", "FAIL", f"Status: {response.status_code}")
except Exception as e:
    log_test("POST /v1/chat/completions (streaming)", "FAIL", f"Error: {str(e)}")
print()

# Test 7: Chat with tools
print("🛠️  TEST 7: Chat with Tools")
print("-" * 70)
tools_data = {
    "model": "qwen-max-latest",
    "messages": [
        {"role": "user", "content": "Search the web for latest AI news"}
    ],
    "tools": [
        {
            "type": "web_search",
            "function": {
                "name": "web_search",
                "description": "Search the web for information"
            }
        }
    ]
}
tools_response = test_endpoint("POST", "/v1/chat/completions", tools_data, "Web search tool")
print()

# Test 8: Different models
print("🎯 TEST 8: Different Models")
print("-" * 70)
models_to_test = ["qwen-max-latest", "qwen-plus-latest", "qwen-turbo-latest"]
for model in models_to_test:
    model_data = {
        "model": model,
        "messages": [{"role": "user", "content": "Hi"}]
    }
    test_endpoint("POST", "/v1/chat/completions", model_data, f"Testing {model}")
print()

# Test 9: Temperature variations
print("🌡️  TEST 9: Temperature Variations")
print("-" * 70)
for temp in [0.0, 0.5, 1.0]:
    temp_data = {
        "model": "qwen-max-latest",
        "messages": [{"role": "user", "content": "Tell me something creative"}],
        "temperature": temp
    }
    test_endpoint("POST", "/v1/chat/completions", temp_data, f"Temperature {temp}")
print()

# Test 10: Max tokens limit
print("📏 TEST 10: Max Tokens Limit")
print("-" * 70)
tokens_data = {
    "model": "qwen-max-latest",
    "messages": [{"role": "user", "content": "Write a short story"}],
    "max_tokens": 100
}
tokens_response = test_endpoint("POST", "/v1/chat/completions", tokens_data, "Max tokens = 100")
print()

# Test 11: System message
print("⚙️  TEST 11: System Message")
print("-" * 70)
system_data = {
    "model": "qwen-max-latest",
    "messages": [
        {"role": "system", "content": "You are a helpful assistant that speaks like a pirate"},
        {"role": "user", "content": "Tell me about the weather"}
    ]
}
system_response = test_endpoint("POST", "/v1/chat/completions", system_data, "System message")
print()

print("=" * 70)
print("TEST SUMMARY")
print("=" * 70)
print(f"Total Tests: {results['total_tests']}")
print(f"✅ Passed: {results['passed']}")
print(f"❌ Failed: {results['failed']}")
print(f"Success Rate: {(results['passed']/results['total_tests']*100):.1f}%")
print()

# Save detailed results
with open('test_results.json', 'w') as f:
    json.dump(results, f, indent=2)
print("📊 Detailed results saved to: test_results.json")
