#!/usr/bin/env bash

read -r usage mem_used mem_total <<< "$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | tr -d ',')"

if [ -z "$usage" ]; then
    printf '{"text": " 🎮 N/A", "tooltip": "nvidia-smi unavailable"}\n'
    exit 0
fi

text=" 🎮 ${usage}%"
tooltip="GPU: ${usage}%\nVRAM: $((mem_used / 1024))G / $((mem_total / 1024))G"

if [ "$usage" -ge 90 ]; then class="critical"
elif [ "$usage" -ge 60 ]; then class="warm"
else class="normal"
fi

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text" "$tooltip" "$class"
