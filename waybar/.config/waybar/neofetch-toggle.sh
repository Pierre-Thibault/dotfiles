#!/usr/bin/env sh

if pgrep -f "title=neofetch" > /dev/null; then
    pkill -f "title=neofetch"
else
    ghostty --title=neofetch --window-decoration=false --confirm-close-surface=false \
        -e sh -c 'neofetch; read -r'
fi
