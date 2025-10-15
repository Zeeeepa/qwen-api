#!/usr/bin/env python3
"""
JSON Schema Validation Script
Validates JSON data against OpenAPI/JSON schemas
"""

import sys
import json
import argparse
from pathlib import Path

try:
    import jsonschema
    from jsonschema import validate, ValidationError, Draft7Validator
except ImportError:
    print("ERROR: jsonschema library not installed", file=sys.stderr)
    print("Install with: pip install jsonschema", file=sys.stderr)
    sys.exit(2)


def load_schema(schema_path: str) -> dict:
    """
    Load JSON schema from file
    
    Args:
        schema_path: Path to schema file
        
    Returns:
        dict: Loaded schema
        
    Raises:
        FileNotFoundError: If schema file doesn't exist
        json.JSONDecodeError: If schema is invalid JSON
    """
    path = Path(schema_path)
    if not path.exists():
        raise FileNotFoundError(f"Schema file not found: {schema_path}")
    
    with open(path, 'r') as f:
        return json.load(f)


def extract_schema_component(full_schema: dict, schema_name: str) -> dict:
    """
    Extract a specific schema component from OpenAPI schema
    
    Args:
        full_schema: Full OpenAPI schema
        schema_name: Name of schema component (e.g., "ChatRequest")
        
    Returns:
        dict: Extracted schema component
    """
    # Handle OpenAPI 3.x format
    if 'components' in full_schema and 'schemas' in full_schema['components']:
        schemas = full_schema['components']['schemas']
        if schema_name in schemas:
            return schemas[schema_name]
    
    # Handle direct schema format
    if 'properties' in full_schema or 'type' in full_schema:
        return full_schema
    
    raise ValueError(f"Schema component '{schema_name}' not found in schema")


def validate_json_data(data: dict, schema: dict, verbose: bool = False) -> tuple[bool, list]:
    """
    Validate JSON data against schema
    
    Args:
        data: JSON data to validate
        schema: JSON schema
        verbose: Print detailed validation info
        
    Returns:
        tuple: (is_valid, errors)
    """
    validator = Draft7Validator(schema)
    errors = []
    
    for error in validator.iter_errors(data):
        error_info = {
            'path': '/'.join(str(p) for p in error.path),
            'message': error.message,
            'validator': error.validator,
            'validator_value': error.validator_value
        }
        errors.append(error_info)
        
        if verbose:
            print(f"❌ Validation error at '{error_info['path']}':", file=sys.stderr)
            print(f"   {error_info['message']}", file=sys.stderr)
    
    is_valid = len(errors) == 0
    
    if verbose:
        if is_valid:
            print("✅ Validation passed", file=sys.stderr)
        else:
            print(f"❌ Validation failed with {len(errors)} error(s)", file=sys.stderr)
    
    return is_valid, errors


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='Validate JSON data against JSON Schema'
    )
    parser.add_argument(
        '--schema',
        required=True,
        help='Path to schema file (OpenAPI or JSON Schema)'
    )
    parser.add_argument(
        '--type',
        help='Schema component name for OpenAPI schemas (e.g., ChatRequest)'
    )
    parser.add_argument(
        '--json',
        help='JSON string to validate (or read from stdin if omitted)'
    )
    parser.add_argument(
        '--file',
        help='JSON file to validate'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Print detailed validation information'
    )
    
    args = parser.parse_args()
    
    try:
        # Load schema
        if args.verbose:
            print(f"📄 Loading schema from {args.schema}...", file=sys.stderr)
        
        full_schema = load_schema(args.schema)
        
        # Extract schema component if specified
        if args.type:
            if args.verbose:
                print(f"🔍 Extracting schema component: {args.type}", file=sys.stderr)
            schema = extract_schema_component(full_schema, args.type)
        else:
            schema = full_schema
        
        # Load data to validate
        if args.file:
            if args.verbose:
                print(f"📄 Loading data from {args.file}...", file=sys.stderr)
            with open(args.file, 'r') as f:
                data = json.load(f)
        elif args.json:
            data = json.loads(args.json)
        else:
            # Read from stdin
            if args.verbose:
                print("📄 Reading data from stdin...", file=sys.stderr)
            data = json.load(sys.stdin)
        
        # Validate
        if args.verbose:
            print("🔍 Validating...", file=sys.stderr)
        
        is_valid, errors = validate_json_data(data, schema, verbose=args.verbose)
        
        # Output results
        result = {
            'valid': is_valid,
            'error_count': len(errors),
            'errors': errors
        }
        
        print(json.dumps(result, indent=2))
        
        # Exit codes: 0=valid, 1=invalid, 2=error
        sys.exit(0 if is_valid else 1)
    
    except FileNotFoundError as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(2)
    except json.JSONDecodeError as e:
        print(f"❌ JSON parsing error: {e}", file=sys.stderr)
        sys.exit(2)
    except Exception as e:
        print(f"❌ Unexpected error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

