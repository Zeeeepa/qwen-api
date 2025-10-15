# Archived Files

This directory contains files that have been replaced by the modular architecture refactor.

## Removed Files

### 1. `qwen_openai_server.py` (Archived: 2025-01-15)
- **Reason**: Monolithic inline implementation replaced by modular backend
- **Replacement**: `qwen-api/api_server.py` + supporting modules
- **Lines**: 404 lines → Replaced with modular 6-file architecture
- **Why archived**: Single-file inline httpx calls with duplicated logic

### 2. `start.py` (Archived: 2025-01-15)
- **Reason**: Simple loader replaced by proper entry point
- **Replacement**: `main.py` with proper imports and configuration
- **Lines**: 51 lines → 47 lines in main.py
- **Why archived**: Used importlib hacks, no configuration management

## New Modular Architecture

The replacement architecture consists of:

```
py-api/
├── main.py                          # New entry point (replaces start.py)
└── qwen-api/
    ├── __init__.py                  # Package initialization
    ├── api_server.py                # FastAPI routes (replaces qwen_openai_server.py)
    ├── config_loader.py             # Centralized configuration
    ├── logging_config.py            # Quiet logging setup
    ├── model_mapper.py              # Model name mapping logic
    ├── request_normalizer.py        # Request format normalization
    └── qwen_client.py               # Qwen API client wrapper
```

## Benefits of New Architecture

1. **Separation of Concerns**: Each module has single responsibility
2. **Testability**: Modules can be tested independently
3. **Maintainability**: Changes isolated to specific files
4. **Configurability**: Centralized settings with env var overrides
5. **Quiet Logging**: Default WARNING level, configurable via LOG_LEVEL
6. **Extensibility**: Easy to add new providers or features

## How to Restore (If Needed)

If you need to restore the old implementation:

```bash
cd py-api
git mv archive/qwen_openai_server.py qwen-api/
git mv archive/start.py .
```

## Dead Code Analysis

After refactoring, the following backend modules are **still unused**:
- `base.py` - Provider base classes (72 lines)
- `check_jwt_expiry.py` - JWT validation (43 lines)
- `cli.py` - CLI interface (78 lines)
- `config.py` - Old config system (72 lines) - replaced by config_loader.py
- `get_qwen_token.py` - Token getter (28 lines)
- `health.py` - Health check endpoint (88 lines) - duplicates api_server.py
- `http_client.py` - HTTP client (120 lines) - replaced by qwen_client.py
- `image_endpoints.py` - Image generation (104 lines)
- `openai.py` - OpenAI compatibility layer (157 lines) - replaced by api_server.py
- `provider_auth.py` - Provider authentication (164 lines)
- `provider_factory.py` - Provider factory (115 lines) - not needed for simple proxy
- `qwen_provider.py` - Qwen provider implementation (871 lines)
- `qwen_proxy_provider.py` - Proxy provider (153 lines)
- `qwen_token_extractor.py` - Token extraction (68 lines)
- `qwen_transformer.py` - Response transformation (427 lines)
- `reload_config.py` - Config reload (25 lines)
- `request_tracker.py` - Request tracking (139 lines)
- `schemas.py` - Pydantic schemas (38 lines) - replaced by api_server.py
- `session_store.py` - Session storage (71 lines)
- `sse_tool_handler.py` - SSE tool handling (286 lines)
- `token_compressor.py` - Token compression (61 lines)
- `token_pool.py` - Token pool management (201 lines)
- `token_utils.py` - Token utilities (41 lines)
- `user_agent.py` - User agent management (47 lines)
- `validate_json.py` - JSON validation (36 lines)

**Total unused code**: ~3,858 lines across 27 files

These files were designed for a more complex architecture with:
- Multiple provider support
- Token pooling and rotation
- Session management
- Image generation
- CLI tools

For the current use case (simple OpenAI-compatible proxy), they are not needed.

**Recommendation**: Keep these files for now as they may be useful for future features. If you want a truly minimal setup, consider archiving them as well.

## Migration Notes

### Environment Variables
Same as before:
- `QWEN_BEARER_TOKEN` - Required
- `HOST` - Optional (default: 0.0.0.0)
- `PORT` - Optional (default: 7050)
- `LOG_LEVEL` - **NEW** - Optional (default: WARNING)

### API Compatibility
100% compatible with old server:
- Same endpoints: /, /v1/models, /v1/chat/completions
- Same request/response format
- Same model mapping behavior
- Accepts any API key (ignores it)

### Testing
Old test still works:
```bash
python test_client.py
```

Just update the port if needed (default changed to 7050).

