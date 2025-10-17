#!/usr/bin/env python3
"""
Comprehensive endpoint testing for Qwen API
Tests all available endpoints with various scenarios
"""

import asyncio
import httpx
import json
import time
from typing import Dict, Any, List

BASE_URL = "http://localhost:8080"
API_BASE = f"{BASE_URL}/v1"
HEADERS = {
    "Authorization": "Bearer sk-test-key",
    "Content-Type": "application/json"
}

class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN = "\033[96m"
    RESET = "\033[0m"
    BOLD = "\033[1m"

class EndpointTester:
    def __init__(self):
        self.results = []
        self.total_tests = 0
        self.passed_tests = 0
        self.failed_tests = 0
        
    def log_test(self, name: str, status: str, details: str = ""):
        """Log test result"""
        if status == "PASS":
            icon = "✅"
            color = Colors.GREEN
            self.passed_tests += 1
        elif status == "FAIL":
            icon = "❌"
            color = Colors.RED
            self.failed_tests += 1
        else:
            icon = "⚠️"
            color = Colors.YELLOW
            
        self.total_tests += 1
        result = f"{icon} {color}{name}{Colors.RESET}"
        if details:
            result += f"\n   {Colors.CYAN}{details}{Colors.RESET}"
        print(result)
        self.results.append((name, status, details))
        
    async def test_root_endpoint(self):
        """Test GET / - Root endpoint"""
        print(f"\n{Colors.BOLD}📍 Testing Root Endpoint{Colors.RESET}")
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(BASE_URL, timeout=5.0)
                if response.status_code == 200:
                    data = response.json()
                    self.log_test(
                        "GET /",
                        "PASS",
                        f"Status: {response.status_code}, Message: {data.get('message', 'N/A')}"
                    )
                else:
                    self.log_test("GET /", "FAIL", f"Status: {response.status_code}")
            except Exception as e:
                self.log_test("GET /", "FAIL", f"Error: {str(e)}")
                
    async def test_health_endpoint(self):
        """Test GET /health - Health check"""
        print(f"\n{Colors.BOLD}🏥 Testing Health Endpoint{Colors.RESET}")
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(f"{BASE_URL}/health", timeout=5.0)
                if response.status_code == 200:
                    data = response.json()
                    self.log_test(
                        "GET /health",
                        "PASS",
                        f"Status: {data.get('status', 'N/A')}"
                    )
                else:
                    self.log_test("GET /health", "FAIL", f"Status: {response.status_code}")
            except Exception as e:
                self.log_test("GET /health", "FAIL", f"Error: {str(e)}")
                
    async def test_models_endpoint(self):
        """Test GET /v1/models - List models"""
        print(f"\n{Colors.BOLD}📋 Testing Models Endpoint{Colors.RESET}")
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(
                    f"{API_BASE}/models",
                    headers=HEADERS,
                    timeout=5.0
                )
                if response.status_code == 200:
                    data = response.json()
                    models = data.get('data', [])
                    self.log_test(
                        "GET /v1/models",
                        "PASS",
                        f"Found {len(models)} models"
                    )
                else:
                    self.log_test("GET /v1/models", "FAIL", f"Status: {response.status_code}")
            except Exception as e:
                self.log_test("GET /v1/models", "FAIL", f"Error: {str(e)}")
                
    async def test_chat_completions_valid(self):
        """Test POST /v1/chat/completions - Valid request"""
        print(f"\n{Colors.BOLD}💬 Testing Chat Completions (Valid){Colors.RESET}")
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{API_BASE}/chat/completions",
                    headers=HEADERS,
                    json={
                        "model": "qwen-max",
                        "messages": [
                            {"role": "user", "content": "Say 'Hello!' in one word"}
                        ],
                        "max_tokens": 10
                    },
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    data = response.json()
                    content = data.get('choices', [{}])[0].get('message', {}).get('content', '')
                    self.log_test(
                        "POST /v1/chat/completions (valid)",
                        "PASS",
                        f"Response: {content[:50]}..."
                    )
                else:
                    self.log_test(
                        "POST /v1/chat/completions (valid)",
                        "FAIL",
                        f"Status: {response.status_code}, Body: {response.text[:100]}"
                    )
            except Exception as e:
                self.log_test("POST /v1/chat/completions (valid)", "FAIL", f"Error: {str(e)}")
                
    async def test_chat_completions_invalid_missing_field(self):
        """Test POST /v1/chat/completions - Invalid (missing messages)"""
        print(f"\n{Colors.BOLD}❌ Testing Chat Completions (Invalid - Missing Field){Colors.RESET}")
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{API_BASE}/chat/completions",
                    headers=HEADERS,
                    json={
                        "model": "qwen-max"
                        # Missing 'messages' field
                    },
                    timeout=10.0
                )
                
                if response.status_code == 400:
                    data = response.json()
                    error_msg = data.get('error', {}).get('message', '')
                    self.log_test(
                        "POST /v1/chat/completions (invalid - missing field)",
                        "PASS",
                        f"Correctly rejected: {error_msg[:80]}"
                    )
                else:
                    self.log_test(
                        "POST /v1/chat/completions (invalid - missing field)",
                        "FAIL",
                        f"Expected 400, got {response.status_code}"
                    )
            except Exception as e:
                self.log_test(
                    "POST /v1/chat/completions (invalid - missing field)",
                    "FAIL",
                    f"Error: {str(e)}"
                )
                
    async def test_chat_completions_invalid_wrong_type(self):
        """Test POST /v1/chat/completions - Invalid (wrong type)"""
        print(f"\n{Colors.BOLD}❌ Testing Chat Completions (Invalid - Wrong Type){Colors.RESET}")
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{API_BASE}/chat/completions",
                    headers=HEADERS,
                    json={
                        "model": "qwen-max",
                        "messages": "should_be_array"  # Wrong type
                    },
                    timeout=10.0
                )
                
                if response.status_code == 400:
                    data = response.json()
                    error_msg = data.get('error', {}).get('message', '')
                    self.log_test(
                        "POST /v1/chat/completions (invalid - wrong type)",
                        "PASS",
                        f"Correctly rejected: {error_msg[:80]}"
                    )
                else:
                    self.log_test(
                        "POST /v1/chat/completions (invalid - wrong type)",
                        "FAIL",
                        f"Expected 400, got {response.status_code}"
                    )
            except Exception as e:
                self.log_test(
                    "POST /v1/chat/completions (invalid - wrong type)",
                    "FAIL",
                    f"Error: {str(e)}"
                )
                
    async def test_chat_completions_streaming(self):
        """Test POST /v1/chat/completions - Streaming"""
        print(f"\n{Colors.BOLD}🌊 Testing Chat Completions (Streaming){Colors.RESET}")
        
        async with httpx.AsyncClient() as client:
            try:
                async with client.stream(
                    "POST",
                    f"{API_BASE}/chat/completions",
                    headers=HEADERS,
                    json={
                        "model": "qwen-max",
                        "messages": [
                            {"role": "user", "content": "Count from 1 to 3"}
                        ],
                        "stream": True,
                        "max_tokens": 20
                    },
                    timeout=30.0
                ) as response:
                    
                    if response.status_code == 200:
                        chunks_received = 0
                        async for line in response.aiter_lines():
                            if line.startswith("data: "):
                                chunks_received += 1
                                if chunks_received >= 3:  # Got enough chunks
                                    break
                        
                        self.log_test(
                            "POST /v1/chat/completions (streaming)",
                            "PASS",
                            f"Received {chunks_received} chunks"
                        )
                    else:
                        self.log_test(
                            "POST /v1/chat/completions (streaming)",
                            "FAIL",
                            f"Status: {response.status_code}"
                        )
            except Exception as e:
                self.log_test("POST /v1/chat/completions (streaming)", "FAIL", f"Error: {str(e)}")
                
    async def test_chat_completions_multiple_models(self):
        """Test POST /v1/chat/completions - Multiple models"""
        print(f"\n{Colors.BOLD}🔄 Testing Chat Completions (Multiple Models){Colors.RESET}")
        
        models_to_test = [
            "qwen-max",
            "qwen-turbo",
            "qwen2.5-max",
            "gpt-4"  # Should work via model mapping
        ]
        
        async with httpx.AsyncClient() as client:
            for model in models_to_test:
                try:
                    response = await client.post(
                        f"{API_BASE}/chat/completions",
                        headers=HEADERS,
                        json={
                            "model": model,
                            "messages": [
                                {"role": "user", "content": "Hi"}
                            ],
                            "max_tokens": 5
                        },
                        timeout=20.0
                    )
                    
                    if response.status_code == 200:
                        self.log_test(
                            f"POST /v1/chat/completions (model: {model})",
                            "PASS",
                            "Model accepted"
                        )
                    else:
                        self.log_test(
                            f"POST /v1/chat/completions (model: {model})",
                            "FAIL",
                            f"Status: {response.status_code}"
                        )
                except Exception as e:
                    self.log_test(
                        f"POST /v1/chat/completions (model: {model})",
                        "FAIL",
                        f"Error: {str(e)}"
                    )
                
                await asyncio.sleep(0.5)  # Small delay between requests
                
    async def test_image_generations_invalid(self):
        """Test POST /v1/images/generations - Invalid request"""
        print(f"\n{Colors.BOLD}🖼️ Testing Image Generations (Invalid){Colors.RESET}")
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{API_BASE}/images/generations",
                    headers=HEADERS,
                    json={
                        "prompt": 123  # Should be string
                    },
                    timeout=10.0
                )
                
                if response.status_code == 400:
                    data = response.json()
                    error_msg = data.get('error', {}).get('message', '')
                    self.log_test(
                        "POST /v1/images/generations (invalid)",
                        "PASS",
                        f"Correctly rejected: {error_msg[:80]}"
                    )
                else:
                    self.log_test(
                        "POST /v1/images/generations (invalid)",
                        "FAIL",
                        f"Expected 400, got {response.status_code}"
                    )
            except Exception as e:
                self.log_test("POST /v1/images/generations (invalid)", "FAIL", f"Error: {str(e)}")
                
    async def test_invalid_json(self):
        """Test invalid JSON handling"""
        print(f"\n{Colors.BOLD}📝 Testing Invalid JSON{Colors.RESET}")
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{API_BASE}/chat/completions",
                    content="invalid json {{{",
                    headers={"Content-Type": "application/json", "Authorization": "Bearer sk-test"},
                    timeout=10.0
                )
                
                if response.status_code == 400:
                    data = response.json()
                    error_msg = data.get('error', {}).get('message', '')
                    self.log_test(
                        "POST /v1/chat/completions (invalid JSON)",
                        "PASS",
                        f"Correctly rejected: {error_msg[:80]}"
                    )
                else:
                    self.log_test(
                        "POST /v1/chat/completions (invalid JSON)",
                        "FAIL",
                        f"Expected 400, got {response.status_code}"
                    )
            except Exception as e:
                self.log_test("POST /v1/chat/completions (invalid JSON)", "FAIL", f"Error: {str(e)}")
                
    def print_summary(self):
        """Print test summary"""
        print(f"\n{'='*80}")
        print(f"{Colors.BOLD}{Colors.CYAN}📊 TEST SUMMARY{Colors.RESET}")
        print(f"{'='*80}")
        
        print(f"\n{Colors.BOLD}Total Tests:{Colors.RESET} {self.total_tests}")
        print(f"{Colors.GREEN}✅ Passed:{Colors.RESET} {self.passed_tests}")
        print(f"{Colors.RED}❌ Failed:{Colors.RESET} {self.failed_tests}")
        
        pass_rate = (self.passed_tests / self.total_tests * 100) if self.total_tests > 0 else 0
        
        if pass_rate == 100:
            print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 ALL TESTS PASSED! 🎉{Colors.RESET}")
        elif pass_rate >= 80:
            print(f"\n{Colors.YELLOW}{Colors.BOLD}⚠️ Most tests passed ({pass_rate:.1f}%){Colors.RESET}")
        else:
            print(f"\n{Colors.RED}{Colors.BOLD}❌ Many tests failed ({pass_rate:.1f}%){Colors.RESET}")
        
        print(f"{'='*80}\n")
        
    async def run_all_tests(self):
        """Run all endpoint tests"""
        print(f"\n{Colors.BOLD}{Colors.MAGENTA}{'='*80}")
        print(f"🧪 COMPREHENSIVE ENDPOINT TESTING")
        print(f"{'='*80}{Colors.RESET}\n")
        
        print(f"{Colors.CYAN}Base URL: {BASE_URL}{Colors.RESET}")
        print(f"{Colors.CYAN}API Base: {API_BASE}{Colors.RESET}\n")
        
        # Run all tests
        await self.test_root_endpoint()
        await self.test_health_endpoint()
        await self.test_models_endpoint()
        await self.test_chat_completions_valid()
        await self.test_chat_completions_invalid_missing_field()
        await self.test_chat_completions_invalid_wrong_type()
        await self.test_chat_completions_streaming()
        await self.test_chat_completions_multiple_models()
        await self.test_image_generations_invalid()
        await self.test_invalid_json()
        
        # Print summary
        self.print_summary()
        
        return 0 if self.failed_tests == 0 else 1


async def main():
    """Main entry point"""
    tester = EndpointTester()
    exit_code = await tester.run_all_tests()
    return exit_code


if __name__ == "__main__":
    try:
        exit_code = asyncio.run(main())
        exit(exit_code)
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Tests interrupted by user{Colors.RESET}")
        exit(130)
