#!/usr/bin/env python3
"""
Focused validation testing - tests only validation middleware functionality
No dependency on actual Qwen API models
"""

import asyncio
import httpx
import json

BASE_URL = "http://localhost:8080"
API_BASE = f"{BASE_URL}/v1"
HEADERS = {
    "Authorization": "Bearer sk-test-key",
    "Content-Type": "application/json"
}

class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    CYAN = "\033[96m"
    RESET = "\033[0m"
    BOLD = "\033[1m"

async def test_validation():
    """Test validation middleware functionality"""
    passed = 0
    total = 0
    
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*80}")
    print(f"🛡️  OPENAPI VALIDATION MIDDLEWARE TESTS")
    print(f"{'='*80}{Colors.RESET}\n")
    
    async with httpx.AsyncClient() as client:
        tests = [
            {
                "name": "✅ GET / - Root endpoint",
                "method": "GET",
                "url": BASE_URL,
                "expected_status": 200,
                "headers": {}
            },
            {
                "name": "✅ GET /health - Health check",
                "method": "GET",
                "url": f"{BASE_URL}/health",
                "expected_status": 200,
                "headers": {}
            },
            {
                "name": "✅ GET /v1/models - List models",
                "method": "GET",
                "url": f"{API_BASE}/models",
                "expected_status": 200,
                "headers": HEADERS
            },
            {
                "name": "❌ POST /v1/chat/completions - Missing required field",
                "method": "POST",
                "url": f"{API_BASE}/chat/completions",
                "expected_status": 400,
                "headers": HEADERS,
                "json": {"model": "test"}  # Missing 'messages'
            },
            {
                "name": "❌ POST /v1/chat/completions - Wrong field type",
                "method": "POST",
                "url": f"{API_BASE}/chat/completions",
                "expected_status": 400,
                "headers": HEADERS,
                "json": {"model": "test", "messages": "not_array"}  # Wrong type
            },
            {
                "name": "❌ POST /v1/chat/completions - Invalid JSON",
                "method": "POST",
                "url": f"{API_BASE}/chat/completions",
                "expected_status": 400,
                "headers": {"Content-Type": "application/json", "Authorization": "Bearer sk-test"},
                "content": "invalid json {{{"
            },
            {
                "name": "❌ POST /v1/images/generations - Wrong prompt type",
                "method": "POST",
                "url": f"{API_BASE}/images/generations",
                "expected_status": 400,
                "headers": HEADERS,
                "json": {"prompt": 123}  # Should be string
            },
            {
                "name": "✅ POST /v1/chat/completions - Valid request (qwen2.5-max)",
                "method": "POST",
                "url": f"{API_BASE}/chat/completions",
                "expected_status": 200,
                "headers": HEADERS,
                "json": {
                    "model": "qwen2.5-max",  # This model works
                    "messages": [{"role": "user", "content": "Hi"}],
                    "max_tokens": 5
                }
            },
            {
                "name": "✅ POST /v1/chat/completions - Valid request (gpt-4 mapping)",
                "method": "POST",
                "url": f"{API_BASE}/chat/completions",
                "expected_status": 200,
                "headers": HEADERS,
                "json": {
                    "model": "gpt-4",  # Maps to qwen-max-latest
                    "messages": [{"role": "user", "content": "Hello"}],
                    "max_tokens": 5
                }
            },
        ]
        
        for test in tests:
            total += 1
            try:
                if test["method"] == "GET":
                    response = await client.get(
                        test["url"],
                        headers=test.get("headers", {}),
                        timeout=5.0
                    )
                else:  # POST
                    if "content" in test:
                        response = await client.post(
                            test["url"],
                            content=test["content"],
                            headers=test["headers"],
                            timeout=10.0
                        )
                    else:
                        response = await client.post(
                            test["url"],
                            headers=test["headers"],
                            json=test["json"],
                            timeout=30.0  # Longer timeout for actual API calls
                        )
                
                if response.status_code == test["expected_status"]:
                    passed += 1
                    print(f"{Colors.GREEN}✅ {test['name']}{Colors.RESET}")
                    if response.status_code == 400:
                        data = response.json()
                        error_msg = data.get('error', {}).get('message', '')
                        print(f"   {Colors.CYAN}→ {error_msg[:80]}{Colors.RESET}")
                else:
                    print(f"{Colors.RED}❌ {test['name']}{Colors.RESET}")
                    print(f"   Expected {test['expected_status']}, got {response.status_code}")
                    if response.status_code >= 400:
                        print(f"   {response.text[:100]}")
                        
            except Exception as e:
                print(f"{Colors.RED}❌ {test['name']}{Colors.RESET}")
                print(f"   Error: {str(e)[:80]}")
        
        # Summary
        print(f"\n{Colors.BOLD}{'='*80}")
        print(f"📊 TEST SUMMARY")
        print(f"{'='*80}{Colors.RESET}")
        print(f"\n{Colors.BOLD}Total Tests:{Colors.RESET} {total}")
        print(f"{Colors.GREEN}✅ Passed:{Colors.RESET} {passed}")
        print(f"{Colors.RED}❌ Failed:{Colors.RESET} {total - passed}")
        
        pass_rate = (passed / total * 100) if total > 0 else 0
        
        if pass_rate == 100:
            print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 ALL TESTS PASSED! 🎉{Colors.RESET}\n")
        elif pass_rate >= 80:
            print(f"\n{Colors.CYAN}{Colors.BOLD}⚠️  Most tests passed ({pass_rate:.1f}%){Colors.RESET}\n")
        else:
            print(f"\n{Colors.RED}{Colors.BOLD}❌ Many tests failed ({pass_rate:.1f}%){Colors.RESET}\n")
        
        return passed == total


async def main():
    success = await test_validation()
    return 0 if success else 1

if __name__ == "__main__":
    try:
        exit_code = asyncio.run(main())
        exit(exit_code)
    except KeyboardInterrupt:
        print(f"\n\n{Colors.CYAN}Tests interrupted{Colors.RESET}")
        exit(130)

