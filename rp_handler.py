# rp_handler.py
import nest_asyncio
nest_asyncio.apply()

import runpod
import requests
import json
import os
import time
import asyncio
import aiohttp
from aiohttp import ClientSession
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

################################################################################
# Константы для ожидания
################################################################################
S3_TIMEOUT_SEC = 300       # Общее время ожидания появления файла на S3 (сек)
S3_POLL_INTERVAL = 1.0     # Интервал опроса (сек)
MIN_FILESIZE = 1000        # Порог байт, чтобы считать «файл появился»


################################################################################
# Основная функция handler, вызываемая RunPod
################################################################################
def handler(event: dict) -> dict:
    """
    Ожидает структуру:
    {
      "prompt": {...},
      "s3_settings": {
        "endpoint": "...",
        "bucket": "...",
        "folder": "...",
        "filename": "..."
      }
    }
    """
    # 1) Забираем "prompt" как есть
    prompt_data = event.get("prompt")
    if not prompt_data:
        return {"error": "No 'prompt' field in the incoming event"}

    # 2) Забираем s3_settings
    s3_data = event.get("s3_settings", {})
    s3_endpoint = s3_data.get("endpoint", "https://example-s3.com")
    s3_bucket = s3_data.get("bucket", "my-bucket")
    s3_folder = s3_data.get("folder", "my-folder")
    filename = s3_data.get("filename", "generated_image.png")

    # 3) Отправляем payload в ComfyUI
    #    Важно, что ComfyUI ждёт JSON вида:
    #    { "prompt": { ... } }
    #    А не { "70": {...}, ... } без верха "prompt".
    comfy_payload = {"prompt": prompt_data}
    comfy_url = "http://127.0.0.1:8188/prompt"

    try:
        resp = requests.post(comfy_url, json=comfy_payload)
        resp.raise_for_status()
        logger.info(f"ComfyUI response: {resp.json()}")
    except Exception as e:
        logger.error(f"Error sending prompt to ComfyUI: {e}")
        return {"error": str(e)}

    # 4) Формируем s3_url и ждём, пока файл появится
    s3_url = f"{s3_endpoint}/{s3_bucket}/{s3_folder}/{filename}"
    logger.info(f"Will wait for file to appear on S3: {s3_url}")

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    file_ok = loop.run_until_complete(wait_for_file_on_s3(s3_url, S3_TIMEOUT_SEC))
    if not file_ok:
        return {
            "status": "error",
            "message": f"File not found on S3 within {S3_TIMEOUT_SEC} seconds",
            "s3_url": s3_url
        }

    # 5) Скачиваем файл и возвращаем base64
    try:
        base64_img = loop.run_until_complete(download_file_as_base64(s3_url))
    except Exception as e:
        logger.error(f"Error downloading file from S3: {e}")
        return {"error": f"Error downloading from S3: {str(e)}"}

    return {
        "status": "success",
        "s3_url": s3_url,
        "base64": base64_img
    }


################################################################################
# Функции для poll'а S3 и скачивания
################################################################################
async def wait_for_file_on_s3(url: str, timeout: float) -> bool:
    """
    Периодически делает HEAD-запрос к url, пока не увидит файл нужного размера (MIN_FILESIZE).
    Возвращает True, если дождались; False, если по таймауту файл так и не появился.
    """
    start_time = time.time()
    while time.time() - start_time < timeout:
        size = await get_file_size(url)
        if size >= MIN_FILESIZE:
            return True
        await asyncio.sleep(S3_POLL_INTERVAL)
    return False


async def get_file_size(url: str) -> int:
    """
    HEAD-запрос к S3. Если статус 200 и есть Content-Length,
    возвращаем его как int. Иначе 0.
    """
    try:
        async with ClientSession() as session:
            async with session.head(url) as resp:
                if resp.status == 200:
                    cl = resp.headers.get("Content-Length")
                    if cl:
                        return int(cl)
    except Exception as e:
        logger.debug(f"HEAD error: {e}")
    return 0


async def download_file_as_base64(url: str) -> str:
    """
    GET-запрос к S3, скачиваем файл в память, кодируем в base64.
    """
    import base64
    async with ClientSession() as session:
        async with session.get(url) as resp:
            if resp.status != 200:
                txt = await resp.text()
                raise Exception(f"GET {url} failed {resp.status}: {txt}")
            data = await resp.read()
    return base64.b64encode(data).decode("utf-8")

################################################################################
# Точка входа
################################################################################
if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
