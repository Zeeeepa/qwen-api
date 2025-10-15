#!/usr/bin/env python3
"""
Logging Configuration
Centralized logging setup with quiet defaults
"""

import logging
import sys
from config_loader import settings


def setup_logging():
    """
    Configure logging for the application
    - Quiet by default (WARNING level)
    - Configurable via LOG_LEVEL env var
    - Suppresses noisy third-party loggers
    """
    # Map string to logging level
    level_map = {
        "DEBUG": logging.DEBUG,
        "INFO": logging.INFO,
        "WARNING": logging.WARNING,
        "ERROR": logging.ERROR,
        "CRITICAL": logging.CRITICAL,
    }
    
    log_level = level_map.get(settings.log_level, logging.WARNING)
    
    # Root logger configuration
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        handlers=[logging.StreamHandler(sys.stderr)]
    )
    
    # Suppress noisy third-party loggers
    logging.getLogger("uvicorn").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.error").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("asyncio").setLevel(logging.WARNING)
    
    # Application logger at configured level
    app_logger = logging.getLogger("qwen_api")
    app_logger.setLevel(log_level)
    
    return app_logger


# Initialize logger
logger = setup_logging()
