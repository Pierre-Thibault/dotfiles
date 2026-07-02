#!/usr/bin/env bash

# Weather script for Waybar
# Uses Open-Meteo API (free, no API key required)

COORDS=$(/home/pierre/nixos-config/bin/get-location)
LAT=$(echo "$COORDS" | cut -d' ' -f1)
LON=$(echo "$COORDS" | cut -d' ' -f2)

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

# Fetch weather data, retry every 30s if network is not ready
API_URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,dew_point_2m,weather_code,wind_speed_10m,wind_direction_10m&timezone=America/Montreal"

for attempt in 1 2 3 4 5; do
    JSON=$(curl -s --max-time 10 "$API_URL" 2>/dev/null)
    if [ -n "$JSON" ] && echo "$JSON" | jq -e '.current' > /dev/null 2>&1; then
        TEMP=$(echo "$JSON" | jq -r '.current.temperature_2m | round')
        DEW=$(echo "$JSON" | jq -r '.current.dew_point_2m')
        WIND=$(echo "$JSON" | jq -r '.current.wind_speed_10m | round')
        WIND_DEG=$(echo "$JSON" | jq -r '.current.wind_direction_10m | round')
        CODE=$(echo "$JSON" | jq -r '.current.weather_code')

        # Feels-like: humidex (T >= 20) or wind chill (T <= 0 and wind >= 5), Environment Canada formulas
        FEELS=$(echo "$TEMP $DEW $WIND" | awk '{
            T=$1; Td=$2; W=$3
            if (T >= 20) {
                vp = 6.105 * exp(17.27 * Td / (237.3 + Td))
                h = T + 0.5555 * (vp - 10)
                printf "(humidex %d\xc2\xb0C)", int(h + 0.5)
            } else if (T <= 0 && W >= 5) {
                wc = 13.12 + 0.6215*T - 11.37*(W^0.16) + 0.3965*T*(W^0.16)
                printf "(refroidissement %d\xc2\xb0C)", int(wc + 0.5)
            }
        }')

        ICON=$(get_weather_icon "$CODE")
        ARROW=$(get_wind_arrow "$WIND_DEG")

        if [ -n "$FEELS" ]; then
            echo "${ICON} ${TEMP}°C ${FEELS} 💨 ${ARROW}${WIND}km/h"
        else
            echo "${ICON} ${TEMP}°C 💨 ${ARROW}${WIND}km/h"
        fi
        exit 0
    fi
    [ "$attempt" -lt 5 ] && sleep 30
done

echo "🌡️ --°C"
