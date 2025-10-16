# Complete model mapping with all models from the Qwen API
VALID_QWEN_MODELS = {
    # Qwen 3.x Main Models
    "qwen3-max": "qwen3-max",
    "qwen3-max-latest": "qwen3-max",
    "qwen3-vl-plus": "qwen3-vl-plus",
    "qwen3-vl-235b-a22b": "qwen3-vl-plus",  # Alias
    "qwen3-coder-plus": "qwen3-coder-plus",
    "qwen3-coder": "qwen3-coder-plus",  # Alias
    "qwen3-vl-30b-a3b": "qwen3-vl-30b-a3b",
    "qwen3-omni-flash": "qwen3-omni-flash",
    "qwen3-next-80b-a3b": "qwen-plus-2025-09-11",  # Actual ID
    "qwen-plus-2025-09-11": "qwen-plus-2025-09-11",
    "qwen3-235b-a22b": "qwen3-235b-a22b",
    "qwen3-235b-a22b-2507": "qwen3-235b-a22b",  # Alias
    "qwen3-30b-a3b": "qwen3-30b-a3b",
    "qwen3-30b-a3b-2507": "qwen3-30b-a3b",  # Alias
    "qwen3-coder-30b-a3b-instruct": "qwen3-coder-30b-a3b-instruct",
    "qwen3-coder-flash": "qwen3-coder-30b-a3b-instruct",  # Alias
    
    # Qwen 2.5 Models
    "qwen-max-latest": "qwen-max-latest",
    "qwen2.5-max": "qwen-max-latest",  # Alias
    "qwen-plus-2025-01-25": "qwen-plus-2025-01-25",
    "qwen2.5-plus": "qwen-plus-2025-01-25",  # Alias
    "qwq-32b": "qwq-32b",
    "qwen-turbo-2025-02-11": "qwen-turbo-2025-02-11",
    "qwen2.5-turbo": "qwen-turbo-2025-02-11",  # Alias
    "qwen2.5-omni-7b": "qwen2.5-omni-7b",
    "qvq-72b-preview-0310": "qvq-72b-preview-0310",
    "qvq-max": "qvq-72b-preview-0310",  # Alias
    "qwen2.5-vl-32b-instruct": "qwen2.5-vl-32b-instruct",
    "qwen2.5-14b-instruct-1m": "qwen2.5-14b-instruct-1m",
    "qwen2.5-coder-32b-instruct": "qwen2.5-coder-32b-instruct",
    "qwen2.5-72b-instruct": "qwen2.5-72b-instruct",
    
    # Special purpose models (from your table)
    "qwen-deep-research": "qwen3-max",  # Maps to qwen3-max with special mode
    "qwen-web-dev": "qwen3-max",  # Maps to qwen3-max with web dev mode
    "qwen-full-stack": "qwen3-max",  # Maps to qwen3-max with full stack mode
    
    # Legacy / Common aliases
    "qwen-max": "qwen3-max",
    "qwen-plus": "qwen-plus-2025-01-25",
    "qwen-turbo": "qwen-turbo-2025-02-11",
}

# Model capabilities mapping
MODEL_CAPABILITIES = {
    "qwen3-max": {"vision": True, "reasoning": False, "web_search": True, "tools": False},
    "qwen3-vl-plus": {"vision": True, "reasoning": True, "web_search": False, "tools": False},
    "qwen3-coder-plus": {"vision": True, "reasoning": False, "web_search": True, "tools": True},
    "qwen3-omni-flash": {"vision": True, "reasoning": True, "web_search": False, "tools": False},
    "qwen-plus-2025-09-11": {"vision": True, "reasoning": True, "web_search": True, "tools": False},
    "qwen3-235b-a22b": {"vision": True, "reasoning": True, "web_search": True, "tools": False},
    "qwen3-30b-a3b": {"vision": True, "reasoning": True, "web_search": True, "tools": False},
    "qwen3-coder-30b-a3b-instruct": {"vision": True, "reasoning": False, "web_search": True, "tools": True},
    "qwen-max-latest": {"vision": True, "reasoning": False, "web_search": True, "tools": False},
    "qwen-plus-2025-01-25": {"vision": True, "reasoning": False, "web_search": True, "tools": False},
    "qwq-32b": {"vision": False, "reasoning": True, "web_search": True, "tools": False},
    "qwen-turbo-2025-02-11": {"vision": True, "reasoning": False, "web_search": True, "tools": False},
    "qvq-72b-preview-0310": {"vision": True, "reasoning": False, "web_search": False, "tools": False},
}

DEFAULT_MODEL = "qwen3-max"

def map_model_name(model: str = None) -> str:
    """Map any model name to a valid Qwen model"""
    if not model:
        return DEFAULT_MODEL
    
    normalized = model.lower().strip().replace(" ", "-")
    
    if normalized in VALID_QWEN_MODELS:
        return VALID_QWEN_MODELS[normalized]
    
    print(f"⚠️  Unknown model '{model}', using default: {DEFAULT_MODEL}")
    return DEFAULT_MODEL
