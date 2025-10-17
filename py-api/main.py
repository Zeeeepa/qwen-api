#!/usr/bin/env python3
"""
Main Entry Point for Qwen OpenAI-Compatible API Server
Legacy compatibility wrapper - use `qwen-api serve` instead
"""

import sys
import warnings

warnings.warn(
    "Using main.py is deprecated. Please use 'qwen-api serve' command instead.",
    DeprecationWarning,
    stacklevel=2
)

# Import from qwen_api package
from qwen_api.cli import cli

if __name__ == '__main__':
    sys.exit(cli())

