"""
Token management for Qwen API authentication.

Handles:
- Compression of credentials into Bearer tokens
- Token validation
- Token caching and refresh
"""

import gzip
import base64
import json
import httpx
from typing import Dict, Optional, Tuple
from pathlib import Path
from datetime import datetime, timedelta
from loguru import logger


class QwenTokenManager:
    """Manages Qwen authentication tokens"""
    
    VALIDATION_ENDPOINT = "https://qwen.aikit.club/validate"
    TOKEN_CACHE_FILE = ".sessions/qwen_token_cache.json"
    
    def __init__(self):
        self.cache_dir = Path(".sessions")
        self.cache_dir.mkdir(exist_ok=True)
        self.cache_file = self.cache_dir / "qwen_token_cache.json"
    
    def compress_credentials(
        self, 
        local_storage: Dict[str, str], 
        cookies: list
    ) -> str:
        """
        Compress localStorage and cookies into a Bearer token
        
        Format: gzip(json({localStorage: {...}, cookies: [...]})) -> base64
        
        Args:
            local_storage: Dict of localStorage key-value pairs
            cookies: List of cookie objects
            
        Returns:
            Base64-encoded compressed token
        """
        logger.info("🔒 Compressing credentials into token...")
        
        # Combine credentials
        credentials = {
            "localStorage": local_storage,
            "cookies": cookies
        }
        
        # Serialize to JSON
        json_str = json.dumps(credentials, separators=(',', ':'))
        json_bytes = json_str.encode('utf-8')
        
        # Compress with gzip
        compressed = gzip.compress(json_bytes, compresslevel=9)
        
        # Encode to base64
        token = base64.b64encode(compressed).decode('ascii')
        
        logger.debug(f"📦 Original size: {len(json_bytes)} bytes")
        logger.debug(f"📦 Compressed size: {len(compressed)} bytes")
        logger.debug(f"📦 Token size: {len(token)} chars")
        logger.debug(f"📦 Compression ratio: {len(compressed)/len(json_bytes)*100:.1f}%")
        
        return token
    
    def decompress_token(self, token: str) -> Dict:
        """
        Decompress a Bearer token back to credentials
        
        Args:
            token: Base64-encoded compressed token
            
        Returns:
            Dict with localStorage and cookies
        """
        logger.debug("🔓 Decompressing token...")
        
        try:
            # Decode from base64
            compressed = base64.b64decode(token)
            
            # Decompress
            json_bytes = gzip.decompress(compressed)
            
            # Parse JSON
            credentials = json.loads(json_bytes.decode('utf-8'))
            
            logger.debug(f"✅ Token decompressed successfully")
            return credentials
            
        except Exception as e:
            logger.error(f"❌ Failed to decompress token: {e}")
            raise ValueError(f"Invalid token format: {e}")
    
    async def validate_token(self, token: str) -> Tuple[bool, Optional[str]]:
        """
        Validate token with Qwen API
        
        Args:
            token: Bearer token to validate
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        logger.info("🔍 Validating token with Qwen API...")
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Try POST method
                response = await client.post(
                    self.VALIDATION_ENDPOINT,
                    json={"token": token},
                    headers={"Content-Type": "application/json"}
                )
                
                if response.status_code == 200:
                    result = response.json()
                    logger.debug(f"Validation response: {result}")
                    
                    # Check if token is valid
                    if result.get('valid') or result.get('success'):
                        logger.success("✅ Token is valid!")
                        return True, None
                    else:
                        error_msg = result.get('error') or result.get('message') or "Token is invalid"
                        logger.warning(f"⚠️ Token validation failed: {error_msg}")
                        return False, error_msg
                
                # Try GET method as fallback
                response = await client.get(
                    f"{self.VALIDATION_ENDPOINT}?token={token}"
                )
                
                if response.status_code == 200:
                    result = response.json()
                    logger.debug(f"Validation response (GET): {result}")
                    
                    if result.get('valid') or result.get('success'):
                        logger.success("✅ Token is valid!")
                        return True, None
                    else:
                        error_msg = result.get('error') or result.get('message') or "Token is invalid"
                        logger.warning(f"⚠️ Token validation failed: {error_msg}")
                        return False, error_msg
                
                logger.error(f"❌ Validation endpoint returned {response.status_code}")
                return False, f"Validation failed with status {response.status_code}"
                
        except httpx.TimeoutException:
            logger.error("❌ Token validation timed out")
            return False, "Validation timeout"
        except Exception as e:
            logger.error(f"❌ Token validation failed: {e}")
            return False, str(e)
    
    def save_token(
        self, 
        token: str, 
        metadata: Optional[Dict] = None
    ):
        """
        Save token to cache with metadata
        
        Args:
            token: Bearer token
            metadata: Optional metadata (expiration, user info, etc.)
        """
        cache_data = {
            "token": token,
            "created_at": datetime.now().isoformat(),
            "metadata": metadata or {}
        }
        
        with open(self.cache_file, 'w') as f:
            json.dump(cache_data, f, indent=2)
        
        logger.success(f"💾 Token cached to: {self.cache_file}")
    
    def load_cached_token(self) -> Optional[str]:
        """
        Load token from cache
        
        Returns:
            Token string or None if not found/expired
        """
        if not self.cache_file.exists():
            logger.debug("No cached token found")
            return None
        
        try:
            with open(self.cache_file, 'r') as f:
                cache_data = json.load(f)
            
            token = cache_data.get('token')
            created_at = datetime.fromisoformat(cache_data.get('created_at'))
            
            # Check if token is too old (>7 days)
            age = datetime.now() - created_at
            if age > timedelta(days=7):
                logger.warning(f"⚠️ Cached token is {age.days} days old, may be expired")
            
            logger.info(f"📂 Loaded cached token (age: {age.days}d {age.seconds//3600}h)")
            return token
            
        except Exception as e:
            logger.error(f"❌ Failed to load cached token: {e}")
            return None
    
    def clear_cache(self):
        """Clear cached token"""
        if self.cache_file.exists():
            self.cache_file.unlink()
            logger.info("🗑️ Token cache cleared")


async def get_or_create_token(
    email: Optional[str] = None,
    password: Optional[str] = None,
    force_new: bool = False
) -> str:
    """
    Get a valid token, creating new one if needed
    
    Args:
        email: User email (required for new token)
        password: User password (required for new token)
        force_new: Force creation of new token
        
    Returns:
        Valid Bearer token
    """
    from app.auth.browser_auth import authenticate_with_browser
    
    manager = QwenTokenManager()
    
    # Try to load cached token first
    if not force_new:
        cached_token = manager.load_cached_token()
        if cached_token:
            # Validate cached token
            is_valid, error = await manager.validate_token(cached_token)
            if is_valid:
                logger.success("✅ Using valid cached token")
                return cached_token
            else:
                logger.warning(f"⚠️ Cached token invalid: {error}")
    
    # Need to create new token
    if not email or not password:
        raise ValueError(
            "Email and password required to create new token. "
            "Set QWEN_EMAIL and QWEN_PASSWORD environment variables."
        )
    
    logger.info("🔄 Creating new token via browser authentication...")
    
    # Authenticate via browser
    local_storage, cookies = await authenticate_with_browser(
        email=email,
        password=password,
        headless=True,
        force_new=True
    )
    
    # Compress into token
    token = manager.compress_credentials(local_storage, cookies)
    
    # Validate new token
    is_valid, error = await manager.validate_token(token)
    if not is_valid:
        raise Exception(f"Newly created token is invalid: {error}")
    
    # Cache for future use
    manager.save_token(token, metadata={
        "email": email,
        "method": "browser_auth"
    })
    
    logger.success("✅ New token created and validated!")
    return token


if __name__ == "__main__":
    # Test token management
    import sys
    import asyncio
    
    async def test():
        if len(sys.argv) < 2:
            print("Usage: python token_manager.py <command> [args]")
            print("\nCommands:")
            print("  create <email> <password>  - Create new token")
            print("  validate <token>           - Validate a token")
            print("  decompress <token>         - Decompress and show token contents")
            sys.exit(1)
        
        command = sys.argv[1]
        manager = QwenTokenManager()
        
        if command == "create":
            if len(sys.argv) < 4:
                print("Usage: python token_manager.py create <email> <password>")
                sys.exit(1)
            
            email = sys.argv[2]
            password = sys.argv[3]
            
            token = await get_or_create_token(email=email, password=password, force_new=True)
            print(f"\n✅ Token created successfully!")
            print(f"📝 Token: {token[:50]}...")
            print(f"📏 Length: {len(token)} characters")
            
        elif command == "validate":
            if len(sys.argv) < 3:
                print("Usage: python token_manager.py validate <token>")
                sys.exit(1)
            
            token = sys.argv[2]
            is_valid, error = await manager.validate_token(token)
            
            if is_valid:
                print("\n✅ Token is VALID")
            else:
                print(f"\n❌ Token is INVALID: {error}")
        
        elif command == "decompress":
            if len(sys.argv) < 3:
                print("Usage: python token_manager.py decompress <token>")
                sys.exit(1)
            
            token = sys.argv[2]
            try:
                credentials = manager.decompress_token(token)
                print("\n✅ Token decompressed successfully!")
                print(f"\n📋 LocalStorage keys: {list(credentials['localStorage'].keys())}")
                print(f"🍪 Cookies: {len(credentials['cookies'])}")
                
                # Print cookie names
                cookie_names = [c['name'] for c in credentials['cookies']]
                print(f"🍪 Cookie names: {cookie_names}")
            except Exception as e:
                print(f"\n❌ Failed to decompress: {e}")
        
        else:
            print(f"Unknown command: {command}")
            sys.exit(1)
    
    asyncio.run(test())

