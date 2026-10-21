# kharag_calendar: port plan and progress tracker

Tracks the port of the traditional Tibetan (Phugpa), Bhutanese and Mongolian
calendar engines from the Python library
[caltib](https://github.com/gantemur/caltib) (commit `bd15aa9`, 2026-10-17)
to pure Dart. One phase at a time; a phase is done only when its tests are
green and this file is updated.

## Goal and accuracy contract

For every civil day from 1800-01-01 to 2200-12-31 and each of the three
traditions, the Dart output (year, month, leap month flag, lunar day, occurrence,
skipped flag, linear day) must equal caltib's output exactly. The fixtures in
`test/golden/` are generated from caltib and are the only definition of
"correct". Dates only; festivals, year names and astrology are later work.

## Status

| Phase | Status | Date | Verified by | Result |
|---|---|---|---|---|
| 0. Scaffold and golden data | done | 2026-10-21 | `dart analyze`; `dart test test/golden_fixtures_test.dart` | no issues; 8/8 passed |
| 1. Exact primitives | done | 2026-10-21 | `dart test test/int_math_test.dart test/julian_day_test.dart test/quarter_wave_table_test.dart` | 12/12 passed; full suite 20/20 |
| 2. Month engine and tradition specs | done | 2026-10-21 | `dart test test/tradition_test.dart test/month_engine_test.dart` | 17/17 passed; full suite 37/37 |
| 3. Day engine | done | 2026-10-21 | `dart test test/day_engine_test.dart` | 11/11 passed; full suite 48/48 |
| 4. Calendar engine (equality gate) | done | 2026-10-21 | `dart test test/calendar_engine_test.dart` | 26/26 passed; 439,386 day rows equal, 0 mismatches; full suite 74/74 |
| 5. Public API, docs, example | done | 2026-10-21 | `dart test test/kharag_calendar_test.dart`; `dart run example/kharag_calendar_example.dart`; `dart pub publish --dry-run` | 18/18 passed; full suite 92/92; example runs; dry run: 2 warnings only (uncommitted files, no `repository` field) |
| Final review (fresh reviewer) | done | 2026-10-21 | `dart test`; `dart analyze`; `dart format --set-exit-if-changed .`; `dart pub publish --dry-run` | 0 critical; 5 fixed (3 important + 2 re-graded); 9 minors deferred; full suite 107/107 |
| 6. Hardening (optional) | pending | | | |

## Phase checklists

### Phase 0: Scaffold and golden data
- [x] Pure Dart `pubspec.yaml` (no Flutter dependency), `lints` + `test` dev deps
- [x] `analysis_options.yaml` on `package:lints/recommended.yaml`
- [x] `.pubignore` excluding `tool/`, `test/golden/`, `docs/`, build output
- [x] Placeholder `Calculator` removed; `lib/kharag_calendar.dart` is an empty library
- [x] `tool/golden/gen_golden.py` generator and `test/golden/README.md`
- [x] Fixtures generated: 3 x 146,462 day rows, 3 x 4,986 month rows, 8,352 table rows
- [x] `test/support/golden.dart` loader and `test/golden_fixtures_test.dart`

### Phase 1: Exact primitives
- [x] `lib/src/int_math.dart`: `floorDiv`, `floorMod` (Python `//` and `%` semantics)
- [x] `lib/src/julian_day.dart`: Gregorian to JDN and back (Fliegel–Van Flandern, 2000-01-01 = 2451545)
- [x] `lib/src/quarter_wave_table.dart`: fixed-point quarter-wave interpolation
- [x] Tests: negatives for floorDiv/floorMod; JDN anchors and round trip 1600–2400; every row of `tables.csv.gz`

### Phase 2: Month engine and tradition specs
- [x] `lib/src/tradition.dart`: enum and exact constants (scaled ints) with a test reconstructing each fraction
- [x] `lib/src/month_engine.dart`: `mstar`, `nPlus`, `isTriggerLabel`, `getLunations`, `mstarFromLunation`, `labelFromLunation`, `firstLunation`
- [x] Tests: every row of `months_*` (label and lunation position); Janson Table 7 leap months

### Phase 3: Day engine
- [x] `lib/src/day_engine.dart`: `trueDateScaled(x)`, `civilJdn(x)`, `xFromJdn(jdn)`
- [x] Tests: every `tithi_end_jdns` value, `first_jdn`/`last_jdn`, the three tie cases, 2^53 bound at years 1000 and 3000

### Phase 4: Calendar engine (equality gate)
- [x] `lib/src/calendar_engine.dart`, `lib/src/tibetan_date.dart`
- [x] Tests: all 439,386 day rows equal on every column; `toJdn` equals `tithi_end_jdns`; `toGregorian` all/occ; `newYearDay` 1801–2199, Janson Table 9, official Losar and Tsagaan Sar dates; `monthBounds`

### Phase 5: Public API, docs, example
- [x] `KharagCalendar` facade, exports, `DateTime` as civil date, rabjung getters, `ArgumentError` validation
- [x] README, CHANGELOG 0.1.0, example, dartdoc
- [x] `dart analyze`, `dart format --set-exit-if-changed .`, `dart pub publish --dry-run` clean

### Phase 6: Hardening (optional)
- [ ] Benchmark, dart2js test run, CI workflow, Tsurphu spec

## Decisions log

- 2026-10-20: caltib chosen over hnw/date-tibetan. Both implement Svante Janson's
  formulas with the same constants and agree on all but 3 days of 1900–2100;
  on those 3 days date-tibetan contradicts its own inverse conversion while
  caltib is self-consistent (exact fractions).
- 2026-10-20: pure Dart package; golden range 1800–2200 (covers negative
  lunation indices before the Phugpa epoch 1927); generator and fixtures committed.
- 2026-10-21: this file is the ledger for the port (no separate progress file).
  No git commits are made by the assistant; the user commits when ready.
- 2026-10-21: fixtures total about 3.6 MB gzipped (CSV compresses less than the
  1.8 MB estimated). Accepted; they are excluded from the published package.
- Numeric design: exact fixed-point `int` arithmetic, no BigInt and no doubles.
  `DAY_SCALE = 102_317_040 = lcm(11312, 7560, 24120)`; moon phase in 1/3528 turn,
  sun anomaly phase in 1/4824 turn. Verified against caltib with exact fractions
  on 321,083 sampled tithi indices across 1000–3000 (0 mismatches); largest
  intermediate 2.88e14, under 2^53, so dart2js stays exact.
- Every division in the port uses `floorDiv`/`floorMod`; Dart `~/` and `%`
  truncate toward zero and would break negative lunation indices.
- 2026-10-21: the facade lives in `lib/src/kharag_calendar_base.dart` (Dart
  convention) rather than `lib/src/kharag_calendar.dart` named in the plan.
- 2026-10-21: LICENSE set to MIT (same as caltib and date-tibetan); the user
  did not name one. `repository`/`homepage` left out of pubspec until the
  user provides the URL (publish dry run warns about it).
- 2026-10-21: two Phase 5 test expectations were wrong and corrected; the
  engine was right (it had already matched caltib on those days in Phase 4):
  Mongol New Year 2025 falls on lunar day 2 because day 1 is skipped, and
  Bhutan 2016 month 8 day 1 is duplicated (1 and 2 October).

## Final review (2026-10-21)

An independent reviewer read every file against caltib and the plan. Its own
checks, run outside the repo: 4,000 days per tradition in 1000-1800 and
2200-3000, all 6,003 New Year's Days 1000-3000, and 298 month bounds with
their `toJdn` values compared with caltib's own functions (0 mismatches);
dart2js versus VM hashes over 105,209 days per tradition (identical); a
365-day `fromDate` loop in 0.24 ms (VM) and 0.55 ms (JS). No critical issues.

Fixed, each with a test that failed first:
- Range edges: `fromYmd(1000, 1, 1)` produced calendar year 999, which the
  inverse rejected, and `toDates(3000, 12, 30)` produced a 3001 date that
  `fromDate` rejected. Calendar years stay 1000..3000; the civil range is now
  `newYearJdn(1000) .. newYearJdn(3001) - 1` per tradition, exposed as
  `firstSupportedDate` / `lastSupportedDate`; `fromJdn` errors name the jdn and
  the range. Tests: "supported range is closed under both directions" (first
  and last 90 days of every tradition round-trip), "rejects civil days outside
  the supported range", "the jdn range error names the jdn and the allowed
  range".
- Export surface: `tradition.dart` exported fixed-point scales, specs and
  `Tradition.spec`. Now `show Tradition`; `spec` moved to an internal
  extension; public `Tradition.leapMonthComesFirst` added. Test:
  `test/public_api_test.dart` (analyzer probe, 9 internals must be errors).
- LICENSE now carries caltib's MIT notice (port of its engines).
- SDK floor `^3.11.4` lowered to `^3.8.0` (lints 6.1 needs 3.8; code needs 3.0).
- "TibetanDate equality covers every field" now changes each of the 8 fields;
  proven by a mutant `==` without `linearDay`, which the test caught.
- Also added: `toDateOf` error-path tests, direct tests of the exported
  `dateTimeToJdn` / `jdnToDateTime`.

Rulings:
- Ruling: SDK floor re-graded Minor to Important. Users on Dart below 3.11 (Flutter before 3.41) could not install the package at all. Cost if wrong: none, the constraint only widens.
- Ruling: equality-test strength re-graded Minor to Important. The 439,386-row gate compares whole `TibetanDate` values, so a field silently dropped from `==` would weaken the accuracy contract with no failing test. Cost if wrong: one test-only change.
- Ruling: civil range defined from the calendar range (Losar 1000 to the eve of Losar 3001) rather than widening calendar years to 999. It keeps one rule ("calendar years 1000..3000") and makes both directions closed. Cost if wrong: `fromYmd` now rejects roughly 1000-01-01..Losar 1000 and accepts early 3001.
- Ruling: the 1000-1800 and 2200-3000 parts of the range stay spot-checked (reviewer) rather than covered by fixtures. Full fixtures would roughly quintuple the 3.6 MB. README says so. Cost if wrong: an unseen divergence outside 1800-2200, judged unlikely after 0 mismatches in 18,000+ comparisons.
- Ruling (declined-to-judge items): almanac-vs-formula accuracy, festivals and astrology, Phase 6, fixture size, missing `repository` URL, facade file name, MIT for the package, caltib's own lax inputs, behaviour outside 1000-3000. All stand as recorded in the decisions log above or as out of scope; none changes what a user of 0.1.0 gets for valid input.

Deferred minors (not fixed):
- `ArgumentError.value(date, ...)` in `toDateOf` prints "Instance of 'TibetanDate'" instead of the date.
- `TibetanDate ==` includes `occ`, `previousTithiSkipped`, `linearDay` (as caltib does), and the constructor default `linearDay = 0` is impossible; document or offer a label-only comparison.
- `MonthBounds` has no `==` / `hashCode`.
- No direct "is this month doubled?" query (`monthBounds(..., isLeapMonth: true)` throws instead); consider `isLeapMonth(year, month)` or `monthsOf(year)`.
- Golden tests use `dart:io` and cannot run on the web; add a VM-vs-JS hash check in Phase 6.
- `gen_golden.py`: gzip headers carry name and mtime and `meta.json` a timestamp, so regeneration always diffs; use `mtime=0`; detect a dirty caltib checkout; docstring says "a few minutes", README "about a minute".
- `.pubignore` lacks `**/doc/api/`; the Flutter template's `.metadata` is still tracked.
- Published `test/*.dart` read `test/golden/`, which pub does not ship; optional skip when fixtures are absent.
- `CalendarEngine.jdnOf(occ: 0)` throws `RangeError` (caltib returns the last day); unreachable through the facade.

## Verification log

| Date | Command | Result |
|---|---|---|
| 2026-10-21 | `python3 tool/golden/gen_golden.py --caltib-src <caltib/src> --from 1800 --to 2200 --out test/golden` | 7 files, 1 min, caltib commit bd15aa9 |
| 2026-10-21 | `dart analyze` | No issues found |
| 2026-10-21 | `dart test test/golden_fixtures_test.dart` | 8/8 passed (watched fail first with fixtures absent) |
| 2026-10-21 | `dart test test/int_math_test.dart test/julian_day_test.dart test/quarter_wave_table_test.dart` | 12/12 passed (watched fail first: library files absent); all 8,352 table values equal caltib; 292,560-day JDN round trip agrees with `DateTime` |
| 2026-10-21 | `dart test`; `dart analyze`; `dart format --set-exit-if-changed .` | 20/20; no issues; clean |
| 2026-10-21 | `dart test test/tradition_test.dart test/month_engine_test.dart` | 17/17 passed (watched fail first: library files absent); all 3 x 4,986 caltib lunation labels and positions equal |
| 2026-10-21 | `dart test`; `dart analyze`; `dart format --set-exit-if-changed .` | 37/37; no issues; clean |
| 2026-10-21 | `dart test test/day_engine_test.dart` | 11/11 passed (watched fail first: library file absent); all 3 x 149,580 caltib tithi boundaries equal; xFromJdn correct at every dawn 1799-2202; 3 tie cases match |
| 2026-10-21 | `dart test`; `dart analyze`; `dart format --set-exit-if-changed .` | 48/48; no issues; clean |
| 2026-10-21 | `dart test test/calendar_engine_test.dart` | 26/26 passed (watched fail first: library files absent); fromJdn equals caltib on all 3 x 146,462 days (every column); toJdn, jdnsOf, jdnOf, newYearJdn, monthBounds equal caltib; Janson Table 9 and official Losar / Tsagaan Sar dates match |
| 2026-10-21 | `dart test`; `dart analyze`; `dart format --set-exit-if-changed .` | 74/74; no issues; clean |
| 2026-10-21 | Independent spot check: caltib `day_info` in Python vs Dart `CalendarEngine.fromJdn` on 26 dates per tradition (20 random in 1500-2500 plus 1500-03-01, 1700-07-15, 1799-12-31, 2201-01-01, 2399-06-30, 2500-12-31) | 78/78 rows identical, including dates outside the fixture range |
| 2026-10-21 | `dart test test/kharag_calendar_test.dart` | 18/18 passed (watched fail first: facade absent; then 2 wrong expectations corrected against the fixtures) |
| 2026-10-21 | `dart test`; `dart analyze`; `dart format --set-exit-if-changed .`; `dart run example/kharag_calendar_example.dart`; `dart pub publish --dry-run` | 92/92; no issues; clean; example prints all three calendars; dry run has 2 warnings (uncommitted files, missing `repository`), no errors |
| 2026-10-21 | Final review fix pass: new tests run first | RED: facade tests failed to compile (no `firstSupportedDate`, `leapMonthComesFirst`), `public_api_test` failed (`meanScale is reachable`); equality test caught a mutant `==` without `linearDay` |
| 2026-10-21 | `dart test`; `dart analyze`; `dart format --set-exit-if-changed .`; `dart run example/kharag_calendar_example.dart`; `dart pub publish --dry-run` | 107/107; no issues; clean; example runs; dry run 2 warnings (files not committed, missing `repository`), no errors |

## Reference: what each Dart file mirrors in caltib (`src/caltib/`)

| Dart | caltib | Notes |
|---|---|---|
| `int_math.dart` | Python `//`, `%` | floor semantics |
| `julian_day.dart` | `core/time.py` `to_jdn`, `from_jdn` | JDN at noon |
| `quarter_wave_table.dart` | `engines/astro/tables.py` `QuarterWaveTable.eval_u` | `>` at the N/2 and N/4 folds, `i >= N/4` returns amplitude |
| `month_engine.dart` | `engines/arithmetic_month.py` | `beta_int = beta_star + (P - tau) % P`, not reduced mod P |
| `day_engine.dart` | `engines/trad_day.py` | `n = x // 30`, `d = x - 30n`; `civil_jdn = floor(true_date)` |
| `calendar_engine.dart` | `engines/calendar.py`, `api.py` | `from_jdn` search, `occ = jdn - J(x-1)`, `skipped = J(x-1) == J(x-2)`, `linear_day = jdn - J(30n)`, `to_gregorian` policies, `new_year_day`, `month_bounds` |
| `tibetan_date.dart` | `core/types.py` | rabjung cycle `(year-1027)//60+1`, year `(year-1027)%60+1` |

`delta_k` is 0 for all three traditions, so month and day lunation indices coincide.

### Constants

Shared: `P=65`, `Q=67`, `M0=3`; `m1 = 167025/5656`, `m2 = 11135/11312`;
`s1 = 65/804`, `s2 = 13/4824`; `a1 = 253/3528`, `a2 = 1/28`;
`r0 = s0 - 1/4`, `r1 = s1`, `r2 = s2`; moon table `(0,5,10,15,19,22,24,25)` (N=28),
sun table `(0,6,10,11)` (N=12); equation amplitude `1/60` day.

| Tradition | Y0 | beta_star | tau | beta_int | m0 | s0 | a0 | leap labeling |
|---|---|---|---|---|---|---|---|---|
| phugpa | 1927 | 55 | 48 | 72 | 13715647089/5656 | 749/804 | 1741/3528 | first_is_leap |
| bhutan | 1754 | 2 | 57 | 10 | 1669797601/707 | 1/67 | 17/147 | second_is_leap |
| mongol | 1747 | 10 | 46 | 29 | 6671924839/2828 | 397/402 | 1523/1764 | first_is_leap |

## How to regenerate fixtures

See `test/golden/README.md`. Clone caltib at the commit in `meta.json`, run the
generator, then `dart test`.
