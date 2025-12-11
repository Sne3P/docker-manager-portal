FROM python:3.11-alpine

# Create demo content
RUN mkdir -p /app
WORKDIR /app

# Create a simple Python web server demo
RUN echo '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
    <title>Python Demo App</title>\n\
    <style>\n\
        body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }\n\
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }\n\
        .header { color: #306998; border-bottom: 2px solid #306998; padding-bottom: 10px; }\n\
        .info { margin: 20px 0; padding: 15px; background: #e8f4fd; border-left: 4px solid #306998; }\n\
    </style>\n\
</head>\n\
<body>\n\
    <div class="container">\n\
        <h1 class="header">🐍 Python Application Demo</h1>\n\
        <div class="info">\n\
            <strong>Status:</strong> Running successfully! ✅<br>\n\
            <strong>Container ID:</strong> <span id="hostname">Loading...</span><br>\n\
            <strong>Python Version:</strong> 3.11+<br>\n\
            <strong>Runtime:</strong> Azure Container Apps\n\
        </div>\n\
        <p>This is a demo Python application running in an Azure Container App.</p>\n\
        <p><strong>Features:</strong></p>\n\
        <ul>\n\
            <li>Python 3.11 Alpine image</li>\n\
            <li>Built-in HTTP server</li>\n\
            <li>Lightweight and fast</li>\n\
            <li>Auto-start/stop capabilities</li>\n\
        </ul>\n\
    </div>\n\
    <script>\n\
        document.getElementById("hostname").textContent = window.location.hostname;\n\
    </script>\n\
</body>\n\
</html>' > /app/index.html

EXPOSE 8080

CMD ["python3", "-m", "http.server", "8080"]