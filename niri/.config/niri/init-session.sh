#!/usr/bin/env bash

# Niri session initialization script
# This script ensures proper environment setup and service restart
# even when reconnecting to an existing Niri session

# Wait a moment for Niri to fully initialize
sleep 0.5

# Export critical environment variables to systemd user session
systemctl --user import-environment \
    WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP \
    XDG_SESSION_TYPE \
    DISPLAY \
    NIRI_SOCKET

# Also update dbus activation environment
dbus-update-activation-environment --systemd \
    WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP \
    XDG_SESSION_TYPE \
    DISPLAY \
    NIRI_SOCKET

# List of critical services to restart on reconnection
# These services need to be restarted to ensure proper functionality
CRITICAL_SERVICES=(
    "waybar.service"
    "swaync.service"
    "swayosd.service"
    "swaybg.service"
    "swayidle.service"
    "nm-applet.service"
    "blueman-applet.service"
    "copyq.service"
)

# Input-remapper requires special handling since it runs as root
# and needs to be reloaded when reconnecting to Niri
if grep -r "046D" /sys/class/input/mouse*/device/uevent 2>/dev/null >/dev/null; then
    echo "Logitech mouse detected, reloading input-remapper mappings..."
    input-remapper-control --command autoload 2>/dev/null &
fi

# Restart all critical services to ensure they work after reconnection
for service in "${CRITICAL_SERVICES[@]}"; do
    echo "Restarting $service..."
    systemctl --user restart "$service" 2>/dev/null || systemctl --user start "$service"
done

# Setting screen temperature
pkill gammastep 2>/dev/null || true
nohup gammastep -l 45.9:-74.2 -b 1:0.7 -t 6500:3000 >/dev/null 2>&1 &
disown

# Give services a moment to fully start
sleep 0.5

echo "Niri session initialized successfully"
