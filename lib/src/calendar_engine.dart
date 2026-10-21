/// The orchestrator binding the month engine and the day engine into
/// conversions between civil days (Julian Day Numbers) and calendar dates.
///
/// Mirrors `CalendarEngine` in caltib's `engines/calendar.py` and the
/// `new_year_day` / `month_bounds` helpers of `api.py`. All inputs and
/// outputs are integers; converting to Gregorian dates is the caller's job
/// (see `julian_day.dart`).
library;

import 'day_engine.dart';
import 'int_math.dart';
import 'month_engine.dart';
import 'tibetan_date.dart';
import 'tradition.dart';

/// Converts between Julian Day Numbers and dates of one tradition.
final class CalendarEngine {
  /// Creates the engine for [tradition].
  CalendarEngine(this.tradition)
    : spec = tradition.spec,
      months = ArithmeticMonthEngine(tradition.spec),
      days = TraditionalDayEngine(tradition.spec);

  /// The calendar this engine computes.
  final Tradition tradition;

  /// The tradition's constants.
  final TraditionSpec spec;

  /// The discrete month arithmetic.
  final ArithmeticMonthEngine months;

  /// The continuous day kinematics.
  final TraditionalDayEngine days;

  bool _isLeap(int leapState) => switch (leapState) {
    1 => spec.leapLabeling == LeapLabeling.firstIsLeap,
    2 => spec.leapLabeling == LeapLabeling.secondIsLeap,
    _ => false,
  };

  /// The lunation index of month ([year], [month]), picking the leap or the
  /// regular one of a doubled pair by [isLeapMonth] and the tradition's
  /// leap labeling.
  ///
  /// Throws an [ArgumentError] if [isLeapMonth] is set for a month that is
  /// not doubled (caltib `to_jdn` raises `ValueError` there).
  int lunationOf(int year, int month, bool isLeapMonth) {
    final lunations = months.getLunations(year, month);
    if (lunations.length == 1) {
      if (isLeapMonth) {
        throw ArgumentError(
          'Month $month of year $year is not a leap month in ${tradition.name}',
        );
      }
      return lunations[0];
    }
    final leapFirst = spec.leapLabeling == LeapLabeling.firstIsLeap;
    return isLeapMonth == leapFirst ? lunations[0] : lunations[1];
  }

  /// The date of civil day [jdn] (caltib `from_jdn` + `day_info`).
  TibetanDate fromJdn(int jdn) {
    final x = days.xFromJdn(jdn);
    final n = floorDiv(x - 1, 30);
    final tithi = floorMod(x - 1, 30) + 1;
    final label = months.labelFromLunation(n);
    final previousEnd = days.civilJdn(x - 1);
    return TibetanDate(
      tradition: tradition,
      year: label.year,
      month: label.month,
      isLeapMonth: _isLeap(label.leapState),
      tithi: tithi,
      occ: jdn - previousEnd,
      previousTithiSkipped: previousEnd == days.civilJdn(x - 2),
      linearDay: jdn - days.civilJdn(30 * n),
    );
  }

  /// The civil day on which lunar day [tithi] of the month ends
  /// (caltib `to_jdn`).
  int toJdn(int year, int month, bool isLeapMonth, int tithi) =>
      days.civilJdn(30 * lunationOf(year, month, isLeapMonth) + tithi);

  /// The civil days labeled ([year], [month], [isLeapMonth], [tithi]):
  /// none if the lunar day is skipped, one normally, two if duplicated
  /// (caltib `to_gregorian` with `policy="all"`).
  List<int> jdnsOf(int year, int month, bool isLeapMonth, int tithi) {
    final x = 30 * lunationOf(year, month, isLeapMonth) + tithi;
    final start = days.civilJdn(x - 1) + 1;
    final end = days.civilJdn(x) + 1; // exclusive
    return [for (var j = start; j < end; j++) j];
  }

  /// The civil day of occurrence [occ] (1 or 2) of a lunar day, clamped to
  /// the last existing occurrence; `null` if the lunar day is skipped
  /// (caltib `to_gregorian` with `policy="occ"`).
  int? jdnOf(int year, int month, bool isLeapMonth, int tithi, {int occ = 1}) {
    final all = jdnsOf(year, month, isLeapMonth, tithi);
    if (all.isEmpty) return null;
    final index = occ - 1 < all.length - 1 ? occ - 1 : all.length - 1;
    return all[index];
  }

  /// The first civil day of [year] (Losar / Tsagaan Sar; caltib
  /// `new_year_day`).
  int newYearJdn(int year) {
    final int lastLunation;
    if (spec.leapLabeling == LeapLabeling.firstIsLeap) {
      lastLunation = lunationOf(year - 1, 12, false);
    } else {
      final n1 = lunationOf(year, 1, false);
      final label = months.labelFromLunation(n1 - 1);
      lastLunation = lunationOf(label.year, label.month, label.leapState == 2);
    }
    return days.civilJdn(30 * lastLunation + 30) + 1;
  }

  /// The civil-day span of a month (caltib `month_bounds`).
  MonthBounds monthBounds(int year, int month, {bool isLeapMonth = false}) {
    final n = lunationOf(year, month, isLeapMonth);
    return MonthBounds(
      tradition: tradition,
      year: year,
      month: month,
      isLeapMonth: isLeapMonth,
      lunation: n,
      firstJdn: days.civilJdn(30 * n) + 1,
      lastJdn: days.civilJdn(30 * n + 30),
    );
  }
}
