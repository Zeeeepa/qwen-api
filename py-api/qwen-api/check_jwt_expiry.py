#!/usr/bin/env python3
"""
Check JWT token expiration
Returns exit code 0 if valid, 1 if expired, 2 if invalid format
"""

import sys
import json
import base64
from datetime import datetime, timezone


def decode_jwt_payload(token: str) -> dict:
    """
    Decode JWT payload without verification
    
    Args:
        token: JWT token string
        
    Returns:
        dict: Decoded payload
        
    Raises:
        ValueError: If token format is invalid
    """
    try:
        # JWT format: header.payload.signature
        parts = token.split('.')
        if len(parts) != 3:
            raise ValueError(f"Invalid JWT format: expected 3 parts, got {len(parts)}")
        
        # Decode payload (middle part)
        # Add padding if needed
        payload = parts[1]
        padding = 4 - (len(payload) % 4)
        if padding != 4:
            payload += '=' * padding
        
        decoded = base64.urlsafe_b64decode(payload)
        return json.loads(decoded)
    
    except Exception as e:
        raise ValueError(f"Failed to decode JWT: {e}")


def check_expiration(token: str, verbose: bool = False) -> tuple[bool, dict]:
    """
    Check if JWT token is expired
    
    Args:
        token: JWT token string
        verbose: Print detailed information
        
    Returns:
        tuple: (is_valid, info_dict)
    """
    try:
        payload = decode_jwt_payload(token)
        
        # Extract expiration claim
        if 'exp' not in payload:
            return False, {
                'error': 'No expiration claim (exp) found in token',
                'payload_keys': list(payload.keys())
            }
        
        exp_timestamp = payload['exp']
        exp_datetime = datetime.fromtimestamp(exp_timestamp, tz=timezone.utc)
        now = datetime.now(timezone.utc)
        
        is_valid = exp_datetime > now
        time_remaining = exp_datetime - now
        
        info = {
            'expiration': exp_datetime.isoformat(),
            'current_time': now.isoformat(),
            'is_valid': is_valid,
            'time_remaining_seconds': int(time_remaining.total_seconds()),
            'time_remaining_hours': time_remaining.total_seconds() / 3600,
            'time_remaining_days': time_remaining.total_seconds() / 86400,
        }
        
        if verbose:
            print(f"🕐 Token expiration: {exp_datetime.strftime('%Y-%m-%d %H:%M:%S UTC')}", file=sys.stderr)
            print(f"🕐 Current time:     {now.strftime('%Y-%m-%d %H:%M:%S UTC')}", file=sys.stderr)
            
            if is_valid:
                hours = info['time_remaining_hours']
                days = info['time_remaining_days']
                
                if days >= 1:
                    print(f"✅ Token valid for {days:.1f} more days", file=sys.stderr)
                elif hours >= 1:
                    print(f"✅ Token valid for {hours:.1f} more hours", file=sys.stderr)
                else:
                    print(f"⚠️  Token expires soon ({info['time_remaining_seconds']} seconds)", file=sys.stderr)
            else:
                print(f"❌ Token expired!", file=sys.stderr)
        
        return is_valid, info
    
    except ValueError as e:
        return False, {'error': str(e)}


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: python3 check_jwt_expiry.py <token> [--verbose]", file=sys.stderr)
        print("  Returns exit code 0 if valid, 1 if expired/invalid", file=sys.stderr)
        sys.exit(2)
    
    token = sys.argv[1]
    verbose = '--verbose' in sys.argv or '-v' in sys.argv
    
    is_valid, info = check_expiration(token, verbose=verbose)
    
    # Output JSON to stdout (for bash parsing)
    print(json.dumps(info, indent=2))
    
    # Exit codes: 0=valid, 1=expired/invalid, 2=error
    sys.exit(0 if is_valid else 1)


if __name__ == "__main__":
    main()

