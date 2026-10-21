/// Value types describing days and months of a traditional calendar.
library;

import 'int_math.dart';
import 'julian_day.dart';
import 'tradition.dart';

/// A civil day expressed in a traditional calendar (caltib `TibetanDate`).
///
/// [year] is numbered like the Gregorian year in which the Tibetan year
/// begins. [tithi] is the lunar day (1..30). When a lunar day spans two civil
/// days the two days share the label and differ in [occ] (1 then 2). When a
/// lunar day covers no dawn it is skipped, and the following day has
/// [previousTithiSkipped] set.
final class TibetanDate {
  /// Creates a date; no validation is performed here.
  const TibetanDate({
    required this.tradition,
    required this.year,
    required this.month,
    required this.isLeapMonth,
    required this.tithi,
    this.occ = 1,
    this.previousTithiSkipped = false,
    this.linearDay = 0,
  });

  /// The calendar this date belongs to.
  final Tradition tradition;

  /// The year, numbered like the Gregorian year it starts in.
  final int year;

  /// The month number, 1..12.
  final int month;

  /// Whether this is the leap (intercalary) month of a doubled pair.
  final bool isLeapMonth;

  /// The lunar day, 1..30.
  final int tithi;

  /// 1 for a normal day or the first of a duplicated pair, 2 for the second.
  final int occ;

  /// Whether the lunar day before [tithi] was skipped (covered no dawn).
  final bool previousTithiSkipped;

  /// Position of the civil day within its lunar month, first day being 1.
  final int linearDay;

  /// The 60-year cycle (rabjung) this year belongs to; the first cycle began
  /// in 1027. Floor semantics as in caltib, so 1026 is year 60 of cycle 0.
  int get rabjungCycle => floorDiv(year - 1027, 60) + 1;

  /// The position of this year within its rabjung cycle, 1..60.
  int get rabjungYear => floorMod(year - 1027, 60) + 1;

  /// Returns a copy with the given fields replaced.
  TibetanDate copyWith({
    Tradition? tradition,
    int? year,
    int? month,
    bool? isLeapMonth,
    int? tithi,
    int? occ,
    bool? previousTithiSkipped,
    int? linearDay,
  }) => TibetanDate(
    tradition: tradition ?? this.tradition,
    year: year ?? this.year,
    month: month ?? this.month,
    isLeapMonth: isLeapMonth ?? this.isLeapMonth,
    tithi: tithi ?? this.tithi,
    occ: occ ?? this.occ,
    previousTithiSkipped: previousTithiSkipped ?? this.previousTithiSkipped,
    linearDay: linearDay ?? this.linearDay,
  );

  @override
  bool operator ==(Object other) =>
      other is TibetanDate &&
      other.tradition == tradition &&
      other.year == year &&
      other.month == month &&
      other.isLeapMonth == isLeapMonth &&
      other.tithi == tithi &&
      other.occ == occ &&
      other.previousTithiSkipped == previousTithiSkipped &&
      other.linearDay == linearDay;

  @override
  int get hashCode => Object.hash(
    tradition,
    year,
    month,
    isLeapMonth,
    tithi,
    occ,
    previousTithiSkipped,
    linearDay,
  );

  @override
  String toString() =>
      'TibetanDate(${tradition.name} $year-$month'
      '${isLeapMonth ? 'L' : ''}-$tithi'
      '${occ == 2 ? ' occ 2' : ''}'
      '${previousTithiSkipped ? ' prevSkipped' : ''}'
      ' linearDay $linearDay)';
}

/// The civil-day span of one lunar month (caltib `month_bounds`).
final class MonthBounds {
  /// Creates the bounds; see [year], [month], [isLeapMonth].
  const MonthBounds({
    required this.tradition,
    required this.year,
    required this.month,
    required this.isLeapMonth,
    required this.lunation,
    required this.firstJdn,
    required this.lastJdn,
  });

  /// The calendar this month belongs to.
  final Tradition tradition;

  /// The year, numbered like the Gregorian year it starts in.
  final int year;

  /// The month number, 1..12.
  final int month;

  /// Whether this is the leap month of a doubled pair.
  final bool isLeapMonth;

  /// The tradition's lunation index of this month.
  final int lunation;

  /// Julian Day Number of the first civil day of the month.
  final int firstJdn;

  /// Julian Day Number of the last civil day of the month.
  final int lastJdn;

  /// The first civil day of the month as a UTC midnight [DateTime].
  DateTime get firstDate => jdnToDateTime(firstJdn);

  /// The last civil day of the month as a UTC midnight [DateTime].
  DateTime get lastDate => jdnToDateTime(lastJdn);

  @override
  String toString() =>
      'MonthBounds(${tradition.name} $year-$month'
      '${isLeapMonth ? 'L' : ''} n=$lunation jdn $firstJdn..$lastJdn)';
}
