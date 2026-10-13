#!/usr/bin/env bash
# Open Tecla on the layout of the current window, while still letting the
# layout be changed afterwards (Tecla follows the keymap of its own window).

# Layout of the window focused before Tecla opens
current=$(niri msg -j keyboard-layouts | jq -r '.current_idx')

tecla &

# With track-layout "window", Tecla's window gets its own layout: wait until
# it is focused, then give it the previous window's layout.
for _ in $(seq 50); do
    if niri msg -j focused-window | jq -e '.app_id == "org.gnome.Tecla"' >/dev/null; then
        niri msg action switch-layout "$current"
        exit 0
    fi
    sleep 0.1
done
