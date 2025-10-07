"""
Browser-based authentication for Qwen API using Playwright.

This module handles:
- Automated login to chat.qwen.ai
- Extraction of localStorage and cookies
- Session persistence for token reuse
"""

import asyncio
import json
import os
from typing import Dict, Any, Optional, Tuple
from pathlib import Path
from playwright.async_api import async_playwright, Browser, BrowserContext, Page
from loguru import logger


class QwenBrowserAuth:
    """Handles browser-based authentication to Qwen"""
    
    LOGIN_URL = "https://chat.qwen.ai/auth?action=signin"
    HOME_URL = "https://chat.qwen.ai"
    
    # Exact selectors from the website
    SELECTORS = {
        "email_input": "body > div:nth-child(1) > div.relative.h-full.max-h-\\[100dvh\\].w-full.text-white > div.flex-col.bg-transparent.fixed.min-h-screen.font-primary.z-50.flex.w-full.items-center.justify-center.text-black.dark\\:text-white > div.w-full.rounded-2xl.sm\\:max-w-md.pb-10.pt-16.shadow-qwen.dark\\:border.dark\\:border-white\\/\\[0\\.16\\] > div > div > form > div.mt-4.flex.flex-col.divide-y.divide-solid.divide-slate-50.rounded-xl.border.border-slate-200.dark\\:divide-\\[\\#ffffff29\\].dark\\:border-\\[\\#ffffff29\\].dark\\:bg-\\[\\#2a2a2a\\] > div:nth-child(1)",
        "password_input": "body > div:nth-child(1) > div.relative.h-full.max-h-\\[100dvh\\].w-full.text-white > div.flex-col.bg-transparent.fixed.min-h-screen.font-primary.z-50.flex.w-full.items-center.justify-center.text-black.dark\\:text-white > div.w-full.rounded-2xl.sm\\:max-w-md.pb-10.pt-16.shadow-qwen.dark\\:border.dark\\:border-white\\/\\[0\\.16\\] > div > div > form > div.mt-4.flex.flex-col.divide-y.divide-solid.divide-slate-50.rounded-xl.border.border-slate-200.dark\\:divide-\\[\\#ffffff29\\].dark\\:border-\\[\\#ffffff29\\].dark\\:bg-\\[\\#2a2a2a\\] > div:nth-child(2) > i",
        "login_button": "body > div:nth-child(1) > div.relative.h-full.max-h-\\[100dvh\\].w-full.text-white > div.flex-col.bg-transparent.fixed.min-h-screen.font-primary.z-50.flex.w-full.items-center.justify-center.text-black.dark\\:text-white > div.w-full.rounded-2xl.sm\\:max-w-md.pb-10.pt-16.shadow-qwen.dark\\:border.dark\\:border-white\\/\\[0\\.16\\] > div > div > form > div:nth-child(4) > button"
    }
    
    # Fallback XPath selectors
    XPATH_SELECTORS = {
        "email_input": "/html/body/div[1]/div[1]/div[3]/div[1]/div/div/form/div[2]/div[1]",
        "password_input": "/html/body/div[1]/div[1]/div[3]/div[1]/div/div/form/div[2]/div[2]",
        "login_button": "/html/body/div[1]/div[1]/div[3]/div[1]/div/div/form/div[4]/button"
    }
    
    def __init__(self, headless: bool = True, session_dir: str = ".sessions"):
        self.headless = headless
        self.session_dir = Path(session_dir)
        self.session_dir.mkdir(exist_ok=True)
        
        self.browser: Optional[Browser] = None
        self.context: Optional[BrowserContext] = None
        self.page: Optional[Page] = None
    
    async def __aenter__(self):
        """Context manager entry"""
        await self.launch_browser()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        await self.close()
    
    async def launch_browser(self):
        """Initialize Playwright browser"""
        logger.info("🚀 Launching browser for Qwen authentication...")
        
        playwright = await async_playwright().start()
        
        # Launch browser with appropriate settings
        self.browser = await playwright.chromium.launch(
            headless=self.headless,
            args=[
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-blink-features=AutomationControlled'
            ]
        )
        
        # Create context with realistic settings
        self.context = await self.browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        )
        
        self.page = await self.context.new_page()
        logger.success("✅ Browser launched successfully")
    
    async def login(self, email: str, password: str) -> bool:
        """
        Perform login to Qwen
        
        Args:
            email: User email
            password: User password
            
        Returns:
            True if login successful, False otherwise
        """
        try:
            logger.info(f"🔐 Logging in to Qwen with email: {email}")
            
            # Navigate to login page
            logger.debug(f"Navigating to {self.LOGIN_URL}")
            await self.page.goto(self.LOGIN_URL, wait_until='networkidle', timeout=30000)
            
            # Wait a bit for page to settle
            await asyncio.sleep(2)
            
            # Try to find and fill email input
            email_filled = False
            try:
                # Try CSS selector first
                await self.page.wait_for_selector(self.SELECTORS['email_input'], timeout=5000)
                await self.page.fill(self.SELECTORS['email_input'], email)
                email_filled = True
                logger.debug("✅ Email filled using CSS selector")
            except Exception as e:
                logger.warning(f"CSS selector failed for email: {e}")
                try:
                    # Try XPath as fallback
                    email_element = await self.page.wait_for_selector(
                        f"xpath={self.XPATH_SELECTORS['email_input']}", 
                        timeout=5000
                    )
                    await email_element.fill(email)
                    email_filled = True
                    logger.debug("✅ Email filled using XPath")
                except Exception as e2:
                    logger.error(f"❌ Failed to fill email: {e2}")
            
            if not email_filled:
                # Try finding input by type
                try:
                    await self.page.fill('input[type="email"]', email)
                    email_filled = True
                    logger.debug("✅ Email filled using type selector")
                except:
                    pass
            
            if not email_filled:
                logger.error("❌ Could not find email input field")
                return False
            
            await asyncio.sleep(1)
            
            # Try to find and fill password input
            password_filled = False
            try:
                # Try CSS selector first
                await self.page.wait_for_selector(self.SELECTORS['password_input'], timeout=5000)
                await self.page.fill(self.SELECTORS['password_input'], password)
                password_filled = True
                logger.debug("✅ Password filled using CSS selector")
            except Exception as e:
                logger.warning(f"CSS selector failed for password: {e}")
                try:
                    # Try XPath as fallback
                    password_element = await self.page.wait_for_selector(
                        f"xpath={self.XPATH_SELECTORS['password_input']}", 
                        timeout=5000
                    )
                    await password_element.fill(password)
                    password_filled = True
                    logger.debug("✅ Password filled using XPath")
                except Exception as e2:
                    logger.error(f"❌ Failed to fill password: {e2}")
            
            if not password_filled:
                # Try finding input by type
                try:
                    await self.page.fill('input[type="password"]', password)
                    password_filled = True
                    logger.debug("✅ Password filled using type selector")
                except:
                    pass
            
            if not password_filled:
                logger.error("❌ Could not find password input field")
                return False
            
            await asyncio.sleep(1)
            
            # Click login button
            login_clicked = False
            try:
                # Try CSS selector first
                await self.page.click(self.SELECTORS['login_button'])
                login_clicked = True
                logger.debug("✅ Login button clicked using CSS selector")
            except Exception as e:
                logger.warning(f"CSS selector failed for login button: {e}")
                try:
                    # Try XPath as fallback
                    await self.page.click(f"xpath={self.XPATH_SELECTORS['login_button']}")
                    login_clicked = True
                    logger.debug("✅ Login button clicked using XPath")
                except Exception as e2:
                    logger.error(f"❌ Failed to click login button: {e2}")
            
            if not login_clicked:
                # Try finding button by text
                try:
                    await self.page.click('button:has-text("Log in")')
                    login_clicked = True
                    logger.debug("✅ Login button clicked using text selector")
                except:
                    pass
            
            if not login_clicked:
                logger.error("❌ Could not find login button")
                return False
            
            # Wait for navigation after login
            logger.info("⏳ Waiting for login to complete...")
            await asyncio.sleep(5)
            
            # Check if we're logged in by verifying URL or checking for user elements
            current_url = self.page.url
            logger.debug(f"Current URL after login: {current_url}")
            
            # If we're still on the login page, login failed
            if "auth?action=signin" in current_url:
                logger.error("❌ Login failed - still on login page")
                
                # Try to capture error message
                try:
                    error_msg = await self.page.text_content('.error, .alert, [role="alert"]')
                    if error_msg:
                        logger.error(f"Error message: {error_msg}")
                except:
                    pass
                
                return False
            
            # Navigate to home to ensure we're fully authenticated
            await self.page.goto(self.HOME_URL, wait_until='networkidle', timeout=30000)
            await asyncio.sleep(3)
            
            logger.success("✅ Login successful!")
            return True
            
        except Exception as e:
            logger.error(f"❌ Login failed with exception: {e}")
            logger.exception(e)
            return False
    
    async def extract_credentials(self) -> Tuple[Dict[str, str], list]:
        """
        Extract localStorage and cookies from authenticated session
        
        Returns:
            Tuple of (localStorage_dict, cookies_list)
        """
        logger.info("📦 Extracting credentials from browser session...")
        
        try:
            # Extract localStorage
            local_storage = await self.page.evaluate("""
                () => {
                    const storage = {};
                    for (let i = 0; i < localStorage.length; i++) {
                        const key = localStorage.key(i);
                        storage[key] = localStorage.getItem(key);
                    }
                    return storage;
                }
            """)
            
            logger.debug(f"📋 Extracted {len(local_storage)} localStorage items")
            
            # Extract cookies
            cookies = await self.context.cookies()
            logger.debug(f"🍪 Extracted {len(cookies)} cookies")
            
            # Log extracted keys (not values for security)
            logger.debug(f"LocalStorage keys: {list(local_storage.keys())}")
            logger.debug(f"Cookie names: {[c['name'] for c in cookies]}")
            
            return local_storage, cookies
            
        except Exception as e:
            logger.error(f"❌ Failed to extract credentials: {e}")
            raise
    
    async def save_session(self, local_storage: Dict[str, str], cookies: list) -> str:
        """
        Save session to file for later reuse
        
        Args:
            local_storage: localStorage data
            cookies: Cookie data
            
        Returns:
            Path to saved session file
        """
        session_file = self.session_dir / "qwen_browser_session.json"
        
        session_data = {
            "localStorage": local_storage,
            "cookies": cookies,
            "timestamp": asyncio.get_event_loop().time()
        }
        
        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2)
        
        logger.success(f"💾 Session saved to: {session_file}")
        return str(session_file)
    
    async def load_session(self) -> Optional[Tuple[Dict[str, str], list]]:
        """
        Load previously saved session
        
        Returns:
            Tuple of (localStorage, cookies) or None if not found
        """
        session_file = self.session_dir / "qwen_browser_session.json"
        
        if not session_file.exists():
            logger.warning("⚠️ No saved session found")
            return None
        
        try:
            with open(session_file, 'r') as f:
                session_data = json.load(f)
            
            logger.info(f"📂 Loaded session from: {session_file}")
            return session_data['localStorage'], session_data['cookies']
            
        except Exception as e:
            logger.error(f"❌ Failed to load session: {e}")
            return None
    
    async def restore_session(self, local_storage: Dict[str, str], cookies: list):
        """
        Restore a previously saved session to browser
        
        Args:
            local_storage: localStorage data to restore
            cookies: Cookies to restore
        """
        logger.info("🔄 Restoring session to browser...")
        
        # Navigate to home page first
        await self.page.goto(self.HOME_URL, wait_until='domcontentloaded')
        
        # Restore localStorage
        await self.page.evaluate(f"""
            (storage) => {{
                for (const [key, value] of Object.entries(storage)) {{
                    localStorage.setItem(key, value);
                }}
            }}
        """, local_storage)
        
        # Restore cookies
        await self.context.add_cookies(cookies)
        
        # Reload page to apply session
        await self.page.reload(wait_until='networkidle')
        await asyncio.sleep(2)
        
        logger.success("✅ Session restored")
    
    async def close(self):
        """Close browser and cleanup"""
        if self.browser:
            await self.browser.close()
            logger.debug("Browser closed")


async def authenticate_with_browser(
    email: str,
    password: str,
    headless: bool = True,
    force_new: bool = False
) -> Tuple[Dict[str, str], list]:
    """
    High-level function to authenticate and extract credentials
    
    Args:
        email: User email
        password: User password
        headless: Run browser in headless mode
        force_new: Force new login even if session exists
        
    Returns:
        Tuple of (localStorage, cookies)
    """
    async with QwenBrowserAuth(headless=headless) as auth:
        # Try to load existing session first
        if not force_new:
            session = await auth.load_session()
            if session:
                logger.info("✅ Using cached session")
                return session
        
        # Perform new login
        success = await auth.login(email, password)
        if not success:
            raise Exception("Login failed")
        
        # Extract credentials
        local_storage, cookies = await auth.extract_credentials()
        
        # Save for future use
        await auth.save_session(local_storage, cookies)
        
        return local_storage, cookies


if __name__ == "__main__":
    # Test authentication
    import sys
    
    if len(sys.argv) < 3:
        print("Usage: python browser_auth.py <email> <password>")
        sys.exit(1)
    
    email = sys.argv[1]
    password = sys.argv[2]
    
    async def test():
        local_storage, cookies = await authenticate_with_browser(
            email=email,
            password=password,
            headless=False  # Show browser for testing
        )
        print(f"\n✅ Authentication successful!")
        print(f"📋 LocalStorage items: {len(local_storage)}")
        print(f"🍪 Cookies: {len(cookies)}")
    
    asyncio.run(test())

