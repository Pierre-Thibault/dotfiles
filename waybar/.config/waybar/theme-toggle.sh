#!/usr/bin/env bash

# Theme toggle script for Niri.
# Thin dispatcher: all theme side effects live in
# ~/nixos-config/bin/set-{light,dark}-theme. Waybar reloads its CSS by
# itself when the color-scheme changes (portal signal), no restart needed.

# Get current theme from gsettings
get_theme() {
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
    if [ "$scheme" = "'prefer-dark'" ]; then
        echo "dark"
    else
        echo "light"
    fi
}

apply_light() {
    if [ -x "$HOME/nixos-config/bin/set-light-theme" ]; then
        "$HOME/nixos-config/bin/set-light-theme" 2>/dev/null || true
    fi
    echo "☀️"
}

apply_dark() {
    if [ -x "$HOME/nixos-config/bin/set-dark-theme" ]; then
        "$HOME/nixos-config/bin/set-dark-theme" 2>/dev/null || true
    fi
    echo "🌙"
}

# Main logic
case "$1" in
    toggle)
        current=$(get_theme)
        if [ "$current" = "light" ]; then
            apply_dark
        else
            apply_light
        fi
        ;;
    light)
        current=$(get_theme)
        if [ "$current" != "light" ]; then
            apply_light
        fi
        ;;
    dark)
        current=$(get_theme)
        if [ "$current" != "dark" ]; then
            apply_dark
        fi
        ;;
    status)
        current=$(get_theme)
        if [ "$current" = "light" ]; then
            echo "☀️"
        else
            echo "🌙"
        fi
        ;;
    *)
        echo "Usage: $0 {toggle|light|dark|status}"
        exit 1
        ;;
esac
