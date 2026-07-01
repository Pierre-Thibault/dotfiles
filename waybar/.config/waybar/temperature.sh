#!/usr/bin/env bash

read_temp() {
    local raw
    raw=$(cat "$1" 2>/dev/null) || return
    echo $(( raw / 1000 ))
}

cpu=$(read_temp /sys/class/hwmon/hwmon1/temp1_input)
gpu=$(read_temp /sys/class/hwmon/hwmon3/temp1_input)
nvme=$(read_temp /sys/class/hwmon/hwmon0/temp1_input)
wifi=$(read_temp /sys/class/hwmon/hwmon2/temp1_input)

text=" 󰍛 🌡️ ${cpu}°C"
tooltip="CPU:  ${cpu}°C\nGPU:  ${gpu}°C\nNVMe: ${nvme}°C\nWiFi: ${wifi}°C"

if [ "$cpu" -ge 85 ]; then class="critical"
elif [ "$cpu" -ge 70 ]; then class="warm"
elif [ "$cpu" -ge 50 ]; then class="normal"
else class="cool"
fi

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text" "$tooltip" "$class"
