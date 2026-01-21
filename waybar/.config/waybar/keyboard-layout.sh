#!/usr/bin/env bash
# Get current keyboard layout from Niri
current=$(niri msg -j keyboard-layouts | jq -r '.current_idx')

case "$current" in
    0)
        echo "🇨🇦"
        ;;
    1)
        echo "🇺🇸"
        ;;
    2)
        echo "🇲🇽"
        ;;
    *)
        echo "⌨️"
        ;;
esac
