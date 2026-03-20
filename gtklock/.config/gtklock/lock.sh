#!/usr/bin/env sh
# Exit if gtklock binary is already running (NixOS wraps it as .gtklock-wrapped)
pgrep -f '\.gtklock-wrapped' > /dev/null && exit 0
gtklock -b ~/.config/background -s ~/.config/gtklock/style.css "$@"
