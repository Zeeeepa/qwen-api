#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Request Correlation and Tracking System

Provides unique request IDs and correlation tracking for:
- FlareProx proxy rotation
- Concurrent request handling
- Request/response mapping
- Performance monitoring
- Debug tracing
"""

import uuid
import time
import asyncio
from typing import Dict, Optional, Any, Callable
from dataclasses import dataclass, field
from datetime import datetime
from contextlib import asynccontextmanager

from app.utils.logger import get_logger

logger = get_logger()


@dataclass
class RequestContext:
    """Context information for a tracked request"""
    request_id: str
    proxy_url: Optional[str] = None
    target_url: Optional[str] = None
    start_time: float = field(default_factory=time.time)
    end_time: Optional[float] = None
    status: str = "pending"  # pending, success, failed, timeout
    error: Optional[str] = None
    retry_count: int = 0
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    @property
    def duration(self) -> Optional[float]:
        """Calculate request duration"""
        if self.end_time:
            return self.end_time - self.start_time
        return None
    
    @property
    def is_completed(self) -> bool:
        """Check if request is completed"""
        return self.status in ("success", "failed", "timeout")
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for logging/metrics"""
        return {
            "request_id": self.request_id,
            "proxy_url": self.proxy_url,
            "target_url": self.target_url,
            "start_time": self.start_time,
            "end_time": self.end_time,
            "duration": self.duration,
            "status": self.status,
            "error": self.error,
            "retry_count": self.retry_count,
            "metadata": self.metadata
        }


class RequestTracker:
    """
    Tracks active and completed requests with correlation IDs
    
    Features:
    - Unique request ID generation
    - Request/response correlation
    - Performance monitoring
    - Automatic cleanup of old entries
    - Thread-safe operations
    """
    
    def __init__(
        self,
        max_tracked_requests: int = 10000,
        cleanup_interval: int = 300,  # 5 minutes
        max_request_age: int = 3600   # 1 hour
    ):
        self._active_requests: Dict[str, RequestContext] = {}
        self._completed_requests: Dict[str, RequestContext] = {}
        self._lock = asyncio.Lock()
        
        self.max_tracked_requests = max_tracked_requests
        self.cleanup_interval = cleanup_interval
        self.max_request_age = max_request_age
        
        # Statistics
        self._total_requests = 0
        self._successful_requests = 0
        self._failed_requests = 0
        self._timeout_requests = 0
        
        # Start cleanup task
        self._cleanup_task: Optional[asyncio.Task] = None
        self._running = False
    
    def start(self):
        """Start the request tracker and cleanup task"""
        if not self._running:
            self._running = True
            self._cleanup_task = asyncio.create_task(self._cleanup_loop())
            logger.info("🔍 Request Tracker: Started")
    
    async def stop(self):
        """Stop the request tracker"""
        self._running = False
        if self._cleanup_task:
            self._cleanup_task.cancel()
            try:
                await self._cleanup_task
            except asyncio.CancelledError:
                pass
        logger.info("🔍 Request Tracker: Stopped")
    
    def generate_request_id(self) -> str:
        """Generate a unique request ID"""
        return f"req_{uuid.uuid4().hex[:16]}"
    
    async def create_context(
        self,
        target_url: str,
        proxy_url: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> RequestContext:
        """Create a new request context"""
        request_id = self.generate_request_id()
        
        context = RequestContext(
            request_id=request_id,
            target_url=target_url,
            proxy_url=proxy_url,
            metadata=metadata or {}
        )
        
        async with self._lock:
            self._active_requests[request_id] = context
            self._total_requests += 1
        
        logger.debug(f"📝 Created request context: {request_id}")
        return context
    
    async def update_context(
        self,
        request_id: str,
        status: Optional[str] = None,
        error: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ):
        """Update an existing request context"""
        async with self._lock:
            if request_id in self._active_requests:
                context = self._active_requests[request_id]
                
                if status:
                    context.status = status
                    context.end_time = time.time()
                    
                    # Update statistics
                    if status == "success":
                        self._successful_requests += 1
                    elif status == "failed":
                        self._failed_requests += 1
                    elif status == "timeout":
                        self._timeout_requests += 1
                
                if error:
                    context.error = error
                
                if metadata:
                    context.metadata.update(metadata)
                
                logger.debug(f"📝 Updated request context: {request_id} -> {status}")
    
    async def complete_request(
        self,
        request_id: str,
        status: str = "success",
        error: Optional[str] = None
    ):
        """Mark a request as completed and move to completed list"""
        async with self._lock:
            if request_id in self._active_requests:
                context = self._active_requests.pop(request_id)
                context.status = status
                context.end_time = time.time()
                context.error = error
                
                # Update statistics
                if status == "success":
                    self._successful_requests += 1
                elif status == "failed":
                    self._failed_requests += 1
                elif status == "timeout":
                    self._timeout_requests += 1
                
                # Store in completed requests (with limit)
                self._completed_requests[request_id] = context
                
                # Cleanup if too many completed requests
                if len(self._completed_requests) > self.max_tracked_requests:
                    # Remove oldest entries
                    sorted_requests = sorted(
                        self._completed_requests.items(),
                        key=lambda x: x[1].end_time or 0
                    )
                    to_remove = len(sorted_requests) - self.max_tracked_requests
                    for req_id, _ in sorted_requests[:to_remove]:
                        del self._completed_requests[req_id]
                
                duration = context.duration
                logger.debug(
                    f"✅ Completed request: {request_id} -> {status} "
                    f"(duration: {duration:.2f}s)" if duration else ""
                )
    
    async def increment_retry(self, request_id: str):
        """Increment retry count for a request"""
        async with self._lock:
            if request_id in self._active_requests:
                self._active_requests[request_id].retry_count += 1
    
    async def get_context(self, request_id: str) -> Optional[RequestContext]:
        """Get context for a request"""
        async with self._lock:
            if request_id in self._active_requests:
                return self._active_requests[request_id]
            if request_id in self._completed_requests:
                return self._completed_requests[request_id]
        return None
    
    @asynccontextmanager
    async def track_request(
        self,
        target_url: str,
        proxy_url: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ):
        """
        Context manager for tracking a request lifecycle
        
        Usage:
            async with tracker.track_request(url, proxy) as context:
                # Make request
                response = await client.get(url)
                # Context automatically completed on exit
        """
        context = await self.create_context(target_url, proxy_url, metadata)
        
        try:
            yield context
            # Success if no exception raised
            await self.complete_request(context.request_id, "success")
        except asyncio.TimeoutError:
            await self.complete_request(
                context.request_id,
                "timeout",
                "Request timeout"
            )
            raise
        except Exception as e:
            await self.complete_request(
                context.request_id,
                "failed",
                str(e)
            )
            raise
    
    async def _cleanup_loop(self):
        """Background task to cleanup old completed requests"""
        while self._running:
            try:
                await asyncio.sleep(self.cleanup_interval)
                await self._cleanup_old_requests()
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"❌ Request tracker cleanup error: {e}")
    
    async def _cleanup_old_requests(self):
        """Remove old completed requests"""
        current_time = time.time()
        
        async with self._lock:
            to_remove = []
            
            for req_id, context in self._completed_requests.items():
                if context.end_time:
                    age = current_time - context.end_time
                    if age > self.max_request_age:
                        to_remove.append(req_id)
            
            for req_id in to_remove:
                del self._completed_requests[req_id]
            
            if to_remove:
                logger.debug(f"🧹 Cleaned up {len(to_remove)} old request contexts")
    
    def get_stats(self) -> Dict[str, Any]:
        """Get request tracking statistics"""
        return {
            "total_requests": self._total_requests,
            "active_requests": len(self._active_requests),
            "completed_requests": len(self._completed_requests),
            "successful_requests": self._successful_requests,
            "failed_requests": self._failed_requests,
            "timeout_requests": self._timeout_requests,
            "success_rate": (
                self._successful_requests / self._total_requests * 100
                if self._total_requests > 0 else 0
            )
        }
    
    async def get_active_requests(self) -> Dict[str, RequestContext]:
        """Get all active requests"""
        async with self._lock:
            return self._active_requests.copy()
    
    async def get_completed_requests(
        self,
        limit: int = 100
    ) -> Dict[str, RequestContext]:
        """Get recent completed requests"""
        async with self._lock:
            # Sort by end time (most recent first)
            sorted_requests = sorted(
                self._completed_requests.items(),
                key=lambda x: x[1].end_time or 0,
                reverse=True
            )
            return dict(sorted_requests[:limit])


# Global request tracker instance
_request_tracker: Optional[RequestTracker] = None


def get_request_tracker() -> RequestTracker:
    """Get the global request tracker instance"""
    global _request_tracker
    if _request_tracker is None:
        _request_tracker = RequestTracker()
    return _request_tracker


async def initialize_request_tracker():
    """Initialize and start the request tracker"""
    tracker = get_request_tracker()
    tracker.start()
    logger.info("✅ Request Tracker: Initialized")
    return tracker

