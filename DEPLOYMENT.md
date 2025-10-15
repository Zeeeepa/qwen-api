# Qwen API - Deployment Guide

Complete guide for deploying the Qwen API server in various environments.

## 🚀 Quick Start

### Option 1: Direct Python

```bash
# Install dependencies
pip install -e .

# Start server (default port 8000)
python main.py

# Start on custom port
python main.py --port 8081

# Start on specific host
python main.py --host 0.0.0.0 --port 8081

# Enable auto-reload for development
python main.py --reload
```

### Option 2: Docker Compose

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Option 3: Docker Manual

```bash
# Build image
docker build -t qwen-api:latest .

# Run container
docker run -d \
  --name qwen-api \
  -p 8000:8000 \
  --restart unless-stopped \
  qwen-api:latest

# View logs
docker logs -f qwen-api
```

## 📊 Server Information

When you start the server, you'll see:

```
============================================================
 🚀 Qwen API Server
============================================================

📍 Server: http://0.0.0.0:8000
📚 Docs: http://0.0.0.0:8000/docs
🔍 Health: http://0.0.0.0:8000/health
📋 Models: http://0.0.0.0:8000/v1/models

✅ Available Endpoints:
   - POST /v1/validate        - Validate token
   - POST /v1/refresh         - Refresh token
   - GET  /v1/models          - List models
   - POST /v1/chat/completions - Chat completions
   - POST /v1/images/generations - Image generation
   - POST /v1/images/edits    - Image editing
   - POST /v1/videos/generations - Video generation

============================================================

📊 Loaded 27 models:
   - qwen-max
   - qwen-max-latest
   - qwen-max-0428
   - qwen-max-thinking
   - qwen-max-search
   ... and 22 more
```

## 🧪 Testing

### Health Check
```bash
curl http://localhost:8000/health
```

### List Models
```bash
curl http://localhost:8000/v1/models
```

### Validate Token
```bash
curl -X POST http://localhost:8000/v1/validate \
  -H "Content-Type: application/json" \
  -d '{"token": "YOUR_COMPRESSED_TOKEN"}'
```

### Chat Completion
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer YOUR_COMPRESSED_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-turbo-latest",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## 📝 Usage Examples

### Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    api_key="YOUR_COMPRESSED_TOKEN",
    base_url="http://localhost:8000/v1"
)

response = client.chat.completions.create(
    model="qwen-turbo-latest",
    messages=[{"role": "user", "content": "What model are you?"}]
)

print(response.choices[0].message.content)
```

### JavaScript

```javascript
const response = await fetch("http://localhost:8000/v1/chat/completions", {
  method: "POST",
  headers: {
    "Authorization": "Bearer YOUR_COMPRESSED_TOKEN",
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    model: "qwen-turbo-latest",
    messages: [{role: "user", content: "Hello!"}]
  })
});

const data = await response.json();
console.log(data.choices[0].message.content);
```

### cURL

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Authorization: Bearer YOUR_COMPRESSED_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-turbo-latest",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": false
  }'
```

## 🌐 Production Deployment

### With nginx

1. **Install nginx**
```bash
sudo apt install nginx
```

2. **Configure nginx** (`/etc/nginx/sites-available/qwen-api`)
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Streaming support
    location /v1/chat/completions {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_buffering off;
        proxy_cache off;
        chunked_transfer_encoding on;
    }
}
```

3. **Enable and restart**
```bash
sudo ln -s /etc/nginx/sites-available/qwen-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### With SSL (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### As Systemd Service

1. **Create service file** (`/etc/systemd/system/qwen-api.service`)
```ini
[Unit]
Description=Qwen API Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/qwen-api
ExecStart=/usr/bin/python3 /opt/qwen-api/main.py --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

2. **Enable and start**
```bash
sudo systemctl enable qwen-api
sudo systemctl start qwen-api
sudo systemctl status qwen-api
```

## 🐳 Docker Production

### With Resource Limits

```bash
docker run -d \
  --name qwen-api \
  -p 8000:8000 \
  --memory="2g" \
  --cpus="2" \
  --restart unless-stopped \
  --health-cmd="curl -f http://localhost:8000/health || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  qwen-api:latest
```

### With Docker Compose (Production)

```yaml
version: '3.8'

services:
  qwen-api:
    build: .
    container_name: qwen-api-prod
    restart: always
    ports:
      - "127.0.0.1:8000:8000"  # Bind to localhost only
    environment:
      - PYTHONUNBUFFERED=1
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '4.0'
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"

  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - qwen-api
```

## 📊 Monitoring

### Prometheus Metrics (Future Enhancement)

Add prometheus client:
```bash
pip install prometheus-client
```

### Logging

Logs are written to stdout by default. To configure:

```python
# In main.py
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('qwen-api.log')
    ]
)
```

### Health Monitoring

```bash
# Simple monitoring script
while true; do
  curl -s http://localhost:8000/health | jq .
  sleep 30
done
```

## 🔧 Troubleshooting

### Port Already in Use

```bash
# Find process using port
lsof -i :8000

# Kill process
kill -9 <PID>

# Or use different port
python main.py --port 8081
```

### Docker Container Won't Start

```bash
# Check logs
docker logs qwen-api

# Check health
docker inspect qwen-api | jq '.[0].State.Health'

# Restart
docker restart qwen-api
```

### API Returns 401 Unauthorized

- Verify your token is valid
- Check token hasn't expired
- Ensure Bearer prefix in Authorization header

### Models Not Loading

- Check internet connectivity
- Verify firewall settings
- Try force refresh: `force_refresh=True` in code

## 🚀 Performance Tuning

### Uvicorn Workers

```bash
# Multiple workers for better concurrency
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

### Resource Limits

```yaml
# docker-compose.yml
deploy:
  resources:
    limits:
      memory: 4G
      cpus: '4.0'
    reservations:
      memory: 1G
      cpus: '1.0'
```

## 📚 API Documentation

- **Interactive Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI Schema**: http://localhost:8000/openapi.json

## 🔒 Security Best Practices

1. **Use HTTPS in production** - Always use SSL/TLS
2. **Secure tokens** - Store tokens securely, rotate regularly
3. **Rate limiting** - Implement rate limiting for API endpoints
4. **Firewall** - Restrict access to trusted IPs
5. **Regular updates** - Keep dependencies up to date

## 📞 Support

- **GitHub Issues**: https://github.com/Zeeeepa/qwen-api/issues
- **Documentation**: See README.md and qwen.json

---

Last updated: 2025-01-07

