#!/usr/bin/env bash

# Centralized swayidle launcher
# Used by both Niri config and video-idle-manager

# Kill any existing swayidle instances first
pkill -x swayidle 2>/dev/null

# Start swayidle with your configuration
exec swayidle -w \
    timeout 300 'swaylock -f' \
    timeout 600 'systemctl suspend' \
    before-sleep 'swaylock -f' \
    after-resume "$HOME/nixos-config/bin/resume-actions.sh"
