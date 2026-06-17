#!/usr/bin/env sh

if pgrep -f "title=fastfetch" > /dev/null; then
    pkill -f "title=fastfetch"
else
    ghostty --title=fastfetch --window-decoration=false --confirm-close-surface=false \
        -e sh -c 'fastfetch; read -r'
fi
