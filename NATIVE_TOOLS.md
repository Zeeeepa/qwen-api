# 🔥 Qwen Native Tools Support

The Qwen API has **NATIVE tool support** that actually executes in real-time. These are NOT simulated - they perform actual web searches, code execution, vision analysis, and deep research.

## 🚀 Available Native Tools

| Tool | Type | Capability | Status |
|------|------|-----------|---------|
| `web_search` | Simple | Real-time web browsing and search | ✅ Working |
| `code` | Function | Python code generation & execution | ⚠️ Needs schema |
| Vision | Multimodal | Image analysis via URLs | ✅ Working |
| Deep Research | Auto | Extended multi-source research | ✅ Working |

---

## 1️⃣ Web Search Tool

### ✅ **REAL Web Browsing**

The `web_search` tool actually browses the internet in real-time and fetches current information.

### Usage Example

```python
import requests

url = "http://localhost:7050/v1/chat/completions"

payload = {
    "model": "qwen-max-latest",
    "tools": [{"type": "web_search"}],  # ✅ Simple format
    "messages": [
        {
            "role": "user",
            "content": "What are the latest AI developments?"
        }
    ],
    "stream": False
}

response = requests.post(url, json=payload)
print(response.json())
```

### OpenAI Client Example

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:7050/v1"
)

# The model will actually browse the web!
result = client.chat.completions.create(
    model="qwen-max-latest",
    messages=[{"role": "user", "content": "Search for latest AI news"}],
    extra_body={"tools": [{"type": "web_search"}]}  # Pass tools in extra_body
)

print(result.choices[0].message.content)
```

### What It Can Do

- 🔍 Search for current information
- 🌐 Visit and extract content from websites
- 📰 Find news articles and updates
- 📊 Get real-time data and statistics
- ✅ Verify facts from multiple sources

### Example Response

```json
{
  "choices": [{
    "message": {
      "content": "Based on recent web search results:\n\n1. **Codegen API Documentation** can be found at https://docs.codegen.com/api-reference/...\n\n2. Key endpoints include:\n- GET /v1/agent-run-logs\n- POST /v1/agents/runs\n...\n\n**References:**\n1. [Codegen Documentation](https://docs.codegen.com/)\n2. [API Reference](https://docs.codegen.com/api-reference/cli-rules)"
    }
  }]
}
```

---

## 2️⃣ Code Tool (Requires Function Schema)

### ⚠️ **Status**: Needs proper function calling format

The `code` tool can generate and execute Python code, but requires the full OpenAI function calling schema.

### Expected Format

```python
payload = {
    "model": "qwen3-coder-plus",
    "tools": [{
        "type": "function",  # Must be "function", not just "code"
        "function": {
            "name": "execute_code",
            "description": "Execute Python code",
            "parameters": {
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Python code to execute"
                    }
                },
                "required": ["code"]
            }
        }
    }],
    "messages": [
        {
            "role": "user",
            "content": "Write Python code to fetch https://example.com and extract all links"
        }
    ]
}
```

### Capabilities

- 📝 Generate Python code
- ⚡ Execute code in sandbox
- 🔍 Web scraping and data extraction
- 🧮 Mathematical calculations
- 📊 Data processing and analysis

---

## 3️⃣ Vision/Multimodal

### ✅ **Image Analysis Working**

Vision models can analyze images provided as URLs.

### Usage Example

```python
import requests

url = "http://localhost:7050/v1/chat/completions"

payload = {
    "model": "qwen3-vl-plus",  # Vision model
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
                        "url": "https://example.com/image.png"
                    }
                }
            ]
        }
    ],
    "stream": False
}

response = requests.post(url, json=payload)
```

### OpenAI Client Example

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:7050/v1"
)

result = client.chat.completions.create(
    model="qwen3-vl-plus",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "Describe this image"},
            {"type": "image_url", "image_url": {"url": "https://example.com/pic.jpg"}}
        ]
    }]
)

print(result.choices[0].message.content)
```

### Capabilities

- 👁️ Describe image content
- 🏷️ Identify objects and people
- 📖 Read text in images (OCR)
- 🎨 Analyze colors and composition
- 📊 Extract data from charts/graphs

---

## 4️⃣ Deep Research Mode

### ✅ **Multi-Source Research Working**

The `qwen-deep-research` model automatically conducts comprehensive research across multiple sources.

### Usage Example

```python
import requests

url = "http://localhost:7050/v1/chat/completions"

payload = {
    "model": "qwen-deep-research",  # Research-specialized model
    "messages": [
        {
            "role": "user",
            "content": "Research the latest developments in quantum computing"
        }
    ],
    "stream": False
}

response = requests.post(url, json=payload)
```

### OpenAI Client Example

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-any",
    base_url="http://localhost:7050/v1"
)

result = client.chat.completions.create(
    model="qwen-deep-research",
    messages=[{"role": "user", "content": "Research AI safety developments"}],
    max_tokens=8000  # Allow extended responses
)

print(result.choices[0].message.content)
```

### Capabilities

- 🔬 Deep analysis of complex topics
- 📚 Multi-source fact checking
- 🧠 Extended reasoning (up to 8000 tokens)
- 📊 Comprehensive summaries
- ✅ Cited references from multiple sources

---

## 🔧 Complete Test Script

Save this as `test_native_tools.py`:

```python
#!/usr/bin/env python3
"""Test all Qwen native tools"""

import requests
import time

SERVER_PORT = 7050
BASE_URL = f"http://localhost:{SERVER_PORT}/v1"

print("=" * 80)
print("🧪 Testing Qwen Native Tools")
print("=" * 80)

# Test 1: Web Search
print("\n[1/3] Web Search Tool")
print("-" * 80)

response = requests.post(
    f"{BASE_URL}/chat/completions",
    json={
        "model": "qwen-max-latest",
        "tools": [{"type": "web_search"}],
        "messages": [{"role": "user", "content": "What is the latest Python version?"}]
    }
)

if response.status_code == 200:
    result = response.json()
    print(f"✅ Success!")
    print(result['choices'][0]['message']['content'][:300] + "...")
else:
    print(f"❌ Error: {response.text}")

time.sleep(2)

# Test 2: Vision
print("\n[2/3] Vision Tool")
print("-" * 80)

response = requests.post(
    f"{BASE_URL}/chat/completions",
    json={
        "model": "qwen3-vl-plus",
        "messages": [{
            "role": "user",
            "content": [
                {"type": "text", "text": "Describe this image"},
                {"type": "image_url", "image_url": {
                    "url": "https://download.samplelib.com/png/sample-hut-400x300.png"
                }}
            ]
        }]
    }
)

if response.status_code == 200:
    result = response.json()
    print(f"✅ Success!")
    print(result['choices'][0]['message']['content'][:200] + "...")
else:
    print(f"❌ Error: {response.text}")

time.sleep(2)

# Test 3: Deep Research
print("\n[3/3] Deep Research")
print("-" * 80)

response = requests.post(
    f"{BASE_URL}/chat/completions",
    json={
        "model": "qwen-deep-research",
        "messages": [{"role": "user", "content": "Brief overview of AI agents"}],
        "max_tokens": 2000
    }
)

if response.status_code == 200:
    result = response.json()
    print(f"✅ Success!")
    print(result['choices'][0]['message']['content'][:400] + "...")
else:
    print(f"❌ Error: {response.text}")

print("\n" + "=" * 80)
print("✅ All native tools tested!")
print("=" * 80)
```

Run with:
```bash
python test_native_tools.py
```

---

## 📊 Test Results Summary

From our testing:

| Tool | Request Format | Response Time | Status |
|------|---------------|---------------|--------|
| web_search | `{"type": "web_search"}` | 8-15s | ✅ Working |
| vision | Multimodal content array | 5-10s | ✅ Working |
| deep-research | Auto-enabled by model | 30-60s | ✅ Working |
| code | Needs function schema | N/A | ⚠️ Format issue |

---

## 🎯 Key Insights

### ✅ What Works Out of the Box

1. **Web Search**: Just add `{"tools": [{"type": "web_search"}]}`
2. **Vision**: Use multimodal message format with `image_url`
3. **Deep Research**: Select `qwen-deep-research` model
4. **Extended Thinking**: Add `max_tokens=8000` for longer responses

### ⚠️ What Needs Configuration

1. **Code Tool**: Requires full OpenAI function calling schema
2. **Custom Tools**: Must follow OpenAI tools specification

### 🔥 Performance Tips

- Web search: 8-15 seconds average
- Vision analysis: 5-10 seconds per image
- Deep research: 30-60 seconds for comprehensive analysis
- Use streaming for better UX: `"stream": True`

---

## 📚 Additional Resources

- [Qwen Official Documentation](https://qwen.readthedocs.io/)
- [OpenAI Function Calling Guide](https://platform.openai.com/docs/guides/function-calling)
- [Server API Reference](./openapi.json)

---

## 🐛 Troubleshooting

### Web Search Not Working?

```python
# ✅ Correct
{"tools": [{"type": "web_search"}]}

# ❌ Wrong
{"tools": ["web_search"]}  # Must be object, not string
```

### Vision Errors?

```python
# ✅ Correct - Use qwen3-vl-plus or qwen3-vl-max
"model": "qwen3-vl-plus"

# ❌ Wrong - Standard models don't support vision
"model": "qwen-max-latest"  # Use VL models for images
```

### Code Tool 400 Error?

The `code` tool needs full function schema. We're working on automatic schema injection for simpler usage. Current workaround: use `web_search` or `deep-research` models which can generate code without explicit tool definitions.

---

## 💡 Pro Tips

1. **Combine Tools**: Use `web_search` with `deep-research` model for best results
2. **Streaming**: Add `"stream": True` for real-time responses
3. **Token Limits**: Increase `max_tokens` for comprehensive answers (up to 8000)
4. **Model Selection**: 
   - General + Web: `qwen-max-latest`
   - Vision: `qwen3-vl-plus`
   - Code: `qwen3-coder-plus`
   - Research: `qwen-deep-research`

---

**Last Updated**: October 17, 2025  
**Server Version**: 2.0.0  
**Tested Models**: qwen-max-latest, qwen3-vl-plus, qwen3-coder-plus, qwen-deep-research

