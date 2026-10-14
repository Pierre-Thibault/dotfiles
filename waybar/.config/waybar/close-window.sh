#!/usr/bin/env bash
# Emit waybar JSON for the close button: greyed out when no window is focused

niri msg --json event-stream | jq --unbuffered -r '
  if .WindowsChanged then (.WindowsChanged.windows | any(.is_focused))
  elif .WindowFocusChanged then (.WindowFocusChanged.id != null)
  else empty end' |
while read -r focused; do
  if [ "$focused" = true ]; then
    echo '{"text":"❌","class":"active"}'
  else
    echo '{"text":"❌","class":"empty"}'
  fi
done
