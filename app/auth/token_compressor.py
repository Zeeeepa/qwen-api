#!/usr/bin/env python

"""
Token Compression Utility
Compresses Qwen credentials using gzip + base64 (matching browser JS implementation)
"""

import base64
import gzip
from typing import Optional

from app.utils.logger import get_logger

logger = get_logger()


def compress_qwen_token(web_api_token: str, ssxmod_itna: str) -> str:
    """
    Compress Qwen credentials into Bearer token format.
    
    Matches the browser JavaScript implementation from Qwen documentation:
    1. Combine: token|cookie
    2. Compress with gzip
    3. Base64 encode
    
    Args:
        web_api_token: Value from localStorage['web_api_auth_token']
        ssxmod_itna: Value from cookie 'ssxmod_itna'
        
    Returns:
        Compressed Bearer token string
        
    Example:
        >>> token = compress_qwen_token(
        ...     "eyJhbGc...",  # web_api_auth_token
        ...     "1234567..."   # ssxmod_itna cookie
        ... )
        >>> print(token[:20])
        H4sIAAAAAAAAA...
    """
    try:
        # Combine credentials with pipe separator
        combined = f"{web_api_token}|{ssxmod_itna}"
        logger.debug(f"🔧 Compressing token: {len(combined)} chars")
        
        # Compress with gzip
        compressed = gzip.compress(combined.encode('utf-8'))
        logger.debug(f"🗜️ Compressed size: {len(compressed)} bytes")
        
        # Base64 encode
        encoded = base64.b64encode(compressed).decode('utf-8')
        logger.debug(f"📦 Encoded size: {len(encoded)} chars")
        
        logger.info(f"✅ Token compressed: {len(combined)} → {len(encoded)} chars")
        return encoded
        
    except Exception as e:
        logger.error(f"❌ Token compression failed: {e}")
        raise


def decompress_qwen_token(compressed_token: str) -> tuple[Optional[str], Optional[str]]:
    """
    Decompress Bearer token back into credentials.
    
    Reverses the compression process:
    1. Base64 decode
    2. Gzip decompress
    3. Split on pipe
    
    Args:
        compressed_token: Compressed Bearer token
        
    Returns:
        Tuple of (web_api_token, ssxmod_itna) or (None, None) if invalid
        
    Example:
        >>> web_token, cookie = decompress_qwen_token("H4sIAAAAAAAAA...")
        >>> print(web_token[:10])
        eyJhbGc...
    """
    try:
        # Base64 decode
        decoded = base64.b64decode(compressed_token)
        logger.debug(f"📦 Decoded: {len(decoded)} bytes")
        
        # Gzip decompress
        decompressed = gzip.decompress(decoded).decode('utf-8')
        logger.debug(f"🗜️ Decompressed: {len(decompressed)} chars")
        
        # Split on pipe
        if '|' not in decompressed:
            logger.warning("⚠️ Invalid token format: missing pipe separator")
            return None, None
            
        parts = decompressed.split('|', 1)
        if len(parts) != 2:
            logger.warning("⚠️ Invalid token format: expected 2 parts")
            return None, None
            
        web_api_token, ssxmod_itna = parts
        logger.info(f"✅ Token decompressed successfully")
        return web_api_token, ssxmod_itna
        
    except base64.binascii.Error as e:
        logger.error(f"❌ Invalid base64: {e}")
        return None, None
    except gzip.BadGzipFile as e:
        logger.error(f"❌ Invalid gzip: {e}")
        return None, None
    except Exception as e:
        logger.error(f"❌ Decompression failed: {e}")
        return None, None


def validate_compressed_token(compressed_token: str) -> bool:
    """
    Validate a compressed token by attempting to decompress it.
    
    Args:
        compressed_token: Token to validate
        
    Returns:
        True if valid, False otherwise
    """
    web_token, cookie = decompress_qwen_token(compressed_token)
    return web_token is not None and cookie is not None


async def validate_token_with_api(compressed_token: str, base_url: str = "https://qwen.aikit.club") -> bool:
    """
    Validate token with the Qwen API proxy validation endpoint.
    
    Args:
        compressed_token: Token to validate
        base_url: API base URL (default: https://qwen.aikit.club)
        
    Returns:
        True if valid, False otherwise
    """
    import aiohttp
    
    try:
        url = f"{base_url}/validate"
        async with aiohttp.ClientSession() as session:
            async with session.post(
                url,
                json={"token": compressed_token},
                timeout=aiohttp.ClientTimeout(total=10)
            ) as response:
                if response.status == 200:
                    result = await response.json()
                    is_valid = result.get("valid", False)
                    logger.info(f"✅ Token validation: {is_valid}")
                    return is_valid
                else:
                    logger.warning(f"⚠️ Token validation failed: {response.status}")
                    return False
                    
    except Exception as e:
        logger.error(f"❌ Token validation error: {e}")
        return False

