import asyncio
import time
import subprocess
import logging

from aiohttp import ClientSession, ClientTimeout
import runpod

# Настройки
TIMEOUT = 60  # Таймаут запроса (сек)
COMFY_URL = "http://127.0.0.1:8188/prompt"  # Локальный адрес ComfyUI

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def call_comfy(prompt: dict, comfy_url: str = COMFY_URL, timeout: int = TIMEOUT) -> dict:
    async with ClientSession(timeout=ClientTimeout(total=timeout)) as session:
        async with session.post(comfy_url, json=prompt) as response:
            if response.status != 200:
                error_text = await response.text()
                logger.error(f"Request failed with status {response.status}. Response: {error_text}")
                raise Exception(f"Bad request: {error_text}")
            return await response.json()

def start_comfyui() -> subprocess.Popen:
    process = subprocess.Popen(
        [
            "python",
            "main.py",
            "--listen", "0.0.0.0",
            "--port", "8188"
        ],
        cwd="/app/ComfyUI_windows_portable_nvidia/ComfyUI_windows_portable/ComfyUI"
    )
    time.sleep(10)  # Ждем инициализации ComfyUI
    return process

def handler(event: dict) -> dict:
    input_data = event.get("input", {})
    prompt = input_data.get("prompt", {})

    # Запускаем ComfyUI как фоновый процесс
    comfyui_process = start_comfyui()

    try:
        result = asyncio.run(call_comfy(prompt))
    except Exception as e:
        logger.error(f"Error calling ComfyUI: {e}")
        result = {"error": str(e)}
    finally:
        comfyui_process.terminate()

    return {"output": result}

if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
