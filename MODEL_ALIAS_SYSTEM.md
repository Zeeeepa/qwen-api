# Model Alias System - Implementation Guide

## Overview

The Model Alias System provides intelligent model routing with automatic tool/feature injection. It allows users to reference models by simple aliases that automatically configure the appropriate Qwen model, tools, and settings.

## Architecture

### Core Components

```
model_mapper.py
├── ModelConfig (dataclass)
│   ├── qwen_model: str
│   ├── auto_tools: List[Dict]
│   ├── thinking_enabled: bool
│   └── max_tokens_override: Optional[int]
│
├── ALIAS_CONFIGS (mapping)
│   └── Case-insensitive model alias → ModelConfig
│
├── map_model_name(model: str) → ModelConfig
│   └── Returns configuration with auto-features
│
└── merge_tools(auto_tools, user_tools) → List
    └── Intelligently combines tool lists
```

## Routing Table

| Alias | Target Model | Auto-Tools | Thinking | Max Tokens |
|-------|-------------|------------|----------|------------|
| `gpt-5` (unknown) | qwen3-max-latest | web_search | ❌ | default |
| `Qwen` | qwen3-max-latest | web_search | ❌ | default |
| `Qwen_Research` | qwen-deep-research | none | ❌ | default |
| `Qwen_Think` | qwen3-235b-a22b-2507 | web_search | ✅ | 81920 |
| `Qwen_Code` | qwen3-coder-plus | web_search | ❌ | default |

### Case-Insensitive Matching

All aliases are case-insensitive:
- `qwen`, `QWEN`, `QwEn` → same routing
- `qwen_research`, `QWEN_RESEARCH`, `Qwen_Research` → same routing

## Request Flow

```
1. User Request
   ↓
   model="Qwen_Think"
   messages=[...]
   tools=[{"type": "code"}]  # Optional user tools

2. map_model_name("Qwen_Think")
   ↓
   ModelConfig(
       qwen_model="qwen3-235b-a22b-2507",
       auto_tools=[{"type": "web_search"}],
       thinking_enabled=True,
       max_tokens_override=81920
   )

3. merge_tools(auto_tools, user_tools)
   ↓
   [{"type": "web_search"}, {"type": "code"}]
   # Auto-tools + user tools, deduped

4. Apply Config
   ↓
   - model = "qwen3-235b-a22b-2507"
   - tools = merged list
   - enable_thinking = True
   - max_tokens = 81920

5. Qwen API Call
   ↓
   POST /v1/chat/completions
   {
       "model": "qwen3-235b-a22b-2507",
       "messages": [...],
       "tools": [{"type": "web_search"}, {"type": "code"}],
       "enable_thinking": true,
       "max_tokens": 81920
   }

6. Response
   ↓
   Returns with original model name: "Qwen_Think"
```

## Tool Merging Rules

```python
def merge_tools(auto_tools, user_tools):
    # 1. Start with auto-tools
    merged = list(auto_tools) if auto_tools else []
    
    # 2. Add user tools with deduplication
    if user_tools:
        existing_types = {tool.get("type") for tool in merged}
        for tool in user_tools:
            tool_type = tool.get("type")
            if tool_type not in existing_types:
                # New tool type → add it
                merged.append(tool)
            else:
                # Duplicate type → user tool takes precedence
                merged = [t for t in merged if t.get("type") != tool_type]
                merged.append(tool)
    
    return merged
```

### Examples

**Auto + User (No Conflict)**
```python
auto_tools = [{"type": "web_search"}]
user_tools = [{"type": "code"}]
result = [{"type": "web_search"}, {"type": "code"}]
```

**Auto + User (Conflict - User Wins)**
```python
auto_tools = [{"type": "web_search"}]
user_tools = [{"type": "web_search", "max_results": 10}]
result = [{"type": "web_search", "max_results": 10}]  # User config
```

**No Auto-Tools**
```python
auto_tools = []  # Qwen_Research
user_tools = [{"type": "code"}]
result = [{"type": "code"}]
```

## Usage Examples

### 1. Simple Alias Usage

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:8000/v1"
)

# Automatically gets web_search
result = client.chat.completions.create(
    model="Qwen",
    messages=[{"role": "user", "content": "What's the latest news?"}]
)
```

### 2. Thinking Mode

```python
# Automatically enables thinking + web_search + 81920 tokens
result = client.chat.completions.create(
    model="Qwen_Think",
    messages=[{"role": "user", "content": "Analyze this complex problem..."}]
)
```

### 3. Research Mode (No Auto-Tools)

```python
# Pure deep research, no automatic tools
result = client.chat.completions.create(
    model="Qwen_Research",
    messages=[{"role": "user", "content": "Comprehensive analysis of..."}]
)
```

### 4. Code Generation

```python
# Gets web_search for looking up latest syntax
result = client.chat.completions.create(
    model="Qwen_Code",
    messages=[{"role": "user", "content": "Write async Python code..."}]
)
```

### 5. User Tools Override

```python
# User adds 'code' tool, gets both web_search + code
result = client.chat.completions.create(
    model="Qwen",
    extra_body={
        "tools": [{"type": "code"}]
    },
    messages=[{"role": "user", "content": "Generate and test code..."}]
)
```

### 6. Unknown Model (Fallback)

```python
# Any unknown model → qwen3-max-latest + web_search
result = client.chat.completions.create(
    model="gpt-5",  # Unknown → defaults
    messages=[{"role": "user", "content": "Hello"}]
)
```

## API Server Integration

### Modified Endpoint

```python
@app.post("/v1/chat/completions")
async def chat_completions(request: ChatCompletionRequest):
    # 1. Map model to config
    model_config = map_model_name(request.model)
    qwen_model = model_config.qwen_model
    
    # 2. Log routing decision
    logger.info(f"🎯 Model routing: '{request.model}' → '{qwen_model}'")
    if model_config.auto_tools:
        logger.info(f"   Auto-tools: {[t['type'] for t in model_config.auto_tools]}")
    
    # 3. Merge tools
    final_tools = merge_tools(model_config.auto_tools, request.tools)
    
    # 4. Apply thinking mode
    enable_thinking = request.enable_thinking
    if model_config.thinking_enabled and enable_thinking is None:
        enable_thinking = True
    
    # 5. Apply max_tokens override
    max_tokens = request.max_tokens
    if model_config.max_tokens_override and max_tokens is None:
        max_tokens = model_config.max_tokens_override
    
    # 6. Call Qwen API
    response = await client.chat_completion(
        model=qwen_model,
        messages=normalized_messages,
        tools=final_tools,
        enable_thinking=enable_thinking,
        max_tokens=max_tokens,
        ...
    )
    
    # 7. Return with original model name
    response["model"] = request.model or qwen_model
    return response
```

## Testing

### Running Tests

```bash
# 1. Start server
export QWEN_EMAIL="your_email"
export QWEN_PASSWORD="your_password"
bash scripts/start.sh

# 2. Run test suite
export SERVER_PORT=8000
python test_model_aliases.py
```

### Test Scenarios

1. **Default Routing** - Unknown model → qwen3-max-latest + web_search
2. **Research Alias** - Qwen_Research → qwen-deep-research (no tools)
3. **Think Alias** - Qwen_Think → thinking + web_search + 81920 tokens
4. **Code Alias** - Qwen_Code → qwen3-coder-plus + web_search
5. **Direct Qwen** - Qwen → qwen3-max-latest + web_search
6. **Tool Merging** - Validates auto + user tool combination
7. **Case Insensitive** - Tests various case patterns

### Expected Output

```
🚀🚀🚀 MODEL ALIAS SYSTEM - COMPREHENSIVE TEST SUITE 🚀🚀🚀

================================================================================
  Scenario 1: Default Routing (gpt-5 → Qwen + web_search)
================================================================================

📡 Testing: Unknown model 'gpt-5' with web search capability
✅ Request model: gpt-5
   Routed to: qwen3-max-latest
   Response preview: Based on web search results...
✅ PASSED: Response contains current information

... (more tests)

================================================================================
  TEST SUMMARY
================================================================================

✅ Passed: 7/7 test scenarios
🎉 ALL TESTS PASSED! Model alias system working perfectly!
```

## Logging

Server logs show routing decisions:

```
2025-10-17 14:00:00,000 - qwen_api - INFO - 🎯 Model routing: 'Qwen_Think' → 'qwen3-235b-a22b-2507'
2025-10-17 14:00:00,001 - qwen_api - INFO -    Auto-tools: ['web_search']
2025-10-17 14:00:00,002 - qwen_api - INFO -    Thinking: enabled (max_tokens=81920)
2025-10-17 14:00:00,003 - qwen_api - DEBUG - Final tools: ['web_search', 'code']
2025-10-17 14:00:00,004 - qwen_api - DEBUG - Applied max_tokens override: 81920
```

## Extension Guide

### Adding New Alias

```python
# In model_mapper.py ALIAS_CONFIGS:

"qwen_vision": ModelConfig(
    qwen_model="qwen3-vl-plus",
    auto_tools=[{"type": "vision"}],
    thinking_enabled=False,
    max_tokens_override=None
)
```

### Adding New Auto-Tool

```python
# Add to existing alias:

"qwen": ModelConfig(
    qwen_model="qwen3-max-latest",
    auto_tools=[
        {"type": "web_search"},
        {"type": "code"}  # New tool
    ]
)
```

### Custom Default Config

```python
# Modify fallback in map_model_name():

def map_model_name(model: Optional[str]) -> ModelConfig:
    ...
    # Fallback for unknown models
    logger.debug(f"Model '{model}' not recognized, using custom default")
    return ModelConfig(
        qwen_model="your-preferred-model",
        auto_tools=[{"type": "your-tool"}],
        thinking_enabled=True,  # Custom setting
        max_tokens_override=100000
    )
```

## Troubleshooting

### Issue: Tools Not Being Applied

**Symptom**: Auto-tools not showing in responses

**Check**:
1. Verify `merge_tools()` is being called
2. Check logs for "Auto-tools:" line
3. Confirm tools in final request payload

### Issue: Wrong Model Being Used

**Symptom**: Different model than expected

**Check**:
1. Review routing logs: "Model routing: 'X' → 'Y'"
2. Verify alias exists in ALIAS_CONFIGS
3. Check case sensitivity (should be case-insensitive)

### Issue: Thinking Mode Not Enabled

**Symptom**: No thinking output despite using Qwen_Think

**Check**:
1. Verify `enable_thinking` in logs
2. Confirm model supports thinking (qwen3-235b-a22b-2507)
3. Check if user explicitly set `enable_thinking=False`

### Issue: Token Expired (400 Error)

**Symptom**: All requests fail with 400 Bad Request

**Solution**:
```bash
export QWEN_EMAIL="your_email"
export QWEN_PASSWORD="your_password"
python py-api/qwen-api/get_qwen_token.py
# Updates .env with fresh token
bash scripts/start.sh  # Restart server
```

## Performance Considerations

### Tool Merging Overhead

- **Negligible**: O(n) where n = tool count (typically ≤ 5)
- Deduplication is hash-based (fast)
- No network calls during merging

### Routing Overhead

- **Minimal**: Dictionary lookup O(1)
- Case-insensitive matching adds `.lower()` cost
- Configuration is in-memory (no I/O)

### Caching

Not currently implemented, but could add:
```python
@lru_cache(maxsize=128)
def map_model_name(model: Optional[str]) -> ModelConfig:
    ...
```

## Security

### Tool Injection Protection

- User tools always take precedence
- No arbitrary code execution in tool merging
- Tools validated by Qwen API backend

### Model Access Control

- All routing goes through map_model_name()
- Cannot bypass to arbitrary models
- Qwen API enforces final access control

## Backward Compatibility

### Existing Code

All existing code continues to work:
```python
# Still works exactly as before
client.chat.completions.create(
    model="qwen3-max-latest",  # Direct model name
    messages=[...]
)
```

### Direct Model Names

Direct Qwen model names are preserved:
```python
map_model_name("qwen3-max-latest")
# Returns: ModelConfig with qwen_model="qwen3-max-latest"
# No auto-tools applied to direct names
```

### Tool Specification

Both formats supported:
```python
# Format 1: Simple tools (for Qwen native tools)
tools=[{"type": "web_search"}]

# Format 2: OpenAI format (for custom functions)
tools=[{
    "type": "function",
    "function": {"name": "get_weather", ...}
}]
```

## Future Enhancements

1. **Dynamic Configuration**: Load ALIAS_CONFIGS from database/config file
2. **User Preferences**: Per-user alias customization
3. **Usage Analytics**: Track which aliases are most popular
4. **Auto-Discovery**: Suggest aliases based on query patterns
5. **Caching**: Cache ModelConfig lookups for performance
6. **Validation**: Pre-validate tool compatibility with models

## References

- [Qwen API Documentation](https://help.aliyun.com/zh/qwen/)
- [OpenAI API Compatibility](https://platform.openai.com/docs/api-reference)
- [Native Tools Guide](./NATIVE_TOOLS.md)
- [Test Suite](./test_model_aliases.py)

---

**Status**: ✅ Production Ready (pending token refresh)  
**Version**: 1.0.0  
**Last Updated**: 2025-10-17

