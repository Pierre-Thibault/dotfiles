#!/usr/bin/env bash

# Safe screen locker wrapper
# Prevents multiple hyprlock instances from conflicting

# Kill any existing hyprlock to prevent conflicts
pkill -x hyprlock 2>/dev/null

# Small delay to ensure clean termination
sleep 0.1

# Start hyprlock
exec hyprlock
