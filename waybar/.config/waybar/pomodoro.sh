#!/usr/bin/env bash

get_prop() {
    busctl --user get-property org.gnome.Pomodoro /org/gnome/Pomodoro \
        org.gnome.Pomodoro "$1" 2>/dev/null | awk '{print $2}' | tr -d '"'
}

STATE=$(get_prop State)

if [ -z "$STATE" ] || [ "$STATE" = "null" ]; then
    echo '{"text": " 🍅", "tooltip": "gnome-pomodoro inactif"}'
    exit 0
fi

ELAPSED=$(get_prop Elapsed)
DURATION=$(get_prop StateDuration)
PAUSED=$(get_prop IsPaused)

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

printf '{"text": " %s %d:%s", "tooltip": "%s"}\n' "$ICON" "$M" "$S" "$STATE"
