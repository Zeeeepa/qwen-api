#!/usr/bin/env python

"""
Health Check and Monitoring Endpoints
"""

import time

import psutil
from fastapi import APIRouter, Response

from app import __version__
from app.core.config import settings
from app.utils.flareprox_manager import get_flareprox_manager
from app.utils.logger import get_logger
from app.utils.request_tracker import get_request_tracker
from app.utils.token_pool import get_token_pool

logger = get_logger()
router = APIRouter()

# Track service start time
_start_time = time.time()


@router.get("/health")
async def health_check():
    """
    Simple health check endpoint

    Returns 200 OK if service is running
    """
    return {"status": "ok", "service": settings.SERVICE_NAME, "version": __version__}


@router.get("/health/detailed")
async def detailed_health():
    """
    Detailed health check with component status

    Returns health status for all system components
    """
    flareprox_manager = get_flareprox_manager()
    request_tracker = get_request_tracker()
    token_pool = get_token_pool()

    health_status = {
        "status": "healthy",
        "service": settings.SERVICE_NAME,
        "version": __version__,
        "uptime_seconds": time.time() - _start_time,
        "components": {
            "flareprox": {
                "enabled": flareprox_manager.enabled,
                "initialized": flareprox_manager._initialized if flareprox_manager.enabled else None,
                "proxy_count": len(flareprox_manager.proxies) if flareprox_manager.enabled else 0,
                "status": "healthy" if flareprox_manager.enabled and flareprox_manager._initialized else "disabled"
            },
            "request_tracker": {
                "active_requests": request_tracker._total_requests,
                "status": "healthy"
            },
            "token_pool": {
                "total_tokens": len(token_pool._tokens) if token_pool else 0,
                "available_tokens": len([t for t in (token_pool._tokens if token_pool else []) if t.is_available]),
                "status": "healthy" if token_pool and any(t.is_available for t in token_pool._tokens) else "degraded"
            }
        }
    }

    # Determine overall health
    component_statuses = [comp["status"] for comp in health_status["components"].values()]
    if any(status == "unhealthy" for status in component_statuses):
        health_status["status"] = "unhealthy"
    elif any(status == "degraded" for status in component_statuses):
        health_status["status"] = "degraded"

    return health_status


@router.get("/stats")
async def get_stats():
    """
    Get service statistics

    Returns:
        Statistics for request tracking, FlareProx, token pool
    """
    flareprox_manager = get_flareprox_manager()
    request_tracker = get_request_tracker()
    token_pool = get_token_pool()

    stats = {
        "service": {
            "name": settings.SERVICE_NAME,
            "version": __version__,
            "uptime_seconds": time.time() - _start_time
        },
        "request_tracker": request_tracker.get_stats(),
        "flareprox": flareprox_manager.get_stats(),
        "token_pool": {
            "total_tokens": len(token_pool._tokens) if token_pool else 0,
            "available_tokens": len([t for t in (token_pool._tokens if token_pool else []) if t.is_available]),
            "token_stats": [
                {
                    "token": t.token[:10] + "..." if len(t.token) > 10 else t.token,
                    "available": t.is_available,
                    "failure_count": t.failure_count,
                    "last_used": t.last_used
                }
                for t in (token_pool._tokens if token_pool else [])
            ]
        } if token_pool else {}
    }

    return stats


@router.get("/system")
async def get_system_info():
    """
    Get system resource information

    Returns:
        CPU, memory, disk usage
    """
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')

    return {
        "cpu": {
            "percent": cpu_percent,
            "count": psutil.cpu_count()
        },
        "memory": {
            "total_gb": round(memory.total / (1024**3), 2),
            "available_gb": round(memory.available / (1024**3), 2),
            "used_gb": round(memory.used / (1024**3), 2),
            "percent": memory.percent
        },
        "disk": {
            "total_gb": round(disk.total / (1024**3), 2),
            "used_gb": round(disk.used / (1024**3), 2),
            "free_gb": round(disk.free / (1024**3), 2),
            "percent": disk.percent
        }
    }


@router.get("/metrics")
async def get_metrics():
    """
    Get metrics in a format suitable for monitoring systems

    Returns metrics that can be scraped by Prometheus or similar tools
    """
    request_tracker = get_request_tracker()
    stats = request_tracker.get_stats()

    # Simple text format metrics
    metrics_text = f"""
# HELP qwen_api_requests_total Total number of requests processed
# TYPE qwen_api_requests_total counter
qwen_api_requests_total {stats['total_requests']}

# HELP qwen_api_requests_active Currently active requests
# TYPE qwen_api_requests_active gauge
qwen_api_requests_active {stats['active_requests']}

# HELP qwen_api_requests_successful Successfully completed requests
# TYPE qwen_api_requests_successful counter
qwen_api_requests_successful {stats['successful_requests']}

# HELP qwen_api_requests_failed Failed requests
# TYPE qwen_api_requests_failed counter
qwen_api_requests_failed {stats['failed_requests']}

# HELP qwen_api_requests_timeout Timed out requests
# TYPE qwen_api_requests_timeout counter
qwen_api_requests_timeout {stats['timeout_requests']}

# HELP qwen_api_success_rate Request success rate percentage
# TYPE qwen_api_success_rate gauge
qwen_api_success_rate {stats['success_rate']}

# HELP qwen_api_uptime_seconds Service uptime in seconds
# TYPE qwen_api_uptime_seconds gauge
qwen_api_uptime_seconds {time.time() - _start_time}
    """.strip()

    return Response(content=metrics_text, media_type="text/plain")


@router.get("/debug")
async def debug_info():
    """
    Debug information endpoint (only available in debug mode)

    Returns detailed debugging information
    """
    if not settings.DEBUG_LOGGING:
        return {"error": "Debug mode is not enabled"}

    request_tracker = get_request_tracker()
    flareprox_manager = get_flareprox_manager()

    active_requests = await request_tracker.get_active_requests()
    completed_requests = await request_tracker.get_completed_requests(limit=10)

    debug_info = {
        "config": {
            "host": settings.HOST,
            "port": settings.LISTEN_PORT,
            "debug_logging": settings.DEBUG_LOGGING,
            "anonymous_mode": settings.ANONYMOUS_MODE,
            "tool_support": settings.TOOL_SUPPORT
        },
        "active_requests": [
            ctx.to_dict() for ctx in active_requests.values()
        ],
        "recent_completed_requests": [
            ctx.to_dict() for ctx in completed_requests.values()
        ],
        "flareprox": {
            "enabled": flareprox_manager.enabled,
            "proxies": list(flareprox_manager.proxies) if flareprox_manager.enabled else [],
            "stats": flareprox_manager.get_stats()
        }
    }

    return debug_info

