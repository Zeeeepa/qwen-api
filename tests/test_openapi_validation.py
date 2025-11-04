#!/usr/bin/env python3
"""
Test script for OpenAPI validation middleware

Tests various scenarios to ensure proper validation of requests/responses.
"""

import sys
import asyncio
import httpx
from typing import Dict, Any

BASE_URL = "http://localhost:8080/v1"


class Colors:
    """ANSI color codes"""
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    RESET = "\033[0m"


def print_test(name: str):
    """Print test name"""
    print(f"\n{Colors.BLUE}▶ {name}{Colors.RESET}")


def print_success(message: str):
    """Print success message"""
    print(f"{Colors.GREEN}✅ {message}{Colors.RESET}")


def print_error(message: str):
    """Print error message"""
    print(f"{Colors.RED}❌ {message}{Colors.RESET}")


def print_info(message: str):
    """Print info message"""
    print(f"{Colors.YELLOW}ℹ️  {message}{Colors.RESET}")


async def test_invalid_request_missing_field():
    """Test request validation with missing required field"""
    print_test("Test 1: Invalid request - missing 'messages' field")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{BASE_URL}/chat/completions",
                json={
                    "model": "qwen-max"
                    # Missing required 'messages' field
                },
                timeout=10.0
            )
            
            if response.status_code == 400:
                error_data = response.json()
                if "error" in error_data and "validation" in error_data["error"]["message"].lower():
                    print_success("Request correctly rejected with validation error")
                    print_info(f"Error message: {error_data['error']['message']}")
                    return True
                else:
                    print_error("Request rejected but not with validation error")
                    return False
            else:
                print_error(f"Expected 400, got {response.status_code}")
                return False
                
        except Exception as e:
            print_error(f"Request failed: {e}")
            return False


async def test_invalid_request_wrong_type():
    """Test request validation with wrong field type"""
    print_test("Test 2: Invalid request - wrong type for 'messages'")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{BASE_URL}/chat/completions",
                json={
                    "model": "qwen-max",
                    "messages": "should_be_array"  # Wrong type
                },
                timeout=10.0
            )
            
            if response.status_code == 400:
                error_data = response.json()
                if "error" in error_data and "validation" in error_data["error"]["message"].lower():
                    print_success("Request correctly rejected with type validation error")
                    print_info(f"Error message: {error_data['error']['message']}")
                    return True
                else:
                    print_error("Request rejected but not with validation error")
                    return False
            else:
                print_error(f"Expected 400, got {response.status_code}")
                return False
                
        except Exception as e:
            print_error(f"Request failed: {e}")
            return False


async def test_valid_request():
    """Test that valid requests pass validation"""
    print_test("Test 3: Valid request - should pass validation")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{BASE_URL}/chat/completions",
                json={
                    "model": "qwen-max",
                    "messages": [
                        {"role": "user", "content": "Hello, test message"}
                    ],
                    "max_tokens": 50
                },
                timeout=30.0
            )
            
            if response.status_code == 200:
                data = response.json()
                if "choices" in data:
                    print_success("Valid request accepted and processed")
                    print_info(f"Response: {data['choices'][0]['message']['content'][:80]}...")
                    return True
                else:
                    print_error("Response missing expected fields")
                    return False
            else:
                print_error(f"Expected 200, got {response.status_code}")
                print_info(f"Response: {response.text[:200]}")
                return False
                
        except Exception as e:
            print_error(f"Request failed: {e}")
            return False


async def test_models_endpoint():
    """Test the /models endpoint"""
    print_test("Test 4: GET /models - should return valid model list")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{BASE_URL}/models", timeout=10.0)
            
            if response.status_code == 200:
                data = response.json()
                if "data" in data and isinstance(data["data"], list):
                    print_success(f"Models endpoint returned {len(data['data'])} models")
                    return True
                else:
                    print_error("Response missing 'data' field or not a list")
                    return False
            else:
                print_error(f"Expected 200, got {response.status_code}")
                return False
                
        except Exception as e:
            print_error(f"Request failed: {e}")
            return False


async def test_invalid_json():
    """Test handling of invalid JSON"""
    print_test("Test 5: Invalid JSON - should be rejected")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{BASE_URL}/chat/completions",
                content="invalid json {{{",
                headers={"Content-Type": "application/json"},
                timeout=10.0
            )
            
            if response.status_code == 400:
                error_data = response.json()
                if "error" in error_data:
                    print_success("Invalid JSON correctly rejected")
                    print_info(f"Error message: {error_data['error']['message']}")
                    return True
                else:
                    print_error("Request rejected but no error message")
                    return False
            else:
                print_error(f"Expected 400, got {response.status_code}")
                return False
                
        except Exception as e:
            print_error(f"Request failed: {e}")
            return False


async def test_image_generation_invalid():
    """Test image generation with invalid request"""
    print_test("Test 6: Image generation - invalid request")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{BASE_URL}/images/generations",
                json={
                    "prompt": 123  # Should be string
                },
                timeout=10.0
            )
            
            if response.status_code == 400:
                error_data = response.json()
                if "error" in error_data and "validation" in error_data["error"]["message"].lower():
                    print_success("Invalid image generation request rejected")
                    print_info(f"Error message: {error_data['error']['message']}")
                    return True
                else:
                    print_error("Request rejected but not with validation error")
                    return False
            else:
                print_error(f"Expected 400, got {response.status_code}")
                return False
                
        except Exception as e:
            print_error(f"Request failed: {e}")
            return False


async def main():
    """Run all tests"""
    print("=" * 80)
    print(f"{Colors.BLUE}OpenAPI Validation Middleware Tests{Colors.RESET}")
    print("=" * 80)
    
    print_info(f"Testing against: {BASE_URL}")
    print_info("Ensure server is running with validation middleware enabled")
    
    # Run all tests
    tests = [
        test_invalid_request_missing_field,
        test_invalid_request_wrong_type,
        test_valid_request,
        test_models_endpoint,
        test_invalid_json,
        test_image_generation_invalid,
    ]
    
    results = []
    for test in tests:
        try:
            result = await test()
            results.append(result)
        except Exception as e:
            print_error(f"Test crashed: {e}")
            results.append(False)
        
        # Small delay between tests
        await asyncio.sleep(0.5)
    
    # Print summary
    print("\n" + "=" * 80)
    print(f"{Colors.BLUE}Test Summary{Colors.RESET}")
    print("=" * 80)
    
    passed = sum(results)
    total = len(results)
    
    if passed == total:
        print_success(f"All {total} tests passed! 🎉")
        return 0
    else:
        print_error(f"{passed}/{total} tests passed")
        print_info(f"{total - passed} tests failed")
        return 1


if __name__ == "__main__":
    try:
        exit_code = asyncio.run(main())
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n\nTests interrupted by user")
        sys.exit(130)

