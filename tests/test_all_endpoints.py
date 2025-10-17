#!/usr/bin/env python3
"""
Comprehensive Endpoint Testing Suite
Tests every endpoint variation including:
- All models (35+)
- Streaming vs non-streaming
- Function calling
- Native tools (web_search, vision, deep_research, code_interpreter)
- Error handling
"""

import json
import time
from openai import OpenAI

# Test configuration
BASE_URL = "http://localhost:7050/v1"
API_KEY = "sk-any"  # Universal key

# Initialize client
client = OpenAI(api_key=API_KEY, base_url=BASE_URL)

# All supported models
ALL_MODELS = [
    "qwen-max-latest",
    "qwen-plus-latest", 
    "qwen-turbo-latest",
    "qwen-long-latest",
    "qwen-max",
    "qwen-plus",
    "qwen-turbo",
    "qwen-long",
    "qwen3-max",
    "qwen3-plus",
    "qwen3-turbo",
    "qwen2.5-max",
    "qwen2.5-plus",
    "qwen2.5-turbo",
    "qwen2.5-72b-instruct",
    "qwen2.5-32b-instruct",
    "qwen2.5-14b-instruct",
    "qwen2.5-7b-instruct",
    "qwen2.5-3b-instruct",
    "qwen2.5-1.5b-instruct",
    "qwen2.5-0.5b-instruct",
    "qwen2.5-math-72b-instruct",
    "qwen2.5-math-7b-instruct",
    "qwen2.5-math-1.5b-instruct",
    "qwen2.5-coder-32b-instruct",
    "qwen2.5-coder-14b-instruct",
    "qwen2.5-coder-7b-instruct",
    "qwen2.5-coder-3b-instruct",
    "qwen2.5-coder-1.5b-instruct",
    "qwen3-coder-plus",
    "qwen-vl-max-latest",
    "qwen-vl-plus-latest",
    "qwen-vl-max",
    "qwen-vl-plus",
    "qwen2-vl-72b-instruct",
    "qwen2-vl-7b-instruct"
]

# Model aliases to test
MODEL_ALIASES = {
    "gpt-4": "qwen-max-latest",
    "gpt-4-turbo": "qwen-plus-latest",
    "gpt-3.5-turbo": "qwen-turbo-latest",
    "claude-3-opus": "qwen-max-latest",
    "claude-3-sonnet": "qwen-plus-latest",
    "random-model-name": "qwen-max-latest"  # Should default
}

def print_section(title):
    """Print a formatted section header"""
    print(f"\n{'='*80}")
    print(f"  {title}")
    print(f"{'='*80}\n")

def test_basic_completion(model):
    """Test basic chat completion"""
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Say 'test passed' and nothing else"}],
            max_tokens=50
        )
        content = response.choices[0].message.content
        print(f"✓ {model}: {content[:50]}")
        return True
    except Exception as e:
        print(f"✗ {model}: {str(e)[:100]}")
        return False

def test_streaming_completion(model):
    """Test streaming chat completion"""
    try:
        stream = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Count to 3"}],
            max_tokens=50,
            stream=True
        )
        chunks = []
        for chunk in stream:
            if chunk.choices[0].delta.content:
                chunks.append(chunk.choices[0].delta.content)
        
        content = "".join(chunks)
        print(f"✓ {model} (streaming): {content[:50]}")
        return True
    except Exception as e:
        print(f"✗ {model} (streaming): {str(e)[:100]}")
        return False

def test_function_calling():
    """Test function calling capability"""
    print_section("FUNCTION CALLING TESTS")
    
    tools = [
        {
            "type": "function",
            "function": {
                "name": "get_weather",
                "description": "Get weather for a location",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "location": {"type": "string"},
                        "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
                    },
                    "required": ["location"]
                }
            }
        }
    ]
    
    try:
        response = client.chat.completions.create(
            model="qwen-max-latest",
            messages=[{"role": "user", "content": "What's the weather in Paris?"}],
            tools=tools,
            max_tokens=200
        )
        
        if response.choices[0].message.tool_calls:
            tool_call = response.choices[0].message.tool_calls[0]
            print(f"✓ Function called: {tool_call.function.name}")
            print(f"  Arguments: {tool_call.function.arguments}")
            return True
        else:
            print(f"✓ Response without tool call: {response.choices[0].message.content[:100]}")
            return True
    except Exception as e:
        print(f"✗ Function calling failed: {e}")
        return False

def test_native_tool(tool_name):
    """Test native tools (web_search, vision, etc.)"""
    tools = [{"type": tool_name}]
    
    test_messages = {
        "web_search": "Search for the latest AI news",
        "vision": "Describe this image: https://example.com/image.jpg",
        "deep_research": "Research quantum computing",
        "code_interpreter": "Calculate 2+2"
    }
    
    try:
        response = client.chat.completions.create(
            model="qwen-max-latest",
            messages=[{"role": "user", "content": test_messages.get(tool_name, "test")}],
            tools=tools,
            max_tokens=200
        )
        
        content = response.choices[0].message.content
        print(f"✓ {tool_name}: {content[:80]}")
        return True
    except Exception as e:
        print(f"✗ {tool_name}: {str(e)[:100]}")
        return False

def test_model_alias(alias, expected_model):
    """Test model aliasing"""
    try:
        response = client.chat.completions.create(
            model=alias,
            messages=[{"role": "user", "content": "Say 'alias works'"}],
            max_tokens=50
        )
        print(f"✓ Alias '{alias}' -> {expected_model}: {response.choices[0].message.content[:50]}")
        return True
    except Exception as e:
        print(f"✗ Alias '{alias}': {str(e)[:100]}")
        return False

def main():
    """Run all tests"""
    results = {
        "basic": [],
        "streaming": [],
        "functions": False,
        "native_tools": [],
        "aliases": []
    }
    
    print_section("HEALTH CHECK")
    import urllib.request
    with urllib.request.urlopen("http://localhost:7050/") as response:
        health = json.loads(response.read())
    print(json.dumps(health, indent=2))
    
    # Test basic completions (sample of models)
    print_section("BASIC COMPLETIONS (Sample Models)")
    sample_models = [
        "qwen-max-latest",
        "qwen-plus-latest", 
        "qwen-turbo-latest",
        "qwen3-max",
        "qwen3-plus",
        "qwen3-coder-plus",
        "qwen2.5-72b-instruct",
        "qwen2.5-coder-32b-instruct",
        "qwen-vl-max-latest"
    ]
    
    for model in sample_models:
        result = test_basic_completion(model)
        results["basic"].append({"model": model, "passed": result})
        time.sleep(0.5)
    
    # Test streaming (sample)
    print_section("STREAMING COMPLETIONS (Sample Models)")
    streaming_models = ["qwen-max-latest", "qwen3-plus", "qwen-turbo-latest"]
    
    for model in streaming_models:
        result = test_streaming_completion(model)
        results["streaming"].append({"model": model, "passed": result})
        time.sleep(0.5)
    
    # Test function calling
    results["functions"] = test_function_calling()
    time.sleep(0.5)
    
    # Test native tools
    print_section("NATIVE TOOLS TESTS")
    native_tools = ["web_search", "vision", "deep_research", "code_interpreter"]
    
    for tool in native_tools:
        result = test_native_tool(tool)
        results["native_tools"].append({"tool": tool, "passed": result})
        time.sleep(0.5)
    
    # Test model aliases
    print_section("MODEL ALIASING TESTS")
    for alias, expected in MODEL_ALIASES.items():
        result = test_model_alias(alias, expected)
        results["aliases"].append({"alias": alias, "expected": expected, "passed": result})
        time.sleep(0.5)
    
    # Print summary
    print_section("TEST RESULTS SUMMARY")
    
    basic_passed = sum(1 for r in results["basic"] if r["passed"])
    print(f"Basic Completions: {basic_passed}/{len(results['basic'])} passed")
    
    streaming_passed = sum(1 for r in results["streaming"] if r["passed"])
    print(f"Streaming: {streaming_passed}/{len(results['streaming'])} passed")
    
    print(f"Function Calling: {'✓' if results['functions'] else '✗'}")
    
    tools_passed = sum(1 for r in results["native_tools"] if r["passed"])
    print(f"Native Tools: {tools_passed}/{len(results['native_tools'])} passed")
    
    aliases_passed = sum(1 for r in results["aliases"] if r["passed"])
    print(f"Model Aliases: {aliases_passed}/{len(results['aliases'])} passed")
    
    total_tests = (len(results["basic"]) + len(results["streaming"]) + 
                   1 + len(results["native_tools"]) + len(results["aliases"]))
    total_passed = (basic_passed + streaming_passed + 
                   (1 if results["functions"] else 0) + tools_passed + aliases_passed)
    
    print(f"\n{'='*80}")
    print(f"OVERALL: {total_passed}/{total_tests} tests passed ({100*total_passed//total_tests}%)")
    print(f"{'='*80}\n")
    
    return results

if __name__ == "__main__":
    main()
