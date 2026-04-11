#!/usr/bin/env bash

# Mouse handedness toggle for Waybar
# Toggles left-handed mode in Niri's config.kdl and reloads

NIRI_CONFIG="$HOME/.config/niri/config.kdl"

is_left_handed() {
    grep -q '^\s*left-handed$' "$NIRI_CONFIG" 2>/dev/null
}

toggle() {
    if is_left_handed; then
        # Remove left-handed from mouse block
        sed -i '/^\s*left-handed$/d' "$NIRI_CONFIG"
        notify-send -t 3000 "🖱️ Souris droitier" "Boutons en mode droitier"
    else
        # Add left-handed inside mouse block, after the opening brace
        sed -i '/^\s*mouse {/a\        left-handed' "$NIRI_CONFIG"
        notify-send -t 3000 "🖱️ Souris gaucher" "Boutons en mode gaucher"
    fi

}

status() {
    if is_left_handed; then
        echo '{"text": "🫲🖱️", "tooltip": "Souris gaucher — Cliquez pour passer en droitier", "class": "left-handed"}'
    else
        echo '{"text": "🖱️🫱", "tooltip": "Souris droitier — Cliquez pour passer en gaucher", "class": "right-handed"}'
    fi
}

case "${1:-status}" in
    toggle)
        toggle
        status
        ;;
    status|*)
        status
        ;;
esac
