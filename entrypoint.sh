#!/usr/bin/env bash
set -ex
cd /app1 && python3 -m http.server 8080 &
cd /app2 && python3 -m http.server 80