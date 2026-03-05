#!/usr/bin/env bash

# Safe screen locker wrapper
# Prevents multiple swaylock instances from conflicting

# Kill any existing swaylock to prevent conflicts
pkill -x swaylock 2>/dev/null

# Small delay to ensure clean termination
sleep 0.1

# Start swaylock
exec swaylock -f
