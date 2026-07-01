#!/usr/bin/env bash

find_hwmon() {
    for dir in /sys/class/hwmon/hwmon*/; do
        [ "$(cat "${dir}name" 2>/dev/null)" = "$1" ] && echo "$dir" && return
    done
}

read_temp() {
    local raw
    raw=$(cat "${1}temp1_input" 2>/dev/null) || return
    echo $(( raw / 1000 ))
}

cpu=$(read_temp "$(find_hwmon k10temp)")
gpu=$(read_temp "$(find_hwmon amdgpu)")
nvme=$(read_temp "$(find_hwmon nvme)")
wifi=$(read_temp "$(find_hwmon iwlwifi_1)")

text=" 󰍛 🌡️ ${cpu}°C"
tooltip="CPU:  ${cpu}°C\nGPU:  ${gpu}°C\nNVMe: ${nvme}°C\nWiFi: ${wifi}°C"

if [ "$cpu" -ge 85 ]; then class="critical"
elif [ "$cpu" -ge 70 ]; then class="warm"
elif [ "$cpu" -ge 50 ]; then class="normal"
else class="cool"
fi

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text" "$tooltip" "$class"
