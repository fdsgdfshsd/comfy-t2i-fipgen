#!/bin/bash
echo "Starting ComfyUI..."
python /app/ComfyUI_windows_portable_nvidia/ComfyUI_windows_portable/ComfyUI/main.py --listen 0.0.0.0 --port 8188 &

echo "Waiting for ComfyUI to initialize..."
# Ждем, пока API не станет доступен (проверяем каждые 5 секунд)
until curl -s http://127.0.0.1:8188/prompt > /dev/null; do
    echo "ComfyUI not ready yet. Waiting 5 seconds..."
    sleep 5
done

echo "ComfyUI is up. Launching rp_handler..."
python -u rp_handler.py
