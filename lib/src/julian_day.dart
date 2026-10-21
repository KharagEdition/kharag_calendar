/// Conversions between proleptic Gregorian dates and Julian Day Numbers.
///
/// Mirrors `core/time.py` of caltib: a JDN names a civil day, with
/// 2000-01-01 being JDN 2451545.
library;

import 'int_math.dart';

/// Returns the Julian Day Number of the Gregorian civil day [year]-[month]-[day].
int gregorianToJdn(int year, int month, int day) {
  final a = floorDiv(14 - month, 12);
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day +
      floorDiv(153 * m + 2, 5) +
      365 * y +
      floorDiv(y, 4) -
      floorDiv(y, 100) +
      floorDiv(y, 400) -
      32045;
}

/// Returns the Gregorian civil day of Julian Day Number [jdn]
/// (Fliegel and Van Flandern, inverse of [gregorianToJdn]).
({int year, int month, int day}) jdnToGregorian(int jdn) {
  final a = jdn + 32044;
  final b = floorDiv(4 * a + 3, 146097);
  final c = a - floorDiv(146097 * b, 4);
  final d = floorDiv(4 * c + 3, 1461);
  final e = c - floorDiv(1461 * d, 4);
  final m = floorDiv(5 * e + 2, 153);
  final day = e - floorDiv(153 * m + 2, 5) + 1;
  final month = m + 3 - 12 * floorDiv(m, 10);
  final year = 100 * b + d - 4800 + floorDiv(m, 10);
  return (year: year, month: month, day: day);
}

/// Returns the civil day of Julian Day Number [jdn] as a UTC midnight
/// [DateTime].
DateTime jdnToDateTime(int jdn) {
  final g = jdnToGregorian(jdn);
  return DateTime.utc(g.year, g.month, g.day);
}

/// Returns the Julian Day Number of the civil day named by [date]'s year,
/// month and day fields; the time of day and the time zone are ignored.
int dateTimeToJdn(DateTime date) =>
    gregorianToJdn(date.year, date.month, date.day);
