#!/usr/bin/env python3
"""
Command-line interface for Qwen API server
"""

import sys
import click
import uvicorn
from pathlib import Path

from .config_loader import settings
from .logging_config import logger


@click.group()
@click.version_option(version="1.0.0", prog_name="qwen-api")
def cli():
    """Qwen API - OpenAI-compatible server for Qwen models"""
    pass


@cli.command()
@click.option('--host', default=None, help='Host to bind to (default: from .env or 0.0.0.0)')
@click.option('--port', default=None, type=int, help='Port to bind to (default: from .env or 7050)')
@click.option('--reload', is_flag=True, help='Enable auto-reload for development')
@click.option('--workers', default=1, type=int, help='Number of worker processes')
@click.option('--log-level', default=None, help='Log level (debug, info, warning, error)')
def serve(host, port, reload, workers, log_level):
    """Start the Qwen API server"""
    
    # Use settings from .env or defaults
    server_host = host or settings.host
    server_port = port or settings.port
    log_level = log_level or settings.log_level.lower()
    
    logger.info(f"Starting Qwen API server on {server_host}:{server_port}")
    logger.info(f"Log level: {log_level}")
    
    # Import app here to avoid circular imports
    from .api_server import app
    
    try:
        uvicorn.run(
            "qwen_api.api_server:app",
            host=server_host,
            port=server_port,
            reload=reload,
            workers=workers if not reload else 1,
            log_level=log_level,
            access_log=False,  # Use our custom logging
        )
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Server failed to start: {e}")
        sys.exit(1)


@cli.command()
def health():
    """Check if the server is running"""
    import httpx
    
    try:
        response = httpx.get(f"http://{settings.host}:{settings.port}/health", timeout=5)
        if response.status_code == 200:
            click.echo(click.style("✓ Server is healthy", fg='green'))
            sys.exit(0)
        else:
            click.echo(click.style(f"✗ Server returned status {response.status_code}", fg='red'))
            sys.exit(1)
    except Exception as e:
        click.echo(click.style(f"✗ Server is not reachable: {e}", fg='red'))
        sys.exit(1)


@cli.command()
@click.option('--email', envvar='QWEN_EMAIL', required=True, help='Qwen account email')
@click.option('--password', envvar='QWEN_PASSWORD', required=True, help='Qwen account password')
def get_token(email, password):
    """Extract Qwen authentication token"""
    import asyncio
    from .qwen_token_real import extract_qwen_token
    
    async def extract():
        token = await extract_qwen_token(email, password)
        if token:
            click.echo(token)
            return 0
        else:
            click.echo(click.style("✗ Failed to extract token", fg='red'), err=True)
            return 1
    
    try:
        exit_code = asyncio.run(extract())
        sys.exit(exit_code)
    except Exception as e:
        click.echo(click.style(f"✗ Error: {e}", fg='red'), err=True)
        sys.exit(1)


@cli.command()
def info():
    """Display server configuration"""
    click.echo(click.style("Qwen API Configuration", fg='cyan', bold=True))
    click.echo(f"  Server: {settings.host}:{settings.port}")
    click.echo(f"  API Base: {settings.qwen_api_base}")
    click.echo(f"  Log Level: {settings.log_level}")
    click.echo(f"  Token Length: {len(settings.qwen_bearer_token) if settings.qwen_bearer_token else 0} chars")
    click.echo(f"  Default Model: {settings.default_model}")


def main():
    """Main entry point"""
    cli()


if __name__ == '__main__':
    main()
