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

# Apply light theme
apply_light() {
    # Increase brightness to 100%
    brightnessctl set 100% 2>/dev/null || true

    # Switch waybar to light theme
    ln -sf "$WAYBAR_CONFIG_DIR/style-light.css" "$WAYBAR_CONFIG_DIR/style.css"
    pkill waybar
    sleep 0.2
    waybar > /dev/null 2>&1 &

    # Remove warm color filter
    pkill wlsunset 2>/dev/null || true

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
}

# Apply dark theme with warm colors and reduced brightness
apply_dark() {
    # Reduce brightness to 70% for reduced strain
    brightnessctl set 70% 2>/dev/null || true

    # Switch waybar to dark theme
    ln -sf "$WAYBAR_CONFIG_DIR/style-dark.css" "$WAYBAR_CONFIG_DIR/style.css"
    pkill waybar
    sleep 0.2
    waybar > /dev/null 2>&1 &

    # Apply warm color filter for evening (reduce blue light)
    pkill wlsunset 2>/dev/null || true
    nohup wlsunset -l 45.9 -L -74.2 -t 3000 -T 6500 >/dev/null 2>&1 &
    disown

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
}

# Main logic
case "$1" in
    toggle)
        current=$(get_theme)
        if [ "$current" = "$LIGHT_THEME" ]; then
            apply_dark
            set_theme "$DARK_THEME"
        else
            apply_light
            set_theme "$LIGHT_THEME"
        fi
        ;;
    light)
        current=$(get_theme)
        if [ "$current" != "$LIGHT_THEME" ]; then
            apply_light
            set_theme "$LIGHT_THEME"
        fi
        ;;
    dark)
        current=$(get_theme)
        if [ "$current" != "$DARK_THEME" ]; then
            apply_dark
            set_theme "$DARK_THEME"
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
