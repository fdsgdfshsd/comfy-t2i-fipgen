#!/usr/bin/env bash
set -e

PORT=${PORT:-8188}

echo "[+] Launching ComfyUI on port ${PORT}..."
python /app/ComfyUI/main.py --listen 0.0.0.0 --port "${PORT}" &
PID=$!

echo "[+] ComfyUI started (pid=${PID}). Press Ctrl+C to stop."
wait "${PID}"
