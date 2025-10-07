#!/usr/bin/env python

"""
Enhanced HTTP Client with FlareProx Integration

Features:
- Automatic FlareProx proxy rotation
- Request correlation tracking
- Retry logic with exponential backoff
- Streaming response support
- Connection pooling
- Error handling and recovery
"""

import asyncio
from contextlib import asynccontextmanager
from typing import AsyncGenerator, Optional

import httpx

from app.utils.flareprox_manager import get_flareprox_manager
from app.utils.logger import get_logger
from app.utils.request_tracker import get_request_tracker

logger = get_logger()


class ProxiedHTTPClient:
    """
    HTTP client wrapper that automatically routes requests through FlareProx

    Features:
    - Automatic proxy URL transformation
    - Request correlation with unique IDs
    - Retry logic with different proxies on failure
    - Streaming support for SSE responses
    - Connection pooling for performance
    """

    def __init__(
        self,
        timeout: float = 30.0,
        max_retries: int = 3,
        retry_delay: float = 1.0,
        follow_redirects: bool = True,
        **httpx_kwargs
    ):
        """
        Initialize HTTP client

        Args:
            timeout: Request timeout in seconds
            max_retries: Maximum number of retry attempts
            retry_delay: Base delay between retries (exponential backoff)
            follow_redirects: Whether to follow HTTP redirects
            **httpx_kwargs: Additional arguments passed to httpx.AsyncClient
        """
        self.timeout = timeout
        self.max_retries = max_retries
        self.retry_delay = retry_delay

        # Get managers
        self.flareprox_manager = get_flareprox_manager()
        self.request_tracker = get_request_tracker()

        # HTTP client configuration
        self._client_config = {
            "timeout": httpx.Timeout(timeout),
            "follow_redirects": follow_redirects,
            "limits": httpx.Limits(
                max_keepalive_connections=50,
                max_connections=100,
                keepalive_expiry=30.0
            ),
            **httpx_kwargs
        }

        self._client: Optional[httpx.AsyncClient] = None

    async def __aenter__(self):
        """Async context manager entry"""
        self._client = httpx.AsyncClient(**self._client_config)
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        if self._client:
            await self._client.aclose()
            self._client = None

    def _get_proxied_url(self, url: str) -> tuple[str, Optional[str]]:
        """
        Get proxied URL through FlareProx

        Returns:
            Tuple of (proxied_url, proxy_url_used)
        """
        if self.flareprox_manager.enabled:
            proxy_url = self.flareprox_manager.get_proxy_url(url)
            return proxy_url, proxy_url
        return url, None

    async def _make_request_with_retry(
        self,
        method: str,
        url: str,
        **kwargs
    ) -> httpx.Response:
        """
        Make HTTP request with automatic retry and proxy rotation

        Args:
            method: HTTP method (GET, POST, etc.)
            url: Target URL
            **kwargs: Additional arguments for httpx request

        Returns:
            HTTP response

        Raises:
            httpx.HTTPError: If all retries fail
        """
        if not self._client:
            raise RuntimeError("HTTP client not initialized. Use async context manager.")

        last_error = None

        for attempt in range(self.max_retries):
            try:
                # Get proxied URL
                proxied_url, proxy_url = self._get_proxied_url(url)

                # Create request context for tracking
                async with self.request_tracker.track_request(
                    target_url=url,
                    proxy_url=proxy_url,
                    metadata={"method": method, "attempt": attempt + 1}
                ) as context:

                    logger.debug(
                        f"🌐 {method} {url} "
                        f"(attempt {attempt + 1}/{self.max_retries}) "
                        f"[{context.request_id}]"
                    )

                    # Make request
                    response = await self._client.request(
                        method=method,
                        url=proxied_url,
                        **kwargs
                    )

                    # Check response status
                    response.raise_for_status()

                    logger.debug(
                        f"✅ {method} {url} -> {response.status_code} "
                        f"[{context.request_id}]"
                    )

                    return response

            except httpx.HTTPStatusError as e:
                last_error = e
                logger.warning(
                    f"⚠️ HTTP error {e.response.status_code} on {method} {url} "
                    f"(attempt {attempt + 1}/{self.max_retries})"
                )

                # Don't retry on 4xx errors (client errors)
                if 400 <= e.response.status_code < 500:
                    raise

                # Rotate proxy on server errors
                if self.flareprox_manager.enabled:
                    self.flareprox_manager.proxies.rotate(-1)

            except (httpx.TimeoutException, httpx.ConnectError) as e:
                last_error = e
                logger.warning(
                    f"⚠️ Network error on {method} {url}: {type(e).__name__} "
                    f"(attempt {attempt + 1}/{self.max_retries})"
                )

                # Rotate proxy on network errors
                if self.flareprox_manager.enabled:
                    self.flareprox_manager.proxies.rotate(-1)

            except Exception as e:
                last_error = e
                logger.error(
                    f"❌ Unexpected error on {method} {url}: {e} "
                    f"(attempt {attempt + 1}/{self.max_retries})"
                )

            # Exponential backoff before retry
            if attempt < self.max_retries - 1:
                delay = self.retry_delay * (2 ** attempt)
                logger.debug(f"⏳ Retrying in {delay:.1f}s...")
                await asyncio.sleep(delay)

        # All retries failed
        logger.error(f"❌ All {self.max_retries} attempts failed for {method} {url}")
        if last_error:
            raise last_error
        raise httpx.HTTPError(f"Request failed after {self.max_retries} attempts")

    async def get(self, url: str, **kwargs) -> httpx.Response:
        """Make GET request"""
        return await self._make_request_with_retry("GET", url, **kwargs)

    async def post(self, url: str, **kwargs) -> httpx.Response:
        """Make POST request"""
        return await self._make_request_with_retry("POST", url, **kwargs)

    async def put(self, url: str, **kwargs) -> httpx.Response:
        """Make PUT request"""
        return await self._make_request_with_retry("PUT", url, **kwargs)

    async def delete(self, url: str, **kwargs) -> httpx.Response:
        """Make DELETE request"""
        return await self._make_request_with_retry("DELETE", url, **kwargs)

    async def stream(
        self,
        method: str,
        url: str,
        **kwargs
    ) -> AsyncGenerator[bytes, None]:
        """
        Stream response data (for SSE, large files, etc.)

        Args:
            method: HTTP method
            url: Target URL
            **kwargs: Additional arguments for httpx request

        Yields:
            Response data chunks
        """
        if not self._client:
            raise RuntimeError("HTTP client not initialized. Use async context manager.")

        # Get proxied URL
        proxied_url, proxy_url = self._get_proxied_url(url)

        # Create request context
        async with self.request_tracker.track_request(
            target_url=url,
            proxy_url=proxy_url,
            metadata={"method": method, "streaming": True}
        ) as context:

            logger.debug(f"🌊 Streaming {method} {url} [{context.request_id}]")

            try:
                async with self._client.stream(
                    method=method,
                    url=proxied_url,
                    **kwargs
                ) as response:
                    response.raise_for_status()

                    async for chunk in response.aiter_bytes():
                        if chunk:
                            yield chunk

                logger.debug(f"✅ Stream completed {url} [{context.request_id}]")

            except Exception as e:
                logger.error(f"❌ Stream error on {url}: {e} [{context.request_id}]")
                raise


@asynccontextmanager
async def get_http_client(**kwargs) -> ProxiedHTTPClient:
    """
    Context manager to get HTTP client instance

    Usage:
        async with get_http_client() as client:
            response = await client.get("https://api.example.com")
    """
    async with ProxiedHTTPClient(**kwargs) as client:
        yield client


# Convenience function for one-off requests
async def request(
    method: str,
    url: str,
    timeout: float = 30.0,
    **kwargs
) -> httpx.Response:
    """
    Make a one-off HTTP request with FlareProx support

    Args:
        method: HTTP method
        url: Target URL
        timeout: Request timeout
        **kwargs: Additional arguments for httpx request

    Returns:
        HTTP response
    """
    async with get_http_client(timeout=timeout) as client:
        return await client._make_request_with_retry(method, url, **kwargs)


# Convenience functions for common HTTP methods
async def get(url: str, **kwargs) -> httpx.Response:
    """Make GET request"""
    return await request("GET", url, **kwargs)


async def post(url: str, **kwargs) -> httpx.Response:
    """Make POST request"""
    return await request("POST", url, **kwargs)


async def put(url: str, **kwargs) -> httpx.Response:
    """Make PUT request"""
    return await request("PUT", url, **kwargs)


async def delete(url: str, **kwargs) -> httpx.Response:
    """Make DELETE request"""
    return await request("DELETE", url, **kwargs)

