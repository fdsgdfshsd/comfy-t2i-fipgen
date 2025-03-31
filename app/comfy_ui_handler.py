import requests

def run_comfy_ui(prompt):
    # Предположим, что ComfyUI-сервер слушает на http://127.0.0.1:8188 и принимает POST-запросы по /prompt
    url = "http://127.0.0.1:8188/prompt"
    response = requests.post(url, json={"prompt": prompt})
    if response.status_code != 200:
        raise Exception(f"ComfyUI error: {response.text}")
    return response.json()
