#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import socket
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse

class CustomHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/' or self.path == '/index.html':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            
            hostname = socket.gethostname()
            
            html_content = f"""<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Python Demo App</title>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 40px; background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 50%, #fecfef 100%); min-height: 100vh; }}
        .container {{ background: white; padding: 40px; border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.1); max-width: 800px; margin: 0 auto; }}
        .header {{ color: #2c3e50; border-bottom: 3px solid #e74c3c; padding-bottom: 15px; margin-bottom: 30px; }}
        .status {{ background: linear-gradient(45deg, #e74c3c, #c0392b); color: white; padding: 20px; border-radius: 8px; margin: 20px 0; }}
        .info {{ background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #e74c3c; }}
        .code {{ background: #2c3e50; color: #ecf0f1; padding: 15px; border-radius: 5px; font-family: 'Courier New', monospace; }}
        .footer {{ margin-top: 30px; color: #7f8c8d; font-size: 0.9em; text-align: center; }}
        .badge {{ background: #f39c12; color: white; padding: 4px 8px; border-radius: 12px; font-size: 0.8em; }}
        h1 {{ margin: 0; font-size: 2.5em; }}
        h3 {{ color: #2c3e50; margin-top: 0; }}
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🐍 Python Web Server <span class="badge">DEMO</span></h1>
        
        <div class="status">
            <h3>✅ Status: Serveur Python Actif</h3>
            <p>Application Python deployee avec succes sur Azure Container Apps</p>
        </div>
        
        <div class="info">
            <h3>📊 Informations Runtime</h3>
            <ul>
                <li><strong>Hostname:</strong> {hostname}</li>
                <li><strong>Python Version:</strong> 3.11+</li>
                <li><strong>Serveur:</strong> HTTP Server Built-in</li>
                <li><strong>Port:</strong> 8000</li>
                <li><strong>Status:</strong> Fonctionnel</li>
            </ul>
        </div>

        <div class="info">
            <h3>🔧 Fonctionnalites Python</h3>
            <ul>
                <li>Serveur HTTP natif Python</li>
                <li>Support Unicode/UTF-8 complet</li>
                <li>Gestion des requetes HTTP</li>
                <li>Environnement Alpine Linux optimise</li>
            </ul>
        </div>

        <div class="info">
            <h3>💻 Code Server</h3>
            <div class="code">
from http.server import HTTPServer, SimpleHTTPRequestHandler<br>
# Serveur Python simple et efficace<br>
server = HTTPServer(('0.0.0.0', 8000), CustomHandler)<br>
server.serve_forever()
            </div>
        </div>

        <div class="footer">
            <p><strong>Portail Cloud Container - Service Python</strong></p>
            <p>Genere le: <span id="timestamp"></span></p>
        </div>
    </div>

    <script>
        document.getElementById('timestamp').textContent = new Date().toLocaleString('fr-FR');
    </script>
</body>
</html>"""
            
            self.wfile.write(html_content.encode('utf-8'))
        else:
            super().do_GET()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    server = HTTPServer(('0.0.0.0', port), CustomHandler)
    print(f"🐍 Python server starting on port {port}")
    server.serve_forever()