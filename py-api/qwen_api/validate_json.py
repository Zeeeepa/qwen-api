#!/usr/bin/env python3
"""
validate_json.py - JSON Schema validator for qwen.json and openapi.json
"""

import json
import sys
from pathlib import Path
from typing import Dict, Any


def validate_json_file(filepath: str) -> bool:
    """
    Validate that a file contains valid JSON.
    
    Args:
        filepath: Path to JSON file
        
    Returns:
        True if valid, False otherwise
    """
    try:
        path = Path(filepath)
        if not path.exists():
            print(f"❌ File not found: {filepath}")
            return False
            
        with open(path, 'r') as f:
            data = json.load(f)
            
        print(f"✅ Valid JSON: {filepath}")
        print(f"   Keys: {', '.join(data.keys())}")
        return True
        
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in {filepath}: {e}")
        return False
    except Exception as e:
        print(f"❌ Error reading {filepath}: {e}")
        return False


def validate_schema_structure(data: Dict[str, Any], schema_type: str) -> bool:
    """
    Validate the structure of a schema file.
    
    Args:
        data: Parsed JSON data
        schema_type: Type of schema ('qwen' or 'openapi')
        
    Returns:
        True if structure is valid
    """
    if schema_type == 'qwen':
        required_keys = ['definitions', 'request', 'response']
        for key in required_keys:
            if key not in data:
                print(f"❌ Missing required key: {key}")
                return False
        print("✅ Qwen schema structure valid")
        return True
        
    elif schema_type == 'openapi':
        required_keys = ['openapi', 'info', 'paths', 'components']
        for key in required_keys:
            if key not in data:
                print(f"❌ Missing required key: {key}")
                return False
        print("✅ OpenAPI schema structure valid")
        return True
        
    return False


def main():
    """Main validation function"""
    if len(sys.argv) < 2:
        print("Usage: python3 validate_json.py <file.json>")
        print("   or: python3 validate_json.py qwen")
        print("   or: python3 validate_json.py openapi")
        sys.exit(1)
        
    target = sys.argv[1]
    
    # Determine file paths
    if target == 'qwen':
        filepath = 'qwen.json'
        schema_type = 'qwen'
    elif target == 'openapi':
        filepath = 'openapi.json'
        schema_type = 'openapi'
    else:
        filepath = target
        schema_type = None
        
    # Validate JSON syntax
    if not validate_json_file(filepath):
        sys.exit(1)
        
    # Validate schema structure if applicable
    if schema_type:
        with open(filepath, 'r') as f:
            data = json.load(f)
        if not validate_schema_structure(data, schema_type):
            sys.exit(1)
            
    print(f"\n✅ {filepath} is valid!")
    sys.exit(0)


if __name__ == '__main__':
    main()

