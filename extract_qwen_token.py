#!/usr/bin/env python3
"""
Standalone Qwen Token Extractor using Playwright
Logs into chat.qwen.ai and extracts the JWT token from localStorage
"""

import asyncio
import os
import sys
from typing import Optional

from playwright.async_api import async_playwright


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
                print("🚀 Launching browser...")
                browser = await p.chromium.launch(headless=True)
                page = await browser.new_page()
                
                print("🌐 Navigating to chat.qwen.ai...")
                await page.goto("https://chat.qwen.ai", wait_until="networkidle", timeout=30000)
                
                # Check if already logged in
                print("🔍 Checking for existing token...")
                token = await self._check_existing_token(page)
                if token:
                    print("✅ Found existing token!")
                    await browser.close()
                    return token
                
                # Perform login
                print("🔐 Logging in...")
                success = await self._perform_login(page)
                
                if not success:
                    print("❌ Login failed")
                    await browser.close()
                    return None
                
                # Extract token from localStorage
                print("🔑 Extracting token...")
                token = await self._extract_token_from_storage(page)
                
                await browser.close()
                
                if token:
                    print("✅ Token extracted successfully!")
                    self.token = token
                    return token
                else:
                    print("❌ Failed to extract token")
                    return None
                    
        except Exception as e:
            print(f"❌ Error during token extraction: {e}")
            return None
    
    async def _check_existing_token(self, page) -> Optional[str]:
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
    
    async def _perform_login(self, page) -> bool:
        """
        Perform login on chat.qwen.ai
        
        Returns:
            bool: True if login successful, False otherwise
        """
        try:
            # Wait for login button/form
            print("   Waiting for login form...")
            await page.wait_for_selector('input[type="email"], input[type="text"]', timeout=10000)
            
            # Fill in email
            print(f"   Entering email: {self.email}")
            await page.fill('input[type="email"], input[type="text"]', self.email)
            await asyncio.sleep(0.5)
            
            # Fill in password
            print("   Entering password...")
            await page.fill('input[type="password"]', self.password)
            await asyncio.sleep(0.5)
            
            # Click login button
            print("   Clicking login button...")
            await page.click('button[type="submit"]')
            
            # Wait for navigation/token to be set
            print("   Waiting for authentication...")
            await asyncio.sleep(5)
            
            return True
            
        except Exception as e:
            print(f"❌ Login error: {e}")
            return False
    
    async def _extract_token_from_storage(self, page) -> Optional[str]:
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
            print(f"❌ Token extraction error: {e}")
            return None


async def main():
    """Main function to extract and display token"""
    email = os.getenv("QWEN_EMAIL")
    password = os.getenv("QWEN_PASSWORD")
    
    if not email or not password:
        print("❌ Error: QWEN_EMAIL and QWEN_PASSWORD environment variables must be set")
        print("\nUsage:")
        print('  export QWEN_EMAIL="your-email@example.com"')
        print('  export QWEN_PASSWORD="your-password"')
        print("  python3 extract_qwen_token.py")
        sys.exit(1)
    
    print("=" * 60)
    print("🔐 Qwen Token Extractor")
    print("=" * 60)
    print(f"📧 Email: {email}")
    print("🔑 Password: {'*' * len(password)}")
    print("=" * 60)
    print()
    
    extractor = QwenTokenExtractor(email, password)
    token = await extractor.extract_token()
    
    print()
    print("=" * 60)
    if token:
        print("✅ SUCCESS!")
        print("=" * 60)
        print()
        print("🔑 Your Qwen JWT Token:")
        print(token)
        print()
        print("📝 To use this token:")
        print(f'  export QWEN_TOKEN="{token}"')
        print()
        print("  curl -X POST http://localhost:8096/v1/chat/completions \\")
        print('    -H "Content-Type: application/json" \\')
        print(f'    -H "Authorization: Bearer {token}" \\')
        print("    -d '{")
        print('      "model": "qwen-turbo",')
        print('      "messages": [{"role": "user", "content": "Hello!"}]')
        print("    }'")
        print()
    else:
        print("❌ FAILED!")
        print("=" * 60)
        print()
        print("Token extraction failed. Please check:")
        print("  - Your email and password are correct")
        print("  - You have access to chat.qwen.ai")
        print("  - Your network connection is stable")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())

