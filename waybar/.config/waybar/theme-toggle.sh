#!/usr/bin/env bash

# Theme toggle script for Niri
# Switches between light and dark modes with warm colors for dark mode

WAYBAR_CONFIG_DIR="$HOME/.config/waybar"

# Get current theme from gsettings
get_theme() {
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
    if [ "$scheme" = "'prefer-dark'" ]; then
        echo "dark"
    else
        echo "light"
    fi
}

# Emit D-Bus signal for theme change (freedesktop portal mechanism)
# This is what GNOME uses and what apps listen to
emit_theme_change() {
    local scheme="$1"  # 0 = prefer-light, 1 = prefer-dark
    
    dbus-send --print-reply --session \
        /org/freedesktop/portal/desktop \
        org.freedesktop.portal.Settings.SettingChanged \
        string:"org.freedesktop.appearance" \
        string:"color-scheme" \
        "variant:uint32:$scheme" 2>/dev/null || true
}

# Restart waybar in a detached process (so it doesn't kill this script)
# Only restart if waybar is currently running (respect manual stops)
restart_waybar() {
    if systemctl --user is-active --quiet waybar; then
        (sleep 0.1 && systemctl --user restart waybar) &
        disown
    fi
}

# Apply light theme
apply_light() {
    # Switch waybar to light theme
    ln -sf "$WAYBAR_CONFIG_DIR/style-light.css" "$WAYBAR_CONFIG_DIR/style.css"

    # Update GNOME settings (color-scheme: 0 = prefer-light)
    gsettings set org.gnome.desktop.interface color-scheme prefer-light 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-mode false 2>/dev/null || true

    # Call user's theme configuration script
    if [ -x "$HOME/nixos-config/bin/set-light-theme" ]; then
        "$HOME/nixos-config/bin/set-light-theme" 2>/dev/null || true
    fi

    # Emit D-Bus signal for apps listening to theme changes
    emit_theme_change 0

    echo "☀️"

    # Restart waybar last (detached)
    restart_waybar
}

# Apply dark theme with warm colors and reduced brightness
apply_dark() {
    # Switch waybar to dark theme
    ln -sf "$WAYBAR_CONFIG_DIR/style-dark.css" "$WAYBAR_CONFIG_DIR/style.css"

    # Update GNOME settings (color-scheme: 1 = prefer-dark)
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-mode true 2>/dev/null || true

    # Call user's theme configuration script
    if [ -x "$HOME/nixos-config/bin/set-dark-theme" ]; then
        "$HOME/nixos-config/bin/set-dark-theme" 2>/dev/null || true
    fi

    # Emit D-Bus signal for apps listening to theme changes
    emit_theme_change 1

    echo "🌙"

    # Restart waybar last (detached)
    restart_waybar
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
