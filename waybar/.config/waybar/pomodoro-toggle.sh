#!/usr/bin/env bash
WINDOW_ID=$(niri msg -j windows 2>/dev/null \
    | grep -o '"id":[0-9]*,"title":"[^"]*","app_id":"gnome-pomodoro"' \
    | grep -o '[0-9]*' | head -1)

if [ -n "$WINDOW_ID" ]; then
    niri msg action focus-window --id "$WINDOW_ID"
    niri msg action close-window
else
    gtk-launch org.gnome.Pomodoro
fi
