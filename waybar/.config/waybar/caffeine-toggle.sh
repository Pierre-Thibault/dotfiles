#!/usr/bin/env bash

# Caffeine toggle for Waybar
# Click to enable/disable idle inhibition

STATE_FILE="$HOME/.cache/caffeine-state"
PID_FILE="$HOME/.cache/caffeine-pid"

disable() {
    if [ -f "$STATE_FILE" ]; then
        # Kill Wayland idle inhibitor
        if [ -f "$PID_FILE" ]; then
            kill "$(cat "$PID_FILE")" 2>/dev/null
            rm -f "$PID_FILE"
        fi
        rm -f "$STATE_FILE"
    fi
}

enable() {
    if [ ! -f "$STATE_FILE" ]; then
        # Hold Wayland idle inhibitor — hypridle stays running but its timeouts are blocked
        wlinhibit &
        echo $! > "$PID_FILE"
        touch "$STATE_FILE"
    fi
}

toggle() {
    if [ -f "$STATE_FILE" ]; then
        disable
        notify-send -t 5000 "💤 Caffeine désactivé" "Le verrouillage automatique est réactivé"
    else
        enable
        notify-send -t 5000 "☕ Caffeine activé" "Le verrouillage automatique est désactivé"
    fi
}

status() {
    if [ -f "$STATE_FILE" ]; then
        # Active - show enabled state
        echo '{"text": "☕", "tooltip": "Caffeine activé - Cliquez pour désactiver", "class": "caffeine-on"}'
    else
        # Inactive - show disabled state
        echo '{"text": "💤", "tooltip": "Caffeine désactivé - Cliquez pour activer", "class": "caffeine-off"}'
    fi
}

case "${1:-status}" in
    toggle)
        toggle
        status
        ;;
    disable)
        disable
        ;;
    enable)
        enable
        ;;
    status|*)
        status
        ;;
esac
