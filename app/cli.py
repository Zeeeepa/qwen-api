#!/usr/bin/env python

"""
Command-line interface for Qwen API Server
"""

import argparse
import os
import sys

from app import __version__
from app.core.config import settings
from app.utils.logger import get_logger

logger = get_logger()


def print_banner():
    """Print startup banner"""
    banner = f"""
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🚀 Qwen API Server v{__version__:<40} ║
║   OpenAI-Compatible Multi-Provider AI API                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"""
    print(banner)


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(
        description="Qwen API Server - OpenAI-Compatible API Gateway",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Using environment variables (recommended)
  export QWEN_EMAIL='your@email.com'
  export QWEN_PASSWORD='your_password'
  python main.py
  
  # Using command-line arguments
  python main.py --qwen-email your@email.com --qwen-password your_password
  
  # Custom port
  python main.py --port 8081
  
  # Force re-authentication (clear cached token)
  python main.py --force-reauth
  
  # Debug mode
  python main.py --debug

Environment Variables:
  QWEN_EMAIL          Qwen account email (REQUIRED)
  QWEN_PASSWORD       Qwen account password (REQUIRED)
  LISTEN_PORT         Server port (default: 8080)
  HOST                Server host (default: 0.0.0.0)
  DEBUG_LOGGING       Enable debug mode (default: false)
  FLAREPROX_ENABLED   Enable FlareProx (default: false)
  FORCE_REAUTH        Force re-authentication (default: false)
        """
    )

    parser.add_argument(
        "--version",
        action="version",
        version=f"Qwen API Server v{__version__}"
    )

    parser.add_argument(
        "-p", "--port",
        type=int,
        help=f"Server port (default: {settings.LISTEN_PORT})",
        default=None
    )

    parser.add_argument(
        "--host",
        type=str,
        help=f"Server host (default: {settings.HOST})",
        default=None,
        dest="host_arg"
    )

    parser.add_argument(
        "-d", "--debug",
        action="store_true",
        help="Enable debug logging",
        default=None
    )

    parser.add_argument(
        "--no-reload",
        action="store_true",
        help="Disable hot reload (recommended for production)",
        default=False
    )

    parser.add_argument(
        "--workers",
        type=int,
        help="Number of worker processes (default: 1)",
        default=1
    )

    parser.add_argument(
        "--tokens-file",
        type=str,
        help="Path to authentication tokens file",
        default=None
    )

    parser.add_argument(
        "--flareprox",
        action="store_true",
        help="Enable FlareProx proxy rotation",
        default=None
    )

    parser.add_argument(
        "--qwen-email",
        type=str,
        help="Qwen account email (or set QWEN_EMAIL env var)",
        default=None
    )

    parser.add_argument(
        "--qwen-password",
        type=str,
        help="Qwen account password (or set QWEN_PASSWORD env var)",
        default=None
    )

    parser.add_argument(
        "--force-reauth",
        action="store_true",
        help="Force re-authentication even if cached token exists",
        default=False
    )

    return parser.parse_args()


def apply_cli_overrides(args: argparse.Namespace):
    """Apply CLI arguments to settings"""

    # Port override
    if args.port is not None:
        settings.LISTEN_PORT = args.port
        logger.info(f"📌 Port override: {args.port}")

    # Host override (check host_arg to avoid conflict)
    if hasattr(args, 'host_arg') and args.host_arg is not None:
        settings.HOST = args.host_arg
        logger.info(f"📌 Host override: {args.host_arg}")

    # Debug mode override
    if args.debug is not None:
        settings.DEBUG_LOGGING = args.debug
        logger.info(f"📌 Debug mode: {'enabled' if args.debug else 'disabled'}")

    # Tokens file override
    if args.tokens_file is not None:
        settings.AUTH_TOKENS_FILE = args.tokens_file
        logger.info(f"📌 Tokens file: {args.tokens_file}")

    # FlareProx override
    if args.flareprox is not None:
        os.environ["FLAREPROX_ENABLED"] = "true" if args.flareprox else "false"
        logger.info(f"📌 FlareProx: {'enabled' if args.flareprox else 'disabled'}")

    # Qwen credentials override
    if args.qwen_email is not None:
        os.environ["QWEN_EMAIL"] = args.qwen_email
        logger.info(f"📌 Qwen email: {args.qwen_email}")
    
    if args.qwen_password is not None:
        os.environ["QWEN_PASSWORD"] = args.qwen_password
        logger.info(f"📌 Qwen password: {'*' * len(args.qwen_password)}")
    
    # Force reauth flag
    if args.force_reauth:
        os.environ["FORCE_REAUTH"] = "true"
        logger.info(f"📌 Force re-authentication: enabled")


def validate_configuration() -> bool:
    """Validate configuration before starting server"""
    errors = []

    # Check port range
    if not (1 <= settings.LISTEN_PORT <= 65535):
        errors.append(f"Invalid port: {settings.LISTEN_PORT} (must be 1-65535)")

    # Check tokens file if specified
    if settings.AUTH_TOKENS_FILE and not os.path.exists(settings.AUTH_TOKENS_FILE):
        errors.append(f"Tokens file not found: {settings.AUTH_TOKENS_FILE}")

    # Check FlareProx configuration
    flareprox_enabled = os.getenv("FLAREPROX_ENABLED", "false").lower() == "true"
    if flareprox_enabled:
        if not os.getenv("CLOUDFLARE_API_TOKEN"):
            errors.append("FlareProx enabled but CLOUDFLARE_API_TOKEN not set")
        if not os.getenv("CLOUDFLARE_ACCOUNT_ID"):
            errors.append("FlareProx enabled but CLOUDFLARE_ACCOUNT_ID not set")

    if errors:
        logger.error("❌ Configuration validation failed:")
        for error in errors:
            logger.error(f"   • {error}")
        return False

    return True


async def ensure_qwen_authentication() -> str:
    """
    Ensure we have valid Qwen authentication token
    
    Returns:
        Valid Bearer token
    """
    from app.auth.token_manager import get_or_create_token
    
    logger.info("=" * 70)
    logger.info("🔐 Qwen Authentication Check")
    logger.info("=" * 70)
    
    # Get credentials from environment
    email = os.getenv("QWEN_EMAIL")
    password = os.getenv("QWEN_PASSWORD")
    force_reauth = os.getenv("FORCE_REAUTH", "false").lower() == "true"
    
    try:
        # Get or create token
        token = await get_or_create_token(
            email=email,
            password=password,
            force_new=force_reauth
        )
        
        logger.success("✅ Qwen authentication successful!")
        logger.info(f"📝 Token: {token[:30]}...{token[-10:]}")
        logger.info("=" * 70)
        
        # Store token in environment for provider to use
        os.environ["QWEN_BEARER_TOKEN"] = token
        
        return token
        
    except ValueError as e:
        logger.error("=" * 70)
        logger.error("❌ Qwen Authentication Required!")
        logger.error("=" * 70)
        logger.error(str(e))
        logger.error("")
        logger.error("Please provide Qwen credentials:")
        logger.error("  1. Set environment variables:")
        logger.error("     export QWEN_EMAIL='your@email.com'")
        logger.error("     export QWEN_PASSWORD='your_password'")
        logger.error("")
        logger.error("  2. Or use command-line arguments:")
        logger.error("     python main.py --qwen-email your@email.com --qwen-password your_password")
        logger.error("=" * 70)
        raise
    except Exception as e:
        logger.error("=" * 70)
        logger.error(f"❌ Authentication failed: {e}")
        logger.error("=" * 70)
        raise


def print_startup_info():
    """Print startup information"""
    logger.info("=" * 70)
    logger.info(f"🚀 Starting {settings.SERVICE_NAME}")
    logger.info(f"📡 Server: http://{settings.HOST}:{settings.LISTEN_PORT}")
    logger.info(f"🔧 Debug Mode: {'ON' if settings.DEBUG_LOGGING else 'OFF'}")

    # FlareProx status
    flareprox_enabled = os.getenv("FLAREPROX_ENABLED", "false").lower() == "true"
    logger.info(f"🔥 FlareProx: {'ENABLED' if flareprox_enabled else 'DISABLED'}")

    # Token pool status
    if settings.AUTH_TOKENS_FILE:
        token_count = len(settings.auth_token_list)
        logger.info(f"🎫 Token Pool: {token_count} tokens loaded")

    logger.info("=" * 70)


def main():
    """Main entry point for CLI"""
    import asyncio
    
    try:
        # Print banner
        print_banner()

        # Parse arguments
        args = parse_args()

        # Apply CLI overrides to settings
        apply_cli_overrides(args)

        # Validate configuration
        if not validate_configuration():
            logger.error("❌ Server startup aborted due to configuration errors")
            sys.exit(1)

        # ⚠️ CRITICAL: Ensure Qwen authentication before starting server
        try:
            asyncio.run(ensure_qwen_authentication())
        except Exception as e:
            logger.error("❌ Authentication failed - cannot start server without valid Qwen credentials")
            sys.exit(1)

        # Print startup info
        print_startup_info()

        # Import and run server
        from main import run_server

        # Start the server
        run_server()

    except KeyboardInterrupt:
        logger.info("\n🛑 Server shutdown requested")
        sys.exit(0)
    except Exception as e:
        logger.error(f"❌ Fatal error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
