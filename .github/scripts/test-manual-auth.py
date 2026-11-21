"""Exercise the installed gpclient and gpauth against a local SAML portal."""

import base64
import os
import re
import subprocess
import threading
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

PAGE = b"<html>Test sign-in</html>"
CALLBACK = base64.b64encode(
    b"<html><!-- <saml-auth-status>1</saml-auth-status>"
    b"<prelogin-cookie>test-cookie</prelogin-cookie>"
    b"<saml-username>tester</saml-username> --></html>"
)


class Portal(BaseHTTPRequestHandler):
    def do_POST(self):
        form = parse_qs(self.rfile.read(int(self.headers["Content-Length"])))
        if self.path.endswith("/prelogin.esp"):
            policy = self.server.browser_policy
            request = base64.b64encode(PAGE).decode()
            body = (
                "<prelogin-response><status>Success</status><region>test</region>"
                f"<saml-auth-method>POST</saml-auth-method><saml-request>{request}</saml-request>"
                f"<saml-default-browser>{policy}</saml-default-browser></prelogin-response>"
            ).encode()
            self.send_response(200)
        else:
            if self.path.endswith("/getconfig.esp") and b"test-cookie" in form.get(b"prelogin-cookie", []):
                self.server.received_cookie.set()
            # Authentication is complete once gpclient presents the callback credential.
            body = b"End of test"
            self.send_response(403)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


with ThreadingHTTPServer(("127.0.0.1", 0), Portal) as server:
    server.received_cookie = threading.Event()
    threading.Thread(target=server.serve_forever, daemon=True).start()
    command = [
        "gpclient", "connect", f"http://127.0.0.1:{server.server_port}", "--cookie-only",
        "--browser", "manual", "--browser-listen", "127.0.0.1",
    ]
    os.environ["no_proxy"] = "127.0.0.1"
    os.environ.pop("DISPLAY", None)
    os.environ.pop("WAYLAND_DISPLAY", None)

    server.browser_policy = "no"
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    assert result.returncode and b"not built with the `webview-auth` feature" in result.stdout, result.stdout

    server.browser_policy = "yes"
    with subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT) as client:
        for line in client.stdout:
            print(line.decode(errors="replace"), end="", flush=True)
            match = re.fullmatch(rb"http://127\.0\.0\.1:\d+/[^\s]+", line.strip())
            if match:
                with urllib.request.urlopen(match[0].decode(), timeout=5) as response:
                    assert response.read() == PAGE
                client.stdin.write(b"globalprotectcallback:" + CALLBACK + b"\n")
                client.stdin.flush()
                break
        client.communicate()
    assert server.received_cookie.is_set(), "gpclient did not present the manual sign-in cookie"
    server.shutdown()
