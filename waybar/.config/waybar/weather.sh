#!/usr/bin/env bash

# Weather script for Waybar - St-Sauveur, Québec
# Uses Open-Meteo API (free, no API key required)

LAT="45.8943"
LON="-74.1581"
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

# Convert degrees to arrow (pointing where wind is going)
get_wind_arrow() {
    local deg=$1
    if [ "$deg" -ge 338 ] || [ "$deg" -lt 23 ]; then echo "↓"
    elif [ "$deg" -ge 23 ] && [ "$deg" -lt 68 ]; then echo "↙"
    elif [ "$deg" -ge 68 ] && [ "$deg" -lt 113 ]; then echo "←"
    elif [ "$deg" -ge 113 ] && [ "$deg" -lt 158 ]; then echo "↖"
    elif [ "$deg" -ge 158 ] && [ "$deg" -lt 203 ]; then echo "↑"
    elif [ "$deg" -ge 203 ] && [ "$deg" -lt 248 ]; then echo "↗"
    elif [ "$deg" -ge 248 ] && [ "$deg" -lt 293 ]; then echo "→"
    elif [ "$deg" -ge 293 ] && [ "$deg" -lt 338 ]; then echo "↘"
    fi
}

# Weather icons based on WMO weather codes
get_weather_icon() {
    case $1 in
        0) echo "☀️" ;;           # Clear sky
        1|2) echo "⛅" ;;          # Mainly clear, partly cloudy
        3) echo "☁️" ;;            # Overcast
        45|48) echo "🌫️" ;;       # Fog
        51|53|55) echo "🌧️" ;;    # Drizzle
        56|57) echo "🌨️" ;;       # Freezing drizzle
        61|63|65) echo "🌧️" ;;    # Rain
        66|67) echo "🌨️" ;;       # Freezing rain
        71|73|75|77) echo "❄️" ;; # Snow
        80|81|82) echo "🌧️" ;;    # Rain showers
        85|86) echo "❄️" ;;       # Snow showers
        95|96|99) echo "⛈️" ;;    # Thunderstorm
        *) echo "🌡️" ;;
    esac
}

# Fetch weather data
API_URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m&timezone=America/Montreal"
JSON=$(curl -s --max-time 10 "$API_URL" 2>/dev/null)

# Check if curl was successful and response is valid JSON
if [ $? -eq 0 ] && [ -n "$JSON" ] && echo "$JSON" | jq -e '.current' > /dev/null 2>&1; then
    # Extract data using jq
    TEMP=$(echo "$JSON" | jq -r '.current.temperature_2m | round')
    FEELS_LIKE=$(echo "$JSON" | jq -r '.current.apparent_temperature | round')
    WIND=$(echo "$JSON" | jq -r '.current.wind_speed_10m | round')
    WIND_DEG=$(echo "$JSON" | jq -r '.current.wind_direction_10m | round')
    CODE=$(echo "$JSON" | jq -r '.current.weather_code')

    ICON=$(get_weather_icon "$CODE")
    ARROW=$(get_wind_arrow "$WIND_DEG")

    OUTPUT="${ICON} ${TEMP}°C (ressenti ${FEELS_LIKE}°C) 💨 ${ARROW}${WIND}km/h"
    echo "$OUTPUT" | tee "$CACHE_FILE"
else
    # If fetch failed, try to use cached data or show error
    if [ -f "$CACHE_FILE" ]; then
        cat "$CACHE_FILE"
    else
        echo "🌡️ --°C"
    fi
fi
