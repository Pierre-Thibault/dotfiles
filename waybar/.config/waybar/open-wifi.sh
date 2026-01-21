#!/usr/bin/env bash

# Open WiFi settings
# Tries different options depending on what's installed

if command -v nmtui &> /dev/null; then
    # NetworkManager TUI (terminal-based)
    kitty nmtui
elif command -v nm-connection-editor &> /dev/null; then
    # GNOME NetworkManager GUI
    nm-connection-editor &
elif command -v iwgtk &> /dev/null; then
    # iwgtk (GTK frontend for iwd)
    iwgtk &
else
    # Fallback: show an error
    notify-send "WiFi Manager" "No WiFi manager found. Install nmtui, nm-connection-editor, or iwgtk."
fi
