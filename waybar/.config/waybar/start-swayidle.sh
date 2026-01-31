#!/usr/bin/env bash

# Centralized swayidle launcher
# Used by Niri config

# Kill any existing swayidle instances first
pkill -x swayidle 2>/dev/null

# Start swayidle with your configuration
exec swayidle -w \
    timeout 570 "notify-send -u critical -t 30000 -i ~/.config/waybar/caution_4539472.png '🔒 Verrouillage imminent' 'L՚écran se verrouillera dans 30 secondes'" \
    resume 'swaync-client -C' \
    timeout 600 'swaylock -f' \
    timeout 900 'systemctl suspend' \
    before-sleep 'swaylock -f' \
    after-resume "$HOME/nixos-config/bin/resume-actions.sh"
