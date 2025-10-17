#!/usr/bin/env python3
"""
Real Qwen Token Extractor - Works with current chat.qwen.ai UI
"""

import asyncio
import json
import os
import sys
from typing import Optional

from playwright.async_api import async_playwright


async def extract_qwen_token(email: str, password: str) -> Optional[str]:
    """
    Extract JWT token from Qwen's chat interface
    
    Args:
        email: User email
        password: User password
        
    Returns:
        JWT token or None
    """
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        page = await context.new_page()
        
        try:
            print("🌐 Navigating to chat.qwen.ai...", file=sys.stderr)
            await page.goto("https://chat.qwen.ai", timeout=30000)
            
            # Click "Log in" button
            print("🔑 Clicking login button...", file=sys.stderr)
            await page.click('button:has-text("Log in")', timeout=10000)
            
            # Wait for login modal/page
            await asyncio.sleep(2)
            
            # Look for email/username input
            print("📧 Entering email...", file=sys.stderr)
            email_selectors = [
                'input[type="email"]',
                'input[type="text"]',
                'input[placeholder*="email" i]',
                'input[placeholder*="Email" i]',
                'input[name="email"]',
                'input[name="username"]',
            ]
            
            email_input = None
            for selector in email_selectors:
                try:
                    email_input = await page.query_selector(selector)
                    if email_input:
                        await page.fill(selector, email)
                        print(f"  ✅ Found email input: {selector}", file=sys.stderr)
                        break
                except Exception:
                    continue
            
            if not email_input:
                print("  ❌ Could not find email input", file=sys.stderr)
                await page.screenshot(path="/tmp/qwen_login_error.png")
                print("  📸 Screenshot saved to /tmp/qwen_login_error.png", file=sys.stderr)
                return None
            
            await asyncio.sleep(0.5)
            
            # Fill password
            print("🔒 Entering password...", file=sys.stderr)
            await page.fill('input[type="password"]', password)
            await asyncio.sleep(0.5)
            
            # Click submit button
            print("🚀 Clicking submit...", file=sys.stderr)
            submit_selectors = [
                'button[type="submit"]',
                'button:has-text("Log in")',
                'button:has-text("Sign in")',
                'button:has-text("Submit")',
                'button:has-text("Continue")',
            ]
            
            for selector in submit_selectors:
                try:
                    await page.click(selector, timeout=2000)
                    print(f"  ✅ Clicked: {selector}", file=sys.stderr)
                    break
                except Exception:
                    continue
            
            # Wait for login to complete
            print("⏳ Waiting for login...", file=sys.stderr)
            await asyncio.sleep(5)
            
            # Try to extract token from various storage mechanisms
            print("🔍 Extracting token...", file=sys.stderr)
            
            # Method 1: localStorage
            token = await page.evaluate("""
                () => {
                    // Try common token storage keys
                    const keys = ['token', 'authToken', 'auth_token', 'accessToken', 'access_token', 'jwt', 'JWT'];
                    for (const key of keys) {
                        const val = localStorage.getItem(key);
                        if (val && val.length > 50) {
                            return val;
                        }
                    }
                    
                    // Try to find in all localStorage
                    for (let i = 0; i < localStorage.length; i++) {
                        const key = localStorage.key(i);
                        const val = localStorage.getItem(key);
                        if (val && val.length > 100 && val.includes('.')) {
                            // Looks like a JWT
                            return val;
                        }
                    }
                    
                    return null;
                }
            """)
            
            if token:
                print(f"✅ Token extracted from localStorage ({len(token)} chars)", file=sys.stderr)
                await browser.close()
                return token
            
            # Method 2: Check cookies
            cookies = await context.cookies()
            for cookie in cookies:
                if 'token' in cookie['name'].lower() and len(cookie['value']) > 50:
                    token = cookie['value']
                    print(f"✅ Token extracted from cookie: {cookie['name']} ({len(token)} chars)", file=sys.stderr)
                    await browser.close()
                    return token
            
            # Method 3: Check sessionStorage
            token = await page.evaluate("""
                () => {
                    for (let i = 0; i < sessionStorage.length; i++) {
                        const key = sessionStorage.key(i);
                        const val = sessionStorage.getItem(key);
                        if (val && val.length > 100 && val.includes('.')) {
                            return val;
                        }
                    }
                    return null;
                }
            """)
            
            if token:
                print(f"✅ Token extracted from sessionStorage ({len(token)} chars)", file=sys.stderr)
                await browser.close()
                return token
            
            print("❌ Could not find token in storage", file=sys.stderr)
            await page.screenshot(path="/tmp/qwen_after_login.png")
            print("  📸 Screenshot saved to /tmp/qwen_after_login.png", file=sys.stderr)
            
            # Debug: print all localStorage keys
            all_keys = await page.evaluate("() => Object.keys(localStorage)")
            print(f"  🔍 LocalStorage keys: {all_keys}", file=sys.stderr)
            
            await browser.close()
            return None
            
        except Exception as e:
            print(f"❌ Error: {e}", file=sys.stderr)
            await browser.close()
            return None


async def main():
    """Main entry point"""
    email = os.getenv("QWEN_EMAIL")
    password = os.getenv("QWEN_PASSWORD")
    
    if not email or not password:
        print("❌ QWEN_EMAIL and QWEN_PASSWORD must be set", file=sys.stderr)
        sys.exit(1)
    
    token = await extract_qwen_token(email, password)
    
    if token:
        # Output token to stdout (for bash capture)
        print(token)
        sys.exit(0)
    else:
        print("❌ Failed to extract token", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())

