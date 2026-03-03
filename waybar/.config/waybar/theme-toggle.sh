#!/usr/bin/env bash

# Theme toggle script for Niri
# Switches between light and dark modes with warm colors for dark mode

CONFIG_FILE="$HOME/.config/waybar/theme-state"
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
LIGHT_THEME="light"
DARK_THEME="dark"
DEFAULT_THEME="light"

# Create config directory if it doesn't exist
mkdir -p "$(dirname "$CONFIG_FILE")"

# Get current theme
get_theme() {
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    else
        echo "$DEFAULT_THEME"
    fi
}

# Save theme
set_theme() {
    echo "$1" > "$CONFIG_FILE"
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
restart_waybar() {
    (sleep 0.1 && systemctl --user restart waybar) &
    disown
}

# Apply light theme
apply_light() {
    # Switch waybar to light theme
    ln -sf "$WAYBAR_CONFIG_DIR/style-light.css" "$WAYBAR_CONFIG_DIR/style.css"

    # Save theme state BEFORE restarting waybar
    set_theme "$LIGHT_THEME"

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

    # Save theme state BEFORE restarting waybar
    set_theme "$DARK_THEME"

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
        if [ "$current" = "$LIGHT_THEME" ]; then
            apply_dark
        else
            apply_light
        fi
        ;;
    light)
        current=$(get_theme)
        if [ "$current" != "$LIGHT_THEME" ]; then
            apply_light
        fi
        ;;
    dark)
        current=$(get_theme)
        if [ "$current" != "$DARK_THEME" ]; then
            apply_dark
        fi
        ;;
    status)
        current=$(get_theme)
        if [ "$current" = "$LIGHT_THEME" ]; then
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
