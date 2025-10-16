#!/usr/bin/env python3
"""
Comprehensive Test Suite for Qwen API
Tests all models, endpoints, and features
"""

import asyncio
import json
import time
from typing import Dict, List, Optional
import httpx
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8096"
API_KEY = "sk-test"  # Any key works in anonymous mode

# Test data
MODELS_TO_TEST = [
    {
        "name": "QVQ-Max",
        "id": "qvq-max",
        "capabilities": {"vision": True, "reasoning": True, "web_search": False, "tools": False}
    },
    {
        "name": "Qwen-Deep-Research", 
        "id": "qwen-deep-research",
        "capabilities": {"vision": False, "reasoning": True, "web_search": False, "tools": False}
    },
    {
        "name": "Qwen3-Next-80B-A3B",
        "id": "qwen3-next-80b-a3b", 
        "capabilities": {"vision": True, "reasoning": True, "web_search": True, "tools": False}
    },
    {
        "name": "Qwen3-235B-A22B-2507",
        "id": "qwen3-235b-a22b-2507",
        "capabilities": {"vision": True, "reasoning": True, "web_search": True, "tools": False}
    },
    {
        "name": "qwen3-coder-plus",
        "id": "qwen3-coder-plus",
        "capabilities": {"vision": True, "reasoning": False, "web_search": True, "tools": True}
    },
    {
        "name": "Qwen3-Coder",
        "id": "qwen3-coder",
        "capabilities": {"vision": True, "reasoning": False, "web_search": True, "tools": True}
    },
    {
        "name": "Qwen-Web-Dev",
        "id": "qwen-web-dev",
        "capabilities": {"vision": True, "reasoning": False, "web_search": False, "tools": False}
    },
    {
        "name": "Qwen-Full-Stack",
        "id": "qwen-full-stack",
        "capabilities": {"vision": True, "reasoning": False, "web_search": False, "tools": False}
    },
    {
        "name": "Qwen3-Max-latest",
        "id": "qwen3-max-latest",
        "capabilities": {"vision": True, "reasoning": False, "web_search": True, "tools": False}
    },
    {
        "name": "Qwen3-Omni-Flash",
        "id": "qwen3-omni-flash",
        "capabilities": {"vision": True, "reasoning": True, "web_search": False, "tools": False}
    },
    {
        "name": "Qwen3-VL-235B-A22B",
        "id": "qwen3-vl-235b-a22b",
        "capabilities": {"vision": True, "reasoning": True, "web_search": False, "tools": False}
    },
    {
        "name": "QWQ-32B",
        "id": "qwq-32b",
        "capabilities": {"vision": False, "reasoning": True, "web_search": True, "tools": False}
    }
]

ENDPOINTS_TO_TEST = [
    {"path": "/health", "method": "GET", "description": "Health check"},
    {"path": "/v1/models", "method": "GET", "description": "List models"},
    {"path": "/v1/validate", "method": "POST", "description": "Validate token"},
    {"path": "/v1/refresh", "method": "POST", "description": "Refresh token"},
    {"path": "/v1/chat/completions", "method": "POST", "description": "Chat completions"},
    {"path": "/v1/images/generations", "method": "POST", "description": "Image generation"},
    {"path": "/v1/images/edits", "method": "POST", "description": "Image editing"},
    {"path": "/v1/videos/generations", "method": "POST", "description": "Video generation"},
]

class Colors:
    """ANSI color codes"""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'

class TestResults:
    """Track test results"""
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.skipped = 0
        self.results = []
        self.start_time = time.time()
    
    def add_result(self, test_name: str, status: str, details: str = ""):
        """Add a test result"""
        self.results.append({
            "test": test_name,
            "status": status,
            "details": details,
            "timestamp": datetime.now().isoformat()
        })
        
        if status == "PASS":
            self.passed += 1
        elif status == "FAIL":
            self.failed += 1
        else:
            self.skipped += 1
    
    def print_summary(self):
        """Print test summary"""
        duration = time.time() - self.start_time
        total = self.passed + self.failed + self.skipped
        
        print(f"\n{Colors.BOLD}{'='*80}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.CYAN}TEST SUMMARY{Colors.END}")
        print(f"{Colors.BOLD}{'='*80}{Colors.END}\n")
        
        print(f"Total Tests: {total}")
        print(f"{Colors.GREEN}✅ Passed: {self.passed}{Colors.END}")
        print(f"{Colors.RED}❌ Failed: {self.failed}{Colors.END}")
        print(f"{Colors.YELLOW}⏭️  Skipped: {self.skipped}{Colors.END}")
        print(f"Duration: {duration:.2f}s\n")
        
        if self.failed > 0:
            print(f"{Colors.RED}{Colors.BOLD}FAILED TESTS:{Colors.END}")
            for result in self.results:
                if result["status"] == "FAIL":
                    print(f"  {Colors.RED}❌ {result['test']}{Colors.END}")
                    if result["details"]:
                        print(f"     {result['details']}")

results = TestResults()

async def test_endpoint(client: httpx.AsyncClient, endpoint: Dict) -> bool:
    """Test a single endpoint"""
    test_name = f"{endpoint['method']} {endpoint['path']}"
    print(f"\n{Colors.CYAN}Testing: {test_name}{Colors.END}")
    
    try:
        if endpoint["method"] == "GET":
            response = await client.get(f"{BASE_URL}{endpoint['path']}")
        else:
            # POST with appropriate payload
            if "chat/completions" in endpoint["path"]:
                payload = {
                    "model": "gpt-4",
                    "messages": [{"role": "user", "content": "Say 'test' only"}],
                    "max_tokens": 10
                }
            elif "validate" in endpoint["path"]:
                payload = {"token": API_KEY}
            elif "refresh" in endpoint["path"]:
                payload = {"token": API_KEY}
            elif "images/generations" in endpoint["path"]:
                payload = {
                    "model": "qwen-vl-max",
                    "prompt": "a test image",
                    "n": 1
                }
            elif "images/edits" in endpoint["path"]:
                payload = {
                    "model": "qwen-vl-max",
                    "image": "base64_image_data",
                    "prompt": "edit test"
                }
            elif "videos/generations" in endpoint["path"]:
                payload = {
                    "model": "qwen-video",
                    "prompt": "a test video"
                }
            else:
                payload = {}
            
            response = await client.post(
                f"{BASE_URL}{endpoint['path']}",
                json=payload,
                headers={"Authorization": f"Bearer {API_KEY}"}
            )
        
        if response.status_code in [200, 201]:
            print(f"  {Colors.GREEN}✅ Status: {response.status_code}{Colors.END}")
            results.add_result(test_name, "PASS", f"Status: {response.status_code}")
            return True
        else:
            print(f"  {Colors.RED}❌ Status: {response.status_code}{Colors.END}")
            print(f"  Response: {response.text[:200]}")
            results.add_result(test_name, "FAIL", f"Status: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"  {Colors.RED}❌ Error: {str(e)}{Colors.END}")
        results.add_result(test_name, "FAIL", str(e))
        return False

async def test_model_chat(client: httpx.AsyncClient, model: Dict) -> bool:
    """Test chat completion with a specific model"""
    test_name = f"Chat with {model['name']}"
    print(f"\n{Colors.CYAN}Testing: {test_name}{Colors.END}")
    
    try:
        payload = {
            "model": model["id"],
            "messages": [
                {"role": "user", "content": "Say 'Hello from Qwen!' only"}
            ],
            "max_tokens": 50
        }
        
        response = await client.post(
            f"{BASE_URL}/v1/chat/completions",
            json=payload,
            headers={"Authorization": f"Bearer {API_KEY}"},
            timeout=30.0
        )
        
        if response.status_code == 200:
            data = response.json()
            if "choices" in data and len(data["choices"]) > 0:
                content = data["choices"][0]["message"]["content"]
                print(f"  {Colors.GREEN}✅ Response: {content[:100]}{Colors.END}")
                results.add_result(test_name, "PASS", f"Got response: {content[:50]}...")
                return True
        
        print(f"  {Colors.RED}❌ Status: {response.status_code}{Colors.END}")
        results.add_result(test_name, "FAIL", f"Status: {response.status_code}")
        return False
        
    except Exception as e:
        print(f"  {Colors.RED}❌ Error: {str(e)}{Colors.END}")
        results.add_result(test_name, "FAIL", str(e))
        return False

async def test_model_streaming(client: httpx.AsyncClient, model: Dict) -> bool:
    """Test streaming chat completion"""
    test_name = f"Streaming chat with {model['name']}"
    print(f"\n{Colors.CYAN}Testing: {test_name}{Colors.END}")
    
    try:
        payload = {
            "model": model["id"],
            "messages": [
                {"role": "user", "content": "Count to 5"}
            ],
            "stream": True,
            "max_tokens": 30
        }
        
        chunks_received = 0
        async with client.stream(
            "POST",
            f"{BASE_URL}/v1/chat/completions",
            json=payload,
            headers={"Authorization": f"Bearer {API_KEY}"},
            timeout=30.0
        ) as response:
            if response.status_code == 200:
                async for chunk in response.aiter_bytes():
                    if chunk:
                        chunks_received += 1
                
                if chunks_received > 0:
                    print(f"  {Colors.GREEN}✅ Received {chunks_received} chunks{Colors.END}")
                    results.add_result(test_name, "PASS", f"{chunks_received} chunks")
                    return True
        
        print(f"  {Colors.RED}❌ No chunks received{Colors.END}")
        results.add_result(test_name, "FAIL", "No chunks")
        return False
        
    except Exception as e:
        print(f"  {Colors.RED}❌ Error: {str(e)}{Colors.END}")
        results.add_result(test_name, "FAIL", str(e))
        return False

async def run_all_tests():
    """Run all tests"""
    print(f"{Colors.BOLD}{Colors.HEADER}")
    print("╔════════════════════════════════════════════════════════════╗")
    print("║                                                            ║")
    print("║          🧪 Qwen API Comprehensive Test Suite 🧪          ║")
    print("║                                                            ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print(f"{Colors.END}\n")
    
    print(f"{Colors.BOLD}Configuration:{Colors.END}")
    print(f"  Base URL: {BASE_URL}")
    print(f"  API Key: {API_KEY}")
    print(f"  Models to test: {len(MODELS_TO_TEST)}")
    print(f"  Endpoints to test: {len(ENDPOINTS_TO_TEST)}\n")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Test basic endpoints first
        print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}PHASE 1: Testing Basic Endpoints{Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.END}")
        
        for endpoint in ENDPOINTS_TO_TEST:
            await test_endpoint(client, endpoint)
            await asyncio.sleep(0.5)  # Rate limiting
        
        # Test all models with chat completion
        print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}PHASE 2: Testing Models (Chat Completion){Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.END}")
        
        for model in MODELS_TO_TEST:
            await test_model_chat(client, model)
            await asyncio.sleep(0.5)
        
        # Test streaming for a few models
        print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}PHASE 3: Testing Streaming{Colors.END}")
        print(f"{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.END}")
        
        streaming_models = MODELS_TO_TEST[:3]  # Test first 3 models
        for model in streaming_models:
            await test_model_streaming(client, model)
            await asyncio.sleep(0.5)
    
    # Print summary
    results.print_summary()
    
    # Save results to file
    with open("test_results.json", "w") as f:
        json.dump({
            "summary": {
                "total": results.passed + results.failed + results.skipped,
                "passed": results.passed,
                "failed": results.failed,
                "skipped": results.skipped,
                "duration": time.time() - results.start_time
            },
            "results": results.results
        }, f, indent=2)
    
    print(f"\n{Colors.CYAN}📄 Detailed results saved to: test_results.json{Colors.END}\n")
    
    return results.failed == 0

if __name__ == "__main__":
    success = asyncio.run(run_all_tests())
    exit(0 if success else 1)

