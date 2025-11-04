#!/usr/bin/env python3
"""
Demo script to test model routing without requiring authentication
Shows how the 4 models are configured and would respond
"""

import sys
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent))

from app.model_router import get_model_router, MODEL_CONFIGS


def demo_model_routing():
    """Demonstrate model routing for all 4 models"""
    
    print("=" * 70)
    print("🎯 Qwen API - Model Routing Demo")
    print("=" * 70)
    print()
    
    router = get_model_router()
    
    # Test all 4 models
    test_models = [
        ("qwen3-max", "What model are you?"),
        ("qwen3-235b", "What model are you?"),
        ("qwen3-vl", "What model are you?"),
        ("qwen3-omni", "What model are you?"),
    ]
    
    print("📋 Model Configuration Summary:")
    print("-" * 70)
    
    for alias, config in MODEL_CONFIGS.items():
        if alias == "_default":
            continue
        print(f"\n🔹 {alias.upper()}")
        print(f"   Actual Model: {config['actual_model']}")
        print(f"   Web Search:   {'✅ YES' if config['tools'] else '❌ NO'}")
        print(f"   Thinking:     {'✅ YES' if config.get('thinking') else '❌ NO'}")
        print(f"   Max Tokens:   {config['max_tokens'] if config['max_tokens'] else 'Provider default'}")
    
    print("\n" + "=" * 70)
    print("🧪 Testing Model Resolution")
    print("=" * 70)
    
    for model_name, question in test_models:
        print(f"\n📤 Request to: {model_name}")
        print(f"   Question: \"{question}\"")
        
        # Resolve model
        actual_model = router.resolve_model(model_name)
        config = router.get_model_config(model_name)
        
        print(f"\n📥 Server Processing:")
        print(f"   ✅ Resolved to: {actual_model}")
        
        # Show what would be injected
        tools = config.get('tools', [])
        if tools:
            print(f"   🛠️  Auto-inject tools: {', '.join(tools)}")
        else:
            print(f"   🚫 No tools injected")
        
        max_tokens = config.get('max_tokens')
        if max_tokens:
            print(f"   📊 Max tokens: {max_tokens:,}")
        else:
            print(f"   📊 Max tokens: Provider default")
        
        thinking = config.get('thinking', False)
        print(f"   🧠 Thinking mode: {'✅ Enabled' if thinking else '❌ Disabled'}")
        
        # Simulate response structure
        print(f"\n📨 Would send to Qwen API:")
        print(f"   {{")
        print(f"      \"model\": \"{actual_model}\",")
        print(f"      \"messages\": [{{\"role\": \"user\", \"content\": \"{question}\"}}],")
        if tools:
            print(f"      \"tools\": {[{'type': t} for t in tools]},")
        if max_tokens:
            print(f"      \"max_tokens\": {max_tokens},")
        print(f"   }}")
        
        # Simulate expected response
        print(f"\n💬 Expected Response Format:")
        print(f"   {{")
        print(f"      \"id\": \"chatcmpl-xxx\",")
        print(f"      \"object\": \"chat.completion\",")
        print(f"      \"model\": \"{actual_model}\",")
        print(f"      \"choices\": [")
        print(f"         {{")
        print(f"            \"message\": {{")
        print(f"               \"role\": \"assistant\",")
        print(f"               \"content\": \"I am {actual_model}...\"")
        print(f"            }},")
        print(f"            \"finish_reason\": \"stop\"")
        print(f"         }}")
        print(f"      ]")
        print(f"   }}")
        
        print("\n" + "-" * 70)
    
    print("\n" + "=" * 70)
    print("🎯 Key Features Demonstrated:")
    print("=" * 70)
    print("""
✅ Model Aliasing: Friendly names → Actual Qwen models
✅ Auto Tool Injection: web_search added where configured
✅ Token Limits: 81,920 for extended context models
✅ Thinking Mode: Enabled for 3 of 4 models
✅ OpenAI Compatible: Standard request/response format
""")
    
    print("=" * 70)
    print("✨ To test with real API:")
    print("=" * 70)
    print("""
1. Set credentials:
   export QWEN_EMAIL="your@email.com"
   export QWEN_PASSWORD="yourpassword"

2. Run setup:
   bash scripts/setup.sh

3. Start server:
   bash scripts/start.sh

4. Test API:
   curl -X POST http://localhost:8096/v1/chat/completions \\
     -H "Content-Type: application/json" \\
     -H "Authorization: Bearer sk-any" \\
     -d '{
       "model": "qwen3-max",
       "messages": [{"role": "user", "content": "What model are you?"}]
     }'
""")
    print("=" * 70)


if __name__ == "__main__":
    demo_model_routing()

