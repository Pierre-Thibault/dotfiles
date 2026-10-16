"""Shared helpers: read GNOME locations from dconf, resolve names and zones.

GNOME stores locations as serialized GWeatherLocation variants:
    (uint32 2, <('Name', 'ICAO', bool, [(lat, lon)], [(lat, lon)])>)
with coordinates in radians (station first, then parent city) and no
time zone, so the zone is looked up once per location and cached.
"""

import json
import math
import re
import subprocess
import time
import urllib.request
from pathlib import Path

CACHE_DIR = Path.home() / ".cache" / "eww"
NAMES = CACHE_DIR / "place.json"
ZONES = CACHE_DIR / "tz.json"
USER_AGENT = "eww-clock-panel/1.0 (personal desktop widget)"

_LOCATION = re.compile(
    r"""\(\s*(?P<q>['"])(?P<name>.*?)(?P=q),\s*'[^']*',\s*(?:true|false),\s*"""
    r"""\[(?P<station>[^\]]*)\],\s*(?:@a\(dd\)\s*)?\[(?P<city>[^\]]*)\]\s*\)""")
_COORD = re.compile(r"\(\s*([-\d.e]+),\s*([-\d.e]+)\s*\)")
_last_nominatim = 0.0


def gnome_locations(key: str) -> list[dict]:
    """Locations stored under a dconf key, e.g. /org/gnome/clocks/world-clocks."""
    try:
        raw = subprocess.run(["dconf", "read", key], capture_output=True,
                             text=True, timeout=5).stdout
    except (OSError, subprocess.TimeoutExpired):
        return []
    result = []
    for m in _LOCATION.finditer(raw):
        # Prefer the city coordinates, fall back to the weather station
        coords = _COORD.search(m["city"]) or _COORD.search(m["station"])
        if not coords:
            continue
        lat, lon = (math.degrees(float(c)) for c in coords.groups())
        result.append({"name": m["name"], "lat": round(lat, 4), "lon": round(lon, 4)})
    return result


def _key(lat: float, lon: float) -> str:
    return f"{float(lat):.2f},{float(lon):.2f}"


def _load(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def _store(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(f".{time.time_ns()}.tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False))
    tmp.replace(path)


def _get_json(url: str):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.load(r)


def place_name(lat: float, lon: float, fallback: str = "") -> str:
    """French locality name via Nominatim, cached per ~1 km grid cell."""
    global _last_nominatim
    cache, key = _load(NAMES), _key(lat, lon)
    if key in cache:
        return cache[key]
    # Nominatim usage policy: at most one request per second
    time.sleep(max(0.0, 1.1 - (time.monotonic() - _last_nominatim)))
    _last_nominatim = time.monotonic()
    try:
        data = _get_json("https://nominatim.openstreetmap.org/reverse?format=jsonv2"
                         f"&zoom=10&accept-language=fr&lat={lat}&lon={lon}")
    except Exception:
        return fallback  # not cached: retried next time
    addr = data.get("address", {})
    name = next((addr[k] for k in ("city", "town", "village", "municipality")
                 if k in addr), data.get("name") or fallback)
    cache = _load(NAMES)  # re-read: another script may have written meanwhile
    cache[key] = name
    _store(NAMES, cache)
    return name


def time_zone(lat: float, lon: float) -> str | None:
    """IANA zone for coordinates (Open-Meteo timezone=auto), cached forever."""
    cache, key = _load(ZONES), _key(lat, lon)
    if key in cache:
        return cache[key]
    try:
        data = _get_json("https://api.open-meteo.com/v1/forecast"
                         f"?latitude={lat}&longitude={lon}&timezone=auto"
                         "&current=temperature_2m")
    except Exception:
        return None
    cache = _load(ZONES)
    cache[key] = data["timezone"]
    _store(ZONES, cache)
    return data["timezone"]
