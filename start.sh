#!/bin/bash
echo "Starting ComfyUI..."
# Запускаем ComfyUI из нативного репозитория (не Windows portable!)
python /app/ComfyUI/main.py --listen 0.0.0.0 --port 8188 &

echo "Waiting for ComfyUI to initialize..."
until curl -s http://127.0.0.1:8188/prompt > /dev/null; do
    echo "ComfyUI not ready yet. Waiting 5 seconds..."
    sleep 5
done

echo "ComfyUI is up. Launching rp_handler..."
python -u rp_handler.py
