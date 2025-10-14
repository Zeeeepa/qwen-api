# 🔑 How to Get Your Qwen Token

There are **two ways** to get your Qwen authentication token:

## Option 1: Use Temporary Test Token (Quick Start) ⚡

For immediate testing, use this temporary token:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjI3ZGUyYzVlLTYzZDYtNDU2MC1iNmQ3LTI2MDk0NDhjZmJmNiIsImxhc3RfcGFzc3dvcmRfY2hhbmdlIjoxNzU5ODg4MzE5LCJleHAiOjE3NjA3NDg4MTF9.NXiiJQMCmw4NCjBoyE_gADBOp8XOTGXWAAJgUjCSx7A
```

⚠️ **Expires**: 2025-10-18 00:53:31 UTC

**Test it now**:
```bash
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjI3ZGUyYzVlLTYzZDYtNDU2MC1iNmQ3LTI2MDk0NDhjZmJmNiIsImxhc3RfcGFzc3dvcmRfY2hhbmdlIjoxNzU5ODg4MzE5LCJleHAiOjE3NjA3NDg4MTF9.NXiiJQMCmw4NCjBoyE_gADBOp8XOTGXWAAJgUjCSx7A"

curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-turbo",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

---

## Option 2: Get Your Own Token (Permanent) 🔐

### Step 1: Log in to Qwen
Visit [chat.qwen.ai](https://chat.qwen.ai) and log in with your credentials.

### Step 2: Open Developer Console
Press **F12** (or right-click → Inspect → Console tab)

### Step 3: Run This JavaScript Code
Paste this into the Console and press Enter:

```javascript
javascript:(function(){if(window.location.hostname!=="chat.qwen.ai"){alert("🚀 This code is for chat.qwen.ai");window.open("https://chat.qwen.ai","_blank");return;}
function getApiKeyData(){const token=localStorage.getItem("token");if(!token){alert("❌ qwen access_token not found !!!");return null;}
return token;}
async function copyToClipboard(text){try{await navigator.clipboard.writeText(text);return true;}catch(err){console.error("❌ Failed to copy to clipboard:",err);const textarea=document.createElement("textarea");textarea.value=text;textarea.style.position="fixed";textarea.style.opacity="0";document.body.appendChild(textarea);textarea.focus();textarea.select();const success=document.execCommand("copy");document.body.removeChild(textarea);return success;}}
const apiKeyData=getApiKeyData();if(!apiKeyData)return;copyToClipboard(apiKeyData).then((success)=>{if(success){alert("🔑 Qwen access_token copied to clipboard !!! 🎉");}else{prompt("🔰 Qwen access_token:",apiKeyData);}});})();
```

### Step 4: Token Copied!
Your token is now in your clipboard! 🎉

### Step 5: Use Your Token
```bash
# Save it to environment variable
export QWEN_TOKEN="YOUR_TOKEN_HERE"

# Or use it directly in requests
curl -X POST http://localhost:8096/v1/chat/completions \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-turbo",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

---

## ✅ Verify Your Token

Test if your token is valid:

```bash
curl -X POST https://qwen.aikit.club/v1/validate \
  -H "Content-Type: application/json" \
  -d '{"token": "YOUR_TOKEN_HERE"}'
```

You should see your user info returned:
```json
{
  "id": "...",
  "email": "your-email@example.com",
  "name": "Your Name",
  "role": "user",
  "token_type": "Bearer"
}
```

---

## 🔄 Token Expiration

Qwen tokens have an expiration time (`exp` field in the JWT). When your token expires:

1. Simply repeat the process above to get a new token
2. Or visit [chat.qwen.ai](https://chat.qwen.ai) and run the JavaScript snippet again

---

## 🛡️ Security Notes

- **Never share your token** - it's like your password
- **Store it securely** in environment variables, not in code
- **Rotate tokens regularly** for better security
- **Use temporary token** only for testing/development

---

## 💡 Pro Tips

### Save Token to .env File
```bash
echo "QWEN_TOKEN=YOUR_TOKEN_HERE" >> .env
```

### Check Token Expiration
Tokens are JWT format. Decode to see expiration:
```bash
# The `exp` field shows expiration as Unix timestamp
echo "YOUR_TOKEN_HERE" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq .
```

### Auto-Refresh Script
Create a script to check and alert when token expires:
```bash
#!/bin/bash
TOKEN=$(cat .env | grep QWEN_TOKEN | cut -d'=' -f2)
EXP=$(echo "$TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq -r .exp)
NOW=$(date +%s)

if [ "$EXP" -lt "$NOW" ]; then
  echo "⚠️ Token expired! Please get a new one."
else
  HOURS=$(( ($EXP - $NOW) / 3600 ))
  echo "✅ Token valid for $HOURS more hours"
fi
```

---

## 🆘 Troubleshooting

### "Missing or invalid authorization header"
- Make sure you're sending `Authorization: Bearer YOUR_TOKEN`
- Check the token isn't expired

### "Invalid or expired Qwen token"
- Token format is wrong or expired
- Get a fresh token using the JavaScript snippet

### JavaScript snippet doesn't work
- Make sure you're on chat.qwen.ai
- Make sure you're logged in
- Try refreshing the page and running again

---

Need help? Check the [README](README.md) for more information!

