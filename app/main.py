from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from comfy_ui_handler import run_comfy_ui

app = FastAPI()

class PromptRequest(BaseModel):
    prompt: dict  # или str – в зависимости от вашей логики

@app.post("/prompt")
async def prompt_endpoint(request: PromptRequest):
    try:
        # В данном примере мы пересылаем запрос к локальному ComfyUI-серверу
        result = run_comfy_ui(request.prompt)
        return {"result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
