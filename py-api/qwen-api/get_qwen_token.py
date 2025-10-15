#!/usr/bin/env python3
"""
get_qwen_token.py - Wrapper to extract Qwen JWT token
This is a convenience wrapper around qwen_token_real.py
"""

import sys
import os
import asyncio
from pathlib import Path

# Import the actual implementation
try:
    from qwen_token_real import extract_qwen_token
except ImportError:
    # If running as script, add current directory to path
    sys.path.insert(0, str(Path(__file__).parent))
    from qwen_token_real import extract_qwen_token


async def main_async():
    """
    Main async function to extract Qwen token.
    
    Requires QWEN_EMAIL and QWEN_PASSWORD environment variables.
    """
    email = os.getenv('QWEN_EMAIL')
    password = os.getenv('QWEN_PASSWORD')
    
    if not email or not password:
        print("❌ Error: QWEN_EMAIL and QWEN_PASSWORD must be set", file=sys.stderr)
        print("", file=sys.stderr)
        print("Usage:", file=sys.stderr)
        print("  export QWEN_EMAIL='your@email.com'", file=sys.stderr)
        print("  export QWEN_PASSWORD='yourpassword'", file=sys.stderr)
        print("  python3 get_qwen_token.py", file=sys.stderr)
        sys.exit(1)
    
    try:
        # Extract token (async call)
        token = await extract_qwen_token(email, password)
        
        if token:
            # Output only the token to stdout (for piping)
            print(token)
            sys.exit(0)
        else:
            print("❌ Failed to extract token", file=sys.stderr)
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    """Entry point that runs the async main function"""
    asyncio.run(main_async())


if __name__ == '__main__':
    main()
