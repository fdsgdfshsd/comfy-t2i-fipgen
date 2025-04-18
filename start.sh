#!/usr/bin/env bash
set -e

PORT=${PORT:-8188}

echo "[+] Launching ComfyUI..."
python /app/ComfyUI/main.py --listen 0.0.0.0 --port "${PORT}" &
COMFY_PID=$!

echo "[+] Waiting for ComfyUI to become ready..."
until curl -s http://127.0.0.1:${PORT}/prompt >/dev/null; do
    echo "    …still starting, wait 5 s"
    sleep 5
done

echo "[+] ComfyUI is ready (pid=${COMFY_PID}). Starting rp_handler."
exec python -u rp_handler.py
