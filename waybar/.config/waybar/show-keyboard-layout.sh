#!/usr/bin/env bash
# Show visual keyboard layout for current Niri layout

# Get current keyboard layout from Niri
layouts=$(niri msg -j keyboard-layouts)
current=$(echo "$layouts" | jq -r '.current_idx')
name=$(echo "$layouts" | jq -r '.names[.current_idx]')

# Map layout names to specific visualization URLs
case "$current" in
    0)
        # Canadian (CSA) - Microsoft interactive layout
        url="https://learn.microsoft.com/en-us/globalization/keyboards/kbdcan"
        ;;
    1)
        # English (US) - kbdlayout.info
        url="http://kbdlayout.info/kbdus"
        ;;
    2)
        # Spanish (Latin American) - kbdlayout.info
        url="http://kbdlayout.info/KBDLA"
        ;;
    *)
        # Default to comparison tool
        url="https://www.farah.cl/Keyboardery/A-Visual-Comparison-of-Different-National-Layouts/"
        ;;
esac

# Open in browser
xdg-open "$url" &
