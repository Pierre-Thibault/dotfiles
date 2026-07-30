#!/usr/bin/env bash

# Waybar module: external monitor brightness via DDC/CI (ddcutil).
# DDC/CI reads are slow, so the current value is cached in a state file;
# adjustments update the cache and signal waybar for an instant refresh.
# When the display is blanked or just waking up, the DDC channel is
# unreachable for a while; in that case the module keeps showing the last
# known value instead of "?".
#
# All ddcutil calls address the bus directly (--bus) and are serialized
# with a lock: concurrent ddcutil invocations (periodic poll vs. a
# scroll/click, or another process) otherwise collide on the /dev/i2c-*
# flock and fail after a 3s timeout.

STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-brightness"
LOCK="$STATE.lock"
STEP=10
SIGNAL=8
PRESETS=(100 75 50 25)

# The i2c bus number isn't stable (a reboot/reconnect can renumber it), so
# it's resolved once via a full `ddcutil detect` (slow, ~3.5s) and cached
# like the brightness value below. The cache is invalidated on a failed
# query against it, not by time, so this stays fast on the common path.
BUS_STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-brightness-bus"

# Full bus scan to (re)find the LG UltraFine's i2c bus, matched by monitor
# name so this keeps working even if the connector changes too.
detect_bus() {
    ddcutil detect --brief 2>/dev/null | awk '
        /^Display/{bus=""}
        /I2C bus:/{bus=$3}
        /Monitor:.*LG ULTRAFINE/{if (bus != "") { print bus; exit }}
    ' | sed 's#/dev/i2c-##'
}

cached_bus() {
    [[ -f "$BUS_STATE" ]] && cat "$BUS_STATE"
}

query_hw() {
    # On lock contention, ddcutil prints its retry/flock diagnostics to
    # stdout (not stderr), so match only the actual "VCP ..." result line
    # instead of blindly taking field 4 of whatever comes through.
    local bus out
    bus=$(cached_bus)
    if [[ -n "$bus" ]]; then
        out=$(ddcutil --bus "$bus" getvcp 10 --brief 2>/dev/null | awk '/^VCP /{print $4; exit}')
    fi
    if [[ -z "$out" ]]; then
        bus=$(detect_bus)
        [[ -z "$bus" ]] && return
        echo "$bus" > "$BUS_STATE"
        out=$(ddcutil --bus "$bus" getvcp 10 --brief 2>/dev/null | awk '/^VCP /{print $4; exit}')
    fi
    [[ -n "$out" ]] && printf '%s\n' "$out"
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
    local target="$1" bus
    if (( target < 0 )); then target=0; fi
    if (( target > 100 )); then target=100; fi
    bus=$(cached_bus)
    if [[ -z "$bus" ]] || ! ddcutil --bus "$bus" setvcp 10 "$target" --noverify >/dev/null 2>&1; then
        bus=$(detect_bus)
        [[ -z "$bus" ]] && return
        echo "$bus" > "$BUS_STATE"
        ddcutil --bus "$bus" setvcp 10 "$target" --noverify >/dev/null 2>&1 || return
    fi
    echo "$target" > "$STATE"
    pkill -RTMIN+"$SIGNAL" waybar
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
