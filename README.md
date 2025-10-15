# Z.AI2API - OpenAI-Compatible Multi-Provider API Gateway

<div align="center">

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://www.docker.com/)

**Unified OpenAI-compatible API gateway supporting multiple AI providers with unlimited scalability via FlareProx**

[Features](#features) • [Quick Start](#quick-start) • [Docker Deploy](#docker-deployment) • [FlareProx](#flareprox-integration) • [API Docs](#api-documentation)

</div>

---

## 🎯 Features

- ✅ **OpenAI-Compatible API** - Drop-in replacement for OpenAI API
- 🔄 **Multi-Provider Support** - Z.AI, K2Think, Qwen (45+ models total)
- 🚀 **Unlimited Scalability** - FlareProx integration for IP rotation via Cloudflare Workers
- 🐳 **Docker Ready** - One-command deployment with docker-compose
- ⚡ **High Performance** - Async/await, streaming support
- 🔐 **Secure** - Environment-based configuration
- 📊 **Comprehensive** - Tool calling, thinking mode, search, multimodal

---

## 📦 Supported Providers & Models

| Provider | Models | Features |
|----------|--------|----------|
| **Qwen** | 35+ | qwen-max/plus/turbo/long + variants (thinking, search, image, video, deep-research) |


---

## 🚀 Quick Start

### 🎯 Option 1: One-Command Auto Deploy (Recommended)

**The fastest way to get started!** This script handles everything automatically:

```bash
# Download and run
curl -fsSL https://raw.githubusercontent.com/Zeeeepa/qwen-api/main/autodeploy.sh -o autodeploy.sh
chmod +x autodeploy.sh
./autodeploy.sh
```

**What it does:**
- ✅ Checks prerequisites (Python 3.10+, git, pip)
- ✅ Collects credentials interactively
- ✅ Clones repository
- ✅ Sets up environment
- ✅ Installs dependencies
- ✅ Starts server
- ✅ Validates with API test
- ✅ Continues running server

📖 **Full documentation:** [AUTODEPLOY.md](./AUTODEPLOY.md)

---

### 🛠️ Option 2: Manual Installation

### Prerequisites

- Python 3.10+
- Provider credentials (Qwen)
- (Optional) Cloudflare account for FlareProx unlimited scalability

### Installation

```bash
# Clone repository
git clone https://github.com/Zeeeepa/qwen-api.git
cd qwen-api

# Install package in development mode
export QWEN_EMAIL=developer@pixelium.uk
export QWEN_PASSWORD=<PasswordFromEnvironmentVariables>
# Or 
nano .env 
QWEN_EMAI=developer@pixelium.uk
QWEN_PASSWORD=<PasswordFromEnvironmentVariables>
# Then proceed setupping and starting server + sending real open ai api request.
bash scripts/setup.sh
bash scripts/start.sh
bash scripts/send_request.sh
bash scripts/all.sh 


## 📖 API Documentation

### Base URL
```
http://localhost:8080
```

## 🔐 Authentication

All API requests require a Bearer token containing your Qwen credentials.

### Getting Your Qwen Token


USE PLAYWRIGHT TO LOG IN TO QWEN account 

Login: "https://chat.qwen.ai/auth?action=signin"

To use in setup.sh step set qwen email and password to log in-> and then properly use this JS code to copy token ->
```javascript
javascript:(function(){if(window.location.hostname!=="chat.qwen.ai"){alert("🚀 This code is for chat.qwen.ai");window.open("https://chat.qwen.ai","_blank");return;}
function getApiKeyData(){const token=localStorage.getItem("token");if(!token){alert("❌ qwen access_token not found !!!");return null;}
return token;}
async function copyToClipboard(text){try{await navigator.clipboard.writeText(text);return true;}catch(err){console.error("❌ Failed to copy to clipboard:",err);const textarea=document.createElement("textarea");textarea.value=text;textarea.style.position="fixed";textarea.style.opacity="0";document.body.appendChild(textarea);textarea.focus();textarea.select();const success=document.execCommand("copy");document.body.removeChild(textarea);return success;}}
const apiKeyData=getApiKeyData();if(!apiKeyData)return;copyToClipboard(apiKeyData).then((success)=>{if(success){alert("🔑 Qwen access_token copied to clipboard !!! 🎉");}else{prompt("🔰 Qwen access_token:",apiKeyData);}});})();
```
AFTER TOKEN IS COPIED -> IT SHOULD BE PASTED INTO .env file and saved. 


### Using Authentication

Include the Bearer token in all requests:
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_QWEN_TOKEN" \
  -d '{
    "model": "qwen-turbo",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": false
  }'
```

THIS TO BE IMPLEMENTED WITH PLAYWRIGHT.
```javascript
javascript:(function(){if(window.location.hostname!=="chat.qwen.ai"){alert("🚀 This code is for chat.qwen.ai");window.open("https://chat.qwen.ai","_blank");return;}
function getApiKeyData(){const token=localStorage.getItem("token");if(!token){alert("❌ qwen access_token not found !!!");return null;}
return token;}
async function copyToClipboard(text){try{await navigator.clipboard.writeText(text);return true;}catch(err){console.error("❌ Failed to copy to clipboard:",err);const textarea=document.createElement("textarea");textarea.value=text;textarea.style.position="fixed";textarea.style.opacity="0";document.body.appendChild(textarea);textarea.focus();textarea.select();const success=document.execCommand("copy");document.body.removeChild(textarea);return success;}}
const apiKeyData=getApiKeyData();if(!apiKeyData)return;copyToClipboard(apiKeyData).then((success)=>{if(success){alert("🔑 Qwen access_token copied to clipboard !!! 🎉");}else{prompt("🔰 Qwen access_token:",apiKeyData);}});})();
```


### Supported Features

- ✅ **Streaming** - `"stream": true`
- ✅ **Thinking Mode** - Use models with `-thinking` suffix
- ✅ **Search** - Use models with `-search` suffix
- ✅ **Tool Calling** - `"tools": [...]`
- ✅ **Multimodal** - Images, video (model-dependent)
- ✅ **Temperature & Parameters** - `temperature`, `max_tokens`, `top_p`





## 🔗 Links

### API documentation : https://qwen-api.readme.io/

- **Spec file**: `qwen.json` (OpenAPI 3.1.0)
- **What it is**: OpenAPI-ready API documentation covering all endpoints, OpenAI-compatible request/response shapes, security, and examples.
- **How to use**:
  - Import `qwen.json` into Swagger UI, Redocly, Postman, Bruno, or Insomnia.
  - Generate typed clients with your preferred tool (e.g., `openapi-generator`, `orval`).
- **Servers**: Defaults to `https://qwen.aikit.club`; you can change the `host` variable or edit the server URL after import.

## 🚀 Key Features

| Feature                     | Description                                               |
| --------------------------- | --------------------------------------------------------- |
| 🔁 **OpenAI Compatibility** | Drop-in replacement for OpenAI API calls                  |
| 💬 **Chat Completions**     | Text-based conversations with all Qwen models             |
| 🎨 **Image Generation**     | Create stunning images from text prompts                  |
| ✏️ **Image Editing**        | Modify existing images with text instructions             |
| 🎬 **Video Generation**     | Transform text into video content                         |
| 🔬 **Deep Research**        | Comprehensive research with web search and citations      |
| 👨🏻‍💻 **Web Development**      | Generate interactive web components and UI elements       |
| 🏗️ **Full-Stack Apps**      | Complete application development from frontend to backend |
| 🔍 **Web Search**           | Enable web search capabilities in conversations           |
| 🧠 **Thinking Mode**        | Activate reasoning mode for complex problem solving       |
| 👁️ **Vision Support**       | Analyze images, PDFs, and visual content                  |
| 📁 **Multimodal Files**     | Support for image, audio, video, and document uploads     |
| 🌍 **CORS Support**         | Full cross-origin resource sharing support                |
| ⚡ **Edge Performance**     | Lightning-fast global deployment via Cloudflare Workers   |

## 🛠️ Supported Endpoints

| Endpoint                 | Method      | Description           |
| ------------------------ | ----------- | --------------------- |
| `/v1/validate`           | GET/POST    | Validate token        |
| `/v1/refresh`            | GET/POST    | Refresh token         |
| `/v1/models`             | GET         | List available models |
| `/v1/chat/completions`   | POST        | Chat completions      |
| `/v1/images/generations` | POST        | Generate images       |
| `/v1/images/edits`       | POST        | Edit existing images  |
| `/v1/videos/generations` | POST        | Generate videos       |
| `/v1/chats/delete`       | DELETE/POST | Delete all chats      |

## 🧠 Model Capabilities

| Model Name                 | 👁️ Vision | 💡 Reasoning | 🌐 Web Search | 🔧 Tool Calling |
| -------------------------- | --------- | ------------ | ------------- | --------------- |
| QVQ-Max                    | ✅        | ✅           | ❌            | ❌              |
| Qwen-Deep-Research         | ❌        | ✅           | ❌            | ❌              |
| Qwen2.5-Max                | ✅        | ✅           | ✅            | ❌              |
| Qwen3-Next-80B-A3B         | ✅        | ✅           | ✅            | ❌              |
| Qwen2.5-Plus               | ✅        | ✅           | ✅            | ❌              |
| Qwen2.5-Turbo              | ✅        | ✅           | ✅            | ❌              |
| Qwen2.5-14B-Instruct-1M    | ✅        | ✅           | ✅            | ❌              |
| Qwen2.5-72B-Instruct       | ✅        | ✅           | ❌            | ❌              |
| Qwen2.5-Coder-32B-Instruct | ✅        | ✅           | ✅            | ❌              |
| Qwen2.5-Omni-7B            | ✅        | ❌           | ✅            | ❌              |
| Qwen2.5-VL-32B-Instruct    | ✅        | ✅           | ✅            | ❌              |
| Qwen3-235B-A22B-2507       | ✅        | ✅           | ✅            | ❌              |
| Qwen3-30B-A3B-2507         | ✅        | ✅           | ✅            | ❌              |
| Qwen3-Coder                | ✅        | ❌           | ✅            | ✅              |
| Qwen3-Coder-Flash          | ✅        | ❌           | ✅            | ❌              |
| Qwen-Web-Dev               | ✅        | ❌           | ❌            | ❌              |
| Qwen-Full-Stack            | ✅        | ❌           | ❌            | ❌              |
| Qwen3-Max                  | ✅        | ❌           | ✅            | ❌              |
| Qwen3-Omni-Flash           | ✅        | ✅           | ❌            | ❌              |
| Qwen3-VL-235B-A22B         | ✅        | ✅           | ❌            | ❌              |
| Qwen3-VL-30B-A3B           | ✅        | ✅           | ❌            | ❌              |
| QWQ-32B                    | ❌        | ✅           | ✅            | ❌              |

## 🚀 Quick Start
### Use the Public Instance
The public instance is available at: `https://qwen.aikit.club`


```javascript
const headers = {
  Authorization: "Bearer YOUR_QWEN_ACCESS_TOKEN",
  "Content-Type": "application/json",
};
```

4. **Use the Token**: The copied token is now ready to use as your `Bearer` token in API requests

**Important Notes:**

- ⚠️ This script only works on chat.qwen.ai - make sure you're logged in
- 🔒 Keep your token secure - it provides access to your Qwen account
- 🔄 You may need to regenerate the token periodically if it expires


### Validate Token (from JS snippet)

Validate the access token produced by the browser JS snippet above.

```bash
curl -X POST https://qwen.aikit.club/validate \
  -H "Content-Type: application/json" \
  -d '{"token": "YOUR_QWEN_ACCESS_TOKEN"}'
```

```bash
curl "https://qwen.aikit.club/validate?token=YOUR_QWEN_ACCESS_TOKEN"
```

### Chat Completions

```javascript
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen-max-latest",
    messages: [{ role: "user", content: "Hello, how are you?" }],
    stream: false,
  }),
});
```

### Image Generation

```javascript
const response = await fetch("https://qwen.aikit.club/v1/images/generations", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    prompt: "A beautiful sunset over mountains",
    size: "1024x1024",
  }),
});
```

### Image Editing

```javascript
// Using FormData for file upload
const formData = new FormData();
formData.append("image", imageFile); // File object
formData.append("prompt", "Change the sky to a starry night");

const response = await fetch("https://qwen.aikit.club/v1/images/edits", {
  method: "POST",
  headers: {
    Authorization: "Bearer YOUR_QWEN_ACCESS_TOKEN",
  },
  body: formData,
});

// Or using JSON with image URL/base64
const response = await fetch("https://qwen.aikit.club/v1/images/edits", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    image: "https://example.com/image.jpg", // or base64 data URL
    prompt: "Add a rainbow in the background",
  }),
});
```

### Web Search Mode

```javascript
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen-max-latest",
    messages: [{ role: "user", content: "What are the latest AI developments?" }],
    tools: [{ type: "web_search" }],
  }),
});
```

### Thinking Mode

```javascript
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen-max-latest",
    messages: [{ role: "user", content: "Solve this complex math problem: ..." }],
    enable_thinking: true,
    thinking_budget: 30000,
  }),
});
```

### Code Generation (qwen3-coder-plus)

Note: `qwen3-coder-plus` supports [Qwen Code](https://github.com/QwenLM/qwen-code) — a coding agent that operates in digital environments and can issue function/tool calls. This API supports handling the function calls produced by the agent.

```javascript
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen3-coder-plus",
    tools: [{ type: "code" }],
    messages: [
      { role: "user", content: "Write a JavaScript function to add two numbers" },
    ],
    stream: true,
  }),
});
```

### Video Generation

```javascript
const response = await fetch("https://qwen.aikit.club/v1/videos/generations", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    prompt: "A cat playing with a ball of yarn in slow motion",
    size: "1280x720",
  }),
});
```

### Deep Research

```javascript
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen-deep-research",
    messages: [
      {
        role: "user",
        content: "Research the latest developments in quantum computing",
      },
    ],
    stream: false,
  }),
});
```

### Web Development (qwen-web-dev)

The `qwen-web-dev` model is specialized for frontend web development, creating interactive web components, HTML/CSS/JavaScript code, and providing live preview capabilities.

**Features:**

- HTML/CSS/JavaScript code generation
- Interactive UI components
- Responsive design support
- Real-time preview generation
- Framework support: React, Vue, Vanilla JS, HTML5
- Styling: Tailwind CSS, Bootstrap

```javascript
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen-web-dev",
    messages: [
      {
        role: "user",
        content:
          "Create a responsive navigation bar with a logo, menu items, and a mobile hamburger menu using HTML, CSS, and vanilla JavaScript",
      },
    ],
    stream: false,
  }),
});
```

**Example Output:**
The model will generate complete, production-ready web components with:

- Clean, semantic HTML structure
- Modern CSS with responsive breakpoints
- Vanilla JavaScript for interactivity
- Mobile-first design approach
- Accessibility considerations

### Full-Stack Development (qwen-full-stack)

The `qwen-full-stack` model handles complete application development, from frontend to backend, database design, API development, and system architecture.

**Features:**

- Frontend and backend code generation
- Database schema design
- RESTful and GraphQL API development
- Authentication and authorization
- Microservices architecture
- Deployment-ready code
- Multi-language support: JavaScript, TypeScript, Python, Java, Go, PHP
- Frameworks: React, Vue, Angular, Node.js, Express, Django, Flask, Spring Boot

```javascript
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen-full-stack",
    messages: [
      {
        role: "user",
        content:
          "Create a complete REST API for a task management system with user authentication, CRUD operations for tasks, and a React frontend. Use Node.js/Express for the backend and MongoDB for the database.",
      },
    ],
    stream: false,
  }),
});
```

**Example Full-Stack Application:**

```javascript
// Advanced example: Building a complete blog platform
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen-full-stack",
    messages: [
      {
        role: "user",
        content: `Build a complete blog platform with the following requirements:

Backend (Node.js/Express):
- User authentication with JWT
- CRUD operations for blog posts
- Comment system
- Like/bookmark functionality
- Image upload support
- RESTful API endpoints

Frontend (React):
- Home page with post listings
- Post detail page with comments
- Create/Edit post interface
- User profile page
- Responsive design with Tailwind CSS

Database (MongoDB):
- User schema with authentication
- Post schema with relationships
- Comment schema
- Proper indexing for performance`,
      },
    ],
    stream: false,
  }),
});
```

**Key Differences:**

| Feature          | qwen-web-dev                               | qwen-full-stack                    |
| ---------------- | ------------------------------------------ | ---------------------------------- |
| **Focus**        | Frontend UI/UX                             | Complete application stack         |
| **Code Output**  | HTML, CSS, JavaScript                      | Frontend + Backend + Database      |
| **Use Cases**    | Web components, landing pages, UI elements | Complete apps, APIs, microservices |
| **Complexity**   | Simple to moderate                         | Moderate to complex                |
| **Architecture** | Client-side only                           | Full system architecture           |

### Delete All Chats

```javascript
// Using DELETE method
const response = await fetch("https://qwen.aikit.club/v1/chats/delete", {
  method: "DELETE", // GET and POST are also supported
  headers: headers,
});
```

## 📁 Multimodal File Support

The API supports various file formats for comprehensive multimodal interactions:

> **⚠️ Important Limitation**: Multiple inputs of the same modality category are not supported. **Image, Audio, and Video** are considered the same category (media files), while **Documents** (PDF, TXT, etc.) are a separate category. You can combine different categories (e.g., image + PDF) but cannot combine files within the same category (e.g., image + video).

### Supported File Types

- **Media Files** _(same category)_:
  - **Images**: **JPG, PNG, GIF, WebP** _(most common)_, BMP, TIFF, ICO, ICNS, JFIF, JP2
  - **Audio**: **MP3, WAV, M4A, AAC** _(most common)_, AMR
  - **Video**: **MP4, MOV, AVI, MKV** _(most common)_, WMV, FLV
- **Documents** _(separate category)_: **PDF, TXT, MD** _(most common)_, DOC, DOCX, CSV, XLS, XLSX

> **💡 Tip**: Bold formats are the most commonly used and recommended for best compatibility.

### 📏 File Limits

The following limits apply to multimodal file uploads:

| File Type | Max Size (MB) | Max Count | Max Duration (seconds) |
|-----------|---------------|-----------|------------------------|
| **Images** | 10 | 5 | - |
| **Audio** | 100 | 1 | 180 |
| **Video** | 500 | 1 | 600 |
| **Documents** | 20 | 5 | - |
| **Default** | 20 | - | - |

> **📋 Summary**: You can upload up to 5 images (10MB each), 1 audio file (100MB, 3 minutes), 1 video file (500MB, 10 minutes), or 5 documents (20MB each) per request.

### ✅ Valid Combinations

- ✅ Multiple images
- ✅ Image + PDF
- ✅ Audio + PDF
- ✅ Video + PDF
- ✅ Single image/audio/video only

### ❌ Invalid Combinations

- ❌ Image + Audio
- ❌ Image + Video
- ❌ Audio + Video
- ❌ Multiple videos
- ❌ Multiple audio files

### Vision-Style Multimodal Chat

```javascript
// Analyze any supported file type using standard chat completions
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen-max-latest",
    messages: [
      {
        role: "user",
        content: [
          { type: "text", text: "What do you see in this image?" },
          {
            type: "image_url",
            image_url: {
              url: "https://download.samplelib.com/png/sample-hut-400x300.png",
              // or use base64: "data:image/jpeg;base64,..."
            },
          },
        ],
      },
    ],
  }),
});
```

### Valid Multimodal Combination (Image + PDF)

```javascript
// ✅ VALID: Combine different categories (Media + Document)
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen-max-latest",
    messages: [
      {
        role: "user",
        content: [
          { type: "text", text: "Analyze this image and PDF document together" },
          {
            type: "image_url",
            image_url: { url: "https://download.samplelib.com/png/sample-hut-400x300.png" },
          },
          {
            type: "file_url",
            file_url: { url: "https://pdfobject.com/pdf/sample.pdf" },
          },
        ],
      },
    ],
  }),
});
```

### ❌ Invalid Combinations (Don't Do This)

```javascript
// ❌ INVALID: Cannot combine image + video (same category)
const response = await fetch("https://qwen.aikit.club/v1/chat/completions", {
  method: "POST",
  headers: headers,
  body: JSON.stringify({
    model: "qwen-max-latest",
    messages: [
      {
        role: "user",
        content: [
          { type: "text", text: "This will not work properly" },
          {
            type: "image_url",
            image_url: { url: "https://download.samplelib.com/png/sample-hut-400x300.png" },
          },
          {
            type: "video_url",
            video_url: { url: "https://download.samplelib.com/mp4/sample-10s.mp4" },
          },
          // ❌ Cannot mix media files (image, audio, video)
        ],
      },
    ],
  }),
});
```