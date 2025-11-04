#!/usr/bin/env python3
"""
Standalone demo showing how the 4 models are configured
No dependencies required!
"""

# Model configurations (copied from app/model_router.py)
MODEL_CONFIGS = {
    # Model 1: Qwen3-Max (no thinking, web search always applied)
    "qwen3-max": {
        "actual_model": "qwen3-max-latest",
        "tools": ["web_search"],
        "max_tokens": None,
        "thinking": False,
        "description": "Qwen3-Max: No thinking option, web search feature always applied"
    },
    
    # Model 2: Qwen3-235B-A22B-2507 (web search + thinking, 81,920 tokens)
    "qwen3-235b": {
        "actual_model": "qwen3-235b-a22b-2507",
        "tools": ["web_search"],
        "max_tokens": 81920,
        "thinking": True,
        "description": "Qwen3-235B: Web search + thinking, 81,920 tokens"
    },
    
    # Model 3: Qwen3-VL-235B-A22B (NO web search + thinking, 81,920 tokens)
    "qwen3-vl": {
        "actual_model": "qwen3-vl-235b-a22b",
        "tools": [],  # NO web search
        "max_tokens": 81920,
        "thinking": True,
        "description": "Qwen3-VL-235B: No web search, thinking enabled, 81,920 tokens"
    },
    
    # Model 4: Qwen3-Omni-Flash (NO web search + thinking, 81,920 tokens)
    "qwen3-omni": {
        "actual_model": "qwen3-omni-flash",
        "tools": [],  # NO web search
        "max_tokens": 81920,
        "thinking": True,
        "description": "Qwen3-Omni-Flash: No web search, thinking enabled, 81,920 tokens"
    }
}


def print_header(text, char="="):
    print("\n" + char * 80)
    print(text.center(80))
    print(char * 80 + "\n")


def print_section(text):
    print(f"\n{'─' * 80}")
    print(f"  {text}")
    print('─' * 80)


def demo_model_config():
    """Show configuration for all 4 models"""
    
    print_header("🎯 QWEN API - 4 ACCESSIBLE MODELS CONFIGURATION", "═")
    
    print("📋 MODEL SUMMARY TABLE:")
    print("-" * 80)
    print(f"{'Model':<15} {'Actual Model':<25} {'Web Search':<12} {'Thinking':<10} {'Max Tokens'}")
    print("-" * 80)
    
    for alias, config in MODEL_CONFIGS.items():
        web_search = "✅ YES" if config['tools'] else "❌ NO"
        thinking = "✅ YES" if config['thinking'] else "❌ NO"
        max_tokens = f"{config['max_tokens']:,}" if config['max_tokens'] else "Default"
        
        print(f"{alias:<15} {config['actual_model']:<25} {web_search:<12} {thinking:<10} {max_tokens}")
    
    print("-" * 80)
    
    # Detailed configuration for each model
    for i, (alias, config) in enumerate(MODEL_CONFIGS.items(), 1):
        print_section(f"MODEL {i}: {alias.upper()}")
        
        print(f"  Alias:        {alias}")
        print(f"  Actual Model: {config['actual_model']}")
        print(f"  Description:  {config['description']}")
        print()
        print("  Features:")
        
        # Web Search
        if config['tools']:
            print(f"    ✅ Web Search: Automatically injected ({', '.join(config['tools'])})")
        else:
            print(f"    ❌ Web Search: NOT applied")
        
        # Thinking
        if config['thinking']:
            print(f"    ✅ Thinking Mode: Enabled for complex reasoning")
        else:
            print(f"    ❌ Thinking Mode: Not available")
        
        # Max Tokens
        if config['max_tokens']:
            print(f"    📊 Max Tokens: {config['max_tokens']:,} (extended context)")
        else:
            print(f"    📊 Max Tokens: Provider default")
        
        print()
        print("  Best Use Cases:")
        if alias == "qwen3-max":
            print("    • General Q&A with real-time web data")
            print("    • Current events and news queries")
            print("    • Fast responses with web verification")
        elif alias == "qwen3-235b":
            print("    • Complex reasoning with web access")
            print("    • Multi-step problem solving")
            print("    • Research requiring depth + breadth")
        elif alias == "qwen3-vl":
            print("    • Image analysis and understanding")
            print("    • Visual question answering")
            print("    • Document and diagram interpretation")
        elif alias == "qwen3-omni":
            print("    • Multimodal content (text + image + audio + video)")
            print("    • Cross-modal understanding")
            print("    • Complex multimedia analysis")


def demo_api_request():
    """Show what an API request looks like for each model"""
    
    print_header("📤 SAMPLE API REQUESTS", "═")
    
    question = "What model are you?"
    
    for alias, config in MODEL_CONFIGS.items():
        print_section(f"REQUEST TO: {alias}")
        
        print(f"  Client Request:")
        print(f"  {{")
        print(f"    \"model\": \"{alias}\",")
        print(f"    \"messages\": [")
        print(f"      {{\"role\": \"user\", \"content\": \"{question}\"}}")
        print(f"    ]")
        print(f"  }}")
        print()
        
        print(f"  ⚙️  Server Processing:")
        print(f"      → Resolves to: {config['actual_model']}")
        
        if config['tools']:
            print(f"      → Auto-injects: {config['tools']}")
        else:
            print(f"      → No tools injected")
        
        if config['max_tokens']:
            print(f"      → Sets max_tokens: {config['max_tokens']:,}")
        
        print()
        print(f"  📨 Actual Request to Qwen API:")
        print(f"  {{")
        print(f"    \"model\": \"{config['actual_model']}\",")
        print(f"    \"messages\": [")
        print(f"      {{\"role\": \"user\", \"content\": \"{question}\"}}")
        print(f"    ],")
        
        if config['tools']:
            print(f"    \"tools\": [")
            for tool in config['tools']:
                print(f"      {{\"type\": \"{tool}\"}}")
            print(f"    ],")
        
        if config['max_tokens']:
            print(f"    \"max_tokens\": {config['max_tokens']}")
        
        print(f"  }}")
        print()
        
        print(f"  💬 Expected Response:")
        print(f"  {{")
        print(f"    \"id\": \"chatcmpl-xxx\",")
        print(f"    \"object\": \"chat.completion\",")
        print(f"    \"model\": \"{config['actual_model']}\",")
        print(f"    \"choices\": [{{")
        print(f"      \"message\": {{")
        print(f"        \"role\": \"assistant\",")
        print(f"        \"content\": \"I am {config['actual_model']}...\"")
        print(f"      }},")
        print(f"      \"finish_reason\": \"stop\"")
        print(f"    }}],")
        print(f"    \"usage\": {{\"total_tokens\": ...}}")
        print(f"  }}")


def demo_curl_commands():
    """Show cURL commands to test each model"""
    
    print_header("🧪 TEST COMMANDS (cURL)", "═")
    
    print("Once the server is running on http://localhost:8096, test with:\n")
    
    for alias, config in MODEL_CONFIGS.items():
        print(f"# Test {alias}")
        print(f"curl -X POST http://localhost:8096/v1/chat/completions \\")
        print(f"  -H \"Content-Type: application/json\" \\")
        print(f"  -H \"Authorization: Bearer sk-any\" \\")
        print(f"  -d '{{")
        print(f"    \"model\": \"{alias}\",")
        print(f"    \"messages\": [")
        print(f"      {{\"role\": \"user\", \"content\": \"What model are you?\"}}")
        print(f"    ]")
        print(f"  }}'")
        print()


def main():
    print_header("🚀 QWEN API - 4 MODELS DEMONSTRATION", "█")
    
    print("""
This demo shows the configuration of the 4 accessible models:

1. qwen3-max    - General purpose with web search
2. qwen3-235b   - Complex reasoning with web search + thinking
3. qwen3-vl     - Vision-language without web search
4. qwen3-omni   - Multimodal without web search

All models are OpenAI API compatible!
""")
    
    # Show configurations
    demo_model_config()
    
    # Show API requests
    demo_api_request()
    
    # Show cURL commands
    demo_curl_commands()
    
    print_header("✅ CONFIGURATION COMPLETE", "═")
    
    print("""
📚 Key Features:

  ✅ 4 specialized models with distinct features
  ✅ Automatic tool injection (web_search where appropriate)
  ✅ Extended context (81,920 tokens for 3 models)
  ✅ Thinking mode enabled for complex reasoning
  ✅ OpenAI API compatible (drop-in replacement)
  ✅ Case-insensitive model names

🚀 To Deploy:

  1. Set credentials:     export QWEN_EMAIL="..." QWEN_PASSWORD="..."
  2. Run setup:           bash scripts/setup.sh
  3. Start server:        bash scripts/start.sh
  4. Test models:         Use cURL commands above

📖 Documentation:

  • MODELS.md              - Complete model specifications
  • tests/README.md        - Test suite documentation
  • scripts/run_tests.sh   - Run comprehensive tests
""")
    
    print("=" * 80)


if __name__ == "__main__":
    main()

