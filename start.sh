#!/bin/bash
# Переходим в папку с ComfyUI
cd /app/ComfyUI_windows_portable_nvidia/ComfyUI_windows_portable/ComfyUI

# Запускаем ComfyUI-сервер на порту 8188 в фоне
python main.py --listen 0.0.0.0 --port 8188 &

# Небольшая задержка, чтобы дать время ComfyUI стартовать
sleep 5

# Переходим в корневую папку с FastAPI-приложением
cd /app

# Запускаем FastAPI через uvicorn на порту 8000
uvicorn app.main:app --host 0.0.0.0 --port 8000
