#!/usr/bin/env bash

# Check current theme and display icon
scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)

if [ "$scheme" = "'prefer-dark'" ]; then
    echo "🌙"
else
    echo "☀️"
fi
