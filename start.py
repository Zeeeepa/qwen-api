#!/usr/bin/env python3

"""
Entry point for Qwen API Server
Delegates to main module for actual server implementation
"""

if __name__ == "__main__":
    # Import and run the CLI main function
    from app.cli import main as cli_main
    cli_main()

