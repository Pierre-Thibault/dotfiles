#!/usr/bin/env sh
# Generic toggle script for applications
# Usage: toggle-app.sh <process-name> <command> [args...]

if [ $# -lt 2 ]; then
    echo "Usage: $0 <process-name> <command> [args...]"
    exit 1
fi

PROCESS_NAME="$1"
shift
COMMAND="$@"

if pgrep "$PROCESS_NAME" > /dev/null; then
    pkill "$PROCESS_NAME"
else
    $COMMAND
fi
