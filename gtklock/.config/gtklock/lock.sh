#!/usr/bin/env sh
# Exit if gtklock binary is already running (NixOS wraps it as .gtklock-wrapped)
pgrep -f '\.gtklock-wrapped' > /dev/null && exit 0

# Run in its own scope so a crash/restart of the caller's cgroup (e.g.
# waybar.service, which has KillMode=mixed) can't SIGKILL an active lock.
systemd-run --user --scope --collect --quiet \
	gtklock -b ~/.config/background -s ~/.config/gtklock/style.css "$@"
