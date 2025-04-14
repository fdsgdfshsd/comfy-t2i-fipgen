#!/bin/bash
SNAPSHOT_DIR="/snapshot"

if [ -d "$SNAPSHOT_DIR" ] && [ -f "$SNAPSHOT_DIR/dump.log" ]; then
    echo "Snapshot found. Restoring ComfyUI state..."
    # Restore the process from the snapshot.
    criu restore -D $SNAPSHOT_DIR --shell-job
    # After restoration, immediately launch rp_handler.
    echo "State restored. Launching rp_handler..."
    python -u rp_handler.py
else
    echo "Snapshot not found. Launching ComfyUI normally..."
    # Launch ComfyUI in the background.
    python /app/ComfyUI/main.py --listen 0.0.0.0 --port 8188 &
    COMFY_PID=$!

    echo "Waiting for ComfyUI to initialize..."
    until curl -s http://127.0.0.1:8188/prompt > /dev/null; do
        echo "ComfyUI is not ready yet. Waiting 5 seconds..."
        sleep 5
    done

    echo "ComfyUI is running. Creating snapshot..."
    mkdir -p $SNAPSHOT_DIR
    # Create a dump of the ComfyUI process.
    # The --leave-running flag keeps the process running after the dump is created.
    criu dump -t $COMFY_PID -D $SNAPSHOT_DIR --shell-job --leave-running

    echo "Snapshot created. Launching rp_handler..."
    python -u rp_handler.py
fi
