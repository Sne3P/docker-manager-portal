FROM node:18-alpine

# Install http-server globally
RUN npm install -g http-server

# Create demo content
RUN mkdir -p /app
WORKDIR /app

# Create a simple Node.js demo page
RUN echo '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>Node.js Demo App</title>\n\
    <style>\n\
        body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }\n\
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }\n\
        .header { color: #4CAF50; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }\n\
        .info { margin: 20px 0; padding: 15px; background: #e8f5e8; border-left: 4px solid #4CAF50; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <h1 class="header">🚀 Node.js Application Demo</h1>\n\
        <div class="info">\n\
            <strong>Status:</strong> Running successfully! ✅<br>\n\
            <strong>Container ID:</strong> <span id="hostname">Loading...</span><br>\n\
            <strong>Node Version:</strong> <span id="nodeVersion">Loading...</span><br>\n\
            <strong>Runtime:</strong> Azure Container Apps\n\
        </div>\n\
        <p>This is a demo Node.js application running in an Azure Container App.</p>\n\
        <p><strong>Features:</strong></p>\n\
        <ul>\n\
            <li>Lightweight Node.js 18 Alpine image</li>\n\
            <li>HTTP server serving static content</li>\n\
            <li>Real-time container information</li>\n\
            <li>Auto-start/stop capabilities</li>\n\
        </ul>\n\
    </div>\n\
    <script>\n\
        document.getElementById("hostname").textContent = window.location.hostname;\n\
        fetch("/api/version").catch(() => {\n\
            document.getElementById("nodeVersion").textContent = "Node.js 18+";\n\
        });\n\
    </script>\n\
</body>\n\
</html>' > /app/index.html

# Create package.json for proper Node app
RUN echo '{\n\
  "name": "nodejs-demo",\n\
  "version": "1.0.0",\n\
  "description": "Node.js Demo Application",\n\
  "main": "index.html",\n\
  "scripts": {\n\
    "start": "http-server -p 3000 ."\n\
  },\n\
  "keywords": ["nodejs", "demo", "azure"],\n\
  "author": "Container Manager",\n\
  "license": "MIT"\n\
}' > /app/package.json

EXPOSE 3000

CMD ["http-server", "-p", "3000", "."]