#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Provider Authentication Manager
Handles automatic login and session management for all providers

Enhanced to support both manual Bearer tokens and automated Playwright login
"""

import asyncio
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional

from app.auth.session_store import SessionStore
from app.utils.logger import get_logger

logger = get_logger()


class ProviderAuth(ABC):
    """Base class for provider authentication"""

    def __init__(self, config: Dict[str, str]):
        """
        Initialize provider authentication

        Args:
            config: Provider configuration (name, baseUrl, loginUrl, email, password)
        """
        self.config = config
        self.name = config["name"]
        self.base_url = config["baseUrl"]
        self.login_url = config["loginUrl"]
        self.email = config["email"]
        self.password = config["password"]

        # Session store
        self.session_store = SessionStore(self.name)

        # Cached session data
        self._cached_cookies: Optional[Dict[str, str]] = None
        self._cached_token: Optional[str] = None

    @abstractmethod
    async def login(self) -> Dict[str, Any]:
        """
        Perform login and extract authentication data

        Returns:
            Dict containing cookies, token, and any extra data
        """
        pass

    async def get_valid_session(self, force_refresh: bool = False) -> Optional[Dict[str, Any]]:
        """
        Get valid session data, auto-login if needed

        Args:
            force_refresh: Force new login even if session exists

        Returns:
            Dict with cookies and token
        """
        # Check cached data first
        if not force_refresh and self._cached_cookies:
            return {
                "cookies": self._cached_cookies,
                "token": self._cached_token
            }

        # Try to load from storage
        if not force_refresh and self.session_store.is_valid(max_age=43200):  # 12 hours
            session = self.session_store.load_session()
            if session:
                self._cached_cookies = session.get("cookies")
                self._cached_token = session.get("token")
                logger.info(f"✅ Using cached {self.name} session")
                return {
                    "cookies": self._cached_cookies,
                    "token": self._cached_token
                }

        # Need to login
        logger.info(f"🔐 Logging in to {self.name}...")
        try:
            auth_data = await self.login()

            # Cache the data
            self._cached_cookies = auth_data.get("cookies", {})
            self._cached_token = auth_data.get("token")

            # Save to storage
            self.session_store.save_session(
                self._cached_cookies,
                self._cached_token,
                auth_data.get("extra")
            )

            logger.info(f"✅ {self.name} login successful")
            return {
                "cookies": self._cached_cookies,
                "token": self._cached_token
            }

        except Exception as e:
            logger.error(f"❌ {self.name} login failed: {e}")
            return None

    async def get_cookies(self, force_refresh: bool = False) -> Optional[Dict[str, str]]:
        """Get authentication cookies"""
        session = await self.get_valid_session(force_refresh)
        return session.get("cookies") if session else None

    async def get_token(self, force_refresh: bool = False) -> Optional[str]:
        """Get authentication token"""
        session = await self.get_valid_session(force_refresh)
        return session.get("token") if session else None

    def clear_session(self):
        """Clear cached session"""
        self._cached_cookies = None
        self._cached_token = None
        self.session_store.clear_session()


class QwenAuth(ProviderAuth):
    """
    Qwen provider authentication with dual-mode support:
    
    Mode 1 (Primary): Manual compressed token
      - User provides QWEN_BEARER_TOKEN environment variable
      - Token extracted via JS snippet from https://chat.qwen.ai
      - Fastest and most reliable
      
    Mode 2 (Fallback): Automatic Playwright login
      - Uses email/password credentials
      - Automatically extracts and compresses token
      - Caches compressed token for reuse
    """
    
    def __init__(self, config: Dict[str, str]):
        """
        Initialize Qwen authentication
        
        Config can include:
        - bearer_token: Pre-compressed Bearer token (QWEN_BEARER_TOKEN)
        - email, password: For Playwright automation fallback
        """
        super().__init__(config)
        # Check for pre-compressed token
        self.bearer_token = config.get("bearer_token") or config.get("token")
        
        # Log authentication mode
        if self.bearer_token:
            logger.info("🔑 Qwen: Bearer token provided (manual mode)")
        else:
            logger.info("🌐 Qwen: Will use Playwright automation (auto mode)")
    
    async def login(self) -> Dict[str, Any]:
        """
        Login to Qwen using either manual token or Playwright automation.
        
        Priority:
        1. Use QWEN_BEARER_TOKEN if provided (fastest)
        2. Check cached compressed token
        3. Fall back to Playwright login + compression
        
        Returns:
            Dict with cookies and Bearer token
        """
        from app.auth.token_compressor import validate_compressed_token
        
        # Mode 1: Use provided Bearer token
        if self.bearer_token:
            logger.info("🔑 Using provided QWEN_BEARER_TOKEN")
            
            # Validate token format
            if validate_compressed_token(self.bearer_token):
                logger.info("✅ Token validated successfully")
                return {
                    "cookies": {},  # Not needed when using Bearer token
                    "token": self.bearer_token,
                    "extra": {"method": "bearer_token"}
                }
            else:
                logger.warning("⚠️ Provided token appears invalid, falling back to login")
        
        # Mode 2: Playwright automation
        logger.info("🌐 Starting Playwright authentication")
        return await self._playwright_login()
    
    async def _playwright_login(self) -> Dict[str, Any]:
        """
        Login to Qwen using Playwright and create compressed Bearer token.
        
        Steps:
        1. Navigate to Qwen chat
        2. Fill in credentials
        3. Extract web_api_auth_token from localStorage
        4. Extract ssxmod_itna from cookies
        5. Compress credentials into Bearer token
        """
        from app.auth.token_compressor import compress_qwen_token
        from playwright.async_api import async_playwright

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context(
                user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36'
            )
            page = await context.new_page()

            try:
                logger.info(f"🌐 Qwen: Navigating to {self.base_url}")
                await page.goto(self.base_url, wait_until='networkidle', timeout=30000)

                # Click "Log in" button to go to login page
                try:
                    logger.debug("🔍 Qwen: Looking for 'Log in' button")
                    login_link = await page.wait_for_selector(
                        'button:has-text("Log in"), button:has-text("登录"), a:has-text("Log in"), a:has-text("登录")',
                        timeout=5000
                    )
                    await login_link.click()
                    logger.info("👆 Qwen: Clicked 'Log in' button")
                    await page.wait_for_load_state('networkidle', timeout=10000)
                except Exception as e:
                    logger.debug(f"Qwen: Could not find/click login button: {e}, assuming already on login page")

                # Wait for login form
                logger.debug("🔐 Qwen: Waiting for login form")
                await page.wait_for_selector('input[type="email"], input[type="text"], input[name="email"]', timeout=10000)

                # Fill in credentials
                logger.debug("✏️ Qwen: Filling credentials")
                email_input = await page.query_selector('input[type="email"], input[type="text"], input[name="email"]')
                await email_input.fill(self.email)

                password_input = await page.query_selector('input[type="password"], input[name="password"]')
                await password_input.fill(self.password)

                # Click login button
                logger.debug("👆 Qwen: Clicking login button")
                submit_button = await page.query_selector('button[type="submit"], button:has-text("登录"), button:has-text("Login")')
                await submit_button.click()

                # Wait for successful login
                logger.debug("⏳ Qwen: Waiting for login to complete")
                try:
                    await page.wait_for_url('**/chat**', timeout=20000)
                    logger.info("✅ Qwen: Login successful (URL changed)")
                except:
                    try:
                        await page.wait_for_load_state('networkidle', timeout=20000)
                        logger.info("✅ Qwen: Login successful (network idle)")
                    except:
                        logger.warning("⚠️ Qwen: Timeout waiting for login, checking token anyway")

                # Extract localStorage token with retries
                logger.debug("🔑 Qwen: Extracting localStorage token")
                web_api_token = None

                # Wait longer after login for token to be set
                await asyncio.sleep(3)
                
                for attempt in range(10):
                    web_api_token = await page.evaluate('''() => {
                        // Try the actual token name used by Qwen
                        return localStorage.getItem('token') 
                            || localStorage.getItem('web_api_auth_token')
                            || localStorage.getItem('access_token')
                            || localStorage.getItem('auth_token');
                    }''')
                    if web_api_token:
                        logger.info(f"✅ Qwen: Found web_api_token on attempt {attempt + 1}")
                        break
                    logger.debug(f"⏳ Qwen: Attempt {attempt + 1}/10 - waiting for token...")
                    await asyncio.sleep(2)

                # Extract cookies
                logger.debug("🍪 Qwen: Extracting cookies")
                cookies = await context.cookies()

                # Find ssxmod_itna cookie
                ssxmod_itna = None
                cookie_dict = {}
                for cookie in cookies:
                    cookie_dict[cookie['name']] = cookie['value']
                    if cookie['name'] == 'ssxmod_itna':
                        ssxmod_itna = cookie['value']

                logger.info(f"📊 Qwen: web_api_token={bool(web_api_token)}, ssxmod_itna={bool(ssxmod_itna)}, total_cookies={len(cookie_dict)}")

                # Create compressed Bearer token
                bearer_token = None
                if web_api_token and ssxmod_itna:
                    try:
                        logger.info("🗜️ Qwen: Compressing credentials into Bearer token")
                        bearer_token = compress_qwen_token(web_api_token, ssxmod_itna)
                        logger.info(f"✅ Qwen: Bearer token created ({len(bearer_token)} chars)")
                    except Exception as e:
                        logger.error(f"❌ Qwen: Failed to compress token: {e}", exc_info=True)
                else:
                    logger.warning("⚠️ Qwen: Missing credentials for Bearer token")
                    if not web_api_token:
                        logger.error("❌ Qwen: 'token' not found in localStorage (checked: token, web_api_auth_token, access_token, auth_token)")
                    if not ssxmod_itna:
                        logger.error("❌ Qwen: ssxmod_itna cookie not found")

                await browser.close()

                # Success if we have bearer token
                if not bearer_token:
                    raise Exception("Failed to create Bearer token - missing credentials")

                return {
                    "cookies": cookie_dict,
                    "token": bearer_token,
                    "extra": {
                        "method": "playwright",
                        "web_api_token_length": len(web_api_token) if web_api_token else 0,
                        "cookie_count": len(cookie_dict)
                    }
                }

            except Exception as e:
                logger.error(f"❌ Qwen: Playwright login failed: {e}", exc_info=True)
                try:
                    await browser.close()
                except:
                    pass
                raise


def create_provider_auth(provider_name: str, config: Dict[str, str]) -> ProviderAuth:
    """
    Factory function to create provider authentication instances
    
    Args:
        provider_name: Name of the provider ('qwen', etc.)
        config: Provider configuration
        
    Returns:
        ProviderAuth instance for the specified provider
    """
    provider_name = provider_name.lower()
    
    if provider_name == 'qwen':
        return QwenAuth(config)
    else:
        raise ValueError(f"Unknown provider: {provider_name}")


# Alias for backward compatibility
create_auth = create_provider_auth
