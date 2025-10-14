#!/usr/bin/env python3
"""
Test Playwright authentication and Bearer token extraction
"""

import asyncio
import os
import sys
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent))

from app.auth.provider_auth import QwenAuth
from app.utils.logger import get_logger

logger = get_logger()


async def main():
    """Test authentication and token extraction"""
    
    # Get credentials from environment
    email = os.getenv("QWEN_EMAIL")
    password = os.getenv("QWEN_PASSWORD")
    
    if not email or not password:
        logger.error("❌ QWEN_EMAIL and QWEN_PASSWORD must be set")
        return False
    
    logger.info(f"🔐 Testing authentication for: {email}")
    
    # Create auth instance
    auth = QwenAuth({
        "name": "qwen",
        "baseUrl": "https://chat.qwen.ai",
        "loginUrl": "https://chat.qwen.ai/login",
        "email": email,
        "password": password
    })
    
    # Attempt login
    try:
        session = await auth.get_valid_session(force_refresh=True)
        
        if session and session.get("token"):
            bearer_token = session["token"]
            logger.info(f"✅ Bearer token extracted successfully!")
            logger.info(f"📏 Token length: {len(bearer_token)} characters")
            logger.info(f"🔑 Token preview: {bearer_token[:30]}...{bearer_token[-30:]}")
            
            # Save to file for use
            token_file = Path(".qwen_bearer_token")
            token_file.write_text(bearer_token)
            logger.info(f"💾 Token saved to: {token_file.absolute()}")
            
            # Print for easy copy-paste
            print("\n" + "="*80)
            print("QWEN_BEARER_TOKEN extracted successfully!")
            print("="*80)
            print(f"\nAdd this to your .env file:\n")
            print(f"QWEN_BEARER_TOKEN={bearer_token}")
            print("\n" + "="*80 + "\n")
            
            return True
        else:
            logger.error("❌ Failed to extract Bearer token")
            return False
            
    except Exception as e:
        logger.error(f"❌ Authentication failed: {e}", exc_info=True)
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)

