#!/usr/bin/env bash

get_prop() {
    busctl --user get-property org.gnome.Pomodoro /org/gnome/Pomodoro \
        org.gnome.Pomodoro "$1" 2>/dev/null | awk '{print $2}' | tr -d '"'
}

# Marks that caffeine was turned on by this script, so we only turn it back
# off if we're the ones who turned it on (don't override a manual enable).
CAFFEINE_STATE="$HOME/.cache/caffeine-state"
CAFFEINE_MARKER="$HOME/.cache/caffeine-pomodoro-managed"

release_caffeine() {
    if [ -f "$CAFFEINE_MARKER" ]; then
        ~/.config/waybar/caffeine-toggle.sh disable
        rm -f "$CAFFEINE_MARKER"
    fi
}

claim_caffeine() {
    if [ ! -f "$CAFFEINE_STATE" ]; then
        ~/.config/waybar/caffeine-toggle.sh enable
        touch "$CAFFEINE_MARKER"
    fi
}

STATE=$(get_prop State)

if [ -z "$STATE" ] || [ "$STATE" = "null" ]; then
    release_caffeine
    echo '{"text": "🍅", "tooltip": "gnome-pomodoro inactif"}'
    exit 0
fi

ELAPSED=$(get_prop Elapsed)
DURATION=$(get_prop StateDuration)
PAUSED=$(get_prop IsPaused)  # Is the countdown stopped?

if [ "$PAUSED" = "true" ]; then
    release_caffeine
else
    claim_caffeine
fi

REMAINING=$(awk "BEGIN {print int($DURATION - $ELAPSED)}")
M=$((REMAINING / 60))
S=$(printf "%02d" $((REMAINING % 60)))

case "$STATE" in
    pomodoro)    ICON="🍅" ;;
    short-break) ICON="☕" ;;
    long-break)  ICON="🛋" ;;
    *)           ICON="🍅" ;;
esac

[ "$PAUSED" = "true" ] && ICON="⏸ $ICON"

printf '{"text": "%s %d:%s", "tooltip": "%s"}\n' "$ICON" "$M" "$S" "$STATE"
