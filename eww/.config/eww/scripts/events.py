#!/usr/bin/env python3

"""iCloud events for the eww clock panel.

    events.py                 print upcoming events (JSON, from cache)
    events.py --refresh       refresh upcoming events from CalDAV
    events.py --month Y M     refresh the colored day dots of a month grid

Output is always cache-first: CalDAV takes several seconds, so stale caches
are refreshed by a detached child that pushes new values with `eww update`.
Secrets: ~/secrets/icloud-email and icloud-password (same as agenda-mcp).

Reading the cache needs only the standard library (instant); the CalDAV
refresh paths re-exec themselves under nix-shell when caldav is missing.
"""

import fcntl
import json
import os
import shlex
import subprocess
import sys
import time
from datetime import date, datetime, timedelta
from pathlib import Path

CACHE_DIR = Path.home() / ".cache" / "eww"
CACHE = CACHE_DIR / "events.json"
DAYS_CACHE = CACHE_DIR / "days.json"
MAX_AGE = 300  # seconds
DAYS_AHEAD = 7
MAX_EVENTS = 6
DEFAULT_COLOR = "#6f8396"
SECRETS = (Path("/run/secrets"), Path.home() / "secrets")
SCRIPTS = Path(__file__).resolve().parent


def ensure_caldav() -> None:
    try:
        import caldav  # noqa: F401
        import icalendar  # noqa: F401
    except ImportError:
        cmd = shlex.join(["python3", os.path.abspath(__file__), *sys.argv[1:]])
        os.execvp("nix-shell", ["nix-shell", "-p", "python3Packages.caldav",
                                "python3Packages.icalendar", "--run", cmd])


def read_secret(name: str) -> str:
    for base in SECRETS:
        path = base / name
        if path.exists():
            return path.read_text().strip()
    raise RuntimeError(f"Missing secret: {name}")


def day_label(d: date, today: date) -> str:
    if d == today:
        return "Aujourd'hui"
    if d == today + timedelta(days=1):
        return "Demain"
    days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
    return f"{days[d.weekday()]} {d.day}"


def css_color(value) -> str:
    """iCloud gives #RRGGBBAA; GTK CSS wants #rrggbb."""
    s = str(value or "").strip()
    return s[:7].lower() if s.startswith("#") and len(s) >= 7 else DEFAULT_COLOR


def instances(start: date, end: date) -> list[dict]:
    """Event instances overlapping [start, end), recurrences expanded."""
    import caldav
    from caldav.elements import ical

    client = caldav.DAVClient(
        url="https://caldav.icloud.com/",
        username=read_secret("icloud-email"),
        password=read_secret("icloud-password"),
    )
    tz = datetime.now().astimezone().tzinfo

    def local(dt):
        if not isinstance(dt, datetime):
            return datetime.combine(dt, datetime.min.time(), tz)
        return (dt if dt.tzinfo else dt.replace(tzinfo=tz)).astimezone(tz)

    result = []
    for order, cal in enumerate(client.principal().calendars()):
        try:
            color = css_color(cal.get_property(ical.CalendarColor()))
            found = cal.search(start=local(start), end=local(end), event=True, expand=True)
        except Exception:
            continue
        for res in found:
            for ev in res.icalendar_instance.walk("VEVENT"):
                raw_start = ev.decoded("DTSTART")
                all_day = not isinstance(raw_start, datetime)
                raw_end = ev.decoded("DTEND", None)
                if raw_end is None:
                    raw_end = raw_start + timedelta(days=1) if all_day else raw_start
                result.append({
                    "start": local(raw_start),
                    "end": local(raw_end),
                    "all_day": all_day,
                    "title": str(ev.get("SUMMARY", "(sans titre)")),
                    "calendar": str(cal.name),
                    "color": color,
                    "order": order,
                })
    result.sort(key=lambda e: e["start"])
    return result


def write_atomic(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(f".{os.getpid()}.tmp")
    tmp.write_text(text)
    tmp.replace(path)


def eww(*args: str) -> None:
    try:
        subprocess.run(["eww", *args], capture_output=True)
    except FileNotFoundError:
        pass  # eww not installed: caches are still updated


def refresh_upcoming() -> None:
    today = date.today()
    now = datetime.now().astimezone()
    try:
        found = instances(today, today + timedelta(days=DAYS_AHEAD))
    except Exception:
        return  # keep the previous cache on network/auth errors
    items = []
    for e in found:
        if e["all_day"]:
            when = "Toute la journée"
        else:
            if e["end"] < now:
                continue  # already over
            when = e["start"].strftime("%H:%M")
            if e["end"] > e["start"]:
                when += " – " + e["end"].strftime("%H:%M")
        items.append({
            "day": day_label(e["start"].date(), today),
            "time": when,
            "title": e["title"],
            "calendar": e["calendar"],
            "color": e["color"],
        })
    payload = json.dumps(items[:MAX_EVENTS], ensure_ascii=False)
    write_atomic(CACHE, payload)
    eww("update", f"events={payload}")


def refresh_month(year: int, month: int) -> None:
    """Store the distinct calendar colors of each day of a month grid."""
    import calendar

    weeks = calendar.Calendar(firstweekday=6).monthdatescalendar(year, month)
    first, last = weeks[0][0], weeks[-1][-1]
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    lock = open(CACHE_DIR / f"month-{year}-{month:02d}.lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return  # already being fetched
    try:
        found = instances(first, last + timedelta(days=1))
    except Exception:
        return

    days: dict[str, list[str]] = {}
    # Same calendar order every day, so a dot keeps its position
    for e in sorted(found, key=lambda e: e["order"]):
        d = max(e["start"].date(), first)
        # DTEND is exclusive: an event ending at midnight doesn't cover that day
        stop = min(max((e["end"] - timedelta(seconds=1)).date(), e["start"].date()), last)
        while d <= stop:
            colors = days.setdefault(d.isoformat(), [])
            if e["color"] not in colors:
                colors.append(e["color"])
            d += timedelta(days=1)

    with open(CACHE_DIR / "days.lock", "w") as merge_lock:
        fcntl.flock(merge_lock, fcntl.LOCK_EX)
        try:
            cache = json.loads(DAYS_CACHE.read_text())
        except (OSError, ValueError):
            cache = {"months": {}, "days": {}}
        d = first
        while d <= last:  # drop the old values of the refreshed range
            cache["days"].pop(d.isoformat(), None)
            d += timedelta(days=1)
        cache["days"].update(days)
        cache["months"][f"{year}-{month:02d}"] = time.time()
        write_atomic(DAYS_CACHE, json.dumps(cache))
    # Redraw the grid (month.py ignores it if another month is displayed)
    subprocess.run([sys.executable, str(SCRIPTS / "month.py"), "render",
                    str(year), str(month)], capture_output=True)


def main() -> None:
    if "--refresh" in sys.argv or "--month" in sys.argv:
        ensure_caldav()
    if "--refresh" in sys.argv:
        refresh_upcoming()
        return
    if "--month" in sys.argv:
        i = sys.argv.index("--month")
        refresh_month(int(sys.argv[i + 1]), int(sys.argv[i + 2]))
        return
    try:
        cached = CACHE.read_text()
        age = time.time() - CACHE.stat().st_mtime
    except OSError:
        cached, age = "[]", MAX_AGE + 1
    print(cached, flush=True)
    if age > MAX_AGE:
        subprocess.Popen(
            [sys.executable, os.path.abspath(__file__), "--refresh"],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


if __name__ == "__main__":
    main()
