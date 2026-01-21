#!/usr/bin/env bash

# Check current theme and display icon
CONFIG_FILE="$HOME/.config/waybar/theme-state"
DEFAULT_THEME="light"

# Get current theme
get_theme() {
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    else
        echo "$DEFAULT_THEME"
    fi
}

# Display icon based on theme
current=$(get_theme)
if [ "$current" = "light" ]; then
    echo "☀️"
else
    echo "🌙"
fi
