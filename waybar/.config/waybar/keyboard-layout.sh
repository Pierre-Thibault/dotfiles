#!/usr/bin/env bash
# Get current keyboard layout from Niri
layouts=$(niri msg -j keyboard-layouts)
current=$(echo "$layouts" | jq -r '.current_idx')
name=$(echo "$layouts" | jq -r '.names[.current_idx]')

case "$current" in
    0)
        icon="🇨🇦"
        ;;
    1)
        icon="🇺🇸"
        ;;
    2)
        icon="🇲🇽"
        ;;
    *)
        icon="⌨️"
        ;;
esac

# Output JSON format for waybar with tooltip
echo "{\"text\":\"$icon\",\"tooltip\":\"Clavier $name\"}"
