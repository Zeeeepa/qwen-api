# 📦 How to Create GitHub Gist for One-Line Deployment

## Step 1: Go to GitHub Gist

Visit: https://gist.github.com/

## Step 2: Create New Gist

Click "+" in top right → "New gist"

## Step 3: Add Files

### File 1: README.md
- Filename: `README.md`
- Content: Copy from `GIST_README.md`

### File 2: deploy_qwen_api.sh
- Filename: `deploy_qwen_api.sh`
- Content: Copy from `deploy_qwen_api.sh`

## Step 4: Configure Gist

- Description: "🚀 Qwen API - One-Line Deployment Script | Complete OpenAI-compatible API deployment"
- Visibility: **Public**

## Step 5: Create Gist

Click "Create public gist"

## Step 6: Get Raw URL

After creation, click "Raw" button on `deploy_qwen_api.sh` to get URL like:
```
https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/deploy_qwen_api.sh
```

## Step 7: Test Deployment

```bash
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"
curl -sSL YOUR_RAW_URL | bash
```

## Step 8: Update Repository

Update main README.md with:

```markdown
## 🚀 Quick Deployment

```bash
# Export credentials
export QWEN_EMAIL="your@email.com"
export QWEN_PASSWORD="yourpassword"

# Deploy with one command
curl -sSL https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/deploy_qwen_api.sh | bash
```
```

## ✅ Done!

Your one-line deployment is now live and shareable!

## 📝 Share Command

Share this with users:

```bash
# One-line deployment for Qwen API
export QWEN_EMAIL="your@email.com" QWEN_PASSWORD="yourpassword"
curl -sSL https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/deploy_qwen_api.sh | bash
```
