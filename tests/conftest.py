"""
Pytest configuration for Qwen API tests.

This file contains shared fixtures and configuration for all tests.
"""

import os
import sys
from pathlib import Path

# Add project root to Python path for imports
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Pytest configuration
def pytest_configure(config):
    """Configure pytest with custom markers."""
    config.addinivalue_line(
        "markers", "integration: marks tests as integration tests (may be slow)"
    )
    config.addinivalue_line(
        "markers", "unit: marks tests as fast unit tests"
    )
    config.addinivalue_line(
        "markers", "requires_auth: marks tests that require Qwen authentication"
    )

