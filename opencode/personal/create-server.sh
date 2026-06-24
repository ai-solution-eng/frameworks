#!/usr/bin/env python3

import sys
import os
import subprocess

def create_server(url, port):
    target = url
    if os.path.isfile(target):
        target = os.path.dirname(target)
    cmd = ["python3", "-m", "http.server", str(port), "--directory", target]
    print(f"Running: {' '.join(cmd)}")
    subprocess.run(cmd)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <url> <port>")
        print("  e.g. ./create-server.sh /workspace/web-apps/demo-confetti-francesco.html 8000")
        sys.exit(1)
    create_server(sys.argv[1], sys.argv[2])