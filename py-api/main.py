#!/usr/bin/env python3
"""
Main Entry Point for Qwen OpenAI-Compatible API Server
Replaces old start.py with clean modular architecture
"""

import sys
import uvicorn

# Import from qwen-api package
sys.path.insert(0, "qwen-api")

from config_loader import settings
from logging_config import logger
from api_server import app


def main():
    """Start the Qwen OpenAI API server"""
    
    # Validate configuration
    if not settings.qwen_bearer_token:
        logger.error("❌ QWEN_BEARER_TOKEN not set in environment")
        logger.error("   Please run setup.sh first to extract token")
        sys.exit(1)
    
    logger.info(f"🚀 Starting Qwen OpenAI Proxy v2.0.0")
    logger.info(f"   Host: {settings.host}:{settings.port}")
    logger.info(f"   Token: {settings.qwen_bearer_token[:20]}...")
    logger.info(f"   Endpoints: http://{settings.host}:{settings.port}/v1/chat/completions")
    logger.info(f"   Log level: {settings.log_level}")
    
    # Start server with quiet logging
    uvicorn.run(
        app,
        host=settings.host,
        port=settings.port,
        log_level=settings.log_level.lower(),
        access_log=False  # Disable access logs for quietness
    )


if __name__ == '__main__':
    main()

