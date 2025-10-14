#!/usr/bin/env python3
"""
Direct Requests Example - Request Transformation
================================================
Shows how the server transforms OpenAI requests to Qwen format
"""

import requests
import json

# Send OpenAI-format request to local server
response = requests.post(
    "http://localhost:8096/v1/chat/completions",
    headers={
        "Content-Type": "application/json",
        "Authorization": "Bearer sk-test"
    },
    json={
        "model": "qwen-max-latest",
        "messages": [{"role": "user", "content": "Hello!"}],
        "stream": False
    }
)

print(json.dumps(response.json(), indent=2))
