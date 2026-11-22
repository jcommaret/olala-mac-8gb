"""Mini serveur local : sert la page de chat et relaie /api/chat vers mlx_engine.server.

Usage : python3 serve.py   (variables : OLALA_PORT, UI_PORT, MLX_ENGINE_API_KEY)
"""
import json
import os
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
UPSTREAM = f"http://127.0.0.1:{os.environ.get('OLALA_PORT', '8000')}"
API_KEY = os.environ.get("MLX_ENGINE_API_KEY", "une-cle")
UI_PORT = int(os.environ.get("UI_PORT", "8080"))


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def _upstream(self, method, path, body=None):
        req = urllib.request.Request(
            UPSTREAM + path,
            data=body,
            method=method,
            headers={
                "Authorization": f"Bearer {API_KEY}",
                "Content-Type": "application/json",
            },
        )
        return urllib.request.urlopen(req, timeout=600)

    def _json(self, status, obj):
        data = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            data = (HERE / "index.html").read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        elif self.path == "/api/health":
            try:
                with self._upstream("GET", "/health") as r:
                    self._json(200, json.loads(r.read()))
            except Exception as e:
                self._json(503, {"status": "down", "error": str(e)})
        else:
            self._json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/api/chat":
            self._json(404, {"error": "not found"})
            return
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        try:
            upstream = self._upstream("POST", "/v1/chat/completions", body)
        except urllib.error.HTTPError as e:
            self._json(e.code, json.loads(e.read() or b"{}"))
            return
        except Exception as e:
            self._json(503, {"error": {"message": f"Serveur Olala injoignable : {e}"}})
            return
        # HTTP/1.0 : pas de Content-Length, la fin du flux = fermeture de la connexion.
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        try:
            with upstream:
                while chunk := upstream.read1(65536):
                    self.wfile.write(chunk)
                    self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            pass  # l'utilisateur a cliqué sur Stop


if __name__ == "__main__":
    print(f"Page de chat : http://127.0.0.1:{UI_PORT}  (serveur Olala : {UPSTREAM})")
    ThreadingHTTPServer(("127.0.0.1", UI_PORT), Handler).serve_forever()
