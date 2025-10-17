"""
OpenAPI Request/Response Validation Middleware

Uses the qwen.json OpenAPI specification to validate all incoming requests
and outgoing responses against the defined schemas.

Features:
- Automatic request body validation
- Automatic response validation
- Detailed error messages with schema violations
- Support for OpenAPI 3.1.0 specifications
"""

import json
from pathlib import Path
from typing import Dict, Any, Optional, Callable
from fastapi import Request, Response
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.types import ASGIApp
from jsonschema import validate, ValidationError, Draft7Validator
from jsonschema.exceptions import SchemaError
from app.utils.logger import logger


class OpenAPIValidator:
    """
    OpenAPI Schema Validator
    
    Loads and caches the OpenAPI specification from qwen.json
    and provides validation methods for requests and responses.
    """
    
    def __init__(self, spec_path: str = "qwen.json"):
        """
        Initialize the validator with an OpenAPI specification file.
        
        Args:
            spec_path: Path to the OpenAPI JSON specification file
        """
        self.spec_path = Path(spec_path)
        self.spec: Optional[Dict[str, Any]] = None
        self.schemas: Dict[str, Any] = {}
        self.paths: Dict[str, Any] = {}
        self._load_spec()
    
    def _load_spec(self) -> None:
        """Load and parse the OpenAPI specification"""
        try:
            if not self.spec_path.exists():
                logger.warning(f"OpenAPI spec not found at {self.spec_path}")
                return
            
            with open(self.spec_path, 'r', encoding='utf-8') as f:
                self.spec = json.load(f)
            
            # Extract schemas and paths
            self.schemas = self.spec.get('components', {}).get('schemas', {})
            self.paths = self.spec.get('paths', {})
            
            logger.info(f"✅ Loaded OpenAPI spec: {len(self.paths)} paths, {len(self.schemas)} schemas")
            
        except Exception as e:
            logger.error(f"❌ Failed to load OpenAPI spec: {e}")
    
    def _resolve_ref(self, ref: str) -> Optional[Dict[str, Any]]:
        """
        Resolve a $ref pointer to the actual schema.
        
        Args:
            ref: Reference string like "#/components/schemas/ChatRequest"
            
        Returns:
            The resolved schema or None if not found
        """
        if not ref.startswith('#/'):
            return None
        
        parts = ref[2:].split('/')
        current = self.spec
        
        for part in parts:
            if isinstance(current, dict) and part in current:
                current = current[part]
            else:
                return None
        
        return current
    
    def _resolve_schema_refs(self, schema: Dict[str, Any]) -> Dict[str, Any]:
        """
        Recursively resolve all $ref in a schema.
        
        Args:
            schema: Schema that may contain $ref
            
        Returns:
            Schema with all $ref resolved
        """
        if not isinstance(schema, dict):
            return schema
        
        if '$ref' in schema:
            resolved = self._resolve_ref(schema['$ref'])
            if resolved:
                return self._resolve_schema_refs(resolved)
            return schema
        
        # Recursively resolve refs in nested structures
        result = {}
        for key, value in schema.items():
            if isinstance(value, dict):
                result[key] = self._resolve_schema_refs(value)
            elif isinstance(value, list):
                result[key] = [
                    self._resolve_schema_refs(item) if isinstance(item, dict) else item
                    for item in value
                ]
            else:
                result[key] = value
        
        return result
    
    def get_request_schema(self, path: str, method: str) -> Optional[Dict[str, Any]]:
        """
        Get the request body schema for a specific path and method.
        
        Args:
            path: API path (e.g., "/chat/completions")
            method: HTTP method (e.g., "post")
            
        Returns:
            Request body schema or None if not found
        """
        if path not in self.paths:
            return None
        
        method_lower = method.lower()
        if method_lower not in self.paths[path]:
            return None
        
        operation = self.paths[path][method_lower]
        request_body = operation.get('requestBody', {})
        content = request_body.get('content', {})
        
        # Get JSON schema
        json_content = content.get('application/json', {})
        schema = json_content.get('schema', {})
        
        if not schema:
            return None
        
        # Resolve all $ref
        return self._resolve_schema_refs(schema)
    
    def get_response_schema(self, path: str, method: str, status_code: int = 200) -> Optional[Dict[str, Any]]:
        """
        Get the response schema for a specific path, method, and status code.
        
        Args:
            path: API path (e.g., "/chat/completions")
            method: HTTP method (e.g., "post")
            status_code: HTTP status code (default: 200)
            
        Returns:
            Response schema or None if not found
        """
        if path not in self.paths:
            return None
        
        method_lower = method.lower()
        if method_lower not in self.paths[path]:
            return None
        
        operation = self.paths[path][method_lower]
        responses = operation.get('responses', {})
        
        # Try exact status code, then default
        response = responses.get(str(status_code)) or responses.get('default')
        if not response:
            return None
        
        content = response.get('content', {})
        json_content = content.get('application/json', {})
        schema = json_content.get('schema', {})
        
        if not schema:
            return None
        
        # Resolve all $ref
        return self._resolve_schema_refs(schema)
    
    def validate_request(self, path: str, method: str, data: Any) -> tuple[bool, Optional[str]]:
        """
        Validate a request body against the OpenAPI schema.
        
        Args:
            path: API path
            method: HTTP method
            data: Request data to validate
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        schema = self.get_request_schema(path, method)
        if not schema:
            # No schema defined, skip validation
            return True, None
        
        try:
            validate(instance=data, schema=schema)
            return True, None
        except ValidationError as e:
            error_msg = f"Request validation failed: {e.message} at path {'.'.join(str(p) for p in e.path)}"
            return False, error_msg
        except SchemaError as e:
            logger.error(f"Schema error: {e}")
            return True, None  # Don't fail request due to schema issues
    
    def validate_response(self, path: str, method: str, data: Any, status_code: int = 200) -> tuple[bool, Optional[str]]:
        """
        Validate a response body against the OpenAPI schema.
        
        Args:
            path: API path
            method: HTTP method
            data: Response data to validate
            status_code: HTTP status code
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        schema = self.get_response_schema(path, method, status_code)
        if not schema:
            # No schema defined, skip validation
            return True, None
        
        try:
            validate(instance=data, schema=schema)
            return True, None
        except ValidationError as e:
            error_msg = f"Response validation failed: {e.message} at path {'.'.join(str(p) for p in e.path)}"
            return False, error_msg
        except SchemaError as e:
            logger.error(f"Schema error: {e}")
            return True, None  # Don't fail response due to schema issues


class OpenAPIValidationMiddleware(BaseHTTPMiddleware):
    """
    FastAPI middleware for automatic OpenAPI validation.
    
    Validates all incoming requests and outgoing responses against
    the OpenAPI specification defined in qwen.json.
    """
    
    def __init__(
        self,
        app: ASGIApp,
        spec_path: str = "qwen.json",
        validate_requests: bool = True,
        validate_responses: bool = True,
        strict_mode: bool = False
    ):
        """
        Initialize the validation middleware.
        
        Args:
            app: FastAPI application
            spec_path: Path to OpenAPI specification file
            validate_requests: Enable request validation
            validate_responses: Enable response validation
            strict_mode: If True, return 500 errors for response validation failures
        """
        super().__init__(app)
        self.validator = OpenAPIValidator(spec_path)
        self.validate_requests = validate_requests
        self.validate_responses = validate_responses
        self.strict_mode = strict_mode
    
    async def dispatch(
        self,
        request: Request,
        call_next: RequestResponseEndpoint
    ) -> Response:
        """
        Process the request and validate according to OpenAPI spec.
        
        Args:
            request: Incoming request
            call_next: Next middleware in chain
            
        Returns:
            Response (possibly with validation errors)
        """
        # Extract path for validation (remove /v1 prefix if present)
        path = request.url.path
        if path.startswith('/v1'):
            path = path[3:]  # Remove /v1 prefix
        
        method = request.method
        
        # Validate request body if enabled
        if self.validate_requests and method in ['POST', 'PUT', 'PATCH']:
            try:
                # Read request body
                body = await request.body()
                if body:
                    data = json.loads(body)
                    
                    # Validate against schema
                    is_valid, error_msg = self.validator.validate_request(path, method, data)
                    
                    if not is_valid:
                        logger.warning(f"❌ Request validation failed: {error_msg}")
                        return JSONResponse(
                            status_code=400,
                            content={
                                "error": {
                                    "message": error_msg,
                                    "type": "invalid_request_error",
                                    "code": "request_validation_failed"
                                }
                            }
                        )
                    
                    logger.debug(f"✅ Request validation passed: {method} {path}")
                    
            except json.JSONDecodeError as e:
                logger.warning(f"❌ Invalid JSON in request body: {e}")
                return JSONResponse(
                    status_code=400,
                    content={
                        "error": {
                            "message": f"Invalid JSON: {str(e)}",
                            "type": "invalid_request_error",
                            "code": "json_decode_error"
                        }
                    }
                )
            except Exception as e:
                logger.error(f"❌ Request validation error: {e}")
                # Don't fail the request due to validation errors
        
        # Call the next middleware/endpoint
        response = await call_next(request)
        
        # Validate response if enabled
        if self.validate_responses and response.status_code < 500:
            try:
                # Only validate JSON responses
                content_type = response.headers.get('content-type', '')
                if 'application/json' in content_type:
                    # Read response body
                    body = b''
                    async for chunk in response.body_iterator:
                        body += chunk
                    
                    if body:
                        data = json.loads(body)
                        
                        # Validate against schema
                        is_valid, error_msg = self.validator.validate_response(
                            path, method, data, response.status_code
                        )
                        
                        if not is_valid:
                            logger.error(f"❌ Response validation failed: {error_msg}")
                            
                            if self.strict_mode:
                                # Return error response
                                return JSONResponse(
                                    status_code=500,
                                    content={
                                        "error": {
                                            "message": "Internal server error: Response validation failed",
                                            "type": "internal_error",
                                            "code": "response_validation_failed"
                                        }
                                    }
                                )
                        else:
                            logger.debug(f"✅ Response validation passed: {method} {path}")
                        
                        # Reconstruct response with same body
                        return Response(
                            content=body,
                            status_code=response.status_code,
                            headers=dict(response.headers),
                            media_type=response.media_type
                        )
            
            except Exception as e:
                logger.error(f"❌ Response validation error: {e}")
                # Don't modify response due to validation errors
        
        return response
