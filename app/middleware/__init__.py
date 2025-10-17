"""
Middleware module for request/response processing
"""

from app.middleware.openapi_validator import OpenAPIValidationMiddleware

__all__ = ["OpenAPIValidationMiddleware"]
