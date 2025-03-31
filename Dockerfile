FROM python:3.12-slim

# Устанавливаем системные зависимости: wget, unzip, p7zip-full, git, python3-pip,
# а также пакеты, необходимые для OpenCV (libGL.so.1 и др.)
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    p7zip-full \
    git \
    python3-pip \
    ca-certificates \
    libgl1-mesa-glx \
    libxrender-dev \
    libsm6 \
    libxext6 \
    libglib2.0-0 \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Задаём рабочую директорию внутри контейнера
WORKDIR /app

# Скачиваем архив портативной сборки и распаковываем его
RUN wget -O ComfyUI_windows_portable_nvidia.7z \
    https://github.com/comfyanonymous/ComfyUI/releases/latest/download/ComfyUI_windows_portable_nvidia.7z \
    && 7z x ComfyUI_windows_portable_nvidia.7z -oComfyUI_windows_portable_nvidia \
    && rm ComfyUI_windows_portable_nvidia.7z

# Переходим в распакованную папку ComfyUI
WORKDIR /app/ComfyUI_windows_portable_nvidia/ComfyUI_windows_portable/ComfyUI

# Устанавливаем Python-зависимости из requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Добавляем установку onnxruntime для нужд insightface/node-reactor
RUN pip install --no-cache-dir onnxruntime

# Создаем каталоги для моделей, workflow, кастомных нод и настроек
RUN mkdir -p models/vae \
    models/embeddings \
    models/checkpoints \
    models/controlnet \
    models/insightface \
    models/facerestore_models \
    user/default/workflows \
    custom_nodes

# Скачиваем модели по указанным URL в соответствующие папки
RUN wget -O models/embeddings/Stable_Yogis_PDXL_Negatives2-neg.safetensors \
    https://s3.timeweb.cloud/4825a983-vq2-dev/comfy_ui_t2i_models/Stable_Yogis_PDXL_Negatives2-neg.safetensors && \
    wget -O models/embeddings/Stable_Yogis_PDXL_Positives2.safetensors \
    https://s3.timeweb.cloud/4825a983-vq2-dev/comfy_ui_t2i_models/Stable_Yogis_PDXL_Positives2.safetensors && \
    wget -O models/checkpoints/juggernautXL_juggXILightningByRD.safetensors \
    https://s3.timeweb.cloud/4825a983-vq2-dev/comfy_ui_t2i_models/juggernautXL_juggXILightningByRD.safetensors && \
    wget -O models/checkpoints/realDream_sdxlPony15.safetensors \
    https://s3.timeweb.cloud/4825a983-vq2-dev/comfy_ui_t2i_models/realDream_sdxlPony15.safetensors && \
    wget -O models/checkpoints/realismByStableYogi_v40DMD2.safetensors \
    https://s3.timeweb.cloud/4825a983-vq2-dev/comfy_ui_t2i_models/realismByStableYogi_v40DMD2.safetensors && \
    wget -O models/controlnet/OpenPoseXL2.safetensors \
    https://s3.timeweb.cloud/4825a983-vq2-dev/comfy_ui_t2i_models/OpenPoseXL2.safetensors && \
    wget -O models/insightface/inswapper_128.onnx \
    https://s3.timeweb.cloud/4825a983-vq2-dev/comfy_ui_t2i_models/inswapper_128.onnx && \
    wget -O models/facerestore_models/codeformer-v0.1.0.pth \
    https://s3.timeweb.cloud/4825a983-vq2-dev/comfy_ui_t2i_models/codeformer-v0.1.0.pth

# Клонируем кастомные ноды в папку custom_nodes
RUN cd custom_nodes && \
    git clone https://github.com/fdsgdfshsd/node-save-img-to-s3.git && \
    git clone https://github.com/fdsgdfshsd/node-load-image-from-url.git && \
    git clone https://github.com/fdsgdfshsd/node-manager.git && \
    git clone https://github.com/fdsgdfshsd/node-reactor.git && \
    git clone https://github.com/fdsgdfshsd/node-essentials.git && \
    git clone https://github.com/fdsgdfshsd/node-control-net.git && \
    git clone https://github.com/fdsgdfshsd/node-wavespeed.git

# Скачиваем настройки comfy.settings.json в папку user/default
RUN wget -O user/default/comfy.settings.json \
    https://s3.timeweb.cloud/4825a983-vq2-dev/comfy_ui_t2i_models/comfy.settings.json

RUN pip install --no-cache-dir -r requirements.txt

# Открываем порт для FastAPI (например, 8000)
EXPOSE 8000

# Запускаем стартовый скрипт
CMD ["/app/start.sh"]
