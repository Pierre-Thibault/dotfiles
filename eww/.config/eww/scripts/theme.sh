#!/usr/bin/env bash
# Emit "dark" or "light" now and on every color-scheme change.
emit() { [ "$1" = "'prefer-dark'" ] && echo dark || echo light; }
emit "$(gsettings get org.gnome.desktop.interface color-scheme)"
gsettings monitor org.gnome.desktop.interface color-scheme | while read -r _ value; do
    emit "$value"
done
