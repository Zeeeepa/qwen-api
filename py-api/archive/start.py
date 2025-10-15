#!/usr/bin/env python3
"""
start.py - Entry point to start the Qwen OpenAI-compatible API server
"""

import sys
import os
from pathlib import Path

# Import the server module directly using importlib
import importlib.util

# Locate and load the server module
server_path = Path(__file__).parent / "qwen-api" / "qwen_openai_server.py"
spec = importlib.util.spec_from_file_location("qwen_openai_server", server_path)
server_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server_module)

# Get the app and config from the module
app = server_module.app
HOST = server_module.HOST
PORT = server_module.PORT


def main():
    """Start the Qwen OpenAI API server"""
    import uvicorn
    
    # Check token
    token = os.getenv('QWEN_BEARER_TOKEN')
    if not token:
        print("❌ Error: QWEN_BEARER_TOKEN not set in environment")
        print("   Please run setup.sh first to extract token")
        sys.exit(1)
    
    print(f"🚀 Starting Qwen OpenAI Proxy on port {PORT}...")
    print(f"   Token loaded: {token[:20]}...")
    print(f"   Access server at: http://{HOST}:{PORT}")
    print(f"   OpenAI endpoint: http://{HOST}:{PORT}/v1/chat/completions")
    
    # Start server
    uvicorn.run(
        app,
        host=HOST,
        port=PORT,
        log_level="info"
    )


if __name__ == '__main__':
    main()
