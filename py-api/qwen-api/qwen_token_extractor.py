#!/usr/bin/env python
"""
Qwen Token Extractor using Playwright
Logs into chat.qwen.ai and extracts the JWT token from localStorage
"""

import asyncio
import json
import os
from typing import Optional

from playwright.async_api import async_playwright, Page, Browser

from logger import get_logger

logger = get_logger()


class QwenTokenExtractor:
    """Extracts JWT token from Qwen's chat interface using Playwright"""
    
    def __init__(self, email: str, password: str):
        self.email = email
        self.password = password
        self.token: Optional[str] = None
        
    async def extract_token(self) -> Optional[str]:
        """
        Main method to extract token from chat.qwen.ai
        
        Returns:
            str: JWT token if successful, None otherwise
        """
        try:
            async with async_playwright() as p:
                # Launch browser in headless mode
                browser = await p.chromium.launch(headless=True)
                page = await browser.new_page()
                
                logger.info("🌐 Navigating to chat.qwen.ai...")
                await page.goto("https://chat.qwen.ai", wait_until="networkidle")
                
                # Check if already logged in
                token = await self._check_existing_token(page)
                if token:
                    logger.info("✅ Found existing token")
                    await browser.close()
                    return token
                
                # Perform login
                logger.info("🔐 Logging in...")
                success = await self._perform_login(page)
                
                if not success:
                    logger.error("❌ Login failed")
                    await browser.close()
                    return None
                
                # Extract token from localStorage
                logger.info("🔑 Extracting token...")
                token = await self._extract_token_from_storage(page)
                
                await browser.close()
                
                if token:
                    logger.info("✅ Token extracted successfully")
                    self.token = token
                    return token
                else:
                    logger.error("❌ Failed to extract token")
                    return None
                    
        except Exception as e:
            logger.error(f"❌ Error during token extraction: {e}")
            return None
    
    async def _check_existing_token(self, page: Page) -> Optional[str]:
        """Check if token already exists in localStorage"""
        try:
            token = await page.evaluate("""
                () => {
                    return localStorage.getItem('token');
                }
            """)
            return token if token else None
        except Exception:
            return None
    
    async def _perform_login(self, page: Page) -> bool:
        """
        Perform login on chat.qwen.ai
        
        Returns:
            bool: True if login successful, False otherwise
        """
        try:
            # Wait for login button/form
            await page.wait_for_selector('input[type="email"], input[type="text"]', timeout=10000)
            
            # Fill in email
            await page.fill('input[type="email"], input[type="text"]', self.email)
            await asyncio.sleep(0.5)
            
            # Fill in password
            await page.fill('input[type="password"]', self.password)
            await asyncio.sleep(0.5)
            
            # Click login button
            await page.click('button[type="submit"]')
            
            # Wait for navigation/token to be set
            await asyncio.sleep(3)
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Login error: {e}")
            return False
    
    async def _extract_token_from_storage(self, page: Page) -> Optional[str]:
        """
        Extract JWT token from localStorage using the same JS as the snippet
        
        Returns:
            str: JWT token if found, None otherwise
        """
        try:
            token = await page.evaluate("""
                () => {
                    const token = localStorage.getItem('token');
                    if (!token) {
                        return null;
                    }
                    return token;
                }
            """)
            
            return token if token else None
            
        except Exception as e:
            logger.error(f"❌ Token extraction error: {e}")
            return None


async def get_qwen_token(email: str = None, password: str = None) -> Optional[str]:
    """
    Convenience function to get Qwen token
    
    Args:
        email: Qwen account email (defaults to env var QWEN_EMAIL)
        password: Qwen account password (defaults to env var QWEN_PASSWORD)
        
    Returns:
        str: JWT token if successful, None otherwise
    """
    email = email or os.getenv("QWEN_EMAIL")
    password = password or os.getenv("QWEN_PASSWORD")
    
    if not email or not password:
        logger.error("❌ QWEN_EMAIL and QWEN_PASSWORD must be set")
        return None
    
    extractor = QwenTokenExtractor(email, password)
    return await extractor.extract_token()


if __name__ == "__main__":
    # Test the extractor
    async def main():
        token = await get_qwen_token()
        if token:
            print(f"✅ Token: {token[:50]}...")
        else:
            print("❌ Failed to get token")
    
    asyncio.run(main())
