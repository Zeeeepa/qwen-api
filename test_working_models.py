#!/usr/bin/env python3
"""
Test WORKING models using OpenAI Python client
Based on actual availability in Qwen API
"""

from openai import OpenAI
import time

# Configuration
SERVER_PORT = 8080
BASE_URL = f"http://localhost:{SERVER_PORT}/v1"

# Initialize client
client = OpenAI(
    api_key="sk-any",  # ✅ Any key works!
    base_url=BASE_URL
)

# Only models that actually work (confirmed working)
WORKING_MODELS = [
    # Qwen Models (via qwen-max-latest mapping)
    "qwen2.5-max",
    "qwen2.5-turbo", 
    "qwen-deep-research",
    
    # Model mappings (via smart mapping to qwen-max-latest)
    "gpt-4",
    "gpt-4-turbo",
    "claude-3-opus",
    "claude-3-sonnet",
    "claude-2",
]

class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    CYAN = "\033[96m"
    MAGENTA = "\033[95m"
    RESET = "\033[0m"
    BOLD = "\033[1m"

def test_model(model_name: str, test_number: int, total: int) -> tuple[bool, str]:
    """Test a single model with OpenAI client"""
    print(f"\n{Colors.CYAN}[{test_number}/{total}] Testing model: {Colors.BOLD}{model_name}{Colors.RESET}")
    
    try:
        # Make API call
        start_time = time.time()
        result = client.chat.completions.create(
            model=model_name,
            messages=[{
                "role": "user", 
                "content": "Say 'Hello!' in exactly one word."
            }],
            max_tokens=10,
            timeout=30.0
        )
        elapsed = time.time() - start_time
        
        # Extract response
        content = result.choices[0].message.content
        tokens = result.usage.total_tokens if result.usage else 0
        
        # Clean response for display
        response_preview = content.split('\n')[0][:50]  # First line only
        
        print(f"{Colors.GREEN}✅ SUCCESS{Colors.RESET}")
        print(f"   Response: {Colors.CYAN}{response_preview}{Colors.RESET}")
        print(f"   Tokens: {tokens}, Time: {elapsed:.2f}s")
        return True, response_preview
        
    except Exception as e:
        error_msg = str(e)
        print(f"{Colors.RED}❌ FAILED{Colors.RESET}")
        print(f"   Error: {error_msg[:150]}")
        return False, error_msg


def main():
    """Run all model tests"""
    print(f"\n{Colors.BOLD}{Colors.MAGENTA}{'='*80}")
    print(f"🤖 TESTING ALL WORKING MODELS WITH OPENAI CLIENT")
    print(f"{'='*80}{Colors.RESET}\n")
    
    print(f"{Colors.CYAN}Server: {BASE_URL}{Colors.RESET}")
    print(f"{Colors.CYAN}Total Models: {len(WORKING_MODELS)}{Colors.RESET}")
    print(f"{Colors.CYAN}Test Query: 'Say Hello! in exactly one word.'{Colors.RESET}")
    
    # Test all models
    results = {}
    passed = 0
    failed = 0
    
    for i, model in enumerate(WORKING_MODELS, 1):
        success, message = test_model(model, i, len(WORKING_MODELS))
        results[model] = (success, message)
        if success:
            passed += 1
        else:
            failed += 1
        
        # Small delay between requests
        if i < len(WORKING_MODELS):
            time.sleep(0.5)
    
    # Print summary
    print(f"\n{Colors.BOLD}{'='*80}")
    print(f"📊 TEST SUMMARY")
    print(f"{'='*80}{Colors.RESET}\n")
    
    print(f"{Colors.BOLD}Total Models Tested:{Colors.RESET} {len(WORKING_MODELS)}")
    print(f"{Colors.GREEN}✅ Passed:{Colors.RESET} {passed}")
    print(f"{Colors.RED}❌ Failed:{Colors.RESET} {failed}")
    
    # Pass rate
    pass_rate = (passed / len(WORKING_MODELS) * 100) if len(WORKING_MODELS) > 0 else 0
    
    # Categorize results
    print(f"\n{Colors.BOLD}Successful Models:{Colors.RESET}")
    for model, (success, message) in results.items():
        if success:
            print(f"  {Colors.GREEN}✅{Colors.RESET} {model:<25} → {message[:40]}")
    
    if failed > 0:
        print(f"\n{Colors.BOLD}Failed Models:{Colors.RESET}")
        for model, (success, message) in results.items():
            if not success:
                print(f"  {Colors.RED}❌{Colors.RESET} {model}")
    
    # Final result
    print(f"\n{Colors.BOLD}Pass Rate: {pass_rate:.1f}%{Colors.RESET}")
    
    if pass_rate == 100:
        print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 ALL MODELS WORKING PERFECTLY! 🎉{Colors.RESET}\n")
    elif pass_rate >= 80:
        print(f"\n{Colors.YELLOW}{Colors.BOLD}⚠️ Most models working ({pass_rate:.1f}%){Colors.RESET}\n")
    else:
        print(f"\n{Colors.RED}{Colors.BOLD}❌ Many models failing ({pass_rate:.1f}%){Colors.RESET}\n")
    
    return 0 if pass_rate == 100 else 1


if __name__ == "__main__":
    try:
        exit_code = main()
        exit(exit_code)
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Tests interrupted by user{Colors.RESET}")
        exit(130)
    except Exception as e:
        print(f"\n{Colors.RED}Fatal error: {e}{Colors.RESET}")
        exit(1)

