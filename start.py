#!/usr/bin/env python3
"""
Start script for Qwen OpenAI-Compatible API Server
Works with the new modular py-api structure
Supports command-line arguments for backward compatibility with start.sh
"""

import sys
import os
import argparse
from pathlib import Path

# Add py-api to Python path
PROJECT_ROOT = Path(__file__).parent
PY_API_DIR = PROJECT_ROOT / "py-api"
sys.path.insert(0, str(PY_API_DIR))

def main():
    """Parse arguments and start server"""
    parser = argparse.ArgumentParser(
        description="Qwen OpenAI-Compatible API Server"
    )
    parser.add_argument(
        "--port", "-p",
        type=int,
        help="Server port (overrides PORT env var)"
    )
    parser.add_argument(
        "--host", "-H",
        type=str,
        help="Server host (overrides HOST env var)"
    )
    parser.add_argument(
        "--debug", "-d",
        action="store_true",
        help="Enable debug logging (overrides LOG_LEVEL env var)"
    )
    
    args = parser.parse_args()
    
    # Override environment variables with command-line arguments
    if args.port:
        os.environ["PORT"] = str(args.port)
    if args.host:
        os.environ["HOST"] = args.host
    if args.debug:
        os.environ["LOG_LEVEL"] = "DEBUG"
    
    # Now import and run the main application
    try:
        # Import main from py-api/main.py
        from main import main as run_server
        
        # Run the server
        run_server()
        
    except ImportError as e:
        print(f"❌ Error importing main module: {e}", file=sys.stderr)
        print(f"   Make sure py-api/ directory exists and contains main.py", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error starting server: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()

