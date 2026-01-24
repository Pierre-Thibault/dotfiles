#!/usr/bin/env bash

# Video idle manager - Monitors systemd inhibit locks
# Automatically stops swayidle when video/media inhibitions are active

LOG_FILE="$HOME/.local/share/video-idle-manager.log"
CHECK_INTERVAL=10  # Check every 10 seconds
SWAYIDLE_LAUNCHER="$HOME/.config/waybar/start-swayidle.sh"
SWAYIDLE_RUNNING=true

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Check if media is playing via MPRIS (playerctl)
is_media_playing() {
    if command -v playerctl &> /dev/null; then
        # Check if any player is actively playing
        playerctl status 2>/dev/null | grep -q "Playing" && return 0
    fi
    return 1
}

# Check if there are active idle/sleep inhibitions (excluding swayidle itself)
has_active_inhibitions() {
    # Get list of inhibitions, exclude swayidle's own delay lock
    # Look for "block" type inhibitions on idle or sleep
    inhibits=$(systemd-inhibit --list --no-legend 2>/dev/null | \
               grep -E "(idle|sleep)" | \
               grep -v "swayidle.*delay" | \
               grep -E "block")

    if [ -n "$inhibits" ]; then
        log "Active inhibition detected: $(echo "$inhibits" | head -1)"
        return 0  # Has inhibitions
    fi

    # Check for media playback via MPRIS
    if is_media_playing; then
        log "Media playback detected via MPRIS"
        return 0
    fi

    return 1  # No inhibitions
}

# Check if swayidle is actually running
is_swayidle_running() {
    pgrep -x swayidle > /dev/null 2>&1
}

# Stop swayidle
stop_swayidle() {
    if is_swayidle_running; then
        log "Stopping swayidle (media playback detected)"
        pkill -x swayidle
        SWAYIDLE_RUNNING=false
    fi
}

# Start swayidle
start_swayidle() {
    if ! is_swayidle_running; then
        log "Starting swayidle (no media playback)"
        nohup "$SWAYIDLE_LAUNCHER" > /dev/null 2>&1 &
        SWAYIDLE_RUNNING=true
    fi
}

# Cleanup on exit
cleanup() {
    log "Script stopped"
    # Ensure swayidle is running when we exit
    if [ "$SWAYIDLE_RUNNING" = false ]; then
        start_swayidle
    fi
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

log "Video idle manager started"

# Main loop
while true; do
    if has_active_inhibitions; then
        stop_swayidle
    else
        start_swayidle
    fi

    sleep "$CHECK_INTERVAL"
done
