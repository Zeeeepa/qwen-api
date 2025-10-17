#!/usr/bin/env python3
"""
Test the Qwen OpenAI proxy with any API key and model name
"""

from openai import OpenAI

client = OpenAI(
    api_key="sk-any",  # ✅ Any key works!
    base_url="http://localhost:7050/v1"  # Updated default port
)

result = client.chat.completions.create(
    model="gpt-5",  # ✅ Any model works!
    messages=[{"role": "user", "content": "Write a haiku about code."}]
)

print(result.choices[0].message.content)
