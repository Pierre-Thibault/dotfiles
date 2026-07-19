#!/usr/bin/env bash

# Waybar module: external monitor brightness via DDC/CI (ddcutil).
# DDC/CI reads are slow, so the current value is cached in a state file;
# adjustments update the cache and signal waybar for an instant refresh.
# When the display is blanked or just waking up, the DDC channel is
# unreachable for a while; in that case the module keeps showing the last
# known value instead of "?".
#
# All ddcutil calls address the bus directly (--bus) and are serialized
# with a lock: waybar gets restarted on every theme change (morning and
# evening), and concurrent ddcutil invocations across a restart otherwise
# collide on the /dev/i2c-* flock and fail after a 3s timeout.

STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-brightness"
LOCK="$STATE.lock"
STEP=10
SIGNAL=8
PRESETS=(100 75 50 25)

# /dev/i2c-7, from `ddcutil detect` (LG UltraFine on HDMI). Addressing the
# bus directly skips the ~3.5s full bus detection and its long lock window.
# Re-run `ddcutil detect` if the display or its connector ever changes.
BUS=7

query_hw() {
    ddcutil --bus "$BUS" getvcp 10 --brief 2>/dev/null | awk '{print $4}'
}

cache_fresh() {
    [[ -f "$STATE" ]] && (( $(date +%s) - $(stat -c %Y "$STATE") <= 240 ))
}

status() {
    local b=""
    if cache_fresh; then
        b=$(cat "$STATE")
    else
        # Never wait on the bus here: if another ddcutil holds the lock,
        # skip the query and fall back to the cached value below.
        b=$(
            exec 9>"$LOCK"
            flock -n 9 || exit 0
            query_hw
        )
        if [[ -n "$b" ]]; then
            echo "$b" > "$STATE"
        else
            b=$(cat "$STATE" 2>/dev/null)
        fi
    fi
    if [[ -z "$b" ]]; then
        printf '{"text":"🔆 ?","tooltip":"Écran injoignable (DDC/CI)"}\n'
        return
    fi
    printf '{"text":"🔆 %s%%","tooltip":"Luminosité : %s %%\\nMolette : ±%s %%\\nClic : 100 → 75 → 50 → 25"}\n' \
        "$b" "$b" "$STEP"
}

# Callers must hold the lock on fd 9.
apply() {
    local target="$1"
    if (( target < 0 )); then target=0; fi
    if (( target > 100 )); then target=100; fi
    if ddcutil --bus "$BUS" setvcp 10 "$target" --noverify >/dev/null 2>&1; then
        echo "$target" > "$STATE"
        pkill -RTMIN+"$SIGNAL" waybar
    fi
}

# Print the current value while holding the lock: fresh cache, else
# hardware, else stale cache as a last resort.
current_locked() {
    local value
    if cache_fresh; then
        cat "$STATE"
        return
    fi
    value=$(query_hw)
    [[ -z "$value" ]] && value=$(cat "$STATE" 2>/dev/null)
    echo "$value"
}

adjust() {
    local delta="$1" current
    exec 9>"$LOCK"
    flock 9
    current=$(current_locked)
    [[ -z "$current" ]] && exit 1
    apply $(( current + delta ))
}

# Jump to the next preset below the current level, wrapping back to 100.
cycle() {
    local current p target=""
    exec 9>"$LOCK"
    flock 9
    current=$(current_locked)
    [[ -z "$current" ]] && exit 1
    for p in "${PRESETS[@]}"; do
        if (( p < current )); then
            target=$p
            break
        fi
    done
    [[ -z "$target" ]] && target=100
    apply "$target"
}

case "${1:-}" in
    status) status ;;
    up)     adjust "$STEP" ;;
    down)   adjust "-$STEP" ;;
    cycle)  cycle ;;
    set)
        exec 9>"$LOCK"
        flock 9
        apply "${2:?usage: $0 set <0-100>}"
        ;;
    *)
        echo "Usage: $0 {status|up|down|cycle|set <0-100>}"
        exit 1
        ;;
esac
