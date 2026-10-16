#!/usr/bin/env python3
"""Month grid with per-calendar colored dots for the eww clock panel.

    month.py today        show the current month
    month.py nav DELTA    move DELTA months from the displayed one
    month.py render Y M   redraw if month Y-M is still displayed

The grid is built from ~/.cache/eww/days.json (filled by events.py --month),
so it draws instantly; a stale month is refetched in the background.
"""

import calendar
import json
import subprocess
import sys
import time
from datetime import date
from pathlib import Path

DAYS_CACHE = Path.home() / ".cache" / "eww" / "days.json"
EVENTS = Path(__file__).resolve().parent / "events.py"
MAX_AGE = 300  # seconds
MAX_DOTS = 6
MONTHS = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet",
          "août", "septembre", "octobre", "novembre", "décembre"]


def eww(*args: str) -> str:
    try:
        return subprocess.run(["eww", *args], capture_output=True, text=True).stdout.strip()
    except FileNotFoundError:
        return ""


def displayed() -> tuple[int, int]:
    try:
        return int(eww("get", "cal_year")), int(eww("get", "cal_month"))
    except ValueError:
        today = date.today()
        return today.year, today.month


def grid(year: int, month: int) -> str:
    try:
        cache = json.loads(DAYS_CACHE.read_text())
    except (OSError, ValueError):
        cache = {"months": {}, "days": {}}
    fetched = cache["months"].get(f"{year}-{month:02d}", 0)
    if time.time() - fetched > MAX_AGE:
        subprocess.Popen([str(EVENTS), "--month", str(year), str(month)],
                         start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    today = date.today()
    weeks = []
    for week in calendar.Calendar(firstweekday=6).monthdatescalendar(year, month):
        cells = []
        for d in week:
            cls = []
            if d.month != month:
                cls.append("other")
            if d == today:
                cls.append("today")
            cells.append({
                "day": d.day,
                "date": d.isoformat(),
                "cls": " ".join(cls),
                "dots": cache["days"].get(d.isoformat(), [])[:MAX_DOTS],
            })
        weeks.append(cells)
    return json.dumps({"title": f"{MONTHS[month - 1]} {year}", "weeks": weeks})


def show(year: int, month: int) -> None:
    eww("update", f"cal_year={year}", f"cal_month={month}",
        f"cal_grid={grid(year, month)}")


def main() -> None:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "today"
    if cmd == "today":
        today = date.today()
        show(today.year, today.month)
    elif cmd == "nav":
        year, month = displayed()
        index = year * 12 + (month - 1) + int(sys.argv[2])
        show(index // 12, index % 12 + 1)
    elif cmd == "render":
        target = int(sys.argv[2]), int(sys.argv[3])
        if displayed() == target:
            eww("update", f"cal_grid={grid(*target)}")
    elif cmd == "print":  # debugging
        print(grid(*displayed()))


if __name__ == "__main__":
    main()
