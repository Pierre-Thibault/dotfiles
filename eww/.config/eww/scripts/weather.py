#!/usr/bin/env python3
"""Print current weather and a short hourly forecast as JSON (Open-Meteo).

Main card: current position (get-location), like GNOME Weather's automatic
location. Below it, the cities saved in GNOME Weather
(dconf /org/gnome/Weather/locations), edited in the Weather app.

Same caching scheme as events.py: instant output, background refresh.
"""

import json
import os
import subprocess
import sys
import time
import urllib.request
from datetime import datetime
from pathlib import Path

from places import gnome_locations, place_name

GET_LOCATION = Path.home() / "nixos-config" / "bin" / "get-location"
CACHE = Path.home() / ".cache" / "eww" / "weather.json"
MAX_AGE = 300  # seconds
HOURS = 5  # forecast slots
STEP = 2   # hours between slots

# WMO weather codes → (icon, description)
CODES = {
    0: ("☀️", "Ciel dégagé"), 1: ("🌤️", "Plutôt dégagé"), 2: ("⛅", "Partiellement nuageux"),
    3: ("☁️", "Couvert"), 45: ("🌫️", "Brouillard"), 48: ("🌫️", "Brouillard givrant"),
    51: ("🌦️", "Bruine légère"), 53: ("🌦️", "Bruine"), 55: ("🌧️", "Bruine forte"),
    56: ("🌨️", "Bruine verglaçante"), 57: ("🌨️", "Bruine verglaçante"),
    61: ("🌧️", "Pluie légère"), 63: ("🌧️", "Pluie"), 65: ("🌧️", "Pluie forte"),
    66: ("🌨️", "Pluie verglaçante"), 67: ("🌨️", "Pluie verglaçante"),
    71: ("🌨️", "Neige légère"), 73: ("❄️", "Neige"), 75: ("❄️", "Neige forte"),
    77: ("❄️", "Grains de neige"), 80: ("🌦️", "Averses"), 81: ("🌧️", "Averses"),
    82: ("⛈️", "Averses violentes"), 85: ("🌨️", "Averses de neige"),
    86: ("❄️", "Averses de neige"), 95: ("⛈️", "Orage"), 96: ("⛈️", "Orage, grêle"),
    99: ("⛈️", "Orage, grêle"),
}


def code(c: int) -> tuple[str, str]:
    return CODES.get(c, ("🌡️", "—"))


def saved_cities() -> list[dict]:
    locs = gnome_locations("/org/gnome/Weather/locations")
    if not locs:
        return []
    url = ("https://api.open-meteo.com/v1/forecast"
           f"?latitude={','.join(str(l['lat']) for l in locs)}"
           f"&longitude={','.join(str(l['lon']) for l in locs)}"
           "&current=temperature_2m,weather_code"
           "&daily=temperature_2m_max,temperature_2m_min"
           "&timezone=auto&forecast_days=1")
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            data = json.load(r)
    except Exception:
        return []
    if isinstance(data, dict):  # a single location is not wrapped in a list
        data = [data]
    return [{
        "name": loc["name"],
        "icon": code(d["current"]["weather_code"])[0],
        "temp": f"{round(d['current']['temperature_2m'])}°",
        "range": f"{round(d['daily']['temperature_2m_min'][0])}° / "
                 f"{round(d['daily']['temperature_2m_max'][0])}°",
    } for loc, d in zip(locs, data)]


def refresh() -> None:
    try:
        lat, lon = subprocess.run([GET_LOCATION], capture_output=True, text=True,
                                  timeout=15).stdout.split()[:2]
    except (OSError, ValueError, subprocess.TimeoutExpired):
        lat, lon = "45.5", "-73.6"
    url = ("https://api.open-meteo.com/v1/forecast"
           f"?latitude={lat}&longitude={lon}"
           "&current=temperature_2m,apparent_temperature,weather_code"
           "&hourly=temperature_2m,weather_code"
           "&daily=temperature_2m_max,temperature_2m_min"
           "&timezone=auto&forecast_days=2")
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            data = json.load(r)
    except Exception:
        return  # network down: keep the last good answer

    cur = data["current"]
    icon, desc = code(cur["weather_code"])
    hourly = data["hourly"]
    now = datetime.fromisoformat(cur["time"])
    start = next(i for i, t in enumerate(hourly["time"])
                 if datetime.fromisoformat(t) > now)
    forecast = []
    for i in range(start, min(start + HOURS * STEP, len(hourly["time"])), STEP):
        forecast.append({
            "hour": datetime.fromisoformat(hourly["time"][i]).strftime("%H h"),
            "icon": code(hourly["weather_code"][i])[0],
            "temp": f"{round(hourly['temperature_2m'][i])}°",
        })
    result = json.dumps({
        "cities": saved_cities(),
        "place": place_name(lat, lon),
        "icon": icon,
        "desc": desc,
        "temp": f"{round(cur['temperature_2m'])}°C",
        "feels": f"Ressenti {round(cur['apparent_temperature'])}°",
        "range": f"{round(data['daily']['temperature_2m_min'][0])}° / "
                 f"{round(data['daily']['temperature_2m_max'][0])}°",
        "forecast": forecast,
    }, ensure_ascii=False)
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    tmp = CACHE.with_suffix(".tmp")
    tmp.write_text(result)
    tmp.replace(CACHE)
    try:
        subprocess.run(["eww", "update", f"weather={result}"], capture_output=True)
    except FileNotFoundError:
        pass


def main() -> None:
    """Print the cache now; refresh it in a detached child when stale."""
    if "--refresh" in sys.argv:
        refresh()
        return
    try:
        cached = CACHE.read_text()
        age = time.time() - CACHE.stat().st_mtime
    except OSError:
        cached, age = "{}", MAX_AGE + 1
    print(cached, flush=True)
    try:
        cached_names = [c["name"] for c in json.loads(cached).get("cities", [])]
    except (ValueError, AttributeError):
        cached_names = None
    # Refresh at once when cities were edited in GNOME Weather
    edited = cached_names != [l["name"] for l in gnome_locations("/org/gnome/Weather/locations")]
    if age > MAX_AGE or edited:
        subprocess.Popen(
            [sys.executable, os.path.abspath(__file__), "--refresh"],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


if __name__ == "__main__":
    main()
