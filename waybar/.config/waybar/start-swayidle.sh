#!/usr/bin/env bash

# Centralized swayidle launcher
# Used by Niri config

# Kill any existing swayidle instances first
pkill -x swayidle 2>/dev/null

# Start swayidle with your configuration
exec swayidle -w \
    timeout 285 "notify-send -u critical -t 15000 -i ~/.config/waybar/caution_4539472.png '🔒 Verrouillage imminent' 'L՚écran se verrouillera dans 15 secondes'" \
    resume 'swaync-client -C' \
    timeout 300 'swaylock -f' \
    timeout 600 'systemctl suspend' \
    before-sleep 'swaylock -f' \
    after-resume "$HOME/nixos-config/bin/resume-actions.sh"
