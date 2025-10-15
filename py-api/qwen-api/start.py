#!/usr/bin/env python3
"""
start.py - Entry point to start the Qwen OpenAI-compatible API server
"""

import sys
import os
from pathlib import Path

# Import the server
try:
    from qwen_openai_server import app, HOST, PORT
except ImportError:
    # If running as script, add current directory to path
    sys.path.insert(0, str(Path(__file__).parent))
    from qwen_openai_server import app, HOST, PORT


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

