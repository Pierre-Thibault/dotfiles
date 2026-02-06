#!/usr/bin/env bash
# Get current keyboard layout from Niri
layouts=$(niri msg -j keyboard-layouts)
current=$(echo "$layouts" | jq -r '.current_idx')
name=$(echo "$layouts" | jq -r '.names[.current_idx]')

# Cache file to track changes
cache_file="/tmp/waybar-keyboard-layout-cache"

# Read previous layout
previous=""
if [ -f "$cache_file" ]; then
    previous=$(cat "$cache_file")
fi

# Save current layout
echo "$current" > "$cache_file"

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

# Add "changed" class if layout changed
class=""
if [ "$previous" != "" ] && [ "$previous" != "$current" ]; then
    class="changed"
fi

# Output JSON format for waybar with tooltip and class
echo "{\"text\":\"$icon\",\"tooltip\":\"Clavier $name\",\"class\":\"$class\"}"
