#!/usr/bin/env bash

# Weather script for Waybar - St-Sauveur, Québec
# Uses wttr.in API (no API key required)

CITY="St-Sauveur,Quebec"
CACHE_FILE="/tmp/waybar_weather_cache"
CACHE_DURATION=1800  # 30 minutes in seconds

# Check if cache exists and is recent
if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
    if [ $CACHE_AGE -lt $CACHE_DURATION ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Fetch weather data
# Format: %c = weather condition, %t = temperature, %f = feels like, %w = wind
WEATHER=$(curl -s "wttr.in/${CITY}?format=%c+%t+(ressenti+%f)+💨+%w" 2>/dev/null)

# Check if curl was successful
if [ $? -eq 0 ] && [ -n "$WEATHER" ]; then
    echo "$WEATHER" | tee "$CACHE_FILE"
else
    # If fetch failed, try to use cached data or show error
    if [ -f "$CACHE_FILE" ]; then
        cat "$CACHE_FILE"
    else
        echo "🌡️ --°C"
    fi
fi
