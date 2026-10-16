#!/usr/bin/env bash
# Open/close the GNOME-like clock panel (called from waybar's clock module).

if ! eww ping >/dev/null 2>&1; then
    eww daemon >/dev/null 2>&1
    for _ in $(seq 100); do  # wait at most ~5 s
        eww ping >/dev/null 2>&1 && break
        sleep 0.05
    done
fi

if eww active-windows | grep -q '^clock-panel'; then
    eww close clock-panel
else
    # Show today's month on every opening
    ~/.config/eww/scripts/month.py today
    eww open clock-panel
fi
