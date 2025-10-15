#!/usr/bin/env python3
"""
Wrapper script to extract Qwen token using existing qwen_token_extractor
Outputs token to stdout for bash script consumption
"""

import sys
import os
import asyncio

# Add py-api to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'py-api'))

try:
    from qwen_token_extractor import get_qwen_token
except ImportError:
    print("ERROR: qwen_token_extractor module not found", file=sys.stderr)
    print("Make sure py-api directory exists", file=sys.stderr)
    sys.exit(1)


async def main():
    """Main entry point"""
    # Get credentials from environment or command line
    email = os.getenv("QWEN_EMAIL") or (sys.argv[1] if len(sys.argv) > 1 else None)
    password = os.getenv("QWEN_PASSWORD") or (sys.argv[2] if len(sys.argv) > 2 else None)
    
    if not email or not password:
        print("ERROR: QWEN_EMAIL and QWEN_PASSWORD must be set", file=sys.stderr)
        print("Usage: QWEN_EMAIL=xxx QWEN_PASSWORD=xxx python3 get_qwen_token.py", file=sys.stderr)
        print("   or: python3 get_qwen_token.py <email> <password>", file=sys.stderr)
        sys.exit(1)
    
    # Extract token
    print(f"🔑 Extracting token for {email}...", file=sys.stderr)
    token = await get_qwen_token(email, password)
    
    if token:
        # Output token to stdout (for bash capture)
        print(token)
        print(f"✅ Token extracted successfully ({len(token)} chars)", file=sys.stderr)
        sys.exit(0)
    else:
        print("❌ Failed to extract token", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())

