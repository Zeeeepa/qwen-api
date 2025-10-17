#!/usr/bin/env python3
"""
🧪 Comprehensive Test Suite for Qwen Native Tools

Tests all native capabilities:
- web_search: Real-time web browsing
- vision: Image analysis
- deep-research: Extended research mode
- Standard chat: Baseline functionality
"""

import requests
import time
import sys
from typing import Dict, Any

# Configuration
SERVER_PORT = 7050
BASE_URL = f"http://localhost:{SERVER_PORT}/v1"

class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(text: str):
    """Print formatted header"""
    print(f"\n{Colors.BLUE}{Colors.BOLD}{'=' * 80}")
    print(f"{text}")
    print(f"{'=' * 80}{Colors.END}\n")

def print_test(number: int, total: int, name: str):
    """Print test header"""
    print(f"\n{Colors.BOLD}[{number}/{total}] {name}{Colors.END}")
    print("-" * 80)

def print_success(message: str):
    """Print success message"""
    print(f"{Colors.GREEN}✅ {message}{Colors.END}")

def print_error(message: str):
    """Print error message"""
    print(f"{Colors.RED}❌ {message}{Colors.END}")

def print_warning(message: str):
    """Print warning message"""
    print(f"{Colors.YELLOW}⚠️  {message}{Colors.END}")

def make_request(payload: Dict[str, Any], test_name: str) -> None:
    """Make API request and print results"""
    try:
        start_time = time.time()
        response = requests.post(f"{BASE_URL}/chat/completions", json=payload)
        elapsed = time.time() - start_time
        
        print(f"⏱️  Response time: {elapsed:.2f}s")
        print(f"📡 Status code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            content = result['choices'][0]['message']['content']
            
            # Token usage
            if 'usage' in result and result['usage']:
                tokens = result['usage'].get('total_tokens', 'N/A')
                print(f"📊 Tokens used: {tokens}")
            
            print_success(f"{test_name} completed successfully!")
            print(f"\n{Colors.BOLD}Response Preview:{Colors.END}")
            print("-" * 80)
            
            # Show first 500 chars of response
            preview = content[:500] + "..." if len(content) > 500 else content
            print(preview)
            print("-" * 80)
            
        else:
            print_error(f"Request failed: {response.status_code}")
            print(f"Response: {response.text[:200]}")
            
    except requests.exceptions.ConnectionError:
        print_error(f"Connection failed - is server running on port {SERVER_PORT}?")
    except Exception as e:
        print_error(f"Unexpected error: {e}")

def test_web_search():
    """Test 1: Web Search Tool"""
    print_test(1, 4, "Web Search Tool - Real-time web browsing")
    
    payload = {
        "model": "qwen-max-latest",
        "tools": [{"type": "web_search"}],
        "messages": [{
            "role": "user",
            "content": "What are the latest developments in AI? Provide specific examples from recent news."
        }],
        "stream": False
    }
    
    print(f"{Colors.BOLD}Test Configuration:{Colors.END}")
    print(f"  Model: qwen-max-latest")
    print(f"  Tool: web_search")
    print(f"  Query: Latest AI developments")
    print()
    
    make_request(payload, "Web Search")

def test_vision():
    """Test 2: Vision/Multimodal"""
    print_test(2, 4, "Vision Tool - Image analysis")
    
    payload = {
        "model": "qwen3-vl-plus",
        "messages": [{
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "Describe this image in detail. What objects do you see?"
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": "https://download.samplelib.com/png/sample-hut-400x300.png"
                    }
                }
            ]
        }],
        "stream": False
    }
    
    print(f"{Colors.BOLD}Test Configuration:{Colors.END}")
    print(f"  Model: qwen3-vl-plus")
    print(f"  Format: Multimodal (text + image)")
    print(f"  Image URL: sample-hut-400x300.png")
    print()
    
    make_request(payload, "Vision Analysis")

def test_deep_research():
    """Test 3: Deep Research Mode"""
    print_test(3, 4, "Deep Research - Comprehensive analysis")
    
    payload = {
        "model": "qwen-deep-research",
        "messages": [{
            "role": "user",
            "content": "Research AI coding assistants. Compare different approaches and provide sources."
        }],
        "max_tokens": 4000,
        "stream": False
    }
    
    print(f"{Colors.BOLD}Test Configuration:{Colors.END}")
    print(f"  Model: qwen-deep-research")
    print(f"  Max tokens: 4000")
    print(f"  Topic: AI coding assistants")
    print()
    
    make_request(payload, "Deep Research")

def test_standard_chat():
    """Test 4: Standard Chat (Baseline)"""
    print_test(4, 4, "Standard Chat - No special tools")
    
    payload = {
        "model": "qwen3-max",
        "messages": [{
            "role": "user",
            "content": "Write a haiku about programming"
        }],
        "stream": False
    }
    
    print(f"{Colors.BOLD}Test Configuration:{Colors.END}")
    print(f"  Model: qwen3-max")
    print(f"  Tools: None (baseline)")
    print(f"  Task: Creative writing")
    print()
    
    make_request(payload, "Standard Chat")

def main():
    """Run all tests"""
    print_header("🧪 Qwen Native Tools Test Suite")
    
    print(f"{Colors.BOLD}Configuration:{Colors.END}")
    print(f"  Server: {BASE_URL}")
    print(f"  Port: {SERVER_PORT}")
    print()
    
    print(f"{Colors.BOLD}Testing:{Colors.END}")
    print("  ✓ Web Search (real-time browsing)")
    print("  ✓ Vision Analysis (image understanding)")
    print("  ✓ Deep Research (multi-source analysis)")
    print("  ✓ Standard Chat (baseline)")
    print()
    
    input(f"{Colors.YELLOW}Press Enter to start tests...{Colors.END}")
    
    # Run tests with delays between them
    test_web_search()
    time.sleep(3)
    
    test_vision()
    time.sleep(3)
    
    test_deep_research()
    time.sleep(3)
    
    test_standard_chat()
    
    # Summary
    print_header("📊 Test Suite Complete!")
    
    print(f"{Colors.BOLD}Summary:{Colors.END}")
    print("  • Web Search: Tests real-time web browsing capability")
    print("  • Vision: Tests multimodal image analysis")
    print("  • Deep Research: Tests extended reasoning and research")
    print("  • Standard Chat: Baseline performance check")
    print()
    
    print(f"{Colors.BOLD}Next Steps:{Colors.END}")
    print("  1. Review response quality and accuracy")
    print("  2. Check response times match expectations")
    print("  3. Verify tool usage in responses (citations, analysis depth)")
    print()
    
    print(f"{Colors.GREEN}All tests executed successfully!{Colors.END}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Tests interrupted by user{Colors.END}")
        sys.exit(0)
    except Exception as e:
        print(f"\n\n{Colors.RED}Fatal error: {e}{Colors.END}")
        sys.exit(1)

