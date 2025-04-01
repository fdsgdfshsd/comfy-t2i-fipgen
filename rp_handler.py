import nest_asyncio
nest_asyncio.apply()

import asyncio
import json
import logging

from aiohttp import ClientSession, ClientTimeout
import runpod

# Настройки
TIMEOUT = 30  # Таймаут запроса (сек)
COMFY_URL = "http://127.0.0.1:8188/prompt"  # Локальный адрес ComfyUI

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def safe_json_loads(value):
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value
    return value

async def call_comfy(prompt: dict, comfy_url: str = COMFY_URL, timeout: int = TIMEOUT) -> dict:
    async with ClientSession(timeout=ClientTimeout(total=timeout)) as session:
        async with session.post(comfy_url, json=prompt) as response:
            if response.status != 200:
                error_text = await response.text()
                logger.error(f"Request failed with status {response.status}. Response: {error_text}")
                raise Exception(f"Bad request: {error_text}")
            return await response.json()

def handler(event: dict) -> dict:
    prompt = event.get("input", {})
    prompt = safe_json_loads(prompt)

    try:
        result = asyncio.run(call_comfy(prompt))
    except Exception as e:
        logger.error(f"Error calling ComfyUI: {e}")
        result = {"error": str(e)}

    return {"output": result}

if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
