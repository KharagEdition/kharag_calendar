## 0.1.0

Initial release.

- Tibetan (Phugpa), Bhutanese and Mongolian calendar conversions in pure Dart,
  with no dependencies.
- `KharagCalendar`: civil date to calendar date, calendar date to civil days
  (handling skipped and duplicated lunar days and leap months), New Year's
  Day, month bounds, rabjung cycle, `firstSupportedDate`/`lastSupportedDate`,
  `Tradition.leapMonthComesFirst`.
- Exact integer arithmetic; results are bit-for-bit identical to the Python
  library caltib (commit `bd15aa9`) on every day from 1800 to 2200 for all
  three traditions, and exact on the web.
