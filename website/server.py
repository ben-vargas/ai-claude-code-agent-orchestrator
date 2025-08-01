#!/usr/bin/env python3

import http.server
import socketserver
import os
import webbrowser
from datetime import datetime

PORT = 8000

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        print(f"[{datetime.now().strftime('%H:%M:%S')}] {format % args}")

os.chdir(os.path.dirname(os.path.abspath(__file__)))

print("\n🎭 Claude Code Agent Orchestrator - Landing Page")
print("=" * 50)
print(f"\n✅ Development server starting on port {PORT}")
print(f"\n🌐 Open your browser to:")
print(f"   http://localhost:{PORT}\n")
print("📱 Features to test:")
print("   • Dark/light mode toggle (top right)")
print("   • Mobile responsive design (resize window)")
print("   • Agent cards hover effects")
print("   • Smooth scroll navigation")
print("   • Interactive pricing tables")
print("\n⌨️  Press Ctrl+C to stop the server\n")
print("-" * 50)

with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
    # Optionally open browser
    # webbrowser.open(f'http://localhost:{PORT}')
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped")
        pass