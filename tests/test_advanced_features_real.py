#!/usr/bin/env python3
"""
REAL API TESTS - Advanced Features
Tests web search, code generation, vision, and deep research
Using actual qwen.aikit.club API (NOT simulated)
"""

import requests
import json
import time
from typing import Dict, Any

# Real API Configuration
REAL_API_URL = "https://qwen.aikit.club/v1/chat/completions"
REAL_API_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjI3ZGUyYzVlLTYzZDYtNDU2MC1iNmQ3LTI2MDk0NDhjZmJmNiIsImxhc3RfcGFzc3dvcmRfY2hhbmdlIjoxNzU5ODg4MzE5LCJleHAiOjE3NjExODEwNDh9.rzgky_5WMlCnDz6gREPfZPwLz8CJ-3sLuJ3FBsbbOUE"

# Local server for comparison
LOCAL_API_URL = "http://localhost:8080/v1/chat/completions"
LOCAL_API_TOKEN = "sk-any"

class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    CYAN = "\033[96m"
    MAGENTA = "\033[95m"
    BLUE = "\033[94m"
    RESET = "\033[0m"
    BOLD = "\033[1m"

def test_web_search(api_url: str, api_token: str, label: str) -> tuple[bool, str]:
    """Test web search tool"""
    print(f"\n{Colors.CYAN}🔍 Testing Web Search Tool ({label}){Colors.RESET}")
    
    payload = {
        "model": "qwen-max-latest",
        "tools": [{"type": "web_search"}],
        "messages": [
            {
                "role": "user",
                "content": "What are the latest AI developments?"
            }
        ],
        "stream": False
    }
    
    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "authorization": f"Bearer {api_token}"
    }
    
    try:
        start_time = time.time()
        response = requests.post(api_url, json=payload, headers=headers, timeout=60.0)
        elapsed = time.time() - start_time
        
        if response.status_code == 200:
            data = response.json()
            content = data.get('choices', [{}])[0].get('message', {}).get('content', '')
            
            print(f"{Colors.GREEN}✅ SUCCESS{Colors.RESET}")
            print(f"   Response length: {len(content)} chars")
            print(f"   Time: {elapsed:.2f}s")
            print(f"   Preview: {Colors.CYAN}{content[:150]}...{Colors.RESET}")
            
            # Check if it actually used web search
            has_search_info = any(indicator in content.lower() for indicator in 
                                 ['search', 'recent', 'latest', 'according to', 'based on'])
            if has_search_info:
                print(f"   {Colors.GREEN}🔍 Web search likely used{Colors.RESET}")
            
            return True, content[:200]
        else:
            print(f"{Colors.RED}❌ FAILED{Colors.RESET}")
            print(f"   Status: {response.status_code}")
            print(f"   Error: {response.text[:200]}")
            return False, response.text[:200]
            
    except Exception as e:
        print(f"{Colors.RED}❌ FAILED{Colors.RESET}")
        print(f"   Error: {str(e)[:200]}")
        return False, str(e)[:200]


def test_code_generation(api_url: str, api_token: str, label: str) -> tuple[bool, str]:
    """Test code generation with qwen3-coder-plus"""
    print(f"\n{Colors.CYAN}💻 Testing Code Generation ({label}){Colors.RESET}")
    
    payload = {
        "model": "qwen3-coder-plus",
        "tools": [{"type": "code"}],
        "messages": [
            {
                "role": "user",
                "content": "Write a JavaScript function to add two numbers"
            }
        ],
        "stream": False
    }
    
    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "authorization": f"Bearer {api_token}"
    }
    
    try:
        start_time = time.time()
        response = requests.post(api_url, json=payload, headers=headers, timeout=30.0)
        elapsed = time.time() - start_time
        
        if response.status_code == 200:
            data = response.json()
            content = data.get('choices', [{}])[0].get('message', {}).get('content', '')
            
            print(f"{Colors.GREEN}✅ SUCCESS{Colors.RESET}")
            print(f"   Response length: {len(content)} chars")
            print(f"   Time: {elapsed:.2f}s")
            print(f"   Preview: {Colors.CYAN}{content[:150]}...{Colors.RESET}")
            
            # Check if it contains code
            has_code = any(indicator in content for indicator in 
                          ['function', 'return', '{', '}', '=>'])
            if has_code:
                print(f"   {Colors.GREEN}💻 Code detected in response{Colors.RESET}")
            
            return True, content[:200]
        else:
            print(f"{Colors.RED}❌ FAILED{Colors.RESET}")
            print(f"   Status: {response.status_code}")
            print(f"   Error: {response.text[:200]}")
            return False, response.text[:200]
            
    except Exception as e:
        print(f"{Colors.RED}❌ FAILED{Colors.RESET}")
        print(f"   Error: {str(e)[:200]}")
        return False, str(e)[:200]


def test_vision_multimodal(api_url: str, api_token: str, label: str) -> tuple[bool, str]:
    """Test vision/multimodal capabilities"""
    print(f"\n{Colors.CYAN}🖼️  Testing Vision/Multimodal ({label}){Colors.RESET}")
    
    payload = {
        "model": "qwen-max-latest",
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": "What do you see in this image?"
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": "https://download.samplelib.com/png/sample-hut-400x300.png"
                        }
                    }
                ]
            }
        ],
        "stream": False
    }
    
    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "authorization": f"Bearer {api_token}"
    }
    
    try:
        start_time = time.time()
        response = requests.post(api_url, json=payload, headers=headers, timeout=30.0)
        elapsed = time.time() - start_time
        
        if response.status_code == 200:
            data = response.json()
            content = data.get('choices', [{}])[0].get('message', {}).get('content', '')
            
            print(f"{Colors.GREEN}✅ SUCCESS{Colors.RESET}")
            print(f"   Response length: {len(content)} chars")
            print(f"   Time: {elapsed:.2f}s")
            print(f"   Preview: {Colors.CYAN}{content[:150]}...{Colors.RESET}")
            
            # Check if it describes visual content
            has_visual_desc = any(indicator in content.lower() for indicator in 
                                 ['image', 'see', 'shows', 'picture', 'hut', 'building'])
            if has_visual_desc:
                print(f"   {Colors.GREEN}🖼️  Vision analysis detected{Colors.RESET}")
            
            return True, content[:200]
        else:
            print(f"{Colors.RED}❌ FAILED{Colors.RESET}")
            print(f"   Status: {response.status_code}")
            print(f"   Error: {response.text[:200]}")
            return False, response.text[:200]
            
    except Exception as e:
        print(f"{Colors.RED}❌ FAILED{Colors.RESET}")
        print(f"   Error: {str(e)[:200]}")
        return False, str(e)[:200]


def test_deep_research(api_url: str, api_token: str, label: str) -> tuple[bool, str]:
    """Test deep research model"""
    print(f"\n{Colors.CYAN}🔬 Testing Deep Research ({label}){Colors.RESET}")
    
    payload = {
        "model": "qwen-deep-research",
        "messages": [
            {
                "role": "user",
                "content": "Research the latest developments in quantum computing"
            }
        ],
        "stream": False
    }
    
    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "authorization": f"Bearer {api_token}"
    }
    
    try:
        start_time = time.time()
        response = requests.post(api_url, json=payload, headers=headers, timeout=60.0)
        elapsed = time.time() - start_time
        
        if response.status_code == 200:
            data = response.json()
            content = data.get('choices', [{}])[0].get('message', {}).get('content', '')
            
            print(f"{Colors.GREEN}✅ SUCCESS{Colors.RESET}")
            print(f"   Response length: {len(content)} chars")
            print(f"   Time: {elapsed:.2f}s")
            print(f"   Preview: {Colors.CYAN}{content[:150]}...{Colors.RESET}")
            
            # Check for research-style content
            has_research = any(indicator in content.lower() for indicator in 
                             ['research', 'development', 'quantum', 'recent', 'breakthrough'])
            if has_research:
                print(f"   {Colors.GREEN}🔬 Research content detected{Colors.RESET}")
            
            return True, content[:200]
        else:
            print(f"{Colors.RED}❌ FAILED{Colors.RESET}")
            print(f"   Status: {response.status_code}")
            print(f"   Error: {response.text[:200]}")
            return False, response.text[:200]
            
    except Exception as e:
        print(f"{Colors.RED}❌ FAILED{Colors.RESET}")
        print(f"   Error: {str(e)[:200]}")
        return False, str(e)[:200]


def main():
    """Run all advanced feature tests"""
    print(f"\n{Colors.BOLD}{Colors.MAGENTA}{'='*80}")
    print(f"🚀 ADVANCED FEATURES - REAL API TESTS")
    print(f"{'='*80}{Colors.RESET}\n")
    
    print(f"{Colors.CYAN}Testing against REAL API: {REAL_API_URL}{Colors.RESET}")
    print(f"{Colors.CYAN}Local server: {LOCAL_API_URL}{Colors.RESET}\n")
    
    results = {
        "real": {},
        "local": {}
    }
    
    # Test against REAL API
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*80}")
    print(f"📡 TESTING REAL API (qwen.aikit.club)")
    print(f"{'='*80}{Colors.RESET}")
    
    results["real"]["web_search"] = test_web_search(REAL_API_URL, REAL_API_TOKEN, "REAL API")
    time.sleep(1)
    
    results["real"]["code_gen"] = test_code_generation(REAL_API_URL, REAL_API_TOKEN, "REAL API")
    time.sleep(1)
    
    results["real"]["vision"] = test_vision_multimodal(REAL_API_URL, REAL_API_TOKEN, "REAL API")
    time.sleep(1)
    
    results["real"]["deep_research"] = test_deep_research(REAL_API_URL, REAL_API_TOKEN, "REAL API")
    
    # Test against LOCAL server
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*80}")
    print(f"🏠 TESTING LOCAL SERVER (localhost:8080)")
    print(f"{'='*80}{Colors.RESET}")
    
    results["local"]["web_search"] = test_web_search(LOCAL_API_URL, LOCAL_API_TOKEN, "LOCAL")
    time.sleep(1)
    
    results["local"]["code_gen"] = test_code_generation(LOCAL_API_URL, LOCAL_API_TOKEN, "LOCAL")
    time.sleep(1)
    
    results["local"]["vision"] = test_vision_multimodal(LOCAL_API_URL, LOCAL_API_TOKEN, "LOCAL")
    time.sleep(1)
    
    results["local"]["deep_research"] = test_deep_research(LOCAL_API_URL, LOCAL_API_TOKEN, "LOCAL")
    
    # Summary
    print(f"\n{Colors.BOLD}{'='*80}")
    print(f"📊 TEST SUMMARY")
    print(f"{'='*80}{Colors.RESET}\n")
    
    features = ["web_search", "code_gen", "vision", "deep_research"]
    feature_names = ["Web Search", "Code Generation", "Vision/Multimodal", "Deep Research"]
    
    print(f"{Colors.BOLD}Feature Comparison:{Colors.RESET}\n")
    print(f"{'Feature':<25} {'Real API':<15} {'Local Server':<15}")
    print(f"{'-'*55}")
    
    for feat, name in zip(features, feature_names):
        real_status = "✅ Pass" if results["real"][feat][0] else "❌ Fail"
        local_status = "✅ Pass" if results["local"][feat][0] else "❌ Fail"
        
        real_color = Colors.GREEN if results["real"][feat][0] else Colors.RED
        local_color = Colors.GREEN if results["local"][feat][0] else Colors.RED
        
        print(f"{name:<25} {real_color}{real_status:<15}{Colors.RESET} {local_color}{local_status:<15}{Colors.RESET}")
    
    # Calculate totals
    real_passed = sum(1 for feat in features if results["real"][feat][0])
    local_passed = sum(1 for feat in features if results["local"][feat][0])
    
    print(f"\n{Colors.BOLD}Results:{Colors.RESET}")
    print(f"Real API:     {real_passed}/4 features working ({real_passed/4*100:.0f}%)")
    print(f"Local Server: {local_passed}/4 features working ({local_passed/4*100:.0f}%)")
    
    if local_passed == 4:
        print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 LOCAL SERVER: ALL FEATURES WORKING! 🎉{Colors.RESET}\n")
    elif local_passed >= 3:
        print(f"\n{Colors.YELLOW}{Colors.BOLD}⚠️  LOCAL SERVER: Most features working ({local_passed}/4){Colors.RESET}\n")
    else:
        print(f"\n{Colors.YELLOW}{Colors.BOLD}📝 LOCAL SERVER: {local_passed}/4 features working{Colors.RESET}\n")
    
    return 0 if local_passed >= 3 else 1


if __name__ == "__main__":
    try:
        exit_code = main()
        exit(exit_code)
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Tests interrupted{Colors.RESET}")
        exit(130)
    except Exception as e:
        print(f"\n{Colors.RED}Fatal error: {e}{Colors.RESET}")
        exit(1)

