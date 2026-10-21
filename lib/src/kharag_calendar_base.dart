/// The public entry point: conversions between Gregorian civil dates and the
/// dates of one traditional calendar, with input validation.
library;

import 'calendar_engine.dart';
import 'julian_day.dart';
import 'tibetan_date.dart';
import 'tradition.dart';

/// Converts between Gregorian civil dates and the dates of a traditional
/// Tibetan, Bhutanese or Mongolian calendar.
///
/// Civil dates are taken from a [DateTime]'s year, month and day only; the
/// time of day and the time zone are ignored, and every [DateTime] returned
/// is a UTC midnight.
///
/// Calendar years [minYear] to [maxYear] are supported. The matching civil
/// range runs from [firstSupportedDate] (New Year's Day of [minYear]) to
/// [lastSupportedDate] (the day before New Year's Day of `maxYear + 1`), so
/// every result of one direction is accepted by the other. The arithmetic is
/// exact (integer only) across that whole range on every Dart platform,
/// including the web.
///
/// Results are bit-for-bit identical to the Python library caltib
/// (https://github.com/gantemur/caltib), see the package README.
final class KharagCalendar {
  /// Creates a calendar for [tradition].
  KharagCalendar(this.tradition) : _engine = CalendarEngine(tradition);

  /// The Tibetan Phugpa calendar.
  KharagCalendar.phugpa() : this(Tradition.phugpa);

  /// The Bhutanese calendar.
  KharagCalendar.bhutan() : this(Tradition.bhutan);

  /// The Mongolian calendar.
  KharagCalendar.mongol() : this(Tradition.mongol);

  /// Smallest supported calendar year.
  static const int minYear = 1000;

  /// Largest supported calendar year.
  static const int maxYear = 3000;

  /// The tradition this calendar computes.
  final Tradition tradition;

  final CalendarEngine _engine;

  late final int _firstJdn = _engine.newYearJdn(minYear);
  late final int _lastJdn = _engine.newYearJdn(maxYear + 1) - 1;

  /// The first supported civil day: New Year's Day of [minYear].
  DateTime get firstSupportedDate => jdnToDateTime(_firstJdn);

  /// The last supported civil day: the last day of calendar year [maxYear].
  DateTime get lastSupportedDate => jdnToDateTime(_lastJdn);

  // ---------------------------------------------------------------------
  // Civil date to calendar date
  // ---------------------------------------------------------------------

  /// The calendar date of the civil day named by [date]'s year, month and day.
  TibetanDate fromDate(DateTime date) =>
      fromYmd(date.year, date.month, date.day);

  /// The calendar date of the Gregorian civil day [year]-[month]-[day].
  ///
  /// Throws an [ArgumentError] for an invalid date or a day outside
  /// [firstSupportedDate]..[lastSupportedDate].
  TibetanDate fromYmd(int year, int month, int day) {
    if (year < minYear - 1 || year > maxYear + 1) {
      throw ArgumentError.value(year, 'year', _civilRangeMessage);
    }
    final jdn = gregorianToJdn(year, month, day);
    if (jdnToGregorian(jdn) != (year: year, month: month, day: day)) {
      throw ArgumentError('$year-$month-$day is not a valid Gregorian date');
    }
    if (jdn < _firstJdn || jdn > _lastJdn) {
      throw ArgumentError.value(
        '$year-$month-$day',
        'date',
        _civilRangeMessage,
      );
    }
    return _engine.fromJdn(jdn);
  }

  /// The calendar date of the civil day with Julian Day Number [jdn].
  ///
  /// Throws an [ArgumentError] for a day outside
  /// [firstSupportedDate]..[lastSupportedDate].
  TibetanDate fromJdn(int jdn) {
    if (jdn < _firstJdn || jdn > _lastJdn) {
      throw ArgumentError.value(
        jdn,
        'jdn',
        'must be $_firstJdn..$_lastJdn ($_civilRangeMessage)',
      );
    }
    return _engine.fromJdn(jdn);
  }

  // ---------------------------------------------------------------------
  // Calendar date to civil date
  // ---------------------------------------------------------------------

  /// The civil days carrying lunar day [tithi] of the given month: an empty
  /// list if that lunar day is skipped, one day normally, two days if it is
  /// duplicated. Pass [isLeapMonth] to address the leap month of a doubled
  /// pair; it is an error for a month that is not doubled.
  List<DateTime> toDates({
    required int year,
    required int month,
    bool isLeapMonth = false,
    required int tithi,
  }) {
    _checkComponents(year, month, tithi);
    return [
      for (final jdn in _engine.jdnsOf(year, month, isLeapMonth, tithi))
        jdnToDateTime(jdn),
    ];
  }

  /// The civil day of occurrence [occ] (1 or 2) of a lunar day, or `null`
  /// if that lunar day is skipped. When [occ] is 2 but the day is not
  /// duplicated, the single existing day is returned.
  DateTime? toDate({
    required int year,
    required int month,
    bool isLeapMonth = false,
    required int tithi,
    int occ = 1,
  }) {
    _checkComponents(year, month, tithi);
    if (occ < 1 || occ > 2) {
      throw ArgumentError.value(occ, 'occ', 'must be 1 or 2');
    }
    final jdn = _engine.jdnOf(year, month, isLeapMonth, tithi, occ: occ);
    return jdn == null ? null : jdnToDateTime(jdn);
  }

  /// The civil day of [date], honouring its occurrence; the inverse of
  /// [fromDate] for dates this calendar produced.
  DateTime toDateOf(TibetanDate date) {
    if (date.tradition != tradition) {
      throw ArgumentError.value(
        date,
        'date',
        'belongs to ${date.tradition.name}, not ${tradition.name}',
      );
    }
    final result = toDate(
      year: date.year,
      month: date.month,
      isLeapMonth: date.isLeapMonth,
      tithi: date.tithi,
      occ: date.occ,
    );
    if (result == null) {
      throw ArgumentError.value(date, 'date', 'is a skipped lunar day');
    }
    return result;
  }

  // ---------------------------------------------------------------------
  // Years and months
  // ---------------------------------------------------------------------

  /// The first civil day of calendar [year] (Losar / Tsagaan Sar).
  DateTime newYearDay(int year) {
    _checkYear(year, 'year');
    return jdnToDateTime(_engine.newYearJdn(year));
  }

  /// The civil-day span of a month; see [toDates] for [isLeapMonth].
  MonthBounds monthBounds(int year, int month, {bool isLeapMonth = false}) {
    _checkComponents(year, month, 1);
    return _engine.monthBounds(year, month, isLeapMonth: isLeapMonth);
  }

  // ---------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------

  String get _civilRangeMessage =>
      'must be ${_iso(_firstJdn)}..${_iso(_lastJdn)}, the civil days of '
      'calendar years $minYear..$maxYear in ${tradition.name}';

  static String _iso(int jdn) {
    final g = jdnToGregorian(jdn);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${g.year}-${two(g.month)}-${two(g.day)}';
  }

  static void _checkYear(int year, String name) {
    if (year < minYear || year > maxYear) {
      throw ArgumentError.value(
        year,
        name,
        'calendar year must be $minYear..$maxYear',
      );
    }
  }

  static void _checkComponents(int year, int month, int tithi) {
    _checkYear(year, 'year');
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be 1..12');
    }
    if (tithi < 1 || tithi > 30) {
      throw ArgumentError.value(tithi, 'tithi', 'must be 1..30');
    }
  }
}
