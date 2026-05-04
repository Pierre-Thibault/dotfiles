#!/usr/bin/env bash

# Caffeine toggle for Waybar
# Click to enable/disable idle inhibition

STATE_FILE="$HOME/.cache/caffeine-state"

disable() {
    rm -f "$STATE_FILE"
}

enable() {
    touch "$STATE_FILE"
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
        echo '{"text": "☕", "tooltip": "Caffeine activé - Cliquez pour désactiver", "class": "caffeine-on"}'
    else
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
