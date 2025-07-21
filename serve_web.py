#!/usr/bin/env python3
"""
Simple web server for Flutter web app
Serves the web directory with proper MIME types for Flutter assets
"""

import http.server
import socketserver
import os
import webbrowser
from urllib.parse import urlparse

class FlutterWebHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="web", **kwargs)
    
    def end_headers(self):
        # Add CORS headers for development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        
        # Add proper MIME types for Flutter assets
        if self.path.endswith('.js'):
            self.send_header('Content-Type', 'application/javascript')
        elif self.path.endswith('.wasm'):
            self.send_header('Content-Type', 'application/wasm')
        elif self.path.endswith('.json'):
            self.send_header('Content-Type', 'application/json')
        
        super().end_headers()
    
    def do_GET(self):
        # Serve index.html for all routes (SPA routing)
        if self.path == '/' or not os.path.exists(os.path.join("web", self.path.lstrip('/'))):
            self.path = '/index.html'
        return super().do_GET()

def main():
    PORT = 8080
    
    print(f"""
🚀 Starting Flutter Web Development Server
📂 Serving from: web/
🌐 Server URL: http://localhost:{PORT}
    
Press Ctrl+C to stop the server
""")
    
    with socketserver.TCPServer(("", PORT), FlutterWebHandler) as httpd:
        try:
            print(f"Server running at http://localhost:{PORT}")
            # Try to open browser automatically
            try:
                webbrowser.open(f'http://localhost:{PORT}')
            except:
                pass
            
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped")

if __name__ == "__main__":
    main()