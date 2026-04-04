#!/usr/bin/env python3
"""
Better You UX Mockup Server
Run: python3 serve.py
Opens: http://localhost:8765
"""
import http.server
import webbrowser
import os
import sys
from functools import partial

PORT = 8766
DIR = os.path.dirname(os.path.abspath(__file__))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIR, **kwargs)

    def log_message(self, fmt, *args):
        # Clean log — skip favicon noise
        if '404' in str(args) and 'favicon' in str(args):
            return
        path = args[0].split('"')[1] if '"' in str(args[0]) else args[0]
        print(f"  {args[1]}  {path}")

if __name__ == '__main__':
    os.chdir(DIR)
    with http.server.HTTPServer(('', PORT), Handler) as httpd:
        url = f'http://localhost:{PORT}'
        print(f'\n  Better You Mockup Server')
        print(f'  ──────────────────────────')
        print(f'  {url}')
        print(f'  Press Ctrl+C to stop\n')
        webbrowser.open(url)
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print('\n  Server stopped.')
