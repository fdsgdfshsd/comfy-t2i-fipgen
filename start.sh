#!/usr/bin/env bash
set -e

SNAPSHOT_DIR="/snapshot"
PORT="${PORT:-8188}"

# ─────────────────────────────────────────────────────────────────────────────
if [[ -f "${SNAPSHOT_DIR}/dump.log" ]]; then
    echo "[+] Snapshot found, restoring..."
    criu restore -D "${SNAPSHOT_DIR}" --shell-job
    exit
fi

echo "[+] Launching ComfyUI..."
python /app/ComfyUI/main.py --listen 0.0.0.0 --port "${PORT}" &
PID=$!

echo "[+] Waiting for UI to become ready..."
until curl -s "http://127.0.0.1:${PORT}/prompt" >/dev/null; do
    sleep 2
done
echo "    UI is up (pid=${PID})"

echo "[+] Creating snapshot..."
mkdir -p "${SNAPSHOT_DIR}"
criu dump -t "${PID}" -D "${SNAPSHOT_DIR}" --shell-job --leave-running

echo "[+] Dump complete. ComfyUI continues to run."
wait "${PID}"
