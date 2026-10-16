#!/usr/bin/env python3
"""Print local date/time and world clocks as JSON for the eww clock panel.

World clocks come from GNOME Clocks (dconf /org/gnome/clocks/world-clocks),
so they are edited in the Clocks app.
"""

import json
from datetime import datetime
from zoneinfo import ZoneInfo

from places import gnome_locations, time_zone

DAYS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
MONTHS = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet",
          "août", "septembre", "octobre", "novembre", "décembre"]

now = datetime.now().astimezone()


def world(loc: dict) -> dict | None:
    zone = time_zone(loc["lat"], loc["lon"])
    if not zone:
        return None
    t = now.astimezone(ZoneInfo(zone))
    diff = (t.utcoffset() - now.utcoffset()).total_seconds() / 3600
    day_shift = (t.date() - now.date()).days
    hint = f"{diff:+g} h" if diff else "même heure"
    if day_shift:
        hint = ("demain, " if day_shift > 0 else "hier, ") + hint
    return {"label": loc["name"],
            "time": t.strftime("%H:%M"), "hint": hint}


clocks = [w for w in map(world, gnome_locations("/org/gnome/clocks/world-clocks")) if w]
print(json.dumps({
    "weekday": DAYS[now.weekday()].capitalize(),
    "date": f"{now.day} {MONTHS[now.month - 1]} {now.year}",
    "time": now.strftime("%H:%M"),
    "world": clocks,
}, ensure_ascii=False))
