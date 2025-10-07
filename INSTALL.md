# Installation Guide

Complete guide for installing and running the Qwen API Server.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation Methods](#installation-methods)
3. [Configuration](#configuration)
4. [Running the Server](#running-the-server)
5. [Docker Deployment](#docker-deployment)
6. [FlareProx Setup](#flareprox-setup)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Prerequisites

- Python 3.8 or higher
- pip or uv package manager
- (Optional) Docker and Docker Compose for containerized deployment
- (Optional) Cloudflare account for FlareProx integration

### Install from Source

```bash
# Clone the repository
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api

# Install in editable mode
pip install -e .

# Or use uv (recommended for faster installation)
uv pip install -e .
```

---

## Installation Methods

### Method 1: pip install -e . (Development)

Best for development and testing:

```bash
# Install in editable mode with all dependencies
pip install -e .

# Run the server
python main.py

# Or use the installed command
z-ai2api
```

### Method 2: Docker (Production)

Best for production deployments:

```bash
# Using docker-compose
docker-compose up -d

# Or build manually
docker build -f docker/Dockerfile -t qwen-api .
docker run -p 8080:8080 qwen-api
```

### Method 3: Manual Setup

For custom installations:

```bash
# Install dependencies
pip install -r requirements.txt

# Run directly
python main.py
```

---

## Configuration

### Environment Variables

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```bash
# Basic Configuration
LISTEN_PORT=8080
HOST=0.0.0.0
DEBUG_LOGGING=false

# Provider Credentials (required for authentication)
QWEN_EMAIL=your-email@example.com
QWEN_PASSWORD=your-password

# FlareProx (optional - for IP rotation)
FLAREPROX_ENABLED=false
CLOUDFLARE_API_TOKEN=your-cloudflare-token
CLOUDFLARE_ACCOUNT_ID=your-account-id
```

### Token Pool Configuration

For unlimited concurrency with multiple API keys:

1. Create a tokens file (e.g., `tokens.txt`):

```
sk-token1-xxxxx
sk-token2-yyyyy
sk-token3-zzzzz
```

2. Set the environment variable:

```bash
AUTH_TOKENS_FILE=tokens.txt
```

### Configuration Priority

1. CLI arguments (highest priority)
2. Environment variables
3. Default values (lowest priority)

---

## Running the Server

### Basic Usage

```bash
# Start with default settings (port 8080)
python main.py

# Specify custom port
python main.py --port 8081

# Enable debug mode
python main.py --debug

# Specify host
python main.py --host 0.0.0.0 --port 8081

# Show all options
python main.py --help
```

### Using the Installed Command

After `pip install -e .`:

```bash
# Default
z-ai2api

# With options
z-ai2api --port 8081 --debug
```

### Command-Line Options

```
Options:
  --version              Show version and exit
  -p, --port PORT        Server port (default: 8080)
  -h, --host HOST        Server host (default: 0.0.0.0)
  -d, --debug            Enable debug logging
  --no-reload            Disable hot reload (production)
  --workers N            Number of worker processes
  --tokens-file PATH     Path to authentication tokens file
  --flareprox            Enable FlareProx proxy rotation
  --anonymous            Enable anonymous mode
```

---

## Docker Deployment

### Using Docker Compose (Recommended)

1. **Create environment file:**

```bash
cp .env.example .env
# Edit .env with your credentials
```

2. **Start services:**

```bash
# Start in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

3. **Test the deployment:**

```bash
curl http://localhost:8080/health
```

### Custom Docker Compose

Create `docker-compose.override.yml` for custom configuration:

```yaml
version: '3.8'

services:
  qwen2api-router:
    environment:
      - DEBUG_LOGGING=true
      - LISTEN_PORT=8081
    ports:
      - "8081:8081"
```

### Docker Build Options

```bash
# Build image
docker build -f docker/Dockerfile -t qwen-api:latest .

# Run with environment variables
docker run -d \
  -p 8080:8080 \
  -e QWEN_EMAIL=your-email \
  -e QWEN_PASSWORD=your-password \
  -e DEBUG_LOGGING=true \
  --name qwen-api \
  qwen-api:latest

# Run with environment file
docker run -d \
  -p 8080:8080 \
  --env-file .env \
  --name qwen-api \
  qwen-api:latest
```

---

## FlareProx Setup

FlareProx provides IP rotation and load balancing through Cloudflare Workers.

### Prerequisites

1. **Cloudflare Account** with API access
2. **API Token** with Workers permissions
3. **Account ID** from Cloudflare dashboard

### Setup Steps

1. **Get Cloudflare credentials:**

   - Login to Cloudflare Dashboard
   - Get your Account ID from the URL or dashboard
   - Create API Token with "Edit Cloudflare Workers" permission

2. **Configure environment:**

```bash
# .env file
FLAREPROX_ENABLED=true
CLOUDFLARE_API_TOKEN=your-api-token
CLOUDFLARE_ACCOUNT_ID=your-account-id
FLAREPROX_PROXY_COUNT=3
FLAREPROX_AUTO_ROTATE=true
```

3. **Install FlareProx:**

```bash
# Download flareprox.py to project root
# The server will automatically initialize proxies on startup
```

4. **Verify setup:**

```bash
# Start server
python main.py --flareprox

# Check status
curl http://localhost:8080/stats
```

### FlareProx Features

- **Automatic IP Rotation:** Rotates through multiple Cloudflare Workers
- **Load Balancing:** Distributes requests across proxies
- **Unlimited Concurrency:** No IP-based rate limiting
- **Health Monitoring:** Automatic failover for unhealthy proxies

---

## Troubleshooting

### Common Issues

#### 1. Port Already in Use

```bash
# Error: Port 8080 already in use

# Solution: Use different port
python main.py --port 8081
```

#### 2. Module Not Found

```bash
# Error: ModuleNotFoundError: No module named 'app'

# Solution: Install in editable mode
pip install -e .
```

#### 3. FlareProx Not Initializing

```bash
# Error: FlareProx: Missing credentials

# Solution: Set environment variables
export CLOUDFLARE_API_TOKEN=your-token
export CLOUDFLARE_ACCOUNT_ID=your-account-id
export FLAREPROX_ENABLED=true
```

#### 4. Token Pool Empty

```bash
# Error: No available tokens

# Solution: Add tokens to file
echo "sk-token1" > tokens.txt
echo "sk-token2" >> tokens.txt
export AUTH_TOKENS_FILE=tokens.txt
```

### Debug Mode

Enable detailed logging:

```bash
# CLI
python main.py --debug

# Environment variable
export DEBUG_LOGGING=true
python main.py

# Check debug info
curl http://localhost:8080/debug
```

### Health Checks

```bash
# Basic health check
curl http://localhost:8080/health

# Detailed component status
curl http://localhost:8080/health/detailed

# System metrics
curl http://localhost:8080/system

# Request statistics
curl http://localhost:8080/stats
```

### Logs

```bash
# View logs (if using docker-compose)
docker-compose logs -f

# View specific service logs
docker-compose logs -f qwen2api-router

# Check log files
tail -f logs/app.log
```

---

## Testing the Installation

### 1. Health Check

```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "status": "ok",
  "service": "qwen-ai2api-server",
  "version": "0.2.0"
}
```

### 2. List Models

```bash
curl http://localhost:8080/v1/models
```

### 3. Chat Completion

```bash
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "GLM-4.5",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

### 4. Check Statistics

```bash
curl http://localhost:8080/stats
```

---

## Next Steps

After successful installation:

1. **Read the [API Documentation](docs/API.md)** for endpoint details
2. **Configure token rotation** for high availability
3. **Set up FlareProx** for unlimited concurrency
4. **Enable monitoring** with `/metrics` endpoint
5. **Review security settings** for production deployment

---

## Support

For issues and questions:

- **GitHub Issues:** https://github.com/Zeeeepa/qwen-api/issues
- **Documentation:** README.md and docs/
- **Examples:** See `examples/` directory

---

## License

MIT License - see LICENSE file for details

