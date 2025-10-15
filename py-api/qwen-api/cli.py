#!/usr/bin/env python

"""
Command-line interface for Qwen API Server
"""

import argparse
import os
import sys

__version__ = "1.0.0"

from config import settings
from logger import get_logger

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
  python main.py                    # Start server with default settings
  python main.py --port 8081        # Start server on port 8081
  python main.py --host 0.0.0.0     # Bind to all interfaces
  python main.py --debug            # Enable debug logging
  python main.py --no-reload        # Disable hot reload

Environment Variables:
  LISTEN_PORT         Server port (default: 8080)
  HOST                Server host (default: 0.0.0.0)
  DEBUG_LOGGING       Enable debug mode (default: false)
  FLAREPROX_ENABLED   Enable FlareProx (default: false)
  AUTH_TOKENS_FILE    Path to tokens file
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
        "--anonymous",
        action="store_true",
        help="Enable anonymous mode (skip API key validation)",
        default=None
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

    # Anonymous mode override
    if args.anonymous is not None:
        settings.ANONYMOUS_MODE = args.anonymous
        logger.info(f"📌 Anonymous mode: {'enabled' if args.anonymous else 'disabled'}")


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


def print_startup_info():
    """Print startup information"""
    logger.info("=" * 70)
    logger.info(f"🚀 Starting {settings.SERVICE_NAME}")
    logger.info(f"📡 Server: http://{settings.HOST}:{settings.LISTEN_PORT}")
    logger.info(f"🔧 Debug Mode: {'ON' if settings.DEBUG_LOGGING else 'OFF'}")
    logger.info(f"🔐 Anonymous Mode: {'ON' if settings.ANONYMOUS_MODE else 'OFF'}")

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
