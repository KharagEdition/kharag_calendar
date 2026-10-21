# kharag_calendar

Tibetan (Phugpa), Bhutanese and Mongolian lunisolar calendar conversions in
pure Dart, with no dependencies. Works in Flutter, command-line and server
apps, on every platform including the web.

The engines are a port of the traditional engines of the Python library
[caltib](https://github.com/gantemur/caltib) by Tsogtgerel Gantumur, which
implement the calendar arithmetic described in Svante Janson's
[*Tibetan calendar mathematics*](https://arxiv.org/abs/1401.6285) and Edward
Henning's *Kālacakra and the Tibetan Calendar*.

## Usage

```dart
import 'package:kharag_calendar/kharag_calendar.dart';

final phugpa = KharagCalendar.phugpa();   // also .bhutan(), .mongol()

// Civil date to calendar date.
final date = phugpa.fromDate(DateTime(2026, 2, 18));
print(date.year);         // 2026 (numbered like the Gregorian year it starts in)
print(date.month);        // 1
print(date.isLeapMonth);  // false
print(date.tithi);        // 1  (lunar day, 1..30)
print(date.rabjungCycle); // 17
print(date.rabjungYear);  // 40

// Calendar date to civil days.
phugpa.toDates(year: 2026, month: 1, tithi: 1);   // [2026-02-18]
phugpa.newYearDay(2026);                           // 2026-02-18 (Losar)
phugpa.monthBounds(2026, 1).lastDate;              // last day of month 1
```

### Skipped and duplicated days

A lunar day that covers no dawn is skipped and a lunar day that covers two
dawns is duplicated, so a month has between 29 and 30 civil days:

```dart
final bhutan = KharagCalendar.bhutan();
bhutan.toDates(year: 2020, month: 2, tithi: 30);  // [2020-04-22, 2020-04-23]
bhutan.fromDate(DateTime(2020, 4, 23)).occ;       // 2 (second occurrence)
bhutan.toDate(year: 2020, month: 2, tithi: 30, occ: 2); // 2020-04-23

phugpa.toDates(year: 2012, month: 1, tithi: 19);  // [] (skipped)
phugpa.fromDate(DateTime(2012, 3, 12)).previousTithiSkipped; // true
```

### Leap months

Roughly every 32 months a month number is used twice. Address the leap
month with `isLeapMonth: true`. In the Phugpa and Mongolian calendars the
leap month comes first; in the Bhutanese calendar it comes second.

```dart
phugpa.toDate(year: 2016, month: 4, isLeapMonth: true, tithi: 1); // 2016-05-07
phugpa.toDate(year: 2016, month: 4, tithi: 1);                    // 2016-06-06
```

### Dates and time zones

`fromDate` reads only the year, month and day of the `DateTime` you pass; the
time of day and the time zone are ignored. All `DateTime`s returned are UTC
midnights. Julian Day Numbers are available too (`fromJdn`, `gregorianToJdn`,
`jdnToGregorian`).

Calendar years 1000 to 3000 are supported. The matching civil range runs from
New Year's Day of 1000 to the last day of calendar year 3000 (early 3001); see
`firstSupportedDate` and `lastSupportedDate`. Every result of one direction is
accepted by the other. Anything outside throws an `ArgumentError`, as do
invalid dates, months or lunar days, or a leap flag on a month that is not
doubled. `Tradition.leapMonthComesFirst` tells which month of a doubled pair
is the leap month.

## Accuracy

Every result is computed with exact integer arithmetic (no floating point),
which keeps it identical on all Dart platforms including the web.

The test suite compares the package with caltib (commit `bd15aa9`) on every
civil day from 1800 to 2200 for all three traditions (439,386 days, every
field), on every lunar-day boundary in that range, on the reverse
conversions, New Year's Days and month bounds. All match. Outside 1800 to
2200, the rest of the supported range was spot-checked against caltib
(thousands of days, every New Year's Day from 1000 to 3000) with no
difference, on the Dart VM and compiled to JavaScript. Published dates
from Janson's paper and official holiday lists for Bhutan and Mongolia are
checked as well. See `docs/PORT_PLAN.md` and `test/golden/README.md` in the
repository.

Note that official almanacs are produced by human astrologers and can, in rare
boundary cases, differ by a day from the mathematical reconstruction (Janson
notes the Bhutanese government calendar placed Losar 2003 on 3 March where the
formulas give 4 March). If you need to track an official almanac exactly,
keep an override table for such dates.

## Traditions

| `Tradition` | Calendar | Epoch used | Leap month |
|---|---|---|---|
| `phugpa` | Tibetan, Phugpa (Phukluk) system | 1927 | first of the pair |
| `bhutan` | Bhutanese | 1754 | second of the pair |
| `mongol` | Mongolian (New Genden) | 1747 | first of the pair |

## License

MIT. The reference library caltib is also MIT licensed.
