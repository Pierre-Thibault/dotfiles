#!/usr/bin/env bash
COORDS=$(get-location)
LAT=$(echo "$COORDS" | cut -d' ' -f1)
LON=$(echo "$COORDS" | cut -d' ' -f2)
exec redland --lat="$LAT" --lon="$LON" --low=2250
