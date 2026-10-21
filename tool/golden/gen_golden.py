#!/usr/bin/env python3
"""Generate the golden fixtures for kharag_calendar from the caltib reference library.

Usage (from the package root):

    python3 tool/golden/gen_golden.py --caltib-src /path/to/caltib/src \
        --from 1800 --to 2200 --out test/golden

Requires Python 3.9+ and a checkout of https://github.com/gantemur/caltib at the
commit recorded in test/golden/meta.json. caltib's core has no third-party
dependencies, so no virtualenv is needed. Runtime is a few minutes.

Outputs (all CSV, gzipped, header row first):
  days_<trad>_<from>_<to>.csv.gz
      date,year,month,is_leap_month,tithi,occ,previous_tithi_skipped,linear_day
      One row per civil day, from caltib `engine.day_info(date).tibetan`.
  months_<trad>_<from>_<to>.csv.gz
      n,year,month,leap_state,first_jdn,last_jdn,tithi_end_jdns
      One row per lunation n from first_lunation(from-1) to first_lunation(to+2),
      from `month.label_from_lunation(n)`, `day.civil_jdn(30n)+1`,
      `day.civil_jdn(30n+30)` and the 30 values civil_jdn(30n+1..30n+30).
  tables.csv.gz
      table,phase,value_scaled
      Moon table at every phase p in 0..3527 (value x 126) and sun table at
      every phase p in 0..4823 (value x 402), from `QuarterWaveTable.eval_turn`.
  meta.json
      caltib commit, command, range and row counts.
"""
from __future__ import annotations

import argparse
import csv
import gzip
import io
import json
import os
import subprocess
import sys
import warnings
from datetime import date, datetime, timedelta, timezone
from fractions import Fraction
from multiprocessing import Pool

TRADITIONS = ("phugpa", "bhutan", "mongol")
MOON_TURN, MOON_SCALE = 3528, 126
SUN_TURN, SUN_SCALE = 4824, 402


def _load_caltib(src: str):
    if src not in sys.path:
        sys.path.insert(0, src)
    warnings.filterwarnings("ignore")
    import caltib  # noqa: E402

    return caltib


def _write_gz(path: str, text: str) -> None:
    with gzip.open(path, "wt", encoding="utf-8", newline="") as f:
        f.write(text)


def _csv_buffer():
    buf = io.StringIO()
    return buf, csv.writer(buf, lineterminator="\n")


def gen_days(job):
    src, trad, y0, y1, out = job
    eng = _load_caltib(src).get_calendar(trad)
    buf, w = _csv_buffer()
    w.writerow(["date", "year", "month", "is_leap_month", "tithi", "occ",
                "previous_tithi_skipped", "linear_day"])
    d, end, rows = date(y0, 1, 1), date(y1, 12, 31), 0
    while d <= end:
        t = eng.day_info(d).tibetan
        w.writerow([d.isoformat(), t.year, t.month, int(t.is_leap_month), t.tithi,
                    t.occ, int(t.previous_tithi_skipped), t.linear_day])
        rows += 1
        d += timedelta(days=1)
    name = f"days_{trad}_{y0}_{y1}.csv.gz"
    _write_gz(os.path.join(out, name), buf.getvalue())
    return name, rows


def gen_months(job):
    src, trad, y0, y1, out = job
    eng = _load_caltib(src).get_calendar(trad)
    buf, w = _csv_buffer()
    w.writerow(["n", "year", "month", "leap_state", "first_jdn", "last_jdn", "tithi_end_jdns"])
    n_start = eng.month.first_lunation(y0 - 1)
    n_end = eng.month.first_lunation(y1 + 2)
    rows = 0
    for n in range(n_start, n_end + 1):
        year, month, leap_state = eng.month.label_from_lunation(n)
        first_jdn = eng.day.civil_jdn(30 * n) + 1
        last_jdn = eng.day.civil_jdn(30 * n + 30)
        ends = " ".join(str(eng.day.civil_jdn(30 * n + d)) for d in range(1, 31))
        w.writerow([n, year, month, leap_state, first_jdn, last_jdn, ends])
        rows += 1
    name = f"months_{trad}_{y0}_{y1}.csv.gz"
    _write_gz(os.path.join(out, name), buf.getvalue())
    return name, rows


def gen_tables(job):
    src, out = job
    eng = _load_caltib(src).get_calendar("phugpa")  # tables are shared by all traditions
    buf, w = _csv_buffer()
    w.writerow(["table", "phase", "value_scaled"])
    rows = 0
    for p in range(MOON_TURN):
        v = eng.day.moon_table.eval_turn(Fraction(p, MOON_TURN)) * MOON_SCALE
        assert v.denominator == 1, (p, v)
        w.writerow(["moon", p, v.numerator])
        rows += 1
    for p in range(SUN_TURN):
        v = eng.day.sun_table.eval_turn(Fraction(p, SUN_TURN)) * SUN_SCALE
        assert v.denominator == 1, (p, v)
        w.writerow(["sun", p, v.numerator])
        rows += 1
    _write_gz(os.path.join(out, "tables.csv.gz"), buf.getvalue())
    return "tables.csv.gz", rows


def _run(job):
    kind, payload = job
    return {"days": gen_days, "months": gen_months, "tables": gen_tables}[kind](payload)


def _caltib_commit(src: str) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", os.path.dirname(os.path.abspath(src)), "rev-parse", "HEAD"],
            text=True).strip()
    except Exception:  # noqa: BLE001
        return "unknown"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--caltib-src", required=True, help="path to caltib/src")
    ap.add_argument("--from", dest="y0", type=int, default=1800)
    ap.add_argument("--to", dest="y1", type=int, default=2200)
    ap.add_argument("--out", default="test/golden")
    ap.add_argument("--jobs", type=int, default=min(7, os.cpu_count() or 1))
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    jobs = [("days", (a.caltib_src, t, a.y0, a.y1, a.out)) for t in TRADITIONS]
    jobs += [("months", (a.caltib_src, t, a.y0, a.y1, a.out)) for t in TRADITIONS]
    jobs += [("tables", (a.caltib_src, a.out))]
    with Pool(processes=a.jobs) as pool:
        results = pool.map(_run, jobs)

    meta = {
        "caltib_repo": "https://github.com/gantemur/caltib",
        "caltib_commit": _caltib_commit(a.caltib_src),
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "command": "python3 tool/golden/gen_golden.py --caltib-src <caltib/src> "
                   f"--from {a.y0} --to {a.y1} --out {a.out}",
        "range": {"from": a.y0, "to": a.y1},
        "traditions": list(TRADITIONS),
        "files": {name: rows for name, rows in results},
    }
    with open(os.path.join(a.out, "meta.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
        f.write("\n")
    for name, rows in results:
        print(f"{name}: {rows} rows")
    print(f"caltib commit: {meta['caltib_commit']}")


if __name__ == "__main__":
    main()
