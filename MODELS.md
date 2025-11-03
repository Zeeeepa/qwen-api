# Qwen API - Available Models

This document describes the 4 accessible models through the Qwen API proxy.

## 🎯 The 4 Accessible Models

| Model Alias | Actual Model | Web Search | Thinking | Max Tokens | Use Case |
|-------------|--------------|------------|----------|------------|----------|
| `qwen3-max` | `qwen3-max-latest` | ✅ Always | ❌ No | Default | General purpose with web access |
| `qwen3-235b` | `qwen3-235b-a22b-2507` | ✅ Always | ✅ Yes | 81,920 | Complex reasoning + web |
| `qwen3-vl` | `qwen3-vl-235b-a22b` | ❌ Never | ✅ Yes | 81,920 | Vision-language tasks |
| `qwen3-omni` | `qwen3-omni-flash` | ❌ Never | ✅ Yes | 81,920 | Multimodal (text/image/audio/video) |

---

## 1️⃣ Qwen3-Max

**Alias**: `qwen3-max`  
**Actual Model**: `qwen3-max-latest`

### Features
- ✅ **Web Search**: Always applied server-side
- ❌ **Thinking Mode**: Not available
- 📊 **Max Tokens**: Provider default

### Best For
- General Q&A with internet access
- Current events and news queries
- Fact-checking with real-time data
- Research tasks requiring web sources

### Example Usage

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:8096/v1"
)

response = client.chat.completions.create(
    model="qwen3-max",
    messages=[
        {"role": "user", "content": "What are the latest AI breakthroughs in 2025?"}
    ]
)

print(response.choices[0].message.content)
```

```bash
# cURL
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-any" \
  -d '{
    "model": "qwen3-max",
    "messages": [
      {"role": "user", "content": "What are the latest AI breakthroughs?"}
    ]
  }'
```

---

## 2️⃣ Qwen3-235B

**Alias**: `qwen3-235b`  
**Actual Model**: `qwen3-235b-a22b-2507`

### Features
- ✅ **Web Search**: Always applied server-side
- ✅ **Thinking Mode**: Enabled for complex reasoning
- 📊 **Max Tokens**: 81,920 (extended context)

### Best For
- Complex problem solving with external data
- Multi-step reasoning tasks
- Research requiring both depth and breadth
- Long-context analysis with web verification

### Example Usage

```python
response = client.chat.completions.create(
    model="qwen3-235b",
    messages=[
        {"role": "user", "content": "Analyze the economic impact of AI across different sectors, citing recent data"}
    ]
)

print(response.choices[0].message.content)
# Server automatically applies: web_search + thinking + 81,920 tokens
```

### Notes
- Automatically configured with 81,920 token limit
- Thinking mode helps with complex multi-step reasoning
- Web search provides up-to-date information

---

## 3️⃣ Qwen3-VL

**Alias**: `qwen3-vl`  
**Actual Model**: `qwen3-vl-235b-a22b`

### Features
- ❌ **Web Search**: NOT applied (pure vision-language)
- ✅ **Thinking Mode**: Enabled
- 📊 **Max Tokens**: 81,920 (extended context)

### Best For
- Image analysis and understanding
- Visual question answering
- Document and diagram interpretation
- Multimodal tasks without web interference

### Example Usage

```python
response = client.chat.completions.create(
    model="qwen3-vl",
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "What architectural style is shown in this image? Provide detailed analysis."
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": "https://example.com/architecture.jpg"
                    }
                }
            ]
        }
    ]
)

print(response.choices[0].message.content)
```

### Notes
- NO web search applied (prevents interference with vision tasks)
- Thinking mode enabled for detailed visual reasoning
- Extended context (81,920 tokens) for long visual descriptions

---

## 4️⃣ Qwen3-Omni

**Alias**: `qwen3-omni`  
**Actual Model**: `qwen3-omni-flash`

### Features
- ❌ **Web Search**: NOT applied (pure omni-modal)
- ✅ **Thinking Mode**: Enabled
- 📊 **Max Tokens**: 81,920 (extended context)

### Best For
- Text + Image + Audio + Video analysis
- Cross-modal understanding tasks
- Multimedia content interpretation
- Complex multimodal reasoning

### Example Usage

```python
response = client.chat.completions.create(
    model="qwen3-omni",
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "Analyze this presentation"},
                {"type": "image_url", "image_url": {"url": "slide1.jpg"}},
                {"type": "audio_url", "audio_url": {"url": "narration.mp3"}},
                {"type": "video_url", "video_url": {"url": "demo.mp4"}}
            ]
        }
    ]
)

print(response.choices[0].message.content)
```

### Notes
- NO web search (focuses on provided multimedia)
- Thinking mode for complex cross-modal reasoning
- Extended context for processing multiple media types

---

## 🔄 Model Routing Logic

The API server automatically routes model names to the correct implementation:

```python
# Client specifies friendly alias
request = {"model": "qwen3-max", ...}

# Server routes to actual model
actual_model = "qwen3-max-latest"

# Server applies configured features
- Tools: ["web_search"]  # Auto-injected
- Max tokens: None       # Provider default
- Thinking: False
```

### Case-Insensitive

All model names are case-insensitive:

```python
"qwen3-max"   → qwen3-max-latest
"QWEN3-MAX"   → qwen3-max-latest
"Qwen3-Max"   → qwen3-max-latest
"qwen3_max"   → qwen3-max-latest
```

### Unknown Models

Unknown model names fall back to `qwen3-max`:

```python
"gpt-4"            → qwen3-max-latest (with web_search)
"claude-3-opus"    → qwen3-max-latest (with web_search)
"random-model-123" → qwen3-max-latest (with web_search)
```

---

## 🛠️ Tool Injection

The server automatically injects tools based on model configuration:

| Model | Auto-Injected Tools | Client Override |
|-------|---------------------|-----------------|
| `qwen3-max` | `web_search` | ✅ Yes |
| `qwen3-235b` | `web_search` | ✅ Yes |
| `qwen3-vl` | None | ✅ Yes |
| `qwen3-omni` | None | ✅ Yes |

### Client Can Override

```python
# Server would normally inject web_search for qwen3-max
# But client specifies custom tools
response = client.chat.completions.create(
    model="qwen3-max",
    tools=[{"type": "custom_calculator"}],  # Client override
    messages=[...]
)
# Server respects client choice, doesn't inject web_search
```

---

## 📊 Token Limits

| Model | Configured Limit | Client Override |
|-------|------------------|-----------------|
| `qwen3-max` | None (provider default) | ✅ Yes |
| `qwen3-235b` | 81,920 | ✅ Yes |
| `qwen3-vl` | 81,920 | ✅ Yes |
| `qwen3-omni` | 81,920 | ✅ Yes |

```python
# Server sets 81,920 tokens for qwen3-235b
# But client can override
response = client.chat.completions.create(
    model="qwen3-235b",
    max_tokens=50000,  # Client override
    messages=[...]
)
```

---

## 🎯 Choosing the Right Model

### Use **Qwen3-Max** when:
- ✅ You need current/real-time information
- ✅ Task requires web sources
- ✅ General purpose Q&A
- ✅ Speed is more important than deep reasoning

### Use **Qwen3-235B** when:
- ✅ Complex multi-step reasoning required
- ✅ Need both thinking AND web access
- ✅ Long context understanding needed (81,920 tokens)
- ✅ Research tasks combining analysis + verification

### Use **Qwen3-VL** when:
- ✅ Analyzing images or documents
- ✅ Visual Q&A tasks
- ✅ Don't want web search interference
- ✅ Need thinking for visual reasoning

### Use **Qwen3-Omni** when:
- ✅ Multimodal content (text + image + audio + video)
- ✅ Cross-modal understanding required
- ✅ Don't want web search interference
- ✅ Complex multimedia analysis needed

---

## 📝 API Compatibility

All 4 models are fully OpenAI API compatible:

```python
# Drop-in replacement for OpenAI API
from openai import OpenAI

# Just change base_url
client = OpenAI(
    api_key="sk-any",  # Any key works in anonymous mode
    base_url="http://localhost:8096/v1"  # Point to qwen-api
)

# Use any of the 4 models
response = client.chat.completions.create(
    model="qwen3-max",  # or qwen3-235b, qwen3-vl, qwen3-omni
    messages=[{"role": "user", "content": "Hello!"}]
)
```

### Streaming Support

All models support streaming:

```python
stream = client.chat.completions.create(
    model="qwen3-235b",
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

---

## 🔍 Testing Models

See [tests/README.md](tests/README.md) for comprehensive test coverage of all 4 models.

```bash
# Test all models
pytest tests/unit/test_model_router.py -v

# Test specific model
pytest tests/unit/test_model_router.py::TestModel1_Qwen3Max -v
```

---

**Last Updated**: 2025-01-03

