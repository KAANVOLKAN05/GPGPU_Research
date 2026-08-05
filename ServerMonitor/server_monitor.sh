#!/usr/bin/env bash
#In order to kill it you must run the following 2 lines
#pgrep -af 'nvidia-smi.*--loop'
#kill PID

OUTPUT_FILE="gpu_stats.csv"
INTERVAL=300
nohup nvidia-smi \
    --query-gpu=timestamp,index,uuid,temperature.gpu,power.draw \
    --format=csv,noheader \
    --loop=$INTERVAL \
    >> "$OUTPUT_FILE" \
    2>/dev/null &

echo "monitoring started, in order to stop you must use kill PID"
