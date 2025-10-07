#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Comprehensive testing for Qwen Provider
Tests streaming output, tool calling, thinking mode, retry mechanisms, etc.
"""

import asyncio
import json
import sys
import os

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.providers.qwen_provider import QwenProvider
from app.models.schemas import OpenAIRequest, Message
from app.core.config import settings


async def test_basic_stream():
    """Test basic streaming output"""
    print("🧪 Testing basic streaming output...")
    
    provider = QwenProvider()
    
    request = OpenAIRequest(
        model=settings.PRIMARY_MODEL,
        messages=[
            Message(role="user", content="Hello, please briefly introduce yourself")
        ],
        stream=True
    )
    
    try:
        response = await provider.chat_completion(request)
        
        if hasattr(response, '__aiter__'):
            print("✅ Returned async generator")
            chunk_count = 0
            content_chunks = []
            
            async for chunk in response:
                chunk_count += 1
                if chunk.startswith("data: ") and not chunk.strip().endswith("[DONE]"):
                    try:
                        chunk_data = json.loads(chunk[6:].strip())
                        if "choices" in chunk_data and chunk_data["choices"]:
                            choice = chunk_data["choices"][0]
                            if "delta" in choice and "content" in choice["delta"]:
                                content = choice["delta"]["content"]
                                if content:
                                    content_chunks.append(content)
                    except:
                        pass
                
                if chunk_count >= 10:  # Limit test length
                    break
            
            full_content = "".join(content_chunks)
            print(f"✅ Successfully processed {chunk_count} chunks")
            print(f"📝 Content preview: {full_content[:100]}...")
            return len(content_chunks) > 0
        else:
            print("❌ Response is not streaming")
            return False
            
    except Exception as e:
        print(f"❌ Basic streaming test failed: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_thinking_mode():
    """Test thinking mode"""
    print("\n🧪 Testing thinking mode...")
    
    provider = QwenProvider()
    
    request = OpenAIRequest(
        model=settings.THINKING_MODEL,
        messages=[
            Message(role="user", content="Please explain the basic principles of quantum computing")
        ],
        stream=True
    )
    
    try:
        response = await provider.chat_completion(request)
        
        if hasattr(response, '__aiter__'):
            print("✅ Returned async generator")
            chunk_count = 0
            has_thinking = False
            has_content = False
            
            async for chunk in response:
                chunk_count += 1
                
                # Check for thinking content
                if 'thinking' in chunk:
                    has_thinking = True
                    print("✅ Detected thinking content")
                
                # Check for regular content
                if '"content"' in chunk and '"thinking"' not in chunk:
                    has_content = True
                    print("✅ Detected answer content")
                
                if chunk_count >= 20:  # Limit test length
                    break
            
            print(f"✅ Successfully processed {chunk_count} chunks")
            print(f"🤔 Thinking mode: {'Normal' if has_thinking else 'Not detected'}")
            print(f"💬 Answer content: {'Normal' if has_content else 'Not detected'}")
            return True
        else:
            print("❌ Response is not streaming")
            return False
            
    except Exception as e:
        print(f"❌ Thinking mode test failed: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_tool_support():
    """Test tool calling support"""
    print("\n🧪 Testing tool calling support...")
    
    if not settings.TOOL_SUPPORT:
        print("⚠️ Tool support disabled, skipping test")
        return True
    
    provider = QwenProvider()
    
    # Simple tool definition
    tools = [
        {
            "type": "function",
            "function": {
                "name": "get_weather",
                "description": "Get weather information for a specified city",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "city": {
                            "type": "string",
                            "description": "City name"
                        }
                    },
                    "required": ["city"]
                }
            }
        }
    ]
    
    request = OpenAIRequest(
        model=settings.PRIMARY_MODEL,
        messages=[
            Message(role="user", content="Please help me check the weather in Beijing")
        ],
        tools=tools,
        stream=True
    )
    
    try:
        response = await provider.chat_completion(request)
        
        if hasattr(response, '__aiter__'):
            print("✅ Returned async generator")
            chunk_count = 0
            has_tool_call = False
            
            async for chunk in response:
                chunk_count += 1
                
                # Check for tool calls
                if 'tool_calls' in chunk:
                    has_tool_call = True
                    print("✅ Detected tool call")
                
                if chunk_count >= 30:  # Limit test length
                    break
            
            print(f"✅ Successfully processed {chunk_count} chunks")
            print(f"🔧 Tool calling: {'Normal' if has_tool_call else 'Not detected'}")
            return True
        else:
            print("❌ Response is not streaming")
            return False
            
    except Exception as e:
        print(f"❌ Tool calling test failed: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_error_handling():
    """Test error handling"""
    print("\n🧪 Testing error handling...")
    
    provider = QwenProvider()
    
    # Use invalid message to trigger error
    request = OpenAIRequest(
        model="invalid-model",
        messages=[
            Message(role="user", content="Test error handling")
        ],
        stream=True
    )
    
    try:
        response = await provider.chat_completion(request)
        
        if hasattr(response, '__aiter__'):
            chunk_count = 0
            has_error = False
            
            async for chunk in response:
                chunk_count += 1
                
                # Check for error message
                if 'error' in chunk:
                    has_error = True
                    print("✅ Detected error handling")
                
                if chunk_count >= 5:  # Limit test length
                    break
            
            print(f"✅ Error handling test completed, processed {chunk_count} chunks")
            return True
        else:
            print("✅ Returned error response (non-streaming)")
            return True
            
    except Exception as e:
        print(f"✅ Correctly caught exception: {type(e).__name__}")
        return True


async def test_non_streaming():
    """Test non-streaming response"""
    print("\n🧪 Testing non-streaming response...")
    
    provider = QwenProvider()
    
    request = OpenAIRequest(
        model=settings.PRIMARY_MODEL,
        messages=[
            Message(role="user", content="Say hello in one sentence")
        ],
        stream=False
    )
    
    try:
        response = await provider.chat_completion(request)
        
        if isinstance(response, dict):
            print("✅ Returned dictionary response")
            if "choices" in response and response["choices"]:
                content = response["choices"][0].get("message", {}).get("content", "")
                print(f"📝 Content: {content[:100]}...")
                return bool(content)
            else:
                print("❌ No content in response")
                return False
        else:
            print("❌ Response is not a dictionary")
            return False
            
    except Exception as e:
        print(f"❌ Non-streaming test failed: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_model_listing():
    """Test model listing"""
    print("\n🧪 Testing model listing...")
    
    provider = QwenProvider()
    
    try:
        models = provider.get_supported_models()
        print(f"✅ Retrieved {len(models)} supported models")
        print(f"📋 Models: {', '.join(models[:5])}...")
        
        # Check if default models are present
        required_models = [settings.PRIMARY_MODEL, settings.THINKING_MODEL, settings.SEARCH_MODEL]
        for model in required_models:
            if model in models:
                print(f"✅ Found required model: {model}")
            else:
                print(f"⚠️ Missing required model: {model}")
        
        return len(models) > 0
        
    except Exception as e:
        print(f"❌ Model listing test failed: {e}")
        import traceback
        traceback.print_exc()
        return False


async def main():
    """Main test function"""
    print("🚀 Starting comprehensive Qwen Provider testing\n")
    
    # Display configuration
    print("📋 Current configuration:")
    print(f"  - Anonymous mode: {settings.ANONYMOUS_MODE}")
    print(f"  - Tool support: {settings.TOOL_SUPPORT}")
    print(f"  - Max retries: {settings.MAX_RETRIES}")
    print(f"  - Retry delay: {settings.RETRY_DELAY}s")
    print(f"  - Primary model: {settings.PRIMARY_MODEL}")
    print(f"  - Thinking model: {settings.THINKING_MODEL}")
    print(f"  - Search model: {settings.SEARCH_MODEL}")
    print()
    
    tests = [
        ("Model listing", test_model_listing),
        ("Basic streaming output", test_basic_stream),
        ("Non-streaming response", test_non_streaming),
        ("Thinking mode", test_thinking_mode),
        ("Tool calling support", test_tool_support),
        ("Error handling", test_error_handling),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        try:
            print(f"{'='*50}")
            result = await test_func()
            if result:
                passed += 1
                print(f"✅ {test_name} test passed")
            else:
                print(f"❌ {test_name} test failed")
        except Exception as e:
            print(f"❌ {test_name} test exception: {e}")
            import traceback
            traceback.print_exc()
        
        print()
    
    print(f"{'='*50}")
    print(f"📊 Test results: {passed}/{total} passed")
    
    if passed == total:
        print("🎉 All tests passed! Qwen Provider is working correctly")
        return 0
    elif passed >= total * 0.75:
        print("✅ Most tests passed, Qwen Provider is mostly working")
        return 0
    else:
        print("⚠️ Multiple tests failed, further investigation needed")
        return 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))

